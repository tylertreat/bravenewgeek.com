---
title: "The Importance of Being Idle"
date: 2012-12-19T19:12:36-06:00
slug: "the-importance-of-being-idle"
categories: ["Design Patterns", "Java"]
tags: ["aop", "design patterns", "graphs", "hibernate", "infinitum", "java", "lazy loading", "orm", "proxies"]
---

_“Practice not-doing and everything will fall into place.”_

It’s good to be lazy. Sometimes, in programming, it can also be hard to be lazy. It’s this paradox that I will explore today — The Art of Being Lazy. Specifically, I’m going to dive into a design pattern known as lazy loading by discussing why it’s used, the different flavors it comes in, and how it can be implemented.

Lazy loading is a pretty simple concept: don’t load something until you really need it. However, the philosophy can be generalized further: don’t do something until you need to do it. It’s this line of thinking that has helped lead to processes like [Kanban](http://en.wikipedia.org/wiki/Kanban_\(development\)) and [lean software development](http://en.wikipedia.org/wiki/Lean_software_development) (and also probably got you through high school). Notwithstanding, this tenet goes beyond the organizational level. It’s about optimizing efficiency and minimizing waste. There’s a lot to be said about optimizing efficiency in a computer program, which is why The Art of Being Lazy is an exceedingly relevant principle.

### They Don’t Teach You This in School

My first _real_ job as a programmer was working as a contractor for Thomson Reuters.  I started as a .NET developer (having no practical experience with it _whatsoever_) working on a web application that primarily consisted of C# and ASP.NET. The project was an internal [configuration management database](http://en.wikipedia.org/wiki/Configuration_management_database), which is basically just a big database containing information pertaining to all of the components of an information system (in this case, Thomson’s _West Tech_ network, the infrastructure behind their legal technology division).

This CMDB was geared towards providing application-impact awareness, which, more or less, meant that operations and maintenance teams could go in and see what applications or platforms would be affected by a server going down (hopefully for scheduled maintenance and not a datacenter outage), which business units were responsible for said applications, and who the contacts were for those groups. It also provided various other pieces of information pertaining to these systems, but what I’m getting at is that we were dealing with a lot of data, and this data was all interconnected. We had a very complex domain model with a lot of different relationships. What applications are running on what app servers? Which database servers do they depend on? What NAS servers have what NAS volumes mounted on them? The list goes on.

Our object graph was immense. You can imagine the scale of infrastructure a company like Thomson Reuters has. The crux of the problem was that we were persisting all of this data as well as the relationships between it, and we wanted to allow users of this software to navigate this vast hierarchy of information. Naturally, we used an ORM to help manage this complexity. Since we were working in .NET, and many of us were Java developers, we went with [NHibernate](http://nhforge.org/).

We wanted to be able to load, say, an application server, and see _all_ of the entities associated with it. To the uninitiated (which, at the time, would have included myself), this might seem like a daunting task. Loading any given entity would result in loading hundreds, if not _thousands_, of related entities because it would load those directly related, then those related to the immediate neighbors, continuing on in what seems like a never-ending cascade. Not only would it take forever, but we’d quickly run out of memory! There’s simply _no way_ you can deal with an object graph of that magnitude and reasonably perform any kind of business logic on it. Moreover, it’s certainly not _scalable_, so obviously this would be a very naive thing to do. The good news is that, unsurprisingly,  it’s something that’s not _necessary_ to do.

### It’s Good to be Lazy

The solution, of course, as I’ve already hit you across the face with, is a design pattern known as _lazy loading_. The idea is to defer initialization of an object until it’s truly needed (i.e. accessed). Going back to my anecdote, when we load, for example, an application server entity, rather than eagerly loading all its associated entities, such as servers, applications, BIG-IPs, etc., we use placeholders. Those related entities are then loaded on-the-fly when they are accessed.

Lazy loading can be implemented in a few different ways, through lazy initialization, ghost objects, value holders, and dynamic proxies — each has its own trade-offs. I’ll talk about all of them, but I’m going to primarily focus on using proxies since it’s probably the most widely-used approach, especially within the ORM arena.

Lazy initialization probably best illustrates the concept of lazy loading. With lazy initialization, the object to be lazily loaded is represented by a special marker value (typically null) which indicates that the object has yet to be loaded. Every call to the object will first check to see if it has been loaded/initialized, and if it hasn’t, it gets loaded/initialized. Thus, the first call to the object will load it, while subsequent calls will not need to. The code below shows how this is done.

<script src="https://gist.github.com/tylertreat/0e428bed8ca728c6fd98.js"></script>

Ghost objects are simply entities that have been partially loaded, usually just having the ID populated so that the full object can be loaded later. This is very similar to lazy initialization. The difference is that the related entity is initialized but not populated.

<script src="https://gist.github.com/tylertreat/4aa97ed1dffdb71ba5fd.js"></script>

A value holder is an object that takes the place of the lazily loaded object and is responsible for loading it. The value holder has a getValue method which does the lazy loading. The entity is loaded on the first call to getValue.

<script src="https://gist.github.com/tylertreat/28f52e6574ed78fb2ad1.js"></script>

The above solutions get the job done, but their biggest problem is that they are pretty intrusive. The classes have knowledge that they are lazily loaded and require logic for loading. Luckily, there’s an option which helps to avoid this issue. Using dynamic proxies ((For more background on proxies themselves, check out one of my [previous posts](http://www.bravenewgeek.com/proxies-why-theyre-useful-and-how-theyre-implemented/ "Proxies: Why They're Useful and How They're Implemented").)), we can write an entity class which has no knowledge of lazy loading and yet still lazily load it if we want to.

This is possible because the proxy extends the entity class or, if applicable, implements the same interface, allowing it to intercept calls to the entity itself. That way, the object need not be loaded, but when it’s accessed, the proxy intercepts the invocation, loads the object if needed, and then delegates the invocation to it. Since proxying classes requires bytecode instrumentation, we need to use a library like [Cglib](http://cglib.sourceforge.net/).

First, we implement an [InvocationHandler](http://docs.oracle.com/javase/1.4.2/docs/api/java/lang/reflect/InvocationHandler.html) we can use to handle lazy loading.

<script src="https://gist.github.com/tylertreat/a24eb6090198db2af7eb.js"></script>

Now, we can use Cglib’s Enhancer class to create a proxy.

<script src="https://gist.github.com/tylertreat/13f9c1e56031d2d6c8df.js"></script>

Now, the first call to any method on foo will invoke loadObject, which in turn will load the object into memory. Cglib actually provides an interface for doing lazy loading called LazyLoader, so we don’t even need to implement an InvocationHandler.

<script src="https://gist.github.com/tylertreat/abadd3f63a62f28c3973.js"></script>

ORM frameworks like Hibernate use proxies to implement lazy loading, which is one of the features we took advantage of while developing the CMDB application. One of the nifty things that Hibernate supports is paged lazy loading, which allows entities in a collection to be loaded and unloaded while it’s being iterated over. This is extremely useful for one-to-many and, in particular, one-to-_very_\-many relationships.

Lazy loading was also one of the features I included in Infinitum’s ORM, implemented using dynamic proxies as well. ((Java bytecode libraries like Cglib are not compatible on the Android platform. Android uses its own [bytecode variant](http://www.bravenewgeek.com/dalvik-bytecode-generation/ "Dalvik Bytecode Generation").)) At a later date, I may examine how lazy loading is implemented within the context of an ORM and how Infinitum uses it. It’s a very useful design pattern and provides some pretty significant performance optimizations. It just goes to show that sometimes being lazy pays off.
