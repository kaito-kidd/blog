title: Python技术进阶——魔法方法（二）
date: 2017-02-23 09:19:58
categories: Python
tags: [python]
---

在上一篇文章[Python技术进阶——魔法方法（一）](http://kaito-kidd.com/2017/02/22/python-magic-methods/)中，我们主要介绍了关于构造与初始化、类的表示、访问控制这几类的魔法方法，以及它们的使用场景。

这篇文章，我们继续介绍剩下的魔法方法，主要包括：比较操作、容器类操作、可调用对象、序列化。

# 比较操作

比较操作的魔法方法主要包括以下几种：

- `__cmp__`
- `__eq__`
- `__ne__`
- `__lt__`
- `__gt__`

## `__cmp__`

从名字我们就能看出来这个魔法方法的作用，当我们需要比较两个对象时，我们可以定义 `__cmp__` 来实现比较操作。

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

从例子中我们可以看到，比较两个对象的具体逻辑：

- 如果 `__cmp__` 返回大于 0 的整数（一般为1），说明 self > other
- 如果 `__cmp__` 返回大于 0 的整数（一般为-1），说明 self < other
- 如果 `__cmp__` 返回 0，说明 self == other

当然，这种比较方式有一定的局限性，如果我有 N 个属性，当比较谁大时，我们想用属性 A 来比较。当比较谁小时，我们想用属性 B 来比较，此时 `__cmp__` 就无法很好地实现这个逻辑了，所以它只适用于通用的比较逻辑。

那如何实现复杂的比较逻辑？

这就需要用到 `__eq__`、`__ne__`、`__lt__`、`__gt__` 这些魔法方法了，我们看下面这个例子。

```python
# coding: utf8

class Person(object):

    def __init__(self, uid, name, salary):
        self.uid = uid
        self.name = name
        self.salary = salary

    def __eq__(self, other):
        """对象 == 判断"""
        return self.uid == other.uid

    def __ne__(self, other):
        """对象 != 判断"""
        return self.uid != other.uid

    def __lt__(self, other):
        """对象 < 判断 根据len(name)"""
        return len(self.name) < len(other.name)

    def __gt__(self, other):
        """对象 > 判断 根据alary"""
        return self.salary > other.salary


p1 = Person(1, 'zhangsan', 1000)
p2 = Person(1, 'lisi', 2000)
p3 = Person(1, 'wangwu', 3000)

print p1 == p1	# uid 是否相同
print p1 != p2	# uid 是否不同
print p2 < p3	# name 长度比较
print p3 > p2	# salary 比较
```

## `__eq__`

`__eq__` 我们在上一篇文章已经介绍过，它配合 `__hash__` 方法，可以判断两个对象是否相等。

但在这个例子中，当判断两个对象是否相等时，实际上我们比较的是 `uid` 这个属性。

## `__ne__`

同样地，当需要判断两个对象不相等时，会调用 `__ne__` 方法，在这个例子中，我们也是根据 `uid` 来判断的。

## `__lt__`

当判断一个对象是否小于另一个对象时，会调用 `__lt__` 方法，在这个例子中，我们根据 `name` 的长度来做的比较。

## `__gt__`

同样地，在判断一个对象是否大于另一个对象时，会调用 `__gt__` 方法，在这个例子中，我们根据 `salary` 属性判断。

> 在 Python3 中，`__cmp__`被取消了，因为它和其他魔法方法存在功能上的重复。

<!-- more -->

# 容器类操作

接下来我们来看容器类的魔法方法，主要包括：

- `__setitem__`
- `__getitem__`
- `__delitem__`
- `__len__`
- `__iter__`
- `__contains__`
- `__reversed__`

是不是很熟悉？我们在开发中多少都使用到过这些方法。

在介绍容器的魔法方法之前，我们首先想一下，Python 中的容器类型都有哪些？

是的，Python 中常见的容器类型有：

- 字典
- 元组
- 列表
- 字符串

这些都是容器类型。为什么这么说？

因为它们都是「可迭代」的。可迭代是因为，它们都实现了容器协议，也就是我们下面要介绍到的魔法方法。

我们看下面这个例子。

```python
# coding: utf8

class MyList(object):
    """自己实现一个list"""

    def __init__(self, values=None):
        # 初始化自定义list
        self.values = values or []

    def __setitem__(self, key, value):
        # 添加元素
        self.values[key] = value

    def __getitem__(self, key):
        # 获取元素
        return self.values[key]

    def __delitem__(self, key):
        # 删除元素
        del self.values[key]

    def __len__(self):
        # 自定义list的元素个数
        return len(self.values)

    def __iter__(self):
        # 可迭代
        return self

    def next(self):
        # 迭代的具体细节
        # 如果__iter__返回self 则必须实现此方法
        if self._index >= len(self.values):
            raise StopIteration()
        value = self.values[self._index]
        self._index += 1
        return value

    def __contains__(self, key):
        # 元素是否在自定义list中
        return key in self.values

    def __reversed__(self):
        # 反转
        return list(reversed(self.values))

# 初始化自定义list
my_list = MyList([1, 2, 3, 4, 5])

print my_list[0]	     # __getitem__
my_list[1] = 20		     # __setitem__

print 1 in my_list	     # __contains__
print len(my_list)	     # __len__

print [i for i in my_list]  # __iter__
del my_list[0]	             # __del__

reversed_list = reversed(my_list) # __reversed__
print [i for i in reversed_list]  # __iter__
```

在这个例子中，我们自己实现了一个 MyList 类，在这个类中，定义了很多容器类的魔法方法。这样一来，我们这个 MyList 类就可以像操作普通 `list` 一样，通过切片的方式添加、获取、删除、迭代元素了。

## `__setitem__`

当我们执行 `my_list[1] = 20` 时，就会调用 `__setitem__` 方法，这个方法主要用于向容器内添加元素。

## `__getitem__`

当我们执行 `my_list[0]` 时，就会调用 `__getitem__` 方法，这个方法主要用于从容器中读取元素。

## `__delitem__`

当我们执行 `del my_list[0]` 时，就会调用 `__delitem__` 方法，这个方法主要用于从容器中删除元素。

## `__len__`

当我们执行 `len(my_list)` 时，就会调用 `__len__` 方法，这个方法主要用于读取容器内元素的数量。

## `__iter__`

这个方法我们需要重点关注，为什么我们可以执行 `[i for i in my_list]`？就是因为我们定义了 `__iter__`。

这个方法的返回值可以有两种：

- 返回 `iter(obj)`：代表使用 `obj` 对象的迭代协议，一般 `obj` 是内置的容器对象
- 返回 `self`：代表迭代的逻辑由本类来实现，此时需要重写 `next` 方法，实现自定义的迭代逻辑

在这个例子中，`__iter__` 返回的是 `self`，所以我们需要定义 `next` 方法，实现自己的迭代细节。

`next` 方法使用一个索引变量，用于记录当前迭代的位置，这个方法每次被调用时，都会返回一个元素，当所有元素都迭代完成后，这个方法会返回 `StopIteration` 异常，此时 `for` 会停止迭代。

> 在 Python3 中，已不再使用 next 方法，取而代之的是 `__next__`。

## `__contains__`

从名字也能看出来，这个方法是在执行 `1 in my_list` 时触发，用于判断某个元素是否存在于容器中。

## `__reversed__`

这个方法在执行 `reversed(my_list)` 时触发，用于反转容器的元素，具体的反转逻辑我们也可以自己实现。

# 可调用对象

了解了容器类魔法方法，我们接着来看可调用对象的魔法方法，这个魔法方法只有一个：`__call__`。

我们看下面这个例子。

```python
# coding: utf8

class Circle(object):

    def __init__(self, x, y):
        self.x = x
        self.y = y

    def __call__(self, x, y):
        self.x = x
        self.y = y

c = Circle(10, 20)	 # __init__
print c.x, c.y	    # 10 20

c(100, 200)	        # 调用instance() 触发__call__
print c.x, c.y	     # 100 200
```

仔细看这个例子，我们首先初始化一个 `Circle` 实例 `c`，此时会调用 `__init__` 方法，这个很好理解。

但是，我们对于实例 `c` 又做了调用 `c(100, 200)`，注意，此时的 `c` 是一个实例对象，当我们这样执行时，其实它调用的就是 `__call__`。这样一来，我们就可以把实例当做一个方法来执行。

如果不好理解，你可以多看几遍这个例子，理解一下。

也就是说，Python 中的实例，也是可以被调用的，通过定义 `__call__` 方法，就可以传入自定义参数实现自己的逻辑。

这个魔法方法通常会用在类实现一个装饰器、元类等场景中，当你遇到这个魔法方法时，你能理解其中的原理就可以了。

# 序列化

我们知道 Python 提供了序列号模块 `pickle`，当我们使用这个模块序列化一个实例时，也可以通过魔法方法来实现自己的逻辑，这些魔法方法包括：

- `__getstate__`
- `__setstate__`

我们来看下面的例子。

```python
# coding: utf8

class Person(object):

    def __init__(self, name, age, birthday):
        self.name = name
        self.age = age
        self.birthday = birthday

    def __getstate__(self):
        # 执行 pick.dumps 时 忽略 age 属性
        return {
            'name': self.name,
            'birthday': self.birthday
        }

    def __setstate__(self, state):
        # 执行 pick.loads 时 忽略 age 属性
        self.name = state['name']
        self.birthday = state['birthday']

person = Person('zhangsan', 20, date(2017, 2, 23))
pickled_person = pickle.dumps(person) # __getstate__

p = pickle.loads(pickled_person) # __setstate__
print p.name, p.birthday

print p.age	# AttributeError: 'Person' object has no attribute 'age'
```

## `__getstate__`

在这个例子中，我们首先初始了 `Person` 对象，其中包括 3 个属性：`name`、`age`、`birthday`。

当我们调用 `pickle.dumps(person)` 时，`__getstate__` 方法就会被调用，在这里我们忽略了 `Person` 对象的 `age` 属性，那么 `person` 在序列化时，就只会对其他两个属性进行保存。

## `__setstate__`

同样地，当我们调用 `pickle.loads(pickled_person)` 时，`__setstate__` 会被调用，其中入参就是 `__getstate__` 返回的结果。

在 `__setstate__` 方法，我们从入参中取得了被序列化的 `dict`，然后从 `dict` 中取出对应的属性，就达到了反序列的效果。

# 其他魔法方法

好了，以上介绍的这些，就是我们平时遇到比较多的魔法方法。

剩下的魔法方法还有很多，主要包括数值处理、算术操作、反射算术操作、增量赋值、类型转换、反射这几类，由于我们在开发中很少会见到，这里就不再过多介绍了，当遇到时，我们直接查阅文档了解即可。

# 总结

这篇文章，我们主要介绍了关于比较操作、容器类、可调用对象、序列化等魔法方法。

其中，比较操作的魔法方法，可以用于自定义实例的比较逻辑。容器类魔法方法，可以帮我们实现一个自定义的容器类，然后我们就可以像操作 `list`、`dict` 那样，方便地去获取容器里的元素、迭代数据等等。可调用对象魔法方法，可以把一个实例当做方法来调用。序列化的魔法方法，可以修改一个实例的序列化和反序列化逻辑。

Python 的魔法方法正如它的名字一样，如果使用得当，我们的类就像被添加了魔法一样，变得更易用。我们可以使用这些魔法方法，帮我们实现一些复杂的功能，例如装饰器、元类等等。