---
title: "Authenticating Stackdriver Uptime Checks for Identity-Aware Proxy"
date: 2019-01-29T14:46:43-06:00
lastmod: 2019-01-29T15:36:12-06:00
slug: "authenticating-stackdriver-uptime-checks-for-identity-aware-proxy"
categories: ["Cloud", "GCP", "Security", "Software Architecture"]
tags: ["api", "app engine", "architecture", "authentication", "authorization", "cloud", "cloud functions", "gcp", "health checks", "iap", "identity-aware proxy", "monitoring", "oauth2", "openid connect", "ops", "security", "serverless", "service accounts", "stackdriver", "uptime checks"]
---

[Google Stackdriver](https://cloud.google.com/stackdriver/) provides a set of tools for monitoring and managing services running in GCP, AWS, or on-prem infrastructure. One feature Stackdriver has is “uptime checks,” which enable you to verify the availability of your service and track response latencies over time from up to six different geographic locations around the world. While Stackdriver uptime checks are not as feature-rich as other similar products such as [Pingdom](https://www.pingdom.com/), they are also completely _free_. For GCP users, this provides a great starting point for quickly setting up health checks and alerting for your applications.  

[Last week](https://bravenewgeek.com/api-authentication-with-gcp-identity-aware-proxy/) I looked at implementing authentication and authorization for APIs in GCP using [Cloud Identity-Aware Proxy (IAP)](https://cloud.google.com/iap/). IAP provides an easy way to implement identity and access management (IAM) for applications and APIs in a centralized place. However, one thing you will bump into when using Stackdriver uptime checks in combination with IAP is authentication. For App Engine in particular, this can be a problem since there is no way to bypass IAP. All traffic, both internal and external to GCP, goes through it. Until [Cloud IAM Conditions](https://cloud.google.com/iam/docs/conditions-overview) is released and generally available, there’s no way to—for example—open up a health-check endpoint with IAP.  

While uptime checks have support for Basic HTTP authentication, there is no way to script more sophisticated request flows (e.g. to implement the OpenID Connect (OIDC) authentication flow for IAP-protected resources) or implement fine-grained IAM policies (as hinted at above, this is coming with [IAP Context-Aware Access](https://cloud.google.com/iap/docs/cloud-iap-context-aware-access-howto) and IAM Conditions). So are we relegated to using Nagios or some other more complicated monitoring tool? Not necessarily. In this post, I’ll present a workaround solution for authenticating Stackdriver uptime checks for systems protected by IAP using [Google Cloud Functions](https://cloud.google.com/functions/).

## The Solution  

The general strategy is to use a Cloud Function which can authenticate with IAP using a service account to proxy uptime checks to the application. Essentially, the proxy takes a request from a client, looks for a header containing a host, forwards the request that host after performing the necessary authentication, and then forwards the response back to the client. The general architecture of this is shown below.

![](/wp-content/uploads/2019/01/uptime-check-arch.png)

There are some trade-offs with this approach. The benefit is we get to rely on health checks that are fully managed by GCP and free of charge. Since Cloud Functions are also managed by GCP, there’s no operations involved beyond deploying the proxy and setting it up. The first two million invocations per month are free for Cloud Functions. If we have an uptime check running every five minutes from six different locations, that’s approximately 52,560 invocations per month. This means we could run roughly 38 different uptime checks without exceeding the free tier for invocations. In addition to invocations, the free tier offers 400,000 GB-seconds, 200,000 GHz-seconds of compute time and 5GB of Internet egress traffic per month. Using the [GCP pricing calculator](https://cloud.google.com/products/calculator/), we can estimate the cost for our uptime check. It generally [won’t come close](https://cloud.google.com/products/calculator/#id=e9845144-9690-4ee6-be35-b61d39851793) to exceeding the free tier.

The downside to this approach is the check is no longer validating availability from the perspective of an end user. Because the actual service request is originating from Google’s infrastructure by way of a Cloud Function as opposed to Stackdriver itself, it’s not quite the same as a true end-to-end check. That said, both Cloud Functions and App Engine rely on the same [Google Front End (GFE)](https://cloud.google.com/security/infrastructure/design/#google_front_end_service) infrastructure, so as long as both the proxy and App Engine application are located in the same region, this is probably not all that important. Besides, for App Engine at least, the value of the uptime check is really more around performing a full-stack probe of the application and its dependencies than monitoring the health of Google’s own infrastructure. That is one of the goals behind using managed services after all. The bigger downside is that the latency reported by the uptime check no longer accurately represents the application. It can still be useful for monitoring aggregate trends nonetheless.

## The Implementation Setup

I’ve built an open-source implementation of the proxy as a Cloud Function in Python called [gcp-oidc-proxy](https://github.com/RealKinetic/gcp-oidc-proxy). It’s runnable out of the box without any modification. We’ll assume you have an IAP-protected application you want to setup a Stackdriver uptime check for. To deploy the proxy Cloud Function, first clone the repository to your machine, then from there run the following _gcloud_ command:

```
$ gcloud functions deploy gcp-oidc-proxy \    --runtime python37 \    --entry-point handle_request \    --trigger-http
```

This will deploy a new Cloud Function called _gcp-oidc-proxy_ to your configured cloud project. It will assume the project’s default service account. Ordinarily, I would suggest creating a separate service account to limit scopes. This can be configured on the Cloud Function with the _–service-account_ flag, which is under _gcloud beta functions deploy_ at the time of this writing. We’ll omit this step for brevity however.

Next, we need to add the “Service Account Actor” IAM role to the Cloud Function’s service account since it will need it to sign JWTs (more on this later). In the GCP console, go to _IAM & admin_, locate the appropriate service account (in this case, the default service account), and add the respective role.

![](/wp-content/uploads/2019/01/service-account-actor-role.png)

The Cloud Function’s service account must also be added as a member to the IAP with the “IAP-secured Web App User” role in order to properly authenticate. Navigate to _Identity-Aware Proxy_ in the GCP console, select the resource you wish to add the service account to, then click _Add Member_.

![](/wp-content/uploads/2019/01/service-account-iap.png)

Find the OAuth2 client ID for the IAP by clicking on the options menu next to the IAP resource and select “Edit OAuth client.” Copy the client ID on the next page and then navigate to the newly deployed _gcp-oidc-proxy_ Cloud Function. We need to configure a few environment variables, so click _edit_ and then expand _more_ at the bottom of the page. We’ll add four environment variables: _CLIENT\_ID_, _WHITELIST_, _AUTH\_USERNAME_, and _AUTH\_PASSWORD_.

![](/wp-content/uploads/2019/01/gcp-oidc-proxy-env-vars.png)

_CLIENT\_ID_ contains the OAuth2 client ID we copied for the IAP. _WHITELIST_ contains a comma-separated list of URL paths to make accessible or _\*_ for everything (I’m using _/ping_ in my example application), and _AUTH\_USERNAME_ and _AUTH\_PASSWORD_ setup Basic authentication for the Cloud Function. If these are omitted, authentication is disabled.

Save the changes to redeploy the function with the new environment variables. Next, we’ll setup a Stackdriver uptime check that uses the proxy to call our service. In the GCP console, navigate to _Monitoring_ then _Create Check_ from the Stackdriver UI. Skip any suggestions for creating a new uptime check. For the hostname, use the Cloud Function host. For the path, use _/gcp-oidc/proxy/<your-endpoint>_. The proxy will use the path to make a request to the protected resource.

![](/wp-content/uploads/2019/01/uptime-check.png)

Expand _Advanced Options_ to set the _Forward-Host_ to the host protected by IAP. The proxy uses this header to forward requests. Lastly, we’ll set the authentication username and password that we configured on the Cloud Function.

![](/wp-content/uploads/2019/01/uptime-check-advanced.png)

Click “Test” to ensure our configuration works and the check passes.

## The Implementation Details

The remainder of this post will walk you through the implementation details of the proxy. The implementation closely resembles what we did to [authenticate API consumers](https://bravenewgeek.com/api-authentication-with-gcp-identity-aware-proxy/) using a service account. We use a header called _Forward-Host_ to allow the client to specify the IAP-authenticated host to forward requests to. If the header is not present, we just return a 400 error. We then use this host and the path of the original request to construct the proxy request and retain the HTTP method and headers (with the exception of the _Host_ header, if present, since this can cause problems).

<script src="https://gist.github.com/tylertreat/1dc68e12997e73256c81c74549a9cf6b.js"></script>

Before sending the request, we perform the authentication process by generating a JWT signed by the service account and exchange it for a Google-signed OIDC token.

<script src="https://gist.github.com/tylertreat/2f756ff162b8d4cdc35e7de45a259273.js"></script>

We can cache this token and renew it only once it expires. Then we set the _Authorization_ header with the OIDC token and send the request.

<script src="https://gist.github.com/tylertreat/e6e8f1fcd95d29e2f804fbee631bdf4b.js"></script>

We simply forward on the resulting content body, status code, and headers. We strip HTTP/1.1 [“hop-by-hop” headers](https://www.w3.org/Protocols/rfc2616/rfc2616-sec13.html#sec13.5.1) since these are unsupported by WSGI and Python Cloud Functions rely on [Flask](http://flask.pocoo.org/). We also strip any _Content-Encoding_ header since this can also cause problems.

<script src="https://gist.github.com/tylertreat/6b14aea5b7784b6b9b0605844f7cfc8a.js"></script>

Because this proxy allows clients to call into endpoints unauthenticated, we also implement a whitelist to expose only certain endpoints. The whitelist is a list of allowed paths passed in from an environment variable. Alternatively, we can whitelist _\*_ to allow all paths. Wildcarding could be implemented to make this even more flexible. We also implement a Basic auth decorator which is configured with environment variables since we can setup uptime checks with a username and password in Stackdriver.

<script src="https://gist.github.com/tylertreat/1603f353c1ff04be3045c2e593f3895b.js"></script>

The only other code worth looking at in detail is how we setup the service account credentials and IAM _Signer_. A Cloud Function has a service account attached to it which allows it to assume the roles of that account. Cloud Functions rely on the [Google Compute Engine metadata server](https://cloud.google.com/compute/docs/storing-retrieving-metadata) which stores service account information among other things. However, the metadata server doesn’t expose the service account key used to sign the JWT, so instead we must use the [IAM signBlob API](https://cloud.google.com/iam/reference/rest/v1/projects.serviceAccounts/signBlob) to sign JWTs.

<script src="https://gist.github.com/tylertreat/fb63b4f98ebcbdb88c787f2724b9fc6d.js"></script>

# Conclusion

It’s not a particularly simple solution, but it gets the job done. The setup of the Cloud Function could definitely be scripted as well. Once IAM Conditions is generally available, it should be possible to expose certain endpoints in a way that is accessible to Stackdriver without the need for the OIDC proxy. That said, it’s not clear if there is a way to implement uptime checks without exposing an endpoint at all since there is currently no way to assign a service account to a check. Ideally, we would be able to assign a service account and use that with IAP Context-Aware Access to allow the uptime check to access protected endpoints.
