---
title: Claude Code Helped Me Resurrect a Five Year Old Codebase
pubDatetime: "2026-02-02T03:01:13-05:00"
description: How AI showed me what is possible in brownfield open source software
heroImage: /assets/blog/claude-code-helped-me-resurrect-a-five-year-old-codebase/fresh-coat-on-solid-foundation.jpg
categories:
  - "[[Posts]]"
author: "Justin Carlson"
url:
created: 2026-02-02
topics: []
draft: false
tags:
  - claudecode
  - gsd
heroImageAlt: Pencil sketch of a worker on a ladder applying a fresh coat of paint to a weathered  wooden house with a solid stone foundation
heroImageCaption: The foundation was never the problem.
---

If you've ever worked as a Zendesk agent, you know the tab problem. Click a ticket link in Slack, new tab. Click another in email, another tab. Before lunch you're drowning in fifteen Zendesk tabs, all showing slightly different states of the same workspace.

QuickTab, a classic browser extension, solved this. It intercepted Zendesk links and routed them to your existing agent tab instead of spawning new ones. Simple concept, useful for enterprise support teams.

Then Tymeshift's version got pulled from the Chrome Web Store. The alternatives I found were... sketchy. Not the kind of thing you install on a corporate machine. I needed a trustworthy open source option, and the original [zendesk/QuickTab](https://github.com/zendesklabs/QuickTab) had been archived since December 2020.

Why abandoned? Google's Manifest V3 requirements. Chrome extensions had gotten dramatically more complex, with stricter security policies and a completely different architecture. The original codebase was jQuery 1.6.1, Grunt, Webpack 1.x. 2015-era tooling facing 2026-era requirements. The gap was massive.

## Why I Didn't Just Fix It Myself

I'm not a software engineer. I'm a technician. A problem solver. My relationship with code mostly involves reviewing console logs and occasionally tweaking a config file. Building something from scratch has always been outside my ceiling.

The QuickTab codebase was quite outdated:

```
BEFORE (2020)
═════════════
┣ jQuery 1.6.1 (known security vulnerabilities)
┣ Handlebars 2.0 templating
┣ Grunt + Webpack 1.x build system
┣ ES5 JavaScript
┣ Zero tests
┗ Manifest V2 (deprecated)
```

As far as I could tell, Google's extension requirements killed it. Service workers that die after 30 seconds. Synchronous event listener registration. Storage-first architecture patterns.

## The Spark: Gemini MVP

Then my friend [Zach](https://github.com/zachvier) built something that made me reconsider. Using Gemini, he put together an MVP. Rough, but it worked.

If AI could help him build a working prototype, maybe it could help me finish the project properly.

## Enter Claude Code + GSD

I have been using Claude Code since the summer of 2025. It's super powerful, but it's also easy to auger yourself headfirst into problems with no way of getting yourself out without starting from scratch. For non-SWEs, you can definitely get into trouble. I certainly have more times than I can count.

Recently, I started working with Claude Code using a workflow called [GSD (Get Shit Done)](https://github.com/glittercowboy/get-shit-done). It's a systematic approach: research first, then plan, then execute in phases with verification at each step. Methodical.

The pitfalls research impressed me. Before writing a single line of code, Claude synthesized documentation from Chrome's developer docs, community issue trackers, and framework comparisons into a single document mapping out ten major traps in MV3 migration.

The biggest trap: **service worker state loss.** In the old Manifest V2 world, background pages were persistent. You could store data in variables and it would just... stay there. In MV3, service workers terminate after 30 seconds of inactivity. Any global variables? Gone. This is the trap that silently kills migrations. Code works perfectly in development (because DevTools keeps the worker alive) and fails mysteriously in production.

The solution is "storage-first architecture" — every piece of runtime state lives in Chrome's storage API, not in memory. The service worker wakes up, reads state, handles the event, writes state back, and goes to sleep. Knowing this before writing code meant I never hit the wall that kills most MV3 migrations.

Then there was the archaeology. Going through five-year-old code, trying to understand decisions made by developers I'd never met. In one file, I found version-checking logic that was literally inverted — `hasUpdated` returned false when the version increased. It had been wrong for five years and nobody noticed because it didn't break anything critical.

I'm not sharing this to shame the original developers. They shipped something useful that helped real people. But finding issues like this, and getting them right, was part of reaching a quality bar I could feel confident about.

## The Result

After six phases of methodical work:

```
AFTER (2026)
════════════
┣ TypeScript with strict mode
┣ WXT + Vite build system
┣ Modern ES2022+ syntax
┣ 100+ unit tests (98% coverage)
┣ Playwright E2E tests
┣ GitHub Actions CI pipeline
┗ Manifest V3 compliant
```

It got approved on the Chrome Web Store.

This is my first public production software, the first thing I've built that strangers can install, and the first codebase I'm proud to hand off to a community.

## What This Means

Before AI tools, I could use, configure, and troubleshoot software. Building it was someone else's job.

Now I've shipped a Chrome extension with 98% test coverage, comprehensive documentation, and Web Store compliance. I didn't know that was something to aim for. I still needed the push, the GSD methodology to stay organized, and my own judgment about what mattered. But AI let me operate at a level of technical sophistication I couldn't reach alone.

This blog post, and the system I use to publish it (my own CMS), are also AI-assisted.

---

## Try QuickTab

If you're a Zendesk agent drowning in tabs, QuickTab might help.

- [**Install from Chrome Web Store**](https://chromewebstore.google.com/detail/quicktab/nmdffjdpeginhmabpeikjimggmnoojjp)
- [**View source on GitHub**](https://github.com/justcarlson/QuickTab)

## Special Thanks

[Zach Vivier](https://github.com/zachvier) — for the MVP that proved this was possible, and for pushing me to ship.
