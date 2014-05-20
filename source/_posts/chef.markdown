---
layout: post
title: "chef"
date: 2013-11-08 23:10
comments: true
categories: 
---

我们使用Chef来自动集成服务器

## Chef

Chef是自动系统集成的工具，他有两种运行模式，一种是Server-Client模式，另一种是Solo模式。
前者比较复杂，需要有个中央服务器维护所有的配置信息，后者比较简单，只需要跑一下chef-solo。

我们这里维护的服务器在10台以下，选择Chef-solo就可以了，成本也比较低。

## 安装Chef

首先安装`curl`，用来下载安装脚本

    aptitude install curl

然后执行[此安装脚本](https://gist.github.com/3521559)

    curl -L https://gist.github.com/raw/3521559/0313893f5d4ae8c35c3610c84d987a20e5236694/chef_solo_bootstrap.sh | bash

执行完毕之后就拥有了Chef的运行环境了。

我们这里管理的服务器还没成千上万，所以这里选择了Chef-solo

## 编写Chef的Cookbooks

我们的Cookbooks都host在自己的Gitlab上

http://git.lanshizi.com/easyread_cookbooks

这里面包括了，所有服务器组件的安装配置脚本，以及创建用户，配置SSH keys等。

目录结构如下

    ├── README.md
    ├── cookbooks
    │   ├── build-essential
    │   ├── main
    │   └── ...
    ├── roles
    │   ├── db.json
    │   ├── proxy.json
    │   ├── rails_server.rb
    │   └── ...
    └── solo.rb

- `solo.rb` 是chef路径的配置文件
- `cookbooks` 所有的组件配置，下面每个目录叫recipe，大部分是现成的东西
- `roles` 是基于服务器角色的配置

## 配置服务器

我们基于服务器角色去维护服务器的配置，比如我们proxy服务器内容是这样的

    {
        "name": "proxy",
        "nginx": {
            "version": "1.2.3",
            "disable_access_log": true
        },
        "run_list": [
            "main",
            "tmpfs",
            "nginx",
            "nginx::http_stub_status_module",
            "sites::proxy",
            "sites::fallback"
        ]
    }
    
这里稍微解释一下，`run_list`就是需要执行的recipes，剩下的都是每个recipe的配置。

配置服务器的方法就是登陆上服务器，执行

    chef-solo -c /var/chef/solo.rb -j /var/chef/roles/{{server_solo}}.json

这样就完成服务器的配置。

## 自动化的优点

相对于手动配置并镜像服务器的方式来说，在过了一段时间之后很容易忘记各种配置。

而Chef这类的自动化配置工具，能把所有的配置都放到版本控制中，而且配置过程都是自动化。这样就可以统一服务器的配置，并记下每次服务器配置的修改。

单靠人手操作服务器是比较容易犯错的，比如误删文件，自动化后可以避免这种低级的人手错误。

另外Chef有个非常好的社区，已经提供了很多现成的recipes，直接可以使用，剩下去编写服务器配置脚本的时间。
