---
layout: post
title: "Inspect SimpleForm (1)"
date: 2015-05-31 00:02:37 +0800
comments: true
categories: ["rails"]
---

## Table of Content

- 简单介绍 SimpleForm 做了什么事情
- 如何编写一个简单的 wrapper
- 从 simple_form_for 这个入口了解 SimpleForm 的基本工作原理
- 深入了解 wrapper 的实现

## 简介

SimpleForm 是 Rails 项目最常用的插件之一，通过抽象出 wrapper 这个概念来简化表单的编写。

通常情况下，网页上的表单都需要经过各种美化，这使得最后的表单控件会被
各种各样的标签所包裹，例如套用了 Bootstrap 的 Horizontal Form 的样式：

```erb
<% form_for resource, html: { class: 'form-horizontal' } do |f| %>
  <div class="form-group">
    <label for="inputEmail3" class="col-sm-2 control-label">Email</label>
    <div class="col-sm-10">
      <%= f.text_field :email, class: 'form-control', placeholder: 'Email' %>
    </div>
  </div>
<% end %>
```

如果我们不做进一步的抽象，那么在每个地方，我们都会重复地写这些代码，而且一旦需要修改，那么就是大面积的查找和替换了。
但如果你使用了 SimpleForm 之后，那么就会变成：

```erb
<%= simple_form_for resource, wrapper: :horizontal_form, html: { class: 'horizontal_form' } do |f| %>
  <%= f.input :email %>
  <%= f.input :password %>
  <%= f.button :submit %>
<% end %>
```

SimpleForm 会根据你所写的配置（[例子](https://github.com/plataformatec/simple_form/blob/master/lib%2Fgenerators%2Fsimple_form%2Ftemplates%2Fconfig%2Finitializers%2Fsimple_form_bootstrap.rb)）
所指定的 wrapper 来对表单控件进行一层包裹，从而达到代码重用的效果。<br/>
wrapper 对于 SimpleForm 来讲是最核心的东西，现在我们来看看关于它的一些东西。

## 如何编写 wrapper

我们看看上面的 horizontal_form 这个 wrapper 是如何编写的。

```ruby
# config/initializers/simple_form_bootstrap3.rb
SimpleForm.setup do |config|
  config.wrapper :horizontal_form, tag: 'div', class: 'form-group', error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label, class: 'control-label'

    b.use :input, class: 'form-control'
    b.use :error, wrap_with: { tag: 'span', class: 'help-block' }
    b.use :hint,  wrap_with: { tag: 'p', class: 'help-block' }
  end
end
```

乍一看还挺多东西的，但是不怕，我们通过对比一些最终的输出内容我们就可以知道，最核心的下面这两行代码：

```ruby
    b.use :label, class: 'control-label'
    b.use :input, class: 'form-control'
```

所以，通过看一下文档和例子我们马上就可以掌握编写一个简单的 wrapper 了。<br/>
好了，最基本的介绍也到此为止了，而关于其他几行代码，究竟是什么意思，
究竟是如何工作的，接下来我会一一讲解。

## simple_form_for

在对 wrapper 进行剖析之前，还是需要先来看看整个程序的入口：simple_form_for。这也是读源代码的方法，我们不能一下子就
把头埋进浩瀚的代码海洋中，我们要从入口来理清楚整个程序的逻辑。下面就是我找到的关键代码片段：

```
# lib/simple_form/active_view_extensions/form_helper.rb
module SimpleForm
  module ActionViewExtensions
    module FormHelper
      def simple_form_for(record, options = {}, &block)
        options[:builder] ||= SimpleForm::FormBuilder
        # 中间代码省略
        with_simple_form_field_error_proc do
          form_for(record, options, &block)
        end
      end
    end
  end
end
ActionView::Base.send :include, SimpleForm::ActionViewExtensions::FormHelper
```

从上面的代码也就可以看出，这个方法做了两件事：

1. 设置 form_for 的 builder 为 SimpleForm::FormBuilder，即 f 是这个类的实例
2. 调用 Rails 原生提供的 form_for 这个 helper 来渲染整个表单

所以，接下来就是找到 SimpleForm::FormBuilder 这个文件了，在这个文件里，我们就可以找到关键的接口 `input` 了：

```ruby
def input(attribute_name, options = {}, &block)
  options = @defaults.deep_dup.deep_merge(options) if @defaults

  input   = find_input(attribute_name, options, &block)
  wrapper = find_wrapper(input.input_type, options)

  wrapper.render input
end
```

这个方法里做了三件事：

1. 找到 attribute 对应的控件（如 String Input, File Input, etc）
2. 找到对应的 wrapper（如 config.wrapper :horizontal ...）
3. 让 wrapper 来将表单控件进行包裹式的渲染，得到我们最终想要的效果

至此， SimpleForm 最基本的工作流我们已经掌握了，接下来，让我们深入 Wrapper 的内部。

## 从 SimpleForm.setup 开始

```ruby
SimpleForm.setup do |config|
  config.wrappers :horizontal_form, tag: 'div', class: 'form-group', error_class: 'has-error' do |b|
    #...
  end
end
```

`config.wrappers ...` 发生了什么事情， 即 SimpleForm 是如何维护这些 wrappers，其实秘密就藏在这里面。

```ruby
# lib/simple_form.rb
  # ...
  mattr_accessor :default_wrapper
  @@default_wrapper = :default
  @@wrappers = {} #:nodoc:
  # Define a new wrapper using SimpleForm::Wrappers::Builder
  # and store it in the given name.
  def self.wrappers(*args, &block)
    if block_given?
      options                 = args.extract_options!
      name                    = args.first || :default
      @@wrappers[name.to_s]   = build(options, &block)
    else
      @@wrappers
    end
  end
  # Builds a new wrapper using SimpleForm::Wrappers::Builder.
  def self.build(options = {})
    options[:tag] = :div if options[:tag].nil?
    builder = SimpleForm::Wrappers::Builder.new(options)
    yield builder
    SimpleForm::Wrappers::Root.new(builder.to_a, options)
  end
  #...
```

从上面的源代码可以看出，这些 wrapper 被放在了类变量 wrappers 这个 Hash 实例对象里了。
它是一个 wrapper_name 对应着 SimpleForm::Wrapper::Root 实例的形式，也就是说，我们可以通过这样的形式访问到我们刚配置的
horizontal_form 这个内容，我们到 rails console 试着把这个打印出来

```
Loading development environment (Rails 4.2.0)

Frame number: 0/5
[1] pry(main)>SimpleForm.wrappers['horizontal_form']
=> #<SimpleForm::Wrappers::Root:0x007fedd7263b18
 @components=
  [#<SimpleForm::Wrappers::Leaf:0x007fedd7298660 @namespace=:html5, @options={}>,
   #<SimpleForm::Wrappers::Leaf:0x007fedd72985e8 @namespace=:placeholder, @options={}>,
   #<SimpleForm::Wrappers::Leaf:0x007fedd7298598 @namespace=:maxlength, @options={}>,
   #<SimpleForm::Wrappers::Leaf:0x007fedd7298520 @namespace=:pattern, @options={}>,
   #<SimpleForm::Wrappers::Leaf:0x007fedd72984d0 @namespace=:min_max, @options={}>,
   #<SimpleForm::Wrappers::Leaf:0x007fedd7298458 @namespace=:readonly, @options={}>,
   #<SimpleForm::Wrappers::Leaf:0x007fedd72983b8 @namespace=:label, @options={:class=>"col-sm-3 control-label"}>,
   #<SimpleForm::Wrappers::Many:0x007fedd7263be0
    @components=
     [#<SimpleForm::Wrappers::Leaf:0x007fedd7298188 @namespace=:input, @options={:class=>"form-control"}>,
      #<SimpleForm::Wrappers::Single:0x007fedd7263fa0
       @component=#<SimpleForm::Wrappers::Leaf:0x007fedd7263f78 @namespace=:error, @options={}>,
       @components=[#<SimpleForm::Wrappers::Leaf:0x007fedd7263f78 @namespace=:error, @options={}>],
       @defaults={:tag=>"span", :class=>["help-block"]},
       @namespace=:error>,
      #<SimpleForm::Wrappers::Single:0x007fedd7263cf8
       @component=#<SimpleForm::Wrappers::Leaf:0x007fedd7263ca8 @namespace=:hint, @options={}>,
       @components=[#<SimpleForm::Wrappers::Leaf:0x007fedd7263ca8 @namespace=:hint, @options={}>],
       @defaults={:tag=>"p", :class=>["help-block"]},
       @namespace=:hint>],
    @defaults={:tag=>"div", :class=>["col-sm-9"]},
    @namespace=nil>],
 @defaults={:tag=>"div", :class=>["form-group"], :error_class=>"has-error", :maxlength=>false, :pattern=>false, :min_max=>false, :readonly=>false},
 @namespace=:wrapper,
 @options={:maxlength=>false, :pattern=>false, :min_max=>false, :readonly=>false}>
```

所以我们找到了关键的点了，那就是 `SimpleForm::Wrappers::Root` ，打开这个源代码文件之后，我们可以发现它继承了
`SimpleForm::Wrappers::Many`，并且主要的方法 `render` 也是在这个类里面。

## SimpleForm::Wrappers::Many

找到 render 方法

```ruby
def render(input)
  content = "".html_safe
  options = input.options

  components.each do |component|
    next if options[component.namespace] == false
    rendered = component.render(input)
    content.safe_concat rendered.to_s if rendered
  end

  wrap(input, options, content)
end
```

我们可以看到，它是将每个 component 通过传入 input （上面讲 simple_form_for 的那段代码的 input） 这个变量后渲染并拼接
所有 component 的输出内容后，通过 wrapper 方法，再将这个内容包括并输入渲染到 view 里去的。例如

```ruby
    b.use :label, class: 'control-label'
    b.use :input, class: 'form-control'
```

这段代码套在这个思路上就是

1. 输出 label 的 HTML 内容
2. 输出表单控件的 HTML 内容
3. 拼接这两段 HTML
4. 用一个 div 将这段拼接后的 HTML 包裹起来然后输出到 view 里

所以， SimpleForm 内部 wrapper 的工作原理就大致如此，但我们掌握得还远远不够，我们还需要深挖下去。<br/>
例如除了上面那两行代码，其他的代码是做什么的，又是怎么样做的。

```ruby
b.use :html5
b.use :placeholder
b.optional :maxlength
b.optional :pattern
```

例如从 Rails Console 里的输出我们还看到了几个类，它们又是什么。

- SimpleForm::Wrappers::Leaf
- SimpleForm::Wrappers::Single
- SimpleForm::Wrappers::Builder

这些我将在下一篇阐述清楚。
