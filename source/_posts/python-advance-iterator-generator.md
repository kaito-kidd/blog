title: Python技术进阶——迭代器、可迭代对象、生成器
date: 2018-04-18 11:33:10
tags: [python]
---

> 在Python开发中，我们见过很常见的概念，如`容器`、`可迭代对象`、`迭代器`、`生成器`。
> 
> 这些概念之间有什么联系和区别呢？
> 

# 总览

容器（`container`）、可迭代对象（`iterable`）、迭代器（`iterator`）、生成器（`generator`）的关系如下图：

![](https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/relationships.png?imageMogr2/thumbnail/!70p)

- `list`、`set`、`tuple`、`dict`都是容器
- 容器通常是一个可迭代对象
- 但凡可以返回一个迭代器的对象，都称之为可迭代对象
- 实现了迭代器协议方法的称作一个迭代器
- 生成器是一种特殊的迭代器

# 容器

简单来说，容器就是存储一些事物的概念统称，它最大的特性就是给你一个事物，告诉我这个事物是否在这个容器内。

在Python中，使用`in`或`not in`来判断某个事物是存在或不存在某个容器内。

也就是说一个对象实现了`__contains__`方法，我们都可以称之为容器。

在Python中，`str`、`list`、`tuple`、`set`、`dict`都是容器，因为我们可以用`in`或`not in`语法得知某个元素是否在容器内，它们内部都实现了`__contains__`方法。

```python
print 1 in [1, 2, 3]    # True
print 2 not in (1, 2, 3)        # False
print 'a' in ('a', 'b', 'c')    # True
print 'x' in 'xyz'      # True
print 'a' not in 'xyz'      # True
```

如果我们想自定义一个容器，只需像下面这样：

```python
class A(object):

    def __init__(self):
        self.items = [1, 2]

    def __contains__(self, item):   # x in y
        return item in self.items

a = A()
print 1 in a    # True
print 2 in a    # True
print 3 in a    # False
```

但一个容器不一定支持输出存储在内的所有元素的功能。

一个容器要想输出保存在内的所有元素，其内部需要实现迭代器协议。

<!-- more -->

# 迭代器

一个对象如果实现了迭代器协议，就可以称之为迭代器。

在Python中实现迭代器协议，需要实现以下2个方法：

- `__iter__`，这个方法返回对象本身
- Python2中实现`next`，Python3中实现`__next__`，这个方法每次返回迭代的值，在没有可迭代元素时，抛出`StopIteration`异常

下面我们实现一个自定义的迭代器：

```python
class A(object):
    """内部实现了迭代器协议，这个对象就是一个迭代器"""
    def __init__(self, n):
        self.idx = 0
        self.n = n

    def __iter__(self):
        print '__iter__'
        return self

    def next(self):
        if self.idx < self.n:
            val = self.idx
            self.idx += 1
            return val
        else:
            raise StopIteration()

# 迭代元素
a = A(3)
for i in a:
    print i
print '-------'
# 再次迭代，没有元素输出，迭代器只能迭代一次
for i in a:
    print i

# __iter__
# 0
# 1
# 2
# -------
# __iter__
```

在执行`for`循环时，我们看到`__iter__`的打印被输出，然后依次输出`next`中的元素。

其实在执行`for`循环时，实际调用顺序是这样的：

```
for i in a => b = iter(a) => next(b) => next(b) ... => StopIteration => end
```

首选执行`iter(a)`，`iter`会调用`__iter__`，在得到一个迭代器后，循环执行`next`，`next`会调用迭代器的`next`，在遇到`StopIteration`异常时，停止迭代。

但注意，再次执行迭代器，如果所有元素都已迭代完成，将不会再次迭代。

如果我们想每次执行都能迭代元素，只需在迭代时，执行的都是一个新的迭代器即可：

```python
for i in A(3):
    print i

# 每次执行一个新的迭代对象
for i in A(3):
    print i
```

# 可迭代对象

但凡是可以返回一个**迭代器**的对象，都可以称之为可迭代对象。

这句话怎么理解？

可以翻译为：**`__iter__`方法返回迭代器，这个对象就是可迭代对象。**

我们在上面看到的迭代器，也就是说实现了`__iter__`和`next/__next__`方法的类，这些类的实例就是一个可迭代对象。

**迭代器一定是个可迭代对象，但可迭代对象不一定是迭代器。**

这句话怎么理解？我们看代码:

```python
class A(object):
    """
    A的实例不是迭代器，因为只A实现了__iter__
    但这个类的实例是一个可迭代对象
    因为__iter__返回了B的实例，也就是返回了一个迭代器，因为B实现了迭代器协议
    返回一个迭代器的对象都被称为可迭代对象
    """
    def __init__(self, n):
        self.n = n

    def __iter__(self):
        return B(self.n)

class B(object):
    """这个类是个迭代器，因为实现了__iter__和next方法"""
    def __init__(self, n):
        self.idx = 0
        self.n = n

    def __iter__(self):
        return self

    def next(self):
        if self.idx < self.n:
            val = self.idx
            self.idx += 1
            return val
        else:
            raise StopIteration()

b = B(3)        # b是一个迭代器，同时b是一个可迭代对象
for i in b:
    print i
print iter(b)   # <__main__.B object at 0x10eb95450>

a = A(3)        # a不是迭代器，但a是可迭代对象，它把迭代细节交给了B，B的实例是迭代器
for i in a:
    print i
print iter(a)   # <__main__.B object at 0x10eb95550>
```

对于`B`：

- `B`的实例是一个迭代器，因为其实现了迭代器协议`__iter__`和`next`方法
- 同时`B`的`__iter__`方法返回了`self`实例本身，也就是说返回了一个迭代器，所以`B`的实例`b`也是一个可迭代对象

对于`A`：

- `A`的实例不是一个迭代器，因为没有同时满足`__iter__`和`next`方法
- 由于`A`的`__iter__`返回了`B`的实例，而`B`的实例是一个迭代器，所以`A`的实例`a`是一个可迭代对象，换句话说，`A`把迭代细节交给了`B`

**其实我们使用的内置对象`list`、`tuple`、`set`、`dict`，都叫做可迭代对象，但不是一个迭代器，因为其内部都把迭代细节交给了另外一个类，这个类才是真正的迭代器：**

```python
>>> l = [1, 2]      # list是可迭代对象
>>> iter(l)         # list返回的迭代器是listiterator
<listiterator object at 0x10599c350>    
>>> iter(l).next()  # 迭代器有next方法
>>> 1

>>> t = ('a', 'b')  # tuple是可迭代对象
>>> iter(t)         # tuple返回的迭代器是tupleiterator
<tupleiterator object at 0x10599c390>   
>>> iter(t).next()  # 迭代器有next方法
>>> a

>>> s = {1, 2}      # set是可迭代对象
>>> iter(s)         # set返回的迭代器是setiterator
<setiterator object at 0x10592df50> # 
>>> iter(s).next()  # 迭代器有next方法
>>> 1

>>> d = {'a': 1, 'b': 2}    # dict是可迭代对象
>>> iter(d)                 # dict返回的迭代器是dictionary-keyiterator
<dictionary-keyiterator object at 0x105977db8>
>>> iter(d).next()          # 迭代器有next方法
>>> a
```

# 生成器

生成器是特殊的迭代器，它也是个可迭代对象。

有2种方式可以创建一个生成器：

- 生成器表达式
- 生成器函数

生成器表达式如下：

```python
>>> g = (i for i in range(5))   # 创建一个生成器
>>> g
<generator object <genexpr> at 0x101334f50>
>>> iter(g)         # 生成器就是一个迭代器
<generator object <genexpr> at 0x101334f50>
>>> for i in g:     # 生成器也是一个可迭代对象
...     print i
# 0 1 2 3 4
```

生成器函数，包含`yield`关键字的函数：

```python
def gen(n):
    # 生成器函数
    for i in range(n):
        yield i

g = gen(5)      # 创建一个生成器
print g         # <generator object gen at 0x10bb46f50>
print type(g)   # <type 'generator'>

# 迭代
for i in g:
    print i
# 0 1 2 3 4
```

一般情况下，我们使用比较多的情况是以函数的方式创建生成器，也就是函数中使用`yield`关键字。

这个函数与包含`return`的函数执行机制不同：

- 包含`return`的方法会以`return`关键字为终结返回，每次执行都返回相同的结果
- 包含`yield`的方法一般用于迭代，每次执行遇到`yield`即返回`yield`后的结果，但内部会保留上次执行的状态，下次迭代继续执行`yield`之后的代码，直到再次遇到`yield`并返回

当我们想得到一个很大的集合时，如果使用普通方法，一次性生成出这个集合，然后`return`返回：

```python
def gen_data(n):
    return [i for i in range(n)]    # 一次性生成大集合
```

但如果这个集合非常大时，就需要在内存中一次性占用非常大的内存。

使用`yield`能够完美解决这类问题，因为`yield`是懒惰执行的，一次只会返回一个值：

```python
for gen_data(n):
    for i in range(n):
        yield i         # 每次只生成一个元素
```

生成器在Python中还有更大的用处，我们来看生成器中还有哪些方法：

```python
>>> g = (i for i in range(3))
>>> dir(g)
['__class__', '__init__', '__iter__', 'next', 'send', 'throw' ...
```

我们发现生成器中还包含了一个叫做`send`的方法，如何使用？

```python
def gen(n):
    for i in range(n):
        a = yield i
        if a == 100:
            print 'a is 100'

a = gen(10)         # 创建生成器
print a.next()      # 0
print a.next()      # 1
print a.send(100)   # send(100)赋值给a 然后打印出'a is 100'
print a.next()      # 2
```

生成器允许在执行时，外部自定义一个值传入生成器内部，从而影响生成器的执行结果。

正因为有了这个机制，Python的生成器在开发中有了很大的应用场景，我们后面单独讲它的具体使用场景和优点。

# 总结

这里总结一下`迭代器`、`可迭代对象`、`生成器`它们之间的联系与区别：

- 迭代器必须实现迭代器协议`__iter__`和`next/__next`方法
- `__iter__`返回迭代器的对象称作可迭代对象
- 迭代器一定是个可迭代对象，但可迭代对象不一定是迭代器，有可能迭代细节交付给另一个类，这个类才是迭代器
- 生成器一定是一个迭代器，同时也是个可迭代对象
- 生成器是一种特殊的迭代器，`yield`关键字可实现懒惰计算，并使得外部影响生成器的执行成为了可能





