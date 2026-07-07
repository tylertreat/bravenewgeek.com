---
title: "Implementing Spring-like Classpath Scanning in Android"
date: 2013-01-05T02:53:36-06:00
lastmod: 2019-01-25T10:52:38-06:00
slug: "implementing-spring-like-classpath-scanning-in-android"
categories: ["Android", "Infinitum", "Java", "Spring"]
tags: ["android", "beans", "bytecode", "classloader", "classpath", "dalvik", "dex", "dexopt", "infinitum", "java", "reflection", "spring"]
---

One of the things that Spring 2.5 introduced back in 2007 was component scanning, a feature which removed the need for XML bean configuration and instead allowed developers to declare their beans using Java annotations. Rather than this:

<script src="https://gist.github.com/tylertreat/7688bafe73aa1eaeaa24.js"></script>

We can do this:

<script src="https://gist.github.com/tylertreat/937b3e36d6ecdcbc7c3b.js"></script>

It’s a pretty simple idea since Java makes it very easy to introspectively check a class’s annotations at runtime through its reflection API. Spring’s component scan feature also allows you to specify the base package(s) to scan for beans.

<script src="https://gist.github.com/tylertreat/ba90b40f96785bc0ebd8.js"></script>

The big question is how do we get access to the classes in the classpath, specifically, those in the desired package? Java SE doesn’t provide an API for doing it, but there are ways to accomplish this. The most common (if not the only) approach is to load classes by relying on the file system. We know that we can use the ClassLoader to load a class by its package-qualified name, so it becomes a matter of retrieving the file names.

Getting the classpath itself in Java SE is easy:

<script src="https://gist.github.com/tylertreat/aaa598261c6bc270d8fc.js"></script>

This will yield something that looks like “/Users/Tyler/Workspace/Test/bin:/Users/Tyler/Workspace/Test/lib/gson-2.1.jar”. Loading the files from here is pretty straightforward, as is filtering on the package name since it maps to a directory one-to-one.

Another similar approach is to use the ClassLoader to load the resources directly:

<script src="https://gist.github.com/tylertreat/809c73358bf7bf3a4565.js"></script>

### Transition to Android

Unfortunately, these solutions don’t lend themselves to Android, which made implementing classpath scanning a little more difficult for Infinitum. The reason for this is, more or less, because of the way Android’s Dalvik VM is designed. When an Android application is compiled, the Dalvik bytecode is packaged into a file called “classes.dex” inside the APK. The good news is that the Android SDK provides an API for interacting with DEX files through the [DexFile](http://developer.android.com/reference/dalvik/system/DexFile.html) class.

In order to access classes.dex, we need a handle on the APK itself, which is actually quite easy to do:

<script src="https://gist.github.com/tylertreat/ec19dc52fe73b482f799.js"></script>

The above code opens a DexFile for the running APK. Of course, this _can_ have some performance implications. Opening the DexFile will potentially cause the VM to pass classes.dex through a process known as “dexopt”, which is a program that performs bytecode verification and optimization. This is an expensive process, but since we’re opening a DexFile for the APK itself, classes.dex should have already undergone this process, meaning dexopt won’t be run again.

<script src="https://gist.github.com/tylertreat/87190dc7faae9e3cb8ad.js"></script>

The DexFile gives us access to the classes contained in classes.dex as an enumeration of strings representing the package-qualified class names. With this, we can iterate over the class names and load any which match the desired package.

<script src="https://gist.github.com/tylertreat/99edd58ec018fa20a0c9.js"></script>

This gets the job done, and it’s essentially how Infinitum accomplishes component scanning. However, it’s a very expensive operation. DexFile.entries() yields _every_ class in the classpath — that is, every class in classes.dex — which includes not just application binaries, but also those of any libraries included.

It’s great that we can introspect every class in the classpath, but if we’re only interested in classes of a particular package, we’re out of luck. Every class is compiled into classes.dex and, short of decompiling it ((Tools for decompiling DEX files exist, such as [Baksmali](http://code.google.com/p/smali/), but doing such a thing at runtime — if it’s even possible — would arguably not gain you any performance benefits. Still, this is something worth exploring.)),  there’s no way to pull out the classes we want without iterating over the entire classpath.

So, for now we settle with this somewhat inefficient solution. Nonetheless, it accomplishes what it needs to at the cost of maybe a few hundred milliseconds ((On the emulator running on my MacBook Pro, the classpath scanning takes about 600 milliseconds, while on my Galaxy Nexus, it takes about 200 milliseconds.)), so maybe it’s not such a bad approach in the grand scheme of things.
