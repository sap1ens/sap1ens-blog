---
layout: post
title: "Syrup - Scrum CLI tool"
date: 2016-07-11 19:25:15 -0700
comments: true
categories:
- Node
---

At Bench we’re convinced that GitHub should be a central place for everything project-related: codebase, documentation, tasks. That’s why we don’t use any specific Project Management software, but instead we try to use GitHub.

Obviously GitHub has a very limited set of features: issues, labels, milestones. But, surprisingly, it’s good enough foundation that can be used by other services, for example [Waffle.io](https://waffle.io).

Waffle gives you Kanban-style dashboard for managing your tasks. It has two-way synchronization with GitHub, so every change in GitHub is propagated to Waffle in near real-time and vice versa. Waffle also uses labels to organize issues in columns, which makes everything easier from the GitHub side.

Still, there are lots of problems if you want to use GitHub & Waffle for your Scrum process. That’s why I’ve been working on [syrup](https://github.com/sap1ens/syrup), CLI tool for Scrum. [Readme](https://github.com/sap1ens/syrup/blob/master/README.md) has lots of details describing Waffle problems and suggested workflow to overcome them. It’s published as [npm module](https://www.npmjs.com/package/syrup-cli), so it’s really easy to install.

From technical point of view it’s a very simple Node.js/ES6 app (using Babel) that mostly uses GitHub API for fetching data.

PS: currently I investigate [ZenHub](https://www.zenhub.com) as a Waffle & Syrup replacement. It solves the same problems and brings even more features, like built-in epics and burndown charts. At the same time, Waffle is completely free even for private repositories (and ZenHub [is not](https://www.zenhub.com/pricing)). Syrup still can be useful for ZenHub though, you can find more details in [Readme](https://github.com/sap1ens/syrup/blob/master/README.md#zenhub-workflow).