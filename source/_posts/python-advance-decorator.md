title: Python进阶——如何实现一个装饰器？
date: 2017-02-06 10:57:59
categories: Python
tags: [python, 装饰器]
---

在 Python 开发中，我们经常会看到使用装饰器的场景，例如日志记录、权限校验、本地缓存等等。

使用这些装饰器，给我们的开发带来了极大的便利，那么一个装饰器是如何实现的呢？

这篇文章我们就来分析一下，Python 装饰器的使用及原理。

# 一切皆对象

在介绍装饰器前，我们需要理解一个概念：在 Python 开发中，**一切皆对象**。

什么意思呢？

就是我们在开发中，无论是定义的变量（数字、字符串、元组、列表、字典）、还是方法、类、实例、模块，这些都可以称作**对象**。

怎么理解呢？在 Python 中，所有的对象都会有属性和方法，也就是说可以通过「.」去获取它的属性或调用它的方法，例如像下面这样：

```python
# coding: utf8

i = 10	# int对象
print id(i), type(i)
# 140703267064136, <type 'int'>

s = 'hello'	# str对象
print id(s), type(s), s.index('o')
# 4308437920, <type 'str'>, 4

d = {'k': 10}	# dict对象
print id(d), type(d), d.get('k')
# 4308446016, <type 'dict'>, 10

def hello():	# function对象
    print 'Hello World'
print id(hello), type(hello), hello.func_name, hello()
# 4308430192, <type 'function'>, hello, Hello World

hello2 = hello	 # 传递对象
print id(hello2), type(hello2), hello2.func_name, hello2()
# 4308430192, <type 'function'>, hello, Hello World

# 构建一个类
class Person(object):

    def __init__(self, name):
        self.name = name

    def say(self):
        return 'I am %s' % self.name

print id(Person), type(Person), Person.say
# 140703269140528, <type 'type'>, <unbound method Person.say>

person = Person('tom')		# 实例化一个对象
print id(person), type(person),
# 4389020560, <class '__main__.Person'>
print person.name, person.say, person.say()
# tom, <bound method Person.say of <__main__.Person object at 0x1059b2390>>, I am tom
```

我们可以看到，常见的这些类型：`int`、`str`、`dict`、`function`，甚至 `class`、`instance` 都可以调用 `id` 和 `type` 获得对象的唯一标识和类型。

例如方法的类型是 `function`，类的类型是 `type`，并且这些对象都是可传递的。

对象可传递会带来什么好处呢？

这么做的好处就是，我们可以实现一个「闭包」，而「闭包」就是实现一个装饰器的基础。

# 闭包

假设我们现在想统计一个方法的执行时间，通常实现的逻辑如下：

```python
# coding: utf8

import time

def hello():
    start = time.time() # 开始时间
    time.sleep(1)       # 模拟执行耗时
    print 'hello'
    end = time.time()   # 结束时间
    print 'duration time: %ds' % int(end - start) # 计算耗时

hello()

# Output:
# hello
# duration time: 1s
```

统计一个方法执行时间的逻辑很简单，只需要在调用这个方法的前后，增加时间的记录就可以了。

但是，统计这一个方法的执行时间这么写一次还好，如果我们想统计任意一个方法的执行时间，每个方法都这么写，就会有大量的重复代码，而且不宜维护。

如何解决？这时我们通常会想到，可以把这个逻辑抽离出来：

```python
# coding: utf8

import time

def timeit(func):   # 计算方法耗时的通用方法
    start = time.time()
    func()          # 执行方法
    end = time.time()
    print 'duration time: %ds' % int(end - start)

def hello():
    time.sleep(1)
    print 'hello'

timeit(hello)   # 调用执行
```

这里我们定义了一个 `timeit` 方法，而参数传入一个方法对象，在执行完真正的方法逻辑后，计算其运行时间。

这样，如果我们想计算哪个方法的执行时间，都按照此方式调用即可。

```python
timeit(func1)   # 计算func1执行时间
timeit(func2)   # 计算func2执行时间
```

虽然此方式可以满足我们的需求，但有没有觉得，本来我们想要执行的是 `hello` 方法，现在执行都需要使用 `timeit` 然后传入 `hello` 才能达到要求，有没有一种方式，既可以给原来的方法加上计算时间的逻辑，还能像调用原方法一样使用呢？

答案当然是可以的，我们对 `timeit` 进行改造：

```python
# coding: utf8

import time

def timeit(func):
    def inner():
        start = time.time()
        func()
        end = time.time()
        print 'duration time: %ds' % int(end - start)
    return inner

def hello():
    time.sleep(1)
    print 'hello'

hello = timeit(hello)	  # 重新定义hello
hello()					  # 像调用原始方法一样使用
```

请注意观察 `timeit` 的变动，它在内部定义了一个 `inner` 方法，此方法内部的实现与之前类似，但是，`timeit` 最终返回的不是一个值，而是 `inner` 对象。

所以当我们调用 `hello = timeit(hello)` 时，会得到一个方法对象，那么变量 `hello` 其实是 `inner`，在执行 `hello()` 时，真正执行的是 `inner` 方法。

我们对 `hello` 方法进行了重新定义，这么一来，`hello` 不仅保留了其原有的逻辑，而且还增加了计算方法执行耗时的新功能。

回过头来，我们分析一下 `timeit` 这个方法是如何运行的？

在 Python 中允许在一个方法中嵌套另一个方法，这种特殊的机制就叫做**「闭包」**，这个内部方法可以保留外部方法的作用域，尽管外部方法不是全局的，内部方法也可以访问到外部方法的参数和变量。

# 装饰器

明白了闭包的工作机制后，那么实现一个装饰器就变得非常简单了。

Python 支持一种装饰器语法糖「@」，使用这个语法糖，我们也可以实现与上面完全相同的功能：

```python
# coding: utf8

@timeit			# 相当于 hello = timeit(hello)
def hello():
    time.sleep(1)
    print 'hello'

hello()		# 直接调用原方法即可
```

看到这里，是不是觉得很简单？

这里的 `@timeit` 其实就等价于 `hello = timeit(hello)`。

装饰器本质上就是实现一个闭包，把一个方法对象当做参数，传入到另一个方法中，然后这个方法返回了一个增强功能的方法对象。

这就是装饰器的核心，平时我们开发中常见的装饰器，无非就是这种形式的变形而已。

<!-- more -->

# functools.wraps

现在我们已经得知，装饰器其实就是先定义好一个闭包，然后使用语法糖 `@` 来装饰方法，最后达到重新定义方法的作用。也就是说，最终我们执行的，其实是另外一个被添加新功能的方法。

还是拿上面的例子来看，虽然我们调用的方法还是 `hello`，但是最终执行的确是 `inner`，虽然功能和结果没有影响，但是执行的方法却被替换了，这会带来什么影响呢?

我们看下面的例子：

```python
# coding: utf8

@timeit
def hello():
    time.sleep(1)
    print 'hello'

print hello.__name__    # 输出 hello 方法的名字

# Output:
# inner
```

我们看到，虽然我们调用的是 `hello`，但是输出 `hello` 方法的名字却是 `inner`。

理想情况下，我们希望被装饰的方法，除了增加额外的功能之外，方法的属性信息依旧可以保留原来的，否则在使用中，可能存在一些隐患。

如何解决这个问题？

在 Python 内置的 `functools` 模块中，提供了一个 `wraps` 方法，专门来解决这个问题。

```python
# coding: utf8

import time
from functools import wraps

def timeit(func):
    @wraps(func)		# 使用 wraps 装饰内部方法inner
    def inner():
        start = time.time()
        func()
        end = time.time()
        print 'duration time: %ds' % int(end - start)
    return inner

@timeit
def hello():
    time.sleep(1)
    print 'hello'

print hello.__name__    # 输出 hello 方法的名字

# Output:
# hello
```

使用 `functools` 模块的 `wraps` 方法装饰内部方法 `inner` 后，我们再获取 `hello` 的属性，都能得到来自原方法的信息了。

# 装饰带参数的方法

上面的例子，我们实现了一个最简单的装饰器，装饰的方法 `hello` 是没有参数的，如果 `hello` 需要参数，此时如何装饰器如何实现呢？

```python
# coding: utf8

import time
from functools import wraps

def timeit(func):
    @wraps(func)
    def inner(name):		# inner 也需加对应的参数
        start = time.time()
        func(name)
        end = time.time()
        print 'duration time: %ds' % int(end - start)
    return inner

@timeit
def hello(name):		# 加了一个参数
    time.sleep(1)
    print 'hello %s' % name

hello('张三')
```

由于最终调用的是 `inner` 方法，被装饰的方法 `hello` 如果想加参数，那么对应的 `inner` 也添加相应的参数就可以了。

但是，我们定义的 `timeit` 是一个通用的装饰器，现在为了适应 `hello` 的参数，而在 `inner` 中加了一个参数，那如果要装饰的方法，有 2 个甚至更多参数，怎么办？难道要在 `inner` 中加继续加参数吗？

这当然是不行的，我们需要一个一劳永逸的方案来解决。我们改造如下：

```python
# coding: utf8

import time
from functools import wraps

def timeit(func):
    @wraps(func)
    def inner(*args, **kwargs):  # 使用 *args, **kwargs 适应所有参数
        start = time.time()
        func(*args, **kwargs)    # 传递参数给真实调用的方法
        end = time.time()
        print 'duration time: %ds' % int(end - start)
    return inner

@timeit
def hello(name):
    time.sleep(1)
    print 'hello %s' % name

@timeit
def say(name, age):
    print 'hello %s %s' % (name, age)

@timeit
def say2(name, age=20):
    print 'hello %s %s' % (name, age)

hello('张三')
say('李四', 25)
say2('王五')
```

我们把 `inner` 方法的参数改为了 `*args, **kwargs`，然后调用真实方法时传入参数`func(*args, **kwargs)`，这样一来，我们的装饰器就可以装饰有任意参数的方法了，这个装饰器就变得非常通用了。

# 带参数的装饰器

被装饰的方法有参数，装饰器内部方法使用 `*args, **kwargs` 来适配。但我们平时也经常看到，有些装饰器也是可以传入参数的，这种如何实现呢？

```python
# coding: utf8

import time
from functools import wraps

def timeit(prefix):		# 装饰器可传入参数
    def decorator(func):	# 多一层方法嵌套
        @wraps(func)
        def wrapper(*args, **kwargs):
            start = time.time()
            func(*args, **kwargs)
            end = time.time()
            print '%s: duration time: %ds' % (prefix, int(end - start))
        return wrapper
    return decorator

@timeit('prefix1')
def hello(name):
    time.sleep(1)
    print 'hello %s' % name
```

实际上，装饰器方法多加一层内部方法就可以了。

我们在 `timeit` 中定义了 2 个内部方法，然后让 `timeit` 可以接收参数，返回 `decorator` 对象，而在 `decorator` 方法中再返回 `wrapper` 对象。

通过这种方式，带参数的装饰器由 2 个内部方法嵌套就可以实现了。

# 类实现装饰器

上面几个例子，都是用方法实现的装饰器，除了用方法实现装饰器，还有没有其他方法实现？

答案是肯定的，我们还可以用类来实现一个装饰器，也可以达到相同的效果。

```python
# coding: utf8

import time
from functools import wraps

class Timeit(object):
    """用类实现装饰器"""
    def __init__(self, prefix):
        self.prefix = prefix

    def __call__(self, func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            start = time.time()
            func(*args, **kwargs)
            end = time.time()
            print '%s: duration time: %ds' % (self.prefix, int(end - start))
        return wrapper

@Timeit('prefix')
def hello():
    time.sleep(1)
    print 'hello'

hello()     # 调用被装饰的方法
```

用类实现一个装饰器，与方法实现类似，只不过用类利用了 `__init__` 和 `__call__` 方法，其中 `__init__` 定义了装饰器的参数，`__call__` 会在调用 `Timeit` 对象的方法时触发。

你可以这样理解：`t = Timeit('prefix')` 会调用 `__init__`，而调用 `t(hello)` 会调用 `__call__(hello)`。

是不是很巧妙？这些都归功于 Python 的魔法方法，我会在后面的文章中，单独讲解关于 Python 魔法方法的实现原理。

# 装饰器使用场景

知道了如何实现一个装饰器，那么我们可以在不修改原方法的情况下，给方法增加额外的功能，这就非常适合给方法集成一些通用的逻辑，例如记录日志、记录执行耗时、本地缓存、路由映射等功能。

下面我列举几个用装饰器实现的常用功能，供你参考。

## 记录调用日志

```python
import logging
from functools import wraps

def logging(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        # 记录调用日志
        logging.info('call method: %s %s %s', func.func_name, args, kwargs)
        return func(*args, **kwargs)
    return wrapper
```

## 记录方法执行耗时

```python
from functools import wraps

def timeit(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        start = time.time()
        result = func(*args, **kwargs)
        duration = int(time.time() - start) # 统计耗时
        print 'method: %s, time: %s' % (func.func_name, duration)
        return result
    return wrapper
```

## 记录方法执行次数

```python
from functools import wraps

def counter(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        wrapper.count = wrapper.count + 1   # 累计执行次数
        print 'method: %s, count: %s' % (func.func_name, wrapper.count)
        return func(*args, **kwargs)
    wrapper.count = 0
    return wrapper
```

## 本地缓存

```python
from functools import wraps

def localcache(func):
    cached = {}
    miss = object()
    @wraps(func)
    def wrapper(*args):
        result = cached.get(args, miss)
        if result is miss:
            result = func(*args)
            cached[args] = result
        return result
    return wrapper
```

## 路由映射

```python
class Router(object):

    def __init__(self):
        self.url_map = {}

    def register(self, url):
        def wrapper(func):
            self.url_map[url] = func
        return wrapper

    def call(self, url):
        func = self.url_map.get(url)
        if not func:
            raise ValueError('No url function: %s', url)
        return func()

router = Router()

@router.register('/page1')
def page1():
    return 'this is page1'

@router.register('/page2')
def page2():
    return 'this is page2'

print router.call('/page1')
print router.call('/page2')
```

除此之外，装饰器还能用在权限校验、上下文处理等场景中。你可以根据自己的业务场景，开发对应的装饰器。

# 总结

这篇文章，我们主要讲解了 Python 装饰器是如何实现的。

在讲解之前，我们先理解了 Python 中一切皆对象的概念，基于这个概念，我们理解了实现装饰器的本质：闭包。闭包可以传入一个方法对象，然后返回一个增强功能的方法对象，然后配合 Python 提供的 `@` 语法糖，我们就可以实现一个装饰器。

实现了简单的装饰器之后，我们还可以继续改进，通过在装饰器中嵌套多个内部方法的方式，让装饰器装饰带有参数的方法，还可以让装饰器也接收参数，非常方便。除了用方法实现一个装饰器之外，我们还可以通过 Python 的魔法方法，用类来实现一个装饰器。

最后，我们分析了使用装饰器的常见场景，主要包括权限校验、日志记录、方法调用耗时、本地缓存、路由映射等功能。

使用装饰器的好处是，可以把我们的业务逻辑和控制逻辑分离开，业务开发人员可以更好地关注业务逻辑，装饰器可以方便地实现对控制逻辑的统一定义，这种方式也遵循了设计模式中的单一职责。

