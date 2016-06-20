---
layout: post
title: "Postgres JSONB indexing is tricky"
date: 2016-06-19 18:39:15 -0700
comments: true
categories:
- Postgres
---

I’m not a Postgres expert, but I’ve been using it for about 6 months as an Event Store database. At Bench we’ve built our own eventing system on top of ActiveMQ, Camel and Akka and we use Postgres to persist every single Domain Event.

Our event schema is very flexible and currently represented in JSON. We chose Postgres for persistence, because of the great JSON support. As you probably know, Postgres 9.4 introduced JSONB type, which is an advanced JSON type that supports indexing. Obviously, you should index all your key fields, but it can be tricky. Let me share what we’ve discovered.

<!-- more -->

## Problem

So, we have a query like this:

> select "id", "created_at", "version", "name", "context", "assets" from "event" where ("assets" @> '[{"resourceId": "569ee61ee4b0e7dd960dcee3"}]') or ("assets" @> '[{"resourceId": "874874"}]' ) or ("assets" @> '[{"resourceId": "875187"}]' ) or ("assets" @> '[{"resourceId": "858164"}]' ) or ("assets" @> '[{"resourceId": "858567"}]') order by "created_at" desc limit 1000 offset 0

`assets` field is a JSON array that contains different entities (objects). Some of them have `resourceId` field. In this query we want to find all events that contain assets with specified `resourceId`s. We only pass 5 `resourceId`s here, but in practice we can have many more.

Of course we have an index on this field:

> CREATE INDEX event_idx_assets ON event USING gin (assets jsonb_path_ops)

But… when you run the query, it can be REALLY slow. Let’s run `analyze`:

> explain analyze select "id", "created_at", "version", "name", "context", "assets" from "event" where ("assets" @> '[{"resourceId": "569ee61ee4b0e7dd960dcee3"}]') or ("assets" @> '[{"resourceId": "874874"}]' ) or ("assets" @> '[{"resourceId": "875187"}]' ) or ("assets" @> '[{"resourceId": "858164"}]' ) or ("assets" @> '[{"resourceId": "858567"}]') order by "created_at" desc limit 1000 offset 0

Results:

```
Limit  (cost=0.43..19176.24 rows=1000 width=322) (actual time=46.737..2730.530 rows=8 loops=1)
 ->  Index Scan Backward using event_idx_created_at on event  (cost=0.43..142898.56 rows=7452 width=322) (actual time=46.733..2730.505 rows=8 loops=1)
       Filter: ((assets @> '[{"resourceId": "569ee61ee4b0e7dd960dcee3"}]'::jsonb) OR (assets @> '[{"resourceId": "874874"}]'::jsonb) OR (assets @> '[{"resourceId": "875187"}]'::jsonb) OR (assets @> '[{"resourceId": "858164"}]'::jsonb) OR (assets @> '[{"resourceId": "858567"}]'::jsonb))
       Rows Removed by Filter: 1485296
Planning time: 0.134 ms
Execution time: 2730.569 ms
```

Wait… It doesn’t use our index! And it’s very slow because of that. But why? If you read documentation and StackOverflow discussions about indexing, you’ll see that it should work. There is no reason why it shouldn’t…

We’ve spent significant amount of time trying to understand why this index doesn’t work. After some we did an experiment - what if you run the query with only one `resourceId`?

> explain analyze select "id", "created_at", "version", "name", "context", "assets" from "event" where ("assets" @> '[{"resourceId": "569ee61ee4b0e7dd960dcee3"}]') order by "created_at" desc limit 1000 offset 0

```
Limit  (cost=6725.17..6727.67 rows=1000 width=322) (actual time=3.732..3.735 rows=1 loops=1)
 ->  Sort  (cost=6725.17..6728.91 rows=1493 width=322) (actual time=3.728..3.729 rows=1 loops=1)
       Sort Key: created_at
       Sort Method: quicksort  Memory: 25kB
       ->  Bitmap Heap Scan on event  (cost=1315.57..6646.46 rows=1493 width=322) (actual time=3.716..3.718 rows=1 loops=1)
             Recheck Cond: (assets @> '[{"resourceId": "569ee61ee4b0e7dd960dcee3"}]'::jsonb)
             Heap Blocks: exact=1
             ->  Bitmap Index Scan on event_idx_assets  (cost=0.00..1315.20 rows=1493 width=0) (actual time=3.700..3.700 rows=1 loops=1)
                   Index Cond: (assets @> '[{"resourceId": "569ee61ee4b0e7dd960dcee3"}]'::jsonb)
Planning time: 0.116 ms
Execution time: 3.771 ms
```

It works! How about 3?

> explain analyze select "id", "created_at", "version", "name", "context", "assets" from "event" where ("assets" @> '[{"resourceId": "569ee61ee4b0e7dd960dcee3"}]') or ("assets" @> '[{"resourceId": "874874"}]' ) or ("assets" @> '[{"resourceId": "875187"}]' ) order by "created_at" desc limit 1000 offset 0

```
Limit  (cost=18630.81..18633.31 rows=1000 width=322) (actual time=10.453..10.462 rows=3 loops=1)
 ->  Sort  (cost=18630.81..18642.00 rows=4476 width=322) (actual time=10.450..10.453 rows=3 loops=1)
       Sort Key: created_at
       Sort Method: quicksort  Memory: 26kB
       ->  Bitmap Heap Scan on event  (cost=3948.96..18385.39 rows=4476 width=322) (actual time=10.430..10.439 rows=3 loops=1)
             Recheck Cond: ((assets @> '[{"resourceId": "569ee61ee4b0e7dd960dcee3"}]'::jsonb) OR (assets @> '[{"resourceId": "874874"}]'::jsonb) OR (assets @> '[{"resourceId": "875187"}]'::jsonb))
             Heap Blocks: exact=1
             ->  BitmapOr  (cost=3948.96..3948.96 rows=4480 width=0) (actual time=10.416..10.416 rows=0 loops=1)
                   ->  Bitmap Index Scan on event_idx_assets  (cost=0.00..1315.20 rows=1493 width=0) (actual time=3.708..3.708 rows=1 loops=1)
                         Index Cond: (assets @> '[{"resourceId": "569ee61ee4b0e7dd960dcee3"}]'::jsonb)
                   ->  Bitmap Index Scan on event_idx_assets  (cost=0.00..1315.20 rows=1493 width=0) (actual time=3.354..3.354 rows=1 loops=1)
                         Index Cond: (assets @> '[{"resourceId": "874874"}]'::jsonb)
                   ->  Bitmap Index Scan on event_idx_assets  (cost=0.00..1315.20 rows=1493 width=0) (actual time=3.349..3.349 rows=1 loops=1)
                         Index Cond: (assets @> '[{"resourceId": "875187"}]'::jsonb)
Planning time: 0.120 ms
Execution time: 10.525 ms
```

Success! It seems like somewhere internally Postgres decides to optimize this query differently depending on the number of conditions you pass for the GIN indexed field. In our case index only worked with 1, 2 and 3 conditions.

## Solution

Well, you can’t really fix the indexing, but at least you know how to use it :) We ended up chunking one big query with lots of conditions into multiple queries containing only 3 conditions and merging results together. Unexpectedly, it’s *much* faster!