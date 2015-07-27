---
layout: post
title: "Scala Slick 3: How To Start, An Opinionated Guide"
date: 2015-07-26 16:42:30 -0700
comments: true
categories:
- Scala
- Slick
---

> Slick is a modern database query and access library for Scala. It allows you to work with stored data almost as if you were using Scala collections while at the same time giving you full control over when a database access happens and which data is transferred.

[Slick](http://slick.typesafe.com) 3.0.0 became available a few months ago, but I’ve started a project earlier using 3.0.0-RC1. Now the project is released in production and everything seems to be working really well. In this post I want to introduce you to some of the Slick concepts and describe some gotchas and best practices that I have discovered.

<!-- more -->

## Intro

If you haven’t seen Slick 3 in action a little example from docs for you:

``` scala
val q3 = for {
  c <- coffees if c.price < 9.0
  s <- c.supplier
} yield (c.name, s.name)
// Equivalent SQL code:
// select c.COF_NAME, s.SUP_NAME from COFFEES c, SUPPLIERS s where c.PRICE < 9.0 and s.SUP_ID = c.SUP_ID
```

Slick uses Functional Relational Mapping (FRM) which is obviously more suitable for functional programming than Object-relational mapping (ORM). So you have an impression that you work with Scala collections, but really code is translated to SQL. [More about that](http://slick.typesafe.com/doc/3.0.0/introduction.html) if you’re interested.

## Reactive streams, Futures, non-blocking calls and making sense of it all

About an year ago we were walking with [Arthur Gonigberg](https://twitter.com/agonigberg) after a Scala meetup and discussing HTTP Scala frameworks. I’m a big fan of Spray and Arthur worked with Scalatra a lot. When I said that Spray is an asynchronous and non-blocking library, he asked about the database driver we use. It’s a really good question, because to be honest, an year ago I didn’t know any non-blocking database driver for Scala, except may be Reactive Mongo. But we didn’t use it.

Arthur’s point was: why do you care about non-blocking behaviour in your HTTP/API level if your database still blocks? And that’s true… at least partially. You still can do tricks with Futures and `blocking {}` stuff, but it’s a bit different.

Finally, our dreams may come true. Slick 3 was built on [Reactive Streams](http://www.reactive-streams.org) implemented in Akka - tool that can provide asynchronous  and non-blocking streaming. But it’s important to know that you still use normal blocking database drivers, so the whole *asynchronicity* happens on the level higher. I’m not sure how I feel about that, but practically I don’t see any difference. I believe that the end goal for Slick is to use / implement non-blocking drivers though.

People often ask how to work with different queries in Slick 3 and what error handling mechanism they should use. Answer is simple, since Slick is an asynchronous library - use Futures. In my opinion, if you have a model type M, you can only have 3 result types: Future[M], Future[Option[M]] and Future[Seq[M]] (and Future[Unit], of course). If you need to have something different from Future - it’s probably worth to take a look at Slick 2.x again.

Also, Future makes perfect sense for error handling. It’s a monad, so you can use default Scala tools for working with monads as well as callbacks.

## Setup

Setup a project with required dependencies and configuration is a non-trivial step already. [Documentation](http://slick.typesafe.com/doc/3.0.0/gettingstarted.html#quick-introduction) mostly uses H2 Database in examples, but real setup for MySQL or Postgres is a bit different.

So, my example for Postgres 9.4.

application.conf:

```
database {
  dataSourceClass = org.postgresql.ds.PGSimpleDataSource
  properties = {
    databaseName = “some_db”
    user = “local”
    password = “local”
  }
  numThreads = 10
}
```

or using JDBC url

```
database {
  dataSourceClass = org.postgresql.ds.PGSimpleDataSource
  properties = {
    url = “jdbc:postgresql://some_url/some_db”
    user = “local”
    password = “local”
  }
  numThreads = 10
}
```

build.sbt:

``` scala
libraryDependencies ++= Seq(
  “com.typesafe.slick” %% “slick” % “3.0.0”,
  “com.zaxxer” % “HikariCP-java6” % “2.3.2”,
  “org.postgresql” % “postgresql” % “9.4-1201-jdbc41”,
  // …
)
```

## Model

First of all, we need to create a Database object to run our queries and generate schema. It’s very simple to do:

``` scala
val db = Database.forConfig(“database”)
```

Where “database” refers to the config block from our application.conf file.

Now let’s create a model representing some Account and containing two fields - id and name.

``` scala
import slick.driver.PostgresDriver.api._
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

case class Account(id: Long, name: Long)

class Accounts(tag: Tag) extends Table[Account](tag, “ACCOUNTS”) {
  def id = column[Long](“ID”, O.PrimaryKey, O.AutoInc)
  def name = column[String](“NAME”)
  def * = (id, name) <> (Account.tupled, Account.unapply)
}

object AccountsDAO extends TableQuery(new Accounts(_)) {
  def findById(id: Long): Future[Option[Account]] = {
    db.run(this.filter(_.id === id).result).map(_.headOption)
  }

  def create(account: Account): Future[Account] = {
    db.run(this returning this.map(_.id) into ((acc, id) => acc.copy(id = id)) += account)
  }

  def deleteById(id: Long): Future[Int] = {
    db.run(this.filter(_.id === id).delete)
  }
}
```

A few things you might notice:

We use *Account* case class to represent a model. It is possible to use regular Scala class, but case classes have too many benefits to avoid them.

 *AccountsDAO* can be initialized differently, as a variable:
```
val AccountsDAO = TableQuery[Accounts]
```
But I think an object is more useful. For example, you can add your custom methods to a DAO and there will be no difference between YourDAO.SlickCall and YourDAO.CustomCall. And in case of a variable you need to create your methods somewhere else.

Queries in Slick are lazy. It means that they are not executed unless we explicitly tell database to do so. For example:

``` scala
AccountsDAO.filter(_.id === id) // 1
```

doesn’t return any results, but some sort of a pointer to a query, so you can easily combine it with different methods.

``` scala
AccountsDAO.filter(_.id === id).result // 2
```

doesn’t return any results, despite of its name.  But it returns a representation of a query. In this case we can execute this single query later or collect a sequence of queries and execute them all at once. Finally:

``` scala
db.run(this.filter(_.id === id).result).map(_.headOption) // 3
```
returns Future[Option[Account]] (map is just a way to convert a list to an item, since we know that id is unique).

My rule of thumb is to use #1 and sometimes #2 queries for private methods you can combine together and #3 for a public interface.

*create* method looks complicated. Why is that? We have a simple case class as a model object, so we need to specify all the fields. From the other side, *ID* is a field with auto-increment, so we can’t know the value of the *ID* field before we save the object. Solution is a bit tricky - you can specify any *ID* you want (I usually go with *0*) and then use method *returning* to get an auto-generated ID back. But because case classes are immutable, we have to copy our class. Oh, please show me the better solution :)

One of our imports (slick.driver.PostgresDriver.api.\_) contains all necessary operators and methods. It seems to me, that the interfaces of all slick.driver.*.api._ methods are similar and you can replace Postgres driver with MySQL driver without changing your database schema or queries. But to be honest I haven’t tried that :-/

## Tests

There is nothing special about testing Slick queries, but I want to mention something useful for tests - database schema generation.
Imagine you have your SomeDAO1 and SomeDAO2. Every time you run a test you want to have a clean state in your database and recreate all tables. Slick allows you to do that. Every DAO has a method called *schema* and you can combine multiple DAOs to get a schema that contains all the tables you need. Syntax is simple:

``` scala
def schema = SomeDAO1.schema ++ SomeDAO2.schema
```

Now you have access to *create* and *drop* statements:

``` scala
schema.drop.statements
schema.create.statements
```

But there is a little issue with that. If any of your statement fails the whole schema generation process fails too, **silently** (https://github.com/slick/slick/issues/93). Solution that I use:

``` scala
def recreateSchema(database: Database) {
  database.withSession { session =>
    for(s <- schema.drop.statements ++ schema.create.statements) {
      try {
        session.withPreparedStatement(s)(_.execute)
      } catch {
        case e: Throwable =>
      }
    }
  }
}
```

So, if some table doesn’t exist when you call *drop*, Slick won’t stop the schema regeneration.

## Summary

I hope this little guide will help you to start with Slick 3, really great Scala library to work with almost every relational database. I've tried to make it really concise and highlight the most unclear parts. Happy coding!

