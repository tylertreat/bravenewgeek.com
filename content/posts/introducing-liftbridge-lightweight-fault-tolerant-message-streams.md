---
title: "Introducing Liftbridge: Lightweight, Fault-Tolerant Message Streams"
date: 2018-07-27T17:42:49-05:00
lastmod: 2018-09-13T23:39:30-05:00
slug: "introducing-liftbridge-lightweight-fault-tolerant-message-streams"
categories: ["Distributed Systems", "Liftbridge", "Messaging"]
tags: ["cloud-native", "distributed log", "distributed systems", "gnatsd", "kafka", "liftbridge", "message queues", "message-oriented middleware", "messaging", "nats", "nats streaming", "open source", "pulsar", "raft", "scalability", "stream processing", "write-ahead log"]
---

[![](/wp-content/uploads/2018/07/liftbridge.png)](https://github.com/liftbridge-io/liftbridge)

[Last week](https://twitter.com/tyler_treat/status/1019281381493526529) I open sourced [Liftbridge](https://github.com/liftbridge-io/liftbridge), my latest project and contribution to the [Cloud Native Computing Foundation](https://www.cncf.io/) ecosystem. Liftbridge is a system for lightweight, fault-tolerant (LIFT) message streams built on [NATS](https://nats.io/) and [gRPC](https://grpc.io/). Fundamentally, it extends NATS with a [Kafka](https://kafka.apache.org/)\-like publish-subscribe log API that is highly available and horizontally scalable.

I’ve been working on Liftbridge for the past couple of months, but it’s something I’ve been thinking about for over a year. I sketched out the design for it last year and [wrote about it](https://bravenewgeek.com/building-a-distributed-log-from-scratch-part-5-sketching-a-new-system/) in January. It was largely inspired while I was working on [NATS Streaming](https://github.com/nats-io/nats-streaming-server), which I’m currently still the second top contributor to. My primary involvement with NATS Streaming was building out the early data replication and clustering solution for high availability, which has continued to evolve since I left the project. In many ways, Liftbridge is about applying a lot of the things I learned while working on NATS Streaming as well as my observations from being closely involved with the NATS community for some time. It’s also the product of scratching an itch I’ve had since these are the kinds of problems I enjoy working on, and I needed something to code.

At its core, Liftbridge is a server that implements a durable, replicated message log for the NATS messaging system. Clients create a named _stream_ which is attached to a NATS subject. The stream then records messages on that subject to a replicated write-ahead log. Multiple consumers can read back from the same stream, and multiple streams can be attached to the same subject.

[![](/wp-content/uploads/2018/07/liftbridge-high-level.png)](/wp-content/uploads/2018/07/liftbridge-high-level.png)

The goal is to bridge the gap between sophisticated log-based messaging systems like Apache Kafka and [Apache Pulsar](https://pulsar.incubator.apache.org/) and simpler, cloud-native systems. This meant not relying on external coordination services like ZooKeeper, not using the JVM, keeping the API as simple and small as possible, and keeping client libraries thin. The system is written in Go, making it a single static binary with a small footprint (~16MB). It relies on the [Raft](https://raft.github.io/) consensus algorithm to do coordination. It has a _very_ [minimal API](https://github.com/liftbridge-io/liftbridge-grpc/blob/d658c291552f32ce810995c5e9dca9862ecc44da/api.proto#L104-L120) (just three endpoints at the moment). And the API uses gRPC, so client libraries can be generated for most popular programming languages (there is a [Go client](https://github.com/liftbridge-io/go-liftbridge) which provides some additional wrapper logic, but it’s pretty thin). The goal is to keep Liftbridge very _lightweight—_in terms of runtime, operations, and complexity.

However, the bigger goal of Liftbridge is to _extend_ NATS with a durable, at-least-once delivery mechanism that upholds the NATS tenets of simplicity, performance, and scalability. Unlike NATS Streaming, it uses the core NATS protocol with optional extensions. This means it can be added to an existing NATS deployment to provide message durability with no code changes.

NATS Streaming provides a similar log-based messaging solution. However, it is an entirely separate protocol built on top of NATS. NATS is an implementation detail—the _transport_—for NATS Streaming. This means the two systems have separate messaging namespaces—messages published to NATS are not accessible from NATS Streaming and vice versa. Of course, it’s a bit more nuanced than this because, in reality, NATS Streaming is using NATS subjects underneath; technically messages can be _accessed_, but they are serialized protobufs. These [nuances](https://github.com/nats-io/nats-streaming-server/issues/609) [often](https://github.com/nats-io/gnatsd/issues/715) [get](https://github.com/nats-io/gnatsd/issues/714) [confounded](https://github.com/nats-io/go-nats-streaming/issues/152) [by](https://github.com/nats-io/gnatsd/issues/713) [first](https://github.com/nats-io/gnatsd/issues/514)–[time](https://github.com/nats-io/go-nats/issues/251) [users](https://github.com/nats-io/go-nats/issues/328) as it’s not always clear that NATS and NATS Streaming are completely separate systems. NATS Streaming also [does not support wildcard subscriptions](https://github.com/nats-io/nats-streaming-server/issues/290), which sometimes surprises users since it’s a major feature of NATS.

As a result, Liftbridge was built to _augment_ NATS with durability rather than providing a completely separate system. To be clear, it’s still a separate _server_, but it merely acts as a write-ahead log for NATS subjects. NATS Streaming provides a broader set of features such as durable subscriptions, queue groups, pluggable storage backends, and multiple fault-tolerance modes. Liftbridge aims to have a relatively small API surface area.

The key features that differentiate Liftbridge are the shared message namespace, wildcards, log compaction, and horizontal scalability. NATS Streaming replicates channels to the entire cluster through a single Raft group, so adding servers does not help with scalability and actually creates a head-of-line bottleneck since everything is replicated through a single consensus group (n.b. NATS Streaming does have a partitioning mechanism, but it cannot be used in conjunction with clustering). Liftbridge allows replicating to a subset of the cluster, and each stream is replicated independently in parallel. This allows the cluster to scale horizontally and partition workloads more easily within a single, multi-tenant cluster.

[![](/wp-content/uploads/2018/07/liftbridge-streams.png)](/wp-content/uploads/2018/07/liftbridge-streams.png)

Some of the key features of Liftbridge include:

-   Log-based API for NATS
-   Replicated for fault-tolerance
-   Horizontally scalable
-   Wildcard subscription support
-   At-least-once delivery support
-   Message key-value support
-   Log compaction by key (WIP)
-   Single static binary (~16MB)
-   Designed to be high-throughput (more on this to come)
-   Supremely simple

Initially, Liftbridge is designed to point to an existing NATS deployment. In the future, there will be support for a “standalone” mode where it can run with an embedded NATS server, allowing for a single deployable process. And in support of the “cloud-native” model, there is work to be done to make Liftbridge play nice with Kubernetes and generally productionalize the system, such as implementing an [Operator](https://coreos.com/operators/) and providing better instrumentation—perhaps with [Prometheus](https://prometheus.io/) support.

Over the coming weeks and months, I will be going into more detail on Liftbridge, including the internals of it—such as its replication protocol—and providing benchmarks for the system. Of course, there’s also a lot of work yet to be done on it, so I’ll be continuing to work on that. There are many interesting problems that still need solved, so consider this my appeal to contributors. :)
