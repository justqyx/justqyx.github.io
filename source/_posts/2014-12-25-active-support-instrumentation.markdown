---
layout: post
title: "Instrumentation in ActiveSupport"
date: 2014-12-25 21:08:03 +0800
comments: true
categories: ["rails"]
---

ActiveSupport 是 Rails 的基础组件，其中包含了一个 Instrumentation API。<br/>
Instrumentation 让我们能够订阅某些事件，然后产生相关的数据和做另外某些事情。<br/>
AcitveSupport 所实现的 Instrumentation API 不仅仅可以在 Rails 项目中使用，也可以在非 Rails 项目中使用。<br/>
个人认为 Instrumentation 应该像是 Specification 之类东西，其他语言也应该有各自的一些实现。

## Instrumentation 能够做什么

> The instrumentation API provided by ActiveSupport allows developers
> to provide hooks which other developers may hook into. Ther are several
> of there within the Rails framework.
>
> With this API, developers can choose to be notified when certain
> events occur inside their application or another piece of Ruby code.

简单地来讲，就是去订阅某些事件，然后做你想做的事情。例如，在 Rails 中， <br/>
我们可以在一个请求结束时，收集本次请求的一些数据（如：渲染 view 所使用的时间、<br/>
数据库查询所花费的时间、本次请求总共所花费的时间等等）。

## The hooks inside the Rails framework for instrumentation

在 Rails 中，已经实现了许多事件的 hooks（框架就是干这种脏活累活的）。分为以下八大类：

- Action Controller
- Active View
- Active Record
- Active Mailer
- Active Resource
- Active Supportt
- Railties
- Rails

每个类别下具体的 hook event，在 [Rails Guide](http://edgeguides.rubyonrails.org/active_support_instrumentation.html#rails-framework-hooks) 文档里可以找到。
在 Action Controller 这个类别里，有一个 **process_action.action_controller**，
它就是收集了一次请求里的一些数据。如下：

{% img /downloads/images/process_action.action_controller.png %}

以上是一个 hook event 所提供的数据，但还有另外的几个由 subcriber 提供的数据，下个 section 会提及。 

## Subscribing to an event

在 Rails 中，subcribe an event 是非常简单的，如下：

```ruby
ActiveSupport::Notifications.subscribe "process_action.action_controller" do
  |name, started, finished, unique_id, data|
  # name 即 event 的名字
  # started 即 event 的开始时间
  # finsihed 即 event 的结束时间
  # unique_id 即 event 的 unique ID
  # data 即上文表格中的数据
end
```

另外，还可以将 block 的参数，传给 **ActiveSupport::Notifications::Event** 构造一个 event object，如下：

```ruby
ActiveSupport::Notifications.subscribe "process_action.action_controller" do |*args|
  event = ActiveSupport::Notifications::Event.new *args
  event.name     # => "process_action.action_controller"
  event.duration # => 整个事件所花费的时间，单位是毫秒(ms)
  event.payload  # => 上文的 data
end
```

最后，subcribe 还支持正则表达式，如下：

```ruby
ActiveSupport::Notifications.subscribe /action_controller/ do |*args|
  # inspect all ActionController events
end
```

## Building a custom instrumentation implementation

先来看看如何 instrument an event

```ruby
ActiveSupport::Notifications.instrument "custom.event", extra: :hello_world do
  # do your custom stuff code
end
```

首先，会执行 block 中的代码，执行完毕之后，就会立即 notify all subscribers。<br/>
**custom.event** 是事件的名字，其余的参数就是 data（subcribe 那里的 data 参数），<br/>
在这里就是 `{ extra: :hello_world }` 了。

下面的代码则是去订阅 custom.event，

```ruby
ActiveSupport::Notifications.subscribe "custom.event" do
  |name, started, finished, unique_id, data|
  puts data.inspect # => { :extra => :hello_world }
end
```

## References

- [Active Support Instrumentation](http://edgeguides.rubyonrails.org/active_support_instrumentation.html)
