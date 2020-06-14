title: 基于Redis实现延迟队列
date: 2016-12-26 15:45:10
categories: Redis
tags: [python, redis, 队列]
---

# 背景

在后端服务中，经常有这样一种场景，写数据库操作在异步队列中执行，且这个异步队列是多进程运行的，这时如果对同一资源进行写库操作，很有可能产生数据被覆盖等问题，于是就需要业务层在更新数据库之前进行加锁，这样保证在更改同一资源时，没有其他更新操作干涉，保证数据一致性。

但如果在更新前对数据库更新加锁，那此时又来了新的更新数据库的请求，但这个更新操作不能丢弃掉，需要延迟执行，那这就需要添加到延迟队列中，延迟执行。

那么如何实现一个延迟队列？利用`Redis`的`SortedSet`和`String`这两种结构，就可以轻松实现。

# 具体实现

```python
# coding: utf8

"""Delay Queue"""

import json
import time
import uuid

import redis


class DelayQueue(object):

    """延迟队列"""

    QUEUE_KEY = 'delay_queue'
    DATA_PREFIX = 'queue_data'

    def __init__(self, conf):
        host, port, db = conf['host'], conf['port'], conf['db']
        self.client = redis.Redis(host=host, port=port, db=db)

    def push(self, data):
        """push

        :param data: data
        """
        # 唯一ID
        task_id = str(uuid.uuid4())
        data_key = '{}_{}'.format(self.DATA_PREFIX, task_id)
        # save string
        self.client.set(data_key, json.dumps(data))
        # add zset(queue_key=>data_key,ts)
        self.client.zadd(self.QUEUE_KEY, data_key, int(time.time()))
        
    def pop(self, num=5, previous=3):
        """pop多条数据

        :param num: pop多少个
        :param previous: 获取多少秒前push的数据
        """
        # 取出previous秒之前push的数据
        until_ts = int(time.time()) - previous
        task_ids = self.client.zrangebyscore(
            self.QUEUE_KEY, 0, until_ts, start=0, num=num)
        if not task_ids:
            return []

        # 利用删除的原子性,防止并发获取重复数据
        pipe = self.client.pipeline()
        for task_id in task_ids:
            pipe.zrem(self.QUEUE_KEY, task_id)
        data_keys = [
            data_key
            for data_key, flag in zip(task_ids, pipe.execute())
            if flag
        ]
        if not data_keys:
            return []
        # load data
        data = [
            json.loads(item)
            for item in self.client.mget(data_keys)
        ]
        # delete string key
        self.client.delete(*data_keys)
        return data
```

<!-- more -->

# 实现思路

## push

在`push`数据时，执行如下几步：

- 生成一个唯一`key`，这里使用uuid4生成（uuid4是根据随机数生成的，重复概率非常小，具体参考[这里](https://en.wikipedia.org/wiki/Universally_unique_identifier)）
- 把数据序列化后存入这个唯一`key`的`String`结构中
- 把这个唯一`key`加到`SortedSet`中，`score`是当前时间戳

> 这里利用`SortedSet`记录添加数据的时间，便于在获取时根据时间获取之前的数据，达到延迟的效果。
>
> 而真正的数据则存放在`String`结构中，等获取时先拿到数据的`key`再获取真正的数据。

这里可能有人会疑问，为什么不把真正的数据放到`SortedSet`的`name`中？

- 把数据放入`name`中可能会产生**瞬间写入相同数据导致数据多条变一条**的情况
- 把数据序列化放到`SortedSet`的`name`中有些过大，不太符合使用习惯

## pop

此`pop`是可以获取多条数据的，上面的代码默认是获取延迟队列中3秒前的5条数据，具体思路如下：

- 计算`previous`秒前的时间戳，使用`SortedSet`的`zrangebysocre`方法获取`previous`秒之前添加的唯一`key`
- 如果`SortedSet`中有数据，则利用`Redis`删除的原子性，使用`zrem`依次删除`SortedSet`的元素，如果删除成功，则使用，防止多进程并发执行此方法，拿到相同的数据
- 那到可用的唯一`key`，从`String`中获取真正的数据即可

> 这里最重要的是第二步，在拿出`SortedSet`的数据后，一定要防止其他进程并发获取到相同的数据，所以在这里使用`zrem`依次删除元素，保证只有删除成功的进程才能使用这条数据。

# 使用

```python
# coding: utf8

import time

from delay import DelayQueue

redis_conf = {'host': '127.0.0.1', 'port': 6379, 'db': 0}

# 构造延迟队列对象
queue = DelayQueue(redis_conf)

# push 20条数据
for i in range(20):
    item = {'user': 'user-{}'.format(i)}
    queue.push(item)
    
# 从延迟队列中马上获取10条数据
data = queue.pop(num=10)
# 刚添加的马上获取是获取不到的
assert len(data) == 0

# 休眠10秒
time.sleep(10)
# 从延迟队列中获取10条数据
data = queue.pop(num=10)
assert len(data) == 10

# 从延迟队列中获取截止到5秒之前添加的10条数据
data = queue.pop(num=10, previous=5)
assert len(data) == 10
```

使用就比较简单了，在实际使用过程中，每次在处理正常队列时，通过上面的方法获取一下延迟队列的数据，如果延迟队列中有数据，那么按照业务正常处理就可以了，这样就达到了数据延迟处理的效果。

