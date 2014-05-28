---
layout: post
title: "Selenium Webdriver for your service"
date: 2014-05-19 21:19:20 -0700
comments: true
categories:
- Selenium
---

### Weapon

During my career I see the battle between website/web app owners and bots/scrapers/crawlers writers. I thought this battle can't be won. But about 6 months ago I joined this battle and I think now I have [almost] deadly weapon.

Selenium Webdriver is my weapon. 

<!-- more -->

Probably, you heard or used it before. It's the most popular tool for the functional tests (also known as end-to-end tests), and projects like saucelabs.com can make these tests very easy to implement and run.

But Selenium Webdriver is not only a testing tool - it's browser automation tool. Modern implementation with Google Chrome (actually Chromium) driver is very powerful - it communicates with Google Chrome via protocol which is a native thing for this browser. You have access to everything - JavaScript, DOM, even secure cookies! That's why it's almost impossible to detect scraper written with Selenium Webdriver and Google Chrome - you just tell browser what to do and it works like there is a real person who is sitting in front of the browser and clicking buttons. 

### Preparations for the battle 




Before I said that it's almost impossible to detect Selenium Webdriver and Chrome when they used. Actually, I see two ways to protect yourself:
1) Create your website/web app with Flash >_<. It's ugly, but it should work. I'm sure it's possible to find a way to interact with Flash as well (with JavaScript calls or using other tools), but it won't be a native browser way to do it - so, probably, you can detect it.
2) Any heuristic methods. For example, Google AdWords/AdSense system is able to detect bots by tracking mouse moves, scrolls, timings, etc. I believe it's very complicated and very expensive technology, but it exists. 

