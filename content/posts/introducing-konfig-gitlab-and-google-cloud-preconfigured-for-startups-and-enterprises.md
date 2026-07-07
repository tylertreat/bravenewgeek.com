---
title: "Introducing Konfig: GitLab and Google Cloud preconfigured for startups and enterprises"
date: 2024-04-04T14:51:23-06:00
lastmod: 2024-10-09T16:27:26-06:00
slug: "introducing-konfig-gitlab-and-google-cloud-preconfigured-for-startups-and-enterprises"
categories: ["Cloud", "Consulting", "DevOps", "GCP", "GitLab", "Konfigurate", "Operations", "Platform Engineering", "Real Kinetic"]
tags: ["gcp", "gitlab", "idp", "internal developer platform", "konfigurate", "platform engineering", "real kinetic"]
---

[Real Kinetic](https://realkinetic.com/) helps businesses transform how they build and deliver software in the cloud. This encompasses legacy migrations, app modernization, and greenfield development. We work with companies ranging from startups to Fortune 500s and everything in between. Most recently, we finished helping Panera Bread migrate their e-commerce platform to Google Cloud from on-prem and led their transition to GitLab. In doing this type of work over the years, we’ve noticed a problem organizations consistently hit that causes them to stumble with these cloud transformations. Products like GCP, GitLab, and Terraform are quite flexible and capable, but they are sort of like the piles of Legos below.

![](/wp-content/uploads/2024/04/image3-1024x286.png)

These products by nature are mostly unopinionated, which means customers need to put the pieces together in a way that works for their unique situation. This makes it difficult to get started, but it’s also difficult to assemble them in a way that works well for 1 team or _100_ teams. Startups require a solution that allows them to focus on product development and accelerate delivery, but ideally adhere to best practices that scale with their growth. Larger organizations require something that enables them to transform how they deliver software and innovate, but they need it to address enterprise concerns like security and governance. Yet, when you’re just getting started, you know the least and are in the worst position to make decisions that will have a potentially long-lasting impact. The outcome is companies attempting a cloud migration or app modernization effort fail to even get off the starting blocks.

It’s easy enough to cobble together something that works, but doing it in a way that is actually enterprise-ready, scalable, and secure is not an insignificant undertaking. In fact, it’s quite literally what we have made a business of helping customers do. What’s worse is that this is undifferentiated work. Companies are spending countless engineering hours building and maintaining their own bespoke “cloud assembly line”—or [Internal Developer Platform](https://internaldeveloperplatform.org/) (IDP)—which are all attempting to address the same types of problems. That engineering time would be better spent on things that actually matter to customers and the business.

This is what prompted us to start thinking about solutions. GitLab and GCP don’t offer strong opinions because they address a broad set of customer needs. This creates a need for an opinionated configuration or _distribution_ of these tools. The solution we arrived at is [Konfig](https://konfigurate.com/?utm_source=bravenewgeek.com&utm_campaign=introducing-konfig). The idea is to provide this distribution through what we call “Platform as Code.” Where Infrastructure as Code (IAC) is about configuring the individual resource-level building blocks, Platform as Code is one level higher. It’s something that can assemble these discrete products in a coherent way—almost as if they were natively integrated. The result is a turnkey experience that minimizes time-to-production in a way that will scale, is secure by default, and has best practices built in from the start. A Linux distro delivers a ready-to-use operating system by providing a preconfigured kernel, system library, and application assembly. In the same way, Konfig delivers a ready-to-use platform for shipping software by providing a preconfigured source control, CI/CD, and cloud provider assembly. Whether it’s legacy migration, modernization, or greenfield, Konfig provides your packaged onramp to GCP and GitLab.

## Platform as Code

Central to Konfig is the notion of a _Platform_. In this context, a Platform is a way to segment or group parts of a business. This might be different product lines, business units, or verticals. How these Platforms are scoped and how many there are is different for every organization and depends on how the business is structured. A small company or startup might consist of a single Platform. A large organization might have dozens or more.

A Platform is then further subdivided into _Domains_, a concept we borrow from Domain-Driven Design. A Domain is a bounded context which encompasses the business logic, rules, and processes for a particular area or problem space. Simply put, it’s a way to logically group related services and workloads that make up a larger system. For example, a business providing online retail might have an E-commerce Platform with the following Domains: Product Catalog, Customer Management, Order Management, Payment Processing, and Fulfillment. Each of these domains might contain on the order of 5 to 10 services.

![](/wp-content/uploads/2024/04/image5.png)

This structure provides a convenient and natural way for us to map access management and governance onto our infrastructure and workloads because it is modeled after the organization structure itself. Teams can have ownership or elevated access within their respective Domains. We can also specify which cloud services and APIs are available at the Platform level and further restrict them at the Domain level where necessary. This hierarchy facilitates a powerful way to enforce enterprise standards for a large organization while allowing for a high degree of flexibility and autonomy for a small organization. Basically, it allows for governance when you need it (and autonomy when you don’t). This is particularly valuable for organizations with regulatory or compliance requirements, but it’s equally valuable for companies wanting to enforce a “[golden path](https://engineering.atspotify.com/2020/08/how-we-use-golden-paths-to-solve-fragmentation-in-our-software-ecosystem/)”—that is, an opinionated and supported way of building something within your organization. Finally, Domains provide clear cost visibility because cloud resources are grouped into Domain projects. This makes it easy to see what “Fulfillment” costs versus “Payment Processing” in our E-commerce Platform, for example.

“Platform as Code” means these abstractions are modeled declaratively in YAML configuration and managed via [GitOps](https://about.gitlab.com/topics/gitops/). The definitions of Platforms and Domains consist of a small amount of metadata, shown below, but that small amount of metadata ends up doing _a lot_ of heavy lifting in the background.

```
apiVersion: konfig.realkinetic.com/v1beta1
kind: Platform
metadata:
  name: ecommerce-platform
  namespace: konfig-control-plane
  labels:
    konfig.realkinetic.com/control-plane: konfig-control-plane
spec:
  platformName: Ecommerce Platform
  gitlab:
    parentGroupId: 82224252
  gcp:
    billingAccountId: "123ABC-456DEF-789GHI"
    parentFolderId: "1080778227704"
    defaultEnvs:
      - dev
      - stage
      - prod
    services:
      defaults:
        - cloud-run
        - cloud-sql
        - cloud-storage
        - secret-manager
        - cloud-kms
        - pubsub
        - redis
        - firestore
    api:
      path: /ecommerce
```

_platform.yaml_

```
apiVersion: konfig.realkinetic.com/v1beta1
kind: Domain
metadata:
  name: payment-processing
  namespace: konfig-control-plane
  labels:
    konfig.realkinetic.com/platform: ecommerce-platform
spec:
  domainName: Payment Processing
  gcp:
    services:
      disabled:
        - pubsub
        - redis
        - firestore
    api:
      path: /payment
  groups:
    dev: [payment-devs@example.com]
    maintainer: [payment-maintainers@example.com]
    owner: [gitlab-owners@example.com]
```

_domain.yaml_

## The Control Plane

Platforms, Domains, and all of the resources contained within them are managed by the Konfig control plane. The control plane consumes these YAML definitions and does whatever is needed in GitLab and GCP to make the “real world” reflect the desired state specified in the configuration.

![](/wp-content/uploads/2024/04/image2-1024x686.png)

The control plane manages the structure of groups and projects in GitLab and synchronizes this structure with GCP. This includes a number of other resources behind the scenes as well: configuring OpenID Connect to allow GitLab pipelines to authenticate with GCP, IAM resources like service accounts and role bindings, managing SAML group links to sync user permissions between GCP and GitLab, and enabling service APIs on the cloud projects. The Platform/Domain model allows the control plane to specify fine-grained permissions and scope access to only the things that need it. In fact, there are no credentials exposed to developers at all. It also allows us to manage what cloud services are available to developers and what level of access they have across the different environments. This governance is managed centrally but federated across both GitLab and GCP.

![](/wp-content/uploads/2024/04/image4-1024x718.png)

The net result is a configuration- and standards-driven foundation for your cloud development platform that spans your source control, CI/CD, and cloud provider environments. This foundation provides a golden path that makes it easy for developers to build and deliver software while meeting an organization’s internal controls, standards, or regulatory requirements. Now we’re ready to start delivering workloads to our enterprise cloud environment.

## Managing Workloads and Infrastructure

The Konfig control plane establishes an enterprise cloud environment in which we could use traditional IAC tools such as Terraform to manage our application infrastructure. However, the control plane is capable of much more than just managing the foundation. It can also manage the workloads that get deployed _to_ this cloud environment. This is because Konfig actually consists of two components: _Konfig Platform_, which configures and manages our cloud platform comprising GitLab and GCP, and _Konfig Workloads_, which configures and manages application workloads and their respective infrastructure resources.

Using the Lego analogy, think of Konfig Platform as providing a pre-built factory and Konfig Workloads as providing pre-built assembly lines within the factory. You can use both in combination to get a complete, turnkey experience or just use Konfig Platform and “bring your own assembly line” such as Terraform.

Konfig Workloads provides an IAC alternative to Terraform where resources are managed by the control plane. Similar to how the platform-level components like GitLab and GCP are managed, this works by using an [operator](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/) that runs in the control plane cluster. This operator runs on a [control loop](https://kubernetes.io/docs/concepts/architecture/controller/) which is constantly comparing the desired state of the system with the current state and performs whatever actions are necessary to reconcile the two. A simple example of this is the thermostat in your house. You set the temperature—the desired state—and the thermostat works to bring the actual room temperature—the current state—closer to the desired state by turning your furnace or air conditioner on and off. This model removes potential for state drift, where the actual state diverges from the configured state, which can be a major headache with tools like Terraform where state is managed with backends.

The Konfig UI provides a visual representation of the state of your system. This is useful for getting a quick understanding of a particular Platform, Domain, or workload versus reading through YAML that could be scattered across multiple files or repos (and which may not even be representative of what’s actually running in your environment). With this UI, we can easily see what resources a workload has configured and can access, the state of these resources (whether they are ready, still provisioning, or in an error state), and how the workload is configured across different environments. We can even use the UI itself to provision new resources like a database or storage bucket that are scoped automatically to the workload. This works by generating a merge request in GitLab with the desired changes, so while we can use the UI to configure resources, everything is still managed declaratively through IAC and GitOps. This is something we call “Visual IAC.”

[![](/wp-content/uploads/2024/04/konfig_ui-1024x597.png)](/wp-content/uploads/2024/04/konfig_ui.png)

## Your Packaged Onramp to GCP and GitLab

The current cloud landscape offers powerful tools, but assembling them efficiently, securely, and at scale remains a challenge. This “undifferentiated work” consumes valuable engineering resources that could be better spent on core business needs, and it often prevents organizations from even getting off the starting line when beginning their cloud journey. Konfig, built around the principles of Platform as Code and standards-driven development, addresses this very gap. We built it to help our clients move quicker through operationalizing the cloud so that they can focus on delivering business value to their customers. Whether you’re migrating to the cloud, modernizing, or starting from scratch, Konfig provides a preconfigured and opinionated integration of GitLab, GCP, and Infrastructure as Code which gives you:

-   **Faster time-to-production:** Streamlined setup minimizes infrastructure headaches and allows developers to focus on building and delivering software.  
    
-   **Enterprise-grade security:** Built-in security best practices and fine-grained access controls ensure your cloud environment remains secure.  
    
-   **Governance:** Platforms and Domains provide a flexible model that balances enterprise standards with team autonomy.  
    
-   **Scalability:** Designed to scale with your business, easily accommodating growth without compromising performance or efficiency.  
    
-   **Great developer UX**: Designed to provide a great user experience for developers shipping applications and services.

[Konfig](https://konfigurate.com/?utm_source=bravenewgeek.com&utm_campaign=introducing-konfig) functions like an operating system for your development organization to deliver software to the cloud. It’s an opinionated IDP specializing in cloud migrations and app modernization. This allows you to focus on what truly matters—building innovative software products and delivering exceptional customer experiences.

We’ve been leveraging these patterns and tools for years to help clients ship with confidence, and we’re excited to finally offer a solution that packages them up. [Please reach out](https://konfigurate.com/contact?utm_source=bravenewgeek.com&utm_campaign=introducing-konfig) if you’d like to learn more and see a demo. If you’re undertaking a modernization or cloud migration effort, we want to help make it a success. We’re looking for a few organizations to partner with to develop Konfig into a robust solution.
