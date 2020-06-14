title: Python技术进阶——魔法方法（二）
date: 2017-02-23 09:19:58
categories: Python
tags: [python]
---

> 在上一篇文章[Python技术进阶——魔法方法（一）](http://kaito-kidd.com/2017/02/22/python-magic-methods/)中，主要介绍了构造与初始化、类的表示、访问控制这几大类魔法方法，同时阐述了各自的使用场景。
>
> 本篇文章继续介绍剩下的魔法方法，主要包括：比较操作、容器类操作、可调用对象、Picking序列化。

# 比较操作

## `__cmp__`

在比较2个对象时，我们可以定义`__cmp__`方法，来达到比较的操作。

```python
class Person(object):
	def __init__(self, uid):
        self.uid = uid

    def __cmp__(self, other):
        if self.uid == other.uid:
            return 0
        if self.uid > other.uid:
            return 1
        return -1

p1 = Person(1)
p2 = Person(2)
print p1 > p2	# False
print p1 < p2	# True
print p1 == p2	# False
```
- self > other，则返回大于0的整数，一般为1
- self < other，返回小于0的整数，一般为-1
- self == other，返回0

当然，这种比较有局限性，如果我有N个属性，比较最大时，我想用第一个属性比较，比较最小时，我想用第二个属性比较，此时`__cmp__`就不合适了，它只能用于通用的比较逻辑。如何进行不同的比较逻辑，我们可以使用如下方式：

```python
class Person(object):

    def __init__(self, uid, name, salary):
        self.uid = uid
        self.name = name
        self.salary = salary

    def __eq__(self, other):
        """对象==判断"""
        return self.uid == other.uid

    def __ne__(self, other):
        """对象!=判断"""
        return self.uid != other.uid

    def __lt__(self, other):
        """对象<判断,根据len(name)"""
        return len(self.name) < len(other.name)

    def __gt__(self, other):
        """对象>判断,根据alary"""
        return self.salary > other.salary


p1 = Person(1, 'zhangsan', 1000)
p2 = Person(1, 'lisi', 2000)
p3 = Person(1, 'wangwu', 3000)

print p1 == p1	# uid是否相同
print p1 != p2	# uid是否不同
print p2 < p3	# name长度比较
print p3 > p2	# salary大小
```

## `__eq__`

在判断两个对象是否相等`==`时，此方法被调用。同时在上一篇文章中也介绍到，如果需要在`set`、`dict`中实现去重，可配合`__hash__`方法使用。

## `__ne__`

在判断两个对象是否不相等`!=`时，此方法被调用。

## `__lt__`

在判断一个对象是否小于`<`另一个对象时，此方法被调用。

## `__gt__`

在判断一个对象是否大于`>`另一个对象时，此方法被调用。

> 在Python3中，`__cmp__`被取消了，因为和其他魔法方法有功能上的重复。

<!-- more -->

# 容器类操作

首先说明一下Python中内建的容器类型都有哪些？

**字典、元组、列表、字符串**都是容器类型，之所以是容器类型，是因为它们实现了一些协议。

这就是我们下面要讲到的容器类魔法方法：

```python
class WrapperList(object):

    def __init__(self, values=None):
        self.values = values or []

    def __setitem__(self, key, value):
        self.values[key] = value

    def __getitem__(self, key):
        return self.values[key]

    def __delitem__(self, key):
        del self.values[key]

    def __len__(self):
        return len(self.values)

    def __iter__(self):
        return self

    def next(self):
        """如果__iter__返回self，则必须实现此方法"""
        if self._index >= len(self.values):
            raise StopIteration()
        value = self.values[self._index]
        self._index += 1
        return value

    def __contains__(self, key):
        return key in self.values

    def __reversed__(self):
        return list(reversed(self.values))
    
my_list = WrapperList([1, 2, 3, 4, 5])
print my_list[0]	# __getitem__
my_list[1] = 20		# __setitem__
print 1 in my_list	# __contains__
print 100 in my_list	# __contains__

print len(my_list)	# __len__

print [i for i in my_list]	# __iter__

del my_list[0]	# __del__

reversed_list = reversed(my_list)	# __reversed__
print [i for i in reversed_list]	# __iter__
```

## `__setitem__`

此方法在执行`obj[key] = value`时触发执行，用于修改容器的某个元素。

## `__getitem__`

执行`obj[key]`触发执行，用于获取容器的某个元素。

## `__delitem__`

执行`del obj[key]`时触发执行，用于删除容器的某个元素。

## `__len__`

执行`len(obj)`时触发执行，用于获取容器内的元素个数。

## `__iter__`

执行`for x in obj`时触发执行，用于迭代容器内的元素。

注意，一般此方法会有两种方式返回：

- 返回`iter(obj)`：代表使用`obj`对象的迭代协议，一般`obj`是内置的容器对象
- 返回`self`：代表迭代的逻辑由本类来实现，要重写`next`方法，实现自定义的迭代逻辑

> 在Python3中，不在使用next方法，而替换成`__next__`方法了。

## `__contains__`

执行`x in obj`时触发执行，用于判断某个元素是否存在于容器中。

## `__reversed__`

执行`reversed(obj)`时触发执行，用于反转容器的元素，具体的反转逻辑可自己实现。

# 可调用对象

## `__call__`

我们知道类中的方法是可调用的，其实实例也是可以被调用的，我们只需要实现`__call__`：

```python
class Circle(object):

    def __init__(self, x, y):
        self.x = x
        self.y = y

    def __call__(self, x, y):
        self.x = x
        self.y = y

c = Circle(10, 20)	# __init__
print c.x, c.y	# 10 20

c(100, 200)	# 调用实例(),触发__call__
print c.x, c.y	# 100 200
```

首先实例化这个类，触发`__init__`，然后通过实例调用触发`__call__` ，修改了实例变量。

此方法常见用于用类实现一个装饰器、元类等场景中。

# Pickling序列化

在我们使用`pickle`模块对数据进行序列化和反序列化时，我们可以通过定义相关的魔术方法，自定义序列化和反序列化逻辑：

```python
class Person(object):

    def __init__(self, name, age, birthday):
        self.name = name
        self.age = age
        self.birthday = birthday

    def __getstate__(self):
        """pick.dumps,忽略了age属性"""
        return {
            'name': self.name,
            'birthday': self.birthday
        }

    def __setstate__(self, state):
        """pick.loads,忽略了age属性"""
        self.name = state['name']
        self.birthday = state['birthday']

person = Person('zhangsan', 20, date(2017, 2, 23))
pickled_person = pickle.dumps(person)	# __getstate__

p = pickle.loads(pickled_person)	# __setstate__
print p.name, p.birthday

print p.age	# AttributeError: 'Person' object has no attribute 'age'
```

## `__getstate__`

当调用`pickle.dumps`时，此方法被调用，可以需要被序列化的数据，例如上面这个例子忽略了`age`属性，那么在序列化后只会对其他两个属性进行保存。

## `__setstate__`

同样，当调用`pickle.loads`时，此方法被调用，传入一个参数，此参数就是`__getstate__`返回的结果。`__setstate__`根据这个参数重新初始化实例属性，已达到反序列化数据的目的。

# 其他魔法方法

主要的几大类魔法方法就是上述这些，剩下的当然还有很多，只不过我们在开发中很少会用到，这里就不再过多介绍了，需要的时候再查文档即可。剩下的魔法方法主要有这几类，了解一下就好：

## 数值处理

一元操作符和函数：仅仅有一个操作位的一元操作符和函数

`__os__(self)`：正号
`__eg__(self)`：负号
`__bs__(self)`：实现内置`abs()`函数的行为
`__nvert__(self)` ：`~`符号

## 算数操作

`__dd__(self, other)`：加法
`__ub__(self, other)`：减法
`__ul__(self, other)`：乘法
`__loordiv__(self, other)`：地板除法，使用`//`操作符
`__iv__(self, other)`：传统除法，使用`/`操作符
`__ruediv__(self, other)`：真正除法。注意，只有当`from __uture__ import division`时才会有效
`__od__(self, other)`：求模，使用`%`操作符
`__ivmod__(self, other)`：实现内建函数`divmod()`的行为
`__ow__(self, other)`：乘方，使用`**`操作符
`__shift__(self, other)`：左按位位移，使用`<<`操作符
`__shift__(self, other)`：右按位位移，使用`>>`操作符
`__nd__(self, other)`：按位与，使用`&`操作符
`__r__(self, other)`：按位或，使用`|`操作符
`__or__(self, other)`：按位异或，使用`^`操作符

## 反射算术操作

`__add__(self, other)`：反射加法
`__sub__(self, other)`：反射减法
`__mul__(self, other)`：反射乘法
`__floordiv__(self, other)`：反射地板除，用`//`操作符
`__div__(self, other)`：传统除法，用`/`操作符
`__turediv__(self, other)`：真实除法，注意，只有当`from __uture__ import division`时才会有效
`__mod__(self, other)`：反射求模，用`%`操作符
`__divmod__(self,other)`：实现内置函数`divmod()`的长除行为，当调用`divmod(other,self)`时被调用
`__pow__(self, other)`：反射乘方，用`**`操作符
`__lshift__(self, other)`：反射的左按位位移，使用`<<`操作符
`__rshift__(self, other)`：反射的右按位位移，使用`>>`操作符
`__and__(self, other)`：反射的按位与，使用`&`操作符
`__or__(self, other)`：反射的按位或，使用`|`操作符
`__xor__(self, other)`：反射的按位异或，使用`^`操作符

## 增量赋值

`__add__(self, other)`：加法和赋值
`__sub__(self, other)`：减法和赋值
`__mul__(self, other)`：乘法和赋值
`__floordiv__(self, other)`：地板除和赋值，用`//=`操作符
`__div__(self, other)`：传统除法和赋值，用`/=`操作符
`__turediv__(self, other)`：真实除法和赋值，注意，只有当`from __uture__ import division`时才会有效
`__mod__(self, other)`：求模和赋值，用`%=`操作符
`__pow__(self, other)`：乘方和赋值，用`**=`操作符
`__lshift__(self, other)`：左按位位移和赋值，使用`<<=`操作符
`__rshift__(self, other)`：右按位位移和赋值，使用`>>=`操作符
`__and__(self, other)`：按位与和赋值，使用`&=`操作符
`__or__(self, other)`：按位或和赋值，使用`|=`操作符
`__xor__(self, other)`：按位异或和赋值，使用`^=`操作符

## 类型转换

`__nt__(self)`：实现到整型的类型转换
`__ong__(self)`：长整形
`__loat__(self)`：浮点型
`__omplex__(self)`：复数型
`__ct__(self)`：8进制型
`__ex__(self)`：16进制型
`__ndex__(self)`：实现一个当对象被切片到int的类型转换。若自定义了一个数值类型，考虑到它可能被切片，要重载`__ndex__`
`__runc__(self)`：当`math.trunc(self)`被调用时调用。返回一个整型的截断
`__oerce__(self,other)`：实现混合模式的算术。如果类型转换不可能则返回`None`。否则，它应当返回一对相同类型的元祖

## 反射

`__nstancecheck__(self, instance)`：检查一个实例是否是你定义类中的一个实例
`__ubclasscheck__(self, subclass)`：检查一个类是否是你定义类的子类

