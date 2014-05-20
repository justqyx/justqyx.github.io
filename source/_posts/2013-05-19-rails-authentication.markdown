---
layout: post
title: "Rails admin authentication"
date: 2013-05-19 11:37
comments: true
categories: [rails]
---

今天想学习一下 omniauth 的使用，但是使用前，想重新整理出以前在做登录时是怎么做的。


曾经，做个登录竟然花了3天，现在看来，怎么都不敢想象，责备自己怎么基础学得这么烂。

天啊，以前的日子究竟都在干什么呀！


## Idear

一个小小的web app，分为前台和后台。前台的页面都不需要登录，后台的页面需要登录。

## General Authentication Module

只需要包含进某个控制器就可以用了。

{% include_code authentication/authenticate_user.rb %}

`helper_method` 使得包含这个模块的控制器拥有`current_user`和`user_signed_in?`这两个方法，并且在视图里面也可以使用。

`SessionsController`控制器 和 `User`模型，一般都是根据自己的需要自己去写实际的逻辑。

## Implementation: Admin Scope

为了实现后台必须登录的逻辑，可以这样实现

  * `/admin/controller/action` 开头的，都是后台页面的，需要登录
  * `/controller/action` 类似的，都是普通的页面，用户可以随便浏览

于是我们可以这样

`rails g controller Admin::Base`，基本代码为

{% include_code authentication/base_controller.rb %}


## Epilogue
  
  现在有一些关于登录校验一些不错的插件，最熟悉的莫过于`devise`。

  但是基本都是这样的一个原理，个人觉得，有机会还是要多学习最原始的，最基础的东西，出来工作就比较难了。

  因为公司一般不想培养人，成本太高，又基本很难留住，所以基本上要求的都是能直接开发的。

  工具可以大大加快开发速度，但是对于新人来说，这并不是最好的。

  新人需要有人去引导。



