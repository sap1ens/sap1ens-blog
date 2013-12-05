---
layout: post
title: "Start with Akka: Let's write a scraper"
date: 2013-12-03 18:45:44 -0800
comments: true
categories:
- Scala
- Akka
---

Since my first meeting with Scala I always think that this language was designed to work in a concurrent environment. I wasn't familiar with actors for a long time, but a few months ago I got a task to write a website scraper. It's a typical story, there are a lot of nice solutions, but I felt it's a right time to try Akka in action. This article is the result of my work. I don't want to describe the basic things, so you should be familiar with the main Akka concepts: actors and messages.

Here is the GitHub repo: [https://github.com/sap1ens/craigslist-scraper](https://github.com/sap1ens/craigslist-scraper).

## The Task

So, my task was to find some ads on Craigslist website, extract data from these ads and save all results to a XLS file. Also, I had a list of cities in US and Canada (472 totally). This work can be done in a few steps:

1. Generate a list of URLs for all cities.
2. Every page with city results can contain a pagination, so we should fetch all pages.
3. Then we should extract URLs of the ads and parse the data.
4. Once it's ready (all ads were fetched and parsed), we need to combine results (for grouping, sorting, etc.) and save to the file.

## Start with Activator

[Typesafe Activator](http://typesafe.com/activator) is a beautiful tool to start Typesafe stack projects. It's [very easy](http://typesafe.com/platform/getstarted) to install.

So, I've started project with Activator (just chose Scala + Akka template) and I've got a ready-to-go application with Sbt, Scala, Akka and ability to run the application with another beautiful tool - [Typesafe Console](http://typesafe.com/platform/runtime/console).

## Keep your stuff in Config

Also, I put all my configuration stuff into the [Typesafe Config](https://github.com/typesafehub/config) file (I've chose JSON format).
There are a list of cities/countries, Craigslist search query and some settings related to saving.

## ActorSystem

### Scraper.scala
``` scala
object Scraper extends App {

    val config = ConfigFactory.load()
    val system = ActorSystem("craigslist-scraper-system")

    val profiles = for {
        profile: ConfigObject <- config.getObjectList("profiles").asScala
    } yield Profile(
        profile.get("country").unwrapped().toString,
        profile.get("pattern").unwrapped().toString,
        profile.get("cities").unwrapped().asInstanceOf[java.util.ArrayList[String]].toList
    )

    val searchString = config.getString("search")
    val resultsFolder = config.getString("results.folder")
    val resultsMode = config.getString("results.mode")

    val collectorService = system.actorOf(Props(new CollectorService(
        profiles.toList,
        searchString,
        resultsFolder,
        resultsMode)
    ), "CollectorService")

    collectorService ! StartScraper
}
```

Here I've took some config data, created ActorSystem and root actor named **CollectorService**. The app starts with sending **StartScraper** message to the root actor.

## Actors

### CollectorService.scala
``` scala
case class Profile(country: String, pattern: String, cities: List[String])

object CollectorService {
    import PageParser._

    case object StartScraper
    case object SaveResults
    case class PagesResults(results: List[PageResult])
    case class AddListUrl(url: String)
    case class RemoveListUrl(url: String)
}

class CollectorService(profiles: List[Profile], search: String, resultsFolder: String, resultsMode: String) extends Actor with ActorLogging with CollectionImplicits {

    import CollectorService._
    import ListParser._
    import PageParser._

    val lists = context.actorOf(Props(new ListParser(self)).withRouter(SmallestMailboxRouter(5)), name = "AdvertisementList")

    var pageResults = List[PageResult]()
    var listUrls = List[String]()

    def receive = {
        case StartScraper => {
            val searchEncoded = URLEncoder.encode(search, "UTF-8")

            for(profile <- profiles; city <- profile.cities) {
                self ! AddListUrl(createCityUrl(profile.pattern, searchEncoded, city))
            }
        }
        case AddListUrl(url) => {
            listUrls = url :: listUrls

            lists ! StartListParser(url)
        }
        case RemoveListUrl(url) => {
            listUrls = listUrls.copyWithout(url)

            if(listUrls.isEmpty) self ! SaveResults
        }
        case PagesResults(results) => {
            pageResults = results ::: pageResults
        }
        case SaveResults => {
            log.info(s"Total results: ${pageResults.size}")

            ExcelFileWriter.write(pageResults, resultsFolder, resultsMode)

            context.system.shutdown()
        }
    }

    def createCityUrl(pattern: String, search: String, city: String) = {
        pattern
            .replace("{search}", search)
            .replace("{city}", city)
    }
}
```

**CollectorService** is the root actor, it coordinates all work.

It contains variable (or *value*, to be correct) named *lists*, which holds a pointer to the next level of hierarchy - **ListParser** actors. Constructor of the **ListParser** accepts one element, **CollectorService**. Also, it uses routing to balance requests between 5 actors, based on the actor mailbox capacity ([SmallestMailboxRouter](http://doc.akka.io/docs/akka/2.2.3/scala/routing.html)).

``` scala
val lists = context.actorOf(Props(new ListParser(self)).withRouter(SmallestMailboxRouter(5)), name = "AdvertisementList")
```

**CollectorService** also contains two variables: *pageResults* and *listUrls*. First one is the storage for final ads results, second one holds URLs to be fetched.

**CollectorService** starts with **StartScraper** message, it sends all generated URLs to itself in **AddListUrl** message. Probably you think that sending messages to itself is a strange practice, but I don't agree :) It's a good pattern to decouple and reuse logic and you'll see it.

The next step is to start fetching these URLs. **CollectorService** delegates this job to the **ListParser** actor and you can see here the second pattern: every actor should have its own task.

So, sending **AddListUrl** message adds URL to the *listUrls* variable as well as sends the **StartListParser** message to the **ListParser** actor.

**RemoveListUrl** message removes specified URL from the *listUrls* and if it's empty, we think that job is done and it should persist results (so it sends **SaveResults** to itself).

**PagesResults** message adds an extracted page data to the *pageResults* variable. We'll use it later, during saving process.

### ListParser.scala
``` scala
object ListParser {
    import PageParser._

    case class StartListParser(listUrl: String)
    case class ListResult(listUrl: String, pageUrls: List[String], nextPage: Option[String] = None)
    case class AddPageUrl(listUrl: String, url: String)
    case class RemovePageUrl(listUrl: String, url: String)
    case class SavePageResult(listUrl: String, result: Option[PageResult])
}

class ListParser(collectorService: ActorRef) extends Actor with ActorLogging with CollectionImplicits with ParserUtil with ParserImplicits {

    import ListParser._
    import PageParser._
    import CollectorService._

    val pages = context.actorOf(Props(new PageParser(self)).withRouter(SmallestMailboxRouter(10)), name = "Advertisement")

    var pageUrls = Map[String, List[String]]()
    var pageResults = Map[String, List[Option[PageResult]]]()

    def receive = {
        case StartListParser(listUrl) => {
            val future = parseAdvertisementList(listUrl)

            future onFailure {
                case e: Exception => {
                    log.warning(s"Can't process $listUrl, cause: ${e.getMessage}")
                    collectorService ! RemoveListUrl(listUrl)
                }
            }

            future pipeTo self
        }
        case AddPageUrl(listUrl, url) => {
            pageUrls = pageUrls.updatedWith(listUrl, List.empty) {url :: _}

            pages ! StartPageParser(listUrl, url)
        }
        case RemovePageUrl(listUrl, url) => {
            pageUrls = pageUrls.updatedWith(listUrl, List.empty) { urls =>
                val updatedUrls = urls.copyWithout(url)

                if(updatedUrls.isEmpty) {
                    pageResults.get(listUrl) map { results =>
                        collectorService ! PagesResults(results.flatten.toList)
                        collectorService ! RemoveListUrl(listUrl)
                    }
                }

                updatedUrls
            }
        }
        case SavePageResult(listUrl, result) => {
            pageResults = pageResults.updatedWith(listUrl, List.empty) {result :: _}
        }
        case ListResult(listUrl, urls, Some(nextPage)) => {
            collectorService ! AddListUrl(nextPage)

            self ! ListResult(listUrl, urls, None)
        }
        case ListResult(listUrl, urls, None) => {
            log.debug(s"${urls.size} pages were extracted")

            if(urls.isEmpty) collectorService ! RemoveListUrl(listUrl)

            urls foreach { url =>
                self ! AddPageUrl(listUrl, url)
            }
        }
    }

    def parseAdvertisementList(listUrl: String): Future[ListResult] = Future {
        // skip
    }
}
```
As you can see, the **ListParser** also contains few variables: *pages*, *pageUrls* and *pageResults*. *pages* is similar to *lists* from **CollectorService**: it holds next level actors - **PageParser** and the same router, SmallestMailboxRouter.

*pageUrls* and *pageResults* help to keep intermediate results. They are pretty similar to the *listUrls* and *pageResults* from **CollectorService**, except they are maps, where key is *listUrl*.

**ListParser** starts with the **StartListParser** message. It sends URL to *parseAdvertisementList* method (which I want to skip, you can find it in the GitHub repo though). As a result, it receives a Future with the **ListResult** case class. This class contains a list of page-level URLs and optionally an URL to the next page of this city results.
``` scala
future pipeTo self
```
This line sends the result of the Future to actor itself. There are two possible ways after.

1.  If there is a next page in the message, it goes to this case:
   ```case ListResult(listUrl, urls, Some(nextPage))```
   It sends the **AddListUrl** message to the **CollectorService**, as well as the **ListResult** message without next page to actor itself.
2.  If there is no next page (or it's a message from 1), it goes to another case
   ```case ListResult(listUrl, urls, None)```

Second *ListResult* case checks a list of URLs. If it's an empty, **RemoveListUrl** will be sent to the **CollectorService**. If it's not empty, actor sends the **AddPageUrl** message for every URL to itself.

In **AddPageUrl** case, actor saves specified URL to the *pageUrls* and sends the **StartPageParser** message to the **PageParser**, next actor in hierarchy.

In **RemovePageUrl** case it removes specified url from the *pageUrls* and if it's empty, it sends the **PagesResults** as well as the **RemoveListUrl** to the **CollectorService**.

Also **ListParser** contains **SavePageResult** case, which just saves sent data to the *pageResults*.

### PageParser.scala
``` scala
object PageParser {
    case class StartPageParser(listUrl: String, pageUrl: String)
    case class PageResult(
        url: String,
        title: String,
        description: String,
        date: Option[(String, String)] = None,
        email: Option[String] = None,
        phone: Option[String] = None
    )
}

class PageParser(listParser: ActorRef) extends Actor with ActorLogging with ParserUtil with ParserImplicits {

    import PageParser._
    import ListParser._

    def receive = {
        case StartPageParser(listUrl, pageUrl) => {
            val future = parseAdvertisement(pageUrl).mapTo[Option[PageResult]]

            future onComplete {
                case Success(result) => {
                    listParser ! SavePageResult(listUrl, result)
                    listParser ! RemovePageUrl(listUrl, pageUrl)
                }
                case Failure(e) => {
                    log.warning(s"Can't process pageUrl, cause: ${e.getMessage}")
                    listParser ! RemovePageUrl(listUrl, pageUrl)
                }
            }
        }
    }

    def parseAdvertisement(url: String): Future[Option[PageResult]] = Future {
        // skip
    }
}
```
**PageParser** actor is pretty straightforward. It uses *parseAdvertisement* method to get a Future with extracted data and then sends **SavePageResult** and **RemovePageUrl** messages to the parent actor (**ListParser**).

### Important things

1. Error handling is a very important thing. That's why every Future has *onFailure* block, which sends clean-up messages to parent actors.
2. You can find **ListParser** and **PageParser** similar: they both have 2 same types of inner variables, same actions (add item to the process queue, remove item from the processing queue, save results). It means we can extend actors hierarchy multiple times, but it's a good practice to have different actors for every level of hierarchy, because we can set up different [supervisors](http://doc.akka.io/docs/akka/2.2.3/scala/fault-tolerance.html). So, it's worth thinking how to reuse this behaviour.

## Summary
I like the results: it takes about 4 minutes on my MBP to find, fetch, parse and save about 10k ads.

## Bonus: Immutable data structures 
May be you didn't notice, but all inner variables inside the actors are immutable. It's not a requirement because actor can process only one message from mailbox at the one period of time, so it won't mess with any mutable data. I used immutable data structures just as an exercise and also it's a good culture in Scala. That's why we have these implicits to work with List and Map.
``` scala
trait CollectionImplicits {
    implicit class ListExtensions[K](val list: List[K]) {
        def copyWithout(item: K) = {
            val (left, right) = list span (_ != item)
            left ::: right.drop(1)
        }
    }

    implicit class MapExtensions[K, V](val map: Map[K, V]) {
        def updatedWith(key: K, default: V)(f: V => V) = {
            map.updated(key, f(map.getOrElse(key, default)))
        }
    }
}
```

## Further Reading

I can recommend perfect book [Akka Concurrency](http://www.artima.com/shop/akka_concurrency) by Derek Wyatt to continue learning about Akka.
