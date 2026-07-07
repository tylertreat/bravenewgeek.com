---
title: "Benchmark Responsibly"
date: 2015-01-02T14:53:22-06:00
lastmod: 2015-12-12T15:14:19-06:00
slug: "benchmark-responsibly"
categories: ["Benchmarking", "Distributed Systems", "Messaging"]
tags: ["benchmarking", "brokers", "flotilla", "hdrhistogram", "latency", "message queues", "messaging", "performance", "statistics", "testing", "throughput"]
---

When I posted my [Dissecting Message Queues](http://www.bravenewgeek.com/dissecting-message-queues/) article last summer, it understandably caused some controversy.  I received both praise and scathing comments, emails asking why I didn’t benchmark X and pull requests to bump the numbers of Y. To be honest, that analysis was more of a brain dump from my own test driving of various message queues than any sort of authoritative or scientific study—it was _far_ from the latter, to say the least. The qualitative discussion was pretty innocuous, but the benchmarks and [supporting code](https://github.com/tylertreat/mq-benchmarking) were the target of a lot of (valid) criticism. In retrospect, it was probably irresponsible to publish them, but I was young and naive back then; now I’m just mostly naive.

### Comparing Apples to Other Assorted Fruit

One such criticism was that the benchmarks were divided into two very broad categories: brokerless and brokered. While the brokerless group compared two very similar libraries, ZeroMQ and nanomsg, the second group included a number of distinct message brokers like RabbitMQ, Kafka, NATS, and Redis, to name a few.

The problem is _not all brokers are created equal_. They often have different goals and different prescribed use cases. As such, they impose different guarantees, different trade-offs, and different constraints. By grouping these benchmarks together, I implied they were fundamentally equivalent, when in fact, most were fundamentally different. For example, [NATS](http://nats.io/) serves a very different purpose than Kafka, and Redis, which offers pub/sub messaging, typically isn’t thought of as a message broker at all.

### Measure Right or Don’t Measure at All

Another criticism was the way in which the benchmarks were performed. The tests were immaterial. The producer, consumer, and the message queue itself all ran on the same machine. Even worse, they used just a single publisher and subscriber. Not only does it _not_ test what a _remotely_ realistic configuration looks like, but it doesn’t even give you a good idea of a trivial one.

To be meaningful, we need to test with more than one producer and consumer, ideally distributed across many machines. We want to see how the system scales to larger workloads. Certainly, the producers and consumers _cannot_ be collocated when we’re measuring discrete throughputs on either end, nor should the broker. This helps to reduce confounding variables between the system under test and the load generation.

### It’s Not Rocket Science, It’s Computer Science

The third major criticism lay with the measurements themselves. Measuring throughput is fairly straightforward: we look at the number of messages sent per unit of time at both the sender and the receiver. If we think of a pipe carrying water, we might look at a discrete cross section and the rate at which water passes through it.

Latency, as a concept, is equally simple. With the pipe, it’s the time it takes for a drop of water to travel from one end to the other. While throughput is dependent on the pipe’s diameter, latency is dependent upon its length. What this means is that we can’t derive one from the other. In order to properly measure latency, we need to consider the latency of each message sent through the system.

However, we can’t ignore the relationship between throughput and latency and what the compromise between them means. Generally, we want to make things as fast as possible. Consider a single-cycle CPU. Its latency per instruction will be extremely low but contrasted with a pipelined processor, its throughput is abysmal—one instruction per clock cycle. The implication is that if we trade per-operation latency for throughput, we actually get a _decrease_ in latency for aggregate instructions. Unfortunately, the benchmarks eschewed this relationship by requiring separate latency and throughput tests which used different code paths.

The interaction between latency and throughput is easy to get confused, but it often has interesting ramifications, whether you’re looking at message queues, CPUs, or databases. In a general sense, we’d say “optimize for latency” because lower latency means higher throughput, but the reality is it’s almost _always_ easier (and more cost-effective) to increase throughput than it is to decrease latency, especially on commodity hardware.

Capturing this data, in and of itself, isn’t terribly difficult, but what’s more susceptible to error is how it’s represented. This was the main fault of the benchmarks (in addition to the things described earlier). The most egregious thing they did was report latency as an average. This is like the _cardinal sin_ of benchmarking. The number is practically useless, particularly without any context like a standard deviation.

We know that latency isn’t going to be uniform, but it’s probably not going to follow a normal distribution either. While network latency may be prone to fitting a nice bell curve, system latency almost certainly won’t. They often exhibit things like GC pauses and other “hiccups,” and averages tend to hide these.

[![latency](/wp-content/uploads/2015/01/latency.png)](http://www.infoq.com/news/2010/09/bigmemory)

Measuring performance isn’t all that easy, but if you do it, at least [do it in a way that disambiguates the results](http://zedshaw.com/archive/programmers-need-to-learn-statistics-or-i-will-kill-them-all/). Look at quantiles, not averages. If you do present a mean, include the standard deviation and max _in addition to_ the 90th or 99th percentile. Plotting latency by percentile distribution is an excellent way to see what your performance behavior actually looks like. Gil Tene has a [great talk on measuring latency](http://www.infoq.com/presentations/latency-pitfalls) which I highly recommend.

### Working Towards a Better Solution

With all this in mind, we can work towards building a better way to test and measure messaging systems. The discussion above really just gives us three key takeaways:

1.  Don’t compare apples to oranges.
2.  Don’t instrument tests in a way that’s not at all representative of real life.
3.  Don’t present results in a statistically insignificant way.

My first attempt at taking these ideas to heart is a tool I call [Flotilla](https://github.com/tylertreat/Flotilla). It’s meant to provide a way to test messaging systems in more realistic configurations, at scale, while offering more useful data. Flotilla allows you to easily spin up producers and consumers on arbitrarily many machines, start a message broker, and run a benchmark against it, all in an automated fashion. It then collects data like producer/consumer throughput and the complete latency distribution and reports back to the user.

Flotilla uses a Go port of [HdrHistogram](http://hdrhistogram.github.io/HdrHistogram/) to capture latency data, of which I’m a _raving fan_. HdrHistogram uses a bucketed approach to record values across a configured high-dynamic range at a particular resolution. Recording is in the single-nanosecond range and the memory footprint is constant. It also has support for correcting [coordinated omission](https://groups.google.com/forum/#!msg/mechanical-sympathy/icNZJejUHfE/BfDekfBEs_sJ), which is a common problem in benchmarking. Seriously, if you’re doing anything performance sensitive, give HdrHistogram a look.

Still, Flotilla is [not perfect](https://github.com/tylertreat/Flotilla#caveats) and there’s certainly [work to do](https://github.com/tylertreat/Flotilla#todo), but I think it’s a substantial improvement over the previous MQ benchmarking utility. Longer term, it would be great to integrate it with something like [Comcast](https://github.com/tylertreat/Comcast) to test workloads under different network conditions. Testing in a vacuum is nice and all, but we know in the real word, [the network isn’t perfectly reliable](http://www.bravenewgeek.com/sometimes-kill-9-isnt-enough/).

### So, Where Are the Benchmarks?

Omitted—for now, anyway. My goal really isn’t to rank a hodgepodge of different message queues because there’s really not much value in doing that. There are different use cases for different systems. I might, at some point, look at individual systems in greater detail, but comparing things like message throughput and latency just devolves into a hotly contested pissing contest. My hope is to garner more feedback and improvements to Flotilla before using it to definitively measure anything.

_Benchmark responsibly._
