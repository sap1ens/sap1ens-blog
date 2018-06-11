---
layout: post
title: "The Level Below"
date: 2018-06-11 11:45:50 +0500
comments: true
categories: 
- Me
- Thoughts
---

Over the years I realized a very simple, but also a fundamental principle about being a better software engineer - **understanding what's happening one level below**. With level I mean any level of abstraction you operate, for example HTTP API for a Front-end engineer, JVM and its internals for an enterprise Java developer, etc. 

It sounds like an obvious suggestion, but it's actually very useful to apply this principle to *any new feature* you're going to work on.

<!-- more --> 

## A few real-life examples

Imagine you need to write data from Kafka to Redshift. Standard implementation would involve reading messages from Kafka, writing files to S3, optionally running some compaction jobs and then finally using COPY command that Redshift provides. There is some complexity involved and the latency will be relatively high, but it's a robust design. 

Now, a colleague of yours heard something about importing data to Redshift using streaming, but only Kinesis is supported. Still, sounds cool: probably low-latency streaming and straightforward implementation, "just" (😉) need to send data from Kafka to Kinesis. 

So, let's go one level below. Unfortunately, [there is no magic](https://docs.aws.amazon.com/firehose/latest/dev/create-destination.html#create-destination-redshift): Kinesis-to-Redshift streaming uses S3 and COPY command too! So we may as well use it directly with Kafka (since I also discovered a well-tuned S3 & COPY implementation in our task scheduling system). We saved a bunch of time (reliable Kafka to Kinesis streaming is not a very easy thing to do) and probably found the right approach just by analyzing what's going on below. 

Another example - container scheduling. Containers promise resource isolation, so we should be able to just run a bunch of them in a cluster and not worry about the runtime at all. But in practice, scheduling MySQL, Elasticsearch and a few heavy Java application containers to run on the same node/vm may be a bad idea (of course, depending on its size). You actually need to understand [affinity settings](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/), [proper isolation configuration](https://mesosphere.com/blog/java-container/) and etc. to make it work in a large-scale production environment. 

## Learning to learn

And how do you find time to learn all this underlying tech? Aside from standard learning & development activities (conferences, training, lunch & learns, book clubs, etc.), discovering important concepts one level below and making rational decisions should come naturally (and be included in the *estimates*!) if you have a healthy team culture and a proper project management setup. It is really important if you want to deliver high-quality solutions!
