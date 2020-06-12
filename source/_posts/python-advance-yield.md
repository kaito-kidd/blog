title: Python技术进阶——yield
date: 2018-05-21 12:20:28
tags: [python]
---

> `yield`关键字在Python中开发中使用较为频繁，它为我们某些开发场景提供了便利，这篇文章我们来深入讲解`yield`相关知识。

# 生成器

在讲`yield`之前，我们先复习一下迭代器与生成器的区别，可以参考我之前写的文章：[Python技术进阶——迭代器、可迭代对象、生成器](http://kaito-kidd.com/2018/04/18/python-advance-iterator-generator/)。

简单总结如下：

- 实现了迭代器协议`__iter__`和`next/__next__`方法的对象被称作迭代器
- 迭代器可以使用`for`执行输出每个元素
- 生成器是一种特殊的迭代器

一个函数内，如果包含了`yield`关键字，这个函数就是一个生成器。

```python
# coding: utf8

def gen(n):
    # 生成器函数
    for i in range(n):
        yield i

g = gen(5)      # 创建一个生成器
print g         # <generator object gen at 0x10bb46f50>
print type(g)   # <type 'generator'>
# 生成器迭代
for i in g:
    print i
    
# Output:
# 0 1 2 3 4
```

注意，在执行`g = gen(5)`时，函数中的代码并没有执行，此时我们只是创建了一个生成器对象，他的类型是`generator`。

当执行`for i in g`时，每执行一次循环，直到执行到`yield`时，返回`yield`后面的值。

换句话说，我们想输出5个元素，在创建生成器时，这个5个元素此时并没有产生，什么时候产生呢？在执行`for`循环遇到`yield`时，此时才会逐个生成每个元素。

生成器除了实现迭代器协议可以进行迭代之外，还包含一些方法：

- `generator.next()`：每次执行到遇到`yield`后返回，直到没有`yield`，抛出`StopIterator`异常
- `generator.send(value)`：将`yield`的值设置为`value`
- `generator.throw(type[, value[, traceback]])`：向生成器当前状态抛出一个异常
- `generator.close()`：关闭生成器

<!-- more -->

## next

为了更便于你理解只有在遇到`yield`时才产生值，我们可以改写程序如下：

```python
# coding: utf8

def gen(n):
    # 生成器函数
    for i in range(n):
        print 'yield before'
        yield i
        print 'yield after'

g = gen(3)      # 创建一个生成器
print g.next()  # 0
print '-' * 5
print g.next()  # 1
print '-' * 5
print g.next()  # 2
print '-' * 5
print g.next()  # StopIteration

# Output:
# yield before
# 0
# ----------
# yield after
# yield before
# 1
# ----------
# yield after
# yield before
# 2
# ----------
# yield after
# Traceback (most recent call last):
#   File "test.py", line 17, in <module>
#     print g.next()
# StopIteration
```

只有在执行`g.next()`时，才会产生值，并且生成器会保留上下文信息，在再次执行`g.next()`时继续返回。

## send

上面的例子只展示了在`yield`后有值的情况，其实也可以使用`j = yield i`这种语法，我们看下面的代码：

```python
# coding: utf8

def gen():
    i = 1
    while True:
        j = yield i
        i *= 2
        if j == -1:
            break
```

如果我们执行：

```python
for i in g():
    print i

# Output:
# 1
# 2
# 4
# 8
# 16
# 32
# 64
# ...
```

这个生成器函数相当于无限生成每次翻倍的数字，一直循环下去，直到我们杀死进程才能停止。

在上面的代码你会发现，貌似永远执行不到`j == -1`这个分支里，如果想让代码执行到这，如何做？

这里就要用到生成的`send`方法，它可以在外部传入一个值，使得改变生成器当前的状态。

```python
g = gen()           # 创建一个生成器
print g.next()      # 1
print g.next()      # 2
print g.next()      # 4
print g.send(-1)    # j = -1 程序退出
```

执行`g.send(-1)`，相当于把-1传入生成器，赋值给了`yield`之前的`j`，从而改变了生成器内部的执行状态。

## throw

除了可以向生成器内部传入指定值，还可以传入指定异常：

```python
# coding: utf8

def gen():
    try:
        yield 1
    except ValueError:
        yield 'ValueError'
    finally:
        print 'finally'

g = gen()           # 创建一个生成器
print g.next()      # 1
print g.throw(ValueError)   # 向内部传入异常，返回ValueError，并打印出finally
```

`throw`与`next`类似，但是以传入异常的方式使生成器执行，`throw`一般在开发中很少被用到。

# 使用场景

上面简单介绍了生成器和`yield`的使用方式，那么`yield`一般在哪些场景中被使用？

## 大列表的生成

如果你想生成一个非常大的列表，使用`list`时只能一次性在内存中创建出这个列表，这可能导致内存资源申请非常大，甚至有可能被操作系统杀死进程。

直接在内存中生成一个大列表：

```python
# coding: utf8

def big_list():
    result = []
    for i in range(10000000000):
        result.append(i)
    return result

# 一次性在内存中生成大列表 内存占用非常大
for i in big_list():
    print i
```

由于生成器只有在执行到`yield`时才会产生值，我们可以使用这个特性优雅地解决这类问题：

```python
# coding: utf8

def big_list():
    for i in range(10000000000):
        yield i

# 大列表只有在迭代时 才逐个生成元素 减少内存占用
for i in big_list():
    print i
```

## 简化代码结构

如果一个函数中要产生一个列表，但这个列表可能是多个逻辑块组合后才能产生的，这就会导致我们的代码结构变得复杂：

```python
# coding: utf8

def gen_list():
    # 多个逻辑块 组成生成一个列表
    result = []
    for i in range(10):
        result.append(i)
    for j in range(5):
        result.append(j * j)
    for k in [100, 200, 300]:
        result.append(k)
    return result
    
for item in gen_list():
    print item
```

使用`yield`生成这个列表：

```python
# coding: utf8

def gen_list():
    # 多个逻辑块 使用yield 生成一个列表
    for i in range(10):
        yield i
    for j in range(5):
        yield j * j
    for k in [100, 200, 300]:
        yield k
        
for item in gen_list():
    print item
```

我们看到，在第一个例子中，我们只能先声明一个`list`类型的变量，然后在每个逻辑块中产生元素，之后`append`到结果中，最终`return`返回这个结果。

而使用`yield`后，只需在每个逻辑块需要产生并返回元素时，使用`yield`即可，代码更加简洁，结构更清晰，同时还拥有减少内存占用的好处。

## 协程与并发

我们都比较熟悉进程、线程，一般为了提高程序的运行效率，会使用多进程、多线程进行开发，最常用的编程模型就是**生产者-消费者**模型，即一个进程/线程生产数据，其他进程/线程消费数据。

在多进程、多线程开发时，为了防止资源被篡改，往往会进行加锁，这就导致了编程的复杂程度。

在Python开发中，也提供了多进程和多线程的开发方式，但由于解释器`GIL`的存在，多线程开发并不能提高执行效率。所以在Python中，更多提高执行效率的编程模型是：协程。

什么是协程？简单来说，由多个程序块组合协作执行的程序，称之为协程。可能这么说还是太过模糊，我们用`yield`实现一个生产者-消费者的例子：

```python
# coding: utf8

def consumer():
    i = None
    while True:
        j = yield i     # 拿到producer发来的数据
        print 'consume %s' % j

def producer(c):
    c.next()
    for i in range(5):
        print 'produce %s' % i
        c.send(i)   # 发数据给consumer
    c.close()

c = consumer()
producer(c)

# Output:
# produce 0
# consume 0
# produce 1
# consume 1
# produce 2
# consume 2
# produce 3
# consume 3
# produce 4
# consume 4
```

整个程序执行流程如下：

- `c = consumer()`创建一个生成器对象
- `producer(c)`开始执行代码，`c.next()`会启动生成器`consumer`直到代码运行到`j = yield i`处，此时`consumer`第一次执行完毕，返回
- `producer`函数继续向下执行，直到`c.send(i)`，利用生成器的`send`方法，向`consumer`发送数据
- `consumer`函数被唤醒，从`j = yield i`处开始执行，并接收`producer`传来的数据赋值给`j`，然后打印输出，直到再次执行到`yield`处，返回
- `producer`继续执行循环，执行上面的过程，逐个发送数据给`cosnumer`，直到循环结束
- 最终`c.close()`关闭`consumer`生成器，程序退出

在上面的代码中我们发现，程序运行时，在`producer`和`consumer`这2个函数之间来回切换执行，完成了生产任务、消费任务的场景，而且整个程序运行在单进程单线程下。

这其中的原理就是利用了生成器的`yield`关键字以及生成器的`next`和`send`方法。

这么做的好处在于：

- 整个程序运行过程中无锁，编程复杂度降低
- 程序在函数之间来回切换，是在用户态下进行的，不像进程/线程切换陷入内核状态，没有内核态的上下文切换，损耗更小，执行效率更高

Python的生成器实现了协程的编程方式，为程序的并发执行提供了编程基础。

Python的很多第三方包都是基于这一特性进行封装的，例如`gevent`、`tornado`，它们都大大提高了程序的运行效率。

# 总结

这篇文章主要讲了Python中生成器与`yield`的相关知识，总结如下：

- 生成器在生成很大的列表的场景，能够节省内存空间的占用
- 在复杂逻辑块生成列表元素时，使用`yield`能极大简化代码结构
- 生成器的特性为Python的并发编程模型——协程，提供了编程基础




