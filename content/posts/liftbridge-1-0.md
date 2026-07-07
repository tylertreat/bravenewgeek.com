---
title: "Liftbridge 1.0"
date: 2020-04-28T13:12:21-05:00
lastmod: 2020-04-28T14:28:33-05:00
slug: "liftbridge-1-0"
categories: ["Distributed Systems", "Liftbridge", "Messaging"]
tags: ["cloud-native", "distributed log", "distributed systems", "liftbridge", "message queues", "message-oriented middleware", "messaging", "nats", "open source"]
---

![](/wp-content/uploads/2020/04/liftbridge_full-1024x228.png)

[Liftbridge](https://liftbridge.io) has evolved a lot since making the first commit in October 2017, but the vision has remained the same: provide a message-streaming solution with a focus on simplicity and usability. This is demonstrated through many of the design and implementation decisions. A few examples include the use of NATS as the messaging backbone, avoiding heavy dependencies on runtimes like the JVM and external coordination systems like ZooKeeper, compiling down to a small, single static binary, opting for a gRPC-based API, and relying on plain YAML configuration. Liftbridge is written in Go, and the code is structured with the hopes that it’s relatively easy for someone to hop in and contribute to the project.

The goal of Liftbridge is to bridge the gap between sophisticated but complex log-based messaging systems like Apache Kafka and Apache Pulsar and simpler, cloud-native solutions. If you’re not familiar with the project, the [introduction post](https://bravenewgeek.com/introducing-liftbridge-lightweight-fault-tolerant-message-streams/) sheds some light. It’s been nearly two years since I open-sourced Liftbridge, and I’m pleased to announce the project has now reached a 1.0 release. In practical terms, what this means is that the API has reached a point of stability suitable for production use and will provide a backward-compatibility commitment going forward. Liftbridge will continue to follow a semantic versioning scheme.

A lot of great features have landed since the project was first conceived in 2016 and started in 2017—replication, log compaction and retention rules, stream partitioning, activity events, and stream pausing to name a few. An official [Java client](https://github.com/liftbridge-io/java-liftbridge) has been implemented and is quickly evolving. Python will follow shortly after. There’s also a lot of exciting stuff on the roadmap ahead including auto-pausing of sparsely used partitions, durable and fault-tolerant consumer groups, a better stream re-partitioning story, and broader client support.

If you’re already using Liftbridge today or are thinking about using it, I’d love to hear from you. Be sure to [follow Liftbridge on Twitter](https://twitter.com/liftbridge_io) and [join the community Slack channel](https://liftbridge.io/help.html) to stay up-to-date on the latest developments.
