---
layout: post
title: "Tutorial: how to test web applications"
date: 2014-01-18 20:52:26 -0800
comments: true
published: false
categories:
- Testing
---


What is the best start of the day? "Coffee!", you may say. "Reddit" is also nice answer.

For me the best start of the day is to see Jenkins main screen without failed jobs. Yes, I'm really passionate about testing and [CI](http://en.wikipedia.org/wiki/Continuous_integration). Today I want to talk with you how to test web applications.

I'm going to describe a few different types of the tests and then give some advices how to write, run and maintain them properly.

<!-- more -->

## Unit testing

Usually the simplest way to test something is to write unit test. Unit testing follows the "black-box" testing principle - you have some function/class/module/library A, input value X and output value Y. You need to write a code snippet that takes A, passes X to it and assumes Y as a result. If it's really Y - test succeed, if not - failed. Pretty simple, huh?

### Example1.java
``` java
class MyLibrary {
    private String _str = "";

    public void setString(String str) {
        _str = str;
    }

    public String getString() {
        return _str;
    }
}

//...

class SimpleTest {
    public void testXY() {
        MyLibrary library = new MyLibrary();
        library.setString("Hey!")

        assertEquals("Hey!", library.getString());
    }
}
```

### Strict
### + Internal systems (database, cache, queue, ...)
### JavaScript (browser)

## Integration testing

## Functional testing

## Load testing

## Continuous Integration