---
layout: post
title: "Run MySQL on Docker machine"
date: 2016-08-05 23:59:58 +0800
comments: true
categories: ['docker']
---

## 使用 docker 来运行 MySQL

把 Docker Container 的 3306 端口映射到宿主机的端口 3306，这样我们的计算机就可以连接到虚拟机里的 3006 端口，
从而能够连接到 Docker Container 里的 MySQL 服务。

```
docker run --name djistore_mysql \
           -p 3306:3306 \
           -e MYSQL_ROOT_PASSWORD=root
           -d mysql:5.6.27 \
           --character-set-server=utf8mb4 \
           --collation-server=utf8mb4_unicode_ci
```

连接到该 MySQL 服务

```
mysql -h 192.168.99.100 -u root -p
```

相关的日志

```
➜  ~ mysql -h 192.168.99.100 -u root -p
Enter password:
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 1
Server version: 5.6.27 MySQL Community Server (GPL)

Copyright (c) 2000, 2016, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
+--------------------+
3 rows in set (0.01 sec)
```

