title: Python技术进阶——魔法方法（一）
date: 2017-02-22 16:02:38
categories: Python
tags: [python]
---

> 想必只要是做Python开发的同学，都会或多或少见到以**双下划线开头**的方法，这些就是我们经常说的“魔法”方法。它可以对你的类添加特殊的功能，使用恰当会给我们的开发带来很大的便利。
>
> 这篇文章主要是总结了在我们开发中，经常遇到的那些“魔法”方法，如何使用以及它们的使用场景。

# 概览

目前我们常见的魔法方法大致可分为以下几类：

- 构造与初始化
- 类的表示
- 访问控制
- 比较操作
- 容器类操作
- 可调用对象
- Pickling序列化

我们这次主要介绍这几类常用魔法方法。

# 构造与初始化

## `__init__`

构造方法是我们使用频率最高的魔法方法了，几乎在我们定义类的时候，都会去定义构造方法，它的主要作用就是在初始化一个对象时，定义这个对象的初始值。

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

这个方法我们一般很少定义，不过我们在一些开源框架中偶尔会遇到定义这个方法的类。实际上，这才是“真正的构造方法”，它会在对象实例化时第一个被调用，然后再调用`__init__`，它们的区别主要如下：

- `__new__`的第一个参数是`cls`，而`__init__`的第一个参数是`self`
- `__new__`返回值是一个实例，而`__init__`没有任何返回值，只做初始化操作
- `__new__`由于是返回一个实例对象，所以它可以给所有实例进行**统一**的初始化操作

由于`__new__`优先于`__init__`调用，且返回一个实例，所以我们可以利用这种特性，每次返回同一个实例来实现一个单例类：

```python
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

另外一种使用场景是当你需要继承内置类时，例如`int`、`str`、`tuple`，只能通过`__new__`来达到初始化数据的效果：

```python
class g(float):
    """千克转克"""
    def __new__(cls, kg):
        return float.__new__(cls, kg * 2)

# 50千克转为克
a = g(50)
print a 	# 100
print a + 100	# 200, 由于继承了float，所以可以直接运算，非常方便！
```

除此之外，`__new__`比较多的应用场景是配合**元类**使用，具体会在以后的文章中讲解到。

<!-- more -->

## `__del__`

这个方法代表**析构方法**，也就是在对象被垃圾回收时被调用。但是请注意，执行`del x`不一定会执行此方法。

由于Python是通过引用计数来进行垃圾回收的，也就是说，如果这个实例还是有被引用到，即使执行`del`销毁这个对象，但其引用计数还是大于0，所以不会触发执行`__del__`。

来看一个例子：

```python
class Person(object):
    def __del__(self):
        print '__del__'
```

如果我们直接执行：

```python
a = Person()
print 'exit'

# Output:
# exit
# __del__
```

此时我们没有对实例进行任何操作时，`__del__`在程序退出后被调用。

```python
a = Person()
del a	# 手动销毁
print 'exit'

# Output:
# __del__
# exit
```

由于此实例没有被其他对象所引用，当我们手动销毁这个实例时，`__del__`被调用后程序正常退出。

```python
a = Person()
b = a	# b引用a
del a	# 手动销毁,不触发__del__
print 'exit'

# Output:
# exit
# __del__
```

此时实例有被其他对象引用，尽管我们手动销毁这个实例，但依然不会触发`__del__`方法，而是在程序正常退出后被调用执行。

为了保险起见，当我们在对文件、socket进行操作时，要想安全地关闭和销毁这些对象，最好是在`try`异常块后的`finally`中进行关闭和释放操作！

# 类的表示

## `__str__`/`__repr__`

这两个魔法方法一般会放到一起进行讲解，它们的主要差别为：

- `__str__`强调可读性，而`__repr__`强调准确性/标准性
- `__str__`的目标人群是用户，而`__repr__`的目标人群是机器，它的结果是可以被执行的
- `%s`调用`__str__`方法，而`%r`调用`__repr__`方法

来看几个例子，了解内置类实现这2个方法的效果：

```python
>>> a = 'hello'
>>> str(a)
'hello'
>>> '%s' % a	# 调用__str__
'hello'

>>> repr(a)		# 对象a的标准表示，也就是a是如何创建的
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
>>> b		# 等同于print repr(b)
datetime.datetime(2017, 2, 22, 12, 28, 40, 923379)

>>> c = eval(repr(b))	# repr(b)目标针对于机器，所以可执行
>>> c
datetime.datetime(2017, 2, 22, 12, 28, 40, 923379)
```

从上面的例子可以看出这两个方法的主要区别，在实际中我们定义类时，一般这样定义即可：

```python
class Person(object):

    def __init__(self, name, age):
        self.name = name
        self.age = age

    def __str__(self):
        # 格式化，友好对用户展示
        return 'name: %s, age: %s' % (self.name, self.age)

    def __repr__(self):
        # 标准化展示
        return "Person('%s', %s)" % (self.name, self.age)

person = Person('zhangsan', 20)

print str(person)		# name: zhangsan, age: 20
print '%s' % person		# name: zhangsan, age: 20

print repr(person)		# Person('zhangsan', 20)
print '%r' % person		# Person('zhangsan', 20)
```

这里值得注意的是，如果只定义了`__str__`或`__repr__`其中一个，那会是什么结果？

- 如果只定义了`_str__`，那么`repr(person)`输出`<__main__.Person object at 0x1093642d0>`
- 如果只定义了`__repr__`，那么`str(person)`与`repr(person)`结果是相同的

也就是说，`__repr__`在表示类时，是一级的，如果只定义它，那么`__str__ = __repr__`。

而`__str__`展示类时是次级的，用户可自定义类的展示格式，如果没有定义`__repr__`，那么`repr(person)`将会展示缺省的定义。

## `__unicode__`

如果一个类定义了`__unicode__`方法，那么在调用`unicode(obj)`时，此方法将被调用，但是其返回值类型是`unicode`。

```python
class Person(object):

    def __unicode__(self):
        # 这里不是u'hello'
        return 'hello'
    
person = Person()
print unicode(person)	# helllo
print type(unicode(person))	# <type 'unicode'>
```

尽管`__unicode__`的返回值不是`unicode`类型，但在输出时候会自动转换成`unicode`类型。

此方法在开发中一般很少使用，通常我们只需要定义`__str__`即可。

## `__hash__/__eq__`

`__hash__`方法返回一个整数，用来表示该对象的唯一标识，配合`__eq__`方法判断两个对象是否相等(`==`)：

```python
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
p1 == p2	# True

p3 = Person(2)
print set([p1, p2, p3])	# 根据唯一标识去重输出 set([Person(1), Person(2)])
```

如果我们需要判断两个对象是否相等，只要我们重写`__hash__`和`__eq__`方法就可以完成此功能。此外使用`set`存放这些对象时，会根据这两个方法进行去重操作。

## `__nonzero__`

当调用`bool(obj)`时，会调用`__nonzero__`方法，返回`True/False`。

```python
class Person(object):
    def __init__(self, uid):
        self.uid = uid

    def __nonzero__(self):
        return self.uid > 10
    
p1 = Person(1)
p2 = Person(15)
print bool(p1)	# False
print bol(p2)	# True
```

> 在Python3中，`__nonzero__`被重命名`__bool__`。

# 访问控制

访问控制相关的魔法方法，主要涉及以下几个：

- `__setattr__`：通过`.`设置属性或`setattr(key, value)`
- `__getattr__`：访问**不存在**的属性
- `__delattr__`：删除某个属性
- `__getattribute__`：访问**任意属性或方法**

来看一个完整的例子：

```python
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
p1.age = 20				# 调用__setattr__
print p1.name	# zhangsan
print p1.age	# 20

setattr(p1, 'name', 'lisi')	# 调用__setattr__
setattr(p1, 'age', 30)		# 调用__setattr__
print p1.name	# lisi
print p1.age	# 30

p1.gender = 'male'	# __setattr__中忽略对gender赋值
print p1.gender	# gender不存在,调用__getattr__返回：unknown

print p1.money	# money不存在,在__getattribute__中返回100

print p1.say()	# hello
print p1.hello()# hello,调用__getattribute__，间接调用say方法

del p1.name		# __delattr__中引发AttributeError

p2 = Person()
p2.age = -1		# __setattr__中引发ValueError
```

## `__setattr__`

通过此方法，对象可在在对属性进行赋值时进行控制，所有的属性赋值都会经过它。

一般常用于对某些属性赋值的检查校验逻辑，例如`age`不能小于0，否则认为是非法数据等等。

## `__getattr__`

很多同学以为此方法是和`__setattr__`完全对立的，其实不然！

这个方法只有在访问某个**不存在的属性**时才会被调用，看上面的例子，由于`gender`属性在赋值时，忽略了此字段的赋值操作，所以此属性是没有被成功赋值给对象的。当访问这个属性时，`__getattr__`被调用，返回`unknown`。

## `__del__`

删除对象的某个属性时，此方法被调用。一般常用于某个属性必须存在，否则无法进行后续的逻辑操作，会重写此方法，对删除属性逻辑进行检查和校验。

## `__getattribute__`

这个方法我们很少用到，它与`__getattr__`很容易混淆。它与前者的区别在于：

- `__getattr__`访问某个不存在的属性被调用，`__getattribute__`访问任意属性被调用
- `__getattr__`只针对属性访问，`__getattribute__`**不仅针对所有属性访问，还包括方法调用**

越是强大的魔法方法，责任越大，如果你不能正确使用它，最好还是不用为好，否则在出现问题时很难排查。

