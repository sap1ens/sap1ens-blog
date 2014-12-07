---
layout: post
title: "State &#8733; 1 / Scale"
date: 2014-12-06 15:53:48 -0800
comments: true
categories:
- Thoughts
- Software Design
---

From [Java Doesn’t Suck – You’re Just Using it Wrong](http://www.jamesward.com/2014/12/03/java-doesnt-suck-youre-just-using-it-wrong):

> Sticky sessions and server state are usually one of the best ways to kill your performance and resilience. Session state (in the traditional Servlet sense) makes it really hard to do Continuous Delivery and scale horizontally. If you want a session cache use a real cache system – something that was designed to deal with multi-node use and failure. e.g. Memcache, ehcache, etc. In-memory caches are fast but hard to invalidate in multi-node environments and are not durable across restarts – they have their place, like calculated / derived properties where invalidation and recalculation are easy.

> Web apps should move state to the edges. UI-related state should live on the client (e.g. cookies, local storage, and in-memory) and in external data stores (e.g. SQL/NoSQL databases, Memcache stores, and distributed cache clusters). Keep those REST services 100% stateless or else the state monster will literally eat you in your sleep.

It's easy to follow the rule, but if you didn't... :-/

Server state is very hard to fix, it requires massive refactoring and additional tools sometimes. Personally, I've realized that it'll be my rule #1: avoid state as much as you can.