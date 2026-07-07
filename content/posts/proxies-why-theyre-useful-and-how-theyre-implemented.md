---
title: "Proxies: Why They’re Useful and How They’re Implemented"
date: 2012-12-17T17:22:52-06:00
slug: "proxies-why-theyre-useful-and-how-theyre-implemented"
categories: ["Design Patterns", "Java"]
tags: ["aop", "bytecode", "design patterns", "java", "lazy loading", "proxies"]
---

I wanted to write about lazy loading, but doing so requires some background on proxies. Proxies are such an interesting and useful concept that I decided it would be worthwhile to write a separate post discussing them. I’ve talked about them in the past, for instance on [StackOverflow](http://stackoverflow.com/a/10239705/210070), so this will be a bit of a rehash, but I will go into a little more depth here.

What is a proxy? Fundamentally, it’s a broker, or mediator, between an object and that object’s user, which I will refer to as its client. Specifically, a proxy intercepts calls to the object, performs some logic, and then (typically) passes the call on to the object itself. I say _typically_ because the proxy could simply intercept without ever calling the object.

![proxy](/wp-content/uploads/2012/12/proxy.png)

A proxy works by implementing an object’s non-final methods. This means that proxying an interface is pretty simple because an interface is merely a list of method signatures that need to be implemented. This facilitates the interception of method invocations quite nicely. Proxying a concrete class is a bit more involved, and I’ll explain why shortly.

Proxies are useful, _very useful._ That’s because they allow for the modification of an object’s behavior and do so in a way that’s completely invisible to the user. Few know about them, but many use them, usually without even being aware of it. Hibernate uses them for lazy loading, Spring uses them for aspect-oriented programming, and Mockito uses them for creating mocks. Those are just three (huge) use cases of many.

### JDK Dynamic Proxies

Java provides a [Proxy](http://docs.oracle.com/javase/1.4.2/docs/api/java/lang/reflect/Proxy.html) class which implements a list of interfaces at runtime. The behavior of a proxy is specified through an implementation of [InvocationHandler](http://docs.oracle.com/javase/1.4.2/docs/api/java/lang/reflect/InvocationHandler.html), an interface which has a single method called invoke. The signature for the invoke method looks like the following:

<script src="https://gist.github.com/tylertreat/e9e9be42b8d5a63a3fbd.js"></script>

The proxy argument is the proxy instance the method was invoked on. The method argument is the Method instance corresponding to the interface method invoked on the object.  The last argument, args, is an array of objects which consists of the arguments passed in to the method invocation, if any.

Each proxy has an InvocationHandler associated with it, and it’s this handler which is responsible for delegating method calls made on the proxy to the object being proxied. This level of indirection means that methods are not invoked on an object itself but rather on its proxy. The example below illustrates how an InvocationHandler would be implemented such that “Hello World” is printed to the console before every method invocation.

<script src="https://gist.github.com/tylertreat/5905e71d1dc535529b99.js"></script>

This is pretty easy to understand. The invoke method will intercept any method call by printing “Hello World” before delegating the invocation to the proxied object. It’s not very useful, but it _does_ lend some insight into why proxies are useful for AOP.

An interesting observation is that invoke provides a reference to the proxy itself, meaning if you were to instead call the method on it, you would receive a StackOverflowError because it would lead to an infinite recursion.

Note that the InvocationHandler alone is of no use. In order to actually create a proxy, we need to use the Proxy class and provide the InvocationHandler. Proxy provides a static method for creating new instances called newProxyInstance. This method takes three arguments, a class loader, an array of interfaces to be implemented by the proxy, and the proxy behavior in the form of an InvocationHandler. An example of creating a proxy for a List is shown below.

<script src="https://gist.github.com/tylertreat/95538d521367dd23d038.js"></script>

The client invoking methods on the List can’t tell the difference between a proxy and its underlying object representation, nor should it care.

### Proxying Classes

While proxying an interface dynamically is relatively straightforward, the same cannot be said for proxying a class. Java’s Proxy class is merely a runtime implementation of an interface or set of interfaces, but a class does not _have_ to implement an interface at all. As a result, proxying classes requires bytecode manipulation. Fortunately, there are libraries available which help to facilitate this through a high-level API. For example, [Cglib](http://cglib.sourceforge.net/) (short for code-generation library) provides a way to extend Java classes at runtime and [Javassist](http://www.csg.ci.i.u-tokyo.ac.jp/~chiba/javassist/) (short for Java Programming Assistant) allows for both class modification and creation at runtime. It’s worth pointing out that Spring, Hibernate, Mockito, and various other frameworks make heavy use of these libraries.

Cglib and Javassist provide support for proxying classes because they can dynamically generate bytecode (i.e. class files), allowing us to extend classes at runtime in a way that Java’s Proxy can implement an interface at runtime.

At the core of Cglib is the Enhancer class, which is used to generate dynamic subclasses. It works in a similar fashion to the JDK’s Proxy class, but rather than using a JDK InvocationHandler, it uses a Callback for providing proxy behavior. There are various Callback extensions, such as InvocationHandler (which is a replacement for the JDK version), LazyLoader, NoOp, and Dispatcher.

<script src="https://gist.github.com/tylertreat/9e748545586fb3eabfb7.js"></script>

This code is essentially the same as the earlier example in that every method invocation on the proxied object will first print “Hello World” before being delegated to the actual object. The difference is that MyClass does not implement an interface, so we didn’t need to specify an array of interfaces for the proxy.

Proxies are a very powerful programming construct which enables us to implement things like lazy loading and AOP. In general, they allow us to alter the behavior of objects transparently. In the future, I’ll dive into the specific use cases of lazy loading and AOP.
