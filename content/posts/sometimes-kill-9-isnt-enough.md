---
title: "Sometimes Kill -9 Isn’t Enough"
date: 2014-11-12T17:00:25-06:00
slug: "sometimes-kill-9-isnt-enough"
categories: ["Bash", "Distributed Systems", "Software Engineering", "Unix"]
tags: ["chaos monkey", "distributed systems", "fault tolerance", "game-day exercises", "ipfw", "iptables", "kill -9", "pfctl", "tc"]
---

If there’s one thing to know about distributed systems, it’s that they have to be [designed with the expectation of failure](http://www.artima.com/intv/distrib.html). It’s also safe to say that most software these days is, in some form, distributed—whether it’s a database, mobile app, or enterprise SaaS. If you have two different processes talking to each other, you have a distributed system, and it doesn’t matter if those processes are local or intergalactically displaced.

Marc Hedlund recently had a [great post](https://stripe.com/blog/game-day-exercises-at-stripe) on Stripe’s game-day exercises where they block off an afternoon, take a blunt instrument to their servers, and see what happens. We’re talking like _abruptly killing_ instances here—`kill -9`, `ec2-terminate-instances`, yanking on the damn power cord—that sort of thing. _Everyone_ should be doing this type of stuff. You really don’t know how your system behaves until you see it under failure conditions.

Netflix uses [Chaos Monkey](http://techblog.netflix.com/2012/07/chaos-monkey-released-into-wild.html) to randomly terminate instances, and they do it _in production_. That takes some balls, but you know you have a pretty solid system when you’re comfortable killing live production servers. At Workiva, we have a middleware we use to inject datastore and other RPC errors into Google App Engine. Building resilient systems is an objective concern, but we still have a ways to go.

We need to be pessimists and design for failure, but injecting failure isn’t enough. Sure, every so often shit hits the proverbial fan, and we need to be tolerant of that. But more often than not, that fan is just a strong headwind.

Simulating failure is a necessary element for building reliable distributed systems, but system behavior isn’t black and white, it’s a _continuum_. We build our system in a vacuum and (hopefully) test it under failure, but we should also be observing it in this gray area. How does it perform with unreliable network connections? Low bandwidth? High latency? Dropped packets? Out-of-order packets? Duplicate packets? Not only do our systems need to be fault-tolerant, they need to be _pressure_\-tolerant.

### Simulating Pressure

There are a lot of options to do these types of “pressure” simulations. On Linux, we can use `iptables` to accomplish this.

<script src="https://gist.github.com/tylertreat/2fdc1c02aedfed9f2a37.js"></script>

This will drop incoming and outgoing packets with a 10% probability. Alternatively, we can use `tc` to simulate network latency, limited bandwidth, and packet loss.

<script src="https://gist.github.com/tylertreat/6d2eb0a089a1da986a95.js"></script>

The above adds an additional 250ms of latency with 10% packet loss and a bandwidth limit of 1Mbps. Likewise, on OSX and BSD we can use `ipfw` or `pfctl`.

<script src="https://gist.github.com/tylertreat/a180dac76778788d8751.js"></script>

Here we inject 500ms of latency while limiting bandwidth to 1Mbps and dropping 10% of packets.

These are just some very simple traffic-shaping examples. Several of these tools allow you to perform even more advanced testing, like adding variation and correlation values. This would allow you to emulate burst packet loss and other situations we often encounter. For instance, with `tc`, we can add jitter to the network latency.

<script src="https://gist.github.com/tylertreat/116cfc2b3d77c414ce1c.js"></script>

This adds 50±20ms of latency. Since network latency typically isn’t uniform, we can apply a normal distribution to achieve a more realistic simulation.

<script src="https://gist.github.com/tylertreat/d8bb5f6389171ec90aec.js"></script>

Now we get a nice bell curve which is probably more representative of what we see in practice. We can also use `tc` to re-order, duplicate, and corrupt packets.

<script src="https://gist.github.com/tylertreat/92e4629b7ef5663a76e9.js"></script>

I’ve been working on an [open-source tool](https://github.com/tylertreat/Comcast) which attempts to wrap these controls up so you don’t have to memorize the options or worry about portability. It’s pretty primitive and doesn’t support much yet, but it provides a thin layer of abstraction.

### Conclusion

Injecting failure is crucial to understanding systems and building confidence, but like good test coverage, it’s important to examine suboptimal-but-operating scenarios. This isn’t even [99th-percentile](http://antirez.com/news/83) stuff—this is the type of shit your users deal with _every single day_. If you can’t handle sustained latency and sporadic network partitions, who cares if you tolerate instance failure? The tools are at our disposal, they just need to be leveraged.
