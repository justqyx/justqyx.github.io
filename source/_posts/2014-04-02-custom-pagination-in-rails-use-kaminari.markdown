---
layout: post
title: Custom pagination in Rails use Kaminari
date: 2014-04-02 15:47:55 +0800
comments: true
categories: [rails]
---

在 Rails App 中，我们使用 `kaminari` 去做分页的时候，我们的代码大概是这样子的：

```ruby
def index
  @users = User.where("users.name like ?", "%something%")
    .page(params[:page])
    .per(30)
end
```

```erb
<%= paginate @users %>
```

但是，当需要组织的数据逻辑较为复杂而我们的最终方案是选择自己写 SQL 语句时，如：

```ruby
page = params[:page].to_i > 0 ? params[:page].to_i : 1
offset = (page - 1) * 30

result = User.connection.execute <<-EOF
  SELECT COUNT(*) AS total
  FROM users
  WHERE users.name like '%something%'
EOF

@total = result.to_a.first.first

@users = User.connection.execute <<-EOF
  SELECT *
  FROM users
  WHERE users.name like '%something%'
  LIMIT 30 OFFSET #{offset}
EOF
```

嗯，代码差不多，但是展示分页条怎么办？自己写当然可以，但是显得麻烦。

在项目里已经使用 `kaminari`，普通情况下我们是通过 `<%= paginate @users %>` 来输入分页条的 HTML 内容，

这种情况下，我们得去翻看一下源码，看看 `paginate` 这个 helper 是怎么发挥作用的。

```ruby
# lib/kaminari/helpers/action_view_extension.rb

def paginate(scope, options = {}, &block)
  paginator = Kaminari::Helpers::Paginator.new self, options.reverse_merge(:current_page => scope.current_page, :total_pages => scope.total_pages, :per_page => scope.limit_value, :remote => false)
  paginator.to_s
end
```

从上面这段代码可以看到，通过实例化 `Kaminari::Helpers::Paginator` 这个对象之后再调用 `to_s` 方法来输出 HTML 的。

于是，继续查看其他代码之后，就可以得到下面这段代码：

```erb
<%= Kaminari::Helpers::Paginator.new(self, {
    current_page: params[:page],
    total_pages: @total_pages,
    per_page: 30,
    param_name: Kaminari.config.param_name,
    remote: false
  }).to_s %>
```

综上，在自己写 SQL 代码而导致出来的结果不是一个 `ActionRecord::Relation` 实例对象的情况下，

我们通过正常的逻辑，得到其结果集和总记录数后，再利用 `Kaminari` 来输出分页条也是一个不错的方案。
