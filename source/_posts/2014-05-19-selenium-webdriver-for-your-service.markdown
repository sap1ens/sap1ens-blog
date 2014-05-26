---
layout: post
title: "Selenium Webdriver for your service"
date: 2014-05-19 21:19:20 -0700
comments: true
categories:
- Selenium
---

During my career I constantly see the battle between people who own websites, web services and even search engines with people who try to break a system, find backdoors or simply automate routine things with custom methods. 
I don't mean just hackers, there are a lot of interesting specialities like black SEO guys, bot/scraper/crawler writers, etc.  

Today I'll talk about a need to emulate user's behaviour in a web browser. Usually you could find such fake users by analyzing logs, HTTP headers or with more sophisticated tools, like checking JavaScript stuff. Web crawler probably doesn't support JavaScript you might think. Well, they didn't, but things changed. 

Selenium Webdriver is a real masterpiece. 

In the first place, it's very easy to start with this library - http://docs.seleniumhq.org/docs/03_webdriver.jsp, you can find implementations for all major languages and browsers. But Google Chrome support is especially good. Why?

Selenium Webdriver authors not just created some tool for testing and automation, but "forced" Google (actually Chromium) to create and support (!) special driver. So it communicates with Google Chrome via protocol which is a native thing for this browser. You have access to everything, including, for example, secure cookies! 

It's almost impossible detect bot/crawler written with Selenium Webdriver and Chrome. HTTP headers, JavaScript, cookies - everything will just work. 

// ...


Before I said that it's almost impossible to detect Selenium Webdriver and Chrome when they used. Actually, I see two ways to protect yourself:
1) Create your website/web app with Flash >_<. It's ugly, but it should work. I'm sure it's possible to find a way to interact with Flash as well (with JavaScript calls or using other tools), but it won't be a native browser way to do it - so, probably, you can detect it.
2) Any heuristic methods. For example, Google AdWords/AdSense system is able to detect bots by tracking mouse moves, scrolls, timings, etc. I believe it's very complicated and very expensive technology, but it exists. 

