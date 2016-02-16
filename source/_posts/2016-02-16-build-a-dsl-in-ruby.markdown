---
layout: post
title: "Building a DSL in Ruby"
date: 2016-02-16 10:23:27 +0800
comments: true
categories: ['dsl', 'ruby']
---

DSL（领域专用语言，Domain Specific Language）不是一个新的技术概念，并且构建是困难的。
其至少包含两个内容：

1. 一个用于解析 DSL 的 Parser
2. 使用 DSL 写出来的程序

## 构建一个简单的 Quiz DSL

最终我们想达到的效果便是，当运行程序之后，会让用户做选择题，并且统计回答正确的题数。

```
Who was the first president of the USA?
1 - Fred Flintstone
2 - Martha Washington
3 - George Washington
4 - George Jetson
Enter your answer:
```

期望的表达语法

```ruby
# questions.qm

question "Who was the first president of the USA?"
wrong 'Fred Flintstone'
wrong 'Martha Washington'
right 'George Washington'
wrong 'George Jetson'

question 'Who is buried in Grant\'s tomb?'
right 'U. S. Grant'
wrong 'Cary Grant'
wrong 'Hugh Grant'
wrong 'W. T. Grant'
```

一个简单的 Parser

```
# quizm.rb

def question text
  puts "Just read a question: #{text}"
end

def wrong text
  puts "Just read a correct answer: #{text}"
end

def right text
  puts "Just read an incorrect answer: #{text}"
end

load './questions.qm'
```

编译语言里的 Parse Phase，最终都是为了得到 AST（抽象语法树）这样类型的数据结构，所以，我们
先定义我们的数据结构：`Question` 和 `Answer`

``` ruby
# quiz.rb
class Answer
  attr_reader :text, :correct
  def initialize text, correct
    @text = text
    @correct = correct
  end
end

class Question
  def initialize text
    @text = text
    @answers = []
  end

  def add_answer answer
    @answers << answer
  end

  def ask
    puts ""
    puts "Question: #{@text}"
    @answers.each_with_index do |answer, index|
      puts "#{index+1} - #{answer.text}"
    end
    print "Enter answer: "
    answer = gets.to_i - 1
    return @answers[answer].correct
  end
end
```

构建简单的 vm，赋予程序存储 DSL 内容的能力

```ruby
# quiz.rb
require 'singleton'

class Quiz
  def initialize
    @questions = []
  end

  def add_question question
    @questions << question
  end

  def last_question
    @questions.last
  end

  def run_quiz
    count = 0
    @questions.each { |q| count += 1 if q.ask }
    puts "You got #{count} answers correct out of #{@questions.size}"
  end
end
```

载入、解析、存储、运行

```ruby
require './quiz'

def question text
  Quiz.instance.add_question Question.new(text)
end

def wrong text
  Quiz.instance.last_question.add_answer Answer.new(text, true)
end

def right text
  Quiz.instance.last_question.add_answer Answer.new(text, false)
end

load './questions.qm'

Quiz.instance.run_quiz
```

## Gif 效果图

{% img /downloads/images/dsl.gif %}

## Ref

- [Building a DSL in Ruby](http://jroller.com/rolsen/entry/building_a_dsl_in_ruby)
