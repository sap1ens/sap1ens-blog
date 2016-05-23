---
layout: post
title: "Static typing and refactoring"
date: 2016-05-22 20:37:31 -0700
comments: true
categories:
- Thoughts
- Refactoring
---

A few months ago I finished a **huge** refactoring of a Java/Scala project. It took 2 weeks and only 2 engineers to actually implement all the changes, make sure it worked and deploy. Surprisingly, deployment was *really* smooth, we didn’t encounter any major issues.

I think the reason why it went so good was statically typed language + amazing IDE support for that. I can’t imagine doing similar refactoring in Ruby/Python/Node, for example.

{% img /images/posts/refactoring.png %}

<!-- more -->

## The task

Project consists from multiple layers:

1. HTTP API and serialization/deserialization logic (Scala/Jersey)
2. Service layer (Scala/Java/Spring)
3. Model (Java/Hibernate/AspectJ)
4. Database (MySQL)

Our goal was to refactor a bunch of model/database fields, mostly renaming (things like `TransactionalDocument.TransactionalDocumentId` -> `JournalEntry.id`). As you can see it mostly affects model and database layers, but the same fields are used in service level as well as API serialization/deserialization logic - basically the whole system is affected.

## Refactoring

First of all, we divided all model classes between 2 engineers and started to deal with classes one by one.

Our toolkit included IntelliJ IDEA and some shell automation for applying database schema and changesets.

Process was simple - rename model field using IntelliJ IDEA refactoring feature, rename database field in a schema file and verify your changes by:

- compiling the project (minute[s])
- recreating database from schema and changesets (seconds)

A few words about IntelliJ IDEA: I’ve been using this IDE for years and I’m so thankful to Jetbrains for this amazing piece of tech (and also I’m a little bit proud, since it’s built by smart Russian guys). Because Java and Scala are statically typed languages, IDE is able to trace *every single usage of a type or a field*, including all layers I mentioned. You just run rename command, confirm all changes in preview, if changeset is large, and apply it in seconds! And you can be absolutely sure that all changes are correct.

One more lesson from this exercise - it’s always a good idea to NOT expose your model fields directly in API. We have an explicit serialization/deserialization logic in that project and I didn’t have to also refactor front-end app (which is mostly Coffeescript) - so good! ;)

Also I want to notice that compilation was enough to test changes, I didn’t even need to run the app to check intermediate results. It allowed us to iterate as fast as possible (which was not really fast, because it runs **3** compilers internally: AspectJ, Java and Scala).

We obviously had a huge set of tests (hundreds) + some things could’ve been tested only in runtime (like Spring configuration), but again: you can mostly rely on IDE/compilation to make sure everything works smoothly. Which is an amazing feeling :)

By the way, tests actually helped to discover something that IDE has missed. We use Hibernate and write all queries using JPQL. These queries are represented by simple strings, but IntelliJ IDEA is mostly able to parse those strings and understand actual classes and fields used there. I said mostly, because for some reason sometimes it missed some of the queries and we only could detect those using tests.

## Summary

So, if you’re planning to work on a big refactoring I advice:

- Understand the easiest way to verify your changes. If you use a statically typed language, compilation is usually enough, but you should always have tests to cover your main code paths
- Make sure you know how to make iteration loop as fast as possible using previous verification step. Refactoring always needs time and it’s important to optimize your workflow
