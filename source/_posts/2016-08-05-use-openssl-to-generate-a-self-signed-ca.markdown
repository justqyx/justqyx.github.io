## 生成根证书

```shell
mkdir -p test/demoCA && cd test/demoCA
mkdir certs crl newcerts private
chmod 700 private
touch index.txt
echo 1000 > serial
vim openssl.cnf

openssl genrsa -aes256 -out private/ca.key.pem 4096
chmod 400 private/ca.key.pem

openssl req -config openssl.cnf \
        -key private/ca.key.pem \
        -new -x509 -days 7300 -sha256 -extensions v3_ca \
        -out certs/ca.cert.pem
```

**验证**

    openssl x509 -noout -text -in certs/ca.cert.pem

## 生成服务器证书，并用根证书签名

1、生成服务器私钥

```shell
cd test
openssl genrsa -aes256 -out server.key 2048
openssl rsa -in server.key -out server.key
```

2、生成服务器请求证书

```shell
openssl req -new -key server.key -out server.csr
```

3、用 CA 证书给服务器请求证书签名

```shell
openssl ca -config ./demoCA/openssl.cnf \
           -in server.csr -out server.crt \
           -cert ./demoCA/certs/ca.cert.pem \
           -keyfile ./demoCA/private/ca.key.pem \
           -startdate 100707000000Z \
           -enddate 300707000000Z
```

## DEMO

拿到上面的根证书 `ca.cert.pem`，导入浏览器并设置为信任，然后取得 `server.crt` 以及 `server.key` 放到某个位置，
是的 nginx 可以读取到，nginx 配置例子如下：

```conf
   server {
        listen 443;
        server_name localhost;

        ssl                   on;
        ssl_certificate       /usr/local/etc/nginx/ca/server.crt;
        ssl_certificate_key   /usr/local/etc/nginx/ca/server.key;

        ssl_session_timeout   5m;

        location / {
            root /Users/yuanxin/www;
            index index.html index.htm;
        }
    }
```

检查 nginx 的语法，如果没有问题则 reload 配置

```shell
sudo nginx -t
sudo nginx -s reload
```

打开浏览器访问：`https://localhost`

## 参考

- [Create the root pair](https://jamielinux.com/docs/openssl-certificate-authority/create-the-root-pair.html) 
- [OpenSSL证书生成(Windows环境)](http://walkerqt.blog.51cto.com/1310630/946122) 
