---
title: "What’s Going on with GKE and Anthos?"
date: 2019-09-17T10:12:52-05:00
slug: "whats-going-on-with-gke-and-anthos"
categories: ["Cloud", "GCP"]
tags: ["anthos", "cloud", "cloud run", "gcp", "gke", "istio", "kubernetes", "multi-cloud", "oracle", "vendor lock-in"]
---

#### GCP’s Slippery Slide into Enterprise

When former Oracle exec Thomas Kurian took over for Diane Greene as Google Cloud’s CEO, a lot of people expressed concern about what this meant for the future of GCP. Vendor lock-in is already at the forefront of the minds of many cloud adopters, and Oracle is notorious for [locking customers into expensive and prolonged contracts](https://www.cnbc.com/2017/04/19/amazon-aws-chief-andy-jassy-on-oracle-customers-are-sick-of-it.html). However, I thought the move was smart on Google’s part.

Google has never been a _customer-first_ company. While it has always been a _technology_ leader, it struggles immensely with enterprise sales and support. It continues to have issues dogfooding its own products (Google’s products are typically built on internal versions of services not available to customers, then there are the external GCP versions that their customers actually use). This means its engineers don’t feel the same pain points that its customers experience and their products lose out on a critical feedback loop (contrast this with Amazon where AWS is treated as a separate company to Amazon.com, and there is a mandate to build with the same services Amazon’s customers use). Customer empathy matters.

Now, most people probably wouldn’t characterize Oracle as a customer-first company, but it knows how to meet customers where they are and to sell in a way that resonates with enterprise decision makers. Historically, Google has approached sales engineering in a way that has failed to resonate with customers by attempting to map its superior technology offerings onto actual customer problems. Nothing could be more off-putting to a decision maker with a round hole than a sales engineer with a square peg telling them their hole is wrong.

Thomas Kurian was brought in to address these glaring issues for Google Cloud. Through [restructuring](https://www.bizjournals.com/sanjose/news/2019/08/15/google-cloud-continues-market-share-battle-with.html) and [growing](https://www.cnbc.com/2019/04/08/google-cloud-chief-kurian-has-aggressive-plan-to-hire-salespeople.html) its sales organization, [key leadership hires, and strategic acquisitions and partnerships](https://www.computerworld.com/article/3435761/thomas-kurians-key-hires-show-google-clouds-enterprise-ambition.html), it’s clear he’s serious about fixing Google Cloud’s enterprise perception problem. Slowly but surely, Google is attempting to shift its culture from being technology-obsessed to customer-obsessed. And while Oracle is notorious when it comes to vendor lock-in, all signs thus far have pointed to Google more strategically embracing open APIs with things like GKE (Kubernetes), Traffic Director (Istio), ML Engine (Tensorflow), and Dataflow (Apache Beam). They are also starting to meet customers where they are with things like Dataproc (Apache Spark and Hadoop), Memorystore (Redis), and Cloud SQL (MySQL, PostgreSQL, and Microsoft SQL Server). Hell, they’ll even [run Microsoft Active Directory for you](https://cloud.google.com/managed-microsoft-ad/) now! Who says Google can’t do enterprise? So the future is bright for GCP, right? _Maybe_. What follows is speculation based on my own observations and anecdotal information.

There’s one thing that could change the outlook on all of this: [_Anthos_](https://cloud.google.com/anthos/). Anthos is GCP’s answer to hybrid-cloud solutions like Pivotal Cloud Foundry (PCF), AWS Outposts, or Azure Stack. It allows organizations to build and manage workloads across public clouds and on-prem by extending GKE. If multi-cloud is your thing and you hate money, these platforms all sound like pretty good things. But here’s the disconcerting thing about Anthos in particular: it’s becoming clear that GCP is deliberately blurring the lines between Anthos and GKE.

I received an email yesterday from GCP announcing that [Binary Authorization](https://cloud.google.com/binary-authorization/) is now generally available (GA). Binary Authorization is a neat security feature that ensures only trusted container images can be deployed to GKE. It’s been in beta for some time and now it’s [GA with a six-month free trial](https://cloud.google.com/binary-authorization/docs/pricing) starting today. Great! How much will it cost after the trial? Contact your sales representative. Wait, what? That’s because starting on March 16, 2020, GKE clusters will need to be part of an Anthos-subscribed organization to enable Binary Authorization. If you choose not to upgrade to Anthos, starting March 16, 2020, you will not be able to turn on Binary Authorization on new clusters.

This is a slippery slope for GCP. I can already foresee other features requiring an Anthos subscription just to use them in GKE, where GKE basically becomes an Anthos subscription funnel. Which features go into Anthos and which go into GKE? Now _this_ is something I’d come to expect from Oracle. If GCP starts to roll differentiating features into Anthos instead of GKE, it could mark the beginning of the end.

While the lines between Anthos and GKE are becoming increasingly fuzzy, Google is clear about this particular feature:

> Binary Authorization is a feature of the Anthos platform and use of Binary Authorization is included in the Anthos subscription.

That wasn’t clear, however, when I started using it with _GKE_ and started to advise clients to use it there, completely irrespective of Anthos. This sets a very dangerous precedent.

What’s more alarming is the marketing and product language on a number of GCP services and features have quietly replaced “GKE” with “Anthos” or, worse yet, “Anthos GKE.” For example, [Cloud Run](https://cloud.google.com/run/)—which is still in beta—now says it can “run stateless containers on a fully managed environment or on Anthos.” Will I need an Anthos subscription to use Cloud Run with GKE once it goes GA? Based on the Binary Authorization move and the language updates, it seems likely. And looking at the GKE cluster setup wizard, it appears managed Istio might also.

![](/wp-content/uploads/2019/09/gke_anthos_features.png)

Anthos features listed in GKE cluster setup wizard

Which of these features is going to require a subscription next? We know Binary Authorization already does.

![](/wp-content/uploads/2019/09/gke_security.png)

Security features listed in GKE cluster setup wizard

And how much does Anthos even cost? [Contact sales](https://cloud.google.com/contact/?form=anthos). Not a good look for [Kurian’s vision of openness and customer choice](https://www.computerworld.com/article/3428035/new-google-cloud-ceo-thomas-kurian-lays-out-his-vision-for-the-vendor.html). As AWS CEO [Andy Jassy puts it](https://www.cnbc.com/2017/04/19/amazon-aws-chief-andy-jassy-on-oracle-customers-are-sick-of-it.html), no longer does the process of buying technology involve the purchase of heavy proprietary software with multi-year contracts that include annual maintenance fees. Now it’s about choice and ease of use, including letting customers turn things off if they’re not working. But choice also means not bundling all of your differentiating features into a massive contract. [List prices for Anthos](https://searchcloudcomputing.techtarget.com/news/252461985/Steep-Google-Anthos-pricing-geared-toward-large-enterprises) start at $10,000 per month per 100 virtual CPUs with a minimum one-year commitment. _This is just for the software layer_. It doesn’t include any of the underlying GCP infrastructure. Again, fine for organizations willing to throw similar sums of money at things like PCF or Outposts, but are plain old GKE users really going to get roped in to this nonsense? Are they going to lose out on value-added features?

Either GCP has a well-thought-out strategy for GKE and Anthos (which, given Google’s history, is frankly unlikely) and is simply tone deaf to how it would be perceived by people already skittish about a former Oracle exec taking the reigns as CEO or this will end in disaster. It’s entirely possible this is all just a misunderstanding and they are, in a misguided fashion, rebranding GKE to Anthos (it’s been [renamed once already](https://cloud.google.com/blog/products/gcp/introducing-certified-kubernetes-and-google-kubernetes-engine) and GCP has a history of rebranding existing products), but requiring a subscription hidden behind a sales contact form in order to use basic features is spooky.

My hope is that there is some longer-term strategy at play and GCP is not moving to an enterprise-subscription model for what should be GKE features. Best case, Google is just muddying the waters as they’ve done in the past. Worst case, they’re steamrolling their entire platform strategy to make way for enterprise sales. That would be tragic for Google given GKE is still by far and away the best managed Kubernetes service available. So what’s going on with GKE and Anthos?
