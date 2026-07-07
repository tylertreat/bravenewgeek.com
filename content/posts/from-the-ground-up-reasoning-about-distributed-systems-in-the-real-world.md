---
title: "From the Ground Up: Reasoning About Distributed Systems in the Real World"
date: 2016-01-01T14:26:50-06:00
lastmod: 2016-12-20T22:32:34-06:00
slug: "from-the-ground-up-reasoning-about-distributed-systems-in-the-real-world"
categories: ["Distributed Systems", "Messaging", "Software Architecture", "Software Engineering"]
tags: ["byzantine generals problem", "cap theorem", "consensus", "coordination", "distributed systems", "end-to-end argument", "flp result", "I-confluence", "messaging", "systems", "two generals problem"]
---

_The rabbit hole is deep. Down and down it goes. Where it ends, nobody knows. But as we traverse it, patterns appear. They give us hope, they quell the fear._

Distributed systems literature is abundant, but as a practitioner, I often find it difficult to know where to start or how to synthesize this knowledge without a more formal background. This is a non-academic’s attempt to provide a line of thought for rationalizing design decisions. This piece doesn’t necessarily contribute any new ideas but rather tries to provide a holistic framework by studying some influential existing ones. It includes references which provide a good starting point for thinking about distributed systems. Specifically, we look at a few formal results and slightly less formal design principles to provide a basis from which we can argue about system design.

This is your last chance. After this, there is no turning back. I wish I could say there is no red-pill/blue-pill scenario at play here, but the world of distributed systems is complex. In order to make sense of it, we reason from the ground up while simultaneously stumbling down the deep and cavernous rabbit hole.

### Guiding Principles

In order to reason about distributed system design, it’s important to lay out some guiding principles or theorems used to establish an argument. Perhaps the most fundamental of which is the Two Generals Problem originally introduced by Akkoyunlu et al. in [Some Constraints and Trade-offs in the Design of Network Communications](http://dsg.tuwien.ac.at/linksites/teaching/courses/AdvancedDistributedSystems/download/1975_Akkoyunlu,%20Ekanadham,%20Huber_Some%20constraints%20and%20tradeoffs%20in%20the%20design%20of%20network%20communications.pdf) and popularized by Jim Gray in [Notes on Data Base Operating Systems](http://research.microsoft.com/en-us/um/people/gray/papers/DBOS.pdf) in 1975 and 1978, respectively. The Two Generals Problem demonstrates that it’s impossible for two processes to agree on a decision over an unreliable network. It’s closely related to the binary consensus problem (“attack” or “don’t attack”) where the following conditions must hold:

-   **Termination:** all correct processes decide some value (liveness property).
-   **Validity:** if all correct processes decide _v_, then _v_ must have been proposed by some correct process (non-triviality property).
-   **Integrity:** all correct processes decide at most one value _v,_ and _v_ is the “right” value (safety property).
-   **Agreement:** all correct processes must agree on the same value (safety property).

It becomes quickly apparent that any useful distributed algorithm consists of some intersection of both liveness and safety properties. The problem becomes more complicated when we consider an asynchronous network with crash failures:

-   **Asynchronous:** messages may be delayed arbitrarily long but will eventually be delivered.
-   **Crash failure**: processes can halt indefinitely.

Considering this environment actually leads us to what is arguably one of the most important results in distributed systems theory: the FLP impossibility result introduced by Fischer, Lynch, and Patterson in their 1985 paper [Impossibility of Distributed Consensus with One Faulty Process](http://cs-www.cs.yale.edu/homes/arvind/cs425/doc/fischer.pdf). This result shows that the Two Generals Problem is provably impossible. When we do not consider an upper bound on the time a process takes to complete its work and respond in a crash-failure model, it’s _impossible_ to make the distinction between a process that is crashed and one that is taking a long time to respond. FLP shows there is no algorithm which deterministically solves the consensus problem in an asynchronous environment when it’s possible for at least one process to crash. Equivalently, we say it’s impossible to have a _perfect_ failure detector in an asynchronous system with crash failures.

When talking about fault-tolerant systems, it’s also important to consider _Byzantine_ faults, which are essentially arbitrary faults. These include, but are not limited to, attacks which might try to subvert the system. For example, a security attack might try to generate or falsify messages. [The Byzantine Generals Problem](http://research.microsoft.com/en-us/um/people/lamport/pubs/byz.pdf) is a generalized version of the Two Generals Problem which describes this fault model. Byzantine fault tolerance attempts to protect against these threats by detecting or masking a bounded number of Byzantine faults.

Why do we care about consensus? The reason is it’s central to so many important problems in system design. Leader election implements consensus allowing you to dynamically promote a coordinator to avoid single points of failure. Distributed databases implement consensus to ensure data consistency across nodes. Message queues implement consensus to provide transactional or ordered delivery. Distributed init systems implement consensus to coordinate processes. Consensus is fundamentally an important problem in distributed programming.

It has [been shown time and time again](https://queue.acm.org/detail.cfm?id=2655736) that networks, whether local-area or wide-area, are often unreliable and largely asynchronous. As a result, these proofs impose real and significant challenges to system design.

> The implications of these results are not simply academic: these impossibility results have motivated a proliferation of systems and designs offering a range of alternative guarantees in the event of network failures.

L. Peter Deutsch’s [fallacies of distributed computing](https://en.wikipedia.org/wiki/Fallacies_of_distributed_computing) are a key jumping-off point in the theory of distributed systems. It presents a set of incorrect assumptions which many new to the space frequently make, of which the first is _“the network is reliable.”_

1.  The network is reliable.
2.  Latency is zero.
3.  Bandwidth is infinite.
4.  The network is secure.
5.  Topology doesn’t change.
6.  There is one administrator.
7.  Transport cost is zero.
8.  The network is homogeneous.

The CAP theorem, while recently the subject of [scrutiny](http://arxiv.org/pdf/1509.05393v2.pdf) and [debate](http://blog.thislongrun.com/2015/03/the-cap-theorem-series.html) over whether it’s overstated or not, is [a useful tool for establishing fundamental trade-offs](https://bravenewgeek.com/cap-and-the-illusion-of-choice/) in distributed systems and detecting vendor sleight of hand. Gilbert and Lynch’s [Perspectives on the CAP Theorem](https://groups.csail.mit.edu/tds/papers/Gilbert/Brewer2.pdf) lays out the intrinsic trade-off between safety and liveness in a fault-prone system, while Fox and Brewer’s [Harvest, Yield, and Scalable Tolerant Systems](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.24.3690&rep=rep1&type=pdf) characterizes it in a more pragmatic light. I will continue to say unequivocally that the CAP theorem is important within the field of distributed systems and of significance to system designers and practitioners.

### A Renewed Hope

Following from the results detailed earlier would imply many distributed algorithms, including those which implement linearizable operations, serializable transactions, and leader election, are a hopeless endeavor. Is it game over? Fortunately, no. Carefully designed distributed systems can maintain correctness without relying on pure coincidence.

First, it’s important to point out that the FLP result does not indicate consensus is unreachable, just that it’s not always reachable in bounded time. Second, the system model FLP uses is, in some ways, a pathological one. Synchronous systems place a known upper bound on message delivery between processes and on process computation. Asynchronous systems have no fixed upper bounds. In practice, systems tend to exhibit _partial synchrony_, which is described as one of two models by Dwork and Lynch in [Consensus in the Presence of Partial Synchrony](http://groups.csail.mit.edu/tds/papers/Lynch/jacm88.pdf). In the first model of partial synchrony, fixed bounds exist but they are not known a priori. In the second model, the bounds are known but are only guaranteed to hold starting at unknown time _T_. Dwork and Lynch present fault-tolerant consensus protocols for both partial-synchrony models combined with various fault models.

Chandra and Toueg introduce the concept of unreliable failure detectors in [Unreliable Failure Detectors for Reliable Distributed Systems](http://www.cs.utexas.edu/~lorenzo/corsi/cs380d/papers/p225-chandra.pdf). Each process has a local, external failure detector which can make mistakes. The detector monitors a subset of the processes in the system and maintains a list of those it suspects to have crashed. Failures are detected by simply pinging each process periodically and suspecting any process which doesn’t respond to the ping within twice the maximum round-trip time for any previous ping. The detector makes a mistake when it erroneously suspects a correct process, but it may later correct the mistake by removing the process from its list of suspects. The presence of failure detectors, even unreliable ones, makes consensus solvable in a slightly relaxed system model.

While consensus ensures processes agree on a value, atomic broadcast ensures processes deliver the same messages in the same order. This same paper shows that the problems of consensus and atomic broadcast are reducible to each other, meaning they are equivalent. Thus, the FLP result and others apply equally to atomic broadcast, which is used in coordination services like Apache ZooKeeper.

In _Introduction to Reliable and Secure Distributed Programming_, Cachin, Guerraoui, and Rodrigues suggest most practical systems can be described as partially synchronous:

> Generally, distributed systems appear to be synchronous. More precisely, for most systems that we know of, it is relatively easy to define physical time bounds that are respected most of the time. There are, however, periods where the timing assumptions do not hold, i.e., periods during which the system is asynchronous. These are periods where the network is overloaded, for instance, or some process has a shortage of memory that slows it down. Typically, the buffer that a process uses to store incoming and outgoing messages may overflow, and messages may thus get lost, violating the time bound on the delivery. The retransmission of the messages may help ensure the reliability of the communication links but introduce unpredictable delays. In this sense, practical systems are partially synchronous.

We capture partial synchrony by assuming timing assumptions only hold eventually without stating exactly when. Similarly, we call the system _eventually synchronous._ However, this does not guarantee the system is synchronous forever after a certain time, nor does it require the system to be initially asynchronous then after a period of time become synchronous. Instead it implies the system has periods of asynchrony which are not bounded, but there are periods where the system is synchronous long enough for an algorithm to do something useful or terminate. The key thing to remember with asynchronous systems is that they contain no timing assumptions.

Lastly, [On the Minimal Synchronism Needed for Distributed Consensus](http://groups.csail.mit.edu/tds/papers/Stockmeyer/DolevDS83-focs.pdf) by Dolev, Dwork, and Stockmeyer describes a consensus protocol as _t-resilient_ if it operates correctly when at most _t_ processes fail. In the paper, several critical system parameters and synchronicity conditions are identified, and it’s shown how varying them affects the _t-resiliency_ of an algorithm. Consensus is shown to be provably possible for some models and impossible for others.

Fault-tolerant consensus is made possible by relying on quorums. The intuition is that as long as a majority of processes agree on every decision, there is at least one process which knows about the complete history in the presence of faults.

Deterministic consensus, and by extension a number of other useful algorithms, is impossible in certain system models, but we can model most real-world systems in a way that circumvents this. Nevertheless, it shows the inherent complexities involved with distributed systems and the rigor needed to solve certain problems.

### Theory to Practice

What does all of this mean for us in practice? For starters, it means distributed systems are usually a harder problem than they let on. Unfortunately, this is often the cause of [improperly documented trade-offs](https://aphyr.com/posts/322-call-me-maybe-mongodb-stale-reads) or, in many cases, [data loss and safety violations](https://aphyr.com/posts/315-call-me-maybe-rabbitmq). It also suggests we need to rethink the way we design systems by shifting the focus from system properties and guarantees to business rules and application invariants.

One of my favorite papers is [End-To-End Arguments in System Design](http://web.mit.edu/Saltzer/www/publications/endtoend/endtoend.pdf) by Saltzer, Reed, and Clark. It’s an easy read, but it presents a compelling design principle for determining where to place functionality in a distributed system. The principle idea behind the end-to-end argument is that functions placed at a low level in a system may be redundant or of little value when compared to the cost of providing them at that low level. It follows that, in many situations, it makes more sense to flip guarantees “inside out”—pushing them outwards rather than relying on subsystems, middleware, or low-level layers of the stack to maintain them.

To illustrate this, we consider the problem of “careful file transfer.” A file is stored by a file system on the disk of computer A, which is linked by a communication network to computer B. The goal is to move the file from computer A’s storage to computer B’s storage without damage and in the face of various failures along the way. The application in this case is the file-transfer program which relies on storage and network abstractions. We can enumerate just a few of the potential problems an application designer might be concerned with:

1.  The file, though originally written correctly onto the disk at host A, if read now may contain incorrect data, perhaps because of hardware faults in the disk storage system.
2.  The software of the file system, the file transfer program, or the data communication system might make a mistake in buffering and copying the data of the file, either at host A or host B.
3.  The hardware processor or its local memory might have a transient error while doing the buffering and copying, either at host A or host B.
4.  The communication system might drop or change the bits in a packet, or lose a packet or deliver a packet more than once.
5.  Either of the hosts may crash part way through the transaction after performing an unknown amount (perhaps all) of the transaction.

Many of these problems are Byzantine in nature. When we consider each threat one by one, it becomes abundantly clear that even if we place countermeasures in the low-level subsystems, there will still be checks required in the high-level application. For example, we might place checksums, retries, and sequencing of packets in the communication system to provide reliable data transmission, but this really only eliminates threat four. An end-to-end checksum and retry mechanism at the file-transfer level is needed to guard against the remaining threats.

Building reliability into the low level has a number of costs involved. It takes a non-trivial amount of effort to build it. It’s redundant and, in fact, hinders performance by reducing the frequency of application retries and adding unneeded overhead. It also has no actual effect on correctness because correctness is determined and enforced by the end-to-end checksum and retries. The reliability and correctness of the communication system is of little importance, so going out of its way to ensure resiliency does not reduce any burden on the application. In fact, ensuring correctness by relying on the low level might be altogether _impossible_ since threat number two requires writing correct programs, but not all programs involved may be written by the file-transfer application programmer.

Fundamentally, there are two problems with placing functionality at the lower level. First, the lower level is not aware of the application needs or semantics, which means logic placed there is often insufficient. This leads to duplication of logic as seen in the example earlier. Second, other applications which rely on the lower level pay the cost of the added functionality even when they don’t necessarily need it.

Saltzer, Reed, and Clark propose the end-to-end principle as a sort of “Occam’s razor” for system design, arguing that it helps guide the placement of functionality and organization of layers in a system.

> Because the communication subsystem is frequently specified before applications that use the subsystem are known, the designer may be tempted to “help” the users by taking on more function than necessary. Awareness of end-to end arguments can help to reduce such temptations.

However, it’s important to note that the end-to-end principle is _not_ a panacea. Rather, it’s a guideline to help get designers to think about their solutions end to end, acknowledge their application requirements, and consider their failure modes. Ultimately, it provides a rationale for moving function upward in a layered system, closer to the application that uses the function, but there are always exceptions to the rule. Low-level mechanisms might be built as a performance optimization. Regardless, the end-to-end argument contends that lower levels should avoid taking on any more responsibility than necessary. The “lessons” section from Google’s [Bigtable paper](http://static.googleusercontent.com/media/research.google.com/en//archive/bigtable-osdi06.pdf) echoes some of these same sentiments:

> Another lesson we learned is that it is important to delay adding new features until it is clear how the new features will be used. For example, we initially planned to support general-purpose transactions in our API. Because we did not have an immediate use for them, however, we did not implement them. Now that we have many real applications running on Bigtable, we have been able to examine their actual needs, and have discovered that most applications require only single-row transactions. Where people have requested distributed transactions, the most important use is for maintaining secondary indices, and we plan to add a specialized mechanism to satisfy this need. The new mechanism will be less general than distributed transactions, but will be more efficient (especially for updates that span hundreds of rows or more) and will also interact better with our scheme for optimistic cross-datacenter replication.

We’ll see the end-to-end argument as a common theme throughout the remainder of this piece.

### Whose Guarantee Is It Anyway?

Generally, we rely on robust algorithms, transaction managers, and coordination services to maintain consistency and application correctness. The problem with these is twofold: they are often unreliable and they impose a massive performance bottleneck.

Distributed coordination algorithms are difficult to get right. Even tried-and-true protocols like two-phase commit are susceptible to crash failures and network partitions. Protocols which are more fault tolerant like Paxos and Raft generally don’t scale well beyond small clusters or across wide-area networks. Consensus systems like ZooKeeper [own your availability](http://www.ustream.tv/recorded/61483409), meaning if you depend on one and it goes down, you’re up a creek. Since quorums are often kept small for performance reasons, this might be less rare than you think.

Coordination systems become a fragile and complex piece of your infrastructure, which seems ironic considering they are usually employed to _reduce_ fragility. On the other hand, message-oriented middleware largely use coordination to provide developers with strong guarantees: exactly-once, ordered, transactional delivery and the like.

From transmission protocols to enterprise message brokers, relying on delivery guarantees is an anti-pattern in distributed system design. Delivery semantics are a tricky business. As such, when it comes to distributed messaging, [what you want is often not what you need](https://bravenewgeek.com/what-you-want-is-what-you-dont-understanding-trade-offs-in-distributed-messaging/). It’s important to look at the trade-offs involved, how they impact system design ([and UX!](https://bravenewgeek.com/distributed-systems-are-a-ux-problem/)), and how we can cope with them to make better decisions.

Subtle and not-so-subtle failure modes make providing strong guarantees exceedingly difficult. In fact, some guarantees, like exactly-once delivery, [aren’t even really _possible_ to achieve](https://bravenewgeek.com/you-cannot-have-exactly-once-delivery/) when we consider things like the Two Generals Problem and the FLP result. When we try to provide semantics like guaranteed, exactly-once, and ordered message delivery, we usually end up with something that’s over-engineered, difficult to deploy and operate, fragile, and slow. What is the upside to all of this? Something that makes your life easier as a developer when things go perfectly well, but the reality is things _don’t_ go perfectly well most of the time. Instead, you end up getting paged at 1 a.m. trying to figure out why RabbitMQ told your monitoring everything is awesome _while proceeding to take a dump in your front yard._

If you have something that relies on these types of guarantees in production, know that this will happen to you at least once sooner or later (and probably much more than that). Eventually, a guarantee is going to break down. It might be inconsequential, it might not. Not only is this a precarious way to go about designing things, but if you operate at a large scale, care about throughput, or have sensitive SLAs, it’s probably a nonstarter.

The performance implications of distributed transactions are obvious. Coordination is expensive because processes can’t make progress independently, which in turn limits throughput, availability, and scalability. Peter Bailis gave an excellent talk called [Silence is Golden: Coordination-Avoiding Systems Design](https://speakerdeck.com/pbailis/silence-is-golden-coordination-avoiding-systems-design) which explains this in great detail and how coordination can be avoided. In it, he explains how distributed transactions can result in nearly a _400x decrease_ in throughput in certain situations.

Avoiding coordination enables infinite scale-out while drastically improving throughput and availability, but in some cases coordination is unavoidable. In [Coordination Avoidance in Database Systems](http://www.vldb.org/pvldb/vol8/p185-bailis.pdf), Bailis et al. answer a key question: when is coordination necessary for correctness? They present a property, _invariant confluence_ (I-confluence), which is necessary and sufficient for safe, coordination-free, available, and convergent execution. I-confluence essentially works by pushing invariants up into the business layer where we specify correctness in terms of application semantics rather than low-level database operations.

> Without knowledge of what “correctness” means to your app (e.g., the invariants used in I-confluence), the best you can do to preserve correctness under a read/write model is serializability.

I-confluence can be determined given a set of transactions and a merge function used to reconcile divergent states. If I-confluence holds, there exists a coordination-free execution strategy that preserves invariants. If it doesn’t hold, no such strategy exists—coordination is required. I-confluence allows us to identify when we can and can’t give up coordination, and by pushing invariants up, we remove a lot of potential bottlenecks from areas which don’t require it.

If we recall, “synchrony” within the context of distributed computing is really just making assumptions about time, so synchronization is basically two or more processes coordinating around time. As we saw, a system which performs no coordination will have optimal performance and availability since everyone can proceed independently. However, a distributed system which performs zero coordination isn’t particularly useful or possible as I-confluence shows. Christopher Meiklejohn’s Strange Loop talk, [Distributed, Eventually Consistent Computations](https://www.youtube.com/watch?v=lsKaNDj4TrE), provides an interesting take on coordination with the parable of the car. A car requires friction to drive, but that friction is limited to very small contact points. Any other friction on the car causes problems or inefficiencies. If we think about physical time as friction, we know we can’t eliminate it altogether because it’s essential to the problem, but we want to reduce the use of it in our systems as much as possible. We can typically avoid relying on physical time by instead using logical time, for example, with the use of Lamport clocks or other conflict-resolution techniques. Lamport’s [Time, Clocks, and the Ordering of Events in a Distributed System](http://research.microsoft.com/en-us/um/people/lamport/pubs/time-clocks.pdf) is the classical introduction to this idea.

Often, systems simply forgo coordination altogether for latency-sensitive operations, a perfectly reasonable thing to do provided the trade-off is explicit and well-documented. Sadly, this is frequently [not the case](https://aphyr.com/posts/324-jepsen-aerospike). But we can do better. I-confluence provides a useful framework for avoiding coordination, but there’s a seemingly larger lesson to be learned here. What it really advocates is reexamining how we design systems, which seems in some ways to closely parallel our end-to-end argument.

When we think low level, we pay the upfront cost of entry—serializable transactions, linearizable reads and writes, _coordination_. This seems contradictory to the end-to-end principle. Our application doesn’t _really_ care about atomicity or isolation levels or linearizability. It cares about two users sharing the same ID or two reservations booking the same room or a negative balance in a bank account, but the database doesn’t know that. Sometimes these rules don’t even _require_ any expensive coordination.

If all we do is code our business rules and constraints into the language our infrastructure understands, we end up with a few problems. First, we have to know how to translate our application semantics into these low-level operations while avoiding any impedance mismatch. In the context of messaging, guaranteed delivery doesn’t really mean anything to our application which cares about what’s _done_ with the messages. Second, we preclude ourselves from using a lot of generalized solutions and, in some cases, we end up having to engineer specialized ones ourselves. It’s not clear how well this scales in practice. Third, we pay a performance penalty that could otherwise be avoided (as I-confluence shows). Lastly, we put ourselves at the mercy of our infrastructure and hope it makes good on its promises—_[it often doesn’t](http://www.bailis.org/blog/when-is-acid-acid-rarely/)._

Working on a messaging platform team, I’ve had countless conversations which resemble the following exchange:

> Developer: “We need _fast_ messaging.”  
> Me: “Is it okay if messages get dropped occasionally?”  
> Developer: “What? Of course not! We need it to be reliable.”  
> Me: “Okay, we’ll add a delivery ack, but what happens if your application crashes before it processes the message?”  
> Developer: “We’ll ack _after_ processing.”  
> Me: “What happens if you crash after processing but before acking?”  
> Developer: “We’ll just retry.”  
> Me: “So duplicate delivery is okay?”  
> Developer: “Well, it should really be exactly-once.”  
> Me: “But you want it to be fast?”  
> Developer: “Yep. Oh, and it should maintain message ordering.”  
> Me: “Here’s TCP.”

If, instead, we reevaluate the interactions between our systems, their APIs, their semantics, and move some of that responsibility _off_ of our infrastructure and _onto_ our applications, then maybe we can start to build more robust, resilient, and performant systems. With messaging, does our infrastructure really need to enforce FIFO ordering? Preserving order with distributed messaging in the presence of failure while trying to simultaneously maintain high availability is difficult and expensive. Why rely on it when it can be avoided with commutativity? Likewise, transactional delivery requires coordination which is slow and brittle while still not providing application guarantees. Why rely on it when it can be avoided with idempotence and retries? If you need application-level guarantees, _build them into the application level_. The infrastructure can’t provide it.

I really like Gregor Hohpe’s “[Your Coffee Shop Doesn’t Use Two-Phase Commit](http://www.enterpriseintegrationpatterns.com/docs/IEEE_Software_Design_2PC.pdf)” because it shows how simple solutions can be if we just model them off of the real world. It gives me hope we can design better systems, sometimes by just turning things on their head. There’s usually a reason things work the way they do, and it often doesn’t even involve the use of computers or complicated algorithms.

Rather than try to hide complexities by using flaky and heavy abstractions, we should engage directly by recognizing them in our design decisions and thinking end to end. It may be a long and winding path to distributed systems zen, but the best place to start is from the beginning.

_I’d like to thank Tom Santero for reviewing an early draft of this writing. Any inaccuracies or opinions expressed are mine alone._
