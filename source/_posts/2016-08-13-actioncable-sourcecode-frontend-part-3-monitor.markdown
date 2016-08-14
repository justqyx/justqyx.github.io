---
layout: post
title: "ActionCable 源码阅读笔记-前端部分-3"
date: 2016-08-13 18:06:30 +0800
comments: true
categories: ['rails']
---

`Cable.ConnectionMonitor` 通过心跳检测来确保连接处于健康的状态，如果连接出现了问题那么会重新连接而不需要，并且这对于维护来说是透明的，不需要开发人员关心。

## 心跳检测

`Cable.Consumer` 的构造函数实例化了 `Cable.ConnectionMonitor`

```coffeescript
constructor: (@url) ->
    @subscriptions = new Cable.Subscriptions this
    @connection = new Cable.Connection this
    @connectionMonitor = new Cable.ConnectionMonitor this
```

看看 `Cable.ConnectionMonitor` 的构造函数

```coffeescript
constructor: (@consumer) ->
    @consumer.subscriptions.add(this)  # 暂时忽略 
    @start()                           # 开始心跳检测
```

start 函数

```coffeescript
start: ->
    # 下面三行代码做了一些连接的准备工作
    @reset()
    delete @stoppedAt
    @startedAt = now()
    
    # 开始定时往服务器发送心跳检测消息
    @poll()
    
    # 兼容 Turbolinks：页面重新载入时，重建连接
    document.addEventListener("visibilitychange", @visibilityDidChange) 
```

poll 函数

```coffeescript
setTimeout =>
    unless @stoppedAt         # 如果已经连接断开，那么重建连接
        @reconnectIfStale()
        @poll()
, @getInterval()              # 随机间隔（3 ~ 30 秒）
```

reconnectIfStale 函数

```coffeescript
#
# 如果连接已经过时，那么重建连接
# 条件是：最后发送消息的时间，或者最后 ping 的时间已经过了 6 秒
# class Cable.ConnectionMonitor
#  @pollInterval:
#    min: 3
#    max: 30
#  @staleThreshold: 6 # Server::Connections::BEAT_INTERVAL * 2 (missed two pings)
#
if @connectionIsStale()
    @reconnectAttempts++
    unless @disconnectedRecently()
        # 调用 Cable.Connection 的实例进行连接的重建
        @consumer.connection.reopen()
```

通过心跳检测来检测连接的健康情况属于主动式的检测，下面阐释基于 WebSocket 的 onclose、onerror 回调的连接重建逻辑。

## WebSocket 回调

在上一篇里提及到在 Cable.Connection 连接的建立是通过 WebSocket 的实例化来实现，同时绑定了以下四个回调

- onmessage
- onopen
- onclose
- onerror

关键源码部分如下

```coffeescript
installEventHandlers: ->  # 向 @webSocket 注入各个回调
    for eventName of @events
        handler = @events[eventName].bind(this)
        @webSocket["on#{eventName}"] = handler
    return

events:
    message: (event) -> # onmessage 回调
        {identifier, message, type} = JSON.parse(event.data)
        switch type
            when message_types.confirmation
                @consumer.subscriptions.notify(identifier, "connected")
            when message_types.rejection
                @consumer.subscriptions.reject(identifier)
            else
                @consumer.subscriptions.notify(identifier, "received", message)
    open: -> # onopen 回调
        @disconnected = false
        @consumer.subscriptions.reload()
    close: -> # onclose 回调
        @disconnect()
    error: -> # onerror 回调
        @disconnect()
```

disconnect 函数

```coffeescript
disconnect: ->
    return if @disconnected # 如果已经断开则直接返回
    @disconnected = true    # 标识已经断开
    @consumer.subscriptions.notifyAll("disconnected") # 通知所有的 subscript 已经断开
```

`Cable.Subscriptions` 里的 `notifyAll` 和 `notify`

```coffeescript
notifyAll: (callbackName, args...) ->
    for subscription in @subscriptions
        # 通知各个 subscription 调用各自的 disconnected 函数
        @notify(subscription, callbackName, args...)

notify: (subscription, callbackName, args...) ->
    if typeof subscription is "string"
        subscriptions = @findAll(subscription)
    else
        subscriptions = [subscription]

    for subscription in subscriptions
        # subscription 调用 disconnected 函数
        #   subscription[callbackName]?(args...) 的意思是
        #   subscription = subscriptions[i];
        #   if (typeof subscription[callbackName] === "function") {
        #       subscription[callbackName].apply(subscription, args);
        #   }
        subscription[callbackName]?(args...)
        # 以下先不理会，否则会脱离内容的主线
        if callbackName in ["initialized", "connected", "disconnected", "rejected"]
            {identifier} = subscription
            @record(notification: {identifier, callbackName, args})
```

好了，回去看 `Cable.ConnectionMonitor` 的 `disconnected` 函数

```coffeescript
disconnected: ->
    @disconnectedAt = now()
```

这样，心跳检测时就会发现连接已断开，就会重建连接，相关代码如下

```coffeescript
poll: ->
    setTimeout =>
        unless @stoppedAt
            @reconnectIfStale()
            @poll()
    , @getInterval()

reconnectIfStale: ->
    if @connectionIsStale()
        @reconnectAttempts++
        unless @disconnectedRecently()
            @consumer.connection.reopen()

connectionIsStale: ->
    secondsSince(@pingedAt ? @startedAt) > @constructor.staleThreshold

disconnectedRecently: ->
    @disconnectedAt and secondsSince(@disconnectedAt) < @constructor.staleThreshold
```

## 总结

连接的监控也简单，通过自主的心跳检测，以及 `WebSocket` 的 `onerror`、`onclose` 回调来自动地重建连接，因此使用者可以不需要去关心当前的连接是否正常。

