---
layout: post
title: "Selenium Webdriver as a deadly weapon"
date: 2014-05-27 21:19:20 -0700
comments: true
categories:
- Scala
- Selenium
---

## Weapon

During my career I see the battle between website/web app owners and bots/scrapers/crawlers writers. I thought this battle can't be won. But about 6 months ago I joined it and I think now I have [almost] deadly weapon.

[Selenium Webdriver](http://docs.seleniumhq.org/projects/webdriver/) is my choice. 

<!-- more -->

Probably, you heard or used it before. It's the most popular tool for the functional tests (also known as end-to-end tests), and projects like [saucelabs.com](https://saucelabs.com) can make these tests very easy to implement and run.

But Selenium Webdriver is not only a testing tool - it's browser automation tool. Modern implementation with Google Chrome (actually Chromium) driver is very powerful - it communicates with Google Chrome via special protocol which is a native thing for this browser. You have access to everything - JavaScript, DOM, even secure cookies! That's why it's almost impossible to detect scraper written with Selenium Webdriver and Google Chrome - you just tell browser what to do and it works like there is a real person who is sitting in front of the browser and clicking buttons. 

## Preparations for the battle 

### Xvfb

So, you wrote a sequence of steps for scraping some website. Awesome! But what step should be next? Of course you can just run it manually on your computer, but what if you need to create some sort of service or even platform based on it? Yes, it's possible! 

[Xvfb](http://www.x.org/archive/X11R7.7/doc/man/man1/Xvfb.1.xhtml) is a virtual display server implementing the X11 protocol. Selenium Webdriver needs a display to work and it works nicely with Xvfb. Set of steps you need to do if you want to run all this stuff on your server:

- install Google Chrome application
- install Xvfb
- [download](https://sites.google.com/a/chromium.org/chromedriver/downloads) Google Chrome driver, add a path to this file to the "webdriver.chrome.driver" system property
- create Xvfb initialization script, [example for Ubuntu](https://gist.github.com/jterrace/2911875)
- run Xvfb
- set DISPLAY variable like "export DISPLAY=:99", where 99 is a number of your virtual display, I believe it can be a random number
- now you can run your application! Everything should just work, including screenshots (useful for debugging). 

### File download

There is one problem that Selenium Webdriver can't solve. Usually, when you click to a download button you see the OS modal window. Unfortunately, driver can't handle OS windows. But there is a solution for this problem - create your own file downloader and pass session information to it, like cookies and other headers. Example with Apache HttpClient and Scala:
``` scala
object FileDownloader {
    val defaultUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.131 Safari/537.36"
    val timeout = 10 // seconds

    def download(url: String, pathToSave: String, cookies: Set[Cookie], userAgent: Option[String]): Future[String] = Future { blocking {
        val fileUrl = new URL(url)

        val downloadedFile = new File(pathToSave)
        if (!downloadedFile.canWrite) downloadedFile.setWritable(true)

        val config = RequestConfig.custom()
            .setConnectTimeout(timeout * 1000)
            .setConnectionRequestTimeout(timeout * 1000)
            .setSocketTimeout(timeout * 1000)
            .setCookieSpec(CookieSpecs.BROWSER_COMPATIBILITY)
            .build()

        val client = HttpClientBuilder.create()
            .setDefaultRequestConfig(config)
            .setRedirectStrategy(new LaxRedirectStrategy())
            .setUserAgent(userAgent getOrElse defaultUserAgent)
            .build()

        val localContext = new BasicHttpContext()

        localContext.setAttribute(HttpClientContext.COOKIE_STORE, mimicCookieState(cookies))

        val request = new HttpGet(fileUrl.toURI)

        val response = client.execute(request, localContext)

        log.info(s"HTTP GET request status: ${response.getStatusLine.getStatusCode}, Downloading file: ${downloadedFile.getName}")

        FileUtils.copyInputStreamToFile(response.getEntity.getContent, downloadedFile)
        response.getEntity.getContent.close()

        downloadedFile.getCanonicalPath
    }}

    private def mimicCookieState(seleniumCookieSet: Set[Cookie]): BasicCookieStore = {
        val mimicWebDriverCookieStore = new BasicCookieStore()

        for (seleniumCookie <- seleniumCookieSet) {
            val duplicateCookie = new BasicClientCookie(seleniumCookie.getName, seleniumCookie.getValue)
            duplicateCookie.setDomain(seleniumCookie.getDomain)
            duplicateCookie.setSecure(seleniumCookie.isSecure)
            duplicateCookie.setExpiryDate(seleniumCookie.getExpiry)
            duplicateCookie.setPath(seleniumCookie.getPath)
            mimicWebDriverCookieStore.addCookie(duplicateCookie)
        }

        mimicWebDriverCookieStore
    }
}
```
It takes URL to download, path where it should save the file, set of cookies and optional user agent header. Of course you can pass and add more headers if you need. 

And it's very easy to get current cookies:
``` scala
driver.manage().getCookies.toSet
```
and user agent:
``` scala
driver.executeScript("return navigator.userAgent") match {
    case userAgent: String => Some(userAgent)
    case _ => None
}
``` 

## Defence

Before I said that it's almost impossible to detect Selenium Webdriver and Google Chrome when they used together. Actually, I see a few ways to protect yourself:

- CAPTCHA. But there are a lot of tools that can help with recognition, so it can't be really serious protection.
- Create your website/web app with Flash. It's ugly, nobody uses it except for promo sites, but it should work. I'm sure it's possible to find a way to interact with Flash as well (with JavaScript calls or using other tools), but it won't be a native browser way to do it - so, probably, you can detect it.
- Heuristic methods. For example, Google AdWords/AdSense system is able to detect bots by tracking mouse moves, scrolls, timings, etc. I believe it's very complicated and very expensive technology, but it exists. 

## Summary

As you can see, Selenium Webdriver is a very powerful tool, not only for testing, but for browser automation in general. If you need an integration with web app that doesn't have a public API, Selenium Webdriver can be a way to go. But with great power comes great responsibility...

