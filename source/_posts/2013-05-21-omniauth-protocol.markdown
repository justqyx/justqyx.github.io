---
layout: post
title: "Oauth2.0 Protocol"
date: 2013-05-21 00:05
comments: true
categories: ['rails']
---

有关 `Oauth2` 协议的，这里有几份文档。

- [官方](http://oauth.net/2/)
- [腾讯](http://wiki.open.qq.com/wiki/website/OAuth2.0%E7%AE%80%E4%BB%8B)
- [维基百科](https://zh.wikipedia.org/zh/OAuth)

下面是维基对 `Oauth` 认证和授权过程的一个描述。

```bash
在认证和授权的过程中涉及的三方包括：
服务提供方，用户使用服务提供方来存储受保护的资源，如照片，视频，联系人列表。
用户 ，存放在服务提供方的受保护的资源的拥有者。
客户端 ，要访问服务提供方资源的第三方应用。在认证过程之前，客户端要向服务提供者申请客户端标识。

使用OAuth进行认证和授权的过程如下所示:
1.用户访问客户端的网站，想操作自己存放在服务提供方的资源。
2.客户端向服务提供方请求一个临时令牌。
3.服务提供方验证客户端的身份后，授予一个临时令牌。
4.客户端获得临时令牌后，将用户引导至服务提供方的授权页面请求用户授权。在这个过程中将临时令牌和客户端的回调连接发送给服务提供方。
5.用户在服务提供方的网页上输入用户名和密码，然后授权该客户端访问所请求的资源。
6.授权成功后，服务提供方引导用户返回客户端的网页。
7.客户端根据临时令牌从服务提供方那里获取访问令牌 。
8.服务提供方根据临时令牌和用户的授权情况授予客户端访问令牌。
9.客户端使用获取的访问令牌访问存放在服务提供方上的受保护的资源。
```

## Example

Add a link in your login page

```ruby
/sign_in?mode=qq_connect
```

Rails 处理代码，`app/controllers/sessions_controller.rb`

```ruby
  def sign_in
    referer = params[:referer_path] && "#{params[:referer_path]}##{params[:referer_hash]}"
    session[:referer_url] = referer || request.referer

    params[:mode] ||= "weibo"

    # 这句代码，完成了对应维基百科中的三个步骤
    # 2.客户端(即我们的app服务器)向服务提供方请求一个临时令牌
    # 3.服务提供方验证客户端的身份后，授予一个临时令牌
    # 4.客户端获得临时令牌后，将用户引导至服务器提供方(如QQ)授权页面请求用户授权
    redirect_to "/auth/#{provider_mapper(params[:mode])}"
  end

  private
  def provider_mapper(mode)
    mapper = {
      "weibo" => "weibo",
      "yammer" => "yammer"
    }

    mapper[mode] || mode
  end
```

引导用户去第三方登录授权

```ruby
 https://open.t.qq.com/cgi-bin/oauth2/authorize?client_id=APP_KEY&response_type=code&redirect_uri=http://www.myurl.com/example
```

当用户正确授权后，QQ服务器会引导用户回来我们的App服务器。
过跳转的方式实现，跳转的url如下：

```ruby
/auth/qq_connect/callback?code=WU9AadwtH0QByEDlnKg
```

就在这个跳转里，携带了用户的信息，所以我们就可以获取到用户的信息了。
配置 `config/routes.rb`。

```ruby
get "/sign_in", to: "sessions#sign_in"
get "/sign_out", to: "sessions#sign_out"
get "/auth/:provider/callback", to: "sessions#create"
```

用户登录，`app/controllers/sessions_controller.rb`。

```ruby
class SessionsController < ApplicationController
  def create
    logger.debug "AuthHash: #{auth_hash}"
    @user = User.find_or_create_from_auth_hash(auth_hash)

    if @user.present?
      current_user = @user
      session[:user_id] = @user.id
      redirect_to :root
    end
  end

  private
  def auth_hash
    request.env['omniauth.auth']
  end
end
```

