---
title: randomkey导致Redis阻塞的问题分析
date: 2020-06-25 18:09:13
categories: Redis
tags: [redis]
---

> 最近在公司对redis做一些二次开发时，发现一个`randomkey`命令可能导致整个redis实例长时间阻塞的问题，redis版本为3.2.9，以此记录。

# 问题

由于我们公司使用的是redis集群版Codis，Codis内置的redis版本比较低，为3.2.9版本。

我们近期在做Codis双机房时，需要对redis增加一些功能以此支持双机房，在开发和测试中发现，执行`randomkey`命令有可能导致整个redis长时间阻塞的问题。

<!-- more -->

`randomkey`主要功能是在redis中随机返回一个key出来，它随机选取key的代码如下。

```c
robj *dbRandomKey(redisDb *db) {
    dictEntry *de;

    // 死循环从哈希表中找到一个不过期的key
    while(1) {
        sds key;
        robj *keyobj;

        // 从实例的哈希表里随机一个元素
        de = dictGetRandomKey(db->dict);
        if (de == NULL) return NULL;

        // 获取这个元素的key
        key = dictGetKey(de);
        keyobj = createStringObject(key,sdslen(key));
        // 如果key已经过期 则把这个key从实例中删除
        // 注意：expireIfNeeded对于过期的key只针对master有效
        // 如果是slave则永远不会删除key
        if (dictFind(db->expires,key)) {
            if (expireIfNeeded(db,keyobj)) {
                decrRefCount(keyobj);
                continue;
            }
        }
        return keyobj;
    }
}
```

从上面代码可以看出来，如果当前是个slave，并且整个实例中存在大量已经过期的key（key已过期，但redis还未来得及删除key），执行`randomkey`命令时，由于找不到不过期的key，那么这个逻辑就会陷入**死循环**，阻塞住整个实例，整个实例不可用。

如果当前是master，执行`randomkey`命令时，redis会一直随机选择key，直到找到一个不过期的key，同时会把已经过期的key从整个实例中删除。也就是说，在这种场景下，虽然不会长时间阻塞整个实例，但也会比执行一个普通的命令耗时要久。如果你在一个大量已过期的实例上执行`randomkey`命令，那可能会导致业务访问redis变慢。

# 解决

我们对比了官方最新版的redis，已经针对此问题进行了修复。

```c
robj *dbRandomKey(redisDb *db) {
    dictEntry *de;
    // 当前实例全部都是过期key 最大循环100次
    int maxtries = 100;
    int allvolatile = dictSize(db->dict) == dictSize(db->expires)

    // 死循环从哈希表中找到一个不过期的key
    while(1) {
        sds key;
        robj *keyobj;

        // 从实例的哈希表里随机一个元素
        de = dictGetRandomKey(db->dict);
        if (de == NULL) return NULL;

        // 获取这个元素的key
        key = dictGetKey(de);
        keyobj = createStringObject(key,sdslen(key));
        // 如果key已经过期 则把这个key从实例中删除
        // 注意：expireIfNeeded对于过期的key只针对master有效
        // 如果是slave则永远不会删除key
        if (dictFind(db->expires,key)) {
            // 如果整个实例都是过期key 在slave上执行此命令最多循环100次 避免长时间阻塞
            if (allvolatile && server.masterhost && --maxtries == 0) {
                return keyobj;
            }
            if (expireIfNeeded(db,keyobj)) {
                decrRefCount(keyobj);
                continue;
            }
        }
        return keyobj;
    }
}
```

解决方案就是增加一个**最大重试次数**，如果整个实例都是过期key，那么最多寻找`maxtries`次就返回，避免阻塞整个实例。

# 注意点

但要注意的是，如果达到了`maxtries`，那么返回的key是已经过期的key，你虽然在`randomkey`中看到了这个key，但对这个key执行其他命令时，还是拿不到这个key的。

这个方案只针对slave上执行这个命令进行了修复，也就是不会再让redis陷入死循环。

但在master上执行这个命令还是会发生上述的变慢问题，如果你在使用redis时，经常使用这个命令，同时实例中存在大量已经过期的key，那么redis变慢很有可能是这个问题导致的。
