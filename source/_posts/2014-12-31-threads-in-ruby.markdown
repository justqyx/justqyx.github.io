---
layout: post
title: "Threads in Ruby（译）"
date: 2014-12-31 14:27:04 +0800
comments: true
categories: [ruby]
---

[这是原文](http://www.sitepoint.com/threads-ruby/)

Ruby 有着许多吸引开发者的 cool features，例如在运行时能够创建类、修改特定对象的行为、使用 ObjectSpace 监控内存中类的数量以及大量的测试套件。这些东西使得开发者的生活更加轻松。今天我们将会讨论在计算机科学里最重要的概念之一：线程，以及 Ruby 是如何支持线程的。

## 简介

首先，让我们来定义“线程”（thread），请参考 [wikipedia](http://en.wikipedia.org/wiki/Thread_\(computing\))

> In computer science, a thread of execution is the smallest sequence of programmed instructions that can be managed independently by an operating system scheduler. A thread is a light-weight process.

线程可以堪称是一个轻量级（light-weight）的进程。
多个线程属于同个进程，并且共享着进程的资源（resources）。
这就是为什么在有些情况下使用多线程是比较经济（economical）的。

现在让我们来看看线程对于我们来说是多么有用。

## Basic Example

看看下面的代码

```ruby
def calculate_sum(arr)
  sum = 0
  arr.each do |item|
    sum += item
  end
  sum
end
 
@items1 = [12, 34, 55]
@items2 = [45, 90, 2]
@items3 = [99, 22, 31]
 
puts "items1 = #{calculate_sum(@items1)}"
puts "items2 = #{calculate_sum(@items2)}"
puts "items3 = #{calculate_sum(@items3)}"
```

上面的代码输出的结果为

```ruby
items1 = 101
items2 = 137
items3 = 152
```

这是一个非常简单的程序，有助于弄明白我们为什么要使用多线程。在上面的代码里，我们有三个数组，并且要计算出它们的和，但有一个问题，我们无法在 items1 算出结果之前，得到 items2 的结果，
对于 items3 也同样存在这个问题。现在，让我们修改一下代码来进一步说明我想表达的东西。

```ruby
def calculate_sum(arr)
  sleep(2)
  sum = 0
  arr.each do |item|
    sum += item
  end
  sum
end
```

在上面的代码中，我们增加了一个 `sleep(2)` 指令，让程序暂停2秒钟之后再继续运行。
这意味着，items1 会在2秒后才得到结果，items2 会在4秒后得到结果，而 items3 将会在6秒后得到结果。
这并不是我们想要的。

上面的三个数组，对与彼此都没有依赖，所以它们是能够独立地进行元素和的计算，这时候多线程就可以派上用场了。

多线程使得我们可以将当前的程序分割成为几个不同的、能够独立运行的上下文执行体（execution contexts）。
现在，让我们来将上面的程序修改成为一个多线程的版本。

```ruby
def calculate_sum(arr)
  sleep(2)
  sum = 0
  arr.each do |item|
    sum += item
  end
  sum
end
 
@items1 = [12, 34, 55]
@items2 = [45, 90, 2]
@items3 = [99, 22, 31]
 
threads = (1..3).map do |i|
  Thread.new(i) do |i|
    items = instance_variable_get("@items#{i}")
    puts "items#{i} = #{calculate_sum(items)}"
  end
end
threads.each {|t| t.join}
```

我们把每一个数组元素和的计算工作，都交给一个线程来做，通过 `Thread.new` 的方式来创建线程，
并且把数组元素和的计算的代码段放到代码块中里去，这样我们一共新建了3个线程。
现在让我们来看看运行的结果，注意每次的运行结果顺序可能有所不同。

```ruby
items2 = 137
items3 = 152
items1 = 101
```

从运行结果来看，我们不是在4秒后收到items2的结果，6秒钟之后收到items3的结果，而是在2秒钟之后收到所有数组的结果。这让我们看到了多线程的魔力，我们是在并行地计算所有数组的元素和，而不是一次只计算一个。这是非常棒的，因为我们节省了4秒钟的时间，提高了程序的性能和效率。

## 竞态（Race Conditions）

每一个功能其实都是有代价的，多线程是好东西，但是如果你在写多线程的代码的时候，你需要了解**竞态条件**这个东西，那么什么是竞态呢？请参考 [wikipedia](http://en.wikipedia.org/wiki/Race_condition#Software)

> Race conditions arise in software when separate computer processes or threads of execution depend on some shared state. Operations upon shared states are critical sections that must be mutually exclusive. Failure to obey this rule opens up the possibility of corrupting the shared state.

简单地来讲，如果我们有一些共享的数据，这些数据能够被多线程使用的话，那么我们的数据在所有的线程执行完毕之后还应该保持正确不出错。

**例子**

```ruby
class Item
  class << self; attr_accessor :price end
  @price = 0
end
 
(1..10).each { Item.price += 10 }
 
puts "Item.price = #{Item.price}"
```

我们创建了一个简单的 Item 类，包含了一个类变量 price。`Item.price` 的值在一个循环力不断地增加。
执行这个程序，然后你将会看到一下的输出

```ruby
Item.price = 100
```

现在，让我们来看看一个多线程的版本

```ruby
class Item
  class << self; attr_accessor :price end
  @price = 0
end
 
threads = (1..10).map do |i|
  Thread.new(i) do |i|
    item_price = Item.price # Reading value
    sleep(rand(0..2))
    item_price += 10        # Updating value
    sleep(rand(0..2))
    Item.price = item_price # Writing value
  end
end
 
threads.each {|t| t.join}
 
puts "Item.price = #{Item.price}"
```

我们的 Item 类还是一样的，但是，我们已经改变了 price 的递增方式。我们在代码里使用了 sleep 来向你展示在并发中可能出现的问题。多跑几次程序，你将会得到不同的结果。

```ruby
Item.price = 40
```

多次运行我们的程序下来，我们会发现，结果不再正确，并且结果是变化的。
输出的不再是 100，你看到的可能是30、40或者70等。
这就是竞态所导致的结果。

## 互斥体

为了解决竞态所产生的问题，我们必须要控制程序，
当一个线程正在工作时，另外一个线程必须等待，直到当前的工作进程完成工作。
这个行为我们称为互斥，下面我们将阐述如何去使用互斥体。

Ruby 已经为我们使用互斥体提供了一个非常简洁的方式，如下：

```ruby
class Item
  class << self; attr_accessor :price end
  @price = 0
end
 
mutex = Mutex.new
 
threads = (1..10).map do |i|
  Thread.new(i) do |i|
    mutex.synchronize do
      item_price = Item.price # Reading value
      sleep(rand(0..2))
      item_price += 10        # Updating value
      sleep(rand(0..2))
      Item.price = item_price # Writing value
    end
  end
end
 
threads.each {|t| t.join}
 
puts "Item.price = #{Item.price}"
```

现在运行这个程序，你将会看到

```ruby
Item.price = 100
```

这是因为 `mutex.synchronize`，在任何时候，每一个都有且仅有一个线程能够执行 `mutex.synchronize` 里的代码块，其他的线程必须等待直到当前的工作线程执行完毕。

这样，我们的代码就是**线程安全**了。

Rails 是线程安全的，当多个线程尝试去运行同样的代码是，它使用了 Mutex 类的一个实例来避免
竞态的出现。请查看 `Rack::Lock` 这个中间件里的代码，你会发现它使用了 `@mutext.lock` 来阻塞其他尝试想要运行相同代码的线程。如果你想要了解 Rails 里更多关于多线程的细节，
请阅读我的[这篇文章](http://www.sitepoint.com/config-threadsafe/)。
另外，你也可以访问 [Ruby Mutext](http://www.ruby-doc.org/core-2.0.0/Mutex.html) 这个类有关的文档。

## 不同 Ruby 版本的线程类型

在 Ruby 1.8 版本里，Ruby 的实现是**绿色线程**（green threads）。绿色线程是由解释器来实现和控制的，下面是一些关于绿色线程的优点和缺点：

**优点**

- Cross platform (managed by the VM)
- Unified behavior / control
- Lightweight -> faster, smaller memory footprint

**缺点**

- Not optimized
- Limited to 1 CPU
- A blocking I/O blocks all threads

到了 Ruby 1.9 版本后，Ruby 使用的是原生线程（native threads）。原生线程的意思是每个线程都是由 Ruby 创建的，并且直接映射到操作系统级别的线程。每一门现代编程语言都实现了 native threads，所以使用 native threads 是更加直接和合理的。下面是一些关于 native threads 的优点：

**优点**

- Run on multiple processors
- Scheduled by the OS
- Blocking I/O operations don’t block other threads

虽然在 Ruby 1.9 里使用的是 native threads，但是即使我们的处理器是多核的，
每次运行时都仍然只有一个线程能运行。这是因为 MRI 的 GIL (Global Interpreter Lock) 
或者说 GVL (Global VM Lock)。在 Ruby 中，如果有一个线程正在运行，
那么 GIL 就会阻止其他线程运行。但是 Ruby 足够聪明来切换到其他正在等待的线程，
如果当前正在运行的线程正在等待一些 I/O 操作完成的话。

在 Ruby 中使用线程是非常容易的，但是我们必须谨慎地处理好并发可能产生地问题。
我希望你能喜欢这篇文章并且在 Ruby 中能够更好地使用好线程。
