---
layout: post
title: "Actors, Streams and Futures in Akka: what to use?"
date: 2015-10-25 16:40:54 -0700
comments: true
categories:
- Scala
- Akka
---

Akka ecosystem provides a rich set of tools nowadays: you can use classic Akka Actors, well-known Scala Futures or relatively new Akka Streams. Because all these tools can help you to build concurrent applications you might start comparing them. Or even [say that Actors are bad and Streams are much better](http://eng.localytics.com/akka-streams-akka-without-the-actors/).

I think that every approach has its own use cases, as well as pros and cons.

<!-- more -->

**Actors model** has two major advantages: control flow and state.

Control flow is very natural to Actor models, you can express quite complicated algorithms with relatively simple Actor structures. Supervision hierarchy helps to make this structure resilient. Also, Actor can be a structural unit that maps nicely to a Service from DDD.

So, it’s possible to design the whole application using Actors. Streams and Futures usually handle only parts of the application business logic.

Stateful actors is a powerful concept. Akka Clustering, Persistence and Distributed Data intend to use internal Actor state, coordinated or replicated in different forms. Streams and Futures also have state, but short-lived, usually.

**Streams** were created to handle asynchronous data pipelines with non-blocking back pressure. So it’s the best tool to use for any kind of data processing, file transformations, ETL pipelines, messaging and eventing solutions.

It looks like an overkill to use Streams for simple asynchronous tasks, Futures seem to be a better option.

**Future** is the simplest concurrency mechanism in the Akka world. It’s just an asynchronous task with a timeout. It can be used to run a processes in background or to be a connection between other tools. For example, Actors can use “ask” pattern to return a Future as a result of a communication between them. It’s also possible to “pipe” results of a Future back to an Actor. And Streams can return Futures as a result of materialization.

Instead of a conclusion: JVM and Akka ecosystems have very rich concurrency tools and it’s important to realize advantages, disadvantages and ways to combine them with each other.