---
layout: post
title: "ActionCable 源码阅读笔记-前端部分-1"
date: 2016-08-13 17:37:26 +0800
comments: true
categories: ['rails']
---

本节将会简单阐述如何使用 ActionCable 收发消息，着重前端部分。

## Cable.Consumer

**基本概念**

负责建立到服务端的连接。
在连接建立之后，`Cable.ConnectionMonitor` 会通过心跳检测来确保连接的状态。
Consumer 实例对象通过 `createSubscription` 方法来建立一个连接到特定频道的订阅。

**例子**

```js
window.App = {};
App.cable = Cable.createConsumer('ws://example.com/accounts/1');
App.appearance = App.cable.subscriptions.create('AppearanceChannel');
```

这样就可以通过 `App.appearance` 来发送消息到服务器，同样其也可以接收来自服务器的消息。

## Cable.Subscription

对应着服务端的 Channel 实例，通过提供 `callbacks`、`methods` 来实现远程过程调用（RPC, Remote Procedure Calls）。

如果你在浏览器创建了一个 `AppearanceChannel` 的 `subcription`，那么 `subscription` 的调用将会直接等同于调用服务端的 `AppearanceChannel` 示例里相应的方法。

**例子**

```coffeescript
// 前端
App.appearance = App.cable.subscription.create('AppearanceChannel', {
    connected: ->
        console.info("连接已经建立好啦");

    received: (data) ->
        console.info("接收到了来自服务端的消息");

    appear: (data) ->
        this.perform('appear', data);
});
```

```ruby
# 服务端代码
class AppearanceChannel < ApplicationCable::Channel
  def subscribed
    stop_all_streams
    stream_from 'appearance_channel'
  end

  def unsubscribed
    stop_all_streams
  end

  def appear data
    # do something
  end
end
```

上面中，如果你这么使用

```js
App.appearance.appear({ message: "Hello, John" });
```

那么对应着服务端，`appear` 方法将会调用，并且你可以用过 `ActionCable.server.broadcast('appearance_channel', message: 'Hello, Katy')` 来响应，这样浏览器端的 `received` 回调将会被调用。
