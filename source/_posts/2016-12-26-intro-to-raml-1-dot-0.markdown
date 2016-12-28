---
layout: post
title: "Intro To RAML 1.0"
date: 2016-12-26 14:37:27 -0800
comments: true
categories:
- RAML
- API
---

Pretty much every web developer has built HTTP APIs. How does it usually happen? If you have good practices established in your team you probably start with a whiteboarding session. Good one-hour exercise with your colleagues produces something that we call "API spec". It might look like this:

{% img /images/posts/api-spec.jpg 960 %}

Great job everyone! Although, we forgot a few "minor" things:

- Error messages and error HTTP codes
- Authorization and authentication
- Schema for the entities
- Versioning
- ... >_<
- And the most important, does it actually satisfy consumers (like front-end apps or other systems)?

Multiply that by number of years you're going to maintain that (∞) and the rate of adding new features... Looks really depressing. Our beautifully designed "API spec" quickly becomes a pile of unmaintainable mess. Is there a better way to do it?

<!-- more -->

## RAML vs Swagger

I'm going to talk about RAML ([RESTful API Modeling Language](http://raml.org/)) today. You probably heard about [Swagger](http://swagger.io/)? It seems to be more popular, so why not use it?

~~Swagger and RAML are *really* similar, but RAML 1.0 uses its own YAML-based format to describe entities. Swagger (and RAML 0.8) uses JSON Schema, which, I think, is inhuman to read. JSON Schema is a great standard when you need to write it once, add to your validators and forget about it. But when you need to constantly iterate and spend most of the time reading it's just really cruel. As an example, try to find a big and relatively complicated JSON Schema file and understand it without a bunch of examples. Then compare it with RAML 1.0 types ;-)~~

Swagger 2.0 / Open API standard is actually really similar to RAML, including YAML-based format to describe entities. I still feel like RAML has more flexible, concise and elegant language.

## Syntax

Let's look at the RAML example:

```yaml
#%RAML 1.0
title: New API
version: v1
baseUri: http://api.samplehost.com
types:
  TestType:
    type: object
    properties:
      id: number
      optional?: string
      expanded:
        type: object
        properties:
          count: number
/helloWorld:
  get:
    responses:
      200:
        body:
          application/json:
            type: TestType
            example:
              id: 12345
              expanded:
                count: 10
```

It looks really straightforward!

First, we define a few generic fields like title, version and baseUri.

Then we describe types I mentioned previously. Here you can include your request/response entities, error messages and even custom "primitive" types like Money or Location. Types can refer to each other, have multiple nesting levels, contain arrays, etc.

And finally we specify all routes including paths, HTTP verbs, HTTP codes, requests (for POST, PUT & PATCH) and responses describing content types with the actual content (usually referring to a predefined type). It's also a good practice to include an example.

Here's another RAML snippet:

```yaml
/subscriptions:
  delete:
    queryParameters:
      client_id:
        description: "Application's client id"
        required: true
      id:
        description: Id of subscription to be removed.
    responses:
      200:
        body:
          application/json:
	        type: SubscriptionsDelete
```

We defined `/subscriptions` path with DELETE action that accepts a few query parameters. As you can see, we can specify if any of those are required.

And one more snippet:

```yaml
/gists:
  post:
    description: Create a gist.
    body:
      application/json:
        type: PostGist
    responses:
      201:
        body:
          application/json:
            type: Gist
```

Here we can see how to use types to define entities for responses AND requests.

You can find detailed RAML 1.0 spec [here](https://github.com/raml-org/raml-spec/blob/master/versions/raml-10/raml-10.md/).

## Tooling

I'm going to mention some tools with RAML 1.0 support that I've actually recently used.

### API Workbench

[API Workbench](http://apiworkbench.com/) is a plugin for [Atom](https://atom.io/). It's awesome! It supports RAML 1.0 standard, validates all your definitions and auto-completes everything. Also it has a nice scaffold project that can be used right away.

### RAML 1.0 JS Parser

[RAML 1.0 JS Parser](https://github.com/raml-org/raml-js-parser-2) is a parser with full RAML 1.0 support, as you can guess. It has very detailed documentation and works perfectly with any RAML file I throw in it. It can be used as a solid foundation for your API client library, for example. Also, some projects below actually use it to parse RAML.

### RAML Mockup

[RAML Mockup](https://github.com/sap1ens/raml-1-mockup) is my fork of another RAML mockup server. It's really handy to be able to use the API endpoints you defined just in a few seconds, without any back-end work. This tool parses the RAML definition and creates Express.js-based API dynamically, so you can call your endpoints with curl or tools like Postman.

Original repo claims to support RAML 1.0, but it uses JSON Schema definitions to generate mock data. In my case I rely on examples defined for types, either "inline" (in responses) or on the top level. When you define multiple examples and route returns a single entity the mockup server will actually pick one of the examples randomly.

### API Console

Do you want to have fully interactive and 100% full API documentation in just a few minutes? Run the RAML Mockup tool I mentioned above and use [API Console](https://github.com/mulesoft/api-console) as a front-end. Now you don't even need curl to explore the API, you'll see all endpoints with a bunch of documentation and examples right in your browser.

You can also use it without the mock server, but in this case you won't be able to actually call any endpoints. It might be a valid use-case if you just want to demo something like API conventions.

### ... and more!

There are lots of other tools (including API client generators) that you can find [here](http://raml.org/projects/projects). Unfortunately most of them only support RAML 0.8, but I hope it'll change soon.

For example, I didn't have a chance to try, but [Go/Python Server/Client generator](https://github.com/Jumpscale/go-raml) looks really promising.

There are also tools like [RAML Tester](https://github.com/nidi3/raml-tester) that can test existing APIs against RAML specs. It can be very helpful for iterative development and continuous integration.

## Workflow

Ok, so you're familiar with RAML syntax now and you know about all these tools. What's next?

I truly believe that RAML spec should be the first step in any project related to API development. You have to work on the spec without even talking about front-end or back-end languages/frameworks. Why? Because you shouldn't limit yourself based on some weird standard one of the frameworks uses. You actually have to focus on solving business problem using domain language, in the best way possible.

Once you have the first version of the RAML spec you can actually start talking with front-end and back-end engineers about implementation details, as well as business people about the language and definitions (we all should use [Domain Driven Design](https://en.wikipedia.org/wiki/Domain-driven_design), especially in APIs). RAML tester, mock server, interactive docs and auto-generated clients will help you to build MVP very fast.

## Summary

RAML 1.0 is a relatively new standard without a lot of support yet, but it's really powerful! I didn't even mention things like overlays, annotations or multiple inheritance in types! RAML 1.0 is a huge spec and you probably will start using only 30% of it in the beginning.

What I also really like - you don't need to use any of those tools and features right away! You can simply start with your favourite editor and small RAML definition, which is already way better than nothing ;-)

***Update 1***: Hacker News comments - https://news.ycombinator.com/item?id=13260266

***Update 2***: Updated **RAML vs Swagger** section.