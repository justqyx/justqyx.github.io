---
layout: post
title: Redis Learning Note
date: 2013-10-26 14:23
comments: true
categories: [database]
---

## 安装

- 使用 Homebrew 安装

```
$ brew install redis
```

- 下载源码，手动编译

```
$ wget http://download.redis.io/redis-stable.tar.gz
$ tar xvzf redis-stable.tar.gz
$ cd redis-stable
$ make && make install
```

## 支持的数据类型

`字符串` `散列表` `列表` `集合` `有序集合`

## 事务

通过使用 `MULTI` 和 `EXEC` 来实现事务。

```
redis > MULTI
OK
redis > SET key1 value
QUEUED
redis > SET key2 value
QUEUED
redis > EXEC
1) (Integer) 1
2) (Integer) 2
```

为了保证在执行事务的过程中，key1 或 key2 的值不会被其他进程所改变（即：竟态），

Redis 提供了 `WATCH` 命令：

```
redis 127.0.0.1:6379> SET key 1
OK
redis 127.0.0.1:6379> watch key
OK
redis 127.0.0.1:6379> set key 2
OK
redis 127.0.0.1:6379> MULTI
OK
redis 127.0.0.1:6379> set key 3
QUEUED
redis 127.0.0.1:6379> exec
(nil)
redis 127.0.0.1:6379> GET key
"2"
redis 127.0.0.1:6379>
```

我们可以看到，因为在 WATCH 命令之后修改了 key 的值，因此事务没有执行成功，key 的值也就是 "2"。

## 持久化

### 第一种：RDB（默认, Redis Database）

其特点有二：

1. 每一次持久化的数据，是内存中`某一时刻的数据`
2. 每一次持久化具有`原子性`，即完成之前，不会对先前的持久化数据产生影响，只有完成后，才会覆盖原先的数据

其过程大致如下：

1. Redis 使用 fork 函数复制一份当前进程（父进程）的副本（子进程）；
2. 父进程继续接收并处理客户端的命令，而子进程开始将内存中的数据写入硬盘中的临时文件；
3. 当子进程写入完所有数据后会用该临时文件替换旧的 RDB 文件，至此一次快照操作完成。

[相关命令](http://redis.io/commands/bgsave)

```
> BGSAVE
> LASTSAVE
```
  
### 第二种：AOF（append only file）

其原理是将命令写入文件中，Redis重启时，读入AOF文件，执行每条命令将值写入内存中。

**优化及写入的频率**

随着执行的命令越来越多，AOF文件也会越来越大，冗余的命令就会出现，如：

```
> set foo 1
> set foo 2
> set foo 3
```

这样一来，前面两条命令是冗余的，于是可以删除前两条命令，只保留第三条命令。我们可以在配置里让 Redis 自动去做：

```
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
```

也可以手动执行：

```
> BGREWRITEAOF
```

随便每次执行更改数据库内容时，AOF 都会将命令记录在 AOF 文件中，

但事实上由于操作系统的缓存机制，数据并没有真正地写入硬盘，而是进入了系统的硬盘缓存。

我们可以主动要求操作系统将缓存内容同步到硬盘中，在 Redis 中，我们可以通过 appendfsync 参数设置同步的实际：

```
# appendfsync always
appendfsync eversec
# appendfsync no        
```

`always`，表示每次执行写入都会执行同步，这是最安全，也是最慢的方式。

`everysec`，表示美标执行一次同步操作。

`no`，完全交由操作系统来做，即 30s 同步一次。


## 主从复制

例如有两台服务器，A（192.168.1.100:6379），B（192.168.1.101:6379），以 A 为主数据库。

A 服务器

```
$ redis-server
```

B 服务器

```
$ redis-server --slaveof 192.168.1.100 6379
```

B服务器终止同步，进入客户端：`$ redis-cli`

```
redis > SLAVEOF NO ONE
```
