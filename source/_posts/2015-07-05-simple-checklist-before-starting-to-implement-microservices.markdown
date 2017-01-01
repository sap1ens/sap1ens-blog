---
layout: post
title: "Simple checklist before starting to implement microservices"
date: 2015-07-05 20:53:20 -0700
comments: true
categories:
- Microservices
---

Over the last few months I’ve seen so many questions about microservices from people who *clearly* don’t need them. Or just not ready yet. So I made this simple checklist, if you answered “no” at least once - you’re not ready for microservices architecture right now. Please don’t feel [Microservice envy](http://www.thoughtworks.com/insights/blog/are-you-infected-microservice-envy) :)

1. Do you understand Domain Driven Design? Can you split your system in a set of services with clear boundaries?
2. Do you understand how and when to use synchronous and asynchronous communication?
3. Do you agree to have eventual consistent data in your system?
4. Do you use modern DevOps practices to have automated configuration management, continuous deployment, health checks & autoscaling, monitoring & alerts, etc.?