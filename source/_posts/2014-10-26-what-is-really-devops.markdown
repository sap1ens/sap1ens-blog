---
layout: post
title: "What is really DevOps?"
date: 2014-10-26 11:51:11 -0700
comments: true
categories:
- DevOps
---

DevOps, from [wikipedia](http://en.wikipedia.org/wiki/DevOps):

> DevOps (a portmanteau of "development" and "operations") is a concept dealing with, among other things: software development, operations, and services. It emphasizes communication, collaboration, and integration between software developers and information technology (IT) operations personnel. DevOps is a response to the interdependence of software development and IT operations. It aims to help an organization rapidly produce software products and services.

I think everybody in IT world knows about DevOps concept. Or at least heard about it. Somebody might hire DevOps Engineers.

But if you ask yourself - what does DevOps mean precisely? What should DevOps Engineer do during the work day? - the answer probably is clear to you only if you’re DevOps Engineer (it should be!) or if you work very closely with them. For the other world it’s some kind of leprechaun that magically solves all the problems for the team (or application). Well, that’s usually true (not the leprechaun part), but it seems to me there are no any good common standards or rules for this job.

I’d like to share my thoughts about what day-to-day activities should have every DevOps Engineer. I wrote them in a form that every developer should understand, especially if you’re interested in doing more DevOps stuff in your team.

<!-- more -->

## Two Simple Rules

So, let’s start from the two very simple rules that every DevOps  person should adopt:

- Everything should be automated
- Everything should be automated in a way that other member of the team can use it

That’s it. You can apply it to anything - running tests, accessing logs, using monitoring, doing releases, … The whole point of having a DevOps Engineer is to glue your Product/Dev/Operations/QA teams together, eliminate any unnecessary communication and manual work. As a result you should see increased speed of development and decreased number of bugs (at least human errors).

Ok, that was very high level things. Let’s go deeper.

## DevOps Activities

### Development tools support

It’s important to increase development speed as much as you can - it affects budget, happiness and even business metrics. But sometimes you have to work with really complicated applications, especially if you use service-oriented architecture.

Having the same setup for all developers can be challenging. Luckily tools like [Vagrant](https://www.vagrantup.com) can reduce the struggle. For example, [Vagrant](https://www.vagrantup.com) + [Docker](https://www.docker.com) is a really powerful combination to reproduce any complicated stack.

Also, make sure you use VCS for everything ;-)

### Continuous Integration (CI)

[Jenkins](http://jenkins-ci.org), [TeamCity](https://www.jetbrains.com/teamcity/), [Bamboo](https://www.atlassian.com/software/bamboo), [CircleCI](https://circleci.com), [Travis](https://travis-ci.org)… - all these tools have very simple, but very powerful idea: run your builds or tests automatically, triggered by events (usually commits in VCS system) or time. It allows you, as a developer, sleep well, because all your changes are tested almost in realtime.

As a DevOps Engineer it’s important to make sure developers can see results and debug any issues, but at the same time they shouldn’t deal with CI system too much - use email/chat notifications. They will like it.

### Configuration management

When a codebase is tested it’s time to deploy it. At least to a staging server. We’ll talk about deployments in the next section, but here let’s talk about environments. Usually every team has a local environment for local development, dev or staging  environment for running tests / showing demos and, of course, production environment.

So, imagine you decided to update a version for some library. Or programming language. It means you have to go and update it for every environment! And in case of local environment you should do it for every team member! That’s a nightmare!

Fortunately we have really nice tools for configuration management. Check Tools section below.

### Deployment / Continuous Delivery

Ok, codebase is ready, we also have a few environments that were configured automatically. It’s time to deploy our application!

Actually, sometimes you might think that it’s a trivial task. You can just write a small bash-script that takes the latest version from your VCS and restarts a service or something.

But it can be really complicated as well. Load balancers for rolling updates, feature flags, blue green deployments, RDBMS replicas and shards…

And again, even very complicated deployment can be automated. Check Tools section for more details.

Btw, you can combine CI and deployments! It’s called Continuous Delivery (or Continuous Deployment) and the idea behind is obvious: deploy your change right away if all tests are succeeded. That’s a huge win, you can deploy very often and you can get a feedback very fast.

### Security

When you prepare your application for production release it’s very important to understand who can access what. Things like ssh keys, VPNs, IP whitelisting should make you life easier.

### Monitoring

So, application is running and it gets some traffic. Nice!

But production environment is always different. And someday you’ll see that one part of your app works really slow. Or just behave strange. Or traffic is too high. And you can’t reproduce it locally :(

That’s why you should use monitoring. And when I say monitoring I don’t mean have [NewRelic](http://newrelic.com) integration (which is great, actually) and relax. [Measure Anything, Measure Everything](http://codeascraft.com/2011/02/15/measure-anything-measure-everything/) - that’s very good idea, especially for your future. You business folks will say thank you, you’ll see.

### Maintenance

Monitoring itself usually is not enough. First of all, when something is not working you should know it first. Notifications and alerts that wake you up at 3am on Sunday are **really** helpful.

All kinds of logs help you investigate issues and if you can afford [Splunk](http://www.splunk.com) - just buy it.

You can design some systems to have self-healing procedures. That’s not easy, but can reduce a lot of pain.

### Backup & Restore

You probably do some backups, don't you? But have you ever tried to actually use them?

Backups can give you false confidence, you should only rely on restore procedure. Make sure you have backups for database, file storage, etc. and they can be quickly used. Otherwise you're in trouble.

Hint: restore = [configuration management + ] deployment + backup data.

## Tools

[Chef](https://www.getchef.com/chef/), [Puppet](http://puppetlabs.com), [Ansible](http://www.ansible.com), [SaltStack](http://www.saltstack.com) - these are main DevOps tools and every DevOps person should be familiar with at least one of them. They all have important features like configuration management, multi-node deployments, task execution, etc.

Usually if you want to create a bash-script and put it on a remote machine one of those tools is a better solution.

Let me show you [an example](https://github.com/ansible/ansible-examples/blob/master/tomcat-standalone/roles/tomcat/tasks/main.yml) of using Ansible for Tomcat installation and configuration:

``` yaml
---
- name: Install Java 1.7
  yum: name=java-1.7.0-openjdk state=present

- name: add group "tomcat"
  group: name=tomcat

- name: add user "tomcat"
  user: name=tomcat group=tomcat home=/usr/share/tomcat
  sudo: True

- name: delete home dir for symlink of tomcat
  shell: rm -fr /usr/share/tomcat
  sudo: True

- name: Download Tomcat
  get_url: url=http://www.us.apache.org/dist/tomcat/tomcat-7/v7.0.55/bin/apache-tomcat-7.0.55.tar.gz dest=/opt/apache-tomcat-7.0.55.tar.gz

- name: Extract archive
  command: chdir=/usr/share /bin/tar xvf /opt/apache-tomcat-7.0.55.tar.gz -C /opt/ creates=/opt/apache-tomcat-7.0.55

- name: Symlink install directory
  file: src=/opt/apache-tomcat-7.0.55 path=/usr/share/tomcat state=link

- name: Change ownership of Tomcat installation
  file: path=/usr/share/tomcat/ owner=tomcat group=tomcat state=directory recurse=yes

- name: Configure Tomcat server
  template: src=server.xml dest=/usr/share/tomcat/conf/
  notify: restart tomcat

- name: Configure Tomcat users
  template: src=tomcat-users.xml dest=/usr/share/tomcat/conf/
  notify: restart tomcat

- name: Install Tomcat init script
  copy: src=tomcat-initscript.sh dest=/etc/init.d/tomcat mode=0755

- name: Start Tomcat
  service: name=tomcat state=started enabled=yes

- name: deploy iptables rules
  template: src=iptables-save dest=/etc/sysconfig/iptables
  notify: restart iptables

- name: wait for tomcat to start
  wait_for: port={% raw %}{{http_port}}{% endraw %}
```

As you can see, it’s very easy to read. Don’t be afraid. Just pick one of those tools and act (pick [Ansible](http://www.ansible.com)).

## Summary

Constantly apply Two Simple Rules and you’ll see how much time you spend on actual development instead of struggling with configuration, environments or deployments. You can’t automate development process (yet), but you should automate everything else.