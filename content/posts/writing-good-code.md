---
title: "Writing Good Code"
date: 2015-04-07T19:50:38-05:00
slug: "writing-good-code"
categories: ["Software Engineering"]
tags: ["code quality", "optimization", "scrap", "software engineering", "tech debt"]
---

There’s no shortage of people preaching the importance of good code. Indeed, many make a [career of it](http://cleancoder.com). The [resources](http://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882) available are equally endless, but lately I’ve been wondering how to extract the essence of building high-quality systems into a shorter, more concise narrative. This is actually something I’ve thought about for a while, but I’m just now starting to formulate some ideas into a blog post. The ideas aren’t fully developed, but my hope is to flesh them out further in the future. You can talk about design patterns, abstraction, encapsulation, and cohesion until you’re blue in the face, but what is the _essence_ of good code?

Like any other engineering discipline, quality control is a huge part of building software. This isn’t just ensuring that it “works”—it’s ensuring it works under the complete range of operating conditions, ensuring it’s usable, ensuring it’s maintainable, ensuring it performs well, and ensuring a number of other characteristics. Verifying it “works” is just a small part of a much larger picture. Anybody can write code that works, but there’s more to it than that. Software is more malleable than most other things. Not only does it require longevity, it requires giving in to that malleability. If it doesn’t, you end up with something that’s brittle and broken. Because of this, it’s vital we **test for correctness and measure for quality**.

### SCRAP for Quality

Quality is a very subjective thing. How can one possibly measure it? Code complexity and static analysis tooling come to mind, and these are deservedly valued, but it really just scratches the surface. How do we narrow an immensely broad topic like “quality” into a set of tangible, quantifiable goals? This is really the crux of the problem, but we can start by identifying a sort of checklist or guidelines for writing software. This breaks that larger problem into smaller, more digestible pieces. The checklist I’ve come up with is called SCRAP, an acronym defined below. It’s unlikely to be comprehensive, but I think it covers most, if not all, of the key areas.

**S**calability

Plan for growth

**C**omplexity

Plan for humans

**R**esiliency

Plan for failure

**A**PI

Plan for integration

**P**erformance

Plan for execution

Each of these items is itself a blog post, so this is only a brief explanation. There is definitely overlap between some of these facets, and there are also multiple dimensions to some.

Scalability is a _plan for growth_—in code, in organization, in architecture, and in workload. Without it, you reach a point where your system falls over, whether it’s because of a growing userbase, a growing codebase, or any number of other reasons. It’s also worth pointing out that without the ‘S’, all you have is _CRAP_. This also helps illustrate some of the overlap between these areas of focus as it leads into Complexity, which is a _plan for humans_. Scalability is about technology scale and demand scale, but it’s also about _people scale_. As your team grows or as your company grows, how do you manage that growth at the code level?

Planning for people doesn’t just mean managing growth, it also means managing complexity. If code is overly complex, it’s difficult to maintain, it’s difficult to extend, and it’s difficult to fix. If systems are overly complex, they’re difficult to deploy, difficult to manage, and difficult to monitor. **Plan for humans, not machines.**

Resiliency is a strategy for fault tolerance. It’s a _plan for failure_. What happens when you crash? What happens when a service you depend on crashes? What happens when the database is unavailable? What happens when the network is unreliable? Systems of all kind need to be designed with the [expectation of failure](https://bravenewgeek.com/sometimes-kill-9-isnt-enough/). **If you’re not thinking about failure at the code level, you’re not thinking about it enough.**

One thing you should be noticing is that “people” is a cross-cutting concern. After all, it’s _people_ who design the systems, and it’s _people_ who write the code. While API is a _plan for integration_, it’s _people_ who integrate the pieces. This is about making your API a first-class citizen. It doesn’t matter if it’s an internal API, a library API, or a RESTful API. It doesn’t matter if it’s for first parties or third parties. **As a programmer, your API is your user interface.** It needs to be clean. It needs to be sensible. It needs to be well-documented. If those integration points aren’t properly thought out, the integration will be more difficult than it needs to be.

The last item on the checklist is Performance. I originally defined this as a plan for speed, but I realized there’s a lot more to performance than doing things fast. It’s about doing things _well_, which is why I call Performance a _plan for execution_. Again, this has some overlap with Resiliency and Scalability, but it’s also about measurement. It’s about benchmarking and profiling. It’s about testing at scale and under failure because testing in a vacuum doesn’t mean much. It’s about optimization.

This brings about the oft-asked question: how do I know when and where to optimize? While premature optimization might be the root of all evil, it’s not a universal law. **Optimize along the critical path and outward from there only as necessary.** The further you get from that critical path, the more wasted effort it’s going to end up being. It depreciates quickly, so don’t lose sight of your optimization ROI. This will enable you to ship _quickly_ and ship _quality_ code. But once you ship, you’re not done measuring! It’s more important than ever that you continue to measure in production. Use performance and usage-pattern data to drive intelligent decisions and intelligent iteration. The payoff is that this doesn’t just apply to code decisions, it applies to _all_ decisions. This is where the real value of measuring comes through. **Decisions that aren’t backed by data aren’t decisions, they’re impulses.** Don’t be impulsive, be _empirical_.

### Going Forward

There is work to be done with respect to quantifying the items on this checklist. However, I strongly suspect even just _thinking_ about them, formally or informally, will improve the overall quality of your code by an equally-unmeasurable order of magnitude. If your code doesn’t pass this checklist, it’s tech debt. Sometimes that’s okay, but remember that tech debt has compounding interest. If you don’t pay it off, you will eventually go bankrupt.

It’s not about being a 10x developer. It’s about being a 1x developer who writes 10x code. By that I mean the quality of your code is far more important than its quantity. Quality will outlast and outperform quantity. These guidelines tend to have a ripple effect. Legacy code often breeds legacy-_like_ code. Instilling these rules in your developer culture helps to make engineers cognizant of when they should break the mold, introduce new patterns, or improve existing ones. **Bad code begets bad code, and bad code is the atrophy of good developers.**
