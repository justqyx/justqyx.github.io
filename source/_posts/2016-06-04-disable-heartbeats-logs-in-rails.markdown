---
layout: post
title: "Disable heartbeats logs in Rails"
date: 2016-06-04 13:15:18 +0800
comments: true
categories: ['Rails']
---

为了监测我们的 Rails 应用是否存活，我们在应用里会提供一个接口，让监控服务调用。如：

```ruby
Rails.application.routes.draw do
    get '/heartbeats', to: proc { [200, { 'Context-Type' => 'text/plain' }, ['']] }
end
```

这样日志里就会有这样的文本

```
Started GET "/heartbeats" for ::1 at 2016-06-04 13:35:14 +0800
```

但因为监控服务会每秒调用一次，所以日志就会不断地打印出来，并且这些日志其实没有任何作用，因为部署到线上后，nginx 的日志同样也会有一份，所以我就在想能不能把它去掉。

```ruby
# lib/quiet_heartbeats.rb
module QuietHeartbeats
  class Railtie < ::Rails::Railtie
    initializer 'quiet_heartbeat.initialize' do |app|
      PATH_PREFIX_REGEX = /\A(\/heartbeats)/
      Rails::Rack::Logger.class_eval do
        def call_with_quiet_heartbeat_request(env)
          if env['PATH_INFO'] =~ PATH_PREFIX_REGEX
            previous_level = Rails.logger.level
            Rails.logger.level = Logger::ERROR
            call_without_quiet_heartbeat_request(env).tap do
              Rails.logger.level = previous_level
            end
          else
            call_without_quiet_heartbeat_request(env)
          end
        end
        alias_method_chain :call, :quiet_heartbeat_request
      end
    end
  end
end
```

在 `config/application.rb` 载入这段代码

```ruby
module YourApplicationName
  class Application < Rails::Application
    require 'quiet_heartbeats'
  end
end
```

Done.
