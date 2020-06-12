title: "Mac效率利器（二）开发篇"
date: 2016-09-26 22:30:50
tags: [利器, 工具, 效率]
---

> 上一篇文章，主要推荐了Mac上系统管理相关的效率利器：[Mac效率利器（一）系统管理篇](http://kaito-kidd.com/2016/09/13/Mac-edge-tools-system)，今天这篇文章主要推荐下Mac平台与开发相关的效率利器。

# iTerm2

如果是服务端开发，自然少不了终端工具，iTerm2算是Mac平台的王牌终端工具，它增强了普通终端，提供了开发中很常用的功能，例如分屏、检索高亮、命令自动补全、选中自动复制、剪贴板历史、终端主题等强大功能。总之，用上了iTerm2，在开发中能达到事半功倍的效果。

## 会话分屏

`command + d`(水平分割)、`command + shift + d`(垂直分割)：

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1474881929.png" width="1482" height="1018" />

## 检索高亮

`command + f`，按`Tab`自动补全，然后按`option + 回车`自动粘贴：

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1474882035.png" width="1062" height="975" />

## 命令自动补全

快捷键：`command + ;`：

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1474885255.png" width="950" height="388" />

## 剪贴板历史

快捷键：`command + shift + h`：

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1474885284.png" width="949" height="488" />

## 主题配置

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1474884157.png" width="1030" height="549" />

# Dash

在写代码时，肯定少不了查文档，打开官方网站，找到Document，然后搜索关键字，之后打开N个网页，不但网页越开越多，而且每次这个流程大部分都是重复的工作。

`Dash`很好的把这些工作集成在一起，只需打开`Dash`，搜索关键字即可，`Dash`提供了非常多官方文档，例如：JQuery、CSS、HTML、Python、Git、Java，在工具中直接下载即可。没有收录到`Dash`的文档，自己也可以制作导入。

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1474885786.png" width="820" height="690" />

## 模糊检索

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1474885827.png" width="1388" height="889" />

## 代码片段

`Dash`除了支持管理、搜索文档之外，还提供了代码片段的收录存储。

例如，我先定义了一段代码片段，然后定义别名为`hello`：

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1474886595.png" width="924" height="620" />

当我在开发工具中输入`hello`后，就会出现：

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1474886531.png" width="300" height="113" />

最重要的是，代码片段中可以预留**占位符**，然后在用的时候再进行填充。这个`__name__`就是代码片段中预留的占位符，在使用的时候，就可以自定义填充内容。

`Dash`还与其他很多开发工具和软件友好集成，例如`Alfred`：

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1474886095.png" width="593" height="517" />

<!-- more -->

# Chrome

浏览器我只用Chrome和Safari，但更多还是用Chrome，书签、插件实时同步，太方便了。

这里介绍下平时用的比较多的插件。

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1474897180.png" width="907" height="930" />

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1474897205.png" width="898" height="850" />

## Adblock Plus

广告过滤插件，自从用上它，再也看不到页面上弹的各种广告，世界一下就清净了。

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1474896597.png" width="257" height="408" />

## Anything to QRcode

一键生成网页的二维码：

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1474897358.png" width="2488" height="1462" />

## Full Page Screen Capture

一键快照当前整个网页，解决了截屏不能截整个网页的烦恼：

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1474897661.png" width="2784" height="1778" />

## Vimium

Vimium提供了使用`Vim`的方式操作网页，例如`j/k`分别代表网页的上下滚动，快捷键`f`可以提取出当前可点击的链接，并分配对应的快捷键，彻底脱离鼠标。

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1474897975.png" width="2784" height="1778" />

## SwitchyOmega

Chrome浏览器代理插件，科学上网必备。除此之外，在访问线上服务器的时可配置不同的代理进行访问，非常方便！

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1474898024.png" width="1878" height="544" />

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1474898057.png" width="1882" height="734" />

## JSONView

格式化`json`格式的数据，方便调试接口数据。

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1474898147.png" width="2442" height="760" />

## LastPass

注册了太多的网站，每次输入账号和密码都很繁琐。LastPass不仅能管理账号密码，还能自动根据不同的网站自动填充账号密码，非常方便，从此再也不用记那么多密码了。

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1474897932.png" width="2552" height="986" />

## Octotree

Github看代码的时候，每次点开文件，只能后退再打开其他文件，操作很繁琐。

这个插件提高了代码目录以树形结构展示，大大方便了查看代码和跳转文件的便捷性。

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1474898250.png" width="2784" height="1778" />

# Gliffy Diagrams

在编写程序的同时，肯定避免不了要画架构图、流程图，这个插件非常的简洁、轻量，基本能满足大多数画图的要求。

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1474899692.png" width="2784" height="1778" />

Gliffy还可以画流程图、时序图，简洁实用，上手简单。

# XMind

当然，使用思维导图也能画图很多漂亮的图形，XMind可与Gliffy相互补充，各司其职。

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1474900266.png" width="2784" height="1778" />

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1474900358.png" width="2784" height="1778" />

# Sequel Pro

自认为是Mac平台下的最好用的MySQL图形界面工具，功能强大，操作友好。

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1474900992.png" width="2776" height="1778" />

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1474900951.png" width="2720" height="1722" />

# Typora

程序员当然少不了写文档，这里推荐Typora，一款markdown文档编辑器。

它与其他markdown编辑器不同，Typora是一款所写即所得的实时转换编辑器，即在你写下`# 标题一`或`**加粗文字**`后，按下回车，随即这些效果就会实时显示出来，不需要两栏来展示源代码和预览，它把源码编写和预览在一个栏目中实时的反馈出来。

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1474901500.png" width="1206" height="913" />

> 本篇文章主要介绍了与开发相关的效率利器，主要围绕开发、画图、文档这些在工作中可以用来提升效率的利器进行了介绍和推荐，如果你也在找这些利器，不妨一试？

附：
- [Mac效率利器（一）系统管理篇](http://kaito-kidd.com/2016/09/13/Mac-edge-tools-system/)
- [Mac效率利器（三）辅助篇](http://kaito-kidd.com/2016/10/09/Mac-edge-tools-assist/)

