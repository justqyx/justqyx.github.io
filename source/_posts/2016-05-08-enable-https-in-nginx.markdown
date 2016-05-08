---
layout: post
title: "nginx 启用 HTTPS"
date: 2016-05-08 17:01:17 +0800
comments: true
categories: ['https']
---

维基百科关于 HTTPS 的介绍 <br/>
https://en.wikipedia.org/wiki/HTTPS

## 服务器设置的步骤

1. 管理员创建 `数字证书`
2. 交由 `证书颁发机构` 签名
3. nginx 配置

浏览器通常都安装了证书颁发机构的证书，所以他们可以验证该签名。<br/>
所以如果你自己创建了一个证书颁发机构，你得让浏览器安装你自己常见的证书颁发机构的证书。

## 创建数字证书

首先需要安装好 openssl，这里不做介绍

1、Generate a 2048bit RSA private key and save it to a file

```bash
openssl genrsa -out server.key 2048
```

2、Generate a certificate signing request to be sent to a certificate authority
```bash
openssl req -new -sha256 -key server.key -out server.csr
```

## 对服务器证书进行签名

由于这里是测试，所以我们创建一个自签名（self-signed）的数字证书。

Generate a self-signed certificate from a certificate signing request valid for some number of days:

```bash
openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
```

最后，将生成的 `server.crt` 在浏览器端设置为信任即可。

## nginx 配置

```
server {
    listen 443;
    server_name https.example.com;

    ssl                   on;
    ssl_certificate       /opt/www/https-example/server.crt;
    ssl_certificate_key   /opt/www/https-example/server.key;

    ssl_session_timeout   5m;

    location / {
        root /opt/www/https-example;
        index index.html index.htm;
    }
}
```

重启 nginx

```bash
# ubuntu
sudo service nginx -s reload

# Mac OSX
sudo nginx -s reload
```

打开浏览器，访问

    https://https.example.com

