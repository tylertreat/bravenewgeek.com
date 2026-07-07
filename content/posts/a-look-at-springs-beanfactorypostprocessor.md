---
title: "A Look at Spring’s BeanFactoryPostProcessor"
date: 2012-12-04T22:42:54-06:00
slug: "a-look-at-springs-beanfactorypostprocessor"
categories: ["Java", "Spring"]
tags: ["beans", "classloader", "classpath", "java", "spring", "stubbing", "tomcat"]
---

One of the issues my team faced during my time at Thomson Reuters was keeping developer build times down. Many of the groups within WestlawNext had a fairly comprehensive check-in policy in that, after your code was reviewed, you had to run a full build which included running all unit tests and endpoint tests before you could commit your changes. This is a good practice, no doubt, but the group I was with had somewhere in the ballpark of 6000 unit tests. Moreover, since we were also testing our REST endpoints, it was necessary to launch an embedded Tomcat instance and deploy the application to it before those tests could execute.

Needless to say, build times could get pretty lengthy. I think I recall, at one point, it taking as long as 20 minutes to complete a full build. If a developer makes three commits in a day, that’s an hour of lost productivity. Extrapolate that out to a week and five hours are wasted, so you get the idea.

Of course, there were things we could do to cut down on that time — disabling the Cobertura and Javadoc Ant tasks for instance — but that only gets you so far. The annoying thing was that you typically had a Tomcat server running with the application already deployed, yet the build process started up a whole other instance in order to run the endpoint tests.

I explored the possibility of having endpoint tests run against a developer’s local server (or any server, in theory) by introducing a new property to the developer build properties file. It seems like a pretty simple concept: if the property doesn’t exist, run the tests normally by starting up an embedded Tomcat server. If it _does_ exist, then simply route the HTTP requests to the specified host. Granted, it’s not going to _significantly_ reduce the build time, but anything helps.

Unfortunately, it was _not_ that simple. That’s because we couldn’t just run endpoint tests against the “live” app. The underlying issue was that our API, which we called ourselves from JavaScript and was also exposed to other consumers, relied on some other WestlawNext web services, such as user authentication and document services. We weren’t doing end-to-end integration testing, we were just testing our API. As a result, we used a separate Spring context which allowed the embedded Tomcat hook to deploy the application using client _stubs_ in place of the actual web service clients.

So, things started to look a little moot. A developer would have to start their Tomcat server such that the client stub beans were registered with the Spring context in place of the normal client bean implementations. At the very least, it presented an interesting exercise. It was especially interesting because the client stubs were not part of the application’s classpath, they were separate from the app’s source and compiled to a bin-test directory.

### Introducing the BeanFactoryPostProcessor

The solution I came up with was to implement one of Spring’s less glamorous (but still really neat) interfaces, the [BeanFactoryPostProcessor](http://static.springsource.org/spring/docs/2.0.x/api/org/springframework/beans/factory/config/BeanFactoryPostProcessor.html). This interface provides a way for applications to modify their Spring context’s bean definitions before any beans get created. In my case, I needed to replace the client beans with their stub equivalents.

We start by implementing the interface, which has a single method, postProcessBeanFactory.

<script src="https://gist.github.com/tylertreat/a912aa32457ddd4d98ad.js"></script>

So the question is how do we implement registerClientStubBeans? This is the method that will overwrite the client beans in the application context, but in order to avoid the dreaded NoClassDefFoundError, we need to dynamically add the stub classes to the classpath.

<script src="https://gist.github.com/tylertreat/21cb0c65143ce67c9bb8.js"></script>

The addClasspathDependencies method will add the stubs to the classpath, while getClientStubBeans will do just as its name suggests. I’ve also created a Bean class that will hold a bean name and its BeanDefinition. In order to register beans with the BeanFactory, we use the registerBeanDefinition method and pass in a bean name and corresponding BeanDefinition.

Let’s take a look at how we can add the stubs to the classpath at runtime.

<script src="https://gist.github.com/tylertreat/e0fb625448a387998347.js"></script>

It looks like there’s a lot going on here, but it’s actually not too bad. The addClasspathDependencies method is simply going to call addToClasspath to add some classes we need, which include the stubs in bin-test but also some libraries they rely on in the libs directory. The more interesting code is in the latter of the two methods, which is responsible for taking a File, which will be a .class file, and adding it to the classpath. We do that by getting the context ClassLoader and then, using reflection, we invoke the method “addURL” by passing in the .class URL we want to add.

Lastly, we need to implement the getClientStubBeans method, which returns a list of the bean definitions we want to register with the context.

<script src="https://gist.github.com/tylertreat/4a346782f7c0190e47ba.js"></script>

Again, it’s a lot of code, but it’s not difficult to follow if you take it piece by piece. The getClientStubBeans method is going to get the directory in which the stubs classes are located and pass it to buildBeanDefinitions. This method iterates over each file, extracts the file name (e.g. “com/foo/client/stub/WebServiceClientStub.class”) and converts it into a fully-qualified class name (e.g. “com.foo.client.stub.WebServiceClientStub”). Since we already added the stubs to the classpath, the class is then loaded by this name. Once the class is loaded, we can check if it is indeed a stub by introspectively looking for the ClientStub annotation (this custom annotation makes a bean eligible for auto-detection and specifies a bean name). If it _is_ a stub, we use Spring’s handy [BeanDefinitionBuilder](http://static.springsource.org/spring/docs/2.5.x/api/org/springframework/beans/factory/support/BeanDefinitionBuilder.html) to build a BeanDefinition for the stub.

Now, when Spring initializes, it will detect this BeanFactoryPostProcessor and invoke its postProcessBeanFactory method, resulting in the client stubs being registered with the context in place of their respective implementations. It’s a pretty unique use case (and, frankly, not particularly useful for the given scenario), but it helps illustrate how the BeanFactoryPostProcessor interface can be leveraged.
