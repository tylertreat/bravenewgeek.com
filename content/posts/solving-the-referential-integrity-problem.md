---
title: "Solving the Referential Integrity Problem"
date: 2012-12-01T13:37:46-06:00
slug: "solving-the-referential-integrity-problem"
categories: ["Databases", "Design Patterns", "Infinitum", "Java"]
tags: ["android", "caching", "databases", "design patterns", "graphs", "hashing", "hashmaps", "identity map", "infinitum", "java", "lazy loading", "orm", "referential integrity"]
---

_“A man with a watch knows what time it is. A man with two watches is never sure.”_

I’ve been developing my open source Android framework, [Infinitum](http://code.google.com/p/infinitum-framework/), for the better part of 10 months now. It has brought about some really interesting problems that I’ve had to tackle, which is one of the many reasons I enjoy working on it so much.

### Chicken or the Egg

Although it’s much more now, Infinitum began as an object-relational mapper which was loosely modeled after [Hibernate](http://www.hibernate.org/). One of the first major issues I faced while developing the ORM component was loading object graphs. To illustrate what I mean by this, suppose we’re developing some software for a department store. The domain model for this software might look something like this:

[![](/wp-content/uploads/2012/12/Deptartment-Store-Domain-Model.png "Deptartment Store Domain Model")](/wp-content/uploads/2012/12/Deptartment-Store-Domain-Model.png)

As you can see, an Employee works in one Department, and, conversely, a Department has one or more Employees working in it, forming a many-to-one relationship and resulting in the class below.

<script src="https://gist.github.com/tylertreat/0e7601728e51806e26c6.js"></script>

Pretty straightforward, right? Now, let’s say we want to retrieve the Employee with, say, the ID 4028 from the database. Thinking about it at a high level and ignoring any notion of lazy loading, this appears to be rather simple.

1\. Perform a query on the Employee table.

<script src="https://gist.github.com/tylertreat/f5be5264fb0823448055.js"></script>

2\. Instantiate a new Employee object.  
3\. Populate the Employee object’s fields from the query result.

But there’s some handwaving going on in those three steps, specifically the last one. One of the Employee fields is an entity, namely department. Okay, this shouldn’t be a problem. We just need to perform a second query to retrieve the Department associated with the Employee (the result of the first query is going to include the Department foreign key — let’s assume its 14).

<script src="https://gist.github.com/tylertreat/616fe2c5bc35063995d2.js"></script>

Then we just create the Department object, populate it and assign it to the respective field in the Employee.

Once again, there’s a problem. To understand why, it’s helpful to see what the Department class actually looks like.

<script src="https://gist.github.com/tylertreat/e355616c93a62f45ff30.js"></script>

Do you see what the issue is? In order to construct our Employee, we need to construct his Department. In order to construct his Department, we need to construct the Employee. Our object graph has a cycle that’s throwing us for a (infinite) loop.

### Breaking the Cycle

Fortunately, there’s a pretty easy solution for this chicken-or-the-egg problem. We’ll make use of a HashMap to keep tabs on our object graph as we incrementally build it. This will make more sense in just a bit.

We’re going to use a HashMap keyed off of an integer hash where the map values will be the entities in the object graph.

<script src="https://gist.github.com/tylertreat/565d8300c3fffdd12c05.js"></script>

The integer hash will be a unique value computed for each entity we need to load to fulfill the object graph. The idea is that we will store the partially populated entity in the HashMap to have its remaining fields populated later. Loading an entity will take the following steps:

1.  Perform query on the entity table.
2.  Instantiate a new entity object.
3.  Populate the entity object fields which do not belong to a relationship from the query result.
4.  Compute the hash for the partial entity object.
5.  Check if the HashMap contains the computed hash.
6.  If the HashMap contains the hash, return the associated entity object (this breaks any potential cycle).
7.  Otherwise, store the entity object in the HashMap using the hash as its key.
8.  Load related entities by recursively calling this sequence.

Going back to our Employee problem, retrieving an Employee from the database will take these steps:

1.  Perform query on the Employee table.
2.  Instantiate a new Employee object.
3.  Populate the Employee object fields which do not belong to a relationship from the query result.
4.  Compute the hash for the partial Employee object.
5.  Check if the HashMap contains the computed hash (it won’t).
6.  Store the Employee object in the HashMap using the hash as its key.
7.  Perform query on the Department table.
8.  Instantiate a new Department object.
9.  Populate the Department object fields which do not belong to a relationship from the query results.
10.  Compute the hash for the partial Department object.
11.  Check if the HashMap contains the computed hash (again, it won’t).
12.  Store the Department object in the HashMap using the hash as its key.
13.  The cycle will terminate and the two objects in the HashMap, the Employee and the Department, will be fully populated and referencing each other.

Considering the HashMap is not specific to any entity type (i.e. it will hold Employees, Departments, and any other domain types we come up with), how do we compute a unique hash for objects of various types? Moreover, we’re computing hashes for incomplete objects, so what gives?

Obviously, we can’t make use of hashCode() since not every field is guaranteed to be populated. Fortunately, we can take advantage of the fact that every entity _must_ have a primary key, but, unless we’re using a policy where every primary key is unique across every table, this won’t get us very far. We will include the entity type as a factor in our hash code. Here’s the code Infinitum currently uses to compute this hash:

<script src="https://gist.github.com/tylertreat/19c422ab4848e7beb60b.js"></script>

This hash allows us to uniquely identify entities even if they have not been fully populated. Our cycle problem is solved!

### Maintaining Referential Integrity

The term “referential integrity” is typically used to refer to a property of relational databases. However, when I say referential integrity, I’m referring to the notion of object references in an object graph. This referential integrity is something ORMs must keep track of or otherwise you run into some big problems.

To illustrate this, say our department store only has one department and two employees who work in said department (this might defeat the purpose of a _department_ store, but just roll with it). Now, let’s say we retrieve one Employee, Bill, from the database. Once again ignoring lazy loading, this should implicitly load an object graph consisting of the Employee, the Department, and the Employees assigned to that Department. Next, let’s subsequently retrieve the second Employee, Frank, from the database. Again, this will load the object graph.

Bill and Frank both work in the same Department, but if referential integrity is not enforced, objects can become out of sync.

<script src="https://gist.github.com/tylertreat/484d7ae84dffed08ca81.js"></script>

The underlying problem is that there are two different copies of the Department object, but we must abide by the Highlander Principle in that “there can be only one.” Bill and Frank should reference the same instance so that, regardless of how the Department is dereferenced, it stays synced between every object in the graph.

In plain terms, when we’re retrieving objects from the database, we must be cautious not to load the same one twice. Otherwise, we’ll have two objects corresponding to a single database row and things will get out of sync.

### Enter Identity Map

This presents an interesting problem. Knowing what we learned earlier with regard to the chicken-or-the-egg problem, can we apply a similar solution? The answer is _yes_! In fact, the solution we discussed earlier was actually masquerading as a fairly common design pattern known as the _Identity Map_, originally cataloged by Martin Fowler in his book _[Patterns of Enterprise Application Architecture](http://www.amazon.com/Patterns-Enterprise-Application-Architecture-Martin/dp/0321127420)_.

The idea behind the Identity Map pattern is that, every time we read a record from the database, we first check the Identity Map to see if the record has already been retrieved. This allows us to simply return a new reference to the in-memory record rather than creating a new object, maintaining referential integrity.

A secondary benefit to the Identity Map is that, since it acts as a cache, it reduces the number of database calls needed to retrieve objects, which yields a performance enhancement.

An Identity Map is normally tied to some sort of transactional context such as a session. This works exceedingly well for Infinitum because its ORM is built around the notion of a Session object, which  can be configured as a scoped unit of work. The Infinitum Session contains a cache which functions as an Identity Map, solving both the cycle and the referential integrity issues.

It’s worth pointing out, however, that while an Identity Map maintains referential integrity within the context of a session, it doesn’t do anything to prevent incongruities between different sessions. This is a complex problem that usually requires a locking strategy, which is beyond the scope of this blog post.

### Under the Hood

It may be helpful to see how Infinitum uses an Identity Map to solve the cycle problem. The method createFromCursor takes a database result cursor and transforms it into an instance of the given type. It makes use of a recursive method that goes through the process I outlined earlier. The call to loadRelationships will result in this recursion.

<script src="https://gist.github.com/tylertreat/3b2ecff2895ac64ae348.js"></script>

Entities are stored in the Session cache as they are retrieved, allowing us to enforce referential integrity while also preventing any infinite loops that might occur while building up the object graph.

So that’s it! We’ve learned to make use of the Identity Map pattern to solve some pretty interesting problems. We looked at how we can design an ORM to load object graphs that contain cycles as well as maintain this critical notion of referential integrity. We also saw how the Identity Map helps to give us some performance gain through caching. Infinitum’s ORM module makes use of this pattern in its session caching and many other frameworks use it as well. In a future blog entry, I will talk about lazy loading and how it can be used to avoid loading large object graphs.
