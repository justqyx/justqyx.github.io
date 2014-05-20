---
layout: post
title: Working with timezone in Rails(01)
date: 2014-04-27 19:05:00 +0800
comments: true
categories: [rails]
---

在讲 Rails 里对时区的处理前，得先来看看数据库对时区的处理到底时怎样的。

在对时区的处理上，MySQL(v5.5) 与 PostgreSQL(v9.3) 是有一些不同的。

## MySQL

通过自己的几次验证，我得到了下面的结论：

1. MySQL 的时区默认跟系统时区是一样的，通过 `SELECT @@global.time_zone, @@session.time_zone;` 可以查看MySQL的时区和当前对话的时区
2. 当前 session 时区会影响到 `now()` 这一类内置函数的结果
3. 插入或更新数据时，MySQL 并不会去处理插入的值是否有带时区


可以来看看下面的例子：

查看时区和 `select now()` 的结果

```
mysql> SELECT @@global.time_zone, @@session.time_zone;
+--------------------+---------------------+
| @@global.time_zone | @@session.time_zone |
+--------------------+---------------------+
| SYSTEM             | SYSTEM              |
+--------------------+---------------------+
1 row in set (0.00 sec)
mysql> select now();
+---------------------+
| now()               |
+---------------------+
| 2014-04-27 19:19:11 |
+---------------------+
1 row in set (0.00 sec)
```

设置当前 session 的时区，并通过 `select now();` 来查看结果：

```
mysql> set time_zone = '+08:00';
Query OK, 0 rows affected (0.00 sec)

mysql> select now();
+---------------------+
| now()               |
+---------------------+
| 2014-04-27 19:19:59 |
+---------------------+
1 row in set (0.00 sec)

mysql> set time_zone = '+00:00';
Query OK, 0 rows affected (0.00 sec)

mysql> select now();
+---------------------+
| now()               |
+---------------------+
| 2014-04-27 11:20:10 |
+---------------------+
1 row in set (0.00 sec)
```

设置当前 session 的时区为 '+08:00'（即东八区），但是插入数据时，我们用 UTC 时区的值，我们来看看结果：

```
mysql> describe users;
+------------+--------------+------+-----+---------+-------+
| Field      | Type         | Null | Key | Default | Extra |
+------------+--------------+------+-----+---------+-------+
| name       | varchar(255) | YES  |     | NULL    |       |
| created_at | datetime     | YES  |     | NULL    |       |
+------------+--------------+------+-----+---------+-------+
2 rows in set (0.03 sec)

mysql> insert into users (name, created_at) values ('张三', '1990-01-01 00:00:00 +0000');
Query OK, 1 row affected, 1 warning (0.00 sec)

mysql> insert into users (name, created_at) values ('李四', '1990-01-01 00:00:00 +0800');
Query OK, 1 row affected, 1 warning (0.00 sec)

mysql> insert into users (name, created_at) values ('李四', '1990-01-01 00:00:00 +8:00');
Query OK, 1 row affected, 1 warning (0.00 sec)

mysql> insert into users (name, created_at) values ('李四', '1990-01-01 00:00:00 +08:00');
Query OK, 1 row affected, 1 warning (0.04 sec)

mysql> insert into users (name, created_at) values ('李四', '1990-01-01 00:00:00');
Query OK, 1 row affected (0.00 sec)

mysql> select * from users;
+--------+---------------------+
| name   | created_at          |
+--------+---------------------+
| 张三   | 1990-01-01 00:00:00 |
| 李四   | 1990-01-01 00:00:00 |
| 李四   | 1990-01-01 00:00:00 |
| 李四   | 1990-01-01 00:00:00 |
| 李四   | 1990-01-01 00:00:00 |
+--------+---------------------+
5 rows in set (0.00 sec)
```

通过上面的结果我们可以看到，只要你带了时区，MySQL 就会给你个警告，然后就不管了，截取前面时间直接就存进去了。

## PostgreSQL

同样的，在 PG 中，做了一组测试之后，我得出的结论：

1. 默认时区为 GMT，具体可参考 [here](http://www.baike.com/wiki/GMT)
2. 当前 session 的设置会影响到内置的一些函数，如：now()
3. 插入或更新数据，如果更改的字段是带有时区的，那么 PG 是会对其进行转换的

下面来看看一些验证的例子：

不设置时区，可以看到默认为 GMT，时间可以认为跟时间标准时间(UTC)一致

```
test=# show timezone;
 TimeZone
----------
 GMT
(1 row)

test=# select now();
              now
-------------------------------
 2014-04-27 11:57:14.541743+00
(1 row)
```

从现在开始，我们将时区设置为 'PRC'（即东八区，中华人民共和国） 来验证

```
test=# show timezone;
 TimeZone
----------
 PRC
(1 row)

test=# select now();
              now
-------------------------------
 2014-04-27 19:59:47.312923+08
(1 row)
```

建立一张表，其中一个字段带有时区，一个则没有

```
test=# \d users;
                 Table "public.users"
   Column   |            Type             | Modifiers
------------+-----------------------------+-----------
 name       | character varying(255)      |
 created_at | timestamp with time zone    |
 updated_at | timestamp without time zone |
```

分别插入不带时区、带不同时区的几组值，然后查看结果

```
test=# insert into users values ('张三', '2014-04-27 08:00:00', '2014-04-27 08:00:00');
INSERT 0 1
test=# insert into users values ('张三', '2014-04-27 08:00:00 +00:00', '2014-04-27 08:00:00 +00:00');
INSERT 0 1
test=# insert into users values ('张三', '2014-04-27 08:00:00 +08:00', '2014-04-27 08:00:00 +08:00');
INSERT 0 1
test=# insert into users values ('张三', '2014-04-27 08:00:00 +09:00', '2014-04-27 08:00:00 +09:00');
INSERT 0 1
test=# select * from users;
 name |       created_at       |     updated_at
------+------------------------+---------------------
 张三 | 2014-04-27 08:00:00+08 | 2014-04-27 08:00:00
 张三 | 2014-04-27 16:00:00+08 | 2014-04-27 08:00:00
 张三 | 2014-04-27 08:00:00+08 | 2014-04-27 08:00:00
 张三 | 2014-04-27 07:00:00+08 | 2014-04-27 08:00:00
(4 rows)
```

我们改变一下当前 session 的时区，并查看刚插入的值：

```
test=# set timezone = '+00:00';
SET
test=# select now();
              now
-------------------------------
 2014-04-27 12:09:10.931947+00
(1 row)

test=# select * from users;
 name |       created_at       |     updated_at
------+------------------------+---------------------
 张三 | 2014-04-27 00:00:00+00 | 2014-04-27 08:00:00
 张三 | 2014-04-27 08:00:00+00 | 2014-04-27 08:00:00
 张三 | 2014-04-27 00:00:00+00 | 2014-04-27 08:00:00
 张三 | 2014-04-26 23:00:00+00 | 2014-04-27 08:00:00
(4 rows)
```

从上面我们可以得到不带时区和带时区的字段结果：

不带时区的字段：

1. 无论插入的数据带不带时区，只截取前面的字符串，并不会对值进行处理
2. 当前 session 的时区，不会影响插入的值

带时区的字段：

1. 若不带时区，则插入的数据会被加上当前 session 的时区
2. 若带时区，则按这个值指定时区存入，取数据时，会根据当前的 session 时区进行相应的转换


## 总结

综上，我们可以得到以下的一些结论：

MySQL 和 PostgreSQL 在时区处理上共同的地方

1. 当前 session 的时区会影响到内置的一些函数的值，如：now() 等
2. PG 里不带时区的字段与 MySQL 的处理方式是一样的

不同的地方

1. MySQL 并不支持有时区的字段，而 PG 支持
2. MySQL 并不会去处理插入或更新的值是否带有时区，而 PG 如果时遇到带时区的字段，则会进行处理

<br />

[下一篇：Working with timezone in Rails(02)](/blog/2014/04/27/working-with-timezone-in-rails-02)
