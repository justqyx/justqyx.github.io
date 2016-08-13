---
layout: post
title: "Captcha in Ruby"
date: 2015-05-16 11:35:41 +0800
comments: true
categories: ['rails']
---

图片验证码的使用场景就不用说了，在这里分享一下我是如何做登录图片验证码的。

## 图片验证码的生成的简单流程

`生成验证码字符` -> `生成图片验证码` [-> `使用`]

第三步的意思是，当你拿到图片验证码时，看你的具体需求了，是直接随着 form 表单渲染，
还是浏览器异步地请求图片验证码，或者其它什么的，反正无所谓了。

## 谈一谈 simple_captcha2 的做法

simple_captcha2 是基于 ImageMagick 来生成图片，基于数据库来存储验证码数据的。
提供了 `Controller Based` 和 `Model Based` 两种用法。

**Controller Based**

simple_captcha2 提供了一对方法： `show_simple_captcha` 和 `simple_captcha_valid?`。
前者是一个 view helper，让我们能够在某个地方显示一张验证码图片，后者让我们可以去判定用户提交的验证码是否正确。
想知道更多的用法可以移步到[它的文档](https://github.com/pludoni/simple-captcha)。

**实现原理**

simple_captcha2 基于数据库维护了一对 key -> value 数据，数据结构如下：

```
                                     Table "public.simple_captcha_data"
   Column   |            Type             |                            Modifiers
------------+-----------------------------+------------------------------------------------------------------
 id         | integer                     | not null default nextval('simple_captcha_data_id_seq'::regclass)
 key        | character varying(40)       |
 value      | character varying(6)        |
 created_at | timestamp without time zone |
 updated_at | timestamp without time zone |
Indexes:
    "simple_captcha_data_pkey" PRIMARY KEY, btree (id)
    "simple_captcha_data_key" btree (key)
```

当我们调用 `show_simple_captcha` 时就会生成一对这样的值，然后存放到数据库（MySQL|Postgresql|Redis）， 然后在 view 里生成这样的内容。

```html
<input type="hidden", name="captcha_key" value="d850ec25ca962ba6606cfe7c84f9568c8473e93e"
<img alt="captcha" src="/simple_captcha?code=d850ec25ca962ba6606cfe7c84f9568c8473e93e&time=1431749439" />
```

这样，它的工作原理就很清楚了。

key 的生成算法如下：

```ruby
Digest::SHA1.hexdigest([session[:id], "captcha", Time.now.to_s].join)
```

value 的算法如下：

```ruby
def generate_simple_captcha_data(code)
  value = ''
  case code
    when 'numeric' then
      SimpleCaptcha.length.times{value << (48 + rand(10)).chr}
    else
      SimpleCaptcha.length.times{value << (65 + rand(26)).chr}
  end
  return value
end
```

simple_captcha 实现了一个 middleware， 以返回验证码图片。

```ruby
module SimpleCaptcha
  class Middleware
    # ...
    def call(env) # :nodoc:
      if env["REQUEST_METHOD"] == "GET" && captcha_path?(env['PATH_INFO'])
        make_image(env)
      else
        @app.call(env)
      end
    end

    # ...

    def make_image(env, headers = {}, status = 404)
      request = Rack::Request.new(env)
      code = request.params["code"]
      body = []
      
      if !code.blank? && Utils::simple_captcha_value(code)
        return send_file(generate_simple_captcha_image(code), :type => 'image/jpeg', :disposition => 'inline', :filename =>  'simple_captcha.jpg')
      end
      
      [status, headers, body]
    end
    #...
```

在生成验证码图片这一步，它是调用了 ImageMagick 的命令来生成图片的。

```ruby
def self.run(cmd, params = "", expected_outcodes = 0)
  command = %Q[#{cmd} #{params}].gsub(/\s+/, " ")
  command = "#{command} 2>&1"

  unless (image_magick_path = SimpleCaptcha.image_magick_path).blank?
    command = File.join(image_magick_path, command)
  end

  # convert -size 100x100 -gravity "Center" -implode 0.2 <path/to/file>
  output = `#{command}`

  unless [expected_outcodes].flatten.include?($?.exitstatus)
    raise ::StandardError, "Error while running #{cmd}: #{output}"
  end

  output
end
```

**总结**

分三步走：

1. 生成一组 key, value，然后存进数据库
2. 浏览器根据 key 请求验证码图片
3. 根据 key 从数据库里取出 value，然后判定用户提交的验证码是否正确

## 我是这么做的

simple_captcha2 为图片验证码提供了一整套的解决方案，在 Rails 里使用非常简单。
但仍有做得不足的地方，例如没有暴露生成验证码图片的接口给我们，使得我们能够直接通过 ajax 来请求验证码图片。
虽然可以通过 mokey patch 来做的，但是我自己想了一个更简单的方案。

我的思路：

1. 生成验证码字符串
2. 根据字符串生成验证码图片
3. 将验证码字符串放到 session 里
4. 将图片编码成 Base64 字符串，剩下的就看你的使用场景

伪代码

```ruby
# in someone controller

# GET /captcha
def captcha
  text = SecureRandom.hex(2).upcase
  session[:captcha] = text
  base64Image = Captcha.generate text, 126, 40  # 验证码的内容，图片的宽度，图片的高度
  render json: { image: base64Image }
end
```

最关键的就是如何实现 `Captcha.generate` 了，使用纯 Ruby 生成图片成本高，需要许多知识，所以我还是选择了依赖于 ImageMagick。
思路也很简单：

1. 根据参数，生成关于 ImageMagick 中的 `convert` 命令所需要的参数
2. 使用系统调用来生成图片，并放在一个临时目录里
3. 读取图片的内容，完成后关闭这个临时文件，最后把图片内容返回

```ruby
module Captcha
  extend self

  def generate text, width = 100, height = 28
    text = text.upcase

    params = ['-fill darkblue', '-background white']
    params << "-size #{width}x#{height}"
    params << "-wave #{distortion}"
    params << '-gravity "Center"'
    params << '-pointsize 22'
    params << '-implode 0.2'

    dst = Tempfile.new(['neolion_captcha', '.png'], Dir::tmpdir)
    dst.binmode

    params << "label:'#{text}' \"#{File.expand_path(dst.path)}\""

    run(params.join(' '))

    dst.close

    read_as_base64 File.expand_path(dst.path)
  end

  private

    def distortion
      [0 + rand(2), 80 + rand(20)].join('x')
    end

    def run params = "", expected_outcodes = 0
      command = %Q[convert #{params}].gsub(/\s+/, " ")
      command = "#{command} 2>&1"

      output = `#{command}`

      unless [expected_outcodes].flatten.include?($?.exitstatus)
        raise ::StandardError, "Error while running #{command}"
      end

      output
    end

    def read_as_base64 filepath
      data = Base64.encode64(File.binread(filepath))
      ['data:image/png;base64,', data].join.gsub(/\n/, '')
    end
end
```

至于判定用户的验证码是否正确，就很简单了

```ruby
class ApplicationController < ActionController::Base
  # ...

  def valid_captcha?
    session[:captcha] == params[:captcha]
  end

  # ...
end
```

## References

- http://en.wikipedia.org/wiki/Digital_image
- http://www.webascender.com/Blog/ID/529/Working-with-Bits-and-Bytes-in-Ruby#.VUuBvROUe58
- http://www.imagemagick.org/script/index.php
- https://github.com/minimagick/minimagick
- https://github.com/minimagick/minimagick/issues/59
- https://github.com/wvanbergen/chunky_png
- https://github.com/wvanbergen/oily_png
