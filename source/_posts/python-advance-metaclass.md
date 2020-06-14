title: Python技术进阶——元类
date: 2018-04-19 12:34:12
categories: Python
tags: [python]
---

> Python中的元类`metaclass`，我们在开发中用到的不是很多，这个特性常用于开源框架中。
> 
> 不过理解元类能够帮我们更深入地理解Python的设计理念，以及Python世界中常说的：**一切皆对象**！
> 

# 什么是元类

我们知道类（`class`）是创建实例（`instance`）的东西，在Python中，元类（`metaclass`）是创建类（`class`）的东西，关系如下图：

![](https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/metaclass-relation.png?imageMogr2/thumbnail/!70p)

简单来说，可以这样理解：

```python
klass = MetaClass()     # 元类创建类
obj = klass()           # 类创建实例
```

我们可以通过`__class__`属性来查看一个实例的类：

```python
>>> a = 1               # 创建a的类是int,a是int的实例
>>> a.__class__
<type 'int'>

>>> b = 'abc'           # 创建b的类是str,b是str的实例
>>> b.__class__
<type 'str'>

>>> def c():            # 创建c的类是function,方法c是function的实例
...     pass
>>> c.__class__
<type 'function'>

>>> class D(object):    # 创建d的类是D,d是D的实例
...     pass
>>> d.__class__
<class '__main__.D'>
```

平时我们在使用`int`、`str`、`list`、`dict`等内置对象时，实际上使用的是这些类创建出来的实例。

我们再来看，创建这些类的是什么？

```python
>>> a = 1
>>> a.__class__.__class__
<type 'type'>
>>>
>>> b = 'abc'
>>> b.__class__.__class__
<type 'type'>
>>>
>>> def c():
...     pass
>>> c.__class__.__class__
<type 'type'>
>>>
>>> class D(object):
...     pass
>>> d = D()
>>> d.__class__.__class__
<type 'type'>
```

从代码结果看到，创建这些类的都是`type`，`type`是创建所有类的元类。

你可以更深刻地感受一下：**Python中一切皆对象！**我们也可以说元类是创建所有类的工厂。

在Python中，使用`type`关键字可就以创建一个类，`type`的语法：

```python
type(class_name, (base_class, ...), {attr_key: attr_value, ...})
```

使用`type`关键字创建一个类：

```python
>>> A = type('MyClass', (object, ), {}) # type创建一个类，继承object
>>> A
<class '__main__.MyClass'>
>>> A()
<__main__.MyClass object at 0x10d905950>
```

使用`type`关键字创建一个类，并包含某些属性和方法：

```python
>>> def foo(self):
...     return 'foo'
...
>>> name = 'zhangsan'
>>>
>>> B = type('MyClass', (object, ), {'name': name, 'foo': foo})     # type创建类B，继承object，包含name属性和foo方法
>>> B.name          # 打印属性name
'zhangsan'
>>> print B().foo() # 调用方法foo
foo
```

`type`是Python中使用的内建元类，其实它也允许我们建立自己的元类。

<!-- more -->

# 自定义元类

在创建一个类时，加上一个属性`__metaclass__`：

```python
class A(object):
    __metaclass__ = ...     # 这个类的创建转交给其他元类
    pass
```

那么我们需要给`__metaclass__`赋值什么呢？

它可以是一个方法，也可以是一个类。

## 类被方法创建

```python
def create_class(name, bases, attr):
    print 'create class by method...'
    return type(name, bases, attr)  # 什么事都没做，直接用type创建了一个类

class A(object):
    __metaclass__ = create_class    # 创建类的过程交给了一个方法
    
# create class by method ...        # 只要这个类被解释器执行创建，就会调用create_class方法
```

## 类被另一个类创建

一个被另一个类创建，这个类必须要继承`type`，并实现`__new__`方法：

```python
class B(type):

    def __new__(cls, name, bases, attr):
        print 'create class by B ...'
        return type(name, bases, attr)

class A(object):
    __metaclass__ = B       # 创建类的过程交给了B
    
# create class by B ...    # 只要这个类被解释器执行创建，就会调用B的__new__
```

## 创建类的过程

上面我们演示了通过元类创建一个类的2种方式，总结一下创建一个类的过程：

- 检查类中是否有`__metaclass__`属性，如果有，调用`__metaclass__`指定的方法或类创建
- 如果类中没有`__metaclass__`属性，会继续在父类寻找
- 任何父类中都没有，那么就用`type`创建这个类

也就是说，如果我们没有指定`__metaclass__`，所有的类都是默认由`type`创建，如果指定了`__metaclass__`，那么就交给元类创建。

## 哪种方式更好？

虽然有2种方式可以创建元类，但一般我们建议使用类的方式创建，优点如下：

- 更能清楚地表达意图
- 更加OOP，类可以继承其他类，更友好地使用面向对象特性
- 更好地组织代码结构

其实在创建元类时，不建议直接调用`type`方法，而是建议使用`super`：

```python
class B(type):

    def __new__(cls, name, bases, attr):
        # 使用super调用type
        return super(B, cls).__new__(cls, name, bases, attr)    
```

## 创建类时自定义行为

上面创建类时，我们什么都没做，只是调用了`type`方法去创建类。其实我们在自定义元类时，通常会加入一些自定义的行为，这样就能很方便地给这个类的所有实例都增加了某种属性和行为。

```python
class B(type):

    def __new__(cls, name, bases, attr):
        # 通过B创建的类属性都变成大写
        for k, v in attr.items():
            if not k.startswith('__'):
                attr[k] = v.upper()
            else:
                attr[k] = v
        return type(name, bases, attr)

class A(object):

    __metaclass__ = B       # 通过B创建类

    name = 'zhangsan'

class C(object):

    __metaclass__ = B       # 通过B创建类

    name = 'lisi'

print A.name                # ZHANGSAN
print C.name                # LISI
```

上面代码展示了如何在自定义元类中，修改了通过这个元类创建的类的属性，当然你可以针对一个类中的方法进行操作。

# 使用场景

元类在平时开发中我们使用较少，只在一些开源框架中进行使用，例如`Django ORM`、`peewee`。

`Django ORM`使用元类的应用场景：

```python
class Person(models.Model):
    name = models.CharField(max_length=30)
    age = models.IntegerField()
    
person = Person(name='zhangsan', age=20)
print person.name       # zhangsan
print person.age        # 20
```

`Person`定义了类属性`name`和`age`，它们的类型分别是`CharField`和`IntegerField`，但在`Person`的实例调用时，输出确实`str`和`int`。

秘密就在于`Person`的创建交给了另一个类，这个类针对类属性进行了其他操作，最终达到对象与数据库的映射，并提供友好的访问方式。

元类是一个更强大的魔术，它可以在创建一个类的同时，修改这个类，然后返回修改后的类。

虽然大部分场景都不会使用它，但在使用它时要谨慎且合理。




