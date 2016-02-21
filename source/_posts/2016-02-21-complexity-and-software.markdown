---
layout: post
title: "Complexity and software"
date: 2016-02-21 11:58:28 -0800
comments: true
categories:
- Thoughts
- Software Design
---

Software engineers like to discuss different aspects of their craft: elegant solutions, performance benchmarks, semantics of programming languages, the shortest webapp implementation with a favourite framework, etc. We like to argue why language X is better than Y and why framework A is faster/simpler/better to use than B.

Something that we don’t usually discuss is complexity. The important thing to realize: we can’t remove it. We can try to hide it, yes. But any relatively big system has complexity in some form, on some level.

As an example, let’s take a look at popular Sinatra-inspired web frameworks: Flask, Express, etc. It’s **really** simple to create a small webapp or RESTful API. Very simple. So simple that the whole implementation fits on one screen. But still, they hide complexity. Try to run them on multi-core and multi-node cluster efficiently and reliably. That should be relatively “easy” to do, until your application has a state or you discover that not everything is thread-safe. Fun stuff. Distributed systems are hard.

Ok, how about the other side now. Toolkits like Erlang/OTP or Scala/Akka are considered to be complex and suited for building distributed systems. They move complexity to a different edge, so bootstrapping takes much more time, but “hard” problems are actually easier to solve. [Cluster Singleton](http://doc.akka.io/docs/akka/2.4.2/scala/cluster-singleton.html) or [Cluster Sharding](http://doc.akka.io/docs/akka/2.4.2/scala/cluster-sharding.html)? Yep, it’s there!

The same concept applies to programming languages. Everything has pros and cons. Complexity should always be an additional dimension that we should take into consideration, discuss it and plan accordingly.