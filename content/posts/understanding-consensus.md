---
title: "Understanding Consensus"
date: 2014-09-24T21:35:07-06:00
slug: "understanding-consensus"
categories: ["Databases", "Distributed Systems", "Messaging"]
tags: ["app engine", "byzantine generals problem", "cap theorem", "consensus", "databases", "distributed systems", "paxos", "raft", "split-brain", "three-phase commit", "two-phase commit", "zab"]
---

A classical problem presented within the field of distributed systems is the [Byzantine Generals Problem](http://en.wikipedia.org/wiki/Two_Generals'_Problem). In it, we observe two allied armies positioned on either side of a valley. Within the valley is a fortified city. Each army has a general with one acting as commander. Both armies _must_ attack at the same time or face defeat by the city’s defenders. In order to come to an agreement on when to attack, messengers must be sent through the valley, risking capture by the city’s patrols. Consider the diagram below illustrating this problem.

![byzantine\_generals](/wp-content/uploads/2014/09/byzantine_generals.png)

In the above scenario, Army A has sent a messenger to Army B with a message saying “Attack at 0700.” Army B receives this message and dispatches a messenger carrying an acknowledgement of the attack plans; however, our ill-fated messenger has been intercepted by the city’s defenders.

How do our armies come to an agreement on when to attack? Perhaps Army A sends 100 messengers and attacks regardless. Unfortunately, if _all_ of the messengers are captured, this would result in a swift defeat because A would attack without B. What if, instead, A sends 100 messengers, waits for acknowledgements of those messages, and only attacks if it reaches a certain level of confidence, say receiving 75 or more confirmations? Yet again, this could very well end in defeat, this time with B attacking without A.

We also need to bear in mind that sending messages has a certain amount of overhead. We can’t, in good conscience, send a million messengers to their potential demise. Or maybe we can, but it’s more than the number of soldiers in our army.

In fact, we can’t _reliably_ make a decision. It’s provenly _impossible_. In the face of a [Byzantine failure](http://en.wikipedia.org/wiki/Byzantine_fault_tolerance), it becomes even more complicated by the possibility of traitors or forged messages.

Now replace two generals with _N_ generals. Coming to a perfectly reliable agreement between two generals was already impossible but becomes dramatically more complicated. It’s a problem more commonly referred to as _distributed consensus_, and it’s the focus of an army of researchers.

The problem of consensus is blissfully simple, but the solution is far from trivial. Consensus is the basis of distributed coordination services, locking protocols, and databases. A monolithic system (think a MySQL server) can enforce ACID constraints with consistent reads but exhibits generally poor availability and fault tolerance. The original Google App Engine datastore relied on a master/slave architecture where a single data center held the primary copy of data which was replicated to backup sites asynchronously. This offered applications strong consistency and low latency with the implied trade-off of availability. The health of an application was directly tied to the health of a data center. Beyond transient losses, it also meant periods of planned unavailability and read-only access while Google performed data center maintenance. App Engine has since transitioned to a high-replication datastore which relies on distributed consensus to replicate data across sites. This allows the datastore to continue operating in the presence of failures and at greater availability. In agreement with CAP, this naturally means higher latency on writes.

There are a number of solutions to distributed consensus, but most of them tend to be pretty characteristic of each other. We will look at some of these solutions, including multi-phase commit and state-replication approaches.

### Two-Phase Commit

Two-phase commit (2PC) is the simplest multi-phase commit protocol. In two-phase commit, all transactions go through a coordinator who is responsible for ensuring a transaction occurs across one or more remote sites (cohorts).

![2pc](/wp-content/uploads/2014/09/2pc.png)

When the coordinator receives a request, it asks each of its cohorts to vote yes or no. During this phase, each cohort performs the transaction up to the point of committing it. The coordinator then waits for all votes. If the vote is unanimously “yes,” it sends a message to its cohorts to commit the transaction. If one or more vote is “no,” a message is sent to rollback. The cohorts then acknowledge whether the transaction was committed or rolled back and the process is complete.

Two-phase commit is a blocking protocol. The coordinator blocks waiting for votes from its cohorts, and cohorts block waiting for a commit/rollback message from the coordinator. Unfortunately, this means 2PC can, in some circumstances, result in a deadlock, e.g. the coordinator dies while cohorts wait or a cohort dies while the coordinator waits. Another problematic scenario is when a coordinator and cohort simultaneously fail. Even if another coordinator takes its place, it won’t be able to determine whether to commit or rollback.

### Three-Phase Commit

Three-phase commit (3PC) is designed to solve the problems identified in two-phase by implementing a non-blocking protocol with an added “prepare” phase. Like 2PC, it relies on a coordinator which relays messages to its cohorts.

![3pc](/wp-content/uploads/2014/09/3pc.png)

Unlike 2PC, cohorts do not execute a transaction during the voting phase. Rather, they simply indicate if they are prepared to perform the transaction. If cohorts timeout during this phase or there is one or more “no” vote, the transaction is aborted. If the vote is unanimously “yes,” the coordinator moves on to the “prepare” phase, sending a message to its cohorts to acknowledge the transaction will be committed. Again, if an ack times out, the transaction is aborted. Once all cohorts have acknowledged the commit, we are guaranteed to be in a state where _all_ cohorts have agreed to commit. At this point, if the commit message from the coordinator is not received in the third phase, the cohort will go ahead and commit anyway. This solves the deadlocking problems described earlier. However, 3PC is still susceptible to network partitions. If a partition occurs, the coordinator will timeout and progress will not be made.

### State Replication

Protocols like [Raft](https://ramcloud.stanford.edu/raft.pdf), [Paxos](http://research.microsoft.com/en-us/um/people/lamport/pubs/paxos-simple.pdf), and [Zab](http://web.stanford.edu/class/cs347/reading/zab.pdf) are popular and widely used solutions to the problem of distributed consensus. These implement state replication or primary-backup using leaders, quorums, and replicas of operation logs or incremental delta states.

![consensus](/wp-content/uploads/2014/09/consensus.png)

![quorum](/wp-content/uploads/2014/09/quorum.png)

These protocols work by electing a leader (coordinator). Like multi-phase commit, all changes must go through that leader, who then broadcasts the changes to the group. Changes occur by appending a log entry, and each node has its own log replica. Where multi-phase commit falls down in the face of network partitions, these protocols are able to continue working by relying on a quorum (majority). The leader commits the change once the quorum has acknowledged it.

The use of quorums provide partition tolerance by fencing minority partitions while the majority continues to operate. This is the pessimistic approach to solving split-brain, so it comes with an inherent availability trade-off. This problem is mitigated by the fact that each node hosts a replicated state machine which can be rebuilt or reconciled once the partition is healed.

Google relies on Paxos for its high-replication datastore in App Engine as well as its [Chubby lock service](http://static.googleusercontent.com/media/research.google.com/en/us/archive/chubby-osdi06.pdf). The distributed key-value store [etcd](https://github.com/coreos/etcd) uses Raft to manage highly available replicated logs. Zab, which differentiates itself from the former by implementing a primary-backup protocol, was designed for the [ZooKeeper](http://zookeeper.apache.org/) coordination service. In general, there are several different implementations of these protocols, such as the [Go implementation](https://github.com/goraft/raft) of Raft.

Distributed consensus is a difficult thing to get right, but it’s important to frame it within the context of CAP. We can ensure stronger consistency at the cost of higher latency and lower availability. On the other hand, we can achieve higher availability with decreased latency while giving up strong consistency. The trade-offs really depend on what your needs are.
