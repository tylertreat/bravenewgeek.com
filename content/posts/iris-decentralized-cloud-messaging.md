---
title: "Iris Decentralized Cloud Messaging"
date: 2014-07-22T22:34:31-06:00
lastmod: 2018-01-23T21:15:17-06:00
slug: "iris-decentralized-cloud-messaging"
categories: ["Design Patterns", "Distributed Systems", "Go", "Messaging", "Software Architecture", "Software Engineering"]
tags: ["design patterns", "distributed systems", "gnatsd", "go", "iris", "message queues", "message-oriented middleware", "messaging", "nanomsg", "nats", "nsq", "zeromq"]
---

A couple weeks ago, I published a rather extensive [analysis](http://www.bravenewgeek.com/dissecting-message-queues/) of numerous message queues, both brokered and brokerless. Brokerless messaging is really just another name for peer-to-peer communication. As we saw, the difference in message latency and throughput between peer-to-peer systems and brokered ones is several orders of magnitude. ZeroMQ and nanomsg are able to reliably transmit _millions_ of messages per second at the expense of guaranteed delivery.

Peer-to-peer messaging is decentralized, scalable, and fast, but it brings with it an inherent complexity. There is a dichotomy between how brokerless messaging is conceptualized and how distributed systems are actually _built_. Distributed systems are composed of services like applications, databases, caches, etc. Services are composed of instances or nodes—individually addressable hosts, either physical or virtual. The key observation is that, conceptually, the unit of interaction lies at the _service level_, not the instance level. We don’t care about _which_ database server we interact with, we just want to talk to _a_ database server (or perhaps multiple). We’re concerned with logical groups of nodes.

While traditional socket-queuing systems like ZeroMQ solve the problem of scaling, they bring about a certain coupling between components. System designers are forced to build applications which communicate with nodes, not services. We can introduce load balancers like HAProxy, but we’re still addressing specific locations while creating potential single points of failure. With lightweight VMs and the pervasiveness of elastic clouds, IP addresses are becoming less and less static—they come and go. The canonical way of dealing with this problem is to use distributed coordination and service discovery via ZooKeeper, et al., but this introduces more configuration, more moving parts, and more headaches.

The _reality_ is that distributed systems are _not_ built with the instance as the smallest unit of composition in mind, they’re built with _services_ in mind. As discussed earlier, a service is simply a logical grouping of nodes. This abstraction is what we attempt to mimic with things like etcd, ZooKeeper and HAProxy. These assemblies are proven, but there are alternative solutions that offer zero configuration, minimal network management, and overall less complexity. One such solution that I want to explore is a distributed messaging framework called [Iris](http://iris.karalabe.com/).

### Decentralized Messaging with Iris

Iris is posited as a [decentralized approach to backend messaging middleware](http://www.comsis.org/archive.php?show=ppr475-1307). It looks to address several of the fundamental issues with traditional brokerless systems, like tight coupling and security.

In order to avoid the problem of addressing instances, Iris considers _clusters_ to be the smallest logical blocks of which systems are composed. A cluster is a collection of zero or more nodes which are responsible for a certain service sub-task. Clusters are then assembled into services such that they can communicate with each other without any regard as to which instance is servicing their requests or where it’s located. Lastly, services are composed into federations, which allow them to communicate across different clouds.

[![](/wp-content/uploads/2014/07/instances_vs_clusters-1.png)](/wp-content/uploads/2014/07/instances_vs_clusters-1.png)

This form of composition allows Iris to use semantic or logical addressing instead of the standard physical addressing. Nodes specify the name of the cluster they wish to participate in, while Iris handles the intricacies of routing and balancing. For example, you might have three database servers which belong to a single cluster called “databases.” The cluster is reached by its name and requests are distributed across the three nodes. Iris also takes care of service discovery, detecting new clusters as they are created on the same cloud.

[![](/wp-content/uploads/2014/07/physical_vs_semantic-1.png)](/wp-content/uploads/2014/07/physical_vs_semantic-1.png)

With libraries like ZeroMQ, security tends to be an [afterthought](http://hintjens.com/blog:48). Iris has been built from the ground-up with security in mind, and it provides a security model that is simple and fast.

> Iris uses a relaxed security model that provides perfect secrecy whilst at the same time requiring effectively zero configuration. This is achieved through the observation that if a node of a service is compromised, the whole system is considered undermined. Hence, the unit of security is a service – opposed to individual instances – where any successfully authenticated node is trusted by all. This enables full data protection whilst maintaining the loosely coupled nature of the system.

In practice, what this means is that each cluster uses a single private key. This encryption scheme not only makes deployment trivial, it minimizes the effect security has on speed.

[![](/wp-content/uploads/2014/07/authentication_and_encryption-1.png)](/wp-content/uploads/2014/07/authentication_and_encryption-1.png)

Like ZeroMQ and nanomsg, Iris offers a few different messaging patterns. It provides the standard request-reply and publish-subscribe schemes, but it’s important to remember that the smallest addressable unit is the cluster, not the node. As such, requests are targeted at a cluster and subsequently relayed on to a member in a load-balanced fashion. Publish-subscribe, on the other hand, is not targeted at a single cluster. It allows members of _any_ cluster to subscribe and publish to a topic.

Iris also implements two patterns called “broadcast” and “tunnel.” While request-reply forwards a message to one member of a cluster, broadcast forwards it to _all_ members. The caveat is that there is no way to listen for responses to a broadcast.

Tunnel is designed to address the problem of stateful or streaming transactions where a communication between two endpoints may consist of multiple data exchanges which need to occur as an atomic operation. It provides the guarantee of in-order and throttled message delivery by establishing a channel between a client and a node.

[![](/wp-content/uploads/2014/07/schemes-1.png)](/wp-content/uploads/2014/07/schemes-1.png)

### Performance Characteristics

According to its author, Iris is still in a “feature phase” and [hasn’t been optimized for speed](https://twitter.com/iriscmf/status/490140040711131136). Since it’s [written in Go](https://github.com/project-iris/iris), I’ve compared its pub/sub benchmark performance with other Go messaging libraries, NATS and NSQ. As before, these benchmarks shouldn’t be taken as gospel, the code is available [here](https://github.com/tylertreat/mq-benchmarking), and pull requests are welcome.

[![](/wp-content/uploads/2014/07/go_mq_throughput.png)](/wp-content/uploads/2014/07/go_mq_throughput.png)[![](/wp-content/uploads/2014/07/go_mq_latency.png)](/wp-content/uploads/2014/07/go_mq_latency.png)

We can see that Iris is comparable to NSQ on the sending side and about 4x on the receiving side, at least out of the box.

### Conclusion

Brokerless systems like ZeroMQ and nanomsg offer considerably higher throughput and less latency than classical message-oriented middleware but require greater orchestration of network topologies. They offer high scalability but can lead to tighter coupling between components. Traditional brokered message queues, like those of the AMQP variety, tend to be slower while providing more guarantees and reduced coupling. However, they are also more prone to scale problems like availability and partitioning.

In terms of its qualities, Iris appears to be a reasonable compromise between the decentralized nature of the brokerless systems and the minimal-configuration and management of the brokered ones. Its intrinsic value lies in its ability to hide the complexities of the underlying infrastructure behind distributed systems. Rather, Iris lends itself to building large-scale systems the way we conceptualize and reason about them—by using _services_ as the building blocks, _not_ instances.
