title: Python进阶——为什么GIL让多线程变得如此鸡肋？
date: 2018-04-26 13:58:55
categories: Python
tags: [python, GIL]
---

做 Python 开发时，想必你肯定听过 GIL，它经常被 Python 程序员吐槽，说 Python 的多线程非常鸡肋，因为 GIL 的存在，Python 无法利用多线程提高性能。

但事实真的如此吗？

这篇文章，我们就来看一下 Python 的 GIL 到底是什么？以及它的存在，究竟对我们的程序有哪些影响。

# GIL是什么？

查阅官方文档，GIL 全称 Global Interpreter Lock，即**全局解释器锁**，它的官方解释如下：

> In CPython, the global interpreter lock, or GIL, is a mutex that protects access to Python objects, preventing multiple threads from executing Python bytecodes at once. This lock is necessary mainly because CPython's memory management is not thread-safe. (However, since the GIL exists, other features have grown to depend on the guarantees that it enforces.)

翻译成中文就是：

> 在 CPython 解释器中，全局解释锁 GIL 是在于执行 Python 字节码时，为了保护访问 Python 对象而阻止多个线程执行的一把互斥锁。这把锁的存在主要是因为 CPython 解释器的内存管理不是线程安全的。然而直到今天 GIL 依旧存在，现在的很多功能已经习惯于依赖它作为执行的保证。

我们从这个定义中，可以看到几个重点：

1. GIL 是存在于 CPython 解释器中的，属于解释器层级，而并非属于 Python 的语言特性。也就是说，如果你自己有能力实现一个 Python 解释器，完全可以不使用 GIL
2. GIL 是为了让解释器在执行 Python 代码时，同一时刻只有一个线程在运行，以此保证内存管理是安全的
3. 历史原因，现在很多 Python 项目已经习惯依赖 GIL（开发者认为 Python 就是线程安全的，写代码时对共享资源的访问不会加锁）

在这里我想强调的是，**因为 Python 默认的解释器是 CPython，GIL 是存在于 CPython 解释器中的，我们平时说到 GIL 就认为它是 Python 语言的问题，其实这个表述是不准确的。**

其实除了 CPython 解释器，常见的 Python 解释器还有如下几种：

- CPython：C 语言开发的解释器，官方默认使用，目前使用也最为广泛，存在 GIL
- IPython：基于 CPython 开发的交互式解释器，只是增强了交互功能，执行过程与 CPython 完全一样
- PyPy：目标是加快执行速度，采用 JIT 技术，对 Python 代码进行动态编译（不是解释），可以显著提高代码的执行速度，但执行结果可能与 CPython 不同，存在 GIL
- Jython：运行在 Java 平台的 Python 解释器，可以把 Python 代码编译成 Java 字节码，依赖 Java 平台，不存在 GIL
- IronPython：和 Jython 类似，运行在微软的 .Net 平台下的 Python 解释器，可以把 Python 代码编译成 .Net 字节码，不存在 GIL

虽然有这么多 Python 解释器，但使用最广泛的依旧是官方提供的 CPython，它默认是有 GIL 的。

那么 GIL 会带来什么问题呢？为什么开发者总是抱怨 Python 多线程无法提高程序效率？

<!-- more -->

# GIL带来的问题

想要了解 GIL 对 Python 多线程带来的影响，我们来看一个例子。

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

在这个例子中，虽然我们开启了 2 个线程去执行 `loop`，但我们观察 CPU 的使用情况，发现这个程序只能跑满一个 CPU 核心，没有利用到多核。

这就是 GIL 带来的问题。

其原因在于，**一个 Python 线程想要执行一段代码，必须先拿到 GIL 锁后才被允许执行，也就是说，即使我们使用了多线程，但同一时刻却只有一个线程在执行。**

但我们进一步思考一下，就算有 GIL 的存在，理论来说，如果 GIL 释放的够快，多线程怎么也要比单线程执行效率高吧？

但现实的结果是：多线程比我们想象的更糟糕。

我们再来看一个例子，还是运行一个 CPU 密集型的任务程序，我们来看单线程执行 2 次和 2 个线程同时执行，哪个效率更高？

单线程执行 2 次 CPU 密集型任务：

```python
import time
import threading

def loop():
    count = 0
    while count <= 1000000000:
        count += 1


# 单线程执行 2 次 CPU 密集型任务
start = time.time()
loop()
loop()
end = time.time()
print("execution time: %s" % (end - start))
# execution time: 89.63111019134521
```

从结果来看，执行耗时 89秒。

再来看 2 个线程同时执行 CPU 密集型任务：

```python
import time
import threading

def loop():
    count = 0
    while count <= 1000000000:
        count += 1


# 2个线程同时执行CPU密集型任务
start = time.time()

t1 = threading.Thread(target=loop)
t2 = threading.Thread(target=loop)
t1.start()
t2.start()
t1.join()
t2.join()

end = time.time()
print("execution time: %s" % (end - start))
# execution time: 92.29994678497314
```

执行耗时却达到了 92 秒。

从执行结果来看，多线程的效率还不如单线程的执行效率高！

为什么会导致这种情况？我们来看一下 GIL 究竟是怎么回事。

# GIL原理

其实，由于 Python 的线程就是 C 语言的 pthread，它是通过操作系统调度算法调度执行的。

Python 2.x 的代码执行是基于 opcode 数量的调度方式，简单来说就是每执行一定数量的字节码，或遇到系统 IO 时，会强制释放 GIL，然后触发一次操作系统的线程调度。

虽然在 Python 3.x 进行了优化，基于固定时间的调度方式，就是每执行固定时间的字节码，或遇到系统 IO 时，强制释放 GIL，触发系统的线程调度。

但这种线程的调度方式，都会导致同一时刻只有一个线程在运行。

**而线程在调度时，又依赖系统的 CPU 环境，也就是在单核 CPU 或多核 CPU 下，多线程在调度切换时的成本是不同的。**

如果是在单核 CPU 环境下，多线程在执行时，线程 A 释放了 GIL 锁，那么被唤醒的线程 B 能够立即拿到 GIL 锁，线程 B 可以无缝接力继续执行，执行流程如下图：

![](https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1524717396.png?imageMogr2/thumbnail/!70p)

而如果在在多核 CPU 环境下，当多线程执行时，线程 A 在 CPU0 执行完之后释放 GIL 锁，其他 CPU 上的线程都会进行竞争。

但 CPU0 上的线程 B 可能又马上获取到了 GIL，这就导致其他 CPU 上被唤醒的线程，只能眼巴巴地看着 CPU0 上的线程愉快地执行着，而自己只能等待，直到又被切换到待调度的状态，这就会产生多核 CPU 频繁进行线程切换，消耗资源，这种情况也被叫做「CPU颠簸」。整个执行流程如下图：

![](https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1524709489.png?imageMogr2/thumbnail/!70p)

图中绿色部分是线程获得了 GIL 并进行有效的 CPU 运算，红色部分是被唤醒的线程由于没有争夺到 GIL，只能无效等待，无法充分利用 CPU 的并行运算能力。

这就是多线程在多核 CPU 下，执行效率还不如单线程或单核 CPU 效率高的原因。

到此，我们可以得出一个结论：**如果使用多线程运行一个 CPU 密集型任务，那么 Python 多线程是无法提高运行效率的。**

别急，你以为事情就这样结束了吗？

我们还需要考虑另一种场景：如果多线程运行的不是一个 CPU 密集型任务，而是一个 **IO 密集型**的任务，结果又会如何呢？

答案是，**多线程可以显著提高运行效率！**

其实原因也很简单，因为 IO 密集型的任务，大部分时间都花在等待 IO 上，并没有一直占用 CPU 的资源，所以并不会像上面的程序那样，进行无效的线程切换。

例如，如果我们想要下载 2 个网页的数据，也就是发起 2 个网络请求，如果使用单线程的方式运行，只能是依次串行执行，其中等待的总耗时是 2 个网络请求的时间之和。

而如果采用 2 个线程的方式同时处理，这 2 个网络请求会同时发送，然后同时等待数据返回（IO等待），最终等待的时间取决于耗时最久的线程时间，这会比串行执行效率要高得多。

所以，**如果需要运行 IO 密集型任务，Python 多线程是可以提高运行效率的。**

# 为什么会有GIL？

我们已经了解到，GIL 对于处理 CPU 密集型任务的场景，多线程是无法提高运行效率的。

既然 GIL 的影响这么大，那为什么 Python 解释器 CPython 在设计时要采用这种方式呢？

这就需要追溯历史原因了。

在 2000 年以前，各个 CPU 厂商为了提高计算机的性能，其努力方向都在提升单个 CPU 的运行频率上，但在之后的几年遇到了天花板，单个 CPU 性能已经无法再得到大幅度提升，所以在 2000 年以后，提升计算机性能的方向便改为向多 CPU 核心方向发展。

为了更有效的利用多核心 CPU，很多编程语言就出现了**多线程**的编程方式，但也正是有了多线程的存在，随之带来的问题就是多线程之间对于维护数据和状态一致性的困难。

Python 设计者在设计解释器时，可能没有想到 CPU 的性能提升会这么快转为多核心方向发展，所以在当时的场景下，设计一个全局锁是那个时代保护多线程资源一致性最简单经济的设计方案。

而随着多核心时代来临，当大家试图去拆分和去除 GIL 的时候，发现大量库的代码和开发者已经重度依赖 GIL（默认认为 Pythonn 内部对象是线程安全的，无需在开发时额外加锁），所以这个去除 GIL 的任务变得复杂且难以实现。

所以，GIL 的存在更多的是历史原因，在 Python 3 的版本，虽然对 GIL 做了优化，但依旧没有去除掉，Python 设计者的解释是，在去除 GIL 时，会破坏现有的 C 扩展模块，因为这些扩展模块都严重依赖于 GIL，去除 GIL 有可能会导致运行速度会比 Python 2 更慢。

Python 走到现在，已经有太多的历史包袱，所以现在只能背负着它们前行，如果一切推倒重来，想必 Python 设计者会设计得更加优雅一些。

# 解决方案

既然 GIL 的存在会导致这么多问题，那我们在开发时，需要注意哪些地方，避免受到 GIL 的影响呢？

我总结了以下几个方案：

1. IO 密集型任务场景，可以使用多线程可以提高运行效率
2. CPU 密集型任务场景，不使用多线程，推荐使用多进程方式部署运行
3. 更换没有 GIL 的 Python 解释器，但需要提前评估运行结果是否与 CPython 一致
4. 编写 Python 的 C 扩展模块，把 CPU 密集型任务交给 C 模块处理，但缺点是编码较为复杂
5. 更换其他语言 :)

# 总结

这篇文章我们主要讲了 Python GIL 相关的问题。

首先，我们了解到 GIL 属于 Python 解释器层面的，它并不是 Python 语言的特性，这一点我们一定不要搞混了。GIL 的存在会让 Python 在执行代码时，只允许同一时刻只有一个线程在执行，其目的是为了保证在执行过程中内存管理的安全性。

之后我们通过一个例子，观察到 Python 在多线程运行 CPU 密集型任务时，执行效率比单线程还要低，其原因是因为在多核 CPU 环境下，GIL 的存在会导致多线程切换时无效的资源消耗，因此会降低程序运行的效率。

但如果使用多线程运行 IO 密集型的任务，由于线程更多地是在等待 IO，所以并不会消耗 CPU 资源，这种情况下，使用多线程是可以提高程序运行效率的。

最后，我们分析了 GIL 存在的原因，更多是因为历史问题导致，也正因为 GIL 的存在，很多 Python 开发者默认 Python 是线程安全的，这也间接增加了去除 GIL 的困难性。

基于这些前提，我们平时在部署 Python 程序时，一般更倾向于使用多进程的方式去部署，就是为了避免 GIL 的影响。

任何一种编程语言，都有其优势和劣势，我们需要理解它的实现机制，发挥其长处，才能更好地服务于我们的需求。