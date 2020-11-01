title: Scrapy源码分析（三）核心组件初始化
date: 2016-11-21 23:30:16
categories: 爬虫
tags: [爬虫, scrapy, 源码分析]

---

在上一篇文章：[Scrapy源码分析（二）运行入口](http://kaito-kidd.com/2016/11/09/scrapy-code-analyze-entrance/)，我们主要剖析了 Scrapy 是如何运行起来的核心逻辑，也就是在真正执行抓取任务之前，Scrapy 都做了哪些工作。

这篇文章，我们就来进一步剖析一下，Scrapy 有哪些核心组件？以及它们主要负责了哪些工作？这些组件为了完成这些功能，内部又是如何实现的。

# 爬虫类

我们接着上一篇结束的地方开始讲起。上次讲到 Scrapy 运行起来后，执行到最后到了 `Crawler` 的 `crawl` 方法，我们来看这个方法：

```python
@defer.inlineCallbacks
def crawl(self, *args, **kwargs):
    assert not self.crawling, "Crawling already taking place"
    self.crawling = True
    try:
        # 从spiderloader中找到爬虫类 并实例化爬虫实例
        self.spider = self._create_spider(*args, **kwargs)
        # 创建引擎
        self.engine = self._create_engine()
        # 调用爬虫类的start_requests方法 拿到种子URL列表
        start_requests = iter(self.spider.start_requests())
        # 执行引擎的open_spider 并传入爬虫实例和初始请求
        yield self.engine.open_spider(self.spider, start_requests)
        yield defer.maybeDeferred(self.engine.start)
    except Exception:
        if six.PY2:
            exc_info = sys.exc_info()
        self.crawling = False
        if self.engine is not None:
            yield self.engine.close()
        if six.PY2:
            six.reraise(*exc_info)
        raise
```

执行到这里，我们看到首先创建了爬虫实例，然后创建了引擎，最后把爬虫交给引擎来处理了。

在上一篇文章我们也讲到，在 `Crawler` 实例化时，会创建 `SpiderLoader`，它会根据我们定义的配置文件 `settings.py` 找到存放爬虫的位置，我们写的爬虫代码都在这里。

然后 `SpiderLoader` 会扫描这些代码文件，并找到父类是 `scrapy.Spider` 爬虫类，然后根据爬虫类中的 `name` 属性（在编写爬虫时，这个属性是必填的），生成一个 `{spider_name: spider_cls}` 的字典，最后根据 `scrapy crawl <spider_name>` 命令中的 `spider_name` 找到我们写的爬虫类，然后实例化它，在这里就是调用了`_create_spider`方法：

```python
def _create_spider(self, *args, **kwargs):
    # 调用类方法from_crawler实例化
    return self.spidercls.from_crawler(self, *args, **kwargs)
```

实例化爬虫比较有意思，它不是通过普通的构造方法进行初始化，而是调用了类方法 `from_crawler` 进行的初始化，找到 `scrapy.Spider` 类：

```python
@classmethod
def from_crawler(cls, crawler, *args, **kwargs):
    spider = cls(*args, **kwargs)
    spider._set_crawler(crawler)
    return spider
    
def _set_crawler(self, crawler):
    self.crawler = crawler
    # 把settings对象赋给spider实例
    self.settings = crawler.settings
    crawler.signals.connect(self.close, signals.spider_closed)
```

在这里我们可以看到，这个类方法其实也是调用了构造方法，进行实例化，同时也拿到了 `settings` 配置，来看构造方法干了些什么？

```python
class Spider(object_ref):
    name = None
    custom_settings = None

    def __init__(self, name=None, **kwargs):
        # name必填
        if name is not None:
            self.name = name
        elif not getattr(self, 'name', None):
            raise ValueError("%s must have a name" % type(self).__name__)
        self.__dict__.update(kwargs)
        # 如果没有设置start_urls 默认是[]
        if not hasattr(self, 'start_urls'):
            self.start_urls = []
```

看到这里是不是很熟悉？这里就是我们平时编写爬虫类时，最常用的几个属性：`name`、`start_urls`、`custom_settings`：

- `name`：在运行爬虫时通过它找到我们编写的爬虫类；
- `start_urls`：抓取入口，也可以叫做种子URL；
- `custom_settings`：爬虫自定义配置，会覆盖配置文件中的配置项；

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1482242067.png" />

# 引擎

分析完爬虫类的初始化后，还是回到 `Crawler` 的 `crawl` 方法，紧接着就是创建**引擎**对象，也就是 `_create_engine` 方法，看看初始化时都发生了什么？

```python
class ExecutionEngine(object):
    """引擎"""
    def __init__(self, crawler, spider_closed_callback):
        self.crawler = crawler
        # 这里也把settings配置保存到引擎中
        self.settings = crawler.settings
        # 信号
        self.signals = crawler.signals
        # 日志格式
        self.logformatter = crawler.logformatter
        self.slot = None
        self.spider = None
        self.running = False
        self.paused = False
        # 从settings中找到Scheduler调度器，找到Scheduler类
        self.scheduler_cls = load_object(self.settings['SCHEDULER'])
        # 同样，找到Downloader下载器类
        downloader_cls = load_object(self.settings['DOWNLOADER'])
        # 实例化Downloader
        self.downloader = downloader_cls(crawler)
        # 实例化Scraper 它是引擎连接爬虫类的桥梁
        self.scraper = Scraper(crawler)
        self._spider_closed_callback = spider_closed_callback
```

在这里我们能看到，主要是对其他几个核心组件进行定义和初始化，主要包括包括：`Scheduler`、`Downloader`、`Scrapyer`，其中 `Scheduler` 只进行了类定义，没有实例化。

也就是说，引擎是整个 Scrapy 的核心大脑，它负责管理和调度这些组件，让这些组件更好地协调工作。

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1482242206.png" />

下面我们依次来看这几个核心组件都是如何初始化的？

# 调度器

调度器初始化发生在引擎的 `open_spider` 方法中，我们提前来看一下调度器的初始化。

```python
class Scheduler(object):
	"""调度器"""
    def __init__(self, dupefilter, jobdir=None, dqclass=None, mqclass=None,
                 logunser=False, stats=None, pqclass=None):
        # 指纹过滤器
        self.df = dupefilter
        # 任务队列文件夹
        self.dqdir = self._dqdir(jobdir)
        # 优先级任务队列类
        self.pqclass = pqclass
        # 磁盘任务队列类
        self.dqclass = dqclass
        # 内存任务队列类
        self.mqclass = mqclass
        # 日志是否序列化
        self.logunser = logunser
        self.stats = stats
        
    @classmethod
    def from_crawler(cls, crawler):
        settings = crawler.settings
        # 从配置文件中获取指纹过滤器类
        dupefilter_cls = load_object(settings['DUPEFILTER_CLASS'])
        # 实例化指纹过滤器
        dupefilter = dupefilter_cls.from_settings(settings)
        # 从配置文件中依次获取优先级任务队列类、磁盘队列类、内存队列类
        pqclass = load_object(settings['SCHEDULER_PRIORITY_QUEUE'])
        dqclass = load_object(settings['SCHEDULER_DISK_QUEUE'])
        mqclass = load_object(settings['SCHEDULER_MEMORY_QUEUE'])
        # 请求日志序列化开关
        logunser = settings.getbool('LOG_UNSERIALIZABLE_REQUESTS', settings.getbool('SCHEDULER_DEBUG'))
        return cls(dupefilter, jobdir=job_dir(settings), logunser=logunser,
                   stats=crawler.stats, pqclass=pqclass, dqclass=dqclass, mqclass=mqclass)
```

可以看到，调度器的初始化主要做了 2 件事：

- 实例化请求指纹过滤器：主要用来过滤重复请求；
- 定义不同类型的任务队列：优先级任务队列、基于磁盘的任务队列、基于内存的任务队列；

请求指纹过滤器又是什么？

在配置文件中，我们可以看到定义的默认指纹过滤器是 `RFPDupeFilter`：

```python
class RFPDupeFilter(BaseDupeFilter):
    """请求指纹过滤器"""
    def __init__(self, path=None, debug=False):
        self.file = None
        # 指纹集合 使用的是Set 基于内存
        self.fingerprints = set()
        self.logdupes = True
        self.debug = debug
        self.logger = logging.getLogger(__name__)
        # 请求指纹可存入磁盘
        if path:
            self.file = open(os.path.join(path, 'requests.seen'), 'a+')
            self.file.seek(0)
            self.fingerprints.update(x.rstrip() for x in self.file)

    @classmethod
    def from_settings(cls, settings):
        debug = settings.getbool('DUPEFILTER_DEBUG')
        return cls(job_dir(settings), debug)
```

请求指纹过滤器初始化时，定义了指纹集合，这个集合使用内存实现的 `Set`，而且可以控制这些指纹是否存入磁盘以供下次重复使用。

也就是说，指纹过滤器的主要职责是：**过滤重复请求，可自定义过滤规则。**

在下篇文章中我们会介绍到，每个请求是根据什么规则生成指纹的，然后是又如何实现重复请求过滤逻辑的，这里我们先知道它的功能即可。

下面来看调度器定义的任务队列都有什么作用？

调度器默认定义了 2 种队列类型：

- 基于磁盘的任务队列：在配置文件可配置存储路径，每次执行后会把队列任务保存到磁盘上；
- 基于内存的任务队列：每次都在内存中执行，下次启动则消失；

配置文件默认定义如下：

```python
# 基于磁盘的任务队列(后进先出)
SCHEDULER_DISK_QUEUE = 'scrapy.squeues.PickleLifoDiskQueue'
# 基于内存的任务队列(后进先出)
SCHEDULER_MEMORY_QUEUE = 'scrapy.squeues.LifoMemoryQueue'
# 优先级队列
SCHEDULER_PRIORITY_QUEUE = 'queuelib.PriorityQueue'
```

如果我们在配置文件中定义了 `JOBDIR` 配置项，那么每次执行爬虫时，都会把任务队列保存在磁盘中，下次启动爬虫时可以重新加载继续执行我们的任务。

如果没有定义这个配置项，那么默认使用的是内存队列。

细心的你可能会发现，默认定义的这些队列结构都是**后进先出**的，什么意思呢？

也就是在运行我们的爬虫代码时，如果生成一个抓取任务，放入到任务队列中，那么下次抓取就会从任务队列中先获取到这个任务，优先执行。

这么实现意味什么呢？其实意味着：**Scrapy 默认的采集规则是深度优先！**

如何改变这种机制，变为**广度优先采集**呢？这时候我们就要看一下 `scrapy.squeues` 模块了，在这里定义了很多种队列：

```python
# 先进先出磁盘队列(pickle序列化)
PickleFifoDiskQueue = _serializable_queue(queue.FifoDiskQueue, \
    _pickle_serialize, pickle.loads)
# 后进先出磁盘队列(pickle序列化)
PickleLifoDiskQueue = _serializable_queue(queue.LifoDiskQueue, \
    _pickle_serialize, pickle.loads)
# 先进先出磁盘队列(marshal序列化)
MarshalFifoDiskQueue = _serializable_queue(queue.FifoDiskQueue, \
    marshal.dumps, marshal.loads)
# 后进先出磁盘队列(marshal序列化)
MarshalLifoDiskQueue = _serializable_queue(queue.LifoDiskQueue, \
    marshal.dumps, marshal.loads)
# 先进先出内存队列
FifoMemoryQueue = queue.FifoMemoryQueue
# 后进先出内存队列
LifoMemoryQueue = queue.LifoMemoryQueue
```

如果我们想把抓取任务改为广度优先，我们只需要在配置文件中把队列类修改为**先进先出**队列类就可以了！从这里我们也可以看出，Scrapy 各个组件之间的耦合性非常低，每个模块都是可自定义的。

如果你想探究这些队列是如何实现的，可以参考 Scrapy 作者写的 [scrapy/queuelib](https://github.com/scrapy/queuelib) 项目，在 Github 上就可以找到，在这里有这些队列的具体实现。

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1482242425.png" />

<!-- more -->

# 下载器

回到引擎的初始化的地方，接下来我们来看，下载器是如何初始化的。

在默认的配置文件 `default_settings.py` 中，下载器配置如下：

```python
DOWNLOADER = 'scrapy.core.downloader.Downloader'
```

我们来看 `Downloader` 类的初始化：

```python
class Downloader(object):
    """下载器"""
    def __init__(self, crawler):
        # 同样的 拿到settings对象
        self.settings = crawler.settings
        self.signals = crawler.signals
        self.slots = {}
        self.active = set()
        # 初始化DownloadHandlers
        self.handlers = DownloadHandlers(crawler)
        # 从配置中获取设置的并发数
        self.total_concurrency = self.settings.getint('CONCURRENT_REQUESTS')
        # 同一域名并发数
        self.domain_concurrency = self.settings.getint('CONCURRENT_REQUESTS_PER_DOMAIN')
        # 同一IP并发数
        self.ip_concurrency = self.settings.getint('CONCURRENT_REQUESTS_PER_IP')
        # 随机延迟下载时间
        self.randomize_delay = self.settings.getbool('RANDOMIZE_DOWNLOAD_DELAY')
        # 初始化下载器中间件
        self.middleware = DownloaderMiddlewareManager.from_crawler(crawler)
        self._slot_gc_loop = task.LoopingCall(self._slot_gc)
        self._slot_gc_loop.start(60)
```

在这个过程中，主要是初始化了**下载处理器**、**下载器中间件管理器**以及从配置文件中拿到抓取请求控制的相关参数。

那么下载处理器是做什么的？下载器中间件又负责哪些工作？

先来看 `DownloadHandlers`：

```python
class DownloadHandlers(object):
    """下载器处理器"""
    def __init__(self, crawler):
        self._crawler = crawler
        self._schemes = {}	# 存储scheme对应的类路径 后面用于实例化
        self._handlers = {}	# 存储scheme对应的下载器
        self._notconfigured = {}
        # 从配置中找到DOWNLOAD_HANDLERS_BASE 构造下载处理器
        # 注意：这里是调用getwithbase方法  取的是配置中的XXXX_BASE配置
        handlers = without_none_values(
            crawler.settings.getwithbase('DOWNLOAD_HANDLERS'))
        # 存储scheme对应的类路径 后面用于实例化
        for scheme, clspath in six.iteritems(handlers):
            self._schemes[scheme] = clspath

        crawler.signals.connect(self._close, signals.engine_stopped)
```

下载处理器在默认的配置文件中是这样配置的：

```python
# 用户可自定义的下载处理器
DOWNLOAD_HANDLERS = {}
# 默认的下载处理器
DOWNLOAD_HANDLERS_BASE = {
    'file': 'scrapy.core.downloader.handlers.file.FileDownloadHandler',
    'http': 'scrapy.core.downloader.handlers.http.HTTPDownloadHandler',
    'https': 'scrapy.core.downloader.handlers.http.HTTPDownloadHandler',
    's3': 'scrapy.core.downloader.handlers.s3.S3DownloadHandler',
    'ftp': 'scrapy.core.downloader.handlers.ftp.FTPDownloadHandler',
}
```

看到这里你应该能明白了，下载处理器会根据下载资源的类型，选择对应的下载器去下载资源。其中我们最常用的就是 `http` 和 `https` 对应的处理器。

但是请注意，在这里，这些下载器是没有被实例化的，只有在真正发起网络请求时，才会进行初始化，而且只会初始化一次，后面文章会讲到。

下面我们来看下载器中间件 `DownloaderMiddlewareManager` 初始化过程，同样地，这里又调用了类方法 `from_crawler` 进行初始化，而且 `DownloaderMiddlewareManager` 继承了`MiddlewareManager` 类，来看它在初始化做了哪些工作：

```python
class MiddlewareManager(object):
    """所有中间件的父类，提供中间件公共的方法"""
    component_name = 'foo middleware'
    @classmethod
    def from_crawler(cls, crawler):
        # 调用from_settings
        return cls.from_settings(crawler.settings, crawler)
    
    @classmethod
    def from_settings(cls, settings, crawler=None):
        # 调用子类_get_mwlist_from_settings得到所有中间件类的模块
        mwlist = cls._get_mwlist_from_settings(settings)
        middlewares = []
        enabled = []
        # 依次实例化
        for clspath in mwlist:
            try:
                # 加载这些中间件模块
                mwcls = load_object(clspath)
                # 如果此中间件类定义了from_crawler 则调用此方法实例化
                if crawler and hasattr(mwcls, 'from_crawler'):
                    mw = mwcls.from_crawler(crawler)
                # 如果此中间件类定义了from_settings 则调用此方法实例化
                elif hasattr(mwcls, 'from_settings'):
                    mw = mwcls.from_settings(settings)
                # 上面2个方法都没有，则直接调用构造实例化
                else:
                    mw = mwcls()
                middlewares.append(mw)
                enabled.append(clspath)
            except NotConfigured as e:
                if e.args:
                    clsname = clspath.split('.')[-1]
                    logger.warning("Disabled %(clsname)s: %(eargs)s",
                                   {'clsname': clsname, 'eargs': e.args[0]},
                                   extra={'crawler': crawler})

        logger.info("Enabled %(componentname)ss:\n%(enabledlist)s",
                    {'componentname': cls.component_name,
                     'enabledlist': pprint.pformat(enabled)},
                    extra={'crawler': crawler})
        # 调用构造方法
        return cls(*middlewares)

    @classmethod
    def _get_mwlist_from_settings(cls, settings):
        # 具体有哪些中间件类，子类定义
        raise NotImplementedError
    
    def __init__(self, *middlewares):
        self.middlewares = middlewares
        # 定义中间件方法
        self.methods = defaultdict(list)
        for mw in middlewares:
            self._add_middleware(mw)
        
	def _add_middleware(self, mw):
        # 默认定义的 子类可覆盖
        # 如果中间件类有定义open_spider 则加入到methods
        if hasattr(mw, 'open_spider'):
            self.methods['open_spider'].append(mw.open_spider)
        # 如果中间件类有定义close_spider 则加入到methods
        # methods就是一串中间件的方法链 后期会依次调用
        if hasattr(mw, 'close_spider'):
            self.methods['close_spider'].insert(0, mw.close_spider)
```

`DownloaderMiddlewareManager` 实例化过程：

```python
class DownloaderMiddlewareManager(MiddlewareManager):
	"""下载中间件管理器"""
    component_name = 'downloader middleware'

    @classmethod
    def _get_mwlist_from_settings(cls, settings):
        # 从配置文件DOWNLOADER_MIDDLEWARES_BASE和DOWNLOADER_MIDDLEWARES获得所有下载器中间件
        return build_component_list(
            settings.getwithbase('DOWNLOADER_MIDDLEWARES'))

    def _add_middleware(self, mw):
        # 定义下载器中间件请求、响应、异常一串方法
        if hasattr(mw, 'process_request'):
            self.methods['process_request'].append(mw.process_request)
        if hasattr(mw, 'process_response'):
            self.methods['process_response'].insert(0, mw.process_response)
        if hasattr(mw, 'process_exception'):
            self.methods['process_exception'].insert(0, mw.process_exception)
```

**下载器中间件管理器**继承了 `MiddlewareManager` 类，然后重写了 `_add_middleware` 方法，为下载行为定义默认的**下载前、下载后、异常时**对应的处理方法。

这里我们可以想一下，中间件这么做的好处是什么？

从这里能大概看出，从某个组件流向另一个组件时，会经过一系列中间件，每个中间件都定义了自己的处理流程，相当于一个个管道，输入时可以针对数据进行处理，然后送达到另一个组件，另一个组件处理完逻辑后，又经过这一系列中间件，这些中间件可再针对这个响应结果进行处理，最终输出。

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1482242611.png" />

# Scraper

下载器实例化完了之后，回到引擎的初始化方法中，然后就是实例化 `Scraper`，在[Scrapy源码分析（一）架构概览](http://kaito-kidd.com/2016/11/01/scrapy-code-analyze-architecture/)这篇文章中我提到过，这个类没有在架构图中出现，但这个类其实是处于`Engine`、`Spiders`、`Pipeline` 之间，是连通这三个组件的桥梁。

我们来看一下它的初始化过程：

```python
class Scraper(object):

    def __init__(self, crawler):
        self.slot = None
        # 实例化爬虫中间件管理器
        self.spidermw = SpiderMiddlewareManager.from_crawler(crawler)
        # 从配置文件中加载Pipeline处理器类
        itemproc_cls = load_object(crawler.settings['ITEM_PROCESSOR'])
        # 实例化Pipeline处理器
        self.itemproc = itemproc_cls.from_crawler(crawler)
        # 从配置文件中获取同时处理输出的任务个数
        self.concurrent_items = crawler.settings.getint('CONCURRENT_ITEMS')
        self.crawler = crawler
        self.signals = crawler.signals
        self.logformatter = crawler.logformatter
```

`Scraper` 创建了 `SpiderMiddlewareManager`，它的初始化过程：

```python
class SpiderMiddlewareManager(MiddlewareManager):
	"""爬虫中间件管理器"""
    component_name = 'spider middleware'

    @classmethod
    def _get_mwlist_from_settings(cls, settings):
        # 从配置文件中SPIDER_MIDDLEWARES_BASE和SPIDER_MIDDLEWARES获取默认的爬虫中间件类
        return build_component_list(settings.getwithbase('SPIDER_MIDDLEWARES'))

    def _add_middleware(self, mw):
        super(SpiderMiddlewareManager, self)._add_middleware(mw)
        # 定义爬虫中间件处理方法
        if hasattr(mw, 'process_spider_input'):
            self.methods['process_spider_input'].append(mw.process_spider_input)
        if hasattr(mw, 'process_spider_output'):
            self.methods['process_spider_output'].insert(0, mw.process_spider_output)
        if hasattr(mw, 'process_spider_exception'):
            self.methods['process_spider_exception'].insert(0, mw.process_spider_exception)
        if hasattr(mw, 'process_start_requests'):
            self.methods['process_start_requests'].insert(0, mw.process_start_requests)
```

爬虫中间件管理器初始化与之前的下载器中间件管理器类似，先是从配置文件中加载了默认的爬虫中间件类，然后依次注册爬虫中间件的一系列流程方法。配置文件中定义的默认的爬虫中间件类如下：

```python
SPIDER_MIDDLEWARES_BASE = {
	# 默认的爬虫中间件类
    'scrapy.spidermiddlewares.httperror.HttpErrorMiddleware': 50,
    'scrapy.spidermiddlewares.offsite.OffsiteMiddleware': 500,
    'scrapy.spidermiddlewares.referer.RefererMiddleware': 700,
    'scrapy.spidermiddlewares.urllength.UrlLengthMiddleware': 800,
    'scrapy.spidermiddlewares.depth.DepthMiddleware': 900,
}
```

这里解释一下，这些默认的爬虫中间件的职责：

- HttpErrorMiddleware：针对非 200 响应错误进行逻辑处理；
- OffsiteMiddleware：如果Spider中定义了 `allowed_domains`，会自动过滤除此之外的域名请求；
- RefererMiddleware：追加 `Referer` 头信息；
- UrlLengthMiddleware：过滤 URL 长度超过限制的请求；
- DepthMiddleware：过滤超过指定深度的抓取请求；

当然，在这里你也可以定义自己的爬虫中间件，来处理自己所需的逻辑。

爬虫中间件管理器初始化完之后，然后就是 `Pipeline` 组件的初始化，默认的 `Pipeline` 组件是 `ItemPipelineManager`：

```python
class ItemPipelineManager(MiddlewareManager):

    component_name = 'item pipeline'

    @classmethod
    def _get_mwlist_from_settings(cls, settings):
        # 从配置文件加载ITEM_PIPELINES_BASE和ITEM_PIPELINES类
        return build_component_list(settings.getwithbase('ITEM_PIPELINES'))

    def _add_middleware(self, pipe):
        super(ItemPipelineManager, self)._add_middleware(pipe)
        # 定义默认的pipeline处理逻辑
        if hasattr(pipe, 'process_item'):
            self.methods['process_item'].append(pipe.process_item)

    def process_item(self, item, spider):
        # 依次调用所有子类的process_item方法
        return self._process_chain('process_item', item, spider)
```

我们可以看到 `ItemPipelineManager` 也是中间件管理器的一个子类，由于它的行为非常类似于中间件，但由于功能较为独立，所以属于核心组件之一。

从 `Scraper` 的初始化过程我们可以看出，它管理着 `Spiders` 和 `Pipeline` 相关的数据交互。

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1482242739.png" />

# 总结

好了，这篇文章我们主要剖析了 Scrapy 涉及到的核心的组件，主要包括：引擎、下载器、调度器、爬虫类、输出处理器，以及它们各自都是如何初始化的，在初始化过程中，它们又包含了哪些子模块来辅助完成这些模块的功能。

这些组件各司其职，相互协调，共同完成爬虫的抓取任务，而且从代码中我们也能发现，每个组件类都是定义在配置文件中的，也就是说我们可以实现自己的逻辑，然后替代这些组件，这样的设计模式也非常值得我们学习。

在下一篇文章中，我会带你剖析 Scrapy 最为核心的处理流程，分析这些组件具体是如何相互协作，完成我们的抓取任务的。

附：

- [Scrapy源码分析（一）架构概览](http://kaito-kidd.com/2016/11/01/scrapy-code-analyze-architecture/)
- [Scrapy源码分析（二）运行入口](http://kaito-kidd.com/2016/11/09/scrapy-code-analyze-entrance/)
- Scrapy源码分析（三）核心组件初始化
- [Scrapy源码分析（四）核心抓取流程](http://kaito-kidd.com/2016/12/07/scrapy-code-analyze-core-process/)

