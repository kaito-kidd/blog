title: Python技术进阶——描述器
date: 2018-04-16 09:42:51
tags: [python]
---

# 前言
在Python开发中，我们很少能接触到描述器的直接使用，但对于熟练使用Python的开发者，了解Python描述器的工作原理，能让你更深入地了解Python以及其设计的优雅之处。

其实我们开发中遇到的很多例子，例如：

- 装饰器`property`、`staticmethod`、`classmethod`
- `function`、`bound method`、`unbound method`

是不是都很熟悉，其实这些都与描述器有着千丝万缕的关系，这篇文章就为大家一一解答其中的奥秘。

# 什么是描述器？
一般来说，描述器是一个有**「绑定行为」**的对象属性，它的访问控制被描述器协议方法重写。

回忆一下，在编程中我们说**「行为」**一般指的是方法。

那么这就容易理解了，**「绑定行为」**的对象属性，就是指这个**「对象属性」**依托于了另外的对象，这个对象里包含了很多「方法」来控制这个行为。


# 描述器协议

对象属性依托的对象中，包含的「方法」不能随便定义，而是规定好的，实现这些方法，就是实现了描述器协议，具体有以下几个：

- `__get__`
- `__set__`
- `__delete__`

只要实现以上方法**其一**，这个对象就叫做描述器。

- 定义了`__get__`和`__set__`的对象叫做**资料描述器**
- 只定义了`__get___`的对象叫做**非资料描述器**

这两者有什么区别呢？我们下面再做解释。

<!-- more -->

# 描述器的调用

我们来看一段描述器的代码：

```python
class Age(object):
    """这个类实现了描述器协议"""

    def __init__(self, value=20):
        self.value = value

    def __get__(self, obj, type=None):
        print 'get --> obj: %s type: %s' % (obj, type)
        return self.value

    def __set__(self, obj, value):
        print 'set --> obj: %s value: %s' % (obj, value)
        self.value = value

class Person(object):

    age = Age() # 这个属性通过描述器托管给了另一个类

    def __init__(self, name):
        self.name = name


person = Person('zhangsan')

print person.age
# get --> obj: <__main__.Person object at 0x105e815d0> type: <class '__main__.Person'>
# 20

print Person.age
# get --> obj: None type: <class '__main__.Person'>
# 20

person.age = 25
# set --> obj: <__main__.Person object at 0x105e815d0> value: 25

print person.age
# get --> obj: <__main__.Person object at 0x105e815d0> type: <class '__main__.Person'>
# 25
```
我们从代码看出，`Person`类的**类属性**`age`被`Age`实现，`Age`类实现了`__set__`和`__get__`方法，对于`Person`类来说，`age`就是一个**描述器**。

我们通过输出结果看出，当调用`age`属性时，都调用了`Age`的`__get__`方法，但打印出的参数结果不同：

- 当调用方是**实例**时，`obj`是`Person`实例，`type`是`type(Person)`
- 当调用方是**类**时，`obj`是`None`，`type`是`type(Person)`

# 工作原理

这背后的机制到底是怎样的呢？

要解释这个现象，我们要先从属性被访问的机制来说，调用`a.b`会发生什么？

如果`a`的类是继承了`object`，也就是说这个类是新式类，那么`a.b`会调用`__getattribute__`方法，如果类中没有定义这个方法，那么默认会调用`object`的`__getattribute__`方法。

而`object`在`__getattribute__`中就默认调用了描述器，但调用细节取决于`a`是一个类还是一个实例：

- 如果`a`是一个**实例**，`object`的这个方法会把其变为：

```python
type(a).__dict__['b'].__get__(a, type(a))
```

- 如果`a`是一个**类**，`object`的这个方法会把其变为：

```python
a.__dict__['b'].__get__(None, a)
```

所以我们就能看到上面例子输出的结果。

也就是说，描述器的调用入口，取决于`__getattribute__`！

如果我们重写了`__getattribute__`，那么会阻止描述器的调用。

# 方法就是描述器

我们思考一个问题，当一个类中的实例变量名与一个方法同名时，例如类`A`有一个实例变量和方法都叫`foo`，那么`A().foo`会输出实例属性还是调用方法？

```python
class A(object):

    def __init__(self):
        self.foo = 'abc'

    def foo(self):
        return 'xyz'

print A().foo   # abc
```

我们看到，`A().foo`输出了`abc`，也就是实例属性的值，而不是调用这个方法，这是怎么回事？

我们执行如下代码：

```python
print dir(A.foo)

# ['__call__', '__class__', '__get__', '__delattr__', '__doc__', ...
```

看到了吗？`dir(A.foo)`包含了`__get__`方法，我们在上面知道描述器的定义是：只要实现了`__get__`、`__set__`、`__del__`其一，这个对象就是描述器。

也就是说：**方法就是一个描述器**，而且是一个**非资料描述器**。

其实在调用一个属性时，具体的执行顺序是这样的：

```
__getattribute()__ -> 资料描述器 > 实例变量 > 非资料描述器 > __getattr()__
```

当一个类中的实例变量名与一个方法同名时：

- 如果描述器是资料描述器，优先使用资料描述器
- 如果描述器是非资料描述器，优先使用字典中的属性

由于每个方法都是一个非资料描述器，所以优先使用实例变量。

到这里我们可以总结一下：

- `__getattribute__`只对新式类的实例有用
- 描述器的调用是因为`object`的`__getattribute__`
- 重写`__getattribute__`方法会阻止正常描述器的调用
- 方法都是非资料描述器
- 实例和类调用`__get__`结果不一样
- 资料描述器 > 实例变量 > 非资料描述器调用

# function/unbound method/bound method

我们常见的`function`、`unbound method`、`bound method`有什么区别呢？

```python
class A(object):

    def foo(self):
        return 'xyz'

print A.__dict__['foo']     # <function foo at 0x10a790d70>
print A.foo     # <unbound method A.foo>
print A().foo   # <bound method A.foo of <__main__.A object at 0x10a793050>>
```

它们的区别如下：

- `function`就是一个函数，因为其实现了`__get__`，因此每个函数都是一个非资料描述器
- 类的字典把方法当做函数存储
- 当方法被实例调用时，返回绑定的方法（`bound method`)
- 当方法被类调用时，返回非绑定的方法（`unbound method`）

# property/staticmethod/classmethod

Python把一些使用特别普遍的功能打包成了独立的函数，例如`property`、`staticmethod`、`classmethod`，这些方法都是基于描述器协议实现的。

`property`的Python版实现：

```python
class property(object):

    def __init__(self, fget=None, fset=None, fdel=None, doc=None):
        self.fget = fget
        self.fset = fset
        self.fdel = fdel
        self.__doc__ = doc

    def __get__(self, obj, objtype=None):
        if obj is None:
            return self.fget
        if self.fget is None:
            raise AttributeError(), "unreadable attribute"
        return self.fget(obj)

    def __set__(self, obj, value):
        if self.fset is None:
            raise AttributeError, "can't set attribute"
        return self.fset(obj, value)

    def __delete__(self, obj):
        if self.fdel is None:
            raise AttributeError, "can't delete attribute"
        return self.fdel(obj)

    def getter(self, fget):
        return type(self)(fget, self.fset, self.fdel, self.__doc__)

    def setter(self, fset):
        return type(self)(self.fget, fset, self.fdel, self.__doc__)

    def deleter(self, fdel):
        return type(self)(self.fget, self.fset, fdel, self.__doc__)
```

`staticmethod`的Python版实现：

```python
class staticmethod(object):

    def __init__(self, func):
        self.func = func

    def __get__(self, obj, objtype=None):
        return self.func
```

`classmethod`的Python版实现：

```python
class classmethod(object):

    def __init__(self, func):
        self.func = func

    def __get__(self, obj, klass=None):
        if klass is None:
            klass = type(obj)
        def newfunc(*args):
            return self.func(klass, *args)
        return newfunc
```

由此可见，通过描述符我们可以实现强大而灵活的属性和方法管理，但强大也意味着责任大，在合适的场景使用才能起到最佳的效果。


