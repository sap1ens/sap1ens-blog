---
layout: post
title: "Bash scripting best practices "
date: 2017-07-01 22:13:18 -0700
comments: true
categories: 
- bash
---

I was always afraid of writing shell scripts. Bash seemed to be a programming language that doesn't allow a slightest mistake... Extra space here and there and everything blows up.

Like with every skill, persistence and repetition help. I've started writing more and more bash scripts a few years ago. But it's important to remember one simple rule - when things become really complex you need to switch to Python/Ruby/scripting language of your choice. Please do!

Anyway, today I want to share some of the very practical conventions, best practices and recommendations I gathered over these years. 

It's not an introduction to bash, you should have some background already (ideally some war stories as well).

Also, I'm not an expert! It's ok to not agree with me. And I'm pretty sure almost everything I mention can be improved. So please help me and leave some feedback ;-)

<!-- more -->

## Start from the top

So, first few lines in the bash script are actually the most important lines! This is how I typically start:

```bash
#!/usr/bin/env bash

set -o errexit
set -o pipefail
```

First line (shebang) tells which interpreter to use. Try to avoid things like `/bin/sh` because they're not portable. More explanations can be found [here](https://stackoverflow.com/questions/10376206/what-is-the-preferred-bash-shebang). 
 
Next, you **MUST ALWAYS INCLUDE** `set -o errexit`!!! I don't know how to attract your attention more here. It's very important to stop the script when an error occurs. Otherwise things can go really catastrophic. Yes, by default bash doesn't stop when an error happens!

You'd also like to use `set -o pipefail`, because if you don't, expressions like `error here | true` will always succeed! It's probably not what you want. 

A few more instructions you might use: 

- `set -o nounset`: detects uninitialised variables in your script (and exits with an error). Generally very useful to have, but it will also reject environment variables, which is a pretty common  thing to use, so I don't include this option by default
- `set -o xtrace`: prints every expression before executing it. Really handy for debugging / build scripts. I usually set it like this: `[[ "${DEBUG}" == 'true' ]] && set -o xtrace`, so it only works when explicitly requested

One more things to notice: it's common to use those instructions in a short form: `set -e`, `set -u`, etc. I prefer the longer format, because it's more readable and less cryptic, especially for people without a lot of bash experience. 

## Variables

How do you refer to a variable in your script? Probably something like `$variable`? 

This is the most reliable notation: `"${variable}"`. 

Quotes help to prevent issues when variable contains spaces (for example, in filenames).  

Curly braces are not needed in this particular example, but help you with more complex situations like:

- string interpolation: `"${variable}.yml"`
- default/fallback values: `"${variable:-something_else}"` 
- string replacement: `"${variable//from/to}"`.

More examples can be found [here](https://ss64.com/bash/syntax-expand.html) under `Shell Parameter Expansion` section.

## Constants

It's always helpful to separate variables that should be mutable from immutable ones. `readonly` instruction can help you with that, practically making constants from variables.

It's very simple to use:

```bash
readonly something='immutable value'
```

Fun fact: there is no [normal] way to unset a readonly variable in bash! Make sure to remember this. 

## Conditionals

Should we use single or double square brackets in conditionals? What's the difference between `if [ "${var}" -le 0 ]` and `if [[ "${var}" -le 0 ]]`? 

They're mostly equal, but double square brackets usually provide cleaner syntax and a few more additional features. Compare this:

```bash
[ -f "$file1" -a \( -d "$dir1" -o -d "$dir2" \) ]
```

and this:

```bash
[[ -f $file1 && ( -d $dir1 || -d $dir2 ) ]]
```

With double square brackets you don't need to escape parenthesis and unquoted variables work just fine even if they contain spaces (meaning no word splitting or glob expansion).

Double square brackets are less portable though: `[` is supported by all POSIX shells and `[[` only works in bash 2.x+, zsh and some other shells. 

Usually you should use double square brackets unless you really know what you're doing.

You can find great detailed explanation [here](http://mywiki.wooledge.org/BashFAQ/031).

## Functions

Now let's look at some functions. Here's what I think is a good example of a function:

```bash
_http_code () {
  local url="$1"
  curl --silent --head \
       --output /dev/null \
       --write-out "%{http_code}\n" \
       "$url"
}
```

What I like about this function:

- `function_name ()` is more concise than `function function_name`
- function name has an underscore as a prefix. It seems like a good idea to always have a special naming convention for your bash functions to avoid any potential clashes with built-in operators or functions you might include from other files
- in bash functions arguments are accessible using index-based variables, first argument is `$1`, second is `$2`, etc. Of course you can refer to them like that, but when you have 5-6 index-based variables in a 20-30 lines function it can become really hard to keep the mapping in mind. So, you should always name them to make things very explicit. It's also applicable to your "main" function, variables like `$1`, `$2`, etc. would be strings passed from CLI and it's also a great idea to name them
- `local` operator restricts the scope of variables, protecting us from leaking those variables to a global namespace. If you only need this variable inside a function - make it `local`!

## Includes

In bash you can include (actually execute) external script using `source FILENAME` command. I'm still not sure how I feel about this:

- It's nice to be able to create a file with a set of utility functions that's shared across various scripts. I generally support DRY principle. It also can be handy for defining configuration parameters in one concise file and then including that file to an actual script with the business logic
- But at the same time I'm not very happy with the idea of including and executing a file with, potentially, unknown content. Yes, you can't always control that and bash doesn't give any mechanisms to protect you!

Anyway, if you decide to use `source` for includes, here's the right way:

```bash
readonly BINPATH="$(dirname "$0")"
# ...
source "${BINPATH}/../shared/some_functions"
```

You make your life easier by always using consistent path for includes, because `BINPATH` variable will always be resolved to the actual script location, not the current location.

## Linting

Surprise, bash has a linter too: [shellcheck.net](https://www.shellcheck.net). 

ShellCheck has more than 200 checks and it  integrates with your test frameworks and CLI tools. It doesn't necessarily follow all the conventions I mentioned here and it definitely has more rules than I can cover. 

Try it!

## Summary

So, I think it's possible to write readable and reliable bash scripts. It's important to remember when not to - some tools should be implemented with more advanced scripting languages. It doesn't make any sense to try to squeeze out as much as you can from bash with very exotic syntax or shell commands. You still want your scripts to be simple and straightforward.
