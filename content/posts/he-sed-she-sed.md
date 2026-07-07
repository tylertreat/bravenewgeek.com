---
title: "He Sed, She Sed"
date: 2013-01-01T03:26:10-06:00
slug: "he-sed-she-sed"
categories: ["Bash", "Unix"]
tags: ["command line", "gnu", "infinitum", "licensing", "osx", "sed", "unix"]
---

Shortly after switching to GitHub, I decided to relicense Infinitum from GNU LGPL to Apache License 2.0. There aren’t really any implications except one: replacing the license and copyright header in every source file.

I’m far from being a Unix expert (more like amateur at best), but I figured [sed](http://en.wikipedia.org/wiki/Sed) would be the quickest and easiest way to do this. Sed is a Unix utility for processing text streams, and it allows you to replace string patterns in files. A simple string replacement using sed is quite easy:

<script src="https://gist.github.com/tylertreat/d71c54286ebaaf192796.js"></script>

This will replace “foo” with “bar”. The “g” indicates that every matching occurrence in file.txt will be replaced, and “-i” means it will do the replacement in place.

In my case, I wanted to find every occurrence of the following string in _every_ Java source file:

<script src="https://gist.github.com/tylertreat/b96a9ec8818c415b89d8.js"></script>

And I wanted to replace it with this:

<script src="https://gist.github.com/tylertreat/ad04d2558f8586151b36.js"></script>

I needed to do a multi-line replacement across a couple hundred files. Feeding lots of files to sed is actually pretty simple:

<script src="https://gist.github.com/tylertreat/2017daadf4c632ad26ac.js"></script>

This command will pass all of the Java files in the current directory (and all sub-directories)  to sed. The reason xargs is needed is because it lets us avoid the “Argument list too long” problem.

In order to replace multiple lines, I needed to use an additional feature of sed. The “c” command lets you replace a range of lines:

<script src="https://gist.github.com/tylertreat/50b0297097b41e1ee40a.js"></script>

There’s a caveat that I have so far ignored. Many Unix utilities have idiosyncrasies or differences between platforms, and sed is no exception. I failed to mention that I was doing this on Mac OSX, whose implementation of sed, as I encountered, had some peculiar quirks. The “-e” in the above command is one such quirk as it’s needed to perform an in-place pattern replacement on OSX.

So, I had a way to process a bunch of files at once and a way to replace multiple lines in a file. Now I just needed to combine these two techniques to replace the license header in all of my project files.

<script src="https://gist.github.com/tylertreat/b901902db7e4dfbfc98c.js"></script>

This replaces the range of lines covering the original license with the new license. It works, but the formatting becomes slightly off. That’s because OSX’s sed does not preserve leading whitespace, so the space before each asterisk is stripped. Fortunately, [GNU sed](http://ftp.gnu.org/gnu/sed/) _does_ preserve leading whitespace, so building that and using it in place of OSX’s sed solved the problem. Also, GNU sed doesn’t require “-e” for in-place replacement.

Sed is a very handy little tool that every developer should have in his or her toolbelt. Admittedly, I don’t leverage Unix’s utilities nearly enough (although I’m working on it!), but tools like grep, sed, find, and xargs are immensely powerful and pretty simple to use. I think some developers have a tendency to over-engineer solutions for problems that could otherwise be solved using a trivial combination of these tools — I know I have! Of course, it’s helped that I’ve started to do all my programming, both work and play, on Mac. It’s my goal to become a better Unix developer!
