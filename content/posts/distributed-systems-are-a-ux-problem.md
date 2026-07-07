---
title: "Distributed Systems Are a UX Problem"
date: 2015-06-03T19:33:29-05:00
lastmod: 2015-06-05T17:26:01-05:00
slug: "distributed-systems-are-a-ux-problem"
categories: ["Distributed Systems", "Software Engineering"]
tags: ["cap theorem", "consistency", "distributed systems", "eventual consistency", "fault tolerance", "sagas", "software engineering", "two-phase commit", "ux"]
---

Distributed systems are not strictly an engineering problem. It’s far too easy to assume a “backend” development concern, but the reality is there are implications at every point in the stack. Often the trade-offs we make lower in the stack in order to buy responsiveness bubble up to the top—so much, in fact, that it rarely _doesn’t_ impact the application in some way. Distributed systems affect the user. We need to shift the focus from system properties and guarantees to business rules and application behavior. We need to understand the limitations and trade-offs at each level in the stack and why they exist. We need to assume failure and plan for recovery. **We need to start thinking of distributed systems as a UX problem.**

### The Truth is Prohibitively Expensive

Stop relying on strong consistency. Coordination and distributed transactions are slow and inhibit availability. **The cost of knowing the “truth” is prohibitively expensive** for many applications. For that matter, what you think is the truth is likely just a partial or outdated version of it.

Instead, choose availability over consistency by making local decisions with the knowledge at hand and design the UX accordingly. By making this trade-off, we can _dramatically_ improve the user’s experience—_most of the time_.

### Failure Is an Option

There are a lot of problems with simultaneity in distributed computing. As Justin Sheehy describes it, [there is no “now”](https://queue.acm.org/detail.cfm?id=2745385) when it comes to distributed systems—that article, by the way, is a must-read for _every_ engineer, regardless of where they work in the stack.

> While some things about computers are “virtual,” they still must operate in the physical world and cannot ignore the challenges of that world.

Even though computers operate in the real world, they are disconnected from it. Imagine an inventory system. It may place orders to its artificial heart’s desire, but if the warehouse burns down, there’s no fulfilling them. Even if the system is perfect, its state may be impossible. But the system is typically _not_ perfect because the truth is prohibitively expensive. And not only do warehouses catch fire or forklifts break down, as rare as this may be, but computers fail and networks partition—and that’s far less rare.

The point is, stop trying to build perfect systems because one of two things will happen:

1\. You have a false sense of security because you think the system is perfect, and it’s not.

or

2\. You will never ship because perfection is out of reach or exorbitantly expensive.

Either case can be catastrophic, depending on the situation. With systems, **f****ailure is not only an option, it’s an _inevitability_**, so let’s plan for it as such. We have a lot to gain by embracing failure. Eric Brewer articulated this idea in a [recent interview](https://medium.com/s-c-a-l-e/google-systems-guru-explains-why-containers-are-the-future-of-computing-87922af2cf95):

> So the general answer is you allow things to be inconsistent and then you find ways to compensate for mistakes, versus trying to prevent mistakes altogether. In fact, the financial system is actually not based on consistency, it’s based on auditing and compensation. They didn’t know anything about the CAP theorem, that was just the decision they made in figuring out what they wanted, and that’s actually, I think, the right decision.

We can look to ATMs, and banks in general, as the canonical example for how this works. When you withdraw money, the bank could choose to first coordinate your account, calculating your available balance at that moment in time, before issuing the withdrawal. But what happens when the ATM is temporarily disconnected from the bank? The bank loses out on revenue.

Instead, they make a calculated risk. They choose availability and compensate the risk of overdraft with interest and charges. Likewise, banks use double-entry bookkeeping to provide an audit trail. Every credit has a corresponding debit. Mistakes happen—accounts are debited twice, an account is credited without another being debited—the failure modes are virtually endless. But we audit and compensate, detect and recover. Banks are loosely coupled systems. **[Accountants don’t use erasers](http://blogs.msdn.com/b/pathelland/archive/2007/06/14/accountants-don-t-use-erasers.aspx). Why should programmers?**

When you find yourself saying “this is important data or people’s money, it _has_ to be correct,” consider how the problem was solved before computers. [Building on Quicksand](http://www-db.cs.wisc.edu/cidr/cidr2009/Paper_133.pdf) by Dave Campbell and Pat Helland is a great read on this topic:

> Whenever the authors struggle with explaining how to implement loosely-coupled solutions, we look to how things were done before computers. In almost every case, we can find inspiration in paper forms, pneumatic tubes, and forms filed in triplicate.
> 
> Consider the lost request and its idempotent execution. In the past, a form would have multiple carbon copies with a printed serial number on top of them. When a purchase-order request was submitted, a copy was kept in the file of the submitter and placed in a folder with the expected date of the response. If the form and its work were not completed by the expected date, the submitter would initiate an inquiry and ask to locate the purchase-order form in question. Even if the work was lost, the purchase-order would be resubmitted without modification to ensure a lack of confusion in the processing of the work. You wouldn’t change the number of items being ordered as that may cause confusion. The unique serial number on the top would act as a mechanism to ensure the work was not performed twice.

Computers allow us to greatly improve the user experience, but many of the same fail-safes still exist, just slightly rethought.

The idea of compensation is actually a common theme within distributed systems. The [Saga pattern](http://www.cs.cornell.edu/andru/cs711/2002fa/reading/sagas.pdf) is a great example of this. Large-scale systems often have to coordinate resources across disparate services.  Traditionally, we might solve this problem using distributed transactions like two-phase commit. The problem with this approach is it doesn’t scale very well, it’s slow, and it’s not particularly fault tolerant. With 2PC, we have deadlock problems and even 3PC is still susceptible to network partitions.

Sagas split a long-lived transaction into individual, interleaved sub-transactions. Each sub-transaction in the sequence has a corresponding compensating transaction which reverses its effects. The compensating transactions must be idempotent so they can be safely retried. In the event of a partial execution, the compensating transactions are run and the Saga is effectively rolled back.

The [commonly used example](http://gotocon.com/dl/goto-chicago-2015/slides/CaitieMcCaffrey_ApplyingTheSagaPattern.pdf) for Sagas is booking a trip. We need to ensure flight, car rental, and hotel are all booked or none are booked. If booking the flight fails, we cancel the hotel and car, etc. Sagas trade off atomicity for availability while still allowing us to manage failure, a common occurrence in distributed systems.

Compensation has a lot of applications as a UX principle because it’s really the only way to build loosely coupled, highly available services.

### Calculated Recovery

Pat Helland describes computing as nothing more than “[memories, guesses, and apologies](http://blogs.msdn.com/b/pathelland/archive/2007/05/15/memories-guesses-and-apologies.aspx).” Computers always have partial knowledge. Either there is a disconnect with the real world (warehouse is on fire) or there is a disconnect between systems (System A sold a Foo Widget but, unbeknownst to it, System B just sold the last one in inventory—oops!). **Systems don’t make decisions, they make _guesses_.** The guess might be good or it might be bad, but rarely is there certainty. We can wait to collect as much information as possible before making a guess, but it means progress can’t be made until the system is confident enough to do so.

Computers have memory. This means they remember facts they have learned and guesses they have made. Memories help systems make better guesses in the future, and they can share those memories with other systems to help in their guesses. We can store more memories at the cost of more money, and we can survey other systems’ memories at the cost of more latency.

> It is a business decision how much money, latency, and energy should be spent on reducing forgetfulness. To make this decision, the costs of the increased probability of remembering should be weighed against the costs of occasionally forgetting stuff.

Generally speaking, the more forgetfulness we can tolerate, the more responsive our systems will be, provided we know how to handle the situations where something is forgotten.

Sooner or later, a system guesses wrong. It sucks. It might mean we lose out on revenue; the business isn’t happy. It might mean the user loses out on what they want; the customer isn’t happy. But we calculate the impact of these wrong guesses, we determine when the trade-offs do and don’t make sense, we compensate, and—when shit hits the fan—_we apologize_.

> Business realities force apologies.  To cope with these difficult realities, we need code and, frequently, we need human beings to apologize. It is essential that businesses have both code and people to manage these apologies.

**Distributed systems are as much about failure modes and recovery as they are about being operationally correct.** It’s critical that we can recover gracefully when something goes wrong, and often that affects the UX.

We could choose to spend extraordinary amounts of money and countless man-hours laboring over a system which provides the reliability we want. We could construct a data center. We could deploy big, expensive machines. We could install redundant fiber and switches. We could drudge over infallible code. Or we could stop, think for a moment, and realize maybe _“sorry”_ is a more effective alternative. Knowing when to make that distinction can be the difference between a successful business and a failed one. The implications of distributed systems may be wider reaching than you thought.
