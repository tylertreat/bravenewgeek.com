---
title: "Distributed Messaging with ZeroMQ"
date: 2014-06-11T16:56:03-06:00
lastmod: 2015-04-21T00:00:00-06:00
slug: "distributed-messaging-with-zeromq"
categories: ["Design Patterns", "Distributed Systems", "Java", "Messaging", "Software Architecture", "Software Engineering"]
tags: ["concurrency", "consistency", "distributed systems", "message queues", "messaging", "scalability", "zeromq", "zinc"]
---

> _“A distributed system is one in which the failure of a computer you didn’t even know existed can render your own computer unusable.” -Leslie Lamport_

With the increased prevalence and accessibility of cloud computing, distributed systems architecture has largely supplanted more monolithic constructs. The implication of using a service-oriented architecture, of course, is that you now have to deal with a myriad of difficulties that previously never existed, such as fault tolerance, availability, and horizontal scaling. Another interesting layer of complexity is providing consistency across nodes, which itself is a problem surrounded with endless research. Algorithms like [Paxos](http://en.wikipedia.org/wiki/Paxos_\(computer_science\)) and [Raft](https://ramcloud.stanford.edu/wiki/download/attachments/11370504/raft.pdf) attempt to provide solutions for managing replicated data, while other solutions offer eventual consistency.

Building scalable, distributed systems is not a trivial feat, but it pales in comparison to building _real-time_ systems of a similar nature. Distributed architecture is a well-understood problem and the fact is, most applications have a high tolerance for latency. Few systems have a _demonstrable_ need for real-time communication, but the few that do present an interesting challenge for developers. In this article, I explore the use of ZeroMQ to approach the problem of distributed, real-time messaging in a scalable manner while also considering the notion of eventual consistency.

### The Intelligent Transport Layer

[ZeroMQ](http://zeromq.org/) is a high-performance asynchronous messaging library written in C++. It’s not a dedicated message broker but rather an embeddable concurrency framework with support for direct and fan-out endpoint connections over a variety of transports. ZeroMQ implements a number of different communication patterns like request-reply, pub-sub, and push-pull through TCP, PGM (multicast), in-process, and inter-process channels. The glaring lack of UDP support is, more or less, by design because ZeroMQ was conceived to provide guaranteed-_ish_ delivery of _atomic_ messages. The library makes no _actual_ guarantee of delivery, but it does make a best effort. What ZeroMQ _does_ guarantee, however, is that you will never receive a partial message, and messages will be received in order. This is important because UDP’s performance gains really only manifest themselves in lossy or congested environments.

The comprehensive list of messaging patterns and transports alone make ZeroMQ an appealing choice for building distributed applications, but it particularly excels due to its reliability, scalability and high throughput. ZeroMQ and related technologies are popular within high-frequency trading, where packet loss of financial data is often unacceptable ((ZeroMQ’s founder, iMatix, was responsible for moving JPMorgan Chase and the Dow Jones Industrial Average trading platforms to OpenAMQ)). In 2011, [CERN](http://en.wikipedia.org/wiki/CERN) actually [performed a study](http://zeromq.wdfiles.com/local--files/intro%3Aread-the-manual/Middleware%20Trends%20and%20Market%20Leaders%202011.pdf) comparing CORBA, Ice, Thrift, ZeroMQ, and several other protocols for use in its particle accelerators and ranked ZeroMQ the highest.

[![cern](/wp-content/uploads/2014/06/cern.png)](/wp-content/uploads/2014/06/cern.png)

ZeroMQ uses some tricks that allow it to actually _outperform_ TCP sockets in terms of throughput such as intelligent message batching, minimizing network-stack traversals, and disabling [Nagle’s algorithm](http://en.wikipedia.org/wiki/Nagle's_algorithm). By default (and when possible), messages are queued on the subscriber, which attempts to avoid the problem of slow subscribers. However, when this isn’t sufficient, ZeroMQ employs a pattern called the “Suicidal Snail.” When a subscriber is running slow and is unable to keep up with incoming messages, ZeroMQ convinces the subscriber to kill itself. “Slow” is determined by a configurable high-water mark. The idea here is that it’s better to fail fast and allow the issue to be resolved quickly than to potentially allow stale data to flow downstream. Again, think about the high-frequency trading use case.

### A Distributed, Scalable, and Fast Messaging Architecture

ZeroMQ makes a convincing case for use as a transport layer. Let’s explore a little deeper to see how it could be used to build a messaging framework for use in a real-time system. ZeroMQ is fairly intuitive to use and offers a plethora of bindings for various languages, so we’ll focus more on the architecture and messaging paradigms than the actual code.

About a year ago, while I first started investigating ZeroMQ, I built a framework to perform real-time messaging and document syncing called [Zinc](https://github.com/tylertreat/Zinc). A “document,” in this sense, is any well-structured and mutable piece of data—think text document, spreadsheet, canvas, etc. While purely academic, the goal was to provide developers with a framework for building rich, collaborative experiences in a distributed manner.

The framework actually had two implementations, one backed by the native ZeroMQ, and one backed by the pure Java implementation, JeroMQ ((In systems where _near_ real-time is sufficient, JeroMQ is adequate and benefits by not requiring any native linking.)). It was really designed to allow _any_ transport layer to be used though.

Zinc is structured around just a few core concepts: Endpoints, ChannelListeners, MessageHandlers, and Messages. An Endpoint represents a single node in an application cluster and provides functionality for sending and receiving messages to and from other Endpoints. It has outbound and inbound channels for transmitting messages to peers and receiving them, respectively.

[![endpoint](/wp-content/uploads/2014/06/endpoint.png)](/wp-content/uploads/2014/06/endpoint.png)

ChannelListeners essentially act as daemons listening for incoming messages when the inbound channel is open on an Endpoint. When a message is received, it’s passed to a thread pool to be processed by a MessageHandler. Therefore, Messages are processed asynchronously in the order they are received, and as mentioned earlier, ZeroMQ guarantees in-order message delivery. As an aside, this is before I began learning [Go](http://golang.org/), which would make for an ideal replacement for Java here as it’s quite well-suited to the problem :)

Messages are simply the data being exchanged between Endpoints, from which we can build upon with Documents and DocumentFragments. A Document is the structured data defined by an application, while DocumentFragment represents a partial Document, or delta, which can be as fine- or coarse- grained as needed.

Zinc is built around the publish-subscribe and push-pull messaging patterns. One Endpoint will act as the host of a cluster, while the others act as clients. With this architecture, the host acts as a publisher and the clients as subscribers. Thus, when a host fires off a Message, it’s delivered to every subscribing client in a multicast-like fashion. Conversely, clients also act as “push” Endpoints with the host being a “pull” Endpoint. Clients can then push Messages into the host’s Message queue from which the host is pulling from in a first-in-first-out manner.

This architecture allows Messages to be propagated across the entire cluster—a client makes a change which is sent to the host, who propagates this delta to all clients. This means that the client who initiated the change will receive an “echo” delta, but it will be discarded by checking the Message origin, a UUID which uniquely identifies an Endpoint. Clients are then responsible for preserving data consistency if necessary, perhaps through [operational transformation](http://en.wikipedia.org/wiki/Operational_transformation) or by maintaining a single source of truth from which clients can reconcile.

[![cluster](/wp-content/uploads/2014/06/cluster.png)](/wp-content/uploads/2014/06/cluster.png)

One of the advantages of this architecture is that it scales reasonably well due to its composability. Specifically, we can construct our cluster as a tree of clients with arbitrary breadth and depth. Obviously, the more we scale horizontally or vertically, the more latency we introduce between edge nodes. Coupled with eventual consistency, this can cause problems for some applications but might be acceptable to others.

[![scalability](/wp-content/uploads/2014/06/scalability.png)](/wp-content/uploads/2014/06/scalability.png)

The downside is this inherently introduces a single point of failure characterized by the client-server model. One solution might be to promote another node when the host fails and balance the tree.

Once again, this framework was mostly academic and acted as a way for me to test-drive ZeroMQ, although there are some other interesting applications of it. Since the framework supports multicast message delivery via push-pull or publish-subscribe mechanisms, one such use case is autonomous load balancing.

Paired with something like [ZooKeeper](http://zookeeper.apache.org/), [etcd](https://github.com/coreos/etcd), or some other service-discovery protocol, clients would be capable of discovering hosts, who act as load balancers. Once a client has discovered a host, it can request to become a part of that host’s cluster. If the host accepts the request, the client can begin to send messages to the host (and, as a result, to the rest of the cluster) and, likewise, receive messages from the host (and the rest of the cluster). This enables clients and hosts to submit work to the cluster such that it’s processed in an evenly distributed way, and workers can determine whether to pass work on further down the tree or process it themselves. Clients can choose to participate in load-balancing clusters at their own will and when they become available, making them mostly autonomous. Clients could then be quickly spun-up and spun-down using, for example, [Docker](http://www.docker.com/) containers.

ZeroMQ is great for achieving reliable, fast, and scalable distributed messaging, but it’s equally useful for performing parallel computation on a single machine or several locally networked ones by facilitating in- and inter- process communication using the same patterns. It also scales in the sense that it can effortlessly leverage multiple cores on each machine. ZeroMQ is _not_ a replacement for a message broker, but it can work in unison with traditional message-oriented middleware. Combined with [Protocol Buffers](https://code.google.com/p/protobuf/) and other serialization methods, ZeroMQ makes it easy to build extremely high-throughput messaging frameworks.
