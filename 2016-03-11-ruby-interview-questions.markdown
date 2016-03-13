---
layout: post
title: "Ruby Interview Questions"
date: 2016-03-11 14:46:03 +0800
comments: true
categories: ['ruby']
---

[原文链接](https://gist.github.com/ryansobol/5252653)

## What is a class ？

> classes hold **data**, have **methods** that interact with that data, and are used to **instantiate**(实例化) **objects**.

类是数据和操作数据的方法的组合，可以实例化成对象。

## What is an object?

> An instance of a class.<br/>
> To some, it's also the root class in ruby(Object).<br/>
> Classes themselves descend from(起源于) the Object root class.

对象是类的一个实例。Object 是 Ruby 的基类。

## What is a module? Can you tell me the difference between classes and modules?

> **Modules** serve as a mechanism for **namespaces**.<br/>

```ruby
module ANamespace
    class AClass
        def initialize
            puts "Another object, coming right up!"
        end
    end
end

ANamespace::AClass.new
#=> Another object, coming right up!
```

> Also, modules provides as a memchanism for multiple inheritance via **mix-ins** and **cannot be instantiated** like classes can.

```ruby
module AMixIn
    def who_am_i?
        puts "An existentialist, that's who."
    end
end

class DeepString < String
    extend AMixIn
end

DeepString.who_am_i?
#=> An existentialist, that's who.

AMixIn.new
#=> NoMethodError: undefined method ‘new’ for AMixIn:Module
```

模块化提供了命名空间的能力，不能够被实例化，但可以被 include 或者 extend 到类里，以达到代码分离和复用的目的。

## Can you tell me the three levels of method access control for classes and modules? What do they imply about the method?

> **All methods**, no matter the access control, can be **accesed within the class**.

> Public methods enforce no access control.<br/>
> Protected methods are only accessible to other objects of the same class.<br/>
> Private methods are only accessible within the context of the current object.

```ruby
class AccessLevel
    def something_interesting
        another = AccessLevel.new
        another.public_method
        another.protected_method
        another.private_method      # 调用失败，因为 self 不是 another 这个实例对象
    end

    def public_method
        puts "Public method. Nice to meet you."
    end

    protected
    def protected_method
        puts "Protected method. Sweet!"
    end

    private
    def private_method
        puts "Incoming exception!"
    end
end

class A
    def self.call_methods
        another = AccessLevel.new
        another.public_method
        another.protected_method    # 调用失败，因为 A 与 AccessLevel 不是同一个 class
        another.private_method      # 调用失败
    end
end

# AccessLevel.new.something_interesting
# 调用结果
# Public method. Nice to meet you.
# Protected method. Sweet!
# access_level.rb:6:in `something_interesting': private method `private_method' called for #<AccessLevel:0x007f918a0b1f80> (NoMethodError)
#     from access_level.rb:33:in `<main>'

# A.call_methods
# 调用结果
# Public method. Nice to meet you.
# access_level.rb:28:in `call_methods': protected method `protected_method' called for #<AccessLevel:0x007fafdb082108> (NoMethodError)
#     from access_level.rb:34:in `<main>'
```

简单来讲，

- public 方法，可以在任意地方被调用
- protected 方法，只要是相同的类里，都可以调用
- privated 方法，只可以在内部调用，不可以直接调用

## There are threee ways to invoke a method in ruby. Can you give me at least two?

```ruby
obj = Object.new

obj.object_id
obj.send(:object_id)
obj.method(:object_id).call
```

## Explain this ruby idiom: a ||= b

A common idiom that strong ruby developers use all the time.

```ruby
# a = b when a == false
# otherwise a remains unchanged
a || a = b
```

```ruby
a = 1
b = 2
a ||= b #=> a = 1
```

```ruby
a = nil
b = 2
a ||= b #=> a = 2
```

```ruby
a = false
b = 2
a ||= b #=> a = 2
```

## What does self mean?

> `self` always refers to the current object. But this question is more difficult than it seems because **Classes are also objects** in ruby.

```ruby
class WhatIsSelf
    def test
        puts "At the instance level, self is #{self}"
    end

    def self.test
        puts "At the class level, self is #{self}"
    end
end

WhatIsSelf.test 
 #=> At the class level, self is WhatIsSelf

WhatIsSelf.new.test 
 #=> At the instance level, self is #<WhatIsSelf:0x28190>
```

This short snippets indicates two things:

- at the class level, self is the **class**, in this case WhatIsSelf
- at the instance level, self is the **instance in context**, in this case the instance of WhatIsSelf at memory location 0x28190.

## What is Proc?

> Everyone usually confuses procs with blocks, but the strongest rubyist can grok the true meaning of the question.

> Essentially, Procs are anonymous methods (or nameless functions) containing code. They can be placed inside a variable and passed around like any other object or scalar value. They are created by Proc.new, lambda, and blocks (invoked by the yield keyword).

> Note: Procs and lambdas do have subtle, but important, differences in ruby v1.8.6. However, I wouldn't expect a candidate talk about these nitty-gritty details during an interview. 

```ruby
def three_ways proc, lambda, &block
    proc.call
    lambda.call
    yield
    puts "#{proc.inspect}\n#{lambda.inspect}\n#{block.inspect}"
end

anonymous = Proc.new { puts "I'm a Proc for sure." }
nameless  = lambda { puts "But what about me?" }

three_ways(anonymous, nameless) do
    puts "I'm a block, but could it be???"
end

# I'm a Proc for sure.
# But what about me?
# I'm a block, but could it be???
# #<Proc:0x007fea02096728@proc.rb:8>
# #<Proc:0x007fea02096700@proc.rb:9 (lambda)>
# #<Proc:0x007fea020966d8@proc.rb:11>
```

## Show me the money!

> Variable typing is one of those topics that everyone sort of understands it, but is hard to put it into words. I've iterated and improved the next series of questions to really test a senior level candidate's knowledge of static and dynamic typing. This is my best attempt so far.

**What is the primary difference in these two code snippets?**

```java
// Java
public boolean isEmpty(String s) {
  return s.length() == 0;
}
```

```ruby
# ruby
def empty?(s)
  return s.size == 0
end
```

> The Java method only accepts Strings as arguments and only returns a boolean while...

> The ruby method accepts any Object and could return anything, but in this case will return a boolean if executed without exceptions.

**What does this say about the advantages of ruby's dynamic (duck) typed system?**

> That ruby program use less code and are more flexible.

**What are some disadvantages (real and potential)?**

> Developers cannot be 100% certain that all arguments sent this empty? method will have a size method that is publicly accessible. Also, ruby is an interpreted language and it may take longer to run than compiled programs, such as Java, that are programmed similarly.

**What could a developer do to address these disadvantages?**

> She could write unit tests or specs to ensure her application behaves as intended. She could also profile her application with tools like the unix time command, the ruby Benchmark class, and the ruby library called ruby-prof.

> A cunning programmer would also argue that these two techniques ought to be used for both static and dynamic languages when developing complex systems.

## Wrapping things up

> To finish up with, I like to lob in some easy ones again. Plus I like to scratch my own curiosity about a candidates relationship with the ruby community.

在结束之前，我会去挖掘面试者在 Ruby 社区里的一些行为，如 ta 提过什么问题，回答了什么问题，关注了哪些人，哪些人关注了 ta。

**What are rubygems? Any favorites not including rails? Any that you've worked on personally?**

> rubygems is package manager software for ruby libraries (i.e. gems). The package manager has basic CRUD operations, dependency trees, and supports asynchronous communication between multiple gem servers.

**What is your favorite api resource for ruby?**

- http://guides.rubyonrails.org
- http://api.rubyonrails.org

## Your Own Questions?

I really want to know how you interview candidates for your ruby positions! Ruby is being used heavily at many companies all over the world for external and internal use alike. Please share your ideas with the rest of us!

## Separating the professional from the hobbyist

> Senior programmers should be able to give competent(合理的) answers for all questions. Junior programmers should answer some correct, but usually won't know them all.
