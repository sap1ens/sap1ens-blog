---
layout: post
title: "Kafka Elasticsearch Sink Connector and the Power of Single Message Transformations"
date: 2020-05-23 17:14:42 -0700
comments: true
categories: 
- Kafka
- Kafka Connect
- Big Data
- Data Pipelines
---

I've been using Kafka Connect for a few years now, but I've never paid much attention to Single Message Transformations (SMTs), until recently. SMTs are simple transforms that are applied to individual messages before they're delivered to a sink connector. They can drop a field, rename a field, add a timestamp, etc. 

I always thought that any kind of transformation should be done in a processing layer (for example, Kafka Streams) before hitting the integration layer (Kafka Connect). However, my recent experience with configuring an Elasticsearch Sink connector proved me wrong! Complex transformations should definitely be handled outside of Connect, but SMTs can be quite handy for simple enrichment and routing!

<!-- more -->

## SMTs and Routing

Before going to a concrete example, let's understand how SMTs allow us to apply routing changes. In Kafka Connect, it's widespread to use Kafka's topic name as a destination in the sink. For example, the S3 connector uses the topic name as a part of the destination path; Elasticsearch uses the topic name to create an index, etc.

Kafka Connect has a few Router SMTs like TimestampRouter, RegexRouter, etc. that provide various ways to modify the Kafka topic _inside the sink_. This topic is not going to be used by Kafka to actually write to it; it's just used in Connect routing, that's it. 

For example, if we have a topic named `a.metrics` and we want to create daily indices in Elasticsearch we could use a TimestampRouter like this:

```
"transforms": "TimestampRouter",
"transforms.TimestampRouter.type": "org.apache.kafka.connect.transforms.TimestampRouter",
"transforms.TimestampRouter.topic.format": "${topic}-${timestamp}",
"transforms.TimestampRouter.timestamp.format": "yyyy.MM.dd"
```

This transform configuration will generate _intermediate_ (used only in the sink connector) topics like `a.metrics-2020.01.01`, `a.metrics-2020.01.02`, and so on that will be used for creating indices in Elasticsearch.

## Elasticsearch Sink Connector Configuration

The example I'm going to provide is a simplified version of the connector I had to configure recently. I had one topic (`source.topic`) with different categories of messages inside. These categories had to be saved as separate indices in Elasticsearch (due to very different schemas). I also had to support multiple projects / topics / connectors, so all indices needed to be namespaced.

Finally, Elasticsearch and Kibana are most useful when dealing with time-series data. I needed to add a timestamp field in a specific format for Elasticsearch to parse.

So, let's take a look at the connector configuration for this use-case:

```json
{
  "name": "ESSink-v1",
  "connector.class": "io.confluent.connect.elasticsearch.ElasticsearchSinkConnector",
  "connection.url": "http://elasticsearch.host",
  
  // not used for ES 7
  "type.name": "",

  "tasks.max": "10",

  "topics": "source.topic",

  "transforms": "ReplaceTopic,AddPrefix,AddSuffix,InsertTimestamp,ConvertTimestamp",

  "transforms.ReplaceTopic.type": "com.sap1ens.connect.transforms.FieldRouter",
  "transforms.ReplaceTopic.field": "category",

  "transforms.AddPrefix.type": "org.apache.kafka.connect.transforms.RegexRouter",
  "transforms.AddPrefix.regex": ".*",
  "transforms.AddPrefix.replacement": "project_a-$0",

  "transforms.AddSuffix.type": "org.apache.kafka.connect.transforms.TimestampRouter",
  "transforms.AddSuffix.topic.format": "${topic}-${timestamp}",
  "transforms.AddSuffix.timestamp.format": "yyyy.MM.dd",

  "transforms.InsertTimestamp.type": "org.apache.kafka.connect.transforms.InsertField$Value",
  "transforms.InsertTimestamp.timestamp.field": "@timestamp",

  "transforms.ConvertTimestamp.type": "org.apache.kafka.connect.transforms.TimestampConverter$Value",
  "transforms.ConvertTimestamp.field": "@timestamp",
  "transforms.ConvertTimestamp.format": "yyyy-MM-dd'T'HH:mm:ss'Z'",
  "transforms.ConvertTimestamp.target.type": "string"
}
```

The first three transforms (`ReplaceTopic`, `AddPrefix`, `AddSuffix`) are used to route a message based on the payload `category` field, the current date and a static prefix. 

`ReplaceTopic` is a `com.sap1ens.connect.transforms.FieldRouter` SMT, which is a custom SMT that looks like this:

```java
package com.sap1ens.connect.transforms;

import io.confluent.connect.storage.util.DataUtils;
import java.util.Map;
import org.apache.commons.lang3.StringUtils;
import org.apache.kafka.common.config.ConfigDef;
import org.apache.kafka.connect.connector.ConnectRecord;
import org.apache.kafka.connect.data.Struct;
import org.apache.kafka.connect.errors.DataException;
import org.apache.kafka.connect.transforms.Transformation;
import org.apache.kafka.connect.transforms.util.SimpleConfig;

public class FieldRouter<R extends ConnectRecord<R>> implements Transformation<R> {

    public static final String OVERVIEW_DOC = "Extract and replace topic value with provided field";

    private static final String FIELD_CONFIG = "field";

    public static final ConfigDef CONFIG_DEF = new ConfigDef()
        .define(FIELD_CONFIG, ConfigDef.Type.STRING, ConfigDef.NO_DEFAULT_VALUE, ConfigDef.Importance.MEDIUM, "Field name to extract.");

    private String fieldName;

    @Override
    public void configure(Map<String, ?> props) {
        final SimpleConfig config = new SimpleConfig(CONFIG_DEF, props);
        fieldName = config.getString(FIELD_CONFIG);
    }

    @Override
    public R apply(R record) {
        String topic;

        if (record.value() instanceof Struct) {
            topic = DataUtils.getNestedFieldValue(record.value(), fieldName).toString();
        } else {
            throw new DataException("Error encoding partition");
        }

        if (StringUtils.isBlank(topic)) {
            return record;
        } else {
            return record.newRecord(topic, record.kafkaPartition(), record.keySchema(), record.key(), record.valueSchema(), record.value(), record.timestamp());
        }
    }

    @Override
    public ConfigDef config() {
        return CONFIG_DEF;
    }

    @Override
    public void close() {

    }
}
```

This SMT simply tries to extract a field from an Avro payload and use it as a topic name.

`AddPrefix` is a `org.apache.kafka.connect.transforms.RegexRouter` SMT. It adds a static project name to the topic once it's transformed into a category.

`AddSuffix` is a `org.apache.kafka.connect.transforms.TimestampRouter` SMT that appends the current date to the topic name, so it would be possible to delete old indices. 

After these three transforms are applied, a topic that looked like `source.topic` would be transformed into `project_a-some_category-2020.01.01`.

In the end, `InsertTimestamp` and `ConvertTimestamp` SMTs add a `@timestamp` field in the right format for Elasticsearch to parse.

## Summary
  
As you can see, SMTs can be quite powerful. With five SMTs, we were able to support non-trivial routing and enrich a timestamp field, which allowed this Elasticsearch sink to be pretty much production-ready! Also, adding a new SMT was very straightforward; it only took ~50 lines of code to implement a new Router.
