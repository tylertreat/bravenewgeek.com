---
title: "Controller-Driven Infrastructure as Code"
date: 2025-03-19T14:36:25-06:00
lastmod: 2025-03-20T07:55:56-06:00
slug: "controller-driven-infrastructure-as-code"
categories: ["Cloud", "DevOps", "Koreo", "Kubernetes", "Platform Engineering"]
tags: ["controllers", "iac", "infrastructure as code", "koreo", "kubernetes", "platform engineering", "resource orchestration"]
---

## Harnessing the Kubernetes Resource Model for modern infrastructure management

Infrastructure as Code (IaC) revolutionized how we manage infrastructure, enabling developers to define resources declaratively and automate their deployment. However, tools like Terraform and CloudFormation, despite their declarative configuration, rely on an _operation-centric_ model, where resources are created or updated through one-shot commands.

### The evolution of IaC: From operations to controllers

In contrast, Kubernetes introduced a new paradigm with its [controller pattern](https://kubernetes.io/docs/concepts/architecture/controller/) and the [Kubernetes Resource Model](https://github.com/kubernetes/design-proposals-archive/blob/main/architecture/resource-management.md) (KRM). This _resource-centric_ approach to APIs redefines infrastructure management by focusing on desired state rather than discrete operations. Kubernetes controllers continuously monitor resources, ensuring they conform to their declarative configurations by performing actions to move the actual state closer to the desired state, much like a human operator would. This is known as a _control loop_.

Kubernetes also demonstrated the value of providing architectural building blocks that encapsulate standard patterns, such as a [Deployment](https://kubernetes.io/docs/tasks/run-application/run-stateless-application-deployment/). These can then be composed and combined to provide impressive capabilities with little effort—[HorizontalPodAutoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) is an example of this. Through extensibility, Kubernetes allows developers to define new resource types and controllers, making it a natural fit for managing not just application workloads but infrastructure of _any_ kind. This enables you to actually provide a clean API for common architectural needs that encapsulates a lot of routine business logic. Extending this model to IaC is something we call _Controller-Driven IaC_.

### Building on the Kubernetes controller model

Controller-Driven IaC builds upon the Kubernetes foundation, leveraging its controllers to reconcile cloud resources and maintain continuous alignment between desired and actual states. By extending Kubernetes’ principles of declarative configuration and control loops to IaC, this approach offers a resilient and scalable way to manage modern infrastructure. Integrating cloud and external system APIs into Kubernetes controllers enables continuous state reconciliation beyond Kubernetes itself, ensuring consistency, eliminating configuration drift, and reducing operational complexity. It results in an IaC solution that is capable of working correctly with modern, dynamic infrastructure. Additionally, it brings many of the other benefits of Kubernetes—such as RBAC, policy enforcement, and observability—to infrastructure and systems _outside_ the cluster, creating a unified and flexible management framework. In essence, Kubernetes becomes the control plane for your entire developer platform. That means you can offer developers a self-service experience within defined bounds, and this can further be scoped to specific application domains.

This concept isn’t entirely new. Kubernetes introduced [Custom Resource Definitions](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) (CRDs) in 2017, enabling the creation of [Operators](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/), or custom controllers, to extend its functionality. Today, [countless Operators exist](https://operatorhub.io) to manage diverse applications and infrastructure, both _within_ and _outside of_ Kubernetes, including those from major cloud providers. For instance, GCP’s [Config Connector](https://cloud.google.com/config-connector/docs/overview), AWS’s [ACK](https://github.com/aws-controllers-k8s/community), and Azure’s [ASO](https://azure.github.io/azure-service-operator/) offer controllers for managing their respective platform’s infrastructure. However, just as operationalizing Kubernetes requires tooling and investment to build an effective platform, so too does implementing Controller-Driven IaC. Integrating these various controllers into a cohesive platform requires its own kind of orchestration. We need a way to _program_ control loops—whether built-in Kubernetes controllers (like Deployments or Jobs), off-the-shelf controllers (like ACK or Config Connector), or custom controllers we’ve built ourselves.

### Introducing Koreo: Programming control loops for modern platforms

There are tools such as [Crossplane](https://www.crossplane.io) that take a controller-oriented approach to infrastructure, but they have their own challenges and limitations. In particular, we really need the ability to compose arbitrary Kubernetes resources and controllers, not just specific provider APIs. What if we could treat _anything_ in Kubernetes as a referenceable object capable of acting as the input or output to an automated workflow, and without the need for building tons of CRDs or custom Operators? Additionally, it’s critical that resources can be namespaced rather than cluster-scoped to support multi-tenant environments and that the corresponding infrastructure can live in cloud projects or accounts separate from where the control plane itself lives.

To address these needs and deliver the full potential of Controller-Driven IaC, we’ve developed and open-sourced [_Koreo_](http://koreo.dev), a platform engineering toolkit for Kubernetes. Koreo is a new approach to Kubernetes configuration management and resource orchestration empowering developers through programmable workflows and structured data. It enables seamless integration and automation around the Kubernetes Resource Model, supporting a wide range of use cases centered on Controller-Driven IaC. Koreo serves as a _meta-controller programming language_ and runtime that allows you to compose control loops into powerful abstractions.

[![](/wp-content/uploads/2025/03/image1-1024x790.png)](/wp-content/uploads/2025/03/image1.png)

_The Koreo UI showing a workflow for a custom AWS workload abstraction_

Koreo is specifically built to empower platform engineering teams and DevOps engineers by allowing them to provide Architecture-as-Code building blocks to the teams they support. With Koreo, you can easily leverage existing Kubernetes Operators or create your own specialized Operators, then expose them through powerful, high-level abstractions aligned with your organization’s needs. For example, you can develop a “StatelessCrudApp” that allows development teams to enable company-standard databases and caches with minimal effort. Similarly, you can build flexible automations that combine and orchestrate various Kubernetes primitives.

[![](/wp-content/uploads/2025/03/image2.png)](/wp-content/uploads/2025/03/image2.png)

_An instance of the custom AWS workload abstraction_

Where Koreo really shines, however, is making it fast and safe to add new capabilities to your internal developer platform. Existing configuration management tools like Helm and Kustomize, while useful for simpler configurations, become unwieldy when dealing with the intricacies of modern Kubernetes deployments. They ultimately treat configuration as static data, and this becomes problematic as configuration evolves in complexity.

Koreo instead embraces configuration as code by providing a programming language and runtime with robust developer tooling. This allows platform engineers to define and manage Kubernetes configurations and resource orchestration in a way that is better suited to modern infrastructure challenges. It offers a solution that scales with complexity. A built-in testing framework makes it easy to quickly validate configuration and iterate on infrastructure, and IDE integration gives developers a familiar programming-like experience.

### The future of infrastructure management is controller-driven

By harnessing the power of Kubernetes controllers for Infrastructure as Code, Koreo bridges the gap between declarative configuration and dynamic infrastructure management. It moves beyond the limitations of traditional IaC, offering a truly Kubernetes-native approach that brings the benefits of control loops, composability, and continuous reconciliation to your entire platform. With Koreo, you’re not just managing resources; you’re composing Kubernetes controllers to do powerful things like building internal developer platforms, managing multi-cloud infrastructure, or orchestrating application deployments and other complex workflows.

See what you can build with [Koreo](http://koreo.dev).
