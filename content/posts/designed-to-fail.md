---
title: "Designed to Fail"
date: 2015-07-21T20:17:17-05:00
lastmod: 2016-12-20T22:36:57-05:00
slug: "designed-to-fail"
categories: ["Distributed Systems", "Software Engineering", "Systems Theory"]
tags: ["availability", "distributed systems", "fault tolerance", "messaging", "microservices", "ops", "resilience engineering", "soa", "software engineering", "systems", "systems theory"]
---

When it comes to reliability engineering, people often talk about things like fault injection, monitoring, and operations runbooks. These are all critical pieces for building systems which can withstand failure, but what’s less talked about is the need to design systems which _deliberately_ fail.

Reliability design has a natural progression which closely follows that of architectural design. With monolithic systems, we care more about preventing failure from occurring. With service-oriented architectures, controlling failure becomes less manageable, so instead we learn to anticipate it. With highly distributed microservice architectures where failure is all but guaranteed, we _embrace_ it.

What does it mean to embrace failure? Anticipating failure is understanding the behavior when things go wrong, building systems to be resilient to it, and having a game plan for when it happens, either manual or automated. _Embracing_ failure means making a conscious decision to purposely fail, and it’s essential for building highly available large-scale systems.

A microservice architecture typically means a complex web of service dependencies. One of SOA’s goals is to isolate failure and allow for graceful degradation. The key to being highly available is learning to be _partially_ available. Frequently, one of the requirements for partial availability is telling the client _“no__.”_ Outright rejecting service requests is often better than allowing them to back up because, when dealing with distributed services, the latter usually results in cascading failure across dependent systems.

While designing our distributed messaging service at Workiva, we made explicit decisions to _drop_ messages on the floor if we detect the system is becoming overloaded. As queues become backed up, incoming messages are discarded, a statsd counter is incremented, and a backpressure notification is sent to the client. Upon receiving this notification, the client can respond accordingly by failing fast, exponentially backing off, or using some other flow-control strategy. By bounding resource utilization, we maintain predictable performance, predictable (and measurable) lossiness, and impede cascading failure.

Other techniques include building kill switches into service calls and routers. If an overloaded service is not essential to core business, we fail fast on calls to it to prevent availability or latency problems upstream. For example, a spam-detection service is not essential to an email system, so if it’s unavailable or overwhelmed, we can simply bypass it. Netflix’s [Hystrix](https://github.com/Netflix/Hystrix) has a set of really nice patterns for handling this.

If we’re not careful, we can often be our own worst enemy. Many times, it’s our own internal services which [cause the biggest DoS attacks on ourselves](http://caitiem.com/2015/06/23/clients-are-jerks-aka-how-halo-4-dosed-the-services-at-launch-how-we-survived/). By isolating and controlling it, we can prevent failure from becoming widespread and unpredictable. By building in backpressure mechanisms and other types of intentional “failure” modes, we can ensure better availability and reliability for our systems through graceful degradation. Sometimes it’s better to fight fire with fire and failure with failure.
