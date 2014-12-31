---
layout: post
title: "What is config.threadsafe!（译）"
date: 2014-12-31 16:37:32 +0800
comments: true
categories: [rails]
---

[原文](http://www.sitepoint.com/config-threadsafe/)

我们都喜欢 Rails，因为它提供了许多优雅的功能让我们来完成我们的任务。
Rails 丰富的功能使得开发着更加专注于应用本身，而不是数据库查询、路由管理、
模板连接等一系列琐碎和重复的事情。

在为开发者提供许多用于 web 应用开发的功能的同时，Rails 隐藏了许多的细节。
因为 Rails 不想让你在构建一些好用功能的时候去关心底层所发生的事情。
开发者可以随时去阅读 Rails 的源码，而这种情况通常是发生在你的应用开始变得越来越大的时候。

初级和中级的开发者，经常会发现难以去理解 Rails 的一些很重要的概念，例如 Rack、Rack Middleware、ActiveRecord、Asset Pipeline、thread safety 等等。
在这篇文章里，我将会专注讲线程安全（thread safety）这一点。

现在让我们先谈谈多线程（multithreading）。多线程是计算机科学里一个非常重要的概念，
在今天我们必须要了解线程的重要性。线程随处可见，通常用来执行非常重要的工作。
请参考 [Wikipedia](http://en.wikipedia.org/wiki/Thread_%28computing%29)

> In computer science, a thread of execution is the smallest sequence of programmed instructions that can be managed independently by an operating system scheduler. A thread is a light-weight process.

就如 Wikipedia 所说的，线程是一个轻量级的进程（a linght-weight process）。
多个线程同属于一个进程，并且共享着该进程的资源。
所以，就内存方面而言，线程比进程更加经济一些（more economical）。
在 web 环境里，线程经常用来处理一些 background job 或者是用来异步地去跑一个长时间运行的任务。
但是在使用多线程时，我们必须非常小心，否则特别是在多线程系统里当出现竞态的时候
我们可能会得到一个意想不到的结果。
请参考 [Wikipedia](http://en.wikipedia.org/wiki/Race_condition#Software)

> Race conditions arise in software when separate computer processes or threads of execution depend on some shared state. Operations upon shared states are critical sections that must be mutually exclusive. Failure to obey this rule opens up the possibility of corrupting the shared state.

我们在计算机科学里已经了解到了一个有用的概念，现在让我们开始介绍 Rails 里的
线程安全（thread safety）。线程安全在 Rails 中已经不是一个新鲜的东西了，事实上，它可以追溯到 Rails 2.3.* 版本。Josh Peek 那时候就已经做了非常出色的工作来保证 Rails 代码是线程安全的。
Rails 里的线程安全避免了上面提到的竞态情况（race conditions）。

也就是说，在一个多线程的 web-server environment 里，我们的代码是需要线程安全的。
如果多线程在处理我们的 web 应用时，当所有的线程结束处理之后，我们的共享数据（shared data）就不应该出错。

但是 Rails 不能保证线程安全，因为开发者可能会犯错误，以至于使得代码是非线程安全的。
所以，Rails 要如何来保证我们的代码是线程安全的呢？

Rails 默认地，加了一个中间件（middleware）叫 “Rack::Lock” 到我们的 middleware stack 里。
这个 middleware 默认是 stack 里的第二个 middleware。
如果你想要查看，你可以在你的项目目录下执行 `rake middleware` 来查看。

第一个 middleware，是 `ActionDispatch::Static`，是用来处理静态资源的，
例如：JavaScript、CSS 文件和图片。

Rack::Lock 保证了每次只有一个线程在运行。如果我们移除了这个 middleware，那么多个线程就能够同时执行了。MIR Ruby 在 1.9 版本里有一个机制叫 `GIL (Global Interpreter Lock) ` or `GVL (Global VM Lock/ Giant VM Lock)`。这个 GIL 保证了每次只有一个线程在运行，在多线程的情况下，它负责线程之间的上下文切换。
如果当前的线程正在等待一个I/O操作完成的话，Ruby 会自动切换到其他线程去处理新来的请求。

现在让我们来练习一个 Rails 里的线程安全。

Create a sample Rails app.

```
rails new test_app
````

Now `cd` into newly created Rails project and bundle to install the necessary gems.

```
bundle install
```

After this, create a controller with some basic actions.

```
rails generate controller thread_safety index simple infinite
```

这将会创建一个控制器 `ThreadSafetyController`，同时有 `index, simple, infinite` 三个 action。
打开 `app/views/thread_safety/index.html.erb` 文件，并粘贴进下面的代码：

```html
<button id="simple_request">Simple Request</button>
&nbsp;
<button id="infinite_request">Infinite Request</button>
 
<script type="text/javascript">
    $("#simple_request").click(function() {
        $.get("/users/simple", function(data) {
            alert(data)
        });
    });
 
    $("#infinite_request").click(function() {
        $.get("/users/infinite", function(data) {
            alert(data)
        });
    });
</script>
```

这个将会创建一个包含两个按钮的页面。目的是为了发送一个 ajax 请求到它们对应的 action，
并且在 alert box 里展示返回的结果。

现在让我们增加一些服务段的代码到这个文件里 `app/controllers/thread_safety_controller.rb`

```ruby
def simple
  sleep(1)
  render :text => "Welcome from simple method"
end
 
def infinite
  while true
  end
end
```

上面的代码是非常简单的。simple 这个 action 在 sleep 1 秒钟之后，就会渲染一个 text/plain 格式的响应
回客户端。而 infinite 这个 action 由于死循环的关系则永远不会返回结果。
现在在终端输入 `rails s`，并打开浏览器，输入 http://localhost:3000/thread_safety/index

点击 simple 这个按钮，然后等一秒钟，你将会收到一个响应。现在点击 infinite 按钮等待服务端的响应。

infinite 用于不会返回结果，由于这个 action 里面有一段死循环的代码。
现在请你再一次点击 simple 按钮，你会发现服务器永远不会返回结果。

这就是线程安全。Rails 每次只允许一个线程在运行，这样保证了我们的代码是线程安全的。
没有其它的线程能够运行除非当前正在运行的线程结束。
因为 infinite 这个 action 里死循环的缘故，所以其他线程永远不会有机会运行并处理请求。

即使我们在生产环境里运行我们的应用，我们也回得到相同的结果。
这是非常酷的，因为每次只有一个线程在执行，所以我们能够保证我们的 Rails 代码是线程安全的。
但是，还有另外一个问题。

如果你已经把应用部署到了生产环境，并且用的是 WEBrick（你不应该用的），你的用户可能会体验到非常糟糕的性能
因为每一个只有一个线程能执行。如果有一些线程的工作需要较长时间，那么通常其他线程就需要等待了，你的用户会很恼火。

我们的静态资源则不会遇到这样的问题，因为，一旦响应发送回给客户端后，我们的服务器会继续服务来自其他客户端对于静态资源的请求。这是因为静态资源是被在 stack 处于第一个 middleware 的 ActionDispatch::Static 所处理。

我们怎么样才能不阻塞其他请求并且同时处理多个请求？我们可以先简单地禁用线程安全。
在 development.rb 或者 production.rb 文件里，启用 `config.threadsafe!`。
如果我们启用了这个选项，那么在我们的应用里会出现一系列的变化。

现在，你可以在按了 Infinite 按钮之后按两次 simple 按钮，它就能够拿到服务器的响应。
这是因为我们在我们的 Rails App 里启用了多线程，但是这会导致我们需要去写出线程安全的代码。
在 [Aaron Patterson 的这篇文章](http://tenderlovemaking.com/2012/06/18/removing-config-threadsafe.html)里，
你可以了解到更多关于 config.threadsafe! 的信息。

我们已经演示了在 Rails 里的线程安全的概念。现在让我来分享给你更多好消息。
即使 config.threadsafe! 被禁用了，你也可以使用一个基于进程（process-based）的 web server 来处理多请求。
如果我们使用 Unicorn 或者 Apache Passenger / Nginx Passenger 这一类的 server 来运行我们的应用，
那么上面所提到的 ajax 请求，即使我们触发了 infinite 的 ajax 请求，我们也可以拿到响应。

这是因为，基于进程的 web server，会创建多个 worker 进程，每一个对应这我们应用的一个实例。
Apache Passenge 会给每一个请求 spawn 一个 child process。
所以，当我们引发上面提到的 infinite ajax request 的时候，一个 worker 线程会处理这个请求，
当我们发起另外一个简单的 ajax request 的时候，它将会被一个新的 child process 所处理。
Aaron Patterson 在[这篇文章](http://tenderlovemaking.com/2012/06/18/removing-config-threadsafe.html)里提到了 `config.threadsafe!` 对于基于进程的 server 来说并没有影响。

我希望你今天能够学习到一些关于 Rails 和线程安全的知识，感谢阅读！
