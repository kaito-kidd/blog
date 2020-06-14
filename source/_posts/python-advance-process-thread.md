title: Python技术进阶——进程和线程
date: 2018-05-11 18:03:17
categories: Python
tags: [python, 进程, 线程]
---

为了提高程序的运行效率，Python与其他语言一样，提供了多进程和多线程的开发方式，这篇文章我们来讲Python的多进程和多线程开发。

# 进程

Python提供了`mutilprocessing`模块，为多进程编程提供了友好的API，并且提供了多进程之间信息同步和通信的相关组件，如`Queue`、`Event`、`Pool`、`Lock`、`Pipe`、`Semaphore`、`Condition`等模块。

## 函数当做进程

Python中创建多进程的方式有2种：

- 函数当做进程
- 类当做进程

逻辑简单的任务一般使用函数当做进程，逻辑较多或代码结构复杂的建议使用类当做进程。

首先来看函数当做进程的例子：

```python
# coding: utf8

import os
import time
import random
from multiprocessing import Process

def task(name):
    s = random.randint(1, 10)
    print 'pid: %s, name: %s, sleep %s ...' % (os.getpid(), name, s)
    time.sleep(s)

if __name__ == '__main__':
    # 创建5个子进程执行
    ps = []
    for i in range(5):
        p = Process(target=task, args=('p%s' % i, ))
        ps.append(p)
        p.start()
    
    # 主进程等待子进程结束
    for p in ps:
        p.join()
    
# Output:
# pid: 52361, name: p0, sleep 8 ...
# pid: 52362, name: p1, sleep 7 ...
# pid: 52363, name: p2, sleep 8 ...
# pid: 52364, name: p3, sleep 3 ...
# pid: 52365, name: p4, sleep 2 ...
```

使用`p = Process(target=func, args=(arg1, arg2...))`即可创建一个进程，调用`p.start()`启动一个进程，`p.join()`使得主进程等待子进程执行结束后才退出。

当这个程序执行时，你可以`ps`查看一下进程，会发现一共有6个进程在执行，其中包括1个主进程，5个子进程。

<!-- more -->

## 类当做进程

```python
# coding: utf8

import os
import random
import time
from multiprocessing import Process

class P(Process):

    def run(self):
        s = random.randint(1, 10)
        print 'pid: %s, name: %s, sleep %s...' % (os.getpid(), self.name, s)
        time.sleep(s)

if __name__ == '__main__':
    # 创建5个进程并执行
    ps = []
    for i in range(5):
        p = P()
        ps.append(p)
        p.start()

    # 主进程等待子进程执行结束后退出
    for p in ps:
        p.join()
        
# Output:
# pid: 59138, name: P-2, sleep 5...
# pid: 59137, name: P-1, sleep 8...
# pid: 59139, name: P-3, sleep 8...
# pid: 59140, name: P-4, sleep 3...
# pid: 59141, name: P-5, sleep 6...
```

类`P`继承了`Process`，并重写了`run`方法，在调用`start`方法时会自动执行`run`方法，执行效果与上面类似。

## Queue

如果多个进程之间需要通信，可以使用队列，Python提供了`Queue`模块，例子如下：

```python
# coding: utf8

import time
import random
from multiprocessing import Process, Queue

class P1(Process):

    def __init__(self, queue):
        self.queue = queue
        super(P1, self).__init__()

    def run(self):
        # 此进程负责put数据
        print 'P1 put ...'
        for i in range(5):
            time.sleep(random.randint(1, 3))
            self.queue.put(i)
            print 'put: P1 -> %s' % i

class P2(Process):

    def __init__(self, queue):
        self.queue = queue
        super(P2, self).__init__()

    def run(self):
        # 此进程负责read数据
        print 'P2 read ...'
        while 1:
            i = self.queue.get()
            print 'get: P2 -> %s' % i

if __name__ == '__main__':
    # 创建多进程队列 使之可通信
    queue = Queue()

    # 创建进程
    p1 = P1(queue)
    p2 = P2(queue)

    # 启动进程
    p1.start()
    p2.start()

    # 主进程等待P1子进程执行
    p1.join()
    # P2执行的是死循环 只能强制结束
    p2.terminate()
    
# Output:
# P1 put ...
# P2 read ...
# put: P1 -> 0
# get: P2 -> 0
# put: P1 -> 1
# get: P2 -> 1
# put: P1 -> 2
# get: P2 -> 2
# put: P1 -> 3
# get: P2 -> 3
# put: P1 -> 4
# get: P2 -> 4
```

一共2个进程，一个进程使用`queue.put()`负责向队列写入数据，另一个进程使用`queue.get()`队列中读取数据，实现了2个进程之间的信息通信。

## Pipe

上面提到队列的使用场景常用于一端写入数据，另一端读取数据进行操作。

如果进程两端在读取数据时同时也想写入数据要怎么做？

Python多进程模块中提供了`Pipe`，意为管道的意思，两端都可以进行读写操作。

```python
# coding: utf8

import time
import random
from multiprocessing import Process, Pipe

class P1(Process):

    def __init__(self, pipe):
        self.pipe = pipe
        super(P1, self).__init__()

    def run(self):
        # send
        print 'P1 send ...'
        for i in range(3):
            time.sleep(random.randint(1, 2))
            self.pipe.send(i)
            print 'send: P1 -> %s' % i

        # recv
        print 'P1 recv ...'
        for i in range(3):
            i = self.pipe.recv()
            print 'recv: P1 -> %s' % i

class P2(Process):

    def __init__(self, pipe):
        self.pipe = pipe
        super(P2, self).__init__()

    def run(self):
        # recv
        print 'P2 recv ...'
        for i in range(3):
            i = self.pipe.recv()
            print 'recv: P2 -> %s' % i
            
        # send
        print 'P2 send ...'
        for i in range(3):
            time.sleep(random.randint(1, 2))
            self.pipe.send(i)
            print 'send: P2 -> %s' % i

if __name__ == '__main__':
    # 创建Pipe
    pipe1, pipe2 = Pipe()

    p1 = P1(pipe1)
    p2 = P2(pipe2)

    p1.start()
    p2.start()

    p1.join()
    p2.join()
    
# Output:
# P1 send ...
# P2 recv ...
# send: P1 -> 0
# recv: P2 -> 0
# send: P1 -> 1
# recv: P2 -> 1
# send: P1 -> 2
# P1 recv ...
# recv: P2 -> 2
# P2 send ...
# send: P2 -> 0
# recv: P1 -> 0
# send: P2 -> 1
# recv: P1 -> 1
# send: P2 -> 2
# recv: P1 -> 2
```

创建一个`Pipe`会返回2个管道，这2个管道分别交给2个进程，即可实现这2个进程之间的互相通信。

## Event

如果需要在多进程之间控制某些事件的开始与停止，也就是在多进程进程保持同步信号信息，可使用`Event`：

```python
# coding: utf8

import time
import random
from multiprocessing import Process, Queue, Event

class P1(Process):

    def __init__(self, queue, event):
        self.queue = queue
        self.event = event
        super(P1, self).__init__()

    def run(self):
        # 阻塞 等待主进程信号
        self.event.wait()
        print 'P1 put ...'
        for i in range(5):
            time.sleep(random.randint(1, 3))
            self.queue.put(i)
            print 'put: P1 -> %s' % i

class P2(Process):

    def __init__(self, queue, event):
        self.queue = queue
        self.event = event
        super(P2, self).__init__()

    def run(self):
        # 阻塞 等待主进程信号
        self.event.wait()
        print 'P2 read ...'
        while 1:
            i = self.queue.get()
            print 'get: P2 -> %s' % i
            
if __name__ == '__main__':
    # 队列
    queue = Queue()
    # 事件
    event = Event()

    p1 = P1(queue, event)
    p2 = P2(queue, event)

    p1.start()
    p2.start()

    # 主进程让子进程阻塞3秒
    print 'sleep 3s ...'
    time.sleep(3)
    # 向子进程发送信号 子进程向下执行
    event.set()

    p1.join()
    p2.terminate()
    
# Output:
# sleep 3s...
# P1 put ...
# P2 read ...
# put: P1 -> 0
# get: P2 -> 0
# put: P1 -> 1
# get: P2 -> 1
# put: P1 -> 2
# get: P2 -> 2
# put: P1 -> 3
# get: P2 -> 3
# put: P1 -> 4
# get: P2 -> 4
```

执行程序后，我们发现2个子进程在执行到`event.wait()`时，阻塞在此，直到主进程休眠3秒后执行`event.set()`时，子进程才得以向下执行。

使用`Event`可以控制进程之间的同步问题。

## Pool

多进程虽然可以提高运行效率，但同时也不建议无限制的创建进程，过多的进程会给操作系统的调度和上下文切换带来更大的负担，进程越来越多也有可能导致效率下降。

在`multiiprocessing`模块中，提供了进程池模块`Pool`，理论来说同时执行的进程数与CPU核心相等，才会保证最高效的运行效率。

```python
# coding: utf8

import os
import random
import time
from multiprocessing import Pool

def task(name):
    s = random.randint(1, 10)
    print 'pid: %s, name: %s, sleep %s ...' % (os.getpid(), name, s)
    time.sleep(s)

if __name__ == '__main__':
    # 大小为5的进程池 同一时刻最多只有5个进程执行
    pool = Pool(5)

    # 运行10个任务
    for i in range(10):
        pool.apply_async(task, ('p-%s' % i, ))

    # 必须先close才能join 表示不再添加新的进程
    pool.close()
    pool.join()

# Output:
# pid: 67193, name: p-0, sleep 3 ...
# pid: 67194, name: p-1, sleep 5 ...
# pid: 67195, name: p-2, sleep 5 ...
# pid: 67196, name: p-3, sleep 6 ...
# pid: 67197, name: p-4, sleep 9 ...
# pid: 67193, name: p-5, sleep 6 ...
# pid: 67194, name: p-6, sleep 5 ...
# pid: 67195, name: p-7, sleep 4 ...
# pid: 67196, name: p-8, sleep 3 ...
# pid: 67197, name: p-9, sleep 7 ...
```

上面代码定义了大小为5的进程池，也就是说不管向进程池里放入多少个任务，同一时刻只有5个进程在执行。

我们在编写多进程程序时，一般使用进程池的方式执行多个任务，保证高效的同时也避免资源的浪费。

## Lock

在执行多进程任务执行过程中，如果需要对同一资源（例如文件）进行访问时，为了防止一个进程操作的资源不被另一个进程篡改，可以使用`Lock`对其进行加锁互斥。

```python
# coding: utf8

from multiprocessing import Process, Lock

class P1(Process):

    def __init__(self, lock, fp):
        self.lock = lock
        self.fp = fp
        super(P1, self).__init__()

    def run(self):
        # 只有一个进程能进入操作
        with self.lock:
            for i in range(5):
                f = open(self.fp, 'a+')
                f.write('p1 - %s\n' % i)
                f.close()

class P2(Process):

    def __init__(self, lock, fp):
        self.lock = lock
        self.fp = fp
        super(P2, self).__init__()

    def run(self):
        # 只有一个进程能进入操作
        with self.lock:
            for i in range(5):
                f = open(self.fp, 'a+')
                f.write('p2 - %s\n' % i)
                f.close()
                
if __name__ == '__main__':
    # 进程锁
    lock = Lock()
    fp = 'test.txt'
    p1 = P1(lock, fp)
    p2 = P2(lock, fp)

    p1.start()
    p2.start()

    p1.join()
    p2.join()
```

上面代码对同一个文件进行操作时，如果不加锁，2个进程会同时向文件写入内容。如果想保证写入顺序，在写文件之前使用`Lock`加锁，就能保证只有一个进程能进入操作文件。

## Semaphore

如果有一种场景，需要多个进程同时执行一些任务或访问某个资源，但要限制最大参与的进程数量，那么就可以使用`Semaphore`信号量来控制。

```python
# coding: utf8

import time
import os
from multiprocessing import Process, Semaphore

# 最大4个进程同时操作
semaphore = Semaphore(4)

def task(name):
    if semaphore.acquire():
        print 'pid: %s, name: %s, sleep 1 ...' % (os.getpid(), name)
        time.sleep(1)
        semaphore.release()

if __name__ == '__main__':
    ps = []
    for i in range(10):
        p = Process(target=task, args=('p%s' % i, ))
        ps.append(p)
        p.start()
    for p in ps:
        p.join()

# Output:
# pid: 37147, name: p0, sleep 1 ...
# pid: 37148, name: p1, sleep 1 ...
# pid: 37149, name: p2, sleep 1 ...
# pid: 37150, name: p3, sleep 1 ...

# pid: 37151, name: p4, sleep 1 ...
# pid: 37152, name: p5, sleep 1 ...
# pid: 37153, name: p6, sleep 1 ...
# pid: 37154, name: p7, sleep 1 ...

# pid: 37155, name: p8, sleep 1 ...
# pid: 37156, name: p9, sleep 1 ...
```

执行上面的代码，你会发现虽然创建了10个进程，但同一时刻只有4个进程能能够执行真正的逻辑。

## Condition

如果你有使用`Lock` + `Event`结合的场景，可以使用`Condition`，它基本上包含了这2种特性，在加锁的同时，还可以根据逻辑条件让其他进程等待或重新唤醒。

```python
# coding: utf8

import time
import random
from multiprocessing import Process, Queue, Condition

def produer(queue, condition):
    while 1:
        # 获取锁
        if condition.acquire():
            if not queue.empty():
                # 等待其他进程唤醒
                condition.wait()
            i = random.randint(1, 10)
            queue.put(i)
            print 'produer --> %s' % i
            # 唤醒其他进程
            condition.notify()
            # 释放锁
            condition.release()
            time.sleep(1)

def consumer(queue, condition):
    while 1:
        # 获取锁
        if condition.acquire():
            if queue.empty():
                # 等待其他进程唤醒
                condition.wait()
            i = queue.get()
            print 'consumer --> %s' % i
            # 唤醒其他进程
            condition.notify()
            # 释放锁
            condition.release()
            time.sleep(1)
            
if __name__ == '__main__':
    queue = Queue()
    condition = Condition()
    p1 = Process(target=produer, args=(queue, condition))
    p2 = Process(target=consumer, args=(queue, condition))
    p1.start()
    p2.start()
    p1.join()
    p2.join()
    
# Output:
# produer --> 10
# consumer --> 10
# produer --> 4
# consumer --> 4
# produer --> 5
# consumer --> 5
# ...
```

`Condition`是一种更高级的控制进程同步和资源控制的方式。

# 线程

线程是进程执行的最小单位，比进程更轻量，一个进程至少包含一个线程，一个进程中的所有线程共享这个进程的地址空间和资源句柄。

在Python代码执行中，默认是单进程单线程执行的。

如果想要编写多线程程序，Python也提供了`threading`模块，同时也提供了线程之间信息同步和信号控制的组件。


## 函数当做线程

创建线程与创建进程类似，也有2种方式：

- 函数当做线程
- 类当做线程

函数当做线程的例子如下：

```python
# coding: utf8

import threading

def run(name):
    for i in range(3):
        print '%s --> %s' % (name, i)

if __name__ == '__main__':
    # 创建2个线程
    t1 = threading.Thread(target=run, args=('t1', ))
    t2 = threading.Thread(target=run, args=('t2', ))
    # 开始执行
    t1.start()
    t2.start()
    # 主线程等待其他线程结束
    t1.join()
    t2.join()
    
# Output:
# t1 --> 0
# t2 --> 0
# t2 --> 1
# t2 --> 2
# t1 --> 1
# t1 --> 2
```

与进程很类似，`t = threading.Thread(target=func, args=(arg1, arg2...))`创建一个线程，`t.start()`开始执行线程，`t.join()`使主线程等待其他线程执行结束。

## 类当做线程

```python
# coding: utf8

import threading

class A(threading.Thread):

    def run(self):
        for i in range(5):
            print self.name, i

if __name__ == '__main__':
    a1 = A()
    a2 = A()
    # 执行线程
    a1.start()
    a2.start()
    # 主线程等待其他线程结束
    a1.join()
    a2.join()
```

只要继承`threading.Thread`类，重写`run`方法，这个类就会以多线程的方式执行`run`方法里的逻辑。

## Queue

多线程之间也可以使用队列进行数据传输：

```python
# coding: utf8

import time
import random
from Queue import Queue
from threading import Thread

class T1(Thread):

    def __init__(self, queue):
        self.queue = queue
        super(T1, self).__init__()

    def run(self):
        print 'T1 put ...'
        for i in range(5):
            time.sleep(random.randint(1, 3))
            self.queue.put(i)
            print 'put: T1 -> %s' % i

class T2(Thread):

    def __init__(self, queue):
        self.queue = queue
        self._running = True
        super(T2, self).__init__()

    def stop(self):
        self._running = False

    def run(self):
        print 'T2 read ...'
        while self._running:
            i = self.queue.get()
            print 'get: T2 -> %s' % i
            
if __name__ == '__main__':
    # 创建多线程队列
    queue = Queue()

    # 创建进程
    t1 = T1(queue)
    t2 = T2(queue)

    # 启动进程
    t1.start()
    t2.start()

    # T2线程10秒后停止
    time.sleep(10)
    t2.stop()

    # 主进程等待线程执行
    t1.join()
    t2.join()
    
# Output:
# T1 put ...
# T2 read ...
# put: T1 -> 0
# get: T2 -> 0
# put: T1 -> 1
# get: T2 -> 1
# put: T1 -> 2
# get: T2 -> 2
# put: T1 -> 3
# get: T2 -> 3
# put: T1 -> 4
# get: T2 -> 4
```

## Event

多线程的同步也有`Event`可以控制：

```python
# coding: utf8

import time
import random
from Queue import Queue
from threading import Thread, Event

class T1(Thread):

    def __init__(self, queue, event):
        self.queue = queue
        self.event = event
        super(T1, self).__init__()

    def run(self):
        # 阻塞 等待主线程信号
        self.event.wait()
        print 'T1 put ...'
        for i in range(5):
            time.sleep(random.randint(1, 3))
            self.queue.put(i)
            print 'put: T1 -> %s' % i


class T2(Thread):

    def __init__(self, queue, event):
        self.queue = queue
        self.event = event
        self._running = True
        super(T2, self).__init__()

    def stop(self):
        self._running = False

    def run(self):
        # 阻塞 等待主线程信号
        self.event.wait()
        print 'T2 read ...'
        while self._running:
            i = self.queue.get()
            print 'get: T2 -> %s' % i

if __name__ == '__main__':
    # 队列
    queue = Queue()
    # 多线程事件
    event = Event()

    t1 = T1(queue, event)
    t2 = T2(queue, event)

    t1.start()
    t2.start()

    # 主线程让其他线程阻塞3秒
    print 'sleep 3s...'
    time.sleep(3)
    event.set()

    # T2线程10秒后停止
    time.sleep(10)
    t2.stop()

    t1.join()
    t2.join()
    
# Output:
# sleep 3s...
# T1 put ...
# T2 read ...
# put: T1 -> 0
# get: T2 -> 0
# put: T1 -> 1
# get: T2 -> 1
# put: T1 -> 2
# get: T2 -> 2
# put: T1 -> 3
# get: T2 -> 3
# put: T1 -> 4
```

## Pool

避免无限制的创建线程，使用线程池执行任务：

```python
# coding: utf8

import time
import random
from multiprocessing.pool import ThreadPool

def task(name):
    s = random.randint(1, 10)
    print 'name: %s, sleep %s ...' % (name, s)
    time.sleep(s)

if __name__ == '__main__':
    # 大小为5的线程池
    pool = ThreadPool(5)

    # 运行10个任务
    for i in range(10):
        pool.apply_async(task, ('t-%s' % i, ))

    # 必须先close才能join 表示不再添加新的线程
    pool.close()
    pool.join()
    
# Output:
# name: t-0, sleep 1 ...
# name: t-1, sleep 4 ...
# name: t-2, sleep 4 ...
# name: t-3, sleep 10 ...
# name: t-4, sleep 9 ...

# name: t-5, sleep 8 ...
# name: t-6, sleep 2 ...
# name: t-7, sleep 2 ...
# name: t-8, sleep 4 ...
# name: t-9, sleep 6 ...
```

## Semaphore

允许多个线程同时操作某个资源并限制最大线程数，使用`Semaphore`：

```python
# coding: utf8

import time
import os
from threading import Thread, Semaphore

# 最大4个线程同时操作
semaphore = Semaphore(4)

def task(name):
    if semaphore.acquire():
        print 'name: %s, sleep 1 ...' % name
        time.sleep(1)
        semaphore.release()

if __name__ == '__main__':
    ts = []
    for i in range(10):
        t = Thread(target=task, args=('t%s' % i, ))
        ts.append(t)
        t.start()
    for t in ts:
        t.join()

# Output:
# name: t0, sleep 1 ...
# name: t2, sleep 1 ...
# name: t1, sleep 1 ...
# name: t3, sleep 1 ...

# name: t4, sleep 1 ...
# name: t5, sleep 1 ...
# name: t7, sleep 1 ...
# name: t6, sleep 1 ...

# name: t8, sleep 1 ...
# name: t9, sleep 1 ...
```

## Condition

与多进程类似，`Condition`是`Lock` + `Event`的结合：

```python
# coding: utf8

import time
import random
from Queue import Queue
from threading import Thread, Condition

def produer(queue, condition):
    for i in range(5):
        # 获取锁
        if condition.acquire():
            if not queue.empty():
                # 等待其他线程唤醒
                condition.wait()
            i = random.randint(1, 10)
            queue.put(i)
            print 'produer --> %s' % i
            # 唤醒其他线程
            condition.notify()
            # 释放锁
            condition.release()
            time.sleep(1)

def consumer(queue, condition):
    for i in range(5):
        # 获取锁
        if condition.acquire():
            if queue.empty():
                # 等待其他线程唤醒
                condition.wait()
            i = queue.get()
            print 'consumer --> %s' % i
            # 唤醒其他线程
            condition.notify()
            # 释放锁
            condition.release()
            time.sleep(1)
            
if __name__ == '__main__':
    queue = Queue()
    condition = Condition()
    t1 = Thread(target=produer, args=(queue, condition))
    t2 = Thread(target=consumer, args=(queue, condition))
    t1.start()
    t2.start()
    t1.join()
    t2.join()
    
# Output:
# produer --> 3
# consumer --> 3
# produer --> 2
# consumer --> 2
# produer --> 2
# consumer --> 2
# produer --> 7
# consumer --> 7
# produer --> 5
# consumer --> 5
```

# concurrent模块

上面介绍了很多进程、线程各种常用的开发方式，其实最常用的编程模式还是使用进程池或线程池来执行进程、线程。

这里有必要推荐一下`concurrent`模块，这个模块非常友好的封装了进程和线程最常用的操作，使用起来更简单易用。

并且在Python3.2以后，已经是纳入官方标准模块。

Python3.2以下需要手动安装此模块：

```shell
pip install futures
```

## 多进程

```python
# coding: utf8

from concurrent.futures import ProcessPoolExecutor

def task(total):
    """模拟CPU密集运算"""
    num = 0
    for i in range(total):
        num += i
    return num

if __name__ == '__main__':
    # 进程池
    pool = ProcessPoolExecutor(max_workers=5)
    # 批量任务 放入进程池执行
    result = pool.map(task, [100, 1000, 10000, 100000])
    # 输出结果
    for item in result:
        print item
```

使用`ProcessPoolExecutor`创建进程池，调用`pool.map`方法批量加入任务并执行，然后输出每个进程的执行结果。

也可以使用`submit`提交单个任务在进程池中执行：

```python
# coding: utf8

from concurrent.futures import ProcessPoolExecutor

def task(total):
    """模拟CPU密集任务"""
    num = 0
    for i in range(total):
        num += i
    return num

if __name__ == '__main__':
    # 进程池
    pool = ProcessPoolExecutor(max_workers=5)

    # 使用submit提交任务
    results = []
    results.append(pool.submit(task, 100))
    results.append(pool.submit(task, 1000))
    results.append(pool.submit(task, 10000))
    results.append(pool.submit(task, 10000))

    # 输出结果
    for future in results:
        print future.result()
```

注意，`pool.submit`提交后返回的是`Future`对象，它意味着在未来的某个时刻才会得到结果，所以在输出结果时，需要调用`future.result()`方法拿到真正的执行结果。

## 多线程

线程池的方式与进程池类似，只需把`ProcessPoolExecutor`换成`ThreadPoolExecutor`即可：

```python
# coding: utf8

import requests
from concurrent.futures import ThreadPoolExecutor

def task(url):
    """模拟IO密集任务"""
    return requests.get(url).status_code

if __name__ == '__main__':
    # 线程池
    pool = ThreadPoolExecutor(max_workers=5)

    # 批量任务 放入线程池执行
    urls = ['http://www.baidu.com', 'http://www.163.com', 'http://www.taobao.com']
    result = pool.map(task, urls)

    # 输出结果
    for item in result:
        print item
```

```python
# coding: utf8

import requests
from concurrent.futures import ThreadPoolExecutor

def task(url):
    """模拟IO密集运算"""
    return requests.get(url).status_code

if __name__ == '__main__':
    # 线程池
    pool = ThreadPoolExecutor(max_workers=5)

    # 使用submit 提交任务到线程池
    results = []
    results.append(pool.submit(task, 'http://www.baidu.com'))
    results.append(pool.submit(task, 'http://www.163.com'))
    results.append(pool.submit(task, 'http://www.taobao.com'))

    # 输出结果
    for future in results:
        print future.result()
```



