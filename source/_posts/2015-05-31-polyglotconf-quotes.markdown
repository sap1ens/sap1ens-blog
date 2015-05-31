---
layout: post
title: "Polyglotconf quotes"
date: 2015-05-31 14:41:53 -0700
comments: true
categories:
- Conference
---

Last week I went to one of the most interesting Vancouver IT events: Polyglot Unconference. It’s quite big event with 300+ people and a wide range of topics. *Unconference* is unusual format, you can take a look more at [Wikipedia](http://en.wikipedia.org/wiki/Unconference), but generally it means that there is no schedule before event and all participants pitch and vote for topics. So you might face absolutely anything from hardcore Haskell and Microservices to React Native and HTML5 semantics.

I wanted to share four quotes that I heard and found really interesting. May be they are obvious for somebody, but I think they are worth mentioning. Unfortunately I don’t remember all authors, so I’m going to specify only session titles.

<!-- more -->

## Lightning Talks: Learning to Learn

*“Don’t break the chain“.*

It’s actually very simple and popular technique described [here](http://lifehacker.com/281626/jerry-seinfelds-productivity-secret).

Short version:

- Pick a goal
- Mark off the days on which you work toward that goal
- Use your chain of marked off days as a motivator

Example:
![](https://www.evernote.com/l/ABiMvC-0mCFN8bGsRBvMxcDl0KxgBkGqmz8B/image.png)

(and yes, there is a [website](http://dontbreakthechain.com) for that!)

So, I think motivation is really important for all creative professions including Software Engineering. Procrastination is a well-known issue and a lot of people struggle because of that every day. I’m sure that “Don’t break the chain“ is a real tool we can use to settle down the struggle. Or at least try ;-)

## Microservices data consistency

*“Avoid joins, use cache instead”.*

Microservices architecture brings a lot of questions regarding data consistency. We often hear concepts like event sourcing, CQRS, CRDTs, etc. But what if you just want to migrate your monolith with a bunch of joins in database level to microservices? Advice from Hootsuite is a bit provocative but still very useful - try to avoid joins as much as possible and use aggressive caching in your [Gateway](http://microservices.io/patterns/apigateway.html) level.

## Hypermedia Web APIs

*“You have to control your API clients”.*

[HATEOAS](http://en.wikipedia.org/wiki/HATEOAS) or Hypermedia as the Engine of Application State is a well-known, but still pretty new technique to the most of us. A very important thing you should know about it: if you want to release and *support* your HATEOAS-based API without hassle you have to control your API consumers. It doesn’t mean you can’t have a public API, it just means that you should provide API clients for major languages / SDKs and support them.

The reason behind is obvious: it’s really hard to propagate updates in HATEOAS-based APIs. Your client should be smart enough to understand changes in schemas, support multiple versions, expand resources, etc. Which is actually true for any complicated API, but in this case it’s almost mandatory.

## Distributed Systems & Elasticsearch

*“Availability is something you can detect and fix”.*

[CAP theorem](http://en.wikipedia.org/wiki/CAP_theorem) popularization made it easier to discuss distributed systems even for people without sophisticated knowledge in that area. In a very practical way you can rephrase CAP theorem to say that you can only built AP (Highly Available and Partition Tolerant) or CP (Strictly Consistent and Partition Tolerant) systems.

Every database, message queue or any other distributed system can be named as AP or CP system and sometimes they might even provide an ability to choose exactly what customer wants (for example Riak, you can have AP or CP system; it depends on some parameters you define).

Traditionally, when you build a system or learn something new you think about AP and CP systems equally. But thanks to this session, now I know a different point of view: consistency is something that is really hard to “fix” and availability is not. Load balancers, health checks and self-recovery, monitoring and alerts - all these tools and techniques are available to everybody.

So maybe we all should just build CP systems and invest to self-recovery / health checks? Sounds like a good plan to me, except the cases when you need to have really low latency (which is rare).

Btw, if you want to read more about practical application of CAP theorem I personally recommend awesome [Call me maybe](https://aphyr.com/tags/jepsen) series.
