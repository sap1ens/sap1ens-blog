---
layout: post
title: "Kafka Streams Application Patterns"
date: 2019-12-27 16:28:08 -0800
comments: true
categories: 
- Kafka
- Kafka Streams
---

Kafka Streams is an advanced stream-processing library with high-level, [intuitive DSL](https://kafka.apache.org/24/documentation/streams/developer-guide/dsl-api.html) and a great set of features including exactly-once delivery, reliable stateful event-time processing, and more. 

Naturally, after completing a few basic tutorials and examples, a question arises: how should I structure an application for a real, production use-case? The answer could be very different depending on your problem, however, I feel like there are a few very useful patterns that can be used for pretty much any application.

<!-- more -->

Any streaming application uses the idea of a _topology_ - a definition of processing steps with one source, a series of transformation steps, and one to many sinks. The ways to structure this kind of application have been discussed for many years, modern stream processing is just an iteration on top of the messaging ideas (there are some differences too, but conceptually it feels like stream processing and messaging is essentially the same thing). And every time we talk about messaging and patterns it's hard to avoid recalling the classic list of [Enterprise Integration Patterns](https://www.enterpriseintegrationpatterns.com/patterns/messaging/). They're still very relevant today, so let's apply them!

## Router

[Router](https://www.enterpriseintegrationpatterns.com/patterns/messaging/MessageRouter.html) is a simple pattern: you have one input message, optional transformation, and _different types_ of potential outputs. To be able to use it in Kafka Streams some kind of intermediate message envelope is necessary to incorporate different _states_ of the processing result, which indicate different destinations. For example, we could decide to use `MessageSucceded`, `MessageFailed` and `MessageSkipped` envelopes. Let's also assume all these classes contain `genericRecord` field, which is the original Avro payload. Now, just combine our message classes with a `branch` operator and we get our Router:

```java
KStream[] streams = builder
    .stream(Pattern.compile(applicationConfig.getTopics()))
    // ... a transformation here returns one of the states below
    .branch(
            (key, value) -> value instanceof MessageSucceeded,
            (key, value) -> value instanceof MessageFailed,
            (key, value) -> value instanceof MessageSkipped
    );

// MessageSucceeded
// assuming 'MessageSucceeded' contains an Avro record field that we want to send to the output topic
streams[0].map((key, value) -> KeyValue.pair(key, ((MessageSucceeded) value).getGenericRecord()))
    .to(new SinkTopicNameExtractor());  

// MessageFailed
streams[1].process(messageFailureHandlerSupplier);

// MessageSkipped
// do nothing
```

`branch` is a very powerful operator that allows us to construct a set of completely different sub-topologies. Each sub-topology could write to a different topic or use a custom processor.

## Dead Letter Channel

[Dead Letter Channel](https://www.enterpriseintegrationpatterns.com/patterns/messaging/DeadLetterChannel.html) (or Dead Letter Queue, DLQ below) is one of the most useful patterns out there. Eventually, your application will fail during message processing and a very common thing to do in this case is delivering that message to a DLQ for inspection and/or reprocessing. 

Unfortunately, Apache Kafka doesn't support DLQs natively, nor does Kafka Streams. There are a few ways to implement a custom DLQ in Kafka Streams, one option is described [here](https://docs.confluent.io/3.2.0/streams/faq.html#option-2-quarantine-corrupted-records-dead-letter-queue-with-branch). I feel like the better solution is using the Router pattern above + a Processor with a custom Kafka Producer, something like this:

```java
public class MessageFailureHandler implements Processor<String, MessageFailed> {
    private ProcessorContext context;

    @Override
    public void init(ProcessorContext context) {
        this.context = context;
    }

    @Override
    public void process(String key, MessageFailed value) {
        String reason = generateFailureReason(value);

        try {
            DeadLetterQueue.getInstance().send(
                key == null ? null : key.getBytes(),
                AvroUtils.serialize(value.getGenericRecord()),
                context.headers(),
                context.topic(),
                reason
            );
        } catch (IOException e) {
            LOG.error("Could not re-serialize record!", e);
        }
    }

    @Override
    public void close() {}

    private String generateFailureReason(MessageFailed value) {
        // ... handle failure reason generation here
    }
}
```

and `DeadLetterQueue` could be the following singleton: 

```java
public class DeadLetterQueue {
    private KafkaProducer<byte[], byte[]> dlqKafkaProducer;

    public static DeadLetterQueue getInstance() {
        // standard singleton logic here
    }

    private DeadLetterQueue() {
        Properties props = new Properties();
        // ... initialize props
        this.dlqKafkaProducer = new KafkaProducer<>(props);
    }

    public void send(byte[] key, byte[] value, Headers headers, String sourceTopic, String reason) throws KafkaException {
        headers.add(new RecordHeader("failure.reason", reason.getBytes()));
        headers.add(new RecordHeader("failure.time", String.valueOf(System.currentTimeMillis()).getBytes()));

        String dlqTopic = generateDLQTopic(sourceTopic);

        LOG.warn("Sending to Dead Letter Queue {}: {}", dlqTopic, reason);

        dlqKafkaProducer.send(new ProducerRecord<>(
            dlqTopic,
            null,
            key,
            value,
            headers)
        );
    }

    private String generateDLQTopic (String sourceTopic) {
        // ... handle DLQ topic generation here
    }
}
```

It's important to highlight a few things:

- DeadLetterQueue's logic is oversimplified, there is no batching, no callback on `send` method to check for an exception, etc. Tweaks like these depend on specific use-cases
- We need a way to serialize a message that's outside of the Kafka SerDe logic. A solution in this case is to move the logic to some kind of Utils class, so it can be leveraged by the SerDe as well as other components like DLQ.

DLQ can be nicely integrated with a Router via `ProcessorSupplier`

```java
public class MessageFailureHandlerSupplier implements ProcessorSupplier {
    @Override
    public Processor get() {
        return new MessageFailureHandler();
    }
}

// ...

// and then when defining your topology, initialize the supplier:
MessageFailureHandlerSupplier messageFailureHandlerSupplier = new MessageFailureHandlerSupplier();

// and use it:
streams[1].process(messageFailureHandlerSupplier);
```

## Meter

There is no pattern called Meter in the original EIP list, however, the idea here is somewhat similar to [Detour](https://www.enterpriseintegrationpatterns.com/patterns/messaging/Detour.html) or [Wire Tap](https://www.enterpriseintegrationpatterns.com/patterns/messaging/WireTap.html). We want to measure our application message rates, at least at the beginning and at the end of the pipeline (and potentially at every major transformation step as well). Let's say we have some kind of metrics client and we just want to report message counts. In this case, using `peek` operator in our topology does the trick:

```java
// ...
.transform(...)
.peek(MetricsHandler::apply)
.branch(...)
// ...
``` 

`MetricsHandler` can be smart enough to report different message states differently, for example, tag `MessageSucceeded` with `success`, `MessageFailure` with `failure`, etc.

But what if we want to report an overall application lag metric? One step is not enough, we actually need to record the time at the start AND the end of the pipeline, and report the difference. An internal header can be used to pass initial timestamp value. For example, imagine injecting two extra steps:

```java
// ...
.stream(...)
.transform(InputMetricsHandler:new)
.transform(...) // actual transformation business logic
.transform(OutputMetricsHandler:new)
.branch(...)
// ...
``` 

Where `InputMetricsHandler` records current system timestamp and passes it as a header, `OutputMetricsHandler` records another timestamp and calculates a difference between the two, reporting the lag. We had to use `transform` instead of a `peek` here to get access to the headers. 

## More?

Most of the EIP patterns are already present in Kafka / Kafka Streams or can be easily implemented. And some patterns provide its core functionality like [Pipes and Filters](https://www.enterpriseintegrationpatterns.com/patterns/messaging/PipesAndFilters.html), [Aggregator](https://www.enterpriseintegrationpatterns.com/patterns/messaging/Aggregator.html) and [Guaranteed Delivery](https://www.enterpriseintegrationpatterns.com/patterns/messaging/GuaranteedMessaging.html). What important patterns do _you_ leverage? Leave a comment or hit me on social media!
