title: Python技术进阶——GIL
date: 2018-04-26 13:58:55
categories: Python
tags: [python, GIL]
---

在Python世界中，我们常常听到的`GIL`到底是什么？因为它的存在，对程序的执行产生什么影响？其背后的原理又是怎样的？

# GIL是什么

`GIL`全称`Global Interpreter Lock`，也叫全局解释锁，官方解释如下：

> In CPython, the global interpreter lock, or GIL, is a mutex that protects access to Python objects, preventing multiple threads from executing Python bytecodes at once. This lock is necessary mainly because CPython's memory management is not thread-safe. (However, since the GIL exists, other features have grown to depend on the guarantees that it enforces.)

翻译为：

> 在`CPython`解释器中，全局解释锁`GIL`是在于执行Python字节码时为了保护访问Python对象而阻止多个线程执行的一把互斥锁。这把锁的存在在主要是因为`CPython`解释器的内存管理不是线程安全的。然而直到今天`GIL`依旧存在，现在的很多功能已经习惯于依赖它作为执行的保证。

关注几个重点：

- `GIL`是存在于`CPython`解释器中的，属于解释器层级的，而并非属于Python语言特性，也就是说，如果你自己有能力实现一个Python解释器，完全可以不使用`GIL`
- `GIL`是为了让Python解释器在执行Python代码过程中，同一时刻只有一个线程在运行，以此保证内存管理是安全的
- 历史原因，现在很多Python的功能已经习惯依赖`GIL`

由于`CPython`是Python的默认解释器，所以平时我们说到`GIL`就会把它想成是Python语言层面的，这个表述是不准确的。

常见的Python解释器有如下几种，以及这些解释器是否存在`GIL`：

- `CPython`：`C`语言开发的解释器，默认官方版本，使用最为广泛，有`GIL`
- `IPython`：基于`CPython`开发的交互式解释器，只是增强了交互功能，执行功能与`CPython`完全一样
- `PyPy`：目标是加快执行速度，采用JIT技术，对Python代码进行动态编译（不是解释），可显著提高执行速度，但执行结果可能与`CPython`不同。有`GIL`，但其开发者宣布发布去掉`GIL`的版本
- `Jython`：运行在Java平台上的Python解释器，可以把Python代码编译成`Java`字节码，依赖`Java`平台，没有`GIL`
- `IronPython`：和`Jython`类似，执行在微软`.Net`平台的Python解释器，可以把Python代码编译成`.Net`字节码依赖`.Net`平台，没有`GIL`


<!-- more -->

# GIL引发的问题

`GIL`会引发什么问题呢？我们来看一段代码模拟一个CPU密集型运算任务：

```python
import threading

def loop():
    count = 0
    while count <= 1000000000:
        count += 1

# 2个线程执行loop方法
t1 = threading.Thread(target=loop)
t2 = threading.Thread(target=loop)

t1.start()
t2.start()
t1.join()
t2.join()
```

上面这段代码，虽然开了2个线程执行，但我们观察CPU使用情况，发现其只能跑满一个核心。

由于`GIL`的存在，当线程被操作系统唤醒后，必须拿到`GIL`锁后才能执行代码，也就是说同一时刻永远只有一个线程在执行，这就导致如果我们的程序是CPU密集运算型的任务，那么使用Python多线程是不能提高效率的。

但即使有`GIL`的存在，理论来上来说，只要`GIL`释放的够勤快，多线程执行怎么也要比单线程效率高吧？

现实结果是：效率比我们想象的更糟糕！

- 串行执行2次CPU密集型任务：

```python
import time
import threading

def loop():
    count = 0
    while count <= 5000000000:
        count += 1


def main():
    # 串行执行2次CPU密集型任务
    start = time.time()
    loop()
    loop()
    print time.time() - start

if __name__ == '__main__':
    main()

# 540.302778006
```


- 2个线程同时执行CPU密集型任务：

```python
import time
import threading

def loop():
    count = 0
    while count <= 5000000000:
        count += 1


def main():
    # 2个线程同时执行CPU密集型任务
    start = time.time()
    
    t1 = threading.Thread(target=loop)
    t2 = threading.Thread(target=loop)
    t1.start()
    t2.start()
    t1.join()
    t2.join()
    
    print time.time() - start

if __name__ == '__main__':
    main()
    
# 573.972337961
```

上面的代码分别模拟了一个CPU密集型任务在串行执行2次和2个线程同时执行的场景，执行结果发现，多线程的效率还不如串行效率高！

为什么会导致这种情况？我们来分析其背后的工作原理。

# GIL原理

由于Python的线程就是C语言的`pthread`，它是通过操作系统调度算法调度执行。而Python的执行是基于`opcode`数量的调度方式，简单来说就是每执行一定数量的字节码，或遇到系统IO时，会强制释放`GIL`，然后触发一次操作系统的线程调度。

## 单核CPU下的多线程

如果是单核CPU情况下，在多线程执行时，每次线程A释放`GIL`后，被唤醒的线程B能够立即拿到`GIL`，能够无缝执行，执行流程如下图：

![](https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1524717396.png?imageMogr2/thumbnail/!70p)



## 多核CPU下的多线程

但在多核CPU情况下多线程执行时，一个线程在CPU0执行完之后释放`GIL`，其他CPU上的线程都会进行竞争，但CPU0可能又马上获取到了`GIL`，这就导致其他CPU上被唤醒的线程只能眼巴巴地看着CPU0上的线程欢快地执行着，而自己只能等待，直到又被切换到待调度的状态，这就会产生多核CPU频繁进行线程切换，消耗着资源，但只有一个线程能够拿到`GIL`真正执行Python代码，这就导致多线程在多核CPU情况下，效率还不如单线程执行效率高。执行流程如下图：

![多核情况下的多线程](https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1524709489.png?imageMogr2/thumbnail/!70p)

绿色部分是线程获得了`GIL`并进行有效的CPU运算，红色部分是被唤醒的线程由于没有争夺到`GIL`，只能无效地等待，无法充分利用CPU的并行运算能力。这就是多线程在多核CPU下，执行效率还不如单线程或单核CPU效率高的原因。

## 多线程IO密集型任务

我们再进一步试想，如果多线程执行IO密集型任务，效率如何？

答案是比单线程效率要高。

这是由于IO密集型的任务，大部分时间都在等待IO上，很少消耗CPU的资源，所以在IO密集型任务的场景下，使用多线程是可以提升效率的。

# 为什么会有GIL

既然`GIL`的影响这么大，那为什么Python的解释器`CPython`在设计时要采用这种方式呢？

这就要追溯历史原因，2000年以前，各个CPU厂商都在努力提升核心频率从而提高计算机的性能，但到2000年以后逐渐遇到天花板，之后提升方向改为多核心方向。

为了更有效的利用多核心CPU，就出现了多线程的编程方式，而随之带来的就是线程间数据一致性和状态同步的困难。

Python设计者在设计解释器时，可能没有想到CPU的性能提升会这么快转为多核心方向发展，所以在当时的场景下，设计一个全局锁是那个时代保护多线程资源一致性的最简单经济的设计方案。

而随着多核心时代来临，当大家试图去拆分和去除`GIL`的时候，发现大量库的代码开发者已经重度依赖`GIL`（默认Pythonn内部对象是线程安全的，无需在开发时额外加锁），所以这个去除`GIL`的任务变得复杂且难以实现。

所以简单来说`GIL`的存在更多的是历史原因，如果推倒重来重新设计，面对多线程问题可能设计得会更为优雅。


# 解决方案

既然`GIL`存在会导致这么多问题，那我们有什么方式可以绕开这些问题，提高程序性能？总结如下：

- IO密集型任务场景，多线程可以提高运行效率（推荐）
- 使用没有`GIL`的Python解释器（不推荐）
- CPU密集型任务场景，可改为多进程执行（推荐）
- 编写Python的C扩展模块，把CPU密集型任务交给C模块处理（编码复杂，不推荐）
- 更换其他语言实现CPU密集型任务


