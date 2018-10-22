---
layout: post
title: "Next-generation data pipelines"
date: 2018-10-21 17:59:53 -0700
comments: true
categories: 
- Thoughts
- Big Data
- Data Pipelines
---

It's Q4 of 2018 and it's really interesting to observe the change in [Big Data Landscape](http://mattturck.com/wp-content/uploads/2017/05/Matt-Turck-FirstMark-2017-Big-Data-Landscape.png), especially around open-source frameworks and tools. Yes, it's still very fragmented, but the actual _solutions_ and _architectures_ start to slowly converge. 

Right now I'm in the beginning of a huge platform redesign at work. We always talk about various frameworks and libraries (which is actually just an implementation detail), but I started to think: what _qualities_ should modern data pipelines have going forward? The list that I came up with is below. 

<!-- more -->

##  Realtime

That's a no-brainer. Everybody wants data, and everybody wants it fast. Forget about nightly batch jobs, and even hourly ones is less than ideal. 

Modern stream processing frameworks like Spark, Flink and Kafka Streams made it possible. And [Kappa architecture](http://milinda.pathirage.org/kappa-architecture.com/) can be used as a real working pattern.

If you look around it seems like stream processing has already became a standard. Everybody assumes we deal with low-latency high-throughput data streams all the time. However, having accurate stateful computations (like 100% correct and historically complete deduplication) is still a huge challenge. I don't think we'll be able to completely avoid writing batch jobs in the near  future.

## Scalable 

We want to build systems that elastically scale to 10s, 100s, 1000s and 10000s of messages per second without investing resources in redesign every order of magnitude. Systems like Kafka and Cassandra use partitioning and replication, which means no single point of failure, and that makes scaling almost effortless. 

Except nothing is effortless in software engineering, especially  in Big Data 😉 Even though Spark can run thousands of nodes and Kafka can use hundreds of brokers you can still easily hit the limit of open TCP connections or exhaust network. At least the concepts and frameworks seem to be applicable for any scale.

## Self-serve 

This one may be a surprise, but it's a very popular trend nowadays. Designing and building a data pipeline is not enough anymore, data teams don't want to be a middle-man between the data and customers. Most of the requests can and should be automated. 

Self-serve UIs solve the problems with data discovery, data lineage (more about that below), capacity planning. They provide automation for simple requests, report the health status of the whole system, show basic monitoring, etc. 

Unfortunately every company has to implement one from scratch. To make self-serve UI very efficient a lot of customizations are required. How to expose the data model? Granularity? What level of permissions is required? There are so many questions to answer and it feels like only a rigid iterative development can handle the complexity, slowly.

## Traceable

Being able to understand the complete flow of data is priceless. How do we populate that Hive table? Who created this Kafka topic? What is the schema for this data stream? 

Modern Data Catalog should be able to answer all these questions. Data linage is an important topic not only from a business owner perspective, it also can be used for debugging, auditing and compliance purposes. 

I will keep saying that Schema Registry (integrated with the Data Catalog) must be part of any data-driven system.

## Secure & anonymous

Our new reality, GDPR. Not considering customer's privacy is illegal. Which means a significant focus on data auditing, security (in so many levels) and preventing exposure of customer's data. 

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">Love this quote from <a href="https://twitter.com/intensivedata?ref_src=twsrc%5Etfw">@intensivedata</a> book, we should always keep that in mind. <a href="https://t.co/7EgTInUFXI">pic.twitter.com/7EgTInUFXI</a></p>&mdash; Yaroslav Tkachenko (@sap1ens) <a href="https://twitter.com/sap1ens/status/995506242851225600?ref_src=twsrc%5Etfw">May 13, 2018</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

It makes me think from a different perspective. I've never cared about my own online privacy too much, but I can clearly understand other people's will to have it.

Also, being "secure" is such a vague concept. Not for a CISSP, but a typical intermediate Software Engineer struggles a lot... Our responsibility is to understand actual steps applicable to the tech we use and execute them no matter what. You probably have no idea how much tools can break when you go from a standard Kafka cluster to SSL-encrypted Kafka cluster, but nevertheless we should do it (and fix everything along the road, but that's what we're paid for anyway, right?). 

<br />

---

<br />

I'm so exited to check this list in 6-12 month and compare what I'll actually accomplish with my current expectations. Wish me luck 🤞
