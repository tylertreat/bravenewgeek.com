---
title: "More Environments Will Not Make Things Easier"
date: 2018-04-11T15:49:47-05:00
lastmod: 2018-04-17T12:46:22-05:00
slug: "more-environments-will-not-make-things-easier"
categories: ["Software Architecture", "Software Engineering"]
tags: ["app engine", "contract testing", "microservices", "mocking", "pain-driven development", "product development", "productivity", "soa", "stubbing", "testing"]
---

Microservices are [hard](https://bravenewgeek.com/service-disoriented-architecture/). They require extreme discipline. They require a lot more upfront thinking. They introduce integration challenges and complexity that you otherwise wouldn’t have with a monolith, but service-oriented design is an important part of scaling organization structure. Hundreds of engineers all working on the same codebase will only lead to angst and the inability to be nimble.

This requires a pretty significant change in the way we think about things. We’re creatures of habit, so if we’re not careful, we’ll just keep on applying the same practices we used before we did services. And that will end in frustration.

How can we possibly build working software that comprises dozens of services owned by dozens of teams? Instinct tells us full-scale integration. That’s how we did things before, right? We ran integration tests. We run all of the services we depend on and develop our service against that. But it turns out, these dozen or so services I depend on also have their _own_ dependencies! This problem is not linear.

Okay, so we can’t run _everything_ on our laptop. Instead, let’s just have a development environment that is a facsimile of production with everything deployed. This way, teams can develop their products against real, deployed services. The trade-off is teams need to provide a high level of stability for these “development” services since other teams are relying on them for their own development. If nothing works, development is hamstrung. Personally, I think this is a pretty reasonable trade-off because if we’re disciplined enough, it shouldn’t be hard to provide stable APIs. In fact, if we’re disciplined, it should be a _requirement_. This is why upfront thinking is critical. Designing your APIs is the most important thing you do. Service-oriented architecture necessitates API-driven development. Literally nothing else matters but the APIs. It reminds me of the famous [Jeff Bezos mandate](https://gist.github.com/chitchcock/1281611):

1.  > All teams will henceforth expose their data and functionality through service interfaces.
    
2.  > Teams must communicate with each other through these interfaces.
    
3.  > There will be no other form of interprocess communication allowed: no direct linking, no direct reads of another team’s data store, no shared-memory model, no back-doors whatsoever. The only communication allowed is via service interface calls over the network.
    
4.  > It doesn’t matter what technology they use. HTTP, Corba, Pubsub, custom protocols – doesn’t matter. Bezos doesn’t care.
    
5.  > All service interfaces, without exception, must be designed from the ground up to be externalizable. That is to say, the team must plan and design to be able to expose the interface to developers in the outside world. No exceptions.
    
6.  > Anyone who doesn’t do this will be fired.
    
7.  > Thank you; have a nice day!
    

If we’re _not_ disciplined, maintaining stability in a development environment becomes too difficult. So naturally, the solution becomes doubling down—we just need _more_ environments. If every team just gets its own full-scale environment to develop against, no more stability problems. We get to develop our distributed monolith happily in our own little world. That sound you hear is every CFO collectively losing their shit, but whatever, they’re nerds and we’ve gotta get this feature to production!

Besides the obvious cost implications to this approach, perhaps the more insidious problem is it will cause teams to develop in a vacuum. In and of itself, this is not an issue, but for the undisciplined team who is not practicing rigorous API-driven development, it will create moving goalposts. A team will spend months developing its product against static dependencies only to find a massive integration headache come production time. It’s [pain deferral](https://bravenewgeek.com/pain-driven-development-why-greedy-algorithms-are-bad-for-engineering-orgs/), plain and simple. That pain isn’t being avoided or managed, you’re just neglecting to deal with instability and integration to a point where it is even more difficult. It is the opposite of the “fail-fast” mindset. It’s failing slowly and drawn out.

“We need to run everything with this particular configuration to test this, and if anyone so much as sneezes my service becomes unstable.” Good luck with that. I’ve got a dirty little secret: if you’re not disciplined, _no amount_ of environments will make things easier. If you can’t keep your service running in an integration environment, production isn’t going to be any easier.

Similarly, massive end-to-end integration tests spanning numerous services  are an anti-pattern. Another dirty little secret: [integrated tests are a scam](http://blog.thecodewhisperer.com/permalink/integrated-tests-are-a-scam). With a big enough system, you cannot reasonably expect to write _meaningful_ large-scale tests in any tractable way.

What are we to do then? With respect to development, get it out of your head that you can run a facsimile of production to build features against. If you need local development, the only _sane_ and cost-effective option is to stub. _Stub everything_. If you have a consistent RPC layer—_discipline_—this shouldn’t be too difficult. You might even be able to _generate_ portions of stubs.

We used Google App Engine heavily at Workiva, which is a PaaS encompassing numerous services—app server, datastore, task queues, memcache, blobstore, cron, mail—all managed by Google. We were doing serverless before serverless was even a thing. App Engine provides an [SDK](https://cloud.google.com/appengine/downloads) for developing applications locally on your machine. Numerous times I overheard someone who thought the SDK was just running a facsimile of App Engine on their laptop. In reality, it was running a bunch of stubs!

If you need a full-scale deployed environment, keep in mind that stability is the cost of entry. Otherwise, you’re just delaying problems. In either case, you need stable APIs.

With respect to integration testing, the only tractable solution that doesn’t lull you into a false sense of security is [consumer-driven contract testing](https://martinfowler.com/articles/consumerDrivenContracts.html). We run our tests against a stub, but these tests are also included in a consumer-driven contract. An API provider runs consumer-driven contract tests against its service to ensure it’s not breaking any downstream services.

All of this aside, the broader issue is ensuring a highly disciplined engineering organization. Without this, the rest becomes much more difficult as [pain-driven development](https://bravenewgeek.com/pain-driven-development-why-greedy-algorithms-are-bad-for-engineering-orgs/) takes hold. Discipline is a key part of doing service-oriented design and preventing things from getting out of control as a company scales. Moving to microservices means using the right tools and processes, not just applying the old ones in a new context.
