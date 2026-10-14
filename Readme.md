# PostgreSQL Walkthrough

In this repository I am going to work through some of the PostgreSQL documentation, not exhausively, but looking into database design and querying using two databases that hold flight data, and taxi data. I will focus on chapters two (SQL language) and three (server administration), looking at the areas that I don't remember well or haven't used. I decided to do this to refresh my memory with using PostgreSQL and also because I remember back in 2006 thinking the documentation for the project was the best documentation I had ever read, and I wonder if that still holds.

* Part [zero](Part-zero-setting-up.md) is where I create the databases, and for the taxi data perform some [QA and transformations](data/yellow_trip/Extract-Transform-Load.ipynb) to get it into a state for use in this project.
* Part [one](Part-one-chapter-five.md) is where I go through most of the fifth chapter.
* Part [two](Part-two-chapter-seven.md) is where I focus on the query types I haven't had experience with.

I will come back and look at chapters 25.3, 26, and 29 once I am up to speed with Docker and Docker Compose, to create the setup for these chapters.