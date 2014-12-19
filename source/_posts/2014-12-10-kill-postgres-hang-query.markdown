---
layout: post
title: "Kill Postgres Hang Query"
date: 2014-12-10 16:20:05 +0800
comments: true
categories: [database]
---

今天，在服务器上面拉了一份数据后，导入了单张表的数据，但发现索引都没有了。

于是开了两个 session，两边都跑创建索引的 SQL，没想到这时候竟然出现了 `deadlock detected` 的错误。

```
ERROR:  deadlock detected
DETAIL:  Process 18131 waits for ShareLock on virtual transaction 3/221; blocked by process 18295.
Process 18295 waits for ShareUpdateExclusiveLock on relation 693783 of database 577626; blocked by process 18131.
HINT:  See server log for query details.
```

查看数据库的 pg_stat_activity，看看有哪些 query 在进行。

```
SELECT * from pg_stat_activity
```

得到的其中相关的数据

```
datid            | 577626
datname          | test_db
pid              | 18131
usesysid         | 10
usename          | John
application_name | psql
client_addr      |
client_hostname  |
client_port      | -1
backend_start    | 2014-12-10 15:48:28.064723+08
xact_start       | 2014-12-10 16:23:59.189095+08
query_start      | 2014-12-10 16:23:59.189095+08
state_change     | 2014-12-10 16:23:59.189098+08
waiting          | t
state            | active
query            | CREATE INDEX index_events_on_source_event ON events USING btree (source_event);
```

可以发现，这个 query 一直处于等待的状态。解决方案就是移除这个 query 就好了。

打开另外一个终端，执行 `ps -ef | grep postgres`

```
➜  ~  ps -ef | grep postgres
  501   642   357   0  9:58PM ??         0:03.91 postgres: checkpointer process
  501   643   357   0  9:58PM ??         0:00.70 postgres: writer process
  501   644   357   0  9:58PM ??         0:02.41 postgres: wal writer process
  501   645   357   0  9:58PM ??         0:02.68 postgres: autovacuum launcher process
  501   646   357   0  9:58PM ??         0:05.16 postgres: stats collector process
  501 18131   357   0  3:48PM ??         7:36.41 postgres: John test_db [local] idle
  501 18295   357   0  3:54PM ??        12:46.07 postgres: John test_db [local] CREATE INDEX
  501 18963 18753   0  4:16PM ttys000    0:00.00 grep postgres
```

这时候就看到了 `CREATE INDEX`，干掉这个进程就可以了。

```
kill -TERM 18295
```
