---
title: "Building User Interfaces with React"
date: 2014-05-21T18:19:41-06:00
slug: "building-user-interfaces-with-react"
categories: ["JavaScript"]
tags: ["javascript", "react"]
---

If you follow me on Twitter, you’ve probably heard me raving about [React](http://facebook.github.io/react/). React is described as a “JavaScript library for building user interfaces” and was open sourced by Facebook about a year ago. Everybody and their mom has a JavaScript framework, so what makes React so interesting? Why would you use it over mainstays like Backbone or Angular?

There are a few things that make React worth looking at. First, React is a _library_, not a framework. It makes no assumptions about your frontend stack, and it plays nicely with existing codebases, regardless of the tech you’re using. This is great because you can use React incrementally for new or legacy code. Write your whole UI with it or use it for a single feature. All you need is a DOM node to mount.

React is delightfully simple (contrasted with Angular, which is a nightmare for beginners, and Backbone, which is relatively simple but still has several core concepts). It’s built around one idea: the Component, which is merely a reusable unit of UI. React was designed from the ground-up to be composable—Components are composed of other Components. _Everything_ in the DOM is a Component, so your UI consists of a hierarchy of them.

Components can be built using JSX, an XML-like syntax that compiles down to regular JavaScript. As such, they can also be specified using plain-old JavaScript. The result is the same, but JSX makes it easy to visualize your DOM.

<script src="https://gist.github.com/tylertreat/b4e1beb372afd39af1d7.js"></script>

React does not do two-way data binding ((It’s worth noting that React provides a small add-on for getting the conciseness of two-way binding with the correctness of its one-way binding model.)). This is _by design_. It uses the [von Neumann model of dataflow](http://en.wikipedia.org/wiki/Von_Neumann_architecture), which means data flows in only one direction. Two-way data binding makes it difficult to reason about your code. The advantage of the one-way model that React adopts is that it essentially turns your UI into a deterministic state machine. On the surface, it behaves as if the entire UI is simply re-rendered based on the current state of your data model. If you know what state your data is in, you know _exactly_ what state your UI is in. Your UI is predictable. The React mantra is _“re-render, don’t mutate.”_

Re-rendering the entire DOM sounds expensive, but this is where React really shines. In order to draw your UI, it maintains a virtual DOM which can then be diffed. React’s diffing algorithm determines the minimum set of Components that need to be updated. It also batches reads and writes to the real DOM. This makes React _fast._

Data is modeled two ways in a React component, _props_ and _state_, which highlights the one-way data flow described earlier. Props consist of data that is passed from parent to child. A Component’s props can _only_ be set by its parent. State, on the other hand, is an internal data structure that is accessed and modified only from within a Component. A Component is re-rendered when either its props or state is updated.

<script src="https://gist.github.com/tylertreat/b6f73b1d447573783781.js"></script>

Once again, this makes it really easy to reason about your code (and unit test). Also note the use of the onClick handler. React provides a synthetic event system that gives you cross-browser compatible event listeners that you can attach to Components.

React and Backbone’s [Router](http://backbonejs.org/#Router) is a surprisingly powerful, yet effortless, combination for building single-page applications.

<script src="https://gist.github.com/tylertreat/3db4e851dc4ea2710be4.js"></script>

React makes it trivial to build small web apps, but because of its affinity for reusability and data modeling, it also scales well for large, complex UIs. You don’t have to use it for a new project, just start replacing small pieces of your UI with React Components. This makes it a lot easier for developers to adopt.
