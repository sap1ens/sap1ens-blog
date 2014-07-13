---
layout: post
title: "Microservice with Akka, Spray and Camel"
date: 2014-07-13 15:44:37 -0700
comments: true
categories:
- Scala
- Akka
- Spray
---

[Microservices architecture](http://wayfinder.co/pathways/53536427f7040a11002ae407/a-field-guide-to-microservices-april-2014-edition) is a popular trend right now. I don't want to repeat anything about microservices in general, but instead I want to introduce an example of a microservice based on Akka, Spray and Camel.

**[akka-microservice](https://github.com/sap1ens/akka-microservice)** is based on one of the Typesafe Activator templates, but it's very simple and very easy to learn - just go and checkout the codebase. It doesn't contain any front-end parts, just pure Scala.

Application has a lot of handy stuff:

- Easy to test Akka system with a sample actor
- Spray-based RESTful API with full [CORS](http://en.wikipedia.org/wiki/Cross-origin_resource_sharing) support
- Actor and API sample tests
- Camel/ActiveMQ extension for a handy integration with Akka system
- Typesafe config with different profiles for production and testing environments
- Logback-SLF4J logging
- Sbt assembly plugin for JAR-file creation with custom merge strategy

So it's focused more on production usage, you can just take the project, rename a few files & packages and it's ready to be deployed! Just write your actors and routes. Happy hAkking! :)
