---
layout: post
title: "How to build CLI in Node.js"
date: 2017-06-07 21:02:07 -0700
comments: true
categories:
- Node
---

CLI (Command-line interface) is a very common way to run a program in a terminal. As a software engineer you use different CLIs every day - git, Docker, npm, etc.

Today I want to share my experience building CLIs using Node.js and a few helpful packages.

<!-- more -->

## Goal

I'm going to only focus on npm in this article, simply because I don't have enough experience with other package managers for Node.js and apparently npm is still the most popular choice.

So, our goal is to have something like this in the end:

```
npm install -g awesometool
awesometool run --fast
```

## npm setup

First of all, let's make sure we have a proper npm configuration and folder structure!

**bin/awesometool.js**:

```js
#!/usr/bin/env node

require("../lib/awesometool")
```

Snippet above should look really straightforward - we simply require the main file (or entry point) of the app, in our case `./lib/awesometool.js`.

**package.json**:

```js
{
  "name": "awesometool",
  "version": "0.1.2",
  ...
  "main": "./lib/awesometool.js",
  "bin": {
    "awesometool": "bin/awesometool.js"
  },
  ...
}
```

The most important things in the package.json are:

- `name`: this is what we use for naming (in npm ecosystem)
- `version`: every time you change your program you'll have to update the version and publish it
- `main`: simply an entry point
- `bin.awesometool`: should point to our `bin/awesometool.js` file. Also, this name is going to be used after the installation as a terminal command for our program

## Designing the CLI

Now we have the basic setup and it's time to think about the CLI itself. Usually every Command-line interface description consists from a few sections:

- usage information
- a list of available commands
- a list of available options

So, you need to decide how to structure the CLI - what commands do you need, what options are available, what are the safe defaults, etc.

A few resources that can help with that:

- https://trevorsullivan.net/2016/07/11/designing-command-line-tools/
- https://softwareengineering.stackexchange.com/questions/307467/what-are-good-habits-for-designing-command-line-arguments
- http://pubs.opengroup.org/onlinepubs/009695399/basedefs/xbd_chap12.html#tag_12_01c

Also I encourage to get some inspiration from well-known tools like Docker or Heroku CLI.

After you realize what kind of commands and options you would need, instead of implementing command-line arguments parsing from scratch (yay) and solving a bunch of terminal rendering issues we're going to use [commander](https://www.npmjs.com/package/commander).

[commander](https://www.npmjs.com/package/commander) is an awesome tool to help us define CLI commands, options and related actions. Here's an example:

```js
import commander from 'commander'

commander
    .option('--fast', 'running things even faster')

commander
    .command('run')
    .description('Run something')
    .action(() => {
        console.log('Working!')
        console.log(commander.dryRun)
    })

commander.parse(process.argv)

if (commander.rawArgs.length <= 2) {
    commander.help()
}
```

I like how concise and expressive it is. We define one command with an action plus an option that's available for all commands.

This is how it looks in the terminal:

```
  Usage: awesometool [options] [command]

  Commands:

    run   Run something

  Options:

    -h, --help  output usage information
    --fast  running things even faster
```

## Bonus: inquiry session flow

If you build a complex CLI you might need to ask user a few questions before proceeding. To make things easier for the end user it's usually a good idea to introduce validation, default values and some other helpers. Also, sometimes user needs to choose from a set of predefined values instead of entering a custom one. All these things are handled by [inquirer](https://www.npmjs.com/package/inquirer)!

Let me show you the wonderful [pizza](https://github.com/SBoudrias/Inquirer.js/blob/master/examples/pizza.js) example they have:

```js
/**
 * Pizza delivery prompt example
 * run example by writing `node pizza.js` in your console
 */

'use strict';
var inquirer = require('..');

console.log('Hi, welcome to Node Pizza');

var questions = [
  {
    type: 'confirm',
    name: 'toBeDelivered',
    message: 'Is this for delivery?',
    default: false
  },
  {
    type: 'input',
    name: 'phone',
    message: 'What\'s your phone number?',
    validate: function (value) {
      var pass = value.match(/^([01]{1})?[-.\s]?\(?(\d{3})\)?[-.\s]?(\d{3})[-.\s]?(\d{4})\s?((?:#|ext\.?\s?|x\.?\s?){1}(?:\d+)?)?$/i);
      if (pass) {
        return true;
      }

      return 'Please enter a valid phone number';
    }
  },
  {
    type: 'list',
    name: 'size',
    message: 'What size do you need?',
    choices: ['Large', 'Medium', 'Small'],
    filter: function (val) {
      return val.toLowerCase();
    }
  },
  {
    type: 'input',
    name: 'quantity',
    message: 'How many do you need?',
    validate: function (value) {
      var valid = !isNaN(parseFloat(value));
      return valid || 'Please enter a number';
    },
    filter: Number
  },
  {
    type: 'expand',
    name: 'toppings',
    message: 'What about the toppings?',
    choices: [
      {
        key: 'p',
        name: 'Pepperoni and cheese',
        value: 'PepperoniCheese'
      },
      {
        key: 'a',
        name: 'All dressed',
        value: 'alldressed'
      },
      {
        key: 'w',
        name: 'Hawaiian',
        value: 'hawaiian'
      }
    ]
  },
  {
    type: 'rawlist',
    name: 'beverage',
    message: 'You also get a free 2L beverage',
    choices: ['Pepsi', '7up', 'Coke']
  },
  {
    type: 'input',
    name: 'comments',
    message: 'Any comments on your purchase experience?',
    default: 'Nope, all good!'
  },
  {
    type: 'list',
    name: 'prize',
    message: 'For leaving a comment, you get a freebie',
    choices: ['cake', 'fries'],
    when: function (answers) {
      return answers.comments !== 'Nope, all good!';
    }
  }
];

inquirer.prompt(questions).then(function (answers) {
  console.log('\nOrder receipt:');
  console.log(JSON.stringify(answers, null, '  '));
});
```

I like the balance between using declarative rules and writing custom logic for validation and default values.

## Bonus: colors

Yes, [colors](https://www.npmjs.com/package/colors) in your terminal! Or [colours](https://www.npmjs.com/package/colours)...

So easy to use:

```js
import colors from 'colors'

console.log('hello'.green); // outputs green text
console.log('i like cake and pies'.underline.red) // outputs red underlined text
console.log('inverse the color'.inverse); // inverses the color
console.log('OMG Rainbows!'.rainbow); // rainbow
```
