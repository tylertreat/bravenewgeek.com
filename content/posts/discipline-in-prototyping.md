---
title: "Discipline in Prototyping"
date: 2013-06-10T19:33:31-06:00
slug: "discipline-in-prototyping"
categories: ["Software Engineering"]
tags: ["agile", "lean", "minimum viable product", "process", "productivity", "prototyping", "software engineering", "tdd"]
---

Writing software doesn’t require discipline, but writing _good_ software does. I would argue that the vast majority of tech debt in projects results from PoCs/prototypes/spikes. The code from these typically aren’t intended to make it into production, but they almost invariably do in some capacity.

“I won’t bother writing unit tests for this code, it’s purely exploratory.”

The code grows…

“It’s just a rough proof-of-concept.”

…and grows…

“It won’t make it to production!”

…and grows, until pressure from above or other factors bulldoze it into a release.

This problem is _not_ difficult to avoid, it’s entirely disciplinary. Spikes should _always_ be timeboxed, but truthfully, this problem rarely occurs because of spikes—it happens at the onset of projects. Nearly every project gets its start as a proof-of-concept, which becomes a prototype, which becomes a product.

It’s during this process, as a project reaches its infancy, where tech debt has a tendency to accumulate like a cancerous growth. Less seasoned developers might skip out on writing unit tests or forgo code reviews because, well, _it’s a prototype_. This is especially tempting when you’re working in a codebase by yourself. I myself have been caught in this rut before.

I’m not saying you need to use TDD for every line of code you write (or, for that matter, _at all_), but, for the love of god, write unit tests around your code. If you’re writing code that’s in source control, it’s set in stone for everyone to see and, more important, maintain (and if it’s not in source control, it doesn’t exist). Write code like it will end up in production (because frankly, it probably will).

“Minimum viable product” is a popular buzzword these days but holds merit when used in the right context. What’s important to note is that an MVP is _not_ a proof-of-concept nor a prototype. A PoC is a great way to sketch out an early draft, but an MVP is not a draft. Building something under the guise of an MVP and renouncing standard development procedures is a wildly mistaken approach.

It takes discipline. It might even take getting yourself caught in a tech-debt-riddled project before realizing just how crucial it is, but it _will_ make you a better software developer and certainly make your projects more sustainable.
