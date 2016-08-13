---
layout: post
title: About test
date: 2013-07-14 17:23
comments: true
categories: ['rails']
---

## 基础

本文不介绍如何写测试，只罗列出一些与测试相关的基本工具。

为此，你需要先阅读过 [Rails Guide](http://guides.rubyonrails.org/testing.html)，并自己手动尝试写一些测试。

## 对测试的一些认识

现在要写测试，一般至少需要以下两个工具：

- 测试框架
- 数据构建工具

然后有需要的话，可以再加上其他一些辅助的工具，如测试覆盖率统计、数据伪造、数据库清理等等。

`Rails` 自身集成的`UnitTest`和`Fxiture`其实已经够用，但是也存在很多的缺点。
结合其他一些工具，我们可以打造出一个更好的测试工具。

`Rails` 我接触过的有以下三个 Test Framework

- UnitTest
- Rspec
- Minitest

## Minitest

[Minitest](https://github.com/seattlerb/minitest)提供了一套完整的测试工具来支持TDD、BDD、mocking 和 benchmarking。

包含以下几个模块：

- minitest/unit
- minitest/spec
- minitest/benchmark
- minitest/pride

基本上看其名字也就可以知道这几个模块分别能干什么事情的了，具体的用法还是参考 [Document](http://docs.seattlerb.org/minitest/) 来得靠谱些。

用于测试的几个基本工具

```ruby
group :test do
  gem "minitest", "< 5.0"               # Got lots of warning when higher than 5.0
  gem 'factory_girl_rails', ">= 4.0"    # FactoryGirl，数据构建工具
  gem 'ffaker'                          # 数据伪造工具, Faker 的改进版
  gem 'database_cleaner'                # Clean database for testing
  gem "simplecov", require: false       # 测试覆盖率统计工具
end
```

## 总结

关于测试的，发现还真没什么好写。

测试就那基本基本语法，看完 Rails Guide 基本就会了，不知道查一查就可以了。

可能比较难的是如何去写测试，也就是比较高的测试覆盖率。

在此贴出一份基本的代码

{% include_code 20130714/test_helper.rb %}

{% include_code 20130714/user.rb %}

{% include_code 20130714/users.rb %}

{% include_code 20130714/user_test.rb %}
