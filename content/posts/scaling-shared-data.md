---
title: "Scaling Shared Data in Distributed Systems"
date: 2014-10-21T21:23:03-06:00
slug: "scaling-shared-data"
categories: ["Databases", "Distributed Systems"]
tags: ["cap theorem", "causal ordering", "crdts", "databases", "distributed data types", "distributed systems", "vector clocks"]
---

Sharing mutable data at large scale is an _exceedingly_ difficult problem. In their seminal paper [_CRDTs: Consistency without concurrency control_](http://pagesperso-systeme.lip6.fr/Marc.Shapiro/papers/RR-6956.pdf), Shapiro et al. describe why the CAP theorem demands a give and take between scalability and consistency. In general, CAP requires us to choose between CP and AP. The former requires serializing every write, which doesn’t scale beyond a small cluster. The latter ensures scalability by giving up consistency.

### Sharing Data in Centralized Systems

We tend to prefer weaker consistency models because they mean lower latency and higher availability. To highlight this point, consider the fact that the memory models for most programming languages are _not_ serializable by default. More concisely, programs with shared memory are not inherently thread-safe. This is a conscious design decision because enforcing memory serializability incurs a significant latency penalty. Instead, programming languages require explicit _memory barriers_ which can be used around the critical sections which need this property.

For example, the [Java memory model](http://en.wikipedia.org/wiki/Java_Memory_Model) uses _within-thread as-if-serial_ semantics. This means the execution of a thread in isolation, regardless of runtime optimizations, is _guaranteed_ to be the same as it would have been had all statements been run in program order. The implication of as-if-serial semantics is that it gives up consistency—different threads _can and will_ have different views of the data. Java requires the use of memory barriers, either through explicit locking or the _volatile_ keyword, in order to establish a _happens-before_ relationship between statements in different threads.

This can be thought of as scaling shared data! We have multiple threads (systems) accessing the same data. While not distributed, many of the same ideas apply. Consistency, by definition, requires linearizability. In multi-threaded programs, we achieve this with mutexes. In distributed systems, we use transactions and distributed locking. Intuitively, both involve performance trade-offs.

### Sharing Data in Distributed Systems

Consider a shared, global counter used to measure ad impressions on a website accessed by millions of users around the world.

![shared\_data](/wp-content/uploads/2014/10/shared_data.png)

Traditionally, we might implement this using transactions—get the value, increment it by one, then save it back atomically. The problem is **transactions will not scale**. In order to guarantee consistency, they must be serialized. This results in high latency and low availability if a lot of writes are occurring. We lose some of the key advantages of distributed systems: parallel computation and availability.

So CAP makes it difficult to scale mutable, shared data. How do we do it then? There are several different strategies, each with their own pros and cons.

#### Immutable Data

Scaling shared read-only data is easy using replication techniques. This means the simplest solution for sharing data in a distributed system is to use _immutable_ data. If we don’t have to worry about writes, then scaling is trivial. Unfortunately, this isn’t always possible, but if your use case allows for it, it’s the best option.

#### Last-Write Wins

From a set of conflicting writes, LWW selects the one with the most recent timestamp. Clock drift happens, so LWW will inevitably lead to data loss with enough concurrent writes. It’s _critical_ to accept this reality, but it’s often acceptable for some use cases. LWW trades consistency for availability.

#### Application-Level Conflict Resolution

Often times, the best way to ensure safety is by resolving write conflicts at the application level. When there are conflicting writes on a piece of data, applications can apply business rules to determine the canonical update. An example of this is Riak’s application-side conflict resolution strategy.

#### Causal Ordering

Rather than relying on LWW, which has a high probability of data loss, we can use the causal relationships between writes in order to determine which one to apply. Unlike timestamps, which attempt to provide a total order, causal ordering establishes a _partial_ order. We can approximate a causal ordering by using techniques like [Lamport timestamps](http://en.wikipedia.org/wiki/Lamport_timestamps) or [vector clocks](http://en.wikipedia.org/wiki/Vector_clock). By storing a causal history with each write and reading that history before each write, we can make informed decisions on the correctness of updates. The trade-off here is the added overhead of storing this additional metadata and the extra round trip.

#### Distributed Data Types

CRDTs, or convergent/commutative replicated data types, are the new, up-and-coming solution for scaling shared data, but they aren’t at all new. In fact, the theory behind CRDTs has been [in use for hundreds of years](http://en.wikipedia.org/wiki/Double-entry_bookkeeping_system). CRDTs are grounded in mathematics. Operations or updates on a CRDT _always_ converge. Because the operations must be commutative, associative, and idempotent, they can be applied in any order and the outcome will always be the same. This means we don’t care about causal ordering—_it doesn’t matter_.

CRDTs are generally modeled after common data structures like sets, maps, lists, and counters, just in a distributed sense. What they provide us are highly available, eventually consistent data structures in which we don’t have to worry about write coordination.

Aside from the operation requirements, the other drawback of CRDTs is that they require knowledge of all clients. Each client has a replica of the CRDT, so the global state is determined by merging them. And although CRDTs can be applied to a wide variety of use cases, they typically require some interpretation and specialization of common data structures. These interpretations tend to be more limited in capability.

### In Summary

Scaling mutable data is hard. On the other hand, scaling immutable data is easy, so if you can get away with it, do it. There are a number of ways to approach the problem, but as with anything, it all comes down to your use case. The solutions are all about trade-offs—namely the trade-off between consistency and availability. Use weakly consistent models when you can because they afford you high availability and low latency, and rely on stronger models only when absolutely necessary. Do what makes sense for your system.
