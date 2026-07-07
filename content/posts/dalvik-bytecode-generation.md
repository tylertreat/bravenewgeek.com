---
title: "Dalvik Bytecode Generation"
date: 2012-12-17T20:03:57-06:00
slug: "dalvik-bytecode-generation"
categories: ["Android", "Infinitum", "Java"]
tags: ["android", "aop", "bytecode", "dalvik", "dex", "infinitum", "java", "jvm", "lazy loading", "proxies"]
---

[Earlier](http://www.bravenewgeek.com/proxies-why-theyre-useful-and-how-theyre-implemented/ "Proxies: Why They're Useful and How They're Implemented"), I discussed the use of dynamic proxies and how they can be implemented in Java. As we saw, a necessary part of proxying classes is bytecode generation. From its onset, something I wanted to include in Infinitum was lazy loading. I also wanted to provide support for AOP down the road. Consequently, it was essential to include some way to generate bytecode at runtime.

The obvious choice would be to use a library like [Cglib](http://cglib.sourceforge.net/) or [Javassist](http://www.csg.ci.i.u-tokyo.ac.jp/~chiba/javassist/), but sadly neither of those would work. That’s because Android does not use a Java VM, it uses its own virtual machine called _Dalvik_. As a result, Java source code isn’t compiled into Java bytecode (.class files), but rather Dalvik bytecode (.dex files). Since Cglib and Javassist are designed for Java bytecode manipulation, they do not work on the Android platform. (([ASMDEX](http://asm.ow2.org/asmdex-index.html), a Dalvik-compatible bytecode-manipulation library was released in March 2012, meaning Cglib could, in theory, be ported to Android since it relies on ASM.))

What’s a programmer to do? Fortunately, some Googlers developed a new library for runtime code generation targeting the Dalvik VM called [Dexmaker](http://code.google.com/p/dexmaker/).

> It has a small, close-to-the-metal API. This API mirrors the [Dalvik bytecode specification](http://source.android.com/tech/dalvik/dalvik-bytecode.html) giving you tight control over the bytecode emitted. Code is generated instruction-by-instruction; you bring your own abstract syntax tree if you need one. And since it uses Dalvik’s dx tool as a backend, you get efficient register allocation and regular/wide instruction selection for free.

Even better, Dexmaker provides an API for directly creating proxies called [ProxyBuilder](http://dexmaker.googlecode.com/git/javadoc/com/google/dexmaker/stock/ProxyBuilder.html). If you followed my previous post on generating proxies, then using ProxyBuilder is a piece of cake. Similar to Java’s [Proxy](http://docs.oracle.com/javase/1.4.2/docs/api/java/lang/reflect/Proxy.html) class, ProxyBuilder relies on an [InvocationHandler](http://docs.oracle.com/javase/1.4.2/docs/api/java/lang/reflect/InvocationHandler.html) to specify a proxy’s behavior.

<script src="https://gist.github.com/tylertreat/9931eeff6e5feab2b682.js"></script>

Dexmaker enabled me to implement lazy loading and AOP within the Infinitum framework. It also opens up the possibility of using [Mockito](http://code.google.com/p/mockito/) for unit testing in an Android environment because Mockito relies on proxies for generating mocks. ((Infinitum is actually unit tested using [Robolectric](http://pivotal.github.com/robolectric/), which allows for testing Android code in a standard JVM.))
