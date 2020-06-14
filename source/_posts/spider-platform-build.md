title: 如何构建垂直网络爬虫平台
date: 2017-08-31 09:19:26
categories: 爬虫
tags: [爬虫, pyspdier, python]
---

> 最近在公司做了垂直网络爬虫平台的技术分享，故整理成文章分享给大家。


写一个爬虫很简单，写一个可持续稳定运行的爬虫也不难，但如何构建一个通用化的垂直网络爬虫平台？

这篇文章主要介绍垂直网络爬虫平台的构建思路。

# 爬虫简介

首先介绍一下什么是爬虫？

>  网络爬虫（又被称为网页蜘蛛，网络机器人），是一种按照一定的规则，自动地抓取网页信息的程序或者脚本。

很简单，爬虫就是指定规则自动采集数据的程序脚本，目的在于拿到想要的数据。

爬虫主要分两类：

- 通用网络爬虫（搜索引擎）
- 垂直网络爬虫（特定领域）

由于第一类的开发成本较高，故只有搜索引擎公司在做，如谷歌、百度等。

而大多数企业在做的是第二类，成本低、数据价值高。例如一家做电商的公司只需要电商领域有价值的数据，那开发一个电商领域的爬虫平台，意义较大。

这篇文章主要针对第二类的平台构建提供设计与思路。

<!-- more -->

# 如何写爬虫
首先从最简单的开始，我们先了解一下如何写一个爬虫？

## 简单爬虫


```python
# coding: utf8

"""简单爬虫"""

import requests
from lxml import etree

def run():
    """run"""
    # 1. 定义页面URL和解析规则
    crawl_urls = [
        'https://book.douban.com/subject/25862578/',
        'https://book.douban.com/subject/26698660/',
        'https://book.douban.com/subject/2230208/'
    ]
    parse_rule = "//div[@id='wrapper']/h1/span/text()"

    for url in crawl_urls:
        # 2. 发起HTTP请求
        response = requests.get(url)

        # 3. 解析HTML
        result = etree.HTML(response.text).xpath(parse_rule)[0]

        # 4. 保存结果
        print result

if __name__ == '__main__':
    run()
```
这个爬虫比较简单，大致流程为：

- 定义页面URL和解析规则
- 发起HTTP请求
- 解析HTML，拿到数据
- 保存数据

任何爬虫，要想获取网页上的数据，都是经过这几步。

当然，这个简单爬虫效率比较低，只能抓完一个网页，再去抓下一个，有没有提高效率的方式呢？

## 异步爬虫
```python
# coding: utf8

"""协程版本爬虫，提高抓取效率"""

from gevent import monkey
monkey.patch_all()

import requests
from lxml import etree
from gevent.pool import Pool

def run():
    """run"""
    # 1. 定义页面URL和解析规则
    crawl_urls = [
        'https://book.douban.com/subject/25862578/',
        'https://book.douban.com/subject/26698660/',
        'https://book.douban.com/subject/2230208/'
    ]
    rule = "//div[@id='wrapper']/h1/span/text()"

    # 2. 抓取
    pool = Pool(size=10)
    for url in crawl_urls:
        pool.spawn(crawl, url, rule)

    pool.join()

def crawl(url, rule):
    """抓取&解析"""
    # 3. 发起HTTP请求
    response = requests.get(url)

    # 4. 解析HTML
    result = etree.HTML(response.text).xpath(rule)[0]

    # 5. 保存结果
    print result

if __name__ == '__main__':
    run()
```
经过优化，我们完成了异步版本的爬虫代码。

由于爬虫要抓的网页一般很多，提高效率是爬虫最基本的技能，由于下载网页都是阻塞在网络IO上，那我们可以利用多线程或异步的方式，提高抓取效率。

有了这些基础知识之后，我们看一个完整的例子，如何抓取一个整站数据？

## 整站爬虫
```python
# coding: utf8

"""整站爬虫"""

from gevent import monkey
monkey.patch_all()

from urlparse import urljoin

import requests
from lxml import etree
from gevent.pool import Pool
from gevent.queue import Queue

base_url = 'https://book.douban.com'

# 种子URL
start_url = 'https://book.douban.com/tag/?view=type&icn=index-sorttags-all'

# 解析规则
rules = {
    # 标签页列表
    'list_urls': "//table[@class='tagCol']/tbody/tr/td/a/@href",
    # 详情页列表
    'detail_urls': "//li[@class='subject-item']/div[@class='info']/h2/a/@href",
    # 页码
    'page_urls': "//div[@id='subject_list']/div[@class='paginator']/a/@href",
    # 书名
    'title': "//div[@id='wrapper']/h1/span/text()",
}

# 定义队列
list_queue = Queue()
detail_queue = Queue()

# 定义协程池
pool = Pool(size=10)

def crawl(url):
    """首页"""
    response = requests.get(url)
    list_urls = etree.HTML(response.text).xpath(rules['list_urls'])
    for list_url in list_urls:
        list_queue.put(urljoin(base_url, list_url))

def list_loop():
    """采集列表页"""
    while True:
        list_url = list_queue.get()
        pool.spawn(crawl_list_page, list_url)

def detail_loop():
    """采集详情页"""
    while True:
        detail_url = detail_queue.get()
        pool.spawn(crawl_detail_page, detail_url)

def crawl_list_page(list_url):
    """采集列表页"""
    html = requests.get(list_url).text
    detail_urls = etree.HTML(html).xpath(rules['detail_urls'])
    # 详情页
    for detail_url in detail_urls:
        detail_queue.put(urljoin(base_url, detail_url))

    # 下一页
    list_urls = etree.HTML(html).xpath(rules['page_urls'])
    for list_url in list_urls:
        list_queue.put(urljoin(base_url, list_url))

def crawl_detail_page(list_url):
    """采集详情页"""
    html = requests.get(list_url).text
    title = etree.HTML(html).xpath(rules['title'])[0]
    print title

def run():
    """run"""
    # 1. 标签页
    crawl(start_url)
    # 2. 列表页
    pool.spawn(list_loop)
    # 3. 详情页
    pool.spawn(detail_loop)
    # 开始采集
    pool.join()

if __name__ == '__main__':
    run()
```
此爬虫以豆瓣图书为例，抓取整站信息，大致思路为：

- 从标签页进入，提取所有标签URL
- 进入每个标签页，提取所有列表URL
- 进入每个列表页，提取每一页的详情URL和下一页列表URL
- 进入每个详情页，拿到书名
- 如此往复循环，直到数据抓取完毕

这就是抓取一个整站的思路，很简单，无非就是分析我们浏览网站的行为轨迹，用程序来进行自动化的请求、抓取。

理想情况下，我们应该能够拿到整站的数据，但实际情况对方网站往往会采取防爬虫措施，在抓取一段时间后，我们的IP就会被禁。

那如何突破这些防爬错误，拿到数据呢？我们继续优化代码。


## 防反爬的整站爬虫
```python
# coding: utf8

"""防反爬的整站爬虫"""

from gevent import monkey
monkey.patch_all()

import random
from urlparse import urljoin

import requests
from lxml import etree
import gevent
from gevent.pool import Pool
from gevent.queue import Queue

base_url = 'https://book.douban.com'

# 种子URL
start_url = 'https://book.douban.com/tag/?view=type&icn=index-sorttags-all'

# 解析规则
rules = {
    # 标签页列表
    'list_urls': "//table[@class='tagCol']/tbody/tr/td/a/@href",
    # 详情页列表
    'detail_urls': "//li[@class='subject-item']/div[@class='info']/h2/a/@href",
    # 页码
    'page_urls': "//div[@id='subject_list']/div[@class='paginator']/a/@href",
    # 书名
    'title': "//div[@id='wrapper']/h1/span/text()",
}

# 定义队列
list_queue = Queue()
detail_queue = Queue()

# 定义协程池
pool = Pool(size=10)

# 定义代理池
proxy_list = [
    '118.190.147.92:15524',
    '47.92.134.176:17141',
    '119.23.32.38:20189',
]

# 定义UserAgent
user_agent_list = [
    'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:40.0) Gecko/20100101 Firefox/40.1',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.75.14 (KHTML, like Gecko) Version/7.0.3 Safari/7046A194A',
    'Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; AS; rv:11.0) like Gecko',
]

def fetch(url):
    """发起HTTP请求"""
    proxies = random.choice(proxy_list)
    user_agent = random.choice(user_agent_list)
    headers = {'User-Agent': user_agent}
    html = requests.get(url, headers=headers, proxies=proxies).text
    return html

def parse(html, rule):
    """解析页面"""
    return etree.HTML(html).xpath(rule)

def crawl(url):
    """首页"""
    html = fetch(url)
    list_urls = parse(html, rules['list_urls'])
    for list_url in list_urls:
        list_queue.put(urljoin(base_url, list_url))

def list_loop():
    """采集列表页"""
    while True:
        list_url = list_queue.get()
        pool.spawn(crawl_list_page, list_url)

def detail_loop():
    """采集详情页"""
    while True:
        detail_url = detail_queue.get()
        pool.spawn(crawl_detail_page, detail_url)

def crawl_list_page(list_url):
    """采集列表页"""
    html = fetch(list_url)
    detail_urls = parse(html, rules['detail_urls'])

    # 详情页
    for detail_url in detail_urls:
        detail_queue.put(urljoin(base_url, detail_url))

    # 下一页
    list_urls = parse(html, rules['page_urls'])
    for list_url in list_urls:
        list_queue.put(urljoin(base_url, list_url))

def crawl_detail_page(list_url):
    """采集详情页"""
    html = fetch(list_url)
    title = parse(html, rules['title'])[0]
    print title

def run():
    """run"""
    # 1. 首页
    crawl(start_url)
    # 2. 列表页
    pool.spawn(list_loop)
    # 3. 详情页
    pool.spawn(detail_loop)
    # 开始采集
    pool.join()

if __name__ == '__main__':
    run()
```
这个版本的爬虫代码，加上了随机代理和请求头，这也是突破防爬措施的常用手段，使用此手段，加上一些质量高的代理，应对一些小网站的数据抓取，不在话下。

当然，这里只为了展示一步步写爬虫、优化爬虫的思路，来达到抓取数据的目的，现实情况的抓取与反爬比想象中的更复杂，需要具体场景具体分析。

# 现有问题
经过上面这几步，我们想要哪个网站的数据，分析网站网页结构，写出代码应该不成问题。
**抓几个网站可以这么写，但抓几十个、几百个网站，你还能写下去吗？**

由此暴露的问题：

- 爬虫脚本繁多，管理困难
- 规则定义零散，重复开发
- 后台脚本，无监控
- 数据输出困难，业务接入慢

这些问题都是我们在爬虫越写越多的情况下，难免会遇到的问题。

此时，我们迫切需要一个更好的解决方案，来更好地开发爬虫，爬虫平台应运而生。

# 平台架构
我们来分析每个爬虫的共同点，结果发现：写一个爬虫无非就是规则、抓取、解析、入库这几步，那我们可不可以把每一块分别拆开呢？如图：

![](https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1504142245.png?imageMogr2/thumbnail/!70p)


- 配置服务：包括抓取页面配置、解析规则配置、清洗配置
- 采集服务：专注网页下载与采集，并提供防爬策略
- 代理服务：提供稳定可持续输出的代理
- 清洗服务：针对同一类型业务进行字段清洗
- 数据服务：数据展示及业务数据对接

我们把一个爬虫的每一个环节，拆开做成一个个单独的服务模块，各模块各司其职。

每个模块维护属于自己领域的功能，可独立升级和优化。

# 详细设计
## 配置服务
此模块主要包括采集URL配置、页面解析规则配置、清洗配置。

我们把爬虫的规则从爬虫脚本中抽离出来，单独配置与维护，这样也便于重用与管理。

由于此模块专注配置管理，那我们可以对配置进一步拆开，配置支持各种方式的数据解析模式，如正则解析、CSS解析、XPATH解析，每种模式配置对应的表达式即可。

采集服务可以写一个配置解析器与配置服务进行对接，此配置解析器内部实现各种模式具体的解析逻辑。

清洗配置主要可配置每个爬虫输出后对应的清洗worker。

## 采集服务
此模块比较纯粹，就是写爬虫逻辑的模块，我们可以像之前那样开发、调试、运行爬虫脚本，但这一切工作都只能在命令行脚本进行，有没有一种好的方案是可以**可视化**操作的呢？

我们调研了市面上比较好的爬虫框架，发现[pyspider](https://github.com/binux/pyspider)符合我们的需求，此框架的特点：

- 支持分布式
- 配置可视化
- 可周期采集
- 支持优先级
- 任务可监控

`pyspider`架构图：
![](https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1504142311.png?imageMogr2/thumbnail/!70p)


正所谓站在巨人的肩膀上。我们决定对其进行二次开发，并增强其一些组件，使爬虫开发成本更低，更符合我们的业务规则。

- 开发配置解析器，对接配置服务
- `spider handler`定制爬虫模板，分类采集任务，生成模板，降低开发成本
- `fetcher`新增代理调度机制，对接代理服务，并增加代理调度策略
- `result_worker`输出定制化，对接清洗服务

**由此我们可做出一个分布式、可视化、任务可监控、可生成爬虫模板的采集服务模块。**

## 代理服务
做爬虫的都知道，代理是突破防抓的常用手段，如何获取稳定且持续的代理呢？

此模块内部维护代理的质量和数量，并输出给采集服务，供采集使用。

主要包括两部分：

- 免费代理
- 付费代理

### 免费代理
免费代理主要由我们自己的代理采集程序采集获得，大致思路为：

- 收集代理源
- 定时采集代理
- 测试代理
- 输出代理

### 付费代理
免费代理的质量和稳定性相对较差，对于采集防爬比较厉害的网站，还是不够用。
这时我们会购买一些付费代理，专门用于采集这类防爬的网站，此代理一般为高匿代理，并定时更新。


## 清洗服务
此模块比较简单，主要接收采集服务输出的数据，然后根据对应的规则执行清洗逻辑。

例如网页字段与数据库字段归一转换，特殊字段清洗定制化等。

这个服务模块运行了很多worker，最终把输出结果输送到数据服务。

## 数据服务
此模块会接收最终清洗后的结构化数据，统一入库。且针对其他业务系统需要的数据进行统一推送输出：

- 数据平台展示
- 数据推送
- 数据API

# 解决的问题
经过这个平台的构建，基本解决了最开始困扰的几个问题：

- 爬虫管理、配置可视化
- 降低开发成本
- 进度可监控、易跟踪
- 数据输出便捷
- 业务接入迅速

# 爬虫技巧
爬虫技巧从整体上来说，其实核心思想就一个：**尽可能地模拟人的行为**。

例如：

- 随机UserAgent（github fake-useragent）
- 随机代理IP（高匿代理、代理策略）
- Cookie池
- JS渲染页面（phantomjs）
- 验证码识别（OCR、机器学习）

当然，做爬虫是一个相互博弈的过程，有时没必要硬碰硬，遇到问题换个思路不免是一种解决办法。例如，对方的PC站防抓厉害，那去看一看对方的WAP站可不可以搞一下？APP端是否可以尝试一下？在有限的成本拿到数据才是爬虫的目的。

> 以上就是构建一个垂直网络爬虫平台的大致思路，从最简单的爬虫脚本，到写越来越多的爬虫，到难以维护，再到整个爬虫平台的构建，一步步都是遇到问题解决问题的产物，在我们真正发现核心问题时，解决思路也就不难了。

