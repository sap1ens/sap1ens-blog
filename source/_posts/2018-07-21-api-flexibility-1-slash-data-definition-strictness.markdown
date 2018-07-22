---
layout: post
title: "API Flexibility ∝ 1 / Data Definition Strictness"
date: 2018-07-21 21:41:59 -0700
comments: true
categories: 
- Thoughts
- Software Design
---

An interesting observation based on the recent conversations at work: the more strict the data format used in the API definition, the harder it is to change the API behaviour later. And vice versa, it's easier to change the APIs that use flexible data formats. 

<!-- more -->

Why do so many startups use JSON? Sure, it's obvious with web applications, but how do you explain sending it to Kafka, using in serverless systems, service-to-service communication in microservices and even infrastructure-as-code tools (looking at you, AWS CloudFormation)?

It's because startups need that flexibility that JSON brings. You need to send an extra field? Sure, we'll accept it. Change field type? Might work. Add huge nested object to the payload? Why not.

Of course, even with JSON you still need to think about versioning, backward- and forward-compatibility, etc., but it's **so much easier**!   

Unfortunately you have to pay the price. Without solid automation and versioning strategy releases in synchronous JSON API-based microservices turn into nightmares. Integers are used as enums and strings are used as booleans. All kinds of fun stuff!

On the other hand, we also have Thrift, Protocol Buffers and similar solutions. These data definition formats can actually **enforce** most of the things you want to enforce. They're binary, so occupy less space, usually faster to serialize/deserialize and have a proper schema evolution rules. But almost zero flexibility. Every schema must be explicitly defined (and ideally added to the Schema Registry), even slightest mismatch triggers serialization exception. But you can be **absolutely** sure that not a single producer will be able to produce incorrect data. 

There are also intermediate solutions, for example JSON Schema. Lots of nuances that should be taken into consideration, but great attempt to get more enforcement in JSON world. Avro is an attempt to improve the situation from the other side.

What do you choose? As usual, it depends. But I have a feeling that I'm starting to be a big fan of strict data formats 😉
