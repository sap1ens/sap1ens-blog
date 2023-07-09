---
layout: post
title: "Heimdall: making operating Flink deployments a bit easier"
date: 2023-07-09 19:07:00 -0700
comments: true
categories: 
- Flink
- Streaming
---

I want to introduce [Heimdall](https://github.com/sap1ens/heimdall): a dashboard for operating Flink jobs and deployments. I've been working on it for the last several weeks, and we've been using it in [Goldsky](https://goldsky.com) to manage 100+ Flink deployments.

First of all, why is it needed? Doesn't Flink come with a built-in UI? It does, and Heimdall doesn't try to replace it. Flink UI is amazing for managing a single job. It can also work great at managing multiple jobs deployed on the Session mode cluster. However, nowadays, especially when using Kubernetes, most of the teams choose to deploy Flink as many standalone jobs in Application mode (as "services"). And when you're running more than a handful of jobs, tracking them and navigating between them becomes challenging.

Heimdall is still in its infancy - it's a read-only application with some very basic functionality (mostly on the front-end) and it currently only supports jobs deployed with the [Flink Kubernetes Operator](https://github.com/apache/flink-kubernetes-operator). But I believe that, with time, it can be improved and turned into a full-fledged control plane. And even in its current form, it can be extremely useful and save a lot of time.

<!-- more -->

## Features

{% img /images/posts/heimdall-demo.gif 800 %}

- Each job is displayed with its name, status, JobManager and TaskManager resources, start time, parallelism, Flink version and Docker image version (some of these can be hidden).
- Flink jobs can be searched by name, filtered using the status.
- Flink jobs can be sorted by name, start time and resources (replica count).
- Flink jobs are automatically refreshed (the interval is configurable).
- Four standard endpoints are available for each job: Flink UI, Flink API, Metrics and Logs (all configurable).

## Configuration

All options can be found [here](https://github.com/sap1ens/heimdall#configuration). In general, you don't need to do much.

- `HEIMDALL_JOBLOCATOR_K8S_OPERATOR_NAMESPACE_TO_WATCH` is needed to specify the Kubernetes namespace to watch (no need to configure it if you use `default`).
- `HEIMDALL_PATTERNS_DISPLAY_NAME` can be used to modify the displayed job name using the metadata. Metadata is currently obtained from the Kubernetes labels. For example, at Goldsky, we use the following pattern: `$jobName ($metadata.streamName)`.
- `HEIMDALL_ENDPOINT_PATH_PATTERNS_*` are four variables that can be used to configure endpoints for accessing Flink UI, Flink API, metrics and logs for each Flink job. `$jobName` is replaced with the actual Flink job name for every row. Every company may deploy Flink differently when it comes to networking; every company may have a different observability tool. So instead of trying to support every way, Heimdall simply exposes a set of URL patterns in the config.

## Why "Heimdall"?

- I love Norse mythology.
- _[Heimdall] is attested as possessing foreknowledge and keen senses, particularly eyesight and hearing_ - sounds like a great fit for what this project is trying to achieve 🙂.

## Feedback

Please provide feedback! Something's not working? Have an idea? Feel free to [create an issue](https://github.com/sap1ens/heimdall/issues).
