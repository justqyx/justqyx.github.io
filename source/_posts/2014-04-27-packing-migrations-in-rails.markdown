---
layout: post
title: Packing migrations in Rails
date: 2014-04-27 18:00:00 +0800
comments: true
categories: ['rails']
---

经过长时间的开发后，项目里的迁移文件就会积累很多，可能有上百个，有些表经过许多次的修改和迁移，
而在初始化数据库时，并不需要按原来的套路走， 这时候我们希望能够将大部分甚至所有的 `migration` 合并成为一个，由一个迁移任务来创建所有表，这样就可以删除其他的迁移文件了。

## `rake db:migrate` 的大致原理

每个迁移文件的命名都是由两部分组成：`时间戳` + `名字`，如：`20140331112354_create_users.rb`，
而数据库里有一张表 `schema_migrations` 是用来记录已经 `执行过的迁移文件的时间戳`。

Rails 是否要跑一个 migration 是通过检查当前文件相应的时间戳是否存在 `schema_migrations` 里，
因此，我们要去打包迁移文件，只需要使用到一个已经跑过的 `migration`，并改一改文件名即可。

## 打包

执行完 `rake db:migrate`，`db/schema.rb` 文件就会更新，这个文件记录着数据库已有的表。

找到一个最旧的迁移文件，更新名字为: `时间戳_create_all_tables.rb`，将 schema.rb 里的创建表的代码拷贝过来即可。

```ruby
# db/migrate/20140227091105_create_all_tables.rb
#
class CreateAllTables < ActiveRecord::Migration
  def change
    create_table "table_1" do |t|
      # ...
    end

    create_table "table_2" do |t|
      # ...
    end

    # ...
  end
end
```

## 注意事项

1. 没有在生产环境跑过的迁移任务是不能打包的
2. 多人协作开发，需要注意呈现出来的迁移逻辑里不要冲突了
