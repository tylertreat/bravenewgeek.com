---
title: "Deployment-Driven Development"
date: 2024-11-11T15:57:13-07:00
lastmod: 2024-11-15T09:25:32-07:00
slug: "deployment-driven-development"
categories: ["DevOps", "Konfigurate", "Platform Engineering", "Software Engineering"]
tags: ["deployment-driven development", "devops", "domain-driven design", "konfigurate", "platform engineering"]
---

[![](/wp-content/uploads/2024/11/pipeline.png)](/wp-content/uploads/2024/11/pipeline.png)

Most people use “DDD” to refer to _Domain-Driven Design_, which is a useful tool for thinking about API boundaries and system architecture. It provides a way to map a business problem into software. At [Real Kinetic](https://realkinetic.com), we regularly help our clients utilize Domain-Driven Design as well as other strategies to architect their systems, avoid some of the pitfalls of DDD, and build an effective foundation for designing software. But _this_ DDD only speaks to one small aspect of building and shipping software.

Software architecture is critical to a number of concerns like scalability, adaptability, and speed-to-market for new products and features, but its effects are usually not felt for some time—weeks, months, even _years_ later. These delayed effects are _lagging indicators_ that reveal how “well” a system was architected (I use quotes here because this is really quite subjective and relative to both the short- and long-term needs of the business). Other lagging indicators also highlight problems in software development. For instance, a high number of reported bugs may point to deficiencies in QA and testing processes, while the volume or severity of findings in an audit may signal issues in security, compliance, or SDLC practices. Similarly, accumulated tech debt may reflect deeper systemic issues.

These lagging indicators often result from a delayed and reactive approach to managing concerns like security, compliance, quality, and even architecture. These concerns are frequently deferred to later stages in the development process or left to evolve on their own organically. It’s not uncommon for us to see teams complete the development of a product or feature, only to spend _months_ navigating the hurdles to get it into production. It may be testing or production-readiness processes, integration challenges, infrastructure issues, change-review boards, or a combination of all of these. One way or another, it takes many teams inordinately long to go from idea to in-customer’s-hands.

Through our work consulting with startups, scaleups, and Fortune 500 companies to improve their product delivery, we’ve been building a solution to this problem called [Konfigurate](https://konfigurate.com?utm_source=bravenewgeek.com&utm_campaign=ddd). But before diving into that, I want to introduce you to the _other_ DDD—_Deployment-Driven Development_—and why it’s critical to improving delivery, how it relates to platform engineering, and how it can be implemented.

## Shift Left

The act of _scaling_ a product—that is to say, going from prototype to production and beyond—takes focus off the product itself. This is because there is a whole host of undifferentiated work that is needed at various stages of a product’s lifecycle:

-   Infrastructure configuration and management
-   CI/CD tooling
-   Workforce and workload IAM
-   System security
-   Compliance
-   Sprawl and tech debt management

“Shifting left” has become a mantra for high-performing teams, particularly as it relates to software testing. The reality, though, is that much of this undifferentiated work—security, compliance, infrastructure, deployment—is still often treated as a separate concern to be tackled just before the system goes live or, in some cases, _after_ it’s already been deployed to production. Security is a good example of this, where tools like Wiz scan for security issues in the runtime environment or during CI/CD—_after_ the code has been written. Nothing against continuous security, but wouldn’t it be nice if systems could be built the “right” way up front to reduce rework or delays?

_Deployment-Driven Development_—a different kind of DDD—challenges this approach by flipping the paradigm. Instead of treating deployment as a final milestone, it prioritizes deployment from the start. The idea is simple but powerful: start with a deployment to a real, production-like environment on day one then work your way backwards. Doing this shifts more of these concerns left into the development process.

## What is Deployment-Driven Development?

Deployment-Driven Development begins with a live, deployable environment and treats it as the foundation for all development activities that follow. The very first step when a new workload is created, before anything else happens, is deploying it to a real environment. From that point on, every line of code, every change, and every new feature is created and tested in an environment that mirrors production. This approach ensures that from day one, teams are building, testing, and iterating in conditions that match the realities of their live system, giving them the confidence that their application is production-ready at any given moment. As a result, teams avoid the common bottleneck of scrambling to get the application ready for production after development is complete—what I call “running the production gauntlet.”

While early-stage deployment to production-like environments is often considered best practice in modern software development, DDD formalizes this approach by reversing the typical order: **start with deployment, then integrate code and configuration into that live setup**. Setting up a real environment can be a significant lift for many teams, as provisioning and configuring production-like environments with the right infrastructure and permissions remains a complex task. By making deployment as simple and foundational as possible, Deployment-Driven Development makes it easier for teams to deliver faster with fewer roadblocks.

Shifting left traditionally applies to moving testing earlier in the development lifecycle, but DDD takes this idea further by shifting the deployment process itself to the beginning. Instead of validating code in isolation, the code is deployed in a full, production-ready environment, using automated provisioning to manage resources and integrate infrastructure. By proactively addressing deployment hurdles early, DDD helps reduce surprises and delays later on.

## Why Legacy Infrastructure as Code Falls Short

[Legacy Infrastructure as Code](https://blog.realkinetic.com/its-time-to-retire-terraform-30545fd5f186) (IaC) like Terraform or CloudFormation doesn’t enable Deployment-Driven Development because these tools lack opinionation—clear, enforced standards for how infrastructure should be built and configured. They are general-purpose tools designed to solve all problems, much like a general-purpose programming language. For example, “least-privileged access” is widely accepted as a best practice, yet IaC tools don’t inherently enforce this principle. Developers must implement least-privileged access and other standards themselves. These IaC primitives just wrap the cloud provider’s API. The result is that legacy IaC tools don’t facilitate Deployment-Driven Development without a sizable investment into platform engineering.

There are abstractions that can help with this, whether it’s writing Terraform modules or using CDK to abstract CloudFormation and implement reusable constructs, but this goes back to what I said earlier about undifferentiated work: the act of “scaling” a product takes focus off the product itself. Consequently, we often see teams—especially those following a DevOps model—spending a disproportionate amount of time writing IaC versus writing product code.

With Deployment-Driven Development, however, opinionated infrastructure must be baked in from the beginning, automating setup in a way that enforces best practices, such as least-privileged access, as _default_ behavior rather than optional guidance. To make this work with traditional IaC tools, it requires [investing in a true platform engineering team to solve these problems](https://blog.realkinetic.com/productize-your-engineering-organizations-internal-tools-25fd2cbe3fb0) for the rest of the organization. I rarely see teams approaching this from the DevOps angle doing this well at scale—it usually results in a great deal of inefficiency and sprawl. People copy/paste and bad patterns quickly proliferate.

## Platform Engineering and Golden Paths

Shipping software _the right way_ should be the easy way. At Real Kinetic, our Platform Engineering as a Service empowers organizations to adopt Deployment-Driven Development by creating [_golden paths_](https://engineering.atspotify.com/2020/08/how-we-use-golden-paths-to-solve-fragmentation-in-our-software-ecosystem/) for streamlined development. A golden path is an opinionated and supported way of building something within your organization. What it allows us to do is shift more things _left_ into the development process. Rather than relying on policy and security scanners like Checkov or Wiz to detect issues reactively, we make it possible to _only_ ship software that conforms to your organization’s internal controls or standards. While security scanners still play a role, this model significantly reduces the undifferentiated work and removes the guesswork from figuring out your organization’s standards. It lets product teams focus on the stuff that actually matters. [Konfigurate](https://konfigurate.com?utm_source=bravenewgeek.com&utm_campaign=ddd), our modern IaC solution, allows organizations to enforce their standards easily—without requiring a substantial platform engineering investment.

Konfigurate was designed and built around the notion of Deployment-Driven Development. The platform’s opinionated IaC approach represents a modern solution to deployment and infrastructure management. By shifting infrastructure, compliance, and security concerns left, Konfigurate ensures that applications are production-ready from day one, enabling faster deployments and reducing time spent on “overhead” work so you can focus more on your actual product. It minimizes this work that otherwise gets deferred or left to evolve organically until it becomes a much bigger problem. This shift-left approach to IaC not only accelerates time-to-production but also provides peace of mind, knowing that infrastructure is secure, compliant, and standardized by design.

Platform engineering offers a scalable approach to DevOps by enabling organizations to codify best practices while providing the tooling and services that empower product teams to work more efficiently. However, this approach requires a dedicated investment in a platform engineering team. For startups and scaleups, this can be particularly challenging as their focus is often on rapid product development rather than internal infrastructure. Even large enterprises, especially those outside the tech industry, face hurdles in adopting platform engineering. IT departments in these organizations are frequently seen as cost centers, making it difficult to justify strategic investments like building a dedicated platform engineering function.

## Conclusion

Deployment-Driven Development represents a subtle, yet fundamental, shift in how teams approach software delivery, prioritizing deployment from day one rather than treating it as an afterthought. By starting with a real, production-like environment, teams can build, test, and iterate more effectively, reducing the friction often caused by traditional infrastructure and deployment practices. This shift-left approach ensures that security, compliance, and operational concerns are addressed early, leading to faster, more reliable releases.

At Real Kinetic, we’ve embraced this methodology to help our clients streamline their delivery processes. Tools like Konfigurate embody this philosophy by providing opinionated, ready-to-use infrastructure that automates best practices, eliminating much of the undifferentiated work that slows teams down. By adopting Deployment-Driven Development, organizations can not only accelerate their time-to-market but also reduce tech debt, improve security posture, and focus more on delivering value to their customers.

Ultimately, Deployment-Driven Development is about making deployment the easy and natural part of the development lifecycle, allowing teams to deliver high-quality software with greater agility and confidence. Whether you’re a startup looking to scale quickly or an enterprise aiming to optimize your delivery pipeline, embracing this approach can be a game changer for your organization.
