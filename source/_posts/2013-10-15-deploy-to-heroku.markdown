---
layout: post
title: "the problem of deploying app to Heroku"
date: 2013-10-15 23:41
comments: true
categories: ['rails']
---

Heroku，要是不因为 GFW 的原因，国内还应该是蛮多人用的。

## 天朝特有的待遇

将项目代码 push 到 heroku 上的时候

`git push heroku master`

遇到了 timeout 的问题，不用想就知道原因了，[ruby-china](http://ruby-china.org/topics/10813) 上也有人遇到了，参考了一把。

## 解决方案

配置一个私有 ssh，打开或者新建 `vim ~/.ssh/config`，配置：

```
Host heroku.com
  HostName 107.21.95.3
  User your_main@gmail.com
  IdentityFile /User/star/.ssh/heroku
  port 22
```

## 其他问题

还需要有个定时任务，本来用的是 `whenever`，只是无奈 Heroku 提供的仅仅是个引擎，故 whenever 这种基于 cron 是无法工作的。

Heroku 也提供了[一些扩展](https://addons.heroku.com/#queues)来支持你做 scheduler jobs，一些免费，一些要钱，但都是先要填写信用卡信息，暂时没有，故做不了。
