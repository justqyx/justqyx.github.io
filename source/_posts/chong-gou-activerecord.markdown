---
layout: post
title: "7 ways to decompose Fat ActiveRecord Models"
date: 2013-05-23 22:59
comments: true
categories: [ruby rails]
---

[未完成]

[7 Patterns to Refactor Fat ActiveRecord Models](http://blog.codeclimate.com/blog/2012/10/17/7-ways-to-decompose-fat-activerecord-models/)

当我们的项目越来越大的时候，我们就会发现，我们的模型跟控制器里面的代码越来越长，变得越来越难以维护。

上面的文章，就介绍了7种关于如何重构模型和控制器的方法，值得学习。

## Don't Extract Mixins from Fat Models

不要单纯地把一堆方法抽取出来，放进一个 module，然后被这个 Model include 。

因为这样做，仅仅是在空间上使代码变得舒适点，但是其本质上却被多大改变！

在 Rails4 里，多了一个东西，称为 [concerns](https://37signals.com/svn/posts/3372-put-chubby-models-on-a-diet-with-concerns) 的东西，现在推荐放进这里面去，但是离重构还有些距离。

## 1. Extract Value Objects

  第1类：将涉及 `数值类` 的对象抽取出来。

  `Value Objects` 顾名思义，就是围绕着 `数值` 来决定某些行为。`Date`、`URI` 和 `Pathname` 是Ruby标准库的例子。

  你的 `Application` 也可以定义一些 `领域特定(domain-specific)` 的 `Value Objects`。

  将它们从 `ActiveRecord Models` 里抽取出来是一种廉价的重构方式。

  {% include_code 20130523/rating.rb %}

  {% include_code 20130523/constant_snapshot.rb %}

  根据用户的消费情况，用户会被视为不同等级的（钱哪！）。

  这里把 `用户的等级` 抽象成为一个领域的东西，它能干什么事情，由类 `Rating` 来维护。

  这样，一旦标准有所不同，我们只需要修改 `Rating` 即可！

```ruby

  # a 和 b 为 ConstantSnapshot实例对象
  a.rating.better_than?(b.rating)

```

## 2. Extract Service Objects

  第2类：将涉及 `服务类` 的对象抽取出来。

  `Service Objects` 顾名思义，表示这个类专门干一件事情，只要你提交必要的信息，它就能把这件事情做好！

  在什么情况下应该抽取出 `Service Objects` 呢？

  * 这个 `action is complex`，例如我一个订单登记之后，要做非常多的事情。
  * 这个 `action 涉及许多模型`
  * 这个 `action 与外部的服务或应用有交互`, 例如我在我的博客发表一篇文章，后台自动将其分享到我的微博。
  * 这个 `action 并不是相关模型的核心代码`，例如，过一段时间，后台要对数据库的数据进行分析，或者是垃圾数据清理。
  * 这个 `action 有许多种实现方式`，例如我们的登录，既可以注册登录，也可以用第三方登录。

  {% include_code 20130523/user_authenticator.rb %}

  有了这个之后呢，我们在 `sessions_controller.rb` 里面呢，就可以说，由 UserAuthenticator 来判断用户是否合法，但是具体的判断方式我就不关心了。

  {% include_code 20130523/sessions_controller.rb %}

## 3. Extract Form Objects

  第3类：将 `表单对象` 抽取出来。

  几个 `ActiveRecord Models` （例如 order 和 order_items）可能一次性的提交更新。用这种方式，在个人角度看来，要比用 `accepts_nested_attributes_for` 要好得多。

  {% include_code 20130523/signup.rb %}

  这里使用了 `Virtus` 这个插件，它提供了像ActiveRecord那样的 `attribute` 的功能，于是，重构后的控制器就变成如下，你看，多清晰的逻辑。

  {% include_code 20130523/signups_controller.rb %}

## 4. Extract Query Objects

第4类：查询类

对于一些涉及复杂的查询和组织的代码，可以考虑将其抽象成一个 `Query Object`。

```ruby

class AbandonedTrialQuery
  def initialize(relation = Account.scoped)
    @relation = relation
  end

  def find_each(&block)
    @relation.
      where(plan: nil, invites_count: 0).
      find_each(&block)
  end
end

```

你可能把它放在 background job 来发送邮件

```ruby

AbandonedTrialQuery.new.find_each do |account|
  account.send_offer_for_support
end

```

```ruby

old_accounts = Account.where("created_at < ?", 1.month.ago)
old_abandoned_trials = AbandonedTrialQuery.new(old_accounts)

```

当然，别忘了测试。

## 5. Introduce View Objects

If logic is needed purely for display purposes, it does not belong in the model. Ask yourself, “If I was implementing an alternative interface to this application, like a voice-activated UI, would I need this?”. If not, consider putting it in a helper or (often better) a View object.

For example, the donut charts in Code Climate break down class ratings based on a snapshot of the codebase (e.g. Rails on Code Climate) and are encapsulated as a View:

```ruby

class DonutChart
  def initialize(snapshot)
    @snapshot = snapshot
  end

  def cache_key
    @snapshot.id.to_s
  end

  def data
    # pull data from @snapshot and turn it into a JSON structure
  end
end

```

I often find a one-to-one relationship between Views and ERB (or Haml/Slim) templates. This has led me to start investigating implementations of the Two Step View pattern that can be used with Rails, but I don’t have a clear solution yet.

Note: The term “Presenter” has caught on in the Ruby community, but I avoid it for its baggage and conflicting use. The “Presenter” term was introduced by Jay Fields to describe what I refer to above as “Form Objects”. Also, Rails unfortunately uses the term “view” to describe what are otherwise known as “templates”. To avoid ambiguity, I sometimes refer to these View objects as “View Models”.

## 6. Extract Policy Objects

`Service Objects` 偏向于 `写操作`

`Policy Objects`  偏向于 `读操作` 

`Query Obejcts`   偏向于 `执行SQL语句操作，并返回一个结果数据集合`

```ruby

class ActiveUserPolicy
  def initialize(user)
    @user = user
  end

  def active?
    @user.email_confirmed? &&
    @user.last_login_at > 14.days.ago
  end
end

```

## 7. Extract Decorators

Decorators let you layer on functionality to existing operations, and therefore serve a similar purpose to callbacks. For cases where callback logic only needs to run in some circumstances or including it in the model would give the model too many responsibilities, a Decorator is useful.

Posting a comment on a blog post might trigger a post to someone’s Facebook wall, but that doesn’t mean the logic should be hard wired into the Comment class. One sign you’ve added too many responsibilities in callbacks is slow and brittle tests or an urge to stub out side effects in wholly unrelated test cases.

Here’s how you might extract Facebook posting logic into a Decorator:

```ruby

class FacebookCommentNotifier
  def initialize(comment)
    @comment = comment
  end

  def save
    @comment.save && post_to_wall
  end

private

  def post_to_wall
    Facebook.post(title: @comment.title, user: @comment.author)
  end
end

```

And how a controller might use it:

```ruby

class CommentsController < ApplicationController
  def create
    @comment = FacebookCommentNotifier.new(Comment.new(params[:comment]))

    if @comment.save
      redirect_to blog_path, notice: "Your comment was posted."
    else
      render "new"
    end
  end
end

```

Decorators differ from Service Objects because they layer on responsibilities to existing interfaces. Once decorated, collaborators just treat the FacebookCommentNotifier instance as if it were a Comment. In its standard library, Ruby provides a number of facilities to make building decorators easier with metaprogramming.

## 总结

  其实，总结起来只有一种，就是为你自己的程序抽象出一些 `domain-specific` 的业务出来，然后将其封装成一个class，放入到 concern 里。
  而不再是以传统的方式，利用 `module` 将代码在空间上抽取出来而已。

  这七种方式，就是罗列了7种 `domain-specific`

## 扩展阅读

* [Objects on Rails](http://objectsonrails.com/)
* [Crazy, Heretical, and Awesome: The Way I Write Rails Apps](http://jamesgolick.com/2010/3/14/crazy-heretical-and-awesome-the-way-i-write-rails-apps.html)
* [ActiveRecord (and Rails) Considered Harmful](http://blog.steveklabnik.com/posts/2011-12-30-active-record-considered-harmful)
* [Single Responsibility Principle on Rails Explained](http://solnic.eu/2012/07/09/single-responsibility-principle-on-rails-explained.html)
