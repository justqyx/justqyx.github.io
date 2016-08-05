# 使用 docker 来运行 MySQL

```
docker run --name djistore_mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=root -d mysql:5.6.27 --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
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

