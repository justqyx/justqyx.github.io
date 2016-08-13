---
layout: post
title: Using oauth in Ruby Project
date: 2013-05-19 21:40
comments: true
categories: ['rails']
---

现在，很多网站和手机app都支持使用第三方帐号登录，如 QQ、微博、Yammer、Github等。 而在这其中，最为重要的就是 `Oauth` 协议，即“开放授权”协议。

`Oauth` 是一个协议、一个标准，它允许用户授权第三方网站访问他们存储在另外的服务器的信息，而不需要将用户的帐号和密码提供给第三方网站。这样使得我们只需要使用一个帐号，就可以登录很多网站了，再也不必去记住许多帐号，而且也不需要担心帐号的安全问题。

## Ruby 实现

下面是使用 Ruby 实现的几个相关的插件

* [oauth2](https://github.com/intridea/oauth2)
* [omniauth](https://github.com/intridea/omniauth)
* [omniauth-oauth2](https://github.com/intridea/omniauth-oauth2)
 
 
## Oauth2

从名字就可以知道了，它就是 `Ruby` 对 `oatuh2` 协议的一个实现。

它实现了 `oauth2` 提及到的相关接口，于是，利用这个gem，你就可以按照协议里面规定的去实现你的功能了。 下面是 `Github` 上给出的一个例子。

```ruby
require 'oauth2'
client = OAuth2::Client.new('client_id', 'client_secret', :site => 'https://example.org')

client.auth_code.authorize_url(:redirect_uri => 'http://localhost:8080/oauth2/callback')
# => "https://example.org/oauth/authorization?response_type=code&client_id=client_id&redirect_uri=http://localhost:8080/oauth2/callback"

token = client.auth_code.get_token('authorization_code_value', :redirect_uri => 'http://localhost:8080/oauth2/callback', :headers => {'Authorization' => 'Basic some_password'})
response = token.get('/api/resource', :params => { 'query_foo' => 'bar' })
response.class.name
# => OAuth2::Response
```

也是就会想，这样不就够了吗？怎么还多出另外两个gem来呢？确实，说得没错，仅仅一个 `Oauth2` 就够了。但是 ...
 
## OmniAuth
 
我们可以看到，现在有很多Web应用，都支持多个第三方登录，
如QQ、新浪微博、Github、Facebook、Twitter等等。
也就是说，如果仅仅使用 `Oauth2` ,你都必须要每一个都实现一次，oh no！那该会是多蛋疼的事情。
`Omniauth`的出现，就是为了解决这样的一个问题而出现。
来看看它的官方描述。

> OmniAuth is a library that standardizes multi-provider authentication for web applications. It was created to be powerful, flexible, and do as little as possible. Any developer can create strategies for OmniAuth that can authenticate users via disparate systems. OmniAuth strategies have been created for everything from Facebook to LDAP.

本人英文不行，所以只能抓关键词了。`standardizes`, `multi-provider authentication`。

这里已经说得很明白了，它是标准化了一个东西，这个东西就是支持多方登录，并且，它称之为“策略”。

下面是它是使用的方法：

`config/initializers/omniauth.rb`

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer unless Rails.env.production?
  provider :twitter, ENV['TWITTER_KEY'], ENV['TWITTER_SECRET']
  provider :weibo, ENV['WEIBO_KEY'], ENV['WEIBO_SECRET']
end
```

这样一来，就简单明了。既提供了开发时调试的developer策略，也提供了twitter和weibo登录的策略。
（这里需要注意，twitter和weibo是需要自己实现的，omniauth仅仅是提供了一个developer策略而已）

于是，又一个问题出来了：策略之间基本上都是大同小异，莫非我们每个也得去写一次，于是`omniath-oauth2`变出现了。

## omniauth-oauth2

一看名字就知道，这个插件是整合了 `omniauth` 和 `oauth2` 着两个插件的。

它的出现，通过提供一个标准化的模板，使我们能够快速开发QQ登录、微博登录插件。模板如下：

```ruby
require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class SomeSite < OmniAuth::Strategies::OAuth2
      option :name, "some_site"
      uid{ raw_info['id'] }
      info do
        {
          :name => raw_info['name'],
          :email => raw_info['email']
        }
      end

      extra do
        {
          'raw_info' => raw_info
        }
      end

      def raw_info
        @raw_info ||= access_token.get('/me').parsed
      end
    end
  end
end
```

这个插件出来以后，于是实现各个第三方登录就非常容易了，下面是常用到的几个插件。

* [omniauth-qq-connect](https://github.com/kaichen/omniauth-qq-connect?source=c)
* [omniauth-weibo-oauth2](https://github.com/beenhero/omniauth-weibo-oauth2)
* [omniauth-twitter](https://github.com/arunagw/omniauth-twitter)
* [omniauth-facebook](https://github.com/mkdynamic/omniauth-facebook) 
* [omniauth-yammer](https://github.com/le0pard/omniauth-yammer) 
* [omniauth-github](https://github.com/intridea/omniauth-github) 

在我们的Rails应用程序里的 `Gemfile` 文件加上下面一句代码，即可使用了。

```ruby
gem 'omniauth-qq-connect'
```

其实这三个gem都是同一个人写的，也可以看出，作者也是在不断地完善这个工具。

