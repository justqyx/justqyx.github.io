---
layout: post
title: Working with timezone in Rails(02)
date: 2014-04-27 20:30:00 +0800
comments: true
categories: ['rails']
---

在 [上一篇](/blog/2014/04/27/working-with-timezone-in-rails-01) 里，
我们讲了 MySQL 和 PostgreSQL 在时区处理上的区别，这一篇里，我们主要讲 Rails 里时区的处理。

## 日期地存储、处理、显示

对于一个带数据库的应用来说，你必须要去关注的几个问题：日期的存储、日期的处理、日期的显示。

- 日期的存储，即一个日期存入数据库时，你要采用的是何种时区去存储；
- 日期的处理，即从数据库拿到的日期数据，你要能把它正确地解析出来；
- 日期的显示，即拿到正确的日期后，你要以何种时区去使用和显示。

例如：<br>
现在我们手里有一个本地的时间 `2014-04-27 08:00:00 +08:00`，
当你以 UTC 格式 `2014-04-27 00:00:00 +00:00` 存入数据库，
相应地，<br>
在东八区，你要能显示成：`2014-04-27 08:00:00 +08:00` <br>
在东七区，你要能显示成：`2014-04-27 07:00:00 +07:00`

## Rails 时区配置

在 Rails 里，时区的设置有下面两个选项，默认值都是 `:utc`，
可以到 [Rails Guide](http://guides.rubyonrails.org/configuring.html)  查看。

```
config.active_record.default_timezone = :utc
config.time_zone = :utc
```

## config.active_record.default_timezone

这个设置是指明当与数据库交互时使用的时区，即前一篇提到的 `当前session的时区`，
它只支持 `:local` 和 `:utc` 两个选项。

我曾经疑惑为什么只支持这两种，后来发现道理其实很简单。

如果应用的使用人群有跨时区的话，那么存储和处理都应该使用 UTC，显示的时候再根据当地的时区去显示；<br>
如果应用的使用人群不跨时区的话，那么存储和处理都可以随你自己定，一般都选择当地时区或者UTC，总不会说在东八区，然后你硬要用东七区的时区存，那么这在处理的时候得多蛋疼，稍微不注意就错了，这不是给自己找罪受么。

## config.time_zone

这个设置指明，在 Ruby 代码里，处理和使用时所用的时区，天朝的码农一般都是配置成 `'Beijing'`。
`'Beijing'` 这个值，其实是被映射成为了 `Asia/Shanghai` 这个值，
可以从 [这里](http://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html) 看到。

## 例子

本例子基于：数据库的时区都设置为 `'+08:00'`，并且如果时 PG，存储的字段也不带时区。

如果数据库里存的是: `2014-04-27 00:00:00`，则：

```ruby
#
# Example 1
#
config.active_record.default_timezone = :utc
config.time_zone = 'Beijing'
#
# And then in console
user.created_at # => 2014-04-27 08:00:00 +08:00

#
# Example 2
#
config.active_record.default_timezone = :local
config.time_zone = 'Beijing'
#
# And then in console
user.created_at # => 2014-04-27 00:00:00 +08:00
```

上面提到了如果数据库是PG，那么字段也不带时区。这么说是因为，如果字段带了时区，即 `timestamp with time zone`，那么无论你当前 session 时区是什么，传过来的时间字符有没有带时区，PG都会自动帮你做相应的转换，结果就不再是上面的结果了，而是：

```
# config.active_record.default_timezone 无论是 :local 还是 :utc
config.time_zone = 'Beijing'
#
# And then in console
user.created_at # => 2014-04-27 08:00:00 +08:00
```

## 总结

1. 对于一个带数据存储的应用来说，我们需要去考虑日期类数据的存储、处理和显示
2. 在 Rails 中，你需要了解时区的设置并根据你的需要配置好上面说的两个选项
3. 对于本地时间的显示，37singals 提供了一个解决方案， [查看这里](https://github.com/basecamp/local_time)

而对于在实际项目中，数据库的时区设置应该如何去选择，
而相应的在 Rails 里这两个选项应该如何设置
以及一些需要注意的问题，将在[下一篇](/blog/2014/05/18/working-with-timezone-in-rails-03)中阐述。

<br />
