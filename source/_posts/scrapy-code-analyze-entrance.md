title: "Scrapy源码分析（二）运行入口"
date: 2016-11-09 20:35:31
categories: 爬虫
tags: [爬虫, scrapy, 源码分析]
---

在上篇文章：[Scrapy源码分析（一）架构概览](http://kaito-kidd.com/2016/11/01/scrapy-code-analyze-architecture/)，我们主要从整体上了解了 Scrapy 的架构和数据流转，并没有深入分析每个模块。从这篇文章开始，我将带你详细剖析 Scrapy 的运行原理。

这篇文章，我们先从最基础的运行入口来讲，来看一下 Scrapy 究竟是如何运行起来的。

# scrapy 命令从哪来？

当我们基于 Scrapy 写好一个爬虫后，想要把我们的爬虫运行起来，怎么做？非常简单，只需要执行以下命令就可以了。

```shell
 scrapy crawl <spider_name>
```

通过这个命令，我们的爬虫就真正开始工作了。那么从命令行到执行爬虫逻辑，这个过程中到底发生了什么？

在开始之前，不知道你有没有和我一样的疑惑，我们执行的 `scrapy` 命令从何而来？

实际上，当你成功安装好 Scrapy 后，使用如下命令，就能找到这个命令文件，这个文件就是 Scrapy 的运行入口：

```
$ which scrapy
/usr/local/bin/scrapy
```

使用编辑打开这个文件，你会发现，它其实它就是一个 Python 脚本，而且代码非常少。

```python
import re
import sys

from scrapy.cmdline import execute

if __name__ == '__main__':
    sys.argv[0] = re.sub(r'(-script\.pyw|\.exe)?$', '', sys.argv[0])
    sys.exit(execute())
```

安装好 Scrapy 后，为什么入口点是这里呢？

答案就在于 Scrapy 的安装文件 `setup.py` 中，我们找到这个文件，就会发现在这个文件里，已经声明好了程序的运行入口处：

```python
from os.path import dirname, join
from setuptools import setup, find_packages

setup(
    name='Scrapy',
    version=version,
    url='http://scrapy.org',
    ...
    entry_points={      # 运行入口在这里：scrapy.cmdline:execute
        'console_scripts': ['scrapy = scrapy.cmdline:execute']
    },
    classifiers=[
        ...
    ],
    install_requires=[
        ...
    ],
)
```

我们需要关注的是 `entry_points` 配置，它就是调用 Scrapy 开始的地方，也就是`cmdline.py` 的 `execute` 方法。

也就是说，我们在安装 Scrapy 的过程中，`setuptools` 这个包管理工具，就会把上述代码生成好并放在可执行路径下，这样当我们调用 `scrapy` 命令时，就会调用 Scrapy 模块下的 `cmdline.py` 的 `execute` 方法。

而且在这这里，我们可以学到一个小技巧——如何用 Python 编写一个可执行文件？其实非常简单，模仿上面的思路，只需要以下几步即可完成：

1. 编写一个带有 `main` 方法的 Python 模块（首行必须注明 Python 执行路径）
2. 去掉`.py`后缀名
3. 修改权限为可执行（`chmod +x` 文件名）
4. 直接用文件名就可以执行这个 Python 文件

例如，我们创建一个文件 `mycmd`，在这个文件中编写一个 `main` 方法，这个方法编写我们想要的执行的逻辑，之后执行 `chmod +x mycmd` 把这个文件权限变成可执行，最后通过 `./mycmd` 就可以执行这段代码了，而不再需要通过 `python <file.py>` 方式就可以执行了，是不是很简单？

# 运行入口（execute.py）

现在，我们已经知道了 Scrapy 的运行入口是 `scrapy/cmdline.py` 的 `execute` 方法，那我们就看一下这个方法。

```python
def execute(argv=None, settings=None):
    if argv is None:
        argv = sys.argv

    # --- 兼容低版本scrapy.conf.settings的配置 ---
    if settings is None and 'scrapy.conf' in sys.modules:
        from scrapy import conf
        if hasattr(conf, 'settings'):
            settings = conf.settings
    # -----------------------------------------

	# 初始化环境、获取项目配置参数 返回settings对象
    if settings is None:
        settings = get_project_settings()
    # 校验弃用的配置项
    check_deprecated_settings(settings)

    # --- 兼容低版本scrapy.conf.settings的配置 ---
    import warnings
    from scrapy.exceptions import ScrapyDeprecationWarning
    with warnings.catch_warnings():
        warnings.simplefilter("ignore", ScrapyDeprecationWarning)
        from scrapy import conf
        conf.settings = settings
    # ---------------------------------------

    # 执行环境是否在项目中 主要检查scrapy.cfg配置文件是否存在
    inproject = inside_project()

    # 读取commands文件夹 把所有的命令类转换为{cmd_name: cmd_instance}的字典
    cmds = _get_commands_dict(settings, inproject)
    # 从命令行解析出执行的是哪个命令
    cmdname = _pop_command_name(argv)
    parser = optparse.OptionParser(formatter=optparse.TitledHelpFormatter(), \
        conflict_handler='resolve')
    if not cmdname:
        _print_commands(settings, inproject)
        sys.exit(0)
    elif cmdname not in cmds:
        _print_unknown_command(settings, cmdname, inproject)
        sys.exit(2)

    # 根据命令名称找到对应的命令实例
    cmd = cmds[cmdname]
    parser.usage = "scrapy %s %s" % (cmdname, cmd.syntax())
    parser.description = cmd.long_desc()
    # 设置项目配置和级别为command
    settings.setdict(cmd.default_settings, priority='command')
    cmd.settings = settings
    # 添加解析规则
    cmd.add_options(parser)
    # 解析命令参数，并交由Scrapy命令实例处理
    opts, args = parser.parse_args(args=argv[1:])
    _run_print_help(parser, cmd.process_options, args, opts)

    # 初始化CrawlerProcess实例 并给命令实例添加crawler_process属性
    cmd.crawler_process = CrawlerProcess(settings)
    # 执行命令实例的run方法
    _run_print_help(parser, _run_command, cmd, args, opts)
    sys.exit(cmd.exitcode)
```

这块代码就是 Scrapy 执行的运行入口了，我们根据注释就能看到，这里的主要工作包括配置初始化、命令解析、爬虫类加载、运行爬虫这几步。

了解了整个入口的流程，下面我会对每个步骤进行详细的分析。

<!-- more -->

# 初始化项目配置

首先第一步，根据环境初始化配置，在这里有一些兼容低版本 Scrapy 配置的代码，我们忽略就好。我们重点来看配置是如何初始化的。这主要和环境变量和 `scrapy.cfg` 有关，通过调用  `get_project_settings` 方法，最终生成一个 `Settings` 实例。

```python
def get_project_settings():
    # 环境变量中是否有SCRAPY_SETTINGS_MODULE配置
    if ENVVAR not in os.environ:
        project = os.environ.get('SCRAPY_PROJECT', 'default')
        # 初始化环境 找到用户配置文件settings.py 设置到环境变量SCRAPY_SETTINGS_MODULE中
        init_env(project)
    # 加载默认配置文件default_settings.py 生成settings实例
    settings = Settings()
    # 取得用户配置文件
    settings_module_path = os.environ.get(ENVVAR)
    # 如果有用户配置 则覆盖默认配置
    if settings_module_path:
        settings.setmodule(settings_module_path, priority='project')
    # 如果环境变量中有其他scrapy相关配置也覆盖
    pickled_settings = os.environ.get("SCRAPY_PICKLED_SETTINGS_TO_OVERRIDE")
    if pickled_settings:
        settings.setdict(pickle.loads(pickled_settings), priority='project')
    env_overrides = {k[7:]: v for k, v in os.environ.items() if
                     k.startswith('SCRAPY_')}
    if env_overrides:
        settings.setdict(env_overrides, priority='project')
    return settings
```

在初始配置时，会加载默认的配置文件 `default_settings.py`，主要逻辑在 `Settings` 类中。

```python
class Settings(BaseSettings):
    def __init__(self, values=None, priority='project'):
        # 调用父类构造初始化
        super(Settings, self).__init__()
        # 把default_settings.py的所有配置set到settings实例中
        self.setmodule(default_settings, 'default')
        # 把attributes属性也set到settings实例中
        for name, val in six.iteritems(self):
            if isinstance(val, dict):
                self.set(name, BaseSettings(val, 'default'), 'default')
        self.update(values, priority)
```

可以看到，首先把默认配置文件 `default_settings.py` 中的所有配置项设置到 `Settings` 中，而且这个配置是有优先级的。

这个默认配置文件 `default_settings.py` 是非常重要的，我们读源码时有必要重点关注一下里面的内容，这里包含了所有组件的默认配置，以及每个组件的类模块，例如调度器类、爬虫中间件类、下载器中间件类、下载处理器类等等。

```python
# 下载器类
DOWNLOADER = 'scrapy.core.downloader.Downloader'
# 调度器类
CHEDULER = 'scrapy.core.scheduler.Scheduler'
# 调度队列类
SCHEDULER_DISK_QUEUE = 'scrapy.squeues.PickleLifoDiskQueue'
SCHEDULER_MEMORY_QUEUE = 'scrapy.squeues.LifoMemoryQueue'
SCHEDULER_PRIORITY_QUEUE = 'scrapy.pqueues.ScrapyPriorityQueue'
```

有没有感觉比较奇怪，默认配置中配置了这么多类模块，这是为什么？

这其实是 Scrapy 特性之一，它这么做的好处是：**任何模块都是可替换的**。

什么意思呢？例如，你觉得默认的调度器功能不够用，那么你就可以按照它定义的接口标准，自己实现一个调度器，然后在自己的配置文件中，注册自己的调度器类，那么 Scrapy 运行时就会加载你的调度器执行了，这极大地提高了我们的灵活性！

所以，只要在默认配置文件中配置的模块类，都是可替换的。

# 检查运行环境是否在项目中

初始化完配置之后，下面一步是检查运行环境是否在爬虫项目中。我们知道，`scrapy` 命令有的是依赖项目运行的，有的命令则是全局的。这里主要通过就近查找 `scrapy.cfg` 文件来确定是否在项目环境中，主要逻辑在 `inside_project` 方法中。

```python
def inside_project():
    # 检查此环境变量是否存在(上面已设置)
    scrapy_module = os.environ.get('SCRAPY_SETTINGS_MODULE')
    if scrapy_module is not None:
        try:
            import_module(scrapy_module)
        except ImportError as exc:
            warnings.warn("Cannot import scrapy settings module %s: %s" % (scrapy_module, exc))
        else:
            return True
	# 如果环境变量没有 就近查找scrapy.cfg 找得到就认为是在项目环境中
    return bool(closest_scrapy_cfg())
```

运行环境是否在爬虫项目中的依据就是能否找到 `scrapy.cfg` 文件，如果能找到，则说明是在爬虫项目中，否则就认为是执行的全局命令。

# 组装命令实例集合

再向下看，就到了加载命令的逻辑了。我们知道 `scrapy` 包括很多命令，例如 `scrapy crawl` 、 `scrapy fetch` 等等，那这些命令是从哪来的？答案就在 `_get_commands_dict` 方法中。

```python
def _get_commands_dict(settings, inproject):
    # 导入commands文件夹下的所有模块 生成{cmd_name: cmd}的字典集合
    cmds = _get_commands_from_module('scrapy.commands', inproject)
    cmds.update(_get_commands_from_entry_points(inproject))
    # 如果用户自定义配置文件中有COMMANDS_MODULE配置 则加载自定义的命令类
    cmds_module = settings['COMMANDS_MODULE']
    if cmds_module:
        cmds.update(_get_commands_from_module(cmds_module, inproject))
    return cmds

def _get_commands_from_module(module, inproject):
    d = {}
    # 找到这个模块下所有的命令类(ScrapyCommand子类)
    for cmd in _iter_command_classes(module):
        if inproject or not cmd.requires_project:
            # 生成{cmd_name: cmd}字典
            cmdname = cmd.__module__.split('.')[-1]
            d[cmdname] = cmd()
    return d

def _iter_command_classes(module_name):
    # 迭代这个包下的所有模块 找到ScrapyCommand的子类
    for module in walk_modules(module_name):
        for obj in vars(module).values():
            if inspect.isclass(obj) and \
                    issubclass(obj, ScrapyCommand) and \
                    obj.__module__ == module.__name__:
                yield obj
```

这个过程主要是，导入 `commands` 文件夹下的所有模块，最终生成一个 `{cmd_name: cmd}` 字典集合，如果用户在配置文件中也配置了自定义的命令类，也会追加进去。也就是说，我们自己也可以**编写自己的命令类**，然后追加到配置文件中，之后就可以使用自己定义的命令了。

# 解析命令

加载好命令类后，就开始解析我们具体执行的哪个命令了，解析逻辑比较简单：

```python
def _pop_command_name(argv):
    i = 0
    for arg in argv[1:]:
        if not arg.startswith('-'):
            del argv[i]
            return arg
        i += 1
```

这个过程就是解析命令行，例如执行 `scrapy crawl <spider_name>`，这个方法会解析出 `crawl`，通过上面生成好的命令类的字典集合，就能找到 `commands` 目录下的 `crawl.py`文件，最终执行的就是它的 `Command` 类。

# 解析命令行参数

找到对应的命令实例后，调用 `cmd.process_options` 方法解析我们的参数：

```python
def process_options(self, args, opts):
    # 首先调用了父类的process_options 解析统一固定的参数
    ScrapyCommand.process_options(self, args, opts)
    try:
        # 命令行参数转为字典
        opts.spargs = arglist_to_dict(opts.spargs)
    except ValueError:
        raise UsageError("Invalid -a value, use -a NAME=VALUE", print_help=False)
    if opts.output:
        if opts.output == '-':
            self.settings.set('FEED_URI', 'stdout:', priority='cmdline')
        else:
            self.settings.set('FEED_URI', opts.output, priority='cmdline')
        feed_exporters = without_none_values(
            self.settings.getwithbase('FEED_EXPORTERS'))
        valid_output_formats = feed_exporters.keys()
        if not opts.output_format:
            opts.output_format = os.path.splitext(opts.output)[1].replace(".", "")
        if opts.output_format not in valid_output_formats:
            raise UsageError("Unrecognized output format '%s', set one"
                             " using the '-t' switch or as a file extension"
                             " from the supported list %s" % (opts.output_format,
                                                              		tuple(valid_output_formats)))
        self.settings.set('FEED_FORMAT', opts.output_format, priority='cmdline')
```

这个过程就是解析命令行其余的参数，**固定参数**解析交给**父类**处理，例如输出位置等。其余不同的参数由不同的命令类解析。

# 初始化CrawlerProcess

一切准备就绪，最后初始化 `CrawlerProcess` 实例，然后运行对应命令实例的 `run` 方法。

```python
cmd.crawler_process = CrawlerProcess(settings)
_run_print_help(parser, _run_command, cmd, args, opts)
```

我们开始运行一个爬虫一般使用的是 `scrapy crawl <spider_name>`，也就是说最终调用的是 `commands/crawl.py` 的 `run` 方法：

```python
def run(self, args, opts):
    if len(args) < 1:
        raise UsageError()
    elif len(args) > 1:
        raise UsageError("running 'scrapy crawl' with more than one spider is no longer supported")
    spname = args[0]

    self.crawler_process.crawl(spname, **opts.spargs)
    self.crawler_process.start()
```

`run` 方法中调用了 `CrawlerProcess` 实例的 `crawl` 和 `start` 方法，就这样整个爬虫程序就会运行起来了。

我们先来看`CrawlerProcess`初始化：

```python
class CrawlerProcess(CrawlerRunner):
    def __init__(self, settings=None):
        # 调用父类初始化
        super(CrawlerProcess, self).__init__(settings)
        # 信号和log初始化
        install_shutdown_handlers(self._signal_shutdown)
        configure_logging(self.settings)
        log_scrapy_info(self.settings)
```

其中，构造方法中调用了父类 `CrawlerRunner` 的构造方法：

```python
class CrawlerRunner(object):
    def __init__(self, settings=None):
        if isinstance(settings, dict) or settings is None:
            settings = Settings(settings)
        self.settings = settings
        # 获取爬虫加载器
        self.spider_loader = _get_spider_loader(settings)
        self._crawlers = set()
        self._active = set()
```

初始化时，调用了 `_get_spider_loader`方法：

```python
def _get_spider_loader(settings):
    # 读取配置文件中的SPIDER_MANAGER_CLASS配置项
    if settings.get('SPIDER_MANAGER_CLASS'):
        warnings.warn(
            'SPIDER_MANAGER_CLASS option is deprecated. '
            'Please use SPIDER_LOADER_CLASS.',
            category=ScrapyDeprecationWarning, stacklevel=2
        )
    cls_path = settings.get('SPIDER_MANAGER_CLASS',
                            settings.get('SPIDER_LOADER_CLASS'))
    loader_cls = load_object(cls_path)
    try:
        verifyClass(ISpiderLoader, loader_cls)
    except DoesNotImplement:
        warnings.warn(
            'SPIDER_LOADER_CLASS (previously named SPIDER_MANAGER_CLASS) does '
            'not fully implement scrapy.interfaces.ISpiderLoader interface. '
            'Please add all missing methods to avoid unexpected runtime errors.',
            category=ScrapyDeprecationWarning, stacklevel=2
        )
    return loader_cls.from_settings(settings.frozencopy())
```

这里会读取默认配置文件中的 `spider_loader`项，默认配置是 `spiderloader.SpiderLoader`类，从名字我们也能看出来，这个类是用来加载我们编写好的爬虫类的，下面看一下这个类的具体实现。

```python
@implementer(ISpiderLoader)
class SpiderLoader(object):
    def __init__(self, settings):
        # 配置文件获取存放爬虫脚本的路径
        self.spider_modules = settings.getlist('SPIDER_MODULES')
        self._spiders = {}
        # 加载所有爬虫
        self._load_all_spiders()

    def _load_spiders(self, module):
        # 组装成{spider_name: spider_cls}的字典
        for spcls in iter_spider_classes(module):
            self._spiders[spcls.name] = spcls

    def _load_all_spiders(self):
        for name in self.spider_modules:
            for module in walk_modules(name):
                self._load_spiders(module)
```

可以看到，在这里爬虫加载器会加载所有的爬虫脚本，最后生成一个 `{spider_name: spider_cls}` 的字典，所以我们在执行 `scarpy crawl <spider_name>` 时，Scrapy 就能找到我们的爬虫类。

# 运行爬虫

`CrawlerProcess` 初始化完之后，调用它的 `crawl` 方法：

```python
def crawl(self, crawler_or_spidercls, *args, **kwargs):
    # 创建crawler
    crawler = self.create_crawler(crawler_or_spidercls)
    return self._crawl(crawler, *args, **kwargs)

def _crawl(self, crawler, *args, **kwargs):
    self.crawlers.add(crawler)
    # 调用Crawler的crawl方法
    d = crawler.crawl(*args, **kwargs)
    self._active.add(d)

    def _done(result):
        self.crawlers.discard(crawler)
        self._active.discard(d)
        return result
    return d.addBoth(_done)

def create_crawler(self, crawler_or_spidercls):
    if isinstance(crawler_or_spidercls, Crawler):
        return crawler_or_spidercls
    return self._create_crawler(crawler_or_spidercls)

def _create_crawler(self, spidercls):
    # 如果是字符串 则从spider_loader中加载这个爬虫类
    if isinstance(spidercls, six.string_types):
        spidercls = self.spider_loader.load(spidercls)
    # 否则创建Crawler
    return Crawler(spidercls, self.settings)
```

这个过程会创建 `Cralwer` 实例，然后调用它的 `crawl` 方法：

```python
@defer.inlineCallbacks
def crawl(self, *args, **kwargs):
    assert not self.crawling, "Crawling already taking place"
    self.crawling = True

    try:
        # 到现在 才是实例化一个爬虫实例
        self.spider = self._create_spider(*args, **kwargs)
        # 创建引擎
        self.engine = self._create_engine()
        # 调用爬虫类的start_requests方法
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

def _create_spider(self, *args, **kwargs):
    return self.spidercls.from_crawler(self, *args, **kwargs)
```

到这里，才会对我们的爬虫类创建一个实例对象，然后创建引擎，之后调用爬虫类的 `start_requests` 方法获取种子 URL，最后交给引擎执行。

最后来看 `Cralwer` 是如何开始运行的额，也就是它的 `start` 方法：

```python
def start(self, stop_after_crawl=True):
    if stop_after_crawl:
        d = self.join()
        if d.called:
            return
        d.addBoth(self._stop_reactor)
    reactor.installResolver(self._get_dns_resolver())
    # 配置reactor的池子大小(可修改REACTOR_THREADPOOL_MAXSIZE调整)
    tp = reactor.getThreadPool()
    tp.adjustPoolsize(maxthreads=self.settings.getint('REACTOR_THREADPOOL_MAXSIZE'))
    reactor.addSystemEventTrigger('before', 'shutdown', self.stop)
    # 开始执行
    reactor.run(installSignalHandlers=False)
```

在这里有一个叫做 `reactor` 的模块。`reactor` 是个什么东西呢？它是 `Twisted` 模块的事件管理器，我们只要把需要执行的事件注册到 `reactor` 中，然后调用它的 `run` 方法，它就会帮我们执行注册好的事件，如果遇到网络IO等待，它会自动帮切换到可执行的事件上，非常高效。

在这里我们不用深究 `reactor` 是如何工作的，你可以把它想象成一个线程池，只是采用注册回调的方式来执行事件。

到这里，Scrapy 运行的入口就分析完了，之后爬虫的调度逻辑就交由引擎 `ExecuteEngine` 处理了，引擎会协调多个组件，相互配合完成整个任务的执行。

# 总结

总结一下，Scrapy 在真正运行前，需要做的工作包括配置环境初始化、命令类的加载、爬虫模块的加载，以及命令类和参数解析，之后运行我们的爬虫类，最终，这个爬虫类的调度交给引擎处理。

这里我把整个流程也总结成了思维导图，方便你理解：

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1478618222.png" />

好了，Scrapy 是如何运行的代码剖析就先分析到这里，下篇文章我们会深入剖析各个核心组件，分析它们都是负责做什么工作的，以及它们之间又是如何协调完成抓取任务的，敬请期待。

附：

- [Scrapy源码分析（一）架构概览](http://kaito-kidd.com/2016/11/01/scrapy-code-analyze-architecture/)
- Scrapy源码分析（二）运行入口
- [Scrapy源码分析（三）核心组件初始化](http://kaito-kidd.com/2016/11/21/scrapy-code-analyze-component-initialization/)
- [Scrapy源码分析（四）核心抓取流程](http://kaito-kidd.com/2016/12/07/scrapy-code-analyze-core-process/)

