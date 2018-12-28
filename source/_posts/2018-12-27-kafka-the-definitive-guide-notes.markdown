---
layout: post
title: "\"Kafka: The Definitive Guide\": Notes"
date: 2018-12-27 19:43:26 -0800
comments: true
categories: 
- Kafka
---

For the last two years I've been working with Apache Kafka _a lot_. Everything including building infrastructure (and running clusters on bare metal, in VMs and containers), improving monitoring and alerting, developing consumers, producers and stream processors, tuning, maintenance, etc., so I consider myself a very proficient user. 

Still, all these years I didn't have a chance to read the ultimate "Kafka: The Definitive Guide" book. Finally, I've got one at Strata NYC earlier this year and finished it about a month ago. Surprisingly, while reading it, I left a lot of bookmarks and notes for myself that might be useful for beginners as well as experienced users. Obviously, they're very subjective and specific.

<!-- more -->

Some notes (no particular order):

- Run Zookeeper as 5-node ensemble. 3-node ensemble will work, and it can tolerate one of the nodes to go down. However, if you think about it, doing all kinds of maintenance that requires a rolling restart is pretty risky with 3-node ensemble: you're restarting nodes one by one and you can't tolerate any issues! With 5-node ensemble it's possible to tolerate the failure of two nodes, which is very  convenient during maintenance - one less thing to worry about.
- `kafka-verifiable-producer.sh` and `kafka-verifiable-consumer.sh` tools seem to be very useful, but I've never had a chance to use them. Suggested approach: use verifiable producer with the same configuration that's used in your application and make sure it can send data to Kafka. Use verifiable consumer to consume the events in order, it'll also show some extra metadata.
- If MirrorMaker is used as a replication tool between clusters and the message order is not critical, throughput can be significantly increased by increasing `max.in.flight.requests.per.connection` producer config option (default in a standard producer is `5`, but MirrorMaker uses `1` to persist the order).
- `kafka-topics.sh` tool has `--topics-with-overrides` option that only shows topics that have configurations that differ from the cluster defaults.
- `__consumer_offsets` topic can consumed (with console consumer, for example) and decoded using `kafka.coordinator.group.GroupMetadataManager$OffsetsMessageFormatter` formatter.
- It's important to monitor not only the number/bytes rate of the incoming messages, but also the bytes out rate. This rate shows all the outgoing traffic for all consumers, which is very likely higher than the incoming one.
- Monitor not only the disk space, but the number of inodes as well.
- By the way, other recommended disk metrics to monitor: writes and reads per second, the average read and write queue sizes and the average wait time.
- `record-error-rate` producer metric is a good candidate for alerting.

I found the book very useful overall and I highly recommend it. Now I'm waiting for the second edition that hopefully will include all the new features!
