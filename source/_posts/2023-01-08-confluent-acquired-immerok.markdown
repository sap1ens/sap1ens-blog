---
layout: post
title: "Confluent acquired Immerok: what does it mean?"
date: 2023-01-08 11:27:32 -0800
comments: true
categories: 
- Flink
- Streaming
- Confluent
---

On January 6th, [Confluent announced its acquisition of Immerok](https://www.confluent.io/blog/cloud-kafka-meets-cloud-flink-with-confluent-and-immerok/). [Immerok](https://www.immerok.io) is a brilliant group of core Apache Flink engineers who have been building a managed Apache Flink offering.

This is an important acquisition for Confluent. Confluent's CEO, Jay Kreps, mentioned in the announcement that "Flink is the future of stream processing." In this post, I'll try to understand what it means for Confluent, Flink and the industry in general.

<!-- more -->

## What Confluent bought

I've used Immerok's existing early product, and I believe Confluent did not buy the company because of the product. It's impressive what the Immerok team has built over the last ~9 months; however, any capable team can build a similar product using the [Flink Kubernetes Operator](https://github.com/apache/flink-kubernetes-operator) nowadays. Of course, Immerok was planning to add a bunch of proprietary features like smart autoscaling and powerful SQL experience, but as far as I know, they were many months away.

It seems to me that Confluent decided it was the right time to start offering Flink as a product and acquiring a talented team to build it was the most straightforward option.

## Why now?

I think it became too hard to ignore Flink. Maybe the most recent [Current conference](https://www.confluent.io/events/current-2022/) showed Confluent that a lot of customers don't want to use Kafka Streams/ksqlDB. Flink has a fantastic adoption in the big tech companies, and offering it as a managed product for small and medium companies makes a lot of sense now. As an additional validation, there are now several companies founded in the last 1-2 years (Decodable, DeltaStream, Popsink) trying to do precisely that.

I've also seen a message in the Flink mailing list from one of Confluent's Principal engineers in early November:

> We're doing more and more Flink development at Confluent these days and we're currently trying to bootstrap a prototype that relies on the SQL Client and Gateway.

That engineer has previously worked in big tech companies using Flink, so I guess there was some desire to move to Flink from within.
It's also interesting to note that the first Flink product that Confluent has announced is SQL-based. Based on the message from the mailing list, they've been working on that for at least a couple of months already...

## Changes in Confluent's technical direction

Confluent's technical direction and its business model have been tightly coupled so far. So I can formulate their primary goal as "selling more Kafka," and all their major technologies like Kafka Connect, Kafka Streams, and ksqlDB, try to ensure you spend as much money on Kafka as possible:

- Kafka Connect makes it easy to stream data from external systems to Kafka, as well as stream data from Kafka to external systems. This design is marketed as a "simple" approach in data integration: instead of creating a bunch of point-to-point connections between different systems, Kafka is used as a central hub that connects everything together. It makes a lot of sense in theory. However, in practice, it doesn't make sense for everything: some datasets could be huge and pretty expensive to move to Kafka (tiered storage helps in this case), and some data pipelines, surprisingly, could be much simpler to maintain *without* Kafka (more on that below). Also, since Kafka Streams only supports Kafka as a source and a sink, Kafka Connect is necessary for any complex data pipeline involving Kafka Streams. Now, about Streams...
- Since its inception, Kafka Streams has had two major design flaws that are covered in [this blog post](https://www.jesse-anderson.com/2019/10/why-i-recommend-my-clients-not-use-ksql-and-kafka-streams/). To summarize here: Kafka Streams leverage Kafka for failure recovery and shuffles. In both scenarios, it means using internal Kafka topics. And I've seen how a few stateful transformations can easily explode your Kafka bill by 3x - 5x, all thanks to the usage of internal topics as an implementation detail (you may need to process your input data multiple times).

So, even though some of these design decisions might look questionable in some use cases, they make a lot of sense if your goal is selling more Kafka.

Now, by adding Flink to the mix, you're potentially reducing Kafka usage. Flink's shuffle implementation is purely network-based. Flink's failure recovery depends on an object store like AWS S3. Flink also has a very mature (although smaller) collection of connectors, which makes Kafka Connect obsolete. Hell, you can even use Flink without Kafka altogether! For example, I genuinely believe that a CDC source connector with an Elasticsearch sink connector for maintaining a search index is a way simpler and more reliable setup than the alternative with Kafka, Kafka Connect and Debezium.

It's hard to say how Confluent will balance Kafka Connect, Kafka Streams/ksqlDB and Flink usage in order not to lose a notable chunk of revenue. It seems to me that with a fully managed Flink product, almost no one will choose Kafka Streams/ksqlDB over it. However, combining Kafka Connect for data integration and Flink for data processing (primarily via source and sink Kafka connectors) can be a viable combo. If I were Confluent, I would not even support Flink connectors other than the Kafka one in the beginning.

## What does it mean for Flink?

Running Flink is challenging. And the existing managed Flink offerings are just not good enough. So I hope that with Confluent's support, the adoption of Flink (and streaming in general) will grow, which is great news for the industry.

I also hope that Confluent will invest more in Flink's Kafka connector. It can work well, but there is a surprising amount of small features that are either missing or not working as well as they should. The whole developer experience around the Schema Registry usage, Avro support, etc., can also be improved. 

## Conclusion
I don't have a crystal ball, but it's clear to me that no other streaming technology will be able to compete seriously with Flink in the next 2-3 years. So I agree with Jay Kreps here - Flink is the future of stream processing. And Confluent's bet on Flink makes a lot of sense since Confluent is trying to cement its place as the leading company in the streaming space.

*Thanks to Jeff Ling for reviewing the draft of this post.*