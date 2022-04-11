---
layout: post
title: "Why I’m Joining Goldsky, a Web3 Company"
date: 2022-04-11 11:44:46 -0700
comments: true
categories: 
- Goldsky
- Web3
- Streaming
---

Today I join [Goldsky](https://goldsky.io) as a Principal Software Engineer. Goldsky’s mission is to make it easy to index, process and use blockchain data. This set of tools could become a foundational building block for many Web3 companies. We leverage streaming SQL to make it possible.

<!-- more -->

## Web3?

I’ve never been a crypto, NFT or web3 enthusiast. Quite the opposite, I was (and I am) very skeptical about “web3” as the next iteration of the modern web. I’ve read many critics in this domain:

* [Why it’s too early to get excited about Web3](https://www.oreilly.com/radar/why-its-too-early-to-get-excited-about-web3/)
* [My first impressions of web3](https://moxie.org/2022/01/07/web3-first-impressions.html)
* [Web3 is Bullshit](https://www.stephendiehl.com/blog/web3-bullshit.html)
* [David Rosenthal’s EE380 Talk](https://blog.dshr.org/2022/02/ee380-talk.html)
* [Line Goes Up – The Problem With NFTs](https://www.youtube.com/watch?v=YQ_xWvX1n9g)
* Hell, I even follow Grady Booch on Twitter 😀…

I’m no expert in this area, but after being briefly exposed to the world of web3 for a few months I can already see that some of the arguments are not that relevant anymore. 

Yes, bitcoin is terribly energy inefficient, but have you seen modern proof-of-stake protocols like [Polkadot](https://polkadot.network/)? 

Yes, many NFTs could be scams, but I _truly believe_ that NFTs and online gaming may be a great match, as an example (can I show off my legendary World of Warcraft NFT sword in Call of Duty, please?). 

Many people claim that web3 doesn’t _actually_ solve any problems, everything can be done with more conventional ways and approaches. I think it’s true for many projects, but I do have a few favourite examples where decentralization provided by blockchain actually makes sense: [Helium](https://www.helium.com), [Render Network](https://rendertoken.com), [Arweave](https://www.arweave.org). Don’t you agree?

Finally, one of the strongest arguments against web3 is that true decentralization is really hard to achieve. And what we see with the most popular chains is actually centralization in the hands of a few parties. This is a tough one, but it’s not a purely technological one. However, _permissionless_ blockchains are not the only type of blockchains out there… 

_Permissioned_ (or private, or “enterprise”) blockchains are not something many critics focus on. As a person who worked in a bookkeeping startup early in my career, I started understanding the importance of distributed immutable ledgers many years ago. Blockchain, as a data structure, provides an elegant implementation for that. Private, permissioned blockchains don’t need to be fully decentralized, so there are no concerns about ownership or performance. But they still provide the same set of features (e.g. smart contracts) and qualities (e.g. auditability). Private, permissioned blockchains also provide [Byzantine fault tolerance](https://en.wikipedia.org/wiki/Byzantine_fault), which can be important for large enterprises, governments, military, etc. 

A badly written and inefficient [dApp](https://en.wikipedia.org/wiki/Decentralized_application) is easy to criticize. A shady startup stealing crypto from its users is a loud news story. Etc. Etc. It may be easy to dismiss the whole web3 world, but maybe we just don’t see enough successes yet? Blockchain itself is just another tool and we need to understand when and how to apply it. Even if 90% of all web3 products will shut down in the next 2 years I’d be excited to focus on the 10% that survived that might actually be life-changing.

## Streaming SQL?

When you start thinking about processing blockchain data, using stream-processing seems like a great idea:

* Blockchain data is (mostly, more about this next) immutable. It’s easy to persist the whole blockchain in a streaming platform like Apache Kafka.
* Blockchain reorganization can be formulated as a problem of late-arriving data and retractions.
* Even the most popular blockchains are not that big when it comes to data size: hundreds of gigabytes or single-digit terabytes. This is easy to handle with modern data tools.
* Stream-processing provides functionality to perform merging, joins and lookups, aggregation and windowing. Also, stream-processing and, more widely, modern data tools, allow combining on-chain data with off-chain data seamlessly. For example, think about ingesting data from your relational database, joining it with blockchain data, then aggregating and writing to a data lake or data warehouse of your choice.

And I see how SQL becomes a standard for stream-processing right now. There are many big players (Confluent, Materialize) and many young startups (Decodable, Popsink, DataCater, Singularity Data, Tinybird, etc.) who realized that SQL is a perfect language for describing transformations, even complex stateful ones.

## Goldsky?

Goldsky is not trying to be a solution to every web3 problem. Instead, we want to provide a solid platform for other companies to use blockchain data. Building high-quality web3 products is hard right now, partially because the tools and practices are so immature. But we see this as a great opportunity. 

Finally, we’re hiring 😉. Ping me if you’re interested!
