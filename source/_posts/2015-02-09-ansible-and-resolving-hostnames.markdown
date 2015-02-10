---
layout: post
title: "Ansible and resolving hostnames"
date: 2015-02-09 20:13:50 -0800
comments: true
categories:
- DevOps
- Ansible
---

Recently I’ve worked on a very simple Ansible task. My goal was to start an environment, wait until it becomes available (online) and do some things after. With environment I mean a web service - imagine any language or framework you want. Let’s say you need to access some specific URL like /api/heartbeat to make sure it’s initialized properly.

Piece of cake, right?

<!-- more -->

## Attempt #1

If you take a look at the list of all Ansible modules [here](http://docs.ansible.com/list_of_all_modules.html), first of all you probably notice **wait_for**. Let’s try to use it:

```yml
--- 
 - hosts: localhost
   tasks:
     - wait_for: host=http://domain.com/api/heartbeat port=80 timeout=5
```

(I’m using small timeout here just for demo purposes.)

Result: *msg: Timeout when waiting for …*

So, **wait_for** doesn’t actually work in our case - it accepts only hostnames without additional path. Ok, skip it.

How about **uri** module? Looks promising:

```yml
--- 
 - hosts: localhost
   tasks:
     - uri: url=http://domain.com/api/heartbeat timeout=5
```

It should work, but I have a very specific use case - every environment I start can also create a new CNAME address. It requires some time to become resolvable. So, unfortunately result is *msg: Unable to resolve the host name given.*

I’ve realized that I couldn’t do it with Ansible tools.

## Attempt #2

If Ansible is powerless let’s just use old school bash. How about that:

```yml
--- 
 - hosts: localhost
   tasks:
     - shell: curl --silent --show-error --output /dev/null --retry 90 --retry-delay 10 --retry-max-time 900 http://domain.com/api/heartbeat
```

Looks like it works! Except it doesn’t :-/

If you run this playbook you see that it actually waits for the URL to be available. But there is a problem in the interval between environment becoming resolvable and environment returning HTTP reply. Curl fails in that specific moment.

Wget is better in this case, it has *retry-connrefused* flag that really helps with the issue. Unfortunately it fails with the part of resolving hostname.

## Attempt #3

I’ve decided to continue with Curl approach, but improve it as much as I can. So, finally:

```yml
--- 
 - hosts: localhost
   tasks:
     - script: scripts/wait_for.sh http://domain.com/api/heartbeat
```

where wait_for.sh:

```bash
#!/bin/sh 
 until curl --silent --output /dev/null $1; do
   echo Could not fetch, retrying...
   sleep 30
 done
```

Looks really optimistic (and simple!), but you can always cancel it.

## Conclusion

I really like the Ansible way, because you can always switch to old school bash and implement whatever you want. I’ve almost decided that this task is impossible to do with Ansible but finally did it in a different way. Don’t be afraid and experiment!
