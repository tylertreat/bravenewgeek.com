---
title: "Using Make with React and RequireJS"
date: 2014-05-27T18:30:13-06:00
slug: "using-make-with-react-and-requirejs"
categories: ["JavaScript"]
tags: ["amd", "javascript", "jsx", "make", "makefile", "react", "requirejs"]
---

[RequireJS](http://requirejs.org/) is a great library for building modular JavaScript clients that conform to the [AMD API specification](https://github.com/amdjs/amdjs-api/wiki/AMD). It gives your JS an import-like mechanism by which you avoid global-namespace issues and makes your code behave more like a server-side language such as Python or Java. It also includes an optimization tool that can concatenate your JavaScript into a single file and minify it, which helps reduce HTTP overhead.

I recently wrote about [React](http://www.bravenewgeek.com/building-user-interfaces-with-react/ "Building User Interfaces with React"), which is a library targeted at constructing UIs. React uses a special syntax called JSX for specifying DOM components in XML, and it compiles down to vanilla JavaScript. JSX can either be precompiled or compiled in the browser at runtime. The latter option has obvious performance implications and probably shouldn’t be used in production, but it works great for quickly hacking something together.

However, if you’re using RequireJS and opt to defer JSX compilation to the browser, you’ll have problems loading your JSX modules since they aren’t valid JavaScript. Fortunately, there are RequireJS plugins to work around this, such as [require-jsx](https://github.com/seiffert/require-jsx), which lets you simply do the following:

<script src="https://gist.github.com/tylertreat/e59bb93633c227c4668d.js"></script>

The require-jsx plugin just performs the compilation when a module is loaded.

The other option, as I hinted at, is to precompile your JSX. This offloads the JSX transformation and allows Require’s optimizer to minify your entire client. React has a set of complementary tools, aptly named [react-tools](https://www.npmjs.org/package/react-tools), which includes a command-line utility for performing this compilation.

<script src="https://gist.github.com/tylertreat/c8cf0bcc223e942f0f6a.js"></script>

The jsx tool can also watch directories, doing the compilation whenever the source changes, with the \`–watch\` option.

Require now has no problem loading our React components since they are plain ole JavaScript—no special JSX plugins necessary. This also means we can easily hook in minification using Require’s [r.js](https://github.com/jrburke/r.js):

<script src="https://gist.github.com/tylertreat/6035ca81531c7d605904.js"></script>

You can use whatever build tool you want to tie all these things together. I personally prefer Make because it’s simple and ubiquitous.

<script src="https://gist.github.com/tylertreat/b9754ac10e881a82788a.js"></script>

Running \`make js\` will install my Bower dependencies, perform JSX compilation, and then minify the client. This workflow works well and makes it easy to setup different build steps, such as pip installing Python requirements, running integration and unit tests, and performing deploys.
