title: "Scrapy源码分析（二）运行入口"
date: 2016-11-09 20:35:31
tags: [爬虫, scrapy]
---

> 在上篇文章中：[Scrapy源码分析（一）架构概览](http://kaito-kidd.com/2016/11/01/scrapy-code-analyze-architecture/)，主要从整体介绍了Scrapy架构和数据流转，这篇文章从运行开始来分析，来看一下Scrapy是如何运行起来的。

# scrapy命令

当用scrapy写好一个爬虫后，使用`scrapy crawl <spider_name>`命令就可以运行这个爬虫，那么这个过程中到底发生了什么？

`scrapy`命令从何而来？

实际上，当你成功安装scrapy后，使用如下命令，就能找到这个命令：

```
$ which scrapy
/usr/local/bin/scrapy
```

使用`vim`或其他编辑器打开它：

```shell
$ vim /usr/local/bin/scrapy
```

其实它就是一个python脚本，而且代码非常少。

```python
#!/usr/bin/python

# -*- coding: utf-8 -*-
import re
import sys

from scrapy.cmdline import execute

if __name__ == '__main__':
    sys.argv[0] = re.sub(r'(-script\.pyw|\.exe)?$', '', sys.argv[0])
    sys.exit(execute())
```

安装scrapy后，为什么入口点是这里呢？

原因是在scrapy的安装文件`setup.py`中，声明了程序的入口处：

```python
from os.path import dirname, join
from setuptools import setup, find_packages

with open(join(dirname(__file__), 'scrapy/VERSION'), 'rb') as f:
    version = f.read().decode('ascii').strip()

setup(
    name='Scrapy',
    version=version,
    url='http://scrapy.org',
    description='A high-level Web Crawling and Screen Scraping framework',
    long_description=open('README.rst').read(),
    author='Scrapy developers',
    maintainer='Pablo Hoffman',
    maintainer_email='pablo@pablohoffman.com',
    license='BSD',
    packages=find_packages(exclude=('tests', 'tests.*')),
    include_package_data=True,
    zip_safe=False,
    entry_points={
        'console_scripts': ['scrapy = scrapy.cmdline:execute']
    },
    classifiers=[
        'Framework :: Scrapy',
        'Development Status :: 5 - Production/Stable',
        'Environment :: Console',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: BSD License',
        'Operating System :: OS Independent',
        'Programming Language :: Python',
        'Programming Language :: Python :: 2',
        'Programming Language :: Python :: 2.7',
        'Topic :: Internet :: WWW/HTTP',
        'Topic :: Software Development :: Libraries :: Application Frameworks',
        'Topic :: Software Development :: Libraries :: Python Modules',
    ],
    install_requires=[
        'Twisted>=10.0.0',
        'w3lib>=1.8.0',
        'queuelib',
        'lxml',
        'pyOpenSSL',
        'cssselect>=0.9',
        'six>=1.5.2',
    ],
)
```

`entry_points`指明了入口是`cmdline.py`的`execute`方法，在安装过程中，`setuptools`这个包管理工具，就会把上述那一段代码生成放在可执行路径下。

这里也有必要说一下，如何用python编写一个可执行文件，其实非常简单，只需要以下几步即可完成：

- 编写一个带有`main`方法的python模块（首行必须注明python执行路径）
- 去掉`.py`后缀名
- 修改权限为可执行：`chmod +x`脚本

这样，你就可以直接使用**文件名**执行此脚本了，而不用通过`python <file.py>`的方式去执行，是不是很简单？

# 入口(execute.py)

既然现在已经知道了scrapy的入口是`scrapy/cmdline.py`的`execute`方法，我们来看一下这个方法。

```python
def execute(argv=None, settings=None):
    if argv is None:
        argv = sys.argv

    # --- 兼容之前scrapy.conf.settings的配置 ---
    if settings is None and 'scrapy.conf' in sys.modules:
        from scrapy import conf
        if hasattr(conf, 'settings'):
            settings = conf.settings
    # ------------------------------------------------------------------

	# 初始化环境、获取项目配置参数，返回settings对象
    if settings is None:
        settings = get_project_settings()
    # 校验弃用的配置项
    check_deprecated_settings(settings)

    # --- 兼容之前scrapy.conf.settings的配置 ---
    import warnings
    from scrapy.exceptions import ScrapyDeprecationWarning
    with warnings.catch_warnings():
        warnings.simplefilter("ignore", ScrapyDeprecationWarning)
        from scrapy import conf
        conf.settings = settings
    # ------------------------------------------------------------------

    # 执行环境是否在项目中，主要检查scrapy.cfg配置文件是否存在
    inproject = inside_project()
    # 读取commands文件夹，把所有的命令类转换为{cmd_name: cmd_instance}的字典
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

    # 初始化CrawlerProcess实例，并给命令实例添加crawler_process属性
    cmd.crawler_process = CrawlerProcess(settings)
    # 执行命令实例的run方法
    _run_print_help(parser, _run_command, cmd, args, opts)
    sys.exit(cmd.exitcode)
```
主要的运行流程已经加好注释，这里我总结出了每个流程执行过程：

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1478618222.png" width="1375" height="814" />

下面会对每个流程进行分析讲解。

<!-- more -->

# 流程解析

## 初始化项目配置

这个流程比较简单，主要是根据环境变量和`scrapy.cfg`初始化环境，最终生成一个`Settings`实例，来看代码`get_project_settings`方法：

```python
def get_project_settings():
    # 环境变量中是否有SCRAPY_SETTINGS_MODULE配置
    if ENVVAR not in os.environ:
        project = os.environ.get('SCRAPY_PROJECT', 'default')
        # 初始化环境,找到用户配置文件settings.py,设置到环境变量SCRAPY_SETTINGS_MODULE中
        init_env(project)
    # 加载默认配置文件default_settings.py，生成settings实例
    settings = Settings()
    # 取得用户配置文件
    settings_module_path = os.environ.get(ENVVAR)
    # 更新配置，用户配置覆盖默认配置
    if settings_module_path:
        settings.setmodule(settings_module_path, priority='project')
	# 如果环境变量中有其他scrapy相关配置则覆盖
    pickled_settings = os.environ.get("SCRAPY_PICKLED_SETTINGS_TO_OVERRIDE")
    if pickled_settings:
        settings.setdict(pickle.loads(pickled_settings), priority='project')
    env_overrides = {k[7:]: v for k, v in os.environ.items() if
                     k.startswith('SCRAPY_')}
    if env_overrides:
        settings.setdict(env_overrides, priority='project')
    return settings
```

这个过程中进行了`Settings`配置初始化：

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

程序加载默认配置文件`default_settings.py`中的所有配置项设置到`Settings`中，且这个配置是有优先级的。

这个默认配置文件`default_settings.py`是非常重要的，个人认为还是有必要看一下里面的内容，这里包含了所有默认的配置，例如调度器类、爬虫中间件类、下载器中间件类、下载处理器类等等。

在这里就能隐约发现，scrapy的架构是非常低耦合的，所有组件都是可替换的，什么是可替换呢？

例如，你觉得默认的调度器功能不够用，那么你就可以按照它定义的接口标准，自己实现一个调度器，然后在自己的配置文件中，注册自己写的调度器模块，那么scrapy的运行时就会用上你新写的调度器模块了！

只要在默认配置文件中配置的模块，都是可替换的。

## 检查环境是否在项目中

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
	# 如果环境变量没有，就近查找scrapy.cfg，找得到就认为是在项目环境中
    return bool(closest_scrapy_cfg())
```

scrapy命令有的是依赖项目运行的，有的命令则是全局的，不依赖项目的。这里主要通过就近查找`scrapy.cfg`文件来确定是否在项目环境中。

## 获取可用命令并组装成名称与实例的字典

```python
def _get_commands_dict(settings, inproject):
    # 导入commands文件夹下的所有模块，生成{cmd_name: cmd}的字典集合
    cmds = _get_commands_from_module('scrapy.commands', inproject)
    cmds.update(_get_commands_from_entry_points(inproject))
    # 如果用户自定义配置文件中有COMMANDS_MODULE配置，则加载自定义的命令类
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
    # 迭代这个包下的所有模块，找到ScrapyCommand的子类
    for module in walk_modules(module_name):
        for obj in vars(module).values():
            if inspect.isclass(obj) and \
                    issubclass(obj, ScrapyCommand) and \
                    obj.__module__ == module.__name__:
                yield obj
```

这个过程主要是，导入`commands`文件夹下的所有模块，生成`{cmd_name: cmd}`字典集合，如果用户在配置文件中配置了自定义的命令类，也追加进去。也就是说，自己也可以**编写自己的命令类**，然后追加到配置文件中，之后就可以使用自己自定义的命令了。

## 解析执行的命令并找到对应的命令实例

```python
def _pop_command_name(argv):
    i = 0
    for arg in argv[1:]:
        if not arg.startswith('-'):
            del argv[i]
            return arg
        i += 1
```

这个过程就是解析命令行，例如`scrapy crawl <spider_name>`，解析出`crawl`，通过上面生成好的命令字典集合，就能找到`commands`模块下的`crawl.py`下的`Command`类的实例。

## scrapy命令实例解析命令行参数

找到对应的命令实例后，调用`cmd.process_options`方法：

```python
    def process_options(self, args, opts):
        # 首先调用了父类的process_options,解析统一固定的参数
        ScrapyCommand.process_options(self, args, opts)
        try:
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

## 初始化CrawlerProcess

最后初始化`CrawlerProcess`实例，然后运行对应命令实例的`run`方法。

```python
    cmd.crawler_process = CrawlerProcess(settings)
    _run_print_help(parser, _run_command, cmd, args, opts)
```

如果运行命令是`scrapy crawl <spider_name>`，则运行的就是`commands/crawl.py`的`run`：

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

`run`方法中调用了`CrawlerProcess`实例的`crawl`和`start`，就这样整个爬虫程序就会运行起来了。

先来看`CrawlerProcess`初始化：

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

构造方法中调用了父类`CrawlerRunner`的构造：

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

默认配置文件中的`spider_loader`配置是`spiderloader.SpiderLoader`：

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

爬虫加载器会加载所有的爬虫脚本，最后生成一个`{spider_name: spider_cls}`的字典。

## 执行crawl和start方法

`CrawlerProcess`初始化完之后，调用`crawl`方法：

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
        # 如果是字符串,则从spider_loader中加载这个爬虫类
        if isinstance(spidercls, six.string_types):
            spidercls = self.spider_loader.load(spidercls)
        # 否则创建Crawler
        return Crawler(spidercls, self.settings)
```

这个过程会创建`Cralwer`实例，然后调用它的`crawl`方法：

```python
    @defer.inlineCallbacks
    def crawl(self, *args, **kwargs):
        assert not self.crawling, "Crawling already taking place"
        self.crawling = True

        try:
            # 到现在，才是实例化一个爬虫实例
            self.spider = self._create_spider(*args, **kwargs)
            # 创建引擎
            self.engine = self._create_engine()
            # 调用爬虫类的start_requests方法
            start_requests = iter(self.spider.start_requests())
            # 执行引擎的open_spider，并传入爬虫实例和初始请求
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

最后调用`start`方法：

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

`reactor`是个什么东西呢？它是`Twisted`模块的事件管理器，只要把需要执行的事件方法注册到`reactor`中，然后调用它的`run`方法，它就会帮你执行注册好的事件方法，如果遇到网络IO等待，它会自动帮你切换可执行的事件方法，非常高效。

大家不用在意`reactor`是如何工作的，你可以把它想象成一个线程池，只是采用注册回调的方式来执行事件。

到这里，爬虫的之后调度逻辑就交由引擎`ExecuteEngine`处理了。

> 在每次执行scrapy命令时，主要经过环境、配置初始化，加载命令类和爬虫模块，最终实例化执行引擎，交给引擎调度处理的流程，下篇文章会讲解执行引擎是如何调度和管理各个组件工作的。

附：

- [Scrapy源码分析（一）架构概览](http://kaito-kidd.com/2016/11/01/scrapy-code-analyze-architecture/)
- Scrapy源码分析（二）运行入口
- [Scrapy源码分析（三）核心组件初始化](http://kaito-kidd.com/2016/11/21/scrapy-code-analyze-component-initialization/)
- [Scrapy源码分析（四）核心抓取流程](http://kaito-kidd.com/2016/12/07/scrapy-code-analyze-core-process/)

