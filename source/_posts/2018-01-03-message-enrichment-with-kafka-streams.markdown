---
layout: post
title: "Message enrichment with Kafka Streams"
date: 2018-01-03 22:08:29 -0800
comments: true
categories:
- Kafka
- Kafka Streams
---

I've been working with Kafka Streams for a few months and I love it! Here's the [great intro](https://www.confluent.io/blog/introducing-kafka-streams-stream-processing-made-simple/) if you're not familiar with the framework. In the sections below I assume that you understand the basic concepts like `KStream`, `KTable`, joins and windowing.

Message enrichment is a standard stream processing task and I want to show different options Kafka Streams provides to implement it properly.

<!-- more -->

## Scenario 1: enriching using static (or mostly static) data

Let's imagine the following situation: you have a stream of address updates and every message in the stream contains a state (province). You need to enrich this information with sales tax rates. Every state has a different sales tax rate, but this information is not changed very often (may be once a year or once in a few months), so it's practically "static".

In this case you'd need to represent your main stream of updates as a `KStream` and create a `KTable` containing state as a key and sales tax rate as a value. After that it should be pretty straightforward to apply a simple `KStream-KTable` non-windowed join:

```java
KStreamBuilder builder = new KStreamBuilder();

KStream<String, AddressUpdateMessage> addressUpdates = builder
    .stream("address-updates");

KTable<String, SalesTax> salesTaxes = builder
    .table(Serdes.String(), new SalesTaxSerde(), "sales-taxes");

addressUpdates
    .selectKey((key, value) -> value.getStateCode())
    .join(salesTaxes, (addressUpdateMessage, salesTax) -> {
        addressUpdateMessage.setSalesTax(salesTax.getTax());
        return addressUpdateMessage;
    })
    .selectKey((key, value) -> value.getId())
    .to("address-updates-enriched");

KafkaStreams streams = new KafkaStreams(builder, getSettings());
streams.start();
```

If, for some reason, a sales tax entry could not exist for a particular state, we can use a `leftJoin` operation and have a fallback value or just ignore the enrichment in this case, using something like this:

```java
    // ...
    .leftJoin(salesTaxes, (addressUpdateMessage, salesTax) -> {
		    if (salesTax != null) {
	          addressUpdateMessage.setSalesTax(salesTax.getTax());
		    }
		    return addressUpdateMessage;
    })
    // ...
```

Still, there is an issue with this implementation. Because address update stream and sales tax stream have different message IDs we need to repartition one stream a few times (first - to use the state as an ID, so we can join, second - return back to the address ID).

If our `KTable` is not very big we may use a `GlobalKTable` instead. This type of table doesn't use partitioning and instead just creates a copy of the same table on every processing node.

## Scenario 2: enriching using data sources we control

Let's look at another typical situation: we have a stream of user activity and we need to enrich it with additional user information (like email, address, preferences, etc.). It's very common to only have a user ID in a message, everything else about the user can be found in a dedicated database / API. In this particular case we're lucky, since we also control that database and we can use the following approach:

- Stream all database changes (CRUD) as a changelog, using event sourcing.
- Potentially duplicate a lot of data and introduce eventual consistency (both can be OK)
- In the end, have a separate "view" on user data based on the changelog in Kafka

After that the enrichment itself is trivial:

```java
KStreamBuilder builder = new KStreamBuilder();

KStream<String, UserActivityMessage> userActivity = builder
    .stream("user-activity");

KTable<String, UserData> userData = builder
    .table(Serdes.String(), new UserDataSerde(), "user-data");

userActivity
    .join(userData, (userActivityMessage, userData) -> {
        userActivityMessage.enrich(userData);
        return userActivityMessage;
    })
    .to("user-activity-enriched");

KafkaStreams streams = new KafkaStreams(builder, getSettings());
streams.start();
```

As you can see, we don't need to change the message keys and repartition data, both data streams already use user ID as a key.

And again, if for some reason user data could not be available, `leftJoin` can be used to provide a fallback value or skip the enrichment (take a look at the previous section).

## Scenario 3: enriching using data sources we don't control

Finally, the most complicated example. Imagine the same user activity stream like in the previous section. Now, every message contains an IP address and we want to do a simple ip2location transformation. So, every time we see an address like `70.36.48.201` we want to enrich the message with `Vancouver, British Columbia, Canada`.

The ip2location transformation itself is just an example and it can be done with a lot of free and commercial APIs, for example:

> http://ip-api.com/json/70.36.48.201

For your use cases you may need to call some other APIs, for example your billing system, CRM, etc. But it's just the same problem in the end - you don't control it, so you can't emit changeset events like in the previous section.

### Scenario 3a: naive solution

So, how do we go about this? Here's a very naive solution:

```java
KStreamBuilder builder = new KStreamBuilder();

KStream<String, UserActivityMessage> userActivity = builder
    .stream("user-activity");

userActivity
    .map((key, value) -> {
        String location = Ip2LocationConverter.getByIp(value.getIpAddress());
        value.setLocation(location);
        return new KeyValue<>(key, value);
    })
    .to("user-activity-enriched");

KafkaStreams streams = new KafkaStreams(builder, getSettings());
streams.start();
```

This implementation is going to kill the throughput! Because we need to call an external API for **every** single message in our stream, which is very expensive. Also, what happens when the call fails? We need to think about proper error handling, retries, etc.

BTW: Apache Flink has a special [Async I/O](https://ci.apache.org/projects/flink/flink-docs-release-1.3/dev/stream/asyncio.html) API to make this option actually usable.

### Scenario 3b: caching

The implementation above can be slightly improved by introducing an internal cache. So, every time we need to call an external API we're going to check the cache first, then call the API if nothing found. This implementation is still relatively simple, but can be a good fit for some use-cases.

Kafka Streams provide [state stores](https://docs.confluent.io/current/streams/architecture.html#state) for managing state in an efficient and reliable way. Let's implement a low-level Processor for the stateful enrichment:

```java
public class EnrichmentProcessor implements Transformer<String, UserActivityMessage, KeyValue<String, UserActivityMessage>> {
    public static final String STORE_NAME = "IP_LOCATIONS";

    private KeyValueStore<String, String> ipLocationsStore;

    public static StateStoreSupplier createStateStoreSupplier() {
        return Stores.create(EnrichmentProcessor.STORE_NAME)
            .withKeys(Serdes.String())
            .withValues(Serdes.String())
            .persistent()
            .build();
    }

    @Override
    public void init(ProcessorContext context) {
        this.ipLocationsStore = (KeyValueStore<String, String>) context.getStateStore(STORE_NAME);
    }

    @Override
    public KeyValue<String, UserActivityMessage> transform(String key, UserActivityMessage msg) {
        String ipAddress = msg.getIpAddress();

        String location;
        String locationInStore = ipLocationsStore.get(ipAddress);

        if(locationInStore == null) {
            location = Ip2LocationConverter.getByIp(ipAddress);

            ipLocationsStore.put(ipAddress, location);

            logger.info("Adding new record to the store {} -> {}", ipAddress, location);
        } else {
            location = locationInStore;
        }

        msg.setLocation(location);

        return new KeyValue<>(key, msg);
    }

    // ...
}
```

And here's how you would use it:

```java
KStreamBuilder builder = new KStreamBuilder();

StateStoreSupplier ipLocationsStoreSupplier = EnrichmentProcessor.createStateStoreSupplier();
builder.addStateStore(ipLocationsStoreSupplier);

TransformerSupplier<String, UserActivityMessage, KeyValue<String, UserActivityMessage>> enrichmentProcessorSupplier =
    EnrichmentProcessor::new;

KStream<String, UserActivityMessage> userActivity = builder
    .stream("user-activity");

userActivity
    .transform(enrichmentProcessorSupplier, ipLocationsStoreSupplier.name())
    .to("user-activity-enriched");

KafkaStreams streams = new KafkaStreams(builder, getSettings());
streams.start();
```

We create suppliers for the state store and the processor and then the processor is applied to all messages using `transform` operation.

This would work as we expected: every time a new IP address is observed it'll take a bit of time to do the API call, but after that the `transform` step should be instantaneous.

Our state store is also backed by local RocksDB database and changelog Kafka topic, so it's pretty reliable.

Final thing to note here: the state store we create in this example is going to grow all the time (which might be ok for some use-cases). If you're not happy with that you could use a window state store ([great example here](https://github.com/confluentinc/kafka-streams-examples/blob/4.0.0-post/src/test/java/io/confluent/examples/streams/EventDeduplicationLambdaIntegrationTest.java)) and a retention period like 1 hour or 1 day.

### Scenario 3c: separate stream for extraction

Our implementation using the cache and a low-level processor may not be good enough if we want to process all messages as soon as possible, without blocking on external API calls.

So, in this case, we can create a separate stream of data, extracted from a source one. Once this stream is enriched it's joined back with the original one. In the end, it's actually a bit more complex than that. Here's the complete diagram (four Kafka topics in total):

![](https://docs.google.com/drawings/d/e/2PACX-1vTpZt66ElpDjH-VuSdq0R3SDCpjbfTmurfkT8ZOcGknTlPJKqqIeR0cdb8bAXtNvuvHXzeGgzHLXSBZ/pub?w=652&h=517)

First, we would extract IP addresses to a separate topic:

```java
KStreamBuilder builder = new KStreamBuilder();

KStream<String, UserActivityMessage> userActivity = builder
    .stream("user-activity");

userActivity
    .map((key, value) -> new KeyValue<>(value.getIpAddress(), new IpLocationMessage(value.getIpAddress())))
    .to(Serdes.String(), new IpLocationMessageSerde(), "ip-addresses");

KafkaStreams streams = new KafkaStreams(builder, getSettings());
streams.start();
```

`IpLocationMessage` is just a little container class with IP address and location (empty string as a default) fields.

After that we can apply the snippets from `Scenario 3b` to enrich this stream and write results as the IP locations stream.

Now we need to join the original user activity stream and the enriched ip locations. But here's the problem - we can't use `KTable` to represent ip locations stream. Because if we do, we could easily miss a match in a join (and drop some messages), since it takes some time to do an external API call and `KTable` will probably not contain all required enriched IP locations right away.

Solution: use windowed join! In this case, even if the right side of a join is not immediately available, Kafka Streams topology is smart enough to wait up to a window size for a match. And we just need to make sure to make the window wide enough for that.

Unfortunately, Kafka Streams doesn't provide windowed joins between `KStream`s and `KTable`s! So, we'll have to join two `KStream`s:

```java
final Long JOIN_WINDOW = TimeUnit.SECONDS.toMillis(60);

// ...

KStreamBuilder builder = new KStreamBuilder();

KStream<String, UserActivityMessage> userActivity = builder
    .stream("user-activity");

KStream<String, IpLocationMessage> locations = builder
    .stream(Serdes.String(), new IpLocationMessageSerde(), "ip-locations");

userActivity
    .selectKey((key, value) -> value.getIpAddress())
    .join(locations, (userActivityMessage, ipLocationMessage) -> {
        userActivityMessage.setLocation(ipLocationMessage.getLocation());
        return userActivityMessage;
    }, JoinWindows.of(JOIN_WINDOW),
        Serdes.String(), // key
        new UserActivityMessageSerde(), // left side
        new IpLocationMessageSerde() // right side
    )
    .selectKey((key, value) -> value.getId())
    .to("user-activity-enriched");

KafkaStreams streams = new KafkaStreams(builder, getSettings());
streams.start();
```

This snippet is very similar to the one from `Scenario 1`, except it uses a windowed joined between two `KStream`s.

Downside? It's very likely to have duplicates, since every time there is the same entry on the right side (the same IP location) the join will happen again! It's probably mandatory to implement some deduplication logic ([great example here](https://github.com/confluentinc/kafka-streams-examples/blob/4.0.0-post/src/test/java/io/confluent/examples/streams/EventDeduplicationLambdaIntegrationTest.java)) after all these steps.

## Summary

Any message enrichment scenario is probably unique, so don't try to use the same solution! I demonstrated a few different options, but the number of possible solutions is probably infinite, so don't be afraid to experiment! ;-)

PS: [https://github.com/confluentinc/kafka-streams-examples](https://github.com/confluentinc/kafka-streams-examples) is a great resource in addition to the Kafka Streams documentation.
