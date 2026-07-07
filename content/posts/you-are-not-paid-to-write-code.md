---
title: "You Are Not Paid to Write Code"
date: 2016-11-16T22:20:11-06:00
lastmod: 2016-12-20T22:36:31-06:00
slug: "you-are-not-paid-to-write-code"
categories: ["Culture", "Software Engineering", "Systems Theory"]
tags: ["not-invented-here syndrome", "software engineering", "systemantics", "systems", "systems theory", "taco bell programming", "the systems bible"]
---

[“Taco Bell Programming”](http://widgetsandshit.com/teddziuba/2010/10/taco-bell-programming.html) is the idea that we can solve many of the problems we face as software engineers with clever reconfigurations of the same basic Unix tools. The name comes from the fact that every item on the menu at Taco Bell, a company which generates almost _$2 billion_ in revenue annually, is simply a different configuration of roughly eight ingredients.

Many people grumble or reject the notion of using proven tools or techniques. It’s boring. It requires investing time to learn at the expense of shipping code.  It doesn’t do this one thing that we need it to do. It won’t work for us. For some reason—and I continue to be _completely baffled_ by this—everyone sees their situation as a unique snowflake despite the fact that a million other people have probably done the same thing. It’s a weird form of tunnel vision, and I see it at every level in the organization. I catch myself doing it on occasion too. I think it’s just human nature.

I was able to come to terms with this once I internalized something a colleague once said: **you are not paid to write code**. You have _never_ been paid to write code. In fact, code is a nasty byproduct of being a software engineer.

> Every time you write code or introduce third-party services, you are introducing the possibility of failure into your system.

I think the idea of Taco Bell Programming can be generalized further and has broader implications based on what I see in industry. There are a lot of parallels to be drawn from _The Systems Bible_ by John Gall, which provides valuable commentary on general systems theory. Gall’s Fundamental Theorem of Systems is that **new systems mean new problems**. I think the same can safely be said of code—more code, more problems. **Do it without a new system if you can.**

Systems are seductive and engineers in particular seem to have a [predisposition for them](https://bravenewgeek.com/not-invented-here/). They promise to do a job faster, better, and more easily than you could do it by yourself or with a less specialized system. But when you introduce a new system, you introduce new variables, new failure points, and new problems.

> But if you set up a system, you are likely to find your time and effort now being consumed in the care and feeding of the system itself. New problems are created by its very presence. Once set up, it won’t go away, it grows and encroaches. It begins to do strange and wonderful things. Breaks down in ways you never thought possible. It kicks back, gets in the way, and opposes its own proper function. Your own perspective becomes distorted by being in the system. You become anxious and push on it to make it work. Eventually you come to believe that the misbegotten product it so grudgingly delivers is what you really wanted all the time. At that point encroachment has become complete. You have become absorbed. You are now a systems person.

The last systems principle we look at is one I find particularly poignant: **almost anything is easier to get into than out of**. When we introduce new systems, new tools, new lines of code, we’re with them for the long haul. It’s like a baby that doesn’t grow up.

We’re not paid to write code, we’re paid to add value (or reduce cost) to the business. Yet I often see people measuring their worth in code, in systems, in tools—all of the output that’s easy to measure. I see it come at the expense of attending meetings. I see it at the expense of supporting other teams. I see it at the expense of cross-training and personal/professional development. It’s like full-bore coding has become the norm and we’ve given up everything else.

Another area I see this manifest is with the siloing of responsibilities. Product, Platform, Infrastructure, Operations, DevOps, QA—whatever the silos, it’s created a sort of [responsibility lethargy](https://bravenewgeek.com/shit-rolls-downhill/). “I’m paid to write software, not tests” or “I’m paid to write features, not deploy and monitor them.” Things of that nature.

I think this is only addressed by stewarding a strong engineering culture and instilling the right values and expectations. For example, engineers should understand that they are not defined by their tools but rather the problems they solve and ultimately the value they add. But it’s important to spell out that this goes beyond things like commits, PRs, and other vanity metrics. We should embrace the principles of systems theory and Taco Bell Programming. New systems or more code should be the last resort, not the first step. Further, we should embody what it really means to be an engineer rather than measuring raw output. You are not paid to write code.
