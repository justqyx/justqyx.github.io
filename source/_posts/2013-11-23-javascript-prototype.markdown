---
layout: post
title: JavaScript Prototype
date: 2013-11-23 10:36
comments: true
categories: ['frontend']
---

虽然 Javascript 一开始就为浏览器而生，但是从现在开始，请不要把 Javascript 和浏览器联系起来，
就仅仅把它当成是一门只要有解释器(如谷歌的V8引擎)就可以运行的东西。

在你的机器装上 `nodejs`，然后执行 `node example.js`，即可调试 js 代码。

## 原型程序设计

> 原型程式设计或称为基于原型的编程、原型编程，是面向对象编程的子系统和一种方式。

> 在原型编程中，类不是实时的，而且行为重用（通常认为继承自基于类的语言）是通过复制已经存在的原型对象的过程实现的。

> 这个模型一般被认为是 classless、面向原型、或者是基于实例的编程。

__与基于类的模型比较__

> 在基于类的编程当中，对象总共有两种类型。
> 类定义了对象的基本布局和函数特性，而接口是“可以使用的”对象，它基于特定类的样式。
> 在此模型中，类表现为行为和结构的集合，就接口持有对象的数据而言，对所有接口来说是相同的。
> 区分规则因而首先是基于结构和行为，而后是状态。

> 原型编程的主张者经常争论说基于类的语言提倡使用一个关注分类和类之间关系开发模型。
> 与此相对，原型编程看起来提倡程序员关注一系列对象实例的行为，而之后才关心如何将这些对象划分到最近的使用方式相似的原型对象，而不是分成类。
> 因为如此，很多基于原型的系统提倡运行时原型的修改，而只有极少数基于类的面向对象系统（比如第一个动态面向对象的系统 Smalltalk）允许类在程序运行时被修改。

## 对象构造

> 在基于原型的系统中构造对象有两种方法：通过`复制已有的对象`或者 `扩展nihilo(空的)对象`创建。
> 因为大多数系统提供了不同的复制方法，扩展 nihilo 对象的方式鲜为人知。

> 提供扩展 nihilo 对象创建的系统，允许对象从空白中创建而无需从已有的原型中复制。
> 这样的系统提供特殊的文法用以指定新对象的行为和属性，无需参考已存在的对象。

> 在很多原型语言中，通常有一个 Object 原型，其中有普遍需要的方法。它被用作所有其他对象的最终原型。
> 扩展 nihilo 对象创建可以保证新对象不会被顶级对象的命名空间污染。

> 如，在 Mozilla 的 Javscript 实现中，可以通过设置一个新创建对象的 \_proto\_ 属性为 null 来做到。

## 模拟创建类

Javascript 是基于原型的编程语言，没有包含对内置类的实现。

但是也可以轻易地模拟出经典的类。 因为有 `构造函数` 和 `new运算符`。

任何 Javascript 函数可以当成构造函数来使用，构造函数必须使用 `new运算符` 作为前缀来创建新的实例。

```javascript
var Person = function(name){
  this.name = name;
}

// 实例化一个 Person
var alice = new Person("alice");

// 检查这个实例
assert(alice instanceof Person);
```

__new 运算符的作用__

简单来讲：`new 运算符` 改变了函数执行的上下文，同时改变了 return 语句的行为。

当使用 `new` 来调用构造函数时，执行上下文就变成一个空的上下文(如在浏览器中就是从 window 全局对象 变成一个空的上下文 )，这个上下文代表了新生成的实例。

因此 this 关键字指向当前创建的实例。

默认情况下，如果你的构造函数中没有返回任何内容，就会返回 this -- 当前的上下文。

## 理解 prototype

简单地来讲，`prototype` 就是用来存储实例对象公共的属性或是行为。

例如，狗和猫，都是动物。于是：

```javascript
var Animal = function(sound){
  this.sound = sound;
}

Animal.prototype.public_name = "动物";

Animal.prototype.belongs_to = function(){
  console.log(this.public_name);
}

var cat = new Animal("喵喵");
var dog = new Animal("旺旺");

cat.belongs_to(); // => 动物
dog.belongs_to(); // => 动物
```

__方法查找__

其实，prototype 是一个模板对象，它所有的属性或行为被用作初始化一个新对象。

当访问属性或是行为时，查找的顺序是：`对象 -> 对象的prototype`，

所以，上面的 cat 和 dog 其实调用的都是 prototype 里的方法。

所以，当你重写 `cat 的 belongs_to` 这个行为时，是不会对 `dog 的 belongs_to` 造成任何影响的。

```javascript
var Animal = function(sound){
  this.sound = sound;
}

Animal.prototype.public_name = "动物";

Animal.prototype.belongs_to = function(){
  console.log(this.public_name);
}

var cat = new Animal("喵喵");
var dog = new Animal("旺旺");

cat.belongs_to = function(){
  console.log("啦啦啦啦");
};

cat.belongs_to(); // => 啦啦啦啦
dog.belongs_to(); // => 动物
```

## 理解 inherit
  
(下面提及的继承，都是指针对构造函数的继承，不是非构造函数的继承)

其实继承也是很简单的，在 Javascript 更多地体现为 `prototype 的链接关系`。

现在，我们把上面的 `Animal 实例化对象` 也抽象成 `Cat 类`，并且让 Cat 将 Animal 的属性和行为都继承过来。

```javascript
var Animal = function(){};
var Cat = function(){}

Cat.prototype = Animal.prototype;
```

这样，Animal.prototype 里所有的属性和行为，都会被 Cat 继承。

__但是，直接这样写是有问题的__

1. 只要修改了 `Cat.prototype` 都会影响到 `Animal.prototype`
2. Cat.constructor(即 Cat.prototype.constructor) 变成了 Animal.constructor(即 Animal.prototype.constructor)

(注：每个构造函数，也是一个对象，并且其默认的 Obj.prototype.constructor 就是构造函数本身)。

所以，我们要这么写：

```javascript
var Animal = function(){};
var Cat = function(){}

var F = function(){};
F.prototype = Animal.prototype;
Cat.prototype = new F();

// 将构造函数重新指回 Cat
Cat.prototype.constructor = Cat;
```

F 是空对象，几乎不占用内存。并且，对 `Cat.prototype` 的修改， 只会直接反映到 `new F()` 这个`匿名实例对象`上，

而不会到 `Animal.prototype` 上。

__我们也来包装包装__

```javascript
var NB = {
  extend: function(child, parent){
    var F = function(){}
    F.prototype = parent.prototype;
    child.prototype = new F();
    child.prototype.constructor = child;
  };
}

NB.extend(Cat, Animal);
```

## 总结

1. 任何函数都是 `构造函数`
2. 通过设置 `prototype` 属性来实现基本的代码重用
3. 继承，其实是通过 `prototype` 的链接来实现的，只是在这过程中，要注意不要影响原来的 “类” 和各自的 `constructor `

__题外话__

Javascript 就是弱化了 class 的概念，但是在现代的编程中，随着我们的 Web 应用越来越庞大，编写易读易维护的 Javascript 代码就越来越重要了。

出现了许多好用的东西，如 jQuery，还有许多的 MVC框架，如：Backbone, EmberJS, AugularJS。


## References

- [Javascript继承机制的设计思想](http://www.ruanyifeng.com/blog/2011/06/designing_ideas_of_inheritance_mechanism_in_javascript.html)
- [构造函数的继承](http://www.ruanyifeng.com/blog/2010/05/object-oriented_javascript_inheritance.html)
