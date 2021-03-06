title: "豆瓣租房小组爬虫"
date: 2015-03-30 08:41:02
categories: 爬虫
tags: [生活, 租房]
---

# 起因
	最近一直没有更新博客了，主要忙什么？一言难尽，相信北漂的IT屌丝们，都会遇到这个问题，那就是找房子！
	房子到期，加上种种原因，决定撤离待了一年之久的小窝，不过也没什么特别值得留恋的，北漂就这样，工作、找房子、租房子。。
	找了半个多月的房子，房源信息包括豆瓣、58、搜房网等，看了不下十几家房子，感想只有一个字：找合适的真特么难！不过就在昨天，终于将这件头疼的事情尘埃落定！
	对于IT屌丝，当然是充分利用网络资源，但是网上例如58，赶集充斥了太多的中介信息，恶心的要命。最后在锁定在豆瓣租房小组中寻找。
	但豆瓣最坑爹的是竟然没有搜索相关功能，别人发帖后，你只能用肉眼一个个寻找自己所需的信息，不能忍了。
	最后决定自己写一个爬虫工具，时时监控豆瓣租房小组，抓下所有的信息，然后自己搞个页面，搜索、排序，OK，够用了！

# 项目
	用了3个晚上的时间，写出了这个爬虫，也比较简单，主要就是配置需要抓取的页面，分析所需信息，入库等等。

	然后做个前台页面，加上搜索排序等功能，齐活！

	效果如下：
![爬虫前台页面效果图](https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/spider-page.jpg "爬虫前台页面效果图")</br>

<!-- more -->

**项目地址在这里：**[豆瓣小组爬虫](https://github.com/kaito-kidd/douban-group-spider)

# 说明

此爬虫用`python`开发，基于`gevent`、`pymongo`、`requests`、`lxml`、`Flask `。<br/>

流程也相对较简单：

- 配置需要爬取的`URL`；
- 配置需要解析的信息元素，用`XPATH`完成；
- 配置`代理`；
- 配置`监控周期`、`最大页数`、`并发数`等；
- 运行爬虫，等待抓取，会自动根据配置`定时`爬取；
- 启动`web`服务，在前台`搜索`、`排序`等；

> 其实目前已经有人写过类似的工具，不过我觉得还是自己写的，所收集的信息是自己所能掌控的，别人的东西一方面是怕自己的需求不满足，另一方面是觉得自己不比人实现的差吧，继续努力！
	

