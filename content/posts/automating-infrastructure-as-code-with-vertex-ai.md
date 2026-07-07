---
title: "Automating Infrastructure as Code with Vertex AI"
date: 2024-11-05T15:23:09-07:00
lastmod: 2024-11-15T09:32:19-07:00
slug: "automating-infrastructure-as-code-with-vertex-ai"
categories: ["AI", "Cloud", "GCP", "JavaScript", "Konfigurate", "Real Kinetic"]
tags: ["ai", "gcp", "gemini", "generative ai", "iac", "konfigurate", "llm", "vertex ai"]
---

[![](/wp-content/uploads/2024/11/konfigurate_ai.gif)](/wp-content/uploads/2024/11/konfigurate_ai.gif)

A lot of companies are trying to figure out how AI can be used to improve their business. Most of them are struggling to not just implement AI, but to even find use cases that aren’t contrived and actually add value to their customers. We recently discovered a compelling use case for AI integration in our [Konfigurate platform](https://konfigurate.com/?utm_source=bravenewgeek.com&utm_campaign=vertex-ai), and we found that implementing generative AI doesn’t require a great deal of complexity. I’m going to walk you through what we learned about integrating an AI assistant into our production system. There’s a ton of noise out there about what you “need” to integrate AI into your product. The good news? You don’t need much. The bad news? It took too much time sifting through nonsense to find what actually helps deliver value with AI.

We’ll show you how to leverage Google’s [Vertex AI](https://cloud.google.com/vertex-ai?hl=en) with Gemini 1.5 to implement multimodal input for automating the creation of infrastructure as code. We’ll see how to make our AI assistant context-aware, how to configure output to be well-structured, how to tune the output without needing actual model tuning, and how to test the model.

## Our Use Case

### The Context

Konfigurate takes a modern approach to infrastructure as code (IaC) that shifts more concerns left into the development process such as security, compliance, and architecture standardization. In addition to managing your cloud infrastructure, it also integrates with GitHub or GitLab to manage your organization’s repository structure and CI/CD.

[Workloads](https://konfigurate.com/docs/workloads/) are organized into Platforms and Domains, creating a structured environment that connects GitHub/GitLab with your cloud platform for seamless application and infrastructure management. Everything in Konfigurate—Platforms, Domains, Workloads, Resources—is GitOps-driven and implemented through YAML configuration. Below is an example showing the configuration for an “Ecommerce” Platform:

```
apiVersion: konfig.realkinetic.com/v1alpha8
kind: Platform
metadata:
  name: ecommerce
  namespace: konfig-control-plane
  labels:
    konfig.realkinetic.com/control-plane: konfig-control-plane
spec:
  platformName: Ecommerce
  gitlab:
    parentGroupId: 88474985
  gcp:
    billingAccountId: "XXXXXX-XXXXXX-XXXXXX"
    parentFolderId: "38822600023"
    defaultEnvs:
      - label: dev
    services:
      defaults:
        - cloud-run
        - cloud-sql
        - pubsub
        - firestore
        - redis
  groups:
    dev:
      - ecomm-devs@realkinetic.com
    maintainer:
      - ecomm-maintainers@realkinetic.com
    owner:
      - sre@realkinetic.com
```

_Example Konfigurate Platform YAML_

### The Problem

The Konfigurate objects like Platforms, Domains, and Workloads are a well-structured problem. We have technical specifications for them defined in a way that’s easily interpretable by programs. In fact, as you can probably tell from the example above, they are simply Kubernetes CRDs, meaning they _are_—quite literally—well-defined APIs. And as you can tell from the example, these YAML configurations are fairly straightforward, but they can still be tedious to write by hand. Instead, usually what happens, which also happens with every other IaC tool, is definitions get copy/pasted and proliferated. We saw an opportunity for AI due to the structured nature of the system and definition of the problem space.

### The Solution

Our idea was to create an AI assistant that could generate Konfigurate IaC definitions based on flexible user input. Users could interact with the system in a couple different ways:

1.  **Text Description:** users could describe their desired system architecture using natural language, e.g. “Add a new analytics domain to the ecommerce platform and within it I need a new ETL pipeline that will pull data from the orders database, process it in Cloud Run, and write the transformed data to BigQuery.”  
    
2.  **Architecture Diagram:** users could provide an image of their architecture diagram.

While we only introduced support for natural language and image-based inputs, we also validated that it worked with _audio_\-based descriptions of the architecture as well with no additional effort. We tested this by recording ourselves describing the infrastructure and then providing an M4A file to the model. We decided not to include this mode of input since, while cool, it seemed not particularly practical.

### The Value

This multimodal approach not only saves developers hours of time spent on boilerplate code but also accommodates different working styles and preferences. Whether a team uses visual tools for architecture design or prefers text-based planning, our system can adapt, getting them up and running with minimal mental effort. Developers would still be responsible for verifying system behavior and testing, but the initial setup time could be drastically reduced across various input methods.

Critically, we found this feature makes IaC more accessible and productive for a much broader set of roles and skill sets. For instance, we’ve worked with mainframe COBOL engineers, data analysts, and developers with no cloud experience who are now able to more effectively implement cloud infrastructure and systems. It doesn’t _hide_ the IaC from them, it just gives them a reliable starting point to work from that is actually grounded to their environment and problem space. What we have found with our AI-assisted infrastructure and our more general approach to Visual IaC is that developers spend more time focusing on their actual product and less time on undifferentiated work.

### The Technology

Our team has a lot of GCP experience, so we decided to use the Vertex AI platform and the Gemini-1.5-Flash-002 model for this project. It was a no-brainer for us. We know the ins and outs of GCP, and Vertex AI offers an all-in-one managed solution that makes it easy to get going. This particular model is fast and most importantly it’s cost-effective. As I am sure this will ring true for many of you, we didn’t want to mess around with setting up our own infrastructure or dealing with the headaches of managing our own AI models. The Vertex AI Studio made it really easy to start developing and iterating prompts as well as trying different models.

[![](/wp-content/uploads/2024/11/vertex_ai_studio-1024x762.png)](/wp-content/uploads/2024/11/vertex_ai_studio.png)

Vertex AI Studio

## No, You Don’t Need RAG (At Least, We Didn’t)

Great, you’ve got your fancy AI setup, but don’t you need some complex retrieval system to make it context-aware? Sure, RAG (Retrieval Augmented Generation) is often touted as essential for creating context-aware AI agents. Our experience took us down a different path.

When researching how to create a context-aware GPT agent, you’ll inevitably encounter [RAG](https://cloud.google.com/use-cases/retrieval-augmented-generation?hl=en). This typically involves:

-   [Vector databases](https://medium.com/@mutahar789/optimizing-rag-a-guide-to-choosing-the-right-vector-database-480f71a33139) for efficient similarity search
-   Complex indexing and retrieval systems
-   Additional infrastructure for training and fine-tuning models

### Our Initial Approach

We started by preparing [JSONL](https://jsonlines.org/)\-formatted data thinking we’d feed it into a RAG system. The plan was to have our AI model learn from this structured data to understand our Konfigurate specifications like Platforms and Domains. As we experimented, we found that going the RAG route wasn’t giving us the consistent, high-quality outputs we needed, so we pivoted.

### The Big Prompt Solution

Instead of relying on RAG, we leaned heavily into prompt engineering. Here’s what we did:

1.  Long-Context Prompts: we crafted detailed prompts that provided the necessary context about our Konfigurate system, its components, and how they interact.
2.  Example IaC: as part of the prompt, we included numerous example definitions for Konfigurate objects such as Platforms and Domains.
3.  Example Prompts: we also included example prompts and their corresponding correct outputs, essentially “showing” the AI what we expected.
4.  Error Handling Prompts: we even included prompting that guided the AI on how to handle errors or edge cases.

### Why This Worked Better

1.  Consistency: by explicitly stating our requirements in the prompts, we got more consistent outputs.
2.  Flexibility: it was easier to tweak and refine our prompts than to restructure a RAG system.
3.  Control: we had more direct control over how the AI interpreted and used our domain-specific knowledge.
4.  Simplicity: no need for additional infrastructure or complex retrieval systems—instead, it’s just a single API call.

### The Takeaway

While RAG has its place, don’t assume it’s always necessary. For our use case, well-crafted prompts proved more effective than a sophisticated retrieval system. I believe this was a better fit because of the well-structured nature of our problem space. We can trivially validate the results output by the model because they are data structures with specifications. As a result, we got our context-aware AI assistant up and running faster, with better results, and without the overhead or complexity of RAG. Remember, in the world of technology, most times the simplest solution is the most elegant.

## Prompt Engineering: The Secret Sauce

While prompt engineering has become a bit of a meme, it turned out to be the most crucial part of this whole process. When you’re working with these AI models, everything boils down to how you craft your prompts. It’s where the magic happens—or doesn’t.

Let’s break down what this looks like in practice. We’re using the Vertex AI API with Node.js , so we started with their boilerplate code. The key player is the [getGenerativeModel()](https://cloud.google.com/vertex-ai/generative-ai/docs/reference/nodejs/latest#initialize-the-vertexai-class) function. Here’s a stripped-down version of what we’re feeding it:

```
const generativeModel = vertexAi.preview.getGenerativeModel({
  model: "gemini-1.5-flash-002",
  generationConfig: {
    maxOutputTokens: 4096,
    temperature: 0.2,
    topP: 0.95,
  },
  safetySettings: [
    {
      category: HarmCategory.HARM_CATEGORY_HATE_SPEECH,
      threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
    },
    {
      category: HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
      threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
    },
    {
      category: HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT,
      threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
    },
    {
      category: HarmCategory.HARM_CATEGORY_HARASSMENT,
      threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
    },
  ],
  systemInstruction: {
    role: "system",
    parts: [
      // Removed for brevity (detailed below)
    ],
  },
});
```

_Gemini 1.5 model initialization_

-   Model: We’re using the latest version of Gemini 1.5 Flash, which is a lightweight and cost-effective model that excels at multimodal tasks and processing large amounts of text.
-   Generation Config: This is where we control things like the max output length as well as the “temperature” of the model. _Temperature_ controls the randomness in token selection for the output. Gemini 1.5 Flash has a temperature range of 0 to 2 with 1 being the default. A lower temperature is good when you’re looking for a “true or correct” response, while a higher temperature can result in more diverse or unexpected results. This can be good for use cases that require a more “creative” model, but since our use case requires quite a bit of precision, we opted for a low temperature value.
-   Safety Settings: These are Google’s defaults. Refer to their [documentation](https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/configure-safety-filters#configurable-filters) for customization.
-   [System Instruction](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/prompts/system-instructions): This is the real meat of prompt engineering. It’s where you prime the model, giving it context and setting its role. I’ve omitted this from the example above to go into more depth on this below since it’s a critical part of the solution.

### The Art and Science of Prompting

Here’s the thing: prompt engineering is a fine line between science and art. We spent a non-trivial amount of time crafting our prompts to get consistent, useful outputs. It’s not just about dumping information, it’s about structuring it in a way that guides the AI to give you what you actually need. Remember, these models will do exactly what you tell them to do, not necessarily what you _want_ them to do. Sound familiar? It’s like debugging code, but instead of fixing logic errors, you’re fine-tuning language.

Fair warning, this is probably where you’ll spend most of your engineering time. It’s tempting to think the AI will just “get it,” but that’s not how this works. You need to be painfully clear and specific in your instructions. We went through many iterations, tweaking words here and there, restructuring our prompts, and sometimes completely overhauling our approach. But each iteration got us closer to that sweet spot where the model consistently churned out exactly what we needed. In the end, nailing your prompt engineering is what separates a frustrating, inconsistent AI experience from one that feels like you’ve just added a new team member to your crew.

The System Instructions mentioned above provide a way to inform the model how it should behave, provide it context, tell it how to structure output, and so forth. Though this information is separate from the actual user-provided prompt, they are still technically part of the overall prompt sent into the model. Effectively, System Instructions provide a way to factor out common prompt components from the user-provided prompt. I won’t show all of our System Instructions because there are quite a few, but I’ll show several examples below to give you an idea. Again, this is about being painstakingly explicit and clear about what you want the model to do.

-   “Konfigurate is a system that manages cloud infrastructure in AWS or Google Cloud Platform. It uses Kubernetes YAML files in order to specify the configuration. Konfigurate makes it easy for developers to quickly and safely configure and deploy cloud resources within a company’s standards. You are a Platform Engineer who’s job is to help Application Software Engineers author their Konfigurate YAML specifications.”
-   “I am going to provide some example Konfigurate YAML files for your reference. Never output this example YAML directly. Rather, when providing examples in your output, generate new examples with different names and so forth.”
-   “Please provide the complete YAML output without any explanations or markdown formatting.”
-   “If the user asks about something other than Konfigurate or if you are unable to produce Konfigurate YAML for their prompt, tell them you cannot help with that (this is the one case to return something other than YAML). Specifically, respond with the following: ‘Sorry, I’m unable to help with that.’”

### Controlling Output and Context-Awareness

The example System Instructions above hint at this but it’s something worth going into more detail. First, our AI assistant has a very specific task: generate Konfigurate IaC YAML for users. For this reason, we never want it to output anything other than Konfigurate YAML to users, nor do we want it to respond to any prompts that are not directly related to Konfigurate. We handle this purely through prompting. To help the model understand Konfigurate IaC, we provide it with an extensive set of examples and tell it to only ever output complete YAML without any explanations or markdown formatting.

However, the output is actually more involved than this for our situation. That’s because we don’t just want to support generating new IaC, but also modify existing resources as well. This means the model doesn’t just need to be context-aware, it also needs to understand the distinction between “this is a new resource” and “this is an existing resource being modified.” This is important because Konfigurate is GitOps-driven, meaning the IaC resources are created in a branch and then a pull request is created for the changes. We need to know which resources are being created or modified, and if the latter, where those resources live.

[![](/wp-content/uploads/2024/11/konfigurate_ai_modify_resource.gif)](/wp-content/uploads/2024/11/konfigurate_ai_modify_resource.gif)

Modifying an existing resource

To make the model context-aware, we feed it the definitions for the existing resources in the user’s environment. This needs to happen at “prompt time”, so this information is not included as part of the System Instructions. Instead, we fetch this information on demand when a user prompt is submitted and augment their prompt with it. Additionally, we provide the UI context in which the user is submitting the prompt from. For example, if they submit a prompt to create a new Domain while within the Ecommerce Platform, we can infer that they wish to create a new Domain within this specific Platform. It may seem obvious to us, but the model is completely unaware of this and so we need to provide it with this context. Below is the full code showing how this works and how the prompt is constructed.

```
export const generateYaml = async (
  context: AIContext,
  prompt: string,
  fileData?: FileData,
) => {
  const k8sApi = kc.makeApiClient(k8s.CustomObjectsApi);
  const { controlPlaneProjectId, defaultBranch } = await getOrSetGitlabContext(k8sApi);

  // Get user's environment information from the control plane
  const [placeholders, konfigObjects] = await Promise.all([
    getPlaceHolders(),
    getKonfigObjectsYAML(controlPlaneProjectId, defaultBranch),
  ]);

  const parts: Part[] = [];
  if (fileData) {
    parts.push({
      fileData,
    });
  }
  if (prompt) {
    parts.push({
      text: prompt,
    });
  }

  // Add user's environment context to the prompt
  parts.push(
    {
      text:
        "Replace the placeholders with the following values if they should be present " +
        "in the output YAML unless the prompt is referring to actual YAMLs from the " + 
        "user's environment, in which case use the YAML as is without replacing " +
        "values: " + JSON.stringify(placeholders, null, 2) + ".",
    },
    {
      text:
        'Following the "---" below are all existing Konfigurate YAMLs for the ' +
        "user\'s environment should they be needed either to reference or modify " +
        "and provide as output based on the prompt. Don't forget to never output " +
        "the example YAML exactly as is without modifications. Only output " +
        "Konfigurate object YAML and no other YAML structures. Infer appropriate " +
        "emails for dev, maintainer, and owner groups based on those in the " +
        "provided YAML below if possible.\n" +
        "---\n" +
        konfigObjects +
        "\n---\n",
    },
  );

  // Add user's UI context to the prompt
  if (context) {
    let contextPrompt = "";
    let contextSet = false;
    if (context.platform && context.domain && context.workload) {
      contextPrompt = `The user is operating within the context of the ${context.workload} Workload which is in the ${context.domain} Domain of the ${context.platform} Platform.`;
      contextSet = true;
    } else if (context.platform && context.domain) {
      contextPrompt = `The user is operating within the context of the ${context.domain} Domain of the ${context.platform} Platform.`;
      contextSet = true;
    } else if (context.platform) {
      contextPrompt = `The user is operating within the context of the ${context.platform} Platform.`;
      contextSet = true;
    }

    if (contextSet) {
      contextPrompt +=
        " Use this context to infer where output objects should go should " +
        "the user not provide explicit instructions in the prompt.";
      parts.push({
        text: contextPrompt,
      });
    }
  }

  const contents: Content[] = [
    {
      role: "user",
      parts,
    },
  ];

  const req: GenerateContentRequest = {
    contents,
  };

  const resp = await makeVertexRequest(req);
  return { error: resp === errorResponseMessage, content: resp };
};
```

This prompt manipulation makes the model smart enough to understand the user’s environment and the context in which they are operating within. Feeding it all of this information is possible due to Gemini 1.5’s context window. The context window acts like a short-term memory, allowing the model to recall information as part of its output generation. While a person’s short-term memory is generally quite limited both in terms of the amount of information and recall accuracy, generative models like Gemini 1.5 can have _massive_ context windows and near-perfect recall. Gemini 1.5 Flash in particular has a _1-million-token_ context window, and Gemini 1.5 Pro has a 2-million-token context window. For reference, 1 million tokens is the equivalent of 50,000 lines of code (with standard 80 characters per line) or 8 average-length English novels. This is called “[long context](https://cloud.google.com/vertex-ai/generative-ai/docs/long-context)”, and it allows us to provide the model with _massive_ prompts while it is still able to find a “needle in a haystack.”

Long context has allowed us to make the model context-aware with minimal effort, but there’s still a question we have not yet addressed: how can the model also output metadata along with the generated IaC YAML? Specifically, we need to know the file path for each respective Konfigurate object so that we create new resources in the right place or we modify the correct existing resources. The answer, of course, is more prompt engineering. To solve this problem, we instructed the model to include metadata YAML with each Konfigurate object. This metadata contains the file path for the object and whether or not it’s an existing resource. Here’s an example:

```
apiVersion: konfig.realkinetic.com/v1alpha8
kind: Domain
metadata:
  name: dashboard
  namespace: konfig-control-plane
  labels:
    konfig.realkinetic.com/platform: internal-services
spec:
  domainName: Dashboards
---
filePath: konfig/internal-services/dashboard-domain.yaml
isExisting: false
```

We did this by providing the model with several examples. Here is the System Instruction prompt we used:

```
{
  text:
    "For each Konfigurate YAML you output, include the following metadata, " +
    "also in YAML format, following the Konfigurate object itself: " +
    "filePath, isExisting. Here are some examples:\n" + metadataExample,
}
```

It seems simple, but it was surprisingly effective and reliable.

### Model Stability and Testing

Working with LLMs is a bit like describing a problem to someone else who writes the code to solve it—but without seeing the code, making it impossible to debug when issues arise. Worse yet, subtle changes in the description of the problem is akin to the other person starting over fully from scratch each time, so you might get consistent results _or_ it could be completely different. There are also cases where no matter how explicit you are in your prompting, the model just _doesn’t do the right thing_. For example, with Gemini-1.5-Flash-001, I had problems preventing the AI from outputting the examples verbatim. I told it, in a variety of ways, to generate _new_ examples using the provided ones as reference for the overall structure of resources, but it simply wouldn’t do it—_until I upgraded to Gemini-1.5-Flash-002_.

What we saw is that something as simple as just changing the model version could result in wildly different output. This is a nascent area but it’s a major challenge for companies attempting to leverage generative AI within their products or, _worse_, as a core component of their product. The only solution I can think of is to have a battery of test prompts you feed your AI and compare the results. But even this is problematic as the output content might be the same but the _structure_ may have slight variations. In our case because we are generating YAML, it’s easy for us to validate output, but for use cases that are less structured, this seems like a major concern. Another solution is to feed results into a _different_ model, but this feels equally precarious.

In addition to model stability, we had some challenges with “jailbreaking” the model. While we were never able to jailbreak the model to operate outside the context of Konfigurate, we were on occasion able to get it to provide Konfigurate output that was outside the bounds of our prompting. We did not invest a ton of time into this area as it felt like there wasn’t great ROI and it wasn’t really a concern within our product, but it’s certainly a concern when building with LLMs.

### Patterns That Worked For Us: Prompt Engineering Pro Tips

You have stuck with us this far and now it’s time for some concrete strategies that consistently improved our AI’s performance. Here’s what we learned:

-   **Be Specific About Output**: tell the model exactly what you want and how you want it. For us, that meant specifying YAML as the output format. Don’t leave room for interpretation—the clearer you are, the better the results.
-   **Show, Don’t Just Tell**: give the model examples of what good output looks like. We explicitly prompted our model to reference our example resource specifications. It’s like training a new team member—_show_ them what success looks like.
-   **Use Placeholders**: providing examples to the model worked great, except when it would use specific field values from the examples in the user’s output. To address this we used sentinel placeholder values in the examples and then had a step that told the model to replace the placeholders with values from the user’s environment at prompt time.
-   **Error Handling is Key:** just like you’d build error handling into your code, build it into your prompts. Give the model clear instructions on how to respond when it encounters ambiguous or out-of-scope requests. This keeps the user experience smooth, even when things go sideways.
-   **The Anti-Hallucination Trick:** it sounds silly but it helps to explicitly tell the model _not_ to hallucinate and to only respond within the context you’ve provided. It’s not foolproof, but we’ve seen a significant reduction in made-up information, especially when you’ve fine-tuned the temperature.

Remember, prompt engineering is an iterative process. What works for one use case might not work for another. Keep experimenting, keep refining, and don’t be afraid to start from scratch if something’s not clicking. The goal is to find that sweet spot where your AI becomes a reliable, consistent part of your workflow.

## Wrapping It Up

There you have it, our journey into integrating AI into the Konfigurate platform. We started thinking we needed all sorts of fancy tech only to find that sometimes, simpler is better. The big takeaways?

-   You don’t always need complex systems like RAG. A well-crafted prompt can often do the job just as well, if not better. Gemini 1.5’s long context and near-perfect recall makes it quite adept at the “needle-in-a-haystack” problem, and it enables pretty sophisticated use cases through complex prompting.
-   Prompt engineering isn’t just a buzzword or meme. It’s where the real work happens, and it’s worth investing your time to get it right.
-   LLMs are well-suited to structured problems because they are good at pattern matching. They’re also good at creative problems, but it’s less clear to us how to integrate something like this into a product versus a structured problem.
-   The AI landscape is constantly evolving. What works today might not be the best approach tomorrow. Stay flexible and keep experimenting.

We hope sharing our experience saves you some time and headaches. Remember, there’s no one-size-fits-all solution in AI integration. What worked for us might need tweaking for your specific use case. The key is to start simple, iterate often, and don’t be afraid to challenge conventional wisdom. You might just find that the “must-have” tools aren’t so must-have after all.

Now, go forth and build something cool!
