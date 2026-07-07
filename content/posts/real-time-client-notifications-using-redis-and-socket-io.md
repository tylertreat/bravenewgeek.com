---
title: "Real-Time Client Notifications Using Redis and Socket.IO"
date: 2014-03-08T19:18:33-06:00
slug: "real-time-client-notifications-using-redis-and-socket-io"
categories: ["JavaScript", "Messaging", "Python", "Software Architecture"]
tags: ["backbone", "flask", "gevent", "gevent-socketio", "javascript", "pubsub", "python", "redis", "server-sent events", "socket.io", "websockets"]
---

Backbone.js is great for building structured client-side applications. Its declarative event-handling makes it easy to listen for actions in the UI and keep your data model in sync, but what about changes that occur to your data model on the server? Coordinating user interfaces for data consistency isn’t a trivial problem. Take a simple example: users A and B are viewing the same data at the same time, while user A makes a change to that data. How do we propagate those changes to user B? Now, how do we do it at scale, say, several thousand concurrent users? What about external consumers of that data?

One of our products at WebFilings called for real-time notifications for a few reasons:

1.  We needed to keep users’ view of data consistent.
2.  We needed a mechanism that would alert users to changes in the web client (and allow them to subscribe/unsubscribe to certain events).
3.  We needed notifications to be easily consumable (beyond the scope of a web client, e.g. email alerts, monitoring services, etc.).

I worked on developing a pattern that would address each of these concerns while fitting within our platform’s ecosystem, giving us a path of least resistance with maximum payoff.

Polling sucks. Long-polling isn’t much better. [Server-Sent Events](http://dev.w3.org/html5/eventsource/) are an improvement. They provide a less rich API than the [WebSocket protocol](https://tools.ietf.org/html/rfc6455), which supports bi-directional communication, but they do have some niceties like handling reconnects and operating over traditional HTTP. [Socket.IO](http://socket.io/) provides a nice wrapper around WebSockets while falling back to other transport methods when necessary. It has a rich API with features like namespaces, multiplexing, and reconnects, but it’s built on Node.js, which means it doesn’t plug into our Python stack very easily.

The solution I decided on was a library called [gevent-socketio](https://github.com/abourget/gevent-socketio), which is a Python implementation of the Socket.IO protocol built on [gevent](http://www.gevent.org/), making it incredibly simple to hook in to our existing [Flask](http://flask.pocoo.org/) app. [  
](http://www.gevent.org/)

The gevent-socketio solution really only solves a small part of the overarching problem by providing a way to broadcast messages to clients. We still need a way to hook these messages in to our Backbone application and, more important, a way to publish and subscribe to events across threads and processes. The Socket.IO dispatcher is just one of potentially _many_ consumers after all.

The other piece of the solution is to use [Redis](http://redis.io/) for its excellent pubsub capabilities. Redis allows us to publish and subscribe to messages from anywhere, even from different machines. Events that occur as a result of user actions, task queues, or cron jobs can all be captured and published to any interested parties as they happen. We’re already using Redis as a caching layer, so we get this for free. The overall architecture looks something like this:

[![pubsub](/wp-content/uploads/2014/03/pubsub.png)](/wp-content/uploads/2014/03/pubsub.png)

Let’s dive into the code.

Hooking gevent-socketio into our Flask app is pretty straightforward. We essentially just wrap it with a SocketIOServer.

<script src="https://gist.github.com/tylertreat/dcf866751c843c51e9af.js"></script>

The other piece is registering client subscribers for notifications:

<script src="https://gist.github.com/tylertreat/ee0575d43368477a164f.js"></script>

NotificationsNamespace is a Socket.IO namespace we will use to broadcast notification messages. We use gevent-socketio’s BroadcastMixin to multicast messages to clients.

<script src="https://gist.github.com/tylertreat/ca2ecaf21cde8f2c7fc3.js"></script>

When a connection is received, we spawn a greenlet that listens for messages and broadcasts them to clients in the notifications namespace. We can then build a minimal API that can be used across our application to publish notifications.

<script src="https://gist.github.com/tylertreat/1053805c13e8d1c9accd.js"></script>

Wiring notifications up to the UI is equally simple. To facilitate communication between our Backbone components while keeping them decoupled, we use an event-dispatcher pattern relying on [Backbone.Events](http://backbonejs.org/#Events). The pattern looks something like this:

<script src="https://gist.github.com/tylertreat/d35eeab40c0937891ea9.js"></script>

This pattern makes it trivial for us to allow our views, collections, and models to subscribe to our Socket.IO notifications because we just have to pump the messages into the dispatcher pipeline.

<script src="https://gist.github.com/tylertreat/19b46b1503bbbf4d809b.js"></script>

Now our UI components can subscribe and react to client- and server-side events as they see fit and in a completely decoupled fashion. This makes it very easy for us to ensure our client-side views and models are updated automatically while also letting other services consume these events.
