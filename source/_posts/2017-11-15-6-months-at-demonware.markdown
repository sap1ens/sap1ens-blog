---
layout: post
title: "6 months at Demonware"
date: 2017-11-15 21:05:43 -0800
comments: true
categories:
- Demonware
- Me
- Thoughts
---

You can probably decide I'm busy based on the absence of any new posts since July :)

And indeed, I was pretty busy for a while. I started to work at Demonware precisely 6 months ago and it's being an amazing ride so far.

<!-- more -->

My team is responsible for Demonware/Activision data pipeline, metrics and logs. I'm mostly focused on the data pipeline, but also slowly learning the metrics side (I'm pretty familiar with Datadog, but I've never worked with Grafana/Graphite at scale).

I joined Demonware to work on large-scale systems and all my expectations were met!

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">Proud of my team at <a href="https://twitter.com/demonware?ref_src=twsrc%5Etfw">@demonware</a>, we&#39;ve been handling tens of thousands msg/s in our data pipeline for <a href="https://twitter.com/hashtag/CODWWII?src=hash&amp;ref_src=twsrc%5Etfw">#CODWWII</a> launch without any issues 🙌</p>&mdash; Yaroslav Tkachenko (@sap1ens) <a href="https://twitter.com/sap1ens/status/927293945914073088?ref_src=twsrc%5Etfw">November 5, 2017</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

Yes! Tens (and sometimes hundreds) of thousands of messages per second in our pipeline, which contains data from many Call Of Duty titles. My work so far included the core Kafka infrastructure, various consumers, stream processing with Kafka Streams and a [POC project with Kafka Connect, S3 and Athena](https://www.slideshare.net/sap1ens/querying-data-pipeline-with-aws-athena).

By the way, my team is great! We have A LOT of freedom and autonomy. I used to work in startups before and the pace feels completely different, but it's a good change (like actually spending time to investigate, learn, build a POC, etc. instead of shipping straight to prod asap, you know 😉).

Finally, Demonware runs A LOT of infrastructure, starting from the racks in a data centre. So I have a chance to work with bare-metal servers, VMs using OpenNebula and a ton of adhoc Ubuntu and Centos work, which is pretty great, since my Linux server skills were never really sharp.

Sounds awesome so far? Yeah, also don't forget great benefits, very flexible work policy and plenty of AAA games to work with (I found myself in the CoD WW2 credits!).

Downsides? Activision is a huge company and we have different departments that use all the data we collect to do all kinds of data warehousing and data analysis. My team still does a lot of processing and I hope we'll do even more, but I'd love to work on the stream processing projects with broader scope, eventually.

I want to finish up with a wisdom from my colleague:

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">&quot;You can always come up with a reason for one more Kafka cluster&quot; (c) <a href="https://twitter.com/mtrienis?ref_src=twsrc%5Etfw">@mtrienis</a></p>&mdash; Yaroslav Tkachenko (@sap1ens) <a href="https://twitter.com/sap1ens/status/928759475359453185?ref_src=twsrc%5Etfw">November 9, 2017</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
