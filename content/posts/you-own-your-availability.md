---
title: "You Own Your Availability"
date: 2015-09-22T11:12:16-05:00
slug: "you-own-your-availability"
categories: ["Distributed Systems", "Software Engineering"]
tags: ["availability", "cap theorem", "distributed systems", "latency", "service-level agreements"]
---

There’s been a lot of discussion around “availability” lately. It’s often trumpeted with phrases like “[you own your availability](http://www.whoownsmyavailability.com/),” meaning there is no buck-passing when it comes to service uptime. The [AWS outage](http://venturebeat.com/2015/09/20/amazons-aws-outage-takes-down-netflix-reddit-medium-and-more/) earlier this week served as a stark reminder that, while owning your availability is a commendable ambition, for many it’s still largely owned by Amazon and the like.

In order to “own” your availability, it’s important to first understand what “availability” really means. Within the context of distributed-systems theory, availability is usually discussed in relation to the [CAP theorem](https://bravenewgeek.com/cap-and-the-illusion-of-choice/). [Formally](https://www.comp.nus.edu.sg/~gilbert/pubs/BrewersConjecture-SigAct.pdf), CAP defines availability as a _liveness_ property: “every request received by a non-failing node in the system must result in a response.” This is a weak definition for two reasons. First, the proviso “every request received by a _non-failing_ node” means that a system in which _all_ nodes have failed is trivially available.  Second, Gilbert and Lynch stipulate no upper bound on latency, only that operations _eventually_ return a response. This means an operation could take weeks to complete and availability would not be violated.

Martin Kleppmann points out these issues in his recent paper “[A Critique of the CAP Theorem](http://arxiv.org/pdf/1509.05393v2.pdf).” I don’t think there is necessarily a problem with the formalizations made by CAP, just a matter of engineering practicality. Kleppmann’s critique recalls a pertinent quote from Leslie Lamport on the topic of liveness:

> Liveness properties are inherently problematic. The question of whether a real system satisfies a liveness property is meaningless; it can be answered only by observing the system for an infinite length of time, and real systems don’t run forever. Liveness is always an approximation to the property we really care about. We want a program to terminate within 100 years, but proving that it does would require the addition of distracting timing assumptions. So, we prove the weaker condition that the program eventually terminates. This doesn’t prove that the program will terminate within our lifetimes, but it does demonstrate the absence of infinite loops.

Despite the pop culture surrounding it, CAP is not meant to neatly classify systems. It’s meant to serve as a jumping-off point from which we can reason from the ground up about distributed systems and the inherent limitations associated with them. It’s a reality check.

Practically speaking, availability is typically described in terms of “uptime” or the proportion of time which requests are successfully served. Brewer [refers to this as “yield,”](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.24.3690&rep=rep1&type=pdf) which is the probability of completing a request. This is the metric that is normally measured in “nines,” such as “five-nines availability.”

> In the presence of faults there is typically a tradeoff between providing no answer (reducing yield) and providing an imperfect answer (maintaining yield, but reducing harvest).

However, this definition is only marginally more useful than CAP’s since it still doesn’t provide an upper bound on computation.

CAP is better used as a starting point for system design and understanding trade-offs than as a tool for reasoning about availability because it doesn’t really account for _real_ availability. “Harvest” and “yield” show that availability is really a probabilistic property and that the trade with consistency is usually a gradient. But availability is much more nuanced than CAP’s “are we serving requests?” and harvest/yield’s “how many requests?” In practice, availability equates to SLAs. How many requests are we serving? At what rate? At what latency? At what percentiles? These things can’t really be formalized into a theorem like CAP because they are empirically observed, not properties of an algorithm.

Availability is specified by an SLA but observed by outside users. Unlike consistency, which is a property of the system and maintained by algorithm invariants, availability is determined by the client. For example, one user’s requests are served but another user’s are not. To the first user, the system is completely available.

To truly _own_ your availability, you have to _own_ every piece of infrastructure from the client to you, in addition to the infrastructure your system uses. Therefore, you can’t own your availability anymore than you can own Comcast’s fiber or Verizon’s 4G network. This is obviously impractical, if not _impossible_, but it might also be taking “own your availability” a bit too literally.

**What “you own your availability” actually means is _“you own your decisions.”_** Plain and simple. You own the decision to use AWS. You own the decision to use DynamoDB. You own the decision to not use multiple vendors. Owning your availability means making informed decisions about technology and vendors. “What is the risk/reward for using this database?” “Does using a PaaS/IaaS incur vendor lock-in? What happens when that service goes down?” It also means making informed decisions about the business. “What is the cost of our providers not meeting their SLAs? Is it cost-effective to have redundant providers?”

[An SLA is not an insurance policy](http://blog.b3k.us/2009/07/15/service-level-disagreements.html) or a hedge against the business impact of an outage, it’s merely a _refund policy_. Use them to set expectations and make intelligent decisions, but don’t _bank the business_ on them. Availability is not a timeshare. It’s not at will. You can’t just pawn it off, just like you can’t redirect your tech support to Amazon or Google.

It’s impossible to own your availability because there are too many things left to probability, too many unknowns, and too many variables outside of our control. **Own as much as you can predict, as much as you can control, and as much as you can _afford_.** The rest comes down to making informed decisions, hoping for the best, and planning for the worst.
