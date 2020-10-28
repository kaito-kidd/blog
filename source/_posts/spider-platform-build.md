title: 如何构建一个通用的垂直爬虫平台？
date: 2017-08-31 09:19:26
categories: 爬虫
tags: [爬虫, pyspider, python]
---

> 之前做爬虫时，在公司设计开发了一个通用的垂直爬虫平台，后来在公司做了内部的技术分享，这篇文章把整个爬虫平台的设计思路整理了一下，分享给大家。

写一个爬虫很简单，写一个可持续稳定运行的爬虫也不难，但如何构建一个通用化的垂直爬虫平台？

这篇文章，我就来和你分享一下，一个通用垂直爬虫平台的构建思路。

# 爬虫简介

首先介绍一下，什么是爬虫？

搜索引擎是这样定义的：

> 网络爬虫（又被称为网页蜘蛛，网络机器人），是一种按照一定的规则，自动地抓取网页信息的程序或者脚本。

很简单，爬虫就是指定规则自动采集数据的程序脚本，目的在于拿到想要的数据。

而爬虫主要分为两大类：

- 通用爬虫（搜索引擎）
- 垂直爬虫（特定领域）

由于第一类的开发成本较高，所以只有搜索引擎公司在做，如谷歌、百度等。

而大多数企业在做的都是第二类，成本低、数据价值高。

例如一家做电商的公司只需要电商领域有价值的数据，那开发一个只采集电商领域数据的爬虫平台，意义较大。

我要和你分享的主要是针对第二类，垂直爬虫平台的设计思路。

<!-- more -->

# 如何写爬虫

首先，从最简单的开始，我们先了解一下如何写一个爬虫？

## 简单爬虫

开发爬虫最快的语言一般是 Python，它的代码写起来非常少。我们以抓取豆瓣书籍页面为例，来写一个简单的程序。

```python
# coding: utf8

"""简单爬虫"""

import requests
from lxml import etree

def main():
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
    main()
```

这个爬虫比较简单，大致流程为：

1. 定义页面URL和解析规则
2. 发起HTTP请求
3. 解析HTML，拿到数据
4. 保存数据

任何爬虫，要想获取网页上的数据，都是经过这几步。

当然，这个简单爬虫效率比较低，是采用同步抓取的方式，只能抓完一个网页，再去抓下一个，有没有可以提高效率的方式呢？

## 异步爬虫

我们进行优化，由于爬虫的抓取请求都是阻塞在网络 IO 上，所以我们可以使用异步的方式来优化，例如多线程或协程并行抓取网页数据，这里用 Python 的协程来实现。

```python
# coding: utf8

"""协程版本爬虫，提高抓取效率"""

from gevent import monkey
monkey.patch_all()

import requests
from lxml import etree
from gevent.pool import Pool

def main():
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
    # 3. 发起HTTP请求
    response = requests.get(url)

    # 4. 解析HTML
    result = etree.HTML(response.text).xpath(rule)[0]

    # 5. 保存结果
    print result

if __name__ == '__main__':
    main()
```

经过优化，我们完成了异步版本的爬虫代码。

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

def main():
    # 1. 标签页
    crawl(start_url)
    # 2. 列表页
    pool.spawn(list_loop)
    # 3. 详情页
    pool.spawn(detail_loop)
    # 开始采集
    pool.join()

if __name__ == '__main__':
    main()
```

我们想要抓取豆瓣图书的整站数据，执行的流程是：

1. 找到入口，也就是从书籍标签页进入，提取所有标签 URL
2. 进入每个标签页，提取所有列表 URL
3. 进入每个列表页，提取每一页的详情URL和下一页列表 URL
4. 进入每个详情页，拿到书籍信息
5. 如此往复循环，直到数据抓取完毕

这就是抓取一个整站的思路，很简单，无非就是分析我们浏览网站的行为轨迹，用程序来进行自动化的请求、抓取。

理想情况下，我们应该能够拿到整站的数据，但实际情况是，对方网站往往会采取防爬虫措施，在抓取一段时间后，我们的 IP 就会被封禁。

那如何突破这些防爬措施，拿到数据呢？我们继续优化代码。

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

def main():
    # 1. 首页
    crawl(start_url)
    # 2. 列表页
    pool.spawn(list_loop)
    # 3. 详情页
    pool.spawn(detail_loop)
    # 开始采集
    pool.join()

if __name__ == '__main__':
    main()
```

这个版本的代码与之前不同的是，在发起 HTTP 请求时，加上了随机代理 IP 和请求头 UserAgent，这也是突破防爬措施的常用手段。使用这些手段，加上一些质量高的代理 IP，应对一些小网站的数据抓取，不在话下。

当然，这里只为了展示一步步写爬虫、优化爬虫的思路，来达到抓取数据的目的，现实情况的抓取与反爬比想象中的更复杂，需要具体场景具体分析。

# 现有问题

经过上面这几步，我们想要哪个网站的数据，分析网站网页结构，写出代码应该不成问题。

但是，**抓几个网站可以这么写，但抓几十个、几百个网站，你还能写下去吗？**

当我们要采集的网站越来越多，编写的爬虫脚本也会越来越多，维护起来也会变得困难。由此暴露出来的问题包括：

- 爬虫脚本繁多，管理和维护困难
- 爬虫规则定义零散，可能会重复开发
- 爬虫都是后台脚本，没有监控
- 爬虫脚本输出的数据格式不统一，可能是文件，也可能也数据库
- 业务要想使用爬虫的数据比较困难，没有统一的对接入口

这些问题都是我们在爬虫越写越多的情况下，难免会遇到的问题。

此时，我们迫切需要一个更好的解决方案，来更好地开发爬虫，所以爬虫平台应运而生。

那么如何设计一个通用化的垂直爬虫平台呢？

# 平台架构

我们来分析每个爬虫的共同点，结果发现：写一个爬虫无非就是**规则、抓取、解析、入库**这几步，那我们可不可以把每一块分别拆开呢？

根据这个思路，我们可以把爬虫平台设计成如下图：

![](https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1504142245.png?imageMogr2/thumbnail/!70p)

我们的爬虫平台包括的模块有：

- 配置服务：包括抓取页面配置、解析规则配置、数据清洗配置
- 采集服务：只专注网页的下载，并配置防爬策略
- 代理服务：持续提供稳定、可用的代理 IP
- 清洗服务：针对爬虫采集到的数据进行进一步清洗和规整
- 数据服务：爬虫数据的展示，以及业务系统对接

我们把一个爬虫的每一个环节，拆开做成一个个单独的服务模块，各模块各司其职，每个模块之间通过 API 或 消息队列进行通信。

这样做的好处是，每个模块维护只维护自己领域的功能，而且每个模块可独立升级和优化，不影响其他模块。

下面我们来看一下每个模块具体是如何设计的。

# 详细设计

## 配置服务

配置服务模块，此模块主要包括采集 URL 的配置、页面解析规则的配置、数据清洗规则的配置。

我们把爬虫的规则从爬虫脚本中抽离出来，单独配置与维护，这样做的好处是便于**重用和管理**。

由于此模块只专注配置管理，那我们可以对配置规则进一步拆开，可以支持各种方式的数据解析模式，主要包含以下几种：

- 正则解析规则
- CSS解析规则
- XPATH解析规则

每种解析规则模式，只配置对应的表达式即可。

采集服务可以写一个配置解析器，与配置服务进行对接，这个配置解析器内部实现各种模式具体的解析逻辑。

数据清洗规则配置，主要包含每个页面采集数据后，针对这个页面字段做进一步清洗和规整化的配置规则。例如采集服务抓取到的数据包含特殊字符，在采集服务中不会做进一步处理，而是放到清洗服务中去处理，具体的清洗规则可以自定义，常见的有删除某些特殊字符、特殊字段类型转换等等。

## 采集服务

此服务模块比较纯粹，就是写爬虫逻辑。我们可以像之前那样开发、调试、运行爬虫脚本那样，在此模块来开发和调试爬虫逻辑。

但之前的方式只能在命令行脚本中编写爬虫程序，然后调试运行，有没有一种好的方案可以把它做成**可视化**的呢？

我们调研了市面上 Python 语言实现的，比较好的爬虫框架，发现 [pyspider](https://github.com/binux/pyspider) 符合我们的需求，此框架的特点：

- 支持分布式
- 配置可视化
- 可周期采集
- 支持优先级
- 任务可监控

`pyspider`架构图如下：
![](https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1504142311.png?imageMogr2/thumbnail/!70p)

正所谓站在巨人的肩膀上，这个框架基本可以满足我们的需求，但为了更好地实现我们的爬虫平台，我们决定对其进行二次开发，并增强一些组件，使爬虫开发成本更低，更符合我们的业务规则。

二次开发的功能主要包括：

- 开发配置解析器，对接配置服务，可以解析配置服务的多种规则模式
- `spider handler`模块定制爬虫模板，并把爬虫任务进行分类，定义成模板，降低开发成本
- `fetcher`模块新增代理 IP 调度机制，对接代理服务，并增加代理 IP 调度策略
- `result_worker`模块把输出结果定制化，用来对接清洗服务

基于这个开源框架，并且增强其组件的方式，**我们可以做出一个分布式、可视化、任务可监控、可生成爬虫模板的采集服务模块。**

这个模块的功能，只专注于网页数据的采集。

## 代理服务

做爬虫的都知道，代理是突破防抓的常用手段，如何获取稳定、持续的代理呢？

代理服务这个模块，就是用来实现这个功能的。

此模块内部维护代理 IP 的质量和数量，并输出给采集服务，供其采集使用。

该模块主要包括两部分：

- 免费代理
- 付费代理

### 免费代理

免费代理 IP 主要由我们自己的代理采集程序采集获得，大致思路为：

- 收集代理源
- 定时采集代理
- 测试代理
- 输出可用代理

具体的实现逻辑可以参考我之前写的这篇文章：[如何构建一个爬虫代理采集服务？](http://kaito-kidd.com/2015/11/02/proxies-service/)

### 付费代理

免费代理的质量和稳定性相对较差，对于采集防爬比较厉害的网站，还是不够用。

这时我们会购买一些付费代理，专门用于采集这类防爬的网站，此代理 IP 一般为高匿代理，并定时更新。

免费代理 IP + 付费代理 IP，通过 API 的方式提供给采集服务。

## 清洗服务

清洗服务这个模块比较简单，主要接收采集服务输出的数据，然后根据对应的规则执行清洗逻辑。

例如网页字段与数据库字段归一转换，特殊字段清洗定制化等等。

这个服务模块运行了很多 Worker，最终把输出结果输送到数据服务。

## 数据服务

数据服务这个模块，会接收最终清洗后的结构化数据，统一入库。且针对其他业务系统需要的数据进行统一推送输出：

主要功能包括：

- 数据平台展示
- 数据推送
- 数据API

# 解决的问题

好了，经过以上爬虫平台的构建，我们基本解决了最开始困扰的几个问题，现在的爬虫平台可以实现的功能包括：

- 爬虫脚本统一管理、配置可视化
- 爬虫模板快速生成爬虫代码，降低开发成本
- 采集进度可监控、易跟踪
- 采集的数据统一输出
- 业务系统使用爬虫数据更便捷

# 爬虫技巧

最后，分享一下做爬虫时候的一些技巧，从整体上来说，其实核心思想就一个：**尽可能地模拟人的行为**。

主要包括以下几方面：

- 随机 UserAgent 模拟不同的客户端（github有UserAgent库，非常全面）
- 随机代理 IP（高匿代理 + 代理调度策略）
- Cookie池（针对需要登录的采集行为）
- JavaScript渲染页面（使用无界面浏览器加载网页获取数据）
- 验证码识别（OCR、机器学习）

当然，做爬虫是一个相互博弈的过程，有时没必要硬碰硬，遇到问题换个思路也是一种解决办法。例如，对方的移动客户端防抓厉害，那去看一看对方的PC站可不可以搞一下？WAP端是否可以尝试一下？在有限的成本拿到数据才是爬虫的目的。

爬虫做的越来越多时，你就会发现，这是一个策略和技巧同样重要的领域。

> 以上就是构建一个垂直爬虫平台的设计思路，从最简单的爬虫脚本，到写越来越多的爬虫，到难以维护，再到整个爬虫平台的构建，一步步都是遇到问题解决问题的产物，在我们真正发现核心问题时，解决思路也就不难了。

