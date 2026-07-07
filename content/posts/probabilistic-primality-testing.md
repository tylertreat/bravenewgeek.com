---
title: "Probabilistic Primality Testing"
date: 2012-12-02T08:30:40+06:00
lastmod: 2018-09-13T23:23:09+06:00
slug: "probabilistic-primality-testing"
categories: ["Algorithms", "Mathematics"]
tags: ["algorithms", "cryptography", "deterministic", "encryption", "interview questions", "java", "math", "nondeterministic", "p vs np", "primality", "probability"]
---

An exceedingly common question asked in coding interviews is to write a function, method, algorithm, whatever to determine if a number is prime. Prime numbers have a wide range of applications in computer science, particularly with regard to cryptography. The idea is that factoring large numbers into their prime factors is extremely difficult.

> “Because both the system’s privacy and the security of digital money depend on encryption, a breakthrough in mathematics or computer science that defeats the cryptographic system could be a disaster. The obvious mathematical breakthrough would be the development of an easy way to factor large prime numbers.” -Bill Gates, [The Road Ahead](http://www.amazon.com/Road-Ahead-Book-CD-Pack/dp/1405879327)

Granted, for most programming positions, this question is asked not to test the candidate’s knowledge of determining primality, but rather as an exercise to gain insight into his or her thought process on a well-understood problem.

### The Naive Approach

The common approach to this problem is a simple brute-force solution. That is, divide the number ![{n}](/images/latex/0345d7ba96a43f71308b9998f4129742.png) by every integer from ![2](/images/latex/322128caedbe4e7dd5f1fc987570acb9.png) to ![n-1](/images/latex/0e0349ac0debe1a04aa841521bba08e3.png) and check the remainder. This is certainly the easiest way to solve the problem.

<script src="https://gist.github.com/tylertreat/5f8056bcff2fa2061a33.js"></script>

This is also incredibly inefficient. We can improve it a bit by checking factors from ![2](/images/latex/322128caedbe4e7dd5f1fc987570acb9.png) to ![n/2](/images/latex/a3325f70df93872936d4f9268bbe43e3.png), but that still isn’t very good for huge numbers. If ![n](/images/latex/fba40e36c7d0a229d9ef2b9be27178b4.png) is composite (i.e. it’s not prime), then it can be factored into two numbers, one of which must be less than or equal to ![\\sqrt{n}](/images/latex/845616bf8a34689d8258f8460af1fd1c.png). With this in mind, we can improve our algorithm even further.

<script src="https://gist.github.com/tylertreat/7af285a7400c77e3b381.js"></script>

These are the solutions your interviewer will probably be looking for, starting with the most naive approach and improving from that, but even the revised version is not very efficient.

### Probabilistic Testing

A slightly more sophisticated way to go about checking primality is to use probabilistic testing. Probabilistic tests use numbers, _a_, chosen at random from some sample space. This technique introduces a probability of error which can be reduced by repeating the test with independently selected _a_ values.

There are a number of different probabilistic primality tests, some better than others.  One of the more simple probabilistic primality tests is the Fermat primality test, which is based on [Fermat’s little theorem](http://en.wikipedia.org/wiki/Fermat's_little_theorem) and is used in PGP and RSA encryption. The theorem states that, if _p_ is prime, then ![a^{p-1} \\equiv 1 \\pmod{p}](/images/latex/68a04a6526c4e8ad1eca8351ebc208f4.png) where ![1\\leq a < p](/images/latex/80e5fc93185c3fe972531f19220c1dd7.png).

<script src="https://gist.github.com/tylertreat/8b5c1c4e53aa009f2ba5.js"></script>

This method will indicate if _p_ is a _probable_ prime, but since we’re only selecting a single _a_ value, the possibility of _p_ being _incorrectly_ identified as a prime is high. In such situations, _a_ is referred to as a _Fermat liar_. As suggested earlier, we can minimize this probability by repeating the process _k_ times and selecting _k_ witnesses.

<script src="https://gist.github.com/tylertreat/37f44fc9d668f4b553b3.js"></script>

This allows us to improve the probability of correctly determining the primality of _p_ by performing _k_ iterations, in which the probability of error becomes vanishingly small for large values of _k_. Nonetheless, being probabilistic in nature, this algorithm is inherently _nondeterministic_, which is really just a fancy way of saying we can get _different_ results on _different_ runs for the _same_ input.

### Polynomial, Deterministic Algorithms

Only within the last decade has a deterministic, polynomial-time algorithm for testing primality been developed. In 2002, the [AKS primality test](http://en.wikipedia.org/wiki/AKS_primality_test) was discovered, moving primality into the P complexity class. The algorithm determines if a given number is prime or composite in polynomial time, and it’s the first to be simultaneously general, polynomial, unconditional, _and_ deterministic. Try busting _that_ out at an interview.

For the mathematically inclined (of which I do not consider myself), primality presents some interesting uses and even more interesting problems. It’s remarkable that a fast, deterministic solution for such a well-defined problem was found only in the last 10 years, and it makes you wonder what tough problems will be solved in the next 10 years and beyond.
