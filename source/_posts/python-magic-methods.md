title: Python技术进阶——魔法方法（一）
date: 2017-02-22 16:02:38
categories: Python
tags: [python]
---

在做 Python 开发时，我们经常会遇到以**双下划线开头和结尾**的方法，例如 `__init__`、`__new__`、`__getattr__`、`__setitem__` 等等，这些方法我们通常称之为「魔法方法」，而使用这些「魔法方法」，我们可以非常方便地给类添加特殊的功能。

这篇文章，我们就来分析一下，Python 中的魔法方法都有哪些？使用这些魔法方法，我们可以实现哪些实用的功能？

# 魔法方法概览

首先，我们先对 Python 中的魔法方法进行归类，常见的魔法方法大致可分为以下几类：

- 构造与初始化
- 类的表示
- 访问控制
- 比较操作
- 容器类操作
- 可调用对象
- 序列化

由于魔法方法分类较多，这篇文章我们先来看前几个：构造与初始化、类的表示、访问控制。剩下的魔法方法，我们会在下一篇文章进行分析讲解。

# 构造与初始化

首先，我们来看关于构造与初始化相关的魔法方法，主要包括以下几种：

- `__init__`
- `__new__`
- `__del__`

## `__init__`

关于构造与初始化的魔法方法，我们使用最频繁的一个就是 `__init__` 了。

我们在定义类的时候，通常都会去定义构造方法，它的作用就是在初始化一个对象时，定义这个对象的初始值。

```python
# coding: utf8

class Person(object):

    def __init__(self, name, age):
        self.name = name
        self.age = age

p1 = Person('张三', 25)
p2 = Person('李四', 30)
```

## `__new__`

在初始化一个类的属性时，除了使用 `__init__` 之外，还可以使用 `__new__` 这个方法。

我们在平时开发中使用的虽然不多，但是经常能够在开源框架中看到它的身影。实际上，这才是「真正的构造方法」。

```python
# coding: utf8

class Person(object):

    def __new__(cls, *args, **kwargs):
        print "call __new__"
        return object.__new__(cls, *args, **kwargs)

    def __init__(self, name, age):
        print "call __init__"
        self.name = name
        self.age = age

p = Person("张三", 20)

# Output:
# call __new__
# call __init__
```

从例子我们可以看到，`__new__` 会在对象实例化时第一个被调用，然后才会调用 `__init__`，它们的区别如下：

- `__new__` 的第一个参数是 `cls`，而 `__init__` 的第一个参数是 `self`
- `__new__` 返回值是一个实例对象，而 `__init__` 没有任何返回值，只做初始化操作
- `__new__` 由于返回的是一个实例对象，所以它可以给所有实例进行**统一**的初始化操作

了解了它们之间的区别，我们来看 `__new__` 在什么场景下使用？

由于 `__new__` 优先于 `__init__` 调用，而且它返回的是一个实例，所以我们可以利用这个特性，在 `__new__` 方法中，每次返回同一个实例来实现一个单例类：

```python
# coding: utf8

class Singleton(object):
    """单例"""
    _instance = None
    def __new__(cls, *args, **kwargs):
        if not cls._instance:
            cls._instance = super(Singleton, cls).__new__(cls, *args, **kwargs)
        return cls._instance

class MySingleton(Singleton):
    pass

a = MySingleton()
b = MySingleton()

assert a is b	# True
```

另外一个使用场景是，当我们需要**继承内置类**时，例如想要继承 `int`、`str`、`tuple`，就无法使用 `__init__` 来初始化了，只能通过 `__new__` 来初始化数据：

```python
# coding: utf8

class g(float):
    """千克转克"""
    def __new__(cls, kg):
        return float.__new__(cls, kg * 2)

a = g(50) # 50千克转为克
print a 	# 100
print a + 100	# 200 由于继承了float，所以可以直接运算，非常方便！
```

在这个例子中，我们实现了一个类，这个类继承了 `float`，之后，我们就可以对这个类的实例进行计算了，是不是很神奇？

除此之外，`__new__` 比较多的应用场景是配合「元类」使用，关于「元类」的原理，我会在后面的文章中讲到。

<!-- more -->

## `__del__`

`__del__` 这个方法就是我们经常说的「析构方法」，也就是在对象被垃圾回收时被调用。

但是请注意，当我们执行 `del obj` 时，这个方法不一定会执行。

由于 Python 是通过引用计数来进行垃圾回收的，如果这个实例在执行 `del` 时，还被其他对象引用，那么就不会触发执行 `__del__` 方法。

我们来看一个例子：

```python
class Person(object):
    def __del__(self):
        print '__del__'
```

我们定义了一个带有 `__del__` 方法的类，此时我们直接执行：

```python
a = Person()
print 'exit'

# Output:
# exit
# __del__
```

由于我们没有对实例进行任何引用操作时，所以 `__del__` 在程序退出时被调用。

如果我们显示执行 `del obj`，如下：

```python
a = Person()
del a   	# 手动销毁对象
print 'exit'

# Output:
# __del__
# exit
```

同样地，由于实例没有被其他对象所引用，当我们手动销毁这个实例时，`__del__` 被调用后程序正常退出。

如果这个对象被其他对象所引用：

```python
a = Person()
b = a   # b引用a
del a   # 手动销毁 不触发__del__
print 'exit'

# Output:
# exit
# __del__
```

可以看到，如果这个实例有被其他对象引用，尽管我们手动销毁这个实例，但不会触发 `__del__` 方法，而是在程序正常退出时被调用执行。

通常来说，`__del__` 这个方法我们很少会使用到，除非需要在显示执行 `del` 执行特殊清理逻辑的场景中才会使用到。

但另一方面，也给我们一个提醒，当我们在对文件、Socket 进行操作时，如果要想安全地关闭和销毁这些对象，最好是在 `try` 异常块后的 `finally` 中进行关闭和释放操作，从而避免资源的泄露。

# 类的表示

接下来，我们来看关于类的表示相关的魔法方法，主要包括以下几种：

- `__str__` / `__repr__`
- `__unicode__`
- `__hash__` / `__eq__`
- `__nozero__`

## `__str__`/`__repr__`

关于 `__str__` 和 `__repr__` 这 2 个魔法方法，非常类似，很多人区分不出它们有什么不同，我们来看几个例子，就能理解这 2 个方法的效果：

```python
>>> a = 'hello'
>>> str(a)
'hello'
>>> '%s' % a	# 调用__str__
'hello'

>>> repr(a)		# 对象a的标准表示 也就是a是如何创建的
"'hello'"
>>> '%r' % a	# 调用__repr__
"'hello'"

>>> import datetime
>>> b = datetime.datetime.now()
>>> str(b)
'2017-02-22 12:28:40.923379'
>>> print b		# 等同于print str(b)
2017-02-22 12:28:40.923379

>>> repr(b)		# 展示对象b的标准创建方式(如何创建的)
'datetime.datetime(2017, 2, 22, 12, 28, 40, 923379)'
>>> b		     # 等同于print repr(b)
datetime.datetime(2017, 2, 22, 12, 28, 40, 923379)

>>> c = eval(repr(b))	# repr(b)目标针对于机器 所以可执行
>>> c
datetime.datetime(2017, 2, 22, 12, 28, 40, 923379)
```

从上述例子中我们可以看出这 2 个方法的区别：

- `__str__` 强调可读性，而 `__repr__` 强调准确性 / 标准性
- `__str__` 的目标人群是用户，而 `__repr__` 的目标人群是机器，`__repr__` 返回的结果是可执行的，通过 `eval(repr(obj))` 可以正确运行
- 占位符 `%s` 调用的是 `__str__`，而 `%r` 调用的是 `__repr__` 方法

所以，我们在实际中开发中定义类时，一般这样使用：

```python
# coding: utf8

class Person(object):

    def __init__(self, name, age):
        self.name = name
        self.age = age

    def __str__(self):
        # 格式化 友好对用户展示
        return 'name: %s, age: %s' % (self.name, self.age)

    def __repr__(self):
        # 标准化展示
        return "Person('%s', %s)" % (self.name, self.age)

person = Person('zhangsan', 20)

# 强调对用户友好
print str(person)       # name: zhangsan, age: 20 
print '%s' % person     # name: zhangsan, age: 20

# 强调对机器友好 结果 eval 可执行
print repr(person)	# Person('zhangsan', 20)
print '%r' % person     # Person('zhangsan', 20)
```

明白了它们之间的区别，我们再思考一下，如果只定义了 `__str__` 或 `__repr__` 其中一个，那会是什么结果？

只定义 `__str__`，但没有定义 `__repr__`：

```python
# coding: utf8

class Person(object):

    def __init__(self, name, age):
        self.name = name
        self.age = age
        
    def __str__(self):
        return 'name: %s, age: %s' % (self.name, self.age)

person = Person('zhangsan', 20)

print str(person)       # name: zhangsan, age: 20 
print '%s' % person     # name: zhangsan, age: 20

print repr(person)	# <__main__.Person object at 0x10bee9390>
print '%r' % person     # <__main__.Person object at 0x10bee9390>
```

只定义 `__repr__`，但没有定义 `__str__`：

```python
# coding: utf8

class Person(object):

    def __init__(self, name, age):
        self.name = name
        self.age = age
        
    def __repr__(self):
        return "Person('%s', %s)" % (self.name, self.age)

person = Person('zhangsan', 20)

print str(person)       # Person('zhangsan', 20)
print '%s' % person     # Person('zhangsan', 20)

print repr(person)	# Person('zhangsan', 20)
print '%r' % person     # Person('zhangsan', 20)
```

从例子中我们可以看到结果：

- 如果只定义了 `_str__`，那么 `repr(person)` 输出 `<__main__.Person object at 0x10bee9390>`
- 如果只定义了 `__repr__`，那么 `str(person)` 与 `repr(person)` 结果是相同的

也就是说，`__repr__` 在表示类时，是一级的，如果只定义它，那么 `__str__ = __repr__`。

而 `__str__` 展示类时是次级的，如果没有定义 `__repr__`，那么 `repr(person)` 将会展示缺省的定义。

## `__unicode__`

如果一个类定义了 `__unicode__` 方法，那么在调用 `unicode(obj)` 时，此方法将被调用，但是其返回值类型是 `unicode`。

```python
# coding: utf8

class Person(object):

    def __unicode__(self):
        # 这里不是u'hello'
        return 'hello'
    
person = Person()
print unicode(person)	          # helllo
print type(unicode(person))	    # <type 'unicode'>
```

从例子中我们可以看到， 虽然我们定义的 `__unicode__` 返回值不是 `unicode` 类型，但在输出时，程序会自动转换成 `unicode` 类型。

这个方法在开发中一般很少使用，通常我们只需要定义 `__str__` 即可。

## `__hash__/__eq__`

`__hash__` 方法返回一个整数，用来表示实例对象的唯一标识，配合 `__eq__` 方法，可以判断两个对象是否相等：

```python
# coding: utf8

class Person(object):
    def __init__(self, uid):
        self.uid = uid
        
	def __repr__(self):
        return 'Person(%s)' % self.uid
        
    def __hash__(self):
        return self.uid
    
    def __eq__(self, other):
        return self.uid == other.uid
    
p1 = Person(1)
p2 = Person(1)
p1 == p2	   # True

p3 = Person(2)
print set([p1, p2, p3])	# 根据唯一标识去重输出 set([Person(1), Person(2)])
```

如果我们需要判断两个对象是否相等，只需要我们重写 `__hash__` 和 `__eq__` 方法就可以了。

此外，当我们使用 `set` 时，在 `set` 中存放这些对象，也会根据这两个方法进行去重操作。

## `__nonzero__`

当调用 `bool(obj)` 时，会调用 `__nonzero__` 方法，返回 `True` 或 `False`：

```python
# coding: utf8

class Person(object):
    def __init__(self, uid):
        self.uid = uid

    def __nonzero__(self):
        return self.uid > 10
    
p1 = Person(1)
p2 = Person(15)
print bool(p1)	 # False
print bool(p2)	 # True
```

> 在 Python3 中，`__nonzero__` 被重命名为 `__bool__`。

# 访问控制

接下来，我们来看关于访问控制的魔法方法，主要包括以下几种：

- `__setattr__`：通过「.」设置属性或 `setattr(key, value)` 设置属性时调用
- `__getattr__`：访问不存在的属性时调用
- `__delattr__`：删除某个属性时调用
- `__getattribute__`：访问任意属性或方法时调用

我们来看使用这些方法的完整例子：

```python
# coding: utf8

class Person(object):

    def __setattr__(self, key, value):
        """属性赋值"""
        if key not in ('name', 'age'):
            return
        if key == 'age' and value < 0:
            raise ValueError()
        super(Person, self).__setattr__(key, value)

    def __getattr__(self, key):
        """访问某个不存在的属性"""
        return 'unknown'

    def __delattr__(self, key):
        """删除某个属性"""
        if key == 'name':
            raise AttributeError()
        super(Person, self).__delattr__(key)

    def __getattribute__(self, key):
        """所有属性/方法调用都经过这里"""
        if key == 'money':
            return 100
        if key == 'hello':
            return self.say
        return super(Person, self).__getattribute__(key)

    def say(self):
        return 'hello'
    
p1 = Person()
p1.name = 'zhangsan'	# 调用__setattr__
p1.age = 20             # 调用__setattr__
print p1.name	      # zhangsan
print p1.age	      # 20

setattr(p1, 'name', 'lisi')	# 调用__setattr__
setattr(p1, 'age', 30)		# 调用__setattr__
print p1.name	            # lisi
print p1.age	            # 30

p1.gender = 'male'	# __setattr__中忽略对gender赋值
print p1.gender	    # gender不存在 所以会调用__getattr__返回unknown

print p1.money	     # money不存在 在__getattribute__中返回100

print p1.say()	     # hello
print p1.hello()    # hello 调用__getattribute__ 间接调用say方法

del p1.name		   # __delattr__中引发AttributeError

p2 = Person()
p2.age = -1		   # __setattr__中引发ValueError
```

我们仔细看一下这个例子，我已经添加好了详细的注释。


## `__setattr__`

先来说 `__setattr__`，当我们在给一个对象进行属性赋值时，都会经过这个方法，在这个例子中，我们只允许对 `name` 和 `age` 这 2 个属性进行赋值，忽略了 `gender` 属性，除此之外，我们还对 `age` 赋值进行了校验。

通过 `__setattr__` 方法，我们可以非常方便地对属性赋值进行控制。

## `__getattr__`

再来看 `__getattr__`，由于我们在 `__setattr__` 中忽略了对 `gender` 属性的赋值，所以当访问这个不存在的属性时，会调用 `__getattr__` 方法，在这个方法中返回了默认值 unknown。

很多同学以为这个方法与 `__setattr__` 方法对等的，一个是赋值，一个是获取。其实不然，`__getattr__` 只有在访问「不存在的属性」时才会被调用，这里我们需要注意。


## `__getattribute__`

了解了 `__getattr__` 后，还有一个和它非常类似的方法：`__getattribute__`。

很多人经常把这个方法和 `__getattr__` 混淆，通过例子我们可以看出，它与前者的区别在于：

- `__getattr__` 只有在访问不存在的属性时被调用，而 `__getattribute__` 在访问任意属性时都会被调用
- `__getattr__` 只针对属性访问，而`__getattribute__` 不仅针对所有属性访问，还包括方法调用

在上面的例子，虽然我们没有定义 `money` 属性和 `hello` 方法，但是在 `__getattribute__` 里拦截到了这个属性和方法，就可以对其执行不同的逻辑。

## `__delattr__`

最后，我们来看 `__delattr__`，它比较简单，当删除对象的某个属性时，这个方法会被调用，所以它一般会用在删除属性前的校验场景中使用。

# 总结

这篇文章，我们主要介绍了 Python 中常见的魔法方法，主要有构造与初始化、类的表示、访问控制这 3 个模块。

构造与初始化的魔法方法，常常用在类的初始化过程中，其中 `__init__`一般用于实例初始化， 而 `__new__` 可以改变初始化实例的行为，通过它我们可以实现一个单例或者继承一个内置类。

关于类的表示的魔法方法，比较常用的，当我们想表示一个类时，可以使用 `__str__` 或 `__repr__` 方法，当需要判断两个对象是否相等时，可以使用 `__hash__` 和 `__eq__` 方法。

关于访问控制的魔法方法，它可以控制实例的属性赋值、属性访问、方法访问、属性删除等操作，这对于我们实现一个复杂功能的类有很大帮助。

在下一篇文章，我们会继续分析剩下的魔法方法，主要包括关于比较操作、容器类操作、可调用对象、序列化相关的魔法方法。


