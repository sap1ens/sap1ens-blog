---
layout: post
title: "Deploying Kafka Connect Connectors"
date: 2019-10-14 11:38:42 -0700
comments: true
categories: 
- Kafka
- Kafka Connect
- Big Data
- Data Pipelines
---

[Kafka Connect](https://kafka.apache.org/documentation/#connect) is a modern open-source Enterprise Integration Framework that leverages Apache Kafka ecosystem. With Connect you get access to dozens of connectors that can send data between Kafka and various data stores (like S3, JDBC, Elasticsearch, etc.).

Kafka Connect provides [REST API](https://kafka.apache.org/documentation/#connect_rest) to manage connectors. The REST API     supports various operations like describing, adding, modifying, pausing, resuming, and deleting connectors. 

Using REST API for managing connectors might become a tedious task, especially when you have to deal with dozens of different connectors. Although it's possible to use some web UI tools like [lensesio/kafka-connect-ui](https://github.com/lensesio/kafka-connect-ui), it makes sense to follow basic deployment principles: config management, version control, CI/CD, etc. In other words, it's perfectly fine to start with manual, ad-hoc REST API calls, but ultimately any large Kafka Connect cluster needs some kind of automation for deploying connectors. 

I want to describe the approach that my team uses to make Connect management simple and reliable.

<!-- more -->

### Git

All connector configs are stored in a single Git repo. We run a customized version of Connect (with our custom plugins, converters, and other tweaks), so connector configs live in the same repo. Every config change is reviewed and merged before deploying.

### Jsonnet 

Connect REST API uses JSON as a protocol format, so storing configuration in JSON files (one per connector) seems reasonable. However, with more and more connectors it becomes obvious that there is a lot of duplication across files. Here's a full config for a typical S3 connector we run:

```json
{
   "connector.class": "com.activision.ds.connect.s3.DSS3SinkConnector",
   "flush.size": "1000000",
   "format.class": "com.activision.ds.connect.s3.format.DSParquetFormat",
   "locale": "en",
   "name": "SomeName-v1",
   "partitioner.class": "com.activision.ds.connect.s3.partitioner.DSTimeBasedPartitioner",
   "path.format": "dt=${ingestion_time}/other_key=${kafka.headers.other.value}",
   "rotate.schedule.interval.ms": "300000",
   "s3.bucket.name": "some-bucket",
   "s3.part.retries": "10",
   "s3.part.size": "5242880",
   "s3.region": "us-west-2",
   "s3.retry.backoff.ms": "1000",
   "schema.compatibility": "NEVER_CHANGE_SCHEMAS",
   "storage.class": "io.confluent.connect.s3.storage.S3Storage",
   "tasks.max": "64",
   "timestamp.field": "ingestion_time",
   "timezone": "UTC",
   "topics": "some.kafka.topics",
   "topics.dir": "some/folder"
}
```

As you can guess, most of the config options above are the same for other S3 connectors. We really care about `name`, `path.format`, `topics`, `topics.dir` and `tasks.max`.

[Jsonnet](https://jsonnet.org) is a simple templating language that extends JSON. It's a pretty powerful language that supports things like variables, functions, inheritance and much more. So, as a first step to simplify our configuration we could come up with a set of defaults for all S3 connectors, for example (`defaults.libsonnet`):

```json
{
  "connector.class": "com.activision.ds.connect.s3.DSS3SinkConnector",
  "storage.class": "io.confluent.connect.s3.storage.S3Storage",
  "timezone": "UTC",
  "locale": "en",

  "s3.region": "us-west-2",
  "s3.part.size": "5242880",
  "s3.bucket.name": "some-bucket",

  "s3.part.retries": "10",
  "s3.retry.backoff.ms": "1000",

  "partitioner.class": "com.activision.ds.connect.s3.partitioner.DSTimeBasedPartitioner",
  "schema.compatibility": "NEVER_CHANGE_SCHEMAS",

  "rotate.schedule.interval.ms": "600000",
  "flush.size": "500000"
}
```

and then the actual connector config could be simplified to:

```json
local defaults = import '../defaults.libsonnet';

local connector = {
  "name": "SomeName-v1",

  "tasks.max": "64",

  "flush.size": "1000000",
  "rotate.schedule.interval.ms": "300000",

  "topics": "some.kafka.topics",

  "topics.dir": "some/folder",

  "format.class": "com.activision.ds.connect.s3.format.DSParquetFormat",

  "path.format": "dt=${ingestion_time}/other_key=${kafka.headers.other.value}",
  "timestamp.field": "ingestion_time"
};

defaults + connector
```

Jsonnet provides endless opportunities to template and optimize these configs even more, however defining defaults and then combining them with specific values with the ability to override seems like a good start. 

### Deployment

Assuming we keep all connector configs in a folder named `connectors`, also separated by an environment like `connectors/prod`, `‌connectors/staging`, etc., we could use a simple Python script for calling REST API:

```python
import argparse
import logging
import _jsonnet
import json
import os
import requests

logging.basicConfig(format='%(asctime)-15s: %(name)s - %(levelname)s: %(message)s')
LOGGER = logging.getLogger('connectors-deploy')
LOGGER.setLevel(logging.INFO)

API_ROOT_TEMPLATE = "https://kafka-connect.%(env)s.company.com"

CONNECTORS_CONFIG_ROOT_TEMPLATE = "./connectors/%(env)s"
CONNECTOR_EXT = ".jsonnet"


def main():
    args = parse_args()

    LOGGER.info("Starting...")

    raw_config_filenames = find_files(get_connectors_config_root(args))

    LOGGER.info("Found connector configs: %s" % raw_config_filenames)

    processed_configs = process_config_files(raw_config_filenames)

    update_or_create_connectors(processed_configs, args)

    LOGGER.info("Completed")


def find_files(path_to_use):
    config_filenames = []

    for path, dirs, files in os.walk(path_to_use):
        for file in files:
            if file.endswith(CONNECTOR_EXT):
                config_filenames.append(os.path.abspath(path + "/" + file))

    return config_filenames


def process_config_files(raw_config_filenames):
    configs = []

    for filename in raw_config_filenames:
        configs.append(_jsonnet.evaluate_file(filename))

    return configs


def get_api_root(args):
    return replace_args(API_ROOT_TEMPLATE, args)


def get_connectors_config_root(args):
    return replace_args(CONNECTORS_CONFIG_ROOT_TEMPLATE, args)


def replace_args(template, args):
    return template % {'env': args.env}


def update_or_create_connectors(configs, args):
    api_root = get_api_root(args)

    for config in configs:
        config_json = json.loads(config)

        LOGGER.info("Adding/updating %s connector" % config_json['name'])

        if args.dry_run:
            LOGGER.info("Dry run is enabled, just printing config: " + config)
        else:
            # Update or Create a connector
            response = requests.put(api_root + "/connectors/" + config_json['name'] + "/config", data=config,
                                    headers={"Accept": "application/json", "Content-Type": "application/json"})

            LOGGER.info("Response: %s" % response.status_code)

            response.raise_for_status()


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument('--env', required=True, choices=['dev', 'staging', 'prod'], help='Kafka Connect environment')
    parser.add_argument('--dry-run', dest='dry_run', default=False, action='store_true', help='Dry-run mode')
    return parser.parse_args()


if __name__ == "__main__":
    main()
```

This script reads all files in a specified folder, compiles Jsonnet templates into actual JSON payloads and uses `PUT /connectors/{name}/config` endpoint to update (or add) connectors in an idempotent way. If a connector with the provided name doesn't exist, it will be created, otherwise, it'll be updated.

We could run this script manually or use a CI/CD tool like Jenkins to simplify dependency management and make sure every update is auditable.
