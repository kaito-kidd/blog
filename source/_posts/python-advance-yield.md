title: Python技术进阶——如何正确使用yield？
date: 2018-05-21 12:20:28
categories: Python
tags: [python]
---

在 Python 开发中，`yield` 关键字的使用其实较为频繁，例如大集合的生成，简化代码结构、协程与并发都会用到它。

但是，你是否真正了解 `yield` 的运行过程呢？

这篇文章，我们就来看一下 `yield` 的运行流程，以及在开发中哪些场景适合使用 `yield`。

# 生成器

如果在一个方法内，包含了 `yield` 关键字，那么这个函数就是一个「生成器」。

生成器其实就是一个特殊的迭代器，它可以像迭代器那样，迭代输出方法内的每个元素。

如果你还不清楚「迭代器」是什么，可以参考我写的这篇文章：[Python进阶——迭代器和可迭代对象有什么区别？](http://kaito-kidd.com/2018/04/18/python-advance-iterator-generator/)。

我们来看一个包含 `yield` 关键字的方法：

```python
# coding: utf8

# 生成器
def gen(n):
    for i in range(n):
        yield i

g = gen(5)      # 创建一个生成器
print(g)        # <generator object gen at 0x10bb46f50>
print(type(g))  # <type 'generator'>

# 迭代生成器中的数据
for i in g:
    print(i)
    
# Output:
# 0 1 2 3 4
```

注意，在这个例子中，当我们执行 `g = gen(5)` 时，`gen` 中的代码其实并没有执行，此时我们只是创建了一个「生成器对象」，它的类型是 `generator`。

然后，当我们执行 `for i in g`，每执行一次循环，就会执行到 `yield` 处，返回一次 `yield` 后面的值。

这个迭代过程是和迭代器最大的区别。

换句话说，如果我们想输出 5 个元素，在创建生成器时，这个 5 个元素其实还并没有产生，什么时候产生呢？只有在执行 `for` 循环遇到 `yield` 时，才会依次生成每个元素。

此外，生成器除了和迭代器一样实现迭代数据之外，还包含了其他方法：

- `generator.__next__()`：执行 `for` 时调用此方法，每次执行到 `yield` 就会停止，然后返回 `yield` 后面的值，如果没有数据可迭代，抛出 `StopIterator` 异常，`for` 循环结束
- `generator.send(value)`：外部传入一个值到生成器内部，改变 `yield` 前面的值
- `generator.throw(type[, value[, traceback]])`：外部向生成器抛出一个异常
- `generator.close()`：关闭生成器

通过使用生成器的这些方法，我们可以完成很多有意思的功能。

<!-- more -->

## __next__

先来看生成器的 `__next__` 方法，我们看下面这个例子。

```python
# coding: utf8

def gen(n):
    for i in range(n):
        print('yield before')
        yield i
        print('yield after')

g = gen(3)      # 创建一个生成器
print(g.__next__())  # 0
print('----')
print(g.__next__())  # 1
print('----')
print(g.__next__())  # 2
print('----')
print(g.__next__())  # StopIteration

# Output:
# yield before
# 0
# ----
# yield after
# yield before
# 1
# ----
# yield after
# yield before
# 2
# ----
# yield after
# Traceback (most recent call last):
#   File "gen.py", line 16, in <module>
#     print(g.__next__())  # StopIteration
# StopIteration
```

在这个例子中，我们定义了 `gen` 方法，这个方法包含了 `yield` 关键字。然后我们执行 `g = gen(3)` 创建一个生成器，但是这次没有执行 `for` 去迭代它，而是多次调用 `g.__next__()` 去输出生成器中的元素。

我们看到，当执行 `g.__next__()`时，代码就会执行到 `yield` 处，然后返回 `yield` 后面的值，如果继续调用 `g.__next__()`，注意，你会发现，这次执行的开始位置，是上次 `yield` 结束的地方，并且它还保留了上一次执行的上下文，继续向后迭代。

这就是使用 `yield` 的作用，在迭代生成器时，每一次执行都可以保留上一次的状态，而不是像普通方法那样，遇到 `return` 就返回结果，下一次执行只能再次重复上一次的流程。

生成器除了能保存状态之外，我们还可以通过其他方式，改变其内部的状态，这就是下面要讲的 `send` 和 `throw` 方法。

## send

上面的例子中，我们只展示了在 `yield` 后有值的情况，其实还可以使用 `j = yield i` 这种语法，我们看下面的代码：

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

此时如果我们执行下面的代码：

```python
for i in gen():
    print(i)
    time.sleep(1)
```

输出结果会是 `1 2 4 8 16 32 64 ...` 一直循环下去， 直到我们杀死这个进程才能停止。

这段代码一直循环的原因在于，它无法执行到 `j == -1` 这个分支里 `break` 出来，如果我们想让代码执行到这个地方，如何做呢？

这里就要用到生成器的 `send` 方法了，**`send` 方法可以把外部的值传入生成器内部，从而改变生成器的状态。**

代码可以像下面这样写：

```python
g = gen()   # 创建一个生成器
print(g.__next__())  # 1
print(g.__next__())  # 2
print(g.__next__())  # 4
# send 把 -1 传入生成器内部 走到了 j = -1 这个分支
print(g.send(-1))   # StopIteration 迭代停止
```

当我们执行 `g.send(-1)` 时，相当于把 `-1` 传入到了生成器内部，然后赋值给了 `yield` 前面的 `j`，此时 `j = -1`，然后这个方法就会 `break` 出来，不会继续迭代下去。

## throw

外部除了可以向生成器内部传入一个值外，还可以传入一个异常，也就是调用 `throw` 方法：

```python
# coding: utf8

def gen():
    try:
        yield 1
    except ValueError:
        yield 'ValueError'
    finally:
        print('finally')

g = gen()   # 创建一个生成器
print(g.__next__()) # 1
# 向生成器内部传入异常 返回ValueError
print(g.throw(ValueError))

# Output：
# 1
# ValueError
# finally
```

这个例子创建好生成器后，使用 `g.throw(ValueError)` 的方式，向生成器内部传入了一个异常，走到了生成器异常处理的分支逻辑。

## close

生成器的 `close` 方法也比较简单，就是手动关闭这个生成器，关闭后的生成器无法再进行操作。

```python
>>> g = gen()
>>> g.close() # 关闭生成器
>>> g.__next__() # 无法迭代数据
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
StopIteration
```

`close` 方法我们在开发中使用得比较少，了解一下就好。

# 使用场景

了解了 `yield` 和生成器的使用方式，那么 `yield` 和生成器一般用在哪些业务场景中呢？

下面我介绍几个例子，分别是大集合的生成、简化代码结构、协程与并发，你可以参考这些使用场景来使用 `yield`。

## 大集合的生成

如果你想生成一个非常大的集合，如果使用 `list` 创建一个集合，这会导致在内存中申请一个很大的存储空间，例如想下面这样：

```python
# coding: utf8

def big_list():
    result = []
    for i in range(10000000000):
        result.append(i)
    return result

# 一次性在内存中生成大集合 内存占用非常大
for i in big_list():
    print(i)
```

这种场景，我们使用生成器就能很好地解决这个问题。

因为生成器只有在执行到 `yield` 时才会迭代数据，这时只会申请需要返回元素的内存空间，代码可以这样写：

```python
# coding: utf8

def big_list():
    for i in range(10000000000):
        yield i

# 只有在迭代时 才依次生成元素 减少内存占用
for i in big_list():
    print(i)
```

## 简化代码结构

我们在开发时还经常遇到这样一种场景，如果一个方法要返回一个 `list`，但这个 `list` 是多个逻辑块组合后才能产生的，这就会导致我们的代码结构变得很复杂：

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
    print(item)
```

这种情况下，我们只能在每个逻辑块内使用 `append` 向 `list` 中追加元素，代码写起来比较啰嗦。

此时如果使用 `yield` 来生成这个 `list`，代码就简洁很多：

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
    print(i)
```

使用 `yield` 后，就不再需要定义 `list` 类型的变量，只需在每个逻辑块直接 `yield` 返回元素即可，可以达到和前面例子一样的功能。

我们看到，使用 `yield` 的代码更加简洁，结构也更清晰，另外的好处是只有在迭代元素时才申请内存空间，降低了内存资源的消耗。

## 协程与并发

还有一种场景是 `yield` 使用非常多的，那就是「协程与并发」。

如果我们想提高程序的执行效率，通常会使用多进程、多线程的方式编写程序代码，最常用的编程模型就是「生产者-消费者」模型，即一个进程 / 线程生产数据，其他进程 / 线程消费数据。

在开发多进程、多线程程序时，为了防止共享资源被篡改，我们通常还需要加锁进行保护，这样就增加了编程的复杂度。

在 Python 中，除了使用进程和线程之外，我们还可以使用「协程」来提高代码的运行效率。

什么是协程？

简单来说，**由多个程序块组合协作执行的程序，称之为「协程」。**

而在 Python 中使用「协程」，就需要用到 `yield` 关键字来配合。

可能这么说还是太好理解，我们用 `yield` 实现一个协程生产者、消费者的例子：

```python
# coding: utf8

def consumer():
    i = None
    while True:
        # 拿到 producer 发来的数据
        j = yield i 
        print('consume %s' % j)

def producer(c):
    c.__next__()
    for i in range(5):
        print('produce %s' % i)
        # 发数据给 consumer
        c.send(i)
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
...
```

这个程序的执行流程如下：

1. `c = consumer()` 创建一个生成器对象
2. `producer(c)` 开始执行，`c.__next()__` 会启动生成器 `consumer` 直到代码运行到 `j = yield i` 处，此时 `consumer` 第一次执行完毕，返回
3. `producer` 函数继续向下执行，直到 `c.send(i)` 处，这里利用生成器的 `send` 方法，向 `consumer` 发送数据
4. `consumer` 函数被唤醒，从 `j = yield i` 处继续开始执行，并且接收到 `producer` 传来的数据赋值给 `j`，然后打印输出，直到再次执行到 `yield` 处，返回
5. `producer` 继续循环执行上面的过程，依次发送数据给 `cosnumer`，直到循环结束
6. 最终 `c.close()` 关闭 `consumer` 生成器，程序退出

在这个例子中我们发现，程序在 `producer` 和 `consumer` 这 2 个函数之间**来回切换**执行，相互协作，完成了生产任务、消费任务的业务场景，最重要的是，整个程序是在**单进程单线程**下完成的。

这个例子用到了上面讲到的 `yield`、生成器的 `__next__`、`send`、`close` 方法。如果不好理解，你可以多看几遍这个例子，最好自己测试一下。

我们使用协程编写生产者、消费者的程序时，它的好处是：

- 整个程序运行过程中无锁，不用考虑共享变量的保护问题，降低了编程复杂度
- 程序在函数之间来回切换，这个过程是用户态下进行的，不像进程 / 线程那样，会陷入到内核态，这就减少了内核态上下文切换的消耗，执行效率更高

所以，**Python 的 `yield` 和生成器实现了协程的编程方式，为程序的并发执行提供了编程基础。**

Python 中的很多第三方库，都是基于这一特性进行封装的，例如 `gevent`、`tornado`，它们都大大提高了程序的运行效率。

# 总结

总结一下，这篇文章我们主要讲了 `yield` 的使用方式，以及生成器的各种特性。

生成器是一种特殊的迭代器，它除了可以迭代数据之外，在执行时还可以保存方法中的状态，除此之外，它还提供了外部改变内部状态的方式，把外部的值传入到生成器内部。

利用 `yield` 和生成器的特性，我们在开发中可以用在大集成的生成、简化代码结构、协程与并发的业务场景中。

Python 的 `yield` 也是实现协程和并发的基础，它提供了协程这种用户态的编程模式，提高了程序运行的效率。