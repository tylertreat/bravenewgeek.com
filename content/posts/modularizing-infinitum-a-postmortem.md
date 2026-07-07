---
title: "Modularizing Infinitum: A Postmortem"
date: 2012-12-27T16:04:16-06:00
slug: "modularizing-infinitum-a-postmortem"
categories: ["Design Patterns", "Infinitum", "Java", "Postmortem", "Software Architecture"]
tags: ["android", "architecture", "design patterns", "github", "infinitum", "java", "retrospective"]
---

In addition to getting the code migrated from [Google Code](https://code.google.com/p/infinitum-framework/) to [GitHub](https://github.com/infinitumframework), one of my projects over the holidays was to modularize the Infinitum Android framework I’ve been working on for the past year.

Infinitum began as a SQLite ORM and quickly grew to include a REST ORM implementation,  REST client, logging wrapper, DI framework, AOP module, and, of course, all of the framework tools needed to support these various functionalities. It evolved as I added more and more features in a semi-haphazard way. In my defense, the code was organized. It was logical. It made _sense_. There was no method, but there also was no madness. Everything was in an appropriately named package. Everything was coded to an interface. There was no duplicated code. However, modularity — in terms of minimizing framework dependencies — wasn’t really in mind at the time, and the code was all in a single project.

### The Wild, Wild West

The issue wasn’t how the code was _organized_, it was how the code was _integrated_. The project was cowboy coding at its finest. I was the only stakeholder, the only tester, the only developer — judge, jury, and executioner. I was building it for my own personal use after all. Consequently, there was no planning involved, unit testing was somewhere between minimal and non-existent, and what got done was at my complete discretion. Ultimately, what was completed any given day, more or less, came down to what I felt like working on.

What started as an ORM framework became a REST framework, which became a logging framework, which became an IOC framework, which became an AOP framework. All of these features, built from the ground up, were tied together through a _context_, which provided framework configuration data. More important, the Infinitum context stored the bean factory used for storing and retrieving bean definitions used by both the framework and the client. The different modules themselves were not tightly coupled, but they were connected to the context like feathers on a bird.

![infinitum-arch](/wp-content/uploads/2012/12/infinitum-arch.png)

The framework began to grow large. It was only about 300KB of actual code (JARed without ProGuard compression), but it had a number of library dependencies, namely Dexmaker, Simple XML, and GSON, which is over 1MB combined in size. Since it’s an Android framework, I wanted to keep the footprint as small as possible. Additionally, it’s likely that someone wouldn’t be using _all_ of the features in the framework. Maybe they just need the SQLite ORM, or just the REST client, or just dependency injection. The way the framework was structured, they had to take it all or none.

### A Painter Looking for a Brush

I began to investigate ways to modularize it. As I illustrated, the central problem lay in the fact that the Infinitum context had knowledge of all of the different modules and was responsible for calling and configuring their APIs. If the ORM is an optional dependency, the context should not need to have knowledge of it. How can the modules be decoupled from the context?

Obviously, there is a core dependency, Infinitum Core, which consists of the framework essentials. These are things used throughout the framework in all of the modules — logging, DI ((I was originally hoping to pull out dependency injection as a separate module, but the framework relies heavily on it to wire up components.)), exceptions, and miscellaneous utilities. The goal was to pull off ORM, REST, and AOP modules.

My initial approach was to try and use the [decorator pattern](http://en.wikipedia.org/wiki/Decorator_pattern) to “decorate” the Infinitum context with additional functionality. The OrmContextDecorator would implement the ORM-specific methods, the AopContextDecorator would implement the AOP-specific methods, and so on. The problem with this was that it would still require the module-specific methods to be declared in the Infinitum context interface. Not only would they need to be stubbed out in the context implementation, a lot of module interfaces would need to be shuffled and placed in Infinitum Core  in order to satisfy the compiler. The problem remained; the context still had knowledge of all the modules.

I had another idea in mind. Maybe I could turn the Infinitum context from a single point of configuration to a hierarchical structure where each module has its own context as a “child” of the root context. The OrmContext interface could extend the InfinitumContext interface, providing ORM-specific functionality while still inheriting the core context methods. The implementation would then contain a reference to the parent context, so if it was unable to perform a certain piece of functionality, it could delegate to the parent. This could work. The Infinitum context has no notion of module X, Y, or Z, and, in effect, the control has been inverted. You could call it the Hollywood Principle — “Don’t call us, we’ll call you.”

![infinitum-context-hierarchy](/wp-content/uploads/2012/12/infinitum-context-hierarchy.png)

There’s still one remaining question: how do we identify the “child” contexts and subsequently initialize them? The solution is to maintain a module registry. This registry will keep track of the optional framework dependencies and is responsible for initializing them if they are available. We use a marker class from each module, a class we _know_ exists if the dependency is included in the classpath, to check its availability.

<script src="https://gist.github.com/tylertreat/a29413e9e0c871fe9a37.js"></script>

Lastly, we use reflection to instantiate an instance of the module context. I used an enum to maintain a registry of Infinitum modules. I then extended the enum to add an _initialize_ method which loads a context instance.

<script src="https://gist.github.com/tylertreat/483aed26b91affc5b358.js"></script>

The modules get picked up during a post-processing step in the ContextFactory. It’s this step that also adds them as child contexts to the parent.

<script src="https://gist.github.com/tylertreat/77deeb24cee7578659c2.js"></script>

New modules can be added to the registry without any changes elsewhere. As long as the context has been implemented, they will be picked up and processed automatically.

Once this architecture was in place, separating the framework into different projects was simple. Now Infinitum Core can be used by itself if only dependency injection is needed, the ORM can be included if needed for SQLite, AOP included for aspect-oriented programming, and Web for the RESTful web service client and various HTTP utilities.

### We Shape Our Buildings, and Afterwards, Our Buildings Shape Us

I think this solution has helped to minimize some of the complexity a bit. As with any modular design, not only is it more extensible, it’s more _maintainable_. Each module context is responsible for its own configuration, so this certainly helped to reduce complexity in the InfinitumContext implementation as before it was handling the initialization for the ORM, AOP, and REST pieces. It also worked out in that I made the switch to GitHub ((Now that the code’s pushed to GitHub, I begin the laborious task of migrating the documentation over from Google Code.)) by setting up four discrete repositories, one for each module.

In retrospect, I would have made things a lot easier on myself if I had taken a more modular approach from the beginning. I ended up having to reengineer quite a bit, although once I had a viable solution, it actually wasn’t all that much work. I was fortunate in that I had things fairly well designed (perhaps not at a very high level, but in general) and extremely organized. It’s difficult to anticipate change, but chances are you’ll be kicking yourself if you don’t. I started the framework almost a year ago, and I never imagined it would grow to what it is today.
