title: Python技术进阶——上下文管理器
date: 2018-04-17 11:33:10
tags: [python]
---

# with语句

我们操作文件时，一般的写法：

```python
f = open('a.txt')   # 打开文件
for line in f:
    print line      # 输出内容
f.close()           # 关闭文件
```

这么写会产生一个问题，如果在打开文件后，输出内容或其他操作发生异常，就会导致不会关闭文件句柄，没有释放资源。

修改如下：

```python
f = open('a.txt')   # 打开文件
try:
    for line in f:
        print line      # 输出内容
finally:
    f.close()           # 关闭文件
```

这么写的好处是能够保证文件资源始终会被释放，但代码结构难免有些繁琐，可读性较差。

使用`with`就能有效解决这些问题：

```python
with open('a.txt') as f:
    for line in f:
        print line
```

使用`with`语句，能够在执行完`with`语句块后，自动关闭文件资源，并且保证了代码的结构干净清晰，可读性较好。

# 上下文管理器协议

那么`with`的实现机制是怎样的？

`with`语句是从Python2.5开始引入的一种与异常处理相关的功能，（2.5 版本中要通过`from __future__ import with_statement`导入后才可以使用），但从2.6版本开始缺省可用。

`with`语句适用于对资源进行访问的场合，确保不管使用过程中是否发生异常都会执行必要的**清理**操作，释放资源。

多用于在读取文件、线程锁中使用后自动释放等场景。

`with`语句格式如下：

```python
with context_expression [as target(s)]:
    with-body
```

要想实现`with`语法，只需要实现上下文管理器协议即可：

- `__enter__`：在进入`with`语句块之前调用，返回值赋给`target`
- `__exit__`：在退出`with`语句块之后调用，主要做异常处理操作

<!-- more -->

# 自定义上下文管理器

下面我们来实现自己的上下文管理器：

```python
class Test(object):

    def __enter__(self):
        print '__enter__'
        return 1

    def __exit__(self, exc_type, exc_value, exc_tb):
        print 'exc_type: %s' % exc_type
        print 'exc_value: %s' % exc_value
        print 'exc_tb: %s' % exc_tb

with Test() as t:
    print 't --> %s' % t
    
# 输出：
# __enter__
# t --> 1
# exc_type: None
# exc_value: None
# exc_tb: None
```
从输出结果我们看到，我们定义了一个类，并实现了上下文管理器协议，这个类对象也就有了使用`with`语法的能力：

- `__enter__`在进入`with`语句块之前调用，返回值赋给了`t`
- `__exit__`在执行完`with`语句块之后调用
- 如果语句块内发生了异常，则3个参数会被依次赋值：**异常类型**、**异常对象**、**异常堆栈信息**

我们来看在发生异常时，`__exit__`方法的参数分别是什么：

```python
with Test() as t:
    a = 1 / 0   # 这里会发生异常
    print 't --> %s' % t
```

再次执行代码，输出结果：

```python
__enter__
exc_type: <type 'exceptions.ZeroDivisionError'>
exc_value: integer division or modulo by zero
exc_tb: <traceback object at 0x10d66dd88>
Traceback (most recent call last):
  File "base.py", line 16, in <module>
    a = 1 / 0
ZeroDivisionError: integer division or modulo by zero
```

我们看到了`__exit__`被调用后，输出了异常的相关信息。

我们回到最初的代码，在操作文件时，使用`with`之所以能够自动关闭文件资源，是因为内置的文件对象实现了上下文管理器协议，并在`__enter__`返回文件句柄，`__exit__`中实现文件资源关闭，并在发生异常时抛出异常。


# contextlib模块

说到上下文管理器，不得不说Python标准库的`contextlib`模块，它更方便的帮我们实现了上下文管理器协议，我们只需要关注业务逻辑即可。

`contextlib`模块包含了3个装饰器：

- `contextmanager`
- `nested`
- `closing`

## contextmanager

```python
from contextlib import contextmanager

@contextmanager
def test():
    print 'before'
    yield 'hello'
    print 'after'

with test() as a:
    print a

# before
# hello
# after
```

我们用一个`生成器`和`contextmanager`装饰器实现了上下文管理器类似的功能。

- `yield`之前相当于执行了`__enter__`
- `yield`相当于`__enter__`的返回值，赋值给了`as`之后的变量`a`
- `yield`之后相当于执行了`__exit__`

使用这个装饰器，我们不用在写一个类，只需要写一个方法即可实现同样的功能。



`contextlib`的实现原理是怎样的？我们来看`contextlib`模块的实现。

> 源码地址：https://github.com/python/cpython/blob/2.7/Lib/contextlib.py

```python
"""Utilities for with-statement contexts.  See PEP 343."""

import sys
from functools import wraps
from warnings import warn

__all__ = ["contextmanager", "nested", "closing"]

class GeneratorContextManager(object):
    """Helper for @contextmanager decorator."""

    def __init__(self, gen):
        self.gen = gen

    def __enter__(self):
        try:
            return self.gen.next()
        except StopIteration:
            raise RuntimeError("generator didn't yield")

    def __exit__(self, type, value, traceback):
        if type is None:
            try:
                self.gen.next()
            except StopIteration:
                return
            else:
                raise RuntimeError("generator didn't stop")
        else:
            if value is None:
                value = type()
            try:
                self.gen.throw(type, value, traceback)
                raise RuntimeError("generator didn't stop after throw()")
            except StopIteration, exc:
                return exc is not value
            except:
                if sys.exc_info()[1] is not value:
                    raise


def contextmanager(func):
    """@contextmanager decorator.
    Typical usage:
        @contextmanager
        def some_generator(<arguments>):
            <setup>
            try:
                yield <value>
            finally:
                <cleanup>
    This makes this:
        with some_generator(<arguments>) as <variable>:
            <body>
    equivalent to this:
        <setup>
        try:
            <variable> = <value>
            <body>
        finally:
            <cleanup>
    """
    @wraps(func)
    def helper(*args, **kwds):
        return GeneratorContextManager(func(*args, **kwds))
    return helper


@contextmanager
def nested(*managers):
    """Combine multiple context managers into a single nested context manager.
   This function has been deprecated in favour of the multiple manager form
   of the with statement.
   The one advantage of this function over the multiple manager form of the
   with statement is that argument unpacking allows it to be
   used with a variable number of context managers as follows:
      with nested(*managers):
          do_something()
    """
    warn("With-statements now directly support multiple context managers",
         DeprecationWarning, 3)
    exits = []
    vars = []
    exc = (None, None, None)
    try:
        for mgr in managers:
            exit = mgr.__exit__
            enter = mgr.__enter__
            vars.append(enter())
            exits.append(exit)
        yield vars
    except:
        exc = sys.exc_info()
    finally:
        while exits:
            exit = exits.pop()
            try:
                if exit(*exc):
                    exc = (None, None, None)
            except:
                exc = sys.exc_info()
        if exc != (None, None, None):
            # Don't rely on sys.exc_info() still containing
            # the right information. Another exception may
            # have been raised and caught by an exit method
            raise exc[0], exc[1], exc[2]


class closing(object):
    """Context to automatically close something at the end of a block.
    Code like this:
        with closing(<module>.open(<arguments>)) as f:
            <block>
    is equivalent to this:
        f = <module>.open(<arguments>)
        try:
            <block>
        finally:
            f.close()
    """
    def __init__(self, thing):
        self.thing = thing
    def __enter__(self):
        return self.thing
    def __exit__(self, *exc_info):
        self.thing.close()
```

源码逻辑也比较简单，`contextmanager`装饰的大致实现逻辑：

- 定义`GeneratorContextManager`类，构造方法接受了一个生成器`gen`
- 这个类实现了上下文管理器协议`__enter__`和`__exit__`
- `__enter__`执行生成器，相当于执行代码到`yield`之前
- `__enter__`返回生成器的执行结果，相当于`yield`的结果
- `__exit__`再次执行生成器，相当于`yield`之后的代码逻辑，并对指定异常进行处理
- `contextmanager`装饰器直接返回了`GeneratorContextManager`对象，并把包装的`func`传入其构造方法



不过有一点需要我们注意，在`contextmanager`装饰器的注释中有举例：

** 如果被装饰的方法可能发生异常，那么我们需要在自己的方法中进行异常处理，否则将不会执行`yield`之后的代码。**



发生异常时，必须按下面这种方式处理：

```python
from contextlib import contextmanager

@contextmanager
def test():
    print 'before'
    try:
        yield 'hello'
        a = 1 / 0   # 这里发生异常时，必须自己处理异常逻辑，否则不会向下执行
    finally:
        print 'after'

with test() as a:
    print a
```

## nested

如果你有多个`with`语句块需要执行，使用这个装饰器可以合并执行：

```python
with nested(A(), B(), C()) as (x, y, z):
    # with body
```

**但我们在源码注释中看到，这个方法已经被标注为已过时，不建议使用，因为标准库的`with`语法已经支持多个语句嵌套执行：**


```python
with open('a.txt') as f1, open('b.txt', 'w') as f2:
    for line in f1:
        f2.write(line)
```

## closing

`closing`装饰器用于装饰已经实现`close`方法的资源对象：

```python
from contextlib import closing

class Test():

    def close(self):
        print 'closed'

with closing(Test()):   # with块执行结束后，自动执行close方法
    print 'do something'
    
# do something
# closed
```

# 使用场景

上下文管理器具体用在什么场景？举几个常用的使用例子。

## 基于redis的分布式锁

```python
from contextlib import contextmanager

@contextmanager
def lock(redis, lock_key, expire):
    try:
        locked = redis.set(lock_key, 'locked', expire)
        yield locked
    finally:
        redis.delete(lock_key)

# 业务调用，with代码块执行结束后，自动释放锁资源
with lock(redis, 'biz_locked', 3) as locked:
    if not locked:
        return
    # do something ...
```

## 基于redis的pipeline

```python
from contextlib import contextmanager

@contextmanager
def pipeline(redis):
    pipe = redis.pipeline()
    try:
        yield pipe
        pipe.execute()
    except Exception as exc:
        pipe.reset()
            
# 业务调用，with代码块执行结束后，自动执行execute方法
with pipeline(redis) as pipe:
    pipe.set('key1', 'a', 30)
    pipe.zadd('key2', 'a', 1)
    pipe.sadd('key3', 'a')
```

我们在开发中可以把前置和后置的资源操作通过上下文管理器实现，抽离前置和后置逻辑，关注具体的业务即可，代码结构和可读性也大大提高。

