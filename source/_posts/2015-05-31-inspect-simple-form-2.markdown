---
layout: post
title: "Inspect SimpleForm (2)"
date: 2015-05-31 01:24:37 +0800
comments: true
categories: ["rails"]
---

上一篇阐述了 SimpleForm 的基本原理，以及阐述了 Wrapper 内部的一个基本的渲染过程，
这一篇，我将基于上文中的 :horizontal_form 这个 wrapper 例子来阐述清楚 Wrapper 的整个渲染过程。

## Wrapper 包含着对 Component 的一个管理。

上一篇我们在 Rails Console 输出了下面这么一段内容，从这段内容我们可以看到，
我们的 Root 实例中有两个实例变量： @components 和 @defaults。

{% include_code 20150531/simple_form.rb %}

@components 包含了一些 Leaf、Single、Many，这些东西将决定着最后的输出内容，例如

```html
<label class="col-sm-3">Email</label>
<div class="col-sm-9">
    <input type="email" class="form-control" />
</div>
```

而 @defaults 一看就知道，它是整个表单控件最外层的包裹。

```html
<div class="form-group">
  <!--- ...... -->
</div>
```

我们上篇就已经提到了 Wrapper 内部是如何渲染的，即递归地调用 component.render 得到每个 component 的输出内容，
然后拼接起来，最后用 wrap 完成最后的包裹后输出。

```ruby
# lib/simple_form/wrappers/many.rb
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

现在让我们来详细看一看两件事情

1. input 是什么
2. component.render(input) 的执行过程

## Input

前面我们也提到过 f.input 这一段代码，请阅读 `lib/simple_form/form_builder.rb` 这个文件里的代码，
通过阅读，循着 find_input -> find_mapping 这两个方法，最终它是根据 attribute 的类型来找到对应的
类并实例化，例如是 String 类型，就返回一个 StringInput 类的实例，其他的如 Boolean、Numeric、File 都是如此。
我们从源码文件目录里的 `lib/simple_form/inputs` 也可以看到一系列的 Input，而这些 Input 全部都继承与 Base 这个类。

但是先到此为此，我们现在只需要了解 input 是什么，至于内部还有什么东西，我们需要在了解 component.render(input)
之后再来看会更好，顺着渲染的流程走更容易理解。

## component.render(input)

同样的，在上文中的 `lib/simple_form/form_builder.rb` 这个文件里我们继续寻找 component 是什么，
继续阅读，循着 find_wrapper -> find_wrapper_mapping 这两个方法，最终我们可以发现，它根据 input.input_type 
来找到合适 wrapper，即 SimpleForm.wrapper_mappings[input_type]，而 SimpleForm.wrapper_mappings 是我们在
项目里所配置的。即 `config/initializers/simple_form_bootstrap3.rb` 里的这么一段代码

```ruby
SimpleForm.setup do |config|
  # ...
  config.wrapper_mappings = {
    check_boxes: :vertical_radio_and_checkboxes,
    radio_buttons: :vertical_radio_and_checkboxes,
    file: :vertical_file_input,
    boolean: :vertical_boolean,
    datetime: :multi_select,
    date: :multi_select,
    time: :multi_select
  }
end
```

因此，它所找到的就是我们一开始所配置的 wrapper，他们全部保存在 SimpleForm.wrappers 这个类变量里。
现在让我们来看一看三个例子。

## SimpleForm::Inputs::Base

在进入例子之前，有必要阐述 SimpleForm::Inputs::Base 这个类，它是所有 SimpleForm 抽象出来的表单控件的一个基类。

```ruby
module SimpleForm
  module Inputs
    class Base
      include ERB::Util
      include ActionView::Helpers::TranslationHelper

      extend I18nCache

      include SimpleForm::Helpers::Autofocus
      include SimpleForm::Helpers::Disabled
      include SimpleForm::Helpers::Readonly
      include SimpleForm::Helpers::Required
      include SimpleForm::Helpers::Validators

      include SimpleForm::Components::Errors
      include SimpleForm::Components::Hints
      include SimpleForm::Components::HTML5
      include SimpleForm::Components::LabelInput
      include SimpleForm::Components::Maxlength
      include SimpleForm::Components::MinMax
      include SimpleForm::Components::Pattern
      include SimpleForm::Components::Placeholders
      include SimpleForm::Components::Readonly

      # ...
    end
  end
end
```

从上面的代码我们可以看到，其 include 了许多 Components，这些 Components 其实是为 SimpleForm::Inputs::StringInput、
SimpleForm::Inputs::FileInput 这些真正的表单控件注入一些方法，这些方法可能是用来改变 Input 实例的一些配置，
也可能是生成一段 HTML 文本，下面的例子会阐述这么一点。

## b.use :input

从之前的讲解我们知道 `b.use :input` 将会生成一个 SimpleForm::Wrappers::Root 实例，
然后其 @compoennts 就会存储着与此相关的 SimpleForm::Wrappers::Leaf 实例。

假如我们这里的 input 是一个 SimpleForm::Inputs::StringInput 的一个实例，而 component 就是
SimpleForm::Wrappers::Leaf 的一个实例，那么我们来看看 component.render 里的这个方法定义：

```ruby
# lib/simple_form/wrappers/leaf.rb
def render(input)
  # 我们先前在 Rails Console 中打出来的文本里有这么一段
  # <SimpleForm::Wrappers::Leaf:0x007fedd7298188 @namespace=:input, @options={:class=>"form-control"}>
  # 所以这里的 @namespace 的值为 :input
  method = input.method(@namespace)

  if method.arity == 0
    ActiveSupport::Deprecation.warn(SimpleForm::CUSTOM_INPUT_DEPRECATION_WARN % { name: @namespace })

    method.call
  else
    method.call(@options)
  end
end
```

我们可以看到，这个 render 方法其实是让 input 这个 StringInput 实例去调用自己的 input 方法，
找到 StringInput 的 input 方法定义：

```ruby
# lib/simple_form/inputs/strin_input.rb
def input(wrapper_options = nil)
  unless string?
    input_html_classes.unshift("string")
    input_html_options[:type] ||= input_type if html5?
  end

  merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

  @builder.text_field(attribute_name, merged_input_options)
end
```

所以我们可以看到，最后的输出内容其实是使用 @builder (SimpleForm::FormBuilder 的一个实例) 的 text_field 方法
来生成一个类似这样的 `<input type="text" name='resource[attribute_name]' />` 一段文本。

## b.use :label

同理， Label 标签的生成也是类似。 SimpleForm::Component::Label 的里 label 方法定义如下：

```ruby
  def label(wrapper_options = nil)
    label_options = merge_wrapper_options(label_html_options, wrapper_options)

    if generate_label_for_attribute?
      @builder.label(label_target, label_text, label_options)
    else
      template.label_tag(nil, label_text, label_options)
    end
  end
```

也是让 @builder 调用 label 来生成类似这样的 `<label class="col-sm-3">Email</label>` 一段文本。

## b.use :placeholder

placeholder，html5，readonly 这一类的 Component，并没有实际的 HTML 文本输出，而是修改 input 这种表单控件的
一些配置，我们来看看 placholder 的代码。

```ruby
# lib/simple_form/components/placeholders.rb
module SimpleForm
  module Components
    # Needs to be enabled in order to do automatic lookups.
    module Placeholders
      def placeholder(wrapper_options = nil)
        input_html_options[:placeholder] ||= placeholder_text
        nil
      end

      def placeholder_text
        placeholder = options[:placeholder]
        placeholder.is_a?(String) ? placeholder : translate_from_namespace(:placeholders)
      end
    end
  end
end
```

我们可以看到，它修改的是 input 这个 StringInput 实例的 input_html_options 里的 placeholder 配置，然后返回 nil，
即没有 HTML 文本输出。

之所以能修改，是因为 component.render(input) 在这里是让 input 自己去调用自己的 placeholder 方法，
而 SimpleForm::Inputs::StringInput 继承了 SimpleForm::Inputs::Base， SimpleForm::Inputs::Base 这个类引用了
众多的 Components，因此 input 实例有了这些 components 所定义的方法。

## 总结

第一篇我们主要阐述了 SimpleForm 在 Rails 渲染表单这整个工作流的一个基本原理，
而这一篇我们主要从 SimpleForm::Wrappers、 SimpleForm::Inputs、SimpleForm::Components 这几个 namespace 下面
相关的类阐述了这几者在 wrapper 对表单控件进行包裹式地渲染这个过程所扮演的角色。

至此，你可以通过详细阅读 SimpleForm::Inputs::Base 的代码和一些 Components 的代码，并做一些练习，
即可完全掌握如何去编写一个 SimpleForm 的扩展。
