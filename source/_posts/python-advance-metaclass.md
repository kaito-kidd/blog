title: Python进阶——什么是元类？
date: 2018-04-19 12:34:12
categories: Python
tags: [python]
---

如果你看过比较优秀的 Python 开源框架，肯定见到过元类的身影。例如，在一个类中定义了类属性 `__metaclass__`，这就说明这个类使用了元类来创建。

那元类的实现原理究竟是怎样的？使用元类能帮我们在开发中解决什么样的问题？

这篇文章，我们就来看一下 Python 元类的来龙去脉。

# 什么是元类？

我们都知道，定义一个类，然后调用它的构造方法，就可以初始化出一个实例出来，就像下面这样：

```python
class Person(object)

    def __init__(name):
        self.name = name

p = Person('zhangsan')
```

那你有没有想过，我们平时定义的类，它是如何创建出来的？

别着急，我们先来看一个例子：

```python
>>> a = 1               # 创建a的类是int a是int的实例
>>> a.__class__
<type 'int'>

>>> b = 'abc'           # 创建b的类是str b是str的实例
>>> b.__class__
<type 'str'>

>>> def c():            # 创建c的类是function 方法c是function的实例
...     pass
>>> c.__class__
<type 'function'>

>>> class D(object):    # 创建d的类是D d是D的实例
...     pass
>>> d.__class__
<class '__main__.D'>
```

在这个例子中，我们定义了 `int`、`str`、`function`、`class`，然后分别调用了它们的`__class__` 方法，这个 `__class__` 方法可以返回实例是如何创建出来的。

从方法返回的结果我们可以看到：

- 创建整数 `a` 的类是 `int`，也就是说 `a` 是 `int` 的一个实例
- 创建字符串 `b` 的类是 `str`，也就是说 `b` 是 `str` 的一个实例
- 创建函数 `c` 的类是 `function`，也就是说 `c` 是 `function` 的一个实例
- 创建实例 `d` 的类是 `class`，也就是说 `d` 是 `class` 的一个实例

除了这些之外，我们在开发中使用到的例如 `list`、`dict` 也类似，你可以测试观察一下结果。

现在我们已经得知，创建这些实例的类是 `int`、`str`、`function`、`class`，那进一步思考一下，这些类又是怎么创建出来的呢？

同样地，我们也调用这些类的 `__class__` 方法，观察结果：

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

从结果我们可以看到，创建这些类的类，都是 `type`，所以 `type` 就是创建所有类的「元类」。也就是说，**元类的作用就是用来创建类的**。

你可以这样理解：

1. 元类 -> 类 
2. 类 -> 实例

用伪代码表示，就是下面这样：

```python
klass = MetaClass()     # 元类创建类
obj = klass()           # 类创建实例
```

是不是很有意思？

在这里，你也可以感受一下这句话的含义：**Python 中一切皆对象！**

无论是普通类型、方法、实例，还是类，都可以统一看作对象，它们的起源就是元类。

其实，在 Python 中，使用 `type` 方法，我们可就以创建出一个类，`type` 方法的语法如下：

```python
type(class_name, (base_class, ...), {attr_key: attr_value, ...})
```

例如，像下面这样，我们使用 `type` 方法创建 MyClass 类，并且让它继承 `object`：

```python
>>> A = type('MyClass', (object, ), {}) # type创建一个类，继承object
>>> A
<class '__main__.MyClass'>
>>> A()
<__main__.MyClass object at 0x10d905950>
```

我们还可以使用 `type` 创建一个包含属性和方法的类：

```python
>>> def foo(self):
...     return 'foo'
...
>>> name = 'zhangsan'
>>>
# type 创建类B 继承object 包含 name 属性和 foo 方法
>>> B = type('MyClass', (object, ), {'name': name, 'foo': foo}) 
>>> B.name          # 打印 name 属性
'zhangsan'
>>> print B().foo() # 调用 foo 方法
foo
```

通过 `type` 方法创建的类，和我们自己定义一个类，在使用上没有任何区别。

其实，除了使用 `type` 方法创建一个类之外，我们还可以使用类属性 `__metaclass__` 创建一个类，这就是下面要讲的「自定义元类」。

<!-- more -->

# 自定义元类

我们可以使用类属性 `__metaclass__` 把一个类的创建过程，转交给其它地方，可以像下面这样写：

```python
class A(object):
    __metaclass__ = ... # 这个类的创建转交给其他地方
    pass
```

这个例子中，我们先定义了类 A，然后定义了一个类属性 `__metaclass__`，这个属性表示创建类 A 的过程，转交给其它地方处理。

那么，这个类属性 `__metaclass__` 需要怎么写呢？

其实，它可以是一个方法，也可以是一个类。

## 用方法创建类

如果类属性 `__metaclass__` 赋值的是一个方法，那么创建类的过程，就交给了一个方法来执行。

```python
def create_class(name, bases, attr):
    print 'create class by method...'
    # 什么事都没做 直接用type创建了一个类
    return type(name, bases, attr)

class A(object):
    # 创建类的过程交给了一个方法
    __metaclass__ = create_class

# Output:    
# create class by method ...
```

我们定义了 `create_class` 方法，然后赋值给 `__metaclass__`，那么类 A 被创建时，就会调用 `create_class` 方法。

而 `create_class` 方法中的逻辑，就是我们上面所讲到的，使用 `type` 方法创建出一个类，然后返回。

## 用类创建类

明白了用方法创建类之后，我们来看一下用类来创建另一个类。

```python
class B(type):
    # 必须定义 __new__ 方法 返回一个类
    def __new__(cls, name, bases, attr):
        print 'create class by B ...'
        return type(name, bases, attr)

class A(object):
    # 创建类的过程交给了B
    __metaclass__ = B
    
# Output:
# create class by B ...
```

在这个例子中，我们定义了类 B，然后把它赋值给了 A 的类变量 `__metaclass__`，这就表示创建 A 的过程，交给了类 B。

B 在定义时，首先继承了 `type`，然后定义了 `__new__` 方法，最后调用 `type` 方法返回了一个类，这样当创建类 A 时，会自动调用类 B 的 `__new__` 方法，然后得到一个类实例。

## 创建类的过程

好了，上面我们演示了通过元类创建一个类的两种方式，分别是通过方法创建和通过类创建。

其实创建一个类的完整流程如下：

1. 检查类中是否有 `__metaclass__` 属性，如果有，则调用 `__metaclass__` 指定的方法或类创建
2. 如果类中没有 `__metaclass__` 属性，那么会继续在父类中寻找
3. 如果任何父类中都没有，那么就用 `type` 创建这个类

也就是说，如果我们没有指定 `__metaclass__`，那么所有的类都是默认由 `type` 创建，这种情况是我们大多数定义类时的流程。

如果类中指定了 `__metaclass__`，那么这个类的创建就会交给外部来做，外部可以定义具体的创建逻辑。

## 哪种创建类的方式更好？

虽然有两种方式可以创建类，那么哪种方式更好呢？

一般我们建议使用类的方式创建，它的优点如下：

- 使用类更能清楚地表达意图
- 使用类更加 OOP，因为类可以继承其他类，而且可以更友好地使用面向对象特性
- 使用类可以更好地组织代码结构

另外，使用类创建一个类时，这里有一个优化点：在 `__new__` 方法中不建议直接调用 `type` 方法，而是建议调用 `super` 的 `__new__` 来创建类，执行结果与 `type` 方法是一样的：

```python
class B(type):

    def __new__(cls, name, bases, attr):
        # 使用 super.__new__ 创建类
        return super(B, cls).__new__(cls, name, bases, attr)    
```

## 创建类时自定义行为

前面我们用元类创建一个类时，它的功能非常简单。现在我们来看一下，使用元类创建类时，如何定义一些自己的逻辑，然后改变类的属性或行为。

我们看下面这个例子：

```python
# coding: utf8

class Meta(type):
    def __new__(cls, name, bases, attr):
        # 通过 Meta 创建的类 属性会都变成大写
        for k, v in attr.items():
            if not k.startswith('__'):
                attr[k] = v.upper()
            else:
                attr[k] = v
        return type(name, bases, attr)

class A(object):
    # 通过 Meta 创建类
    __metaclass__ = Meta

    name = 'zhangsan'

class B(object):
    # 通过 Meta 创建类
    __metaclass__ = Meta

    name = 'lisi'

# 打印类属性 会自动变成大写
print A.name    # ZHANGSAN
print B.name    # LISI
```

在这个例子中，我们定义了一个元类 `Meta`，然后在定义类 A 和 B 时，把创建类的过程交给了  `Meta`，在 `Meta` 类中，我们可以拿到 A 和 B 的属性，然后把它们的属性都转换成了大写。

所以当我们打印 A 和 B 的属性时，虽然定义的变量是小写的，但输出结果都变成了大写，这就是元类发挥的作用。

# 使用场景

了解了元类的实现原理，那么元类都会用在哪些场景呢？

我们在开发中其实用的并不多，元类的使用，经常会出现在一些框架中，例如`Django ORM`、`peewee`，下面是使用 `Django ORM` 定义一个数据表映射类的代码：

```python
class Person(models.Model):
    # 注意: name 和 age 是类属性
    name = models.CharField(max_length=30)
    age = models.IntegerField()
    
person = Person(name='zhangsan', age=20)
print person.name   # zhangsan
print person.age    # 20
```

仔细看在这段代码中，我们定义了一个 `Person` 类，然后在类中定义了类属性 `name` 和 `age`，它们的类型分别是 `CharField` 和 `IntegerField`，之后我们初始化 `Person` 实例，然后通过实例获取 `name` 和 `age` 属性，输出的却是 `str` 和 `int`，而不再是 `CharField` 和 `IntegerField`。

能做到这样的秘密就在于，`Person` 类在创建时，它的逻辑交给了另一个类，这个类针对类属性进行了转换，最终变成对象与数据表的映射，通过转换映射，我们就可以通过实例属性的方式，友好地访问表中对应的字段值了。


# 总结

总结一下，这篇文章我们讲了元类的实现原理，了解到元类是创建所有类的根源，我们可以通过 `type` 方法，或者在类中定义 `__metaclass__` 的方式，把创建类的过程交给外部。

当使用 `__metaclass__` 创建类时，它可以是一个方法，也可以是一个类。我们通常会使用类的方式去实现一个元类，这样做更方便我们组织代码，实现面向对象。

在使用元类创建一个类时，我们可以修改创建类的细节，例如对属性做统一的转换，或者增加新的方法等等，这对于我们开发一个复杂功能的类很友好，它可以把创建类的细节屏蔽在元类中，所以元类常常用在优秀的开源框架中。
