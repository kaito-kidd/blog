title: Python技术进阶——装饰器
date: 2017-02-06 10:57:59
categories: Python
tags: [python, 装饰器]
---

> 在Python开发中，经常会看到使用装饰器的场景，那如何正确定义和使用装饰器呢？
>
> 本篇文章就来讲解一下装饰器的使用及原理。

# 一切皆对象

在介绍装饰器前，我们需要理解一个概念，在Python开发中，**一切皆对象**。什么意思呢？

就是我们在开发中，不管是定义的变量（数字、字符串、元组、列表、字典）、方法、类、实例、模块，都是对象。

怎么理解呢？在Python中，所有的对象都会有属性或者方法，也就是说可以通过`.`去获取它的属性或调用它的方法，例如：

```python
i = 10	# 构建int对象
print id(i), type(i)
# 140703267064136, <type 'int'>

s = 'hello'	# 构建str对象
print id(s), type(s), s.index('o')
# 4308437920, <type 'str'>, 4

d = {'k': 10}	# 构建dict对象
print id(d), type(d), d.get('k')
# 4308446016, <type 'dict'>, 10

def hello():	# 构建function对象
    print 'Hello World'
print id(hello), type(hello), hello.func_name, hello()
# 4308430192, <type 'function'>, hello, Hello World

hello2 = hello	# 传递对象
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

Python中的对象都可以通过调用`id`和`type`获得自己的唯一标识和类型，例如方法的类型是`function`，类的类型是`type`，在上面代码也可看出这些对象都是可以进行传递的。

我们现在已经知道，方法也是对象，也有自己的方法和属性，而且是可传递执行的。

# 闭包

假如我们现在想统计一个函数执行的时间，通常编写代码逻辑大致如下：

```python
# coding: utf8

import time

def hello():
    start = time.time()
    time.sleep(1)
    print 'hello'
    end = time.time()
    print 'duration time: %ds' % int(end - start)

hello()

# Output:
# hello
# duration time: 1s
```

统计这一个方法的执行时间这么写一次还好，如果我想统计指定任意方法的执行时间，其实每个方法计算时间的逻辑都相同，如果每个方法都这么写，就会有大量的重复代码，而且不好维护，那么我们可以把这个逻辑抽离出来。

改造如下：

```python
# coding: utf8

import time

def timeit(func):
    start = time.time()
    func()
    end = time.time()
    print 'duration time: %ds' % int(end - start)

def hello():
    time.sleep(1)
    print 'hello'

timeit(hello)
```

这里我们定义了`timeit`这个方法，参数传入一个方法对象，在执行完真正的逻辑后，然后计算其运行时间。这样，我们如果想对哪个函数计算执行时间，都按照此方式调用即可。

```python
timeit(func1)
timeit(func2)
```

虽然此方式可以完成我们的需求，但有没有觉得，本来我是想执行`hello`方法，现在执行都需要使用`timeit`重新包裹一下才能达到要求，有没有一种方式是既给原方法加上计算时间的逻辑，还能像调用原方法一样使用呢？

答案当然是可以的，我们对`timeit`方法进行改造：

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

hello = timeit(hello)	# 重新定义hello
hello()					# 像调用原始方法一样使用
```

请注意观察`timeit`方法的变动，它在内部定义了一个`inner`方法，此方法内部实现与之前类似，`timeit`最终返回了`inner`对象，注意：返回的是**方法对象**，而不是方法执行后的结果。

所以在调用`hello = timeit(hello)`时，会得到一个方法对象，重新赋值给`hello`，那么此时的变量`hello`其实是`inner`，在执行`hello()`时，也就是执行了`inner`方法的逻辑。

这么一来，我们就对`hello`方法进行了重新定义，无形中不仅保证其原有的逻辑，而且又增加了新的功能。

回过头我们来分析一下`timeit`这个方法内部是如何运行的，在Python中允许在一个方法中嵌套另一个方法，这种特殊的机制叫做**闭包**，这个内部方法保留外部方法的作用域，尽管外部方法不是全局的，内部方法也可以访问到外部方法的参数和变量。

# 装饰器

明白了上面的工作机制，那装饰器就变得非常简单了。Python支持一种装饰器语法糖`@`，也就是上面方式的变形：

```python
@timeit			# 相当于hello = timeit(hello)
def hello():
    time.sleep(1)
    print 'hello'

hello()		# 直接调用原方法即可
```

装饰器其实就是实现一个闭包，把一个方法当做参数，然后返回另一个方法替代之。是不是很简单？这就是装饰器的核心，平时开发中我们见过的装饰器无非就是这种形式的继续变形而已，现在只有一个内部方法，如果想达到更高级的使用，定义**多个内部方法**即可。

<!-- more -->

# functools.wraps

现在我们已经得知，装饰器其实就是先定义好一个闭包，然后使用语法糖`@`来装饰方法，最后达到重新定义方法的作用，也就是说，最后我们执行的方法，其实是另外一个方法了。

还是上面的例子，我们来看一下被装饰方法的属性。

```python
@timeit
def hello():
    time.sleep(1)
    print 'hello'

print hello.__name__

# Output:
# inner
```

我们看到，由于最终执行的是`inner`方法的逻辑，所以被装饰的`hello`方法的`__name__`属性是`inner`。

理想情况下，我们希望被装饰的方法，除了增加额外的功能逻辑外，对其属性和方法都还是保持原有的值和行为，否则在使用中，有可能存在一些隐患。在Python内置的`functools`模块中，提供了一个`wraps`方法，专门来消除这种问题。

```python
# coding: utf8

import time
from functools import wraps

def timeit(func):
    @wraps(func)		# 使用wraps装饰内部方法inner
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

print hello.__name__

# Output:
# hello
```

使用`wraps`装饰内部方法`inner`后，我们再调用`hello`的任意属性和方法，都能得到来自原方法的属性和值了。

# 装饰带参数的方法

在上面例子中，被装饰的方法都是没有参数的，那么如何装饰一个带参数的方法呢？

```python
# coding: utf8

import time
from functools import wraps

def timeit(func):
    @wraps(func)
    def inner(name):		# 也需加对应的参数
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

由于最终调用的是`inner`方法，所以被装饰的方法`hello`如果想加参数，对应的`inner`方法也同样加相应的参数。

有没有发现，我们定义的`timeit`是一个通用的装饰器，现在由于为了适应`hello`的参数，而在`inner`方法中加了一个参数，那如果要装饰其他方法，有2个甚至更多参数，怎么办，难道要在`inner`中加继续加参数吗？

这当然是不行的，我们改造如下：

```python
# coding: utf8

import time
from functools import wraps

def timeit(func):
    @wraps(func)
    def inner(*args, **kwargs):		# *args, **kwargs适应所有参数
        start = time.time()
        func(*args, **kwargs)		# 传递参数给真实调用的方法
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

我们把`inner`方法的参数改为了`*args, **kwargs`，然后调用真实方法时传入参数`func(*args, **kwargs)`，这样，我们的装饰器就可以装饰任意个数参数的方法了。

# 带参数的装饰器

你可能也见过，有些装饰器是可以带参数的，如何实现？

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

实际上，就是多加了一层方法嵌套，在`timeit`中定义了2个内部方法，`timeit`接收参数，返回`decorator`对象，而在`decorator`方法中返回`wrapper`对象。

也就是说，带参数的装饰器由2个内部方法嵌套就可以实现。

# 类实现装饰器

上面几个例子，都是用方法完成的装饰器，当然，用类也可以达到同样的效果。

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

hello()
```

利用类的`__init__`和`__call__`方法，就可以实现一个上面相同功能的装饰器。

# 装饰器使用场景

有了装饰器，在可以不修改原方法的情况下，给方法增加额外的功能，这里举几个常用的使用例子。

## 记录方法调用日志

```python
from functools import wraps
def logging(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        print 'method: %s, %s, %s' % (func.func_name, args, kwargs)
        return func(*args, **kwargs)
    return wrapper
```

## 记录方法执行时间

```python
from functools import wraps
def timeit(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        start = time.time()
        result = func(*args, **kwargs)
        duration = int(time.time() - start)
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
        wrapper.count = wrapper.count + 1
        print 'method: %s, count: %s' % (func.func_name, wrapper.count)
        return func(*args, **kwargs)
    wrapper.count = 0
    return wrapper
```

## 方法缓存

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

除此之外，装饰器还能在权限校验、上下文处理等场景有非常适合使用的场景。

