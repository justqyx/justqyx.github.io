---
layout: post
title: "Ruby App Server 常用的三种 I/O 模型"
date: 2016-02-17 11:06:27 +0800
comments: true
categories: ['rails']
---

所有的 Web 应用都遵循着一个基本模型。首先，它们需要从一些 I/O 通道接收 HTTP 请求，
然后处理这些请求，最后输出 HTTP 响应体，这个响应体将会被发送回 HTTP 客户端。
这个 HTTP 客户端通常是 Web 浏览器，又或者是一些像 curl 这一类的工具，又或者是搜索引擎的爬虫。

## Ruby app server

Ruby app server 其实就是 HTTP Server，能与 HTTP client 直接进行对话的服务。<br/>
Ruby 里常见的 app server 的有 thin、Unicorn、Puma、Passenger。

## Ruby web app

Ruby web app 是基于像 Rails、Sinatra 这一类框架所构建出来的应用，它并不直接与 HTTP 打交道。

如果 Ruby web app 直接与 HTTP 请求打交道的话，那么每一个 Ruby Web app 都需要实现与 HTTP 打交道，
所以为了简化这一过程，Ruby web app 只需要与一个被抽象过的 HTTP 请求和响应打交道，在 Ruby 生态里，最流行的便是 Rack。

Unicorn、Puma 和 Passenger 这一类的 app server 实现了 Rack 接口，因此 Ruby web app 能够和 Ruby app server
进行无缝对接。

{% img /downloads/images/rack.png %}

理解完 Ruby app server 和 Ruby web app 的概念后，让我们来看看常见的三种连接处理和 I/O 模型（Connection handling and I/O models）。

## Multi-process blocking I/O

{% img /downloads/images/multi-process-io.png %}

一个进程每次只处理一个客户端（的请求），通过多进程的方式来实现并发。

读操作会被阻塞如果另一端没有发送任何数据，同样写操作也会被阻塞如果另一端接收数据太慢。
因为这样的特性，所以一个进程每次只能处理一个客户端（的请求）。
想要处理多少个客户端（的请求），就需要多少个进程。

这是一种传统的 I/O 模型，被 Unicorn 和 [Apache with the prefork NPM](http://httpd.apache.org/docs/current/mod/prefork.html) 所采用。

**优点**

- 使用非常简单
- 线程安全

**缺点**

- 进程开销大
- I/O 阻塞导致吞吐量低

## Multi-threaded blocking I/O

{% img /downloads/images/multithreaded-io.png %}

I/O 调用仍然会阻塞，但通过创建线程来替代进程。
一个进程可以有许多线程，每一个线程一次处理一个客户端（的请求）。
因为线程是轻量级的，你可以使用更少的内存处理同样数量的的 I/O 并发。
要服务 5000 个 websocket 客户端，你总共需要 5000 个线程，假设你在一个台8核的机器上运行了
8 个应用进程，那么每个进程需要配置 625 个线程，这对于 Ruby 和 OS 来说是非常容易的。
一个进程可能需要 1GB 或者更少的内存，这样对于 8 个进程来说需要 8GB 的内存，
比起多进程阻塞 I/O 模型来说的 1.2TB 来说是非常小的。

这个 I/O 模型被 Torquebox 和 [Apache with the worker MPM](http://httpd.apache.org/docs/current/mod/worker.html) 所使用。
也是 Puma 经常使用的模型之一，Puma 采用了一种带限制的混合策略。

**优点**

- 对于类似 [embarassingly parallel](https://en.wikipedia.org/wiki/Embarrassingly_parallel) 的工作负载，
比如 web 请求，使用线程来处理客户端 I/O 还是非常容易的。

**缺点**

- 应用程序所有的代码和依赖的库必须是线程安全的
- 应用服务必须被反向代理保护，原因和多进程 I/O 模型一样，相比较而言，虽然多线程的应用服务不太容易受 slow client 影响，
但是也并没有完全解决 slow client 的问题

## Evented I/O

{% img /downloads/images/event-io.png %}

在这种模型里，I/O 调用完全不会被阻塞。
当另一端没有发送数据，或者接收数据太慢，I/O 调用只是返回一个特定的错误。
应用程序有一个持续监听并响应 I/O 事件的事件循环，当没有事件时，该循环会进入睡眠状态。

这是目前最为怪异（weirdest）和难以编写的一种 I/O 模型。
它需要与前面两种模型完全不同的方法，当多进程阻塞 I/O 模型的代码非常容易转换成为多线程阻塞 I/O 模型的代码，
但是如果使用 Evented I/O 模型的话，通常情况下代码需要重写。使用 Evented I/O 模型的程序需要特定的设计。

这样的 I/O 模型被 Nignx、Nodejs 和 Thin 所采用，同时它也被 Puma 部分采用以限制 slow client 达到保护的目的。

**优点**

- 使用这个模型你可以仅仅使用一个进程和一个线程便可以处理无限量的 I/O 并发，同时资源使用也非常少。
虽然多线程已经能够处理非常多的 I/O 并发，但 Evented I/O 还要多得多。
- 采用该模型的服务器，对 slow client 是免疫的（immune），所以可以不需要一个缓冲反向代理。

**缺点**

- 相比于阻塞型 I/O 模型，事件模型要难掌握地多，并且需要你时刻记住应用代码和库要适配该模型。

## 经验

Nginx + Unicorn 是一个不错的选择，并且 Unicorn 支持 hot restart，部署过程对用户的使用影响较小。

如果遇到 websocket 这一类的需求，那么 Puma (support hot restart) 单独部署这需求相关的功能是不错的。

如果遇到高 I/O 的场景，如消息群发通知，那么使用 Node来实现与外部服务交互，性能是比较理想的。相信 Rubist 都会 Node。

## Ref

- [How we made raptor up to 4x faster than unicorn and up to 2x faster than puma torquebox](http://www.rubyraptor.org/how-we-made-raptor-up-to-4x-faster-than-unicorn-and-up-to-2x-faster-than-puma-torquebox)
