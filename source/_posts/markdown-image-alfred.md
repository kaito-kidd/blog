title: "Markdown快速插入图片工具"
date: 2016-10-19 21:53:31
tags: [利器, 工具, 效率, alfred]
---

# 背景

不知道大家在用Markdown语法写博客时有没有遇到这样的问题？想使用Markdown语法插入一张图，大概要经过以下几个步骤：

- 截图保存图片到本地
- 打开并登陆注册好的图床网站
- 上传图片至图床
- 复制生成好的图片地址
- 用Markdown语法插入图片

如果插入图片过多，这样来回操作多次，简直要崩溃！经过网上搜索，貌似有2种解决方案：

- 付费购买此类软件
- 自己写一个小工具，简化工作

我当然是属于第二种，想一想这个功能也不复杂，参考了有人已经实现出来的代码和思路，但是不忍其代码写的太渣太low，便自己造了这个轮子。

# 功能

先来看效果图：

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/fast-upload-img-animation.gif" width="1188" height="490" />

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/screenshot-upload-image-animation.gif" width="1188" height="490" />

**主要功能就是：复制本地图片或截图，快速上传图片至七牛云空间，并获取Markdown格式的图片地址。**

<!-- more -->

此工具是由Python编写的Alfred插件。

## 依赖

- 七牛图床（注册方式见官网）
- Mac平台
- 付费版Alfred

## 功能特点

- 支持复制本地图片获取图片链接
- 支持截图获取图片图片链接
- 支持gif格式
- 操作结果会在通知栏显示

## 如何使用

- 下载`alfredworkflow`插件，双击安装即可（点击[这里](https://github.com/kaito-kidd/markdown-image-alfred/releases/download/1.1.1/markdown-image.alfredworkflow)下载）
- 复制本地一张图片(格式为：jpg、png、gif)，或截一张图
- 打开任意编辑器，按下`option + command + v`快捷键
- 自动插入上传后的图片链接

## 说明

第一次操作：**需设置七牛的相关参数，按下快捷键后，会自动打开配置文件，填入配置即可**。

说明：插入的图片链接不是标准的Markdown格式，而是`img`标签。由于在retina屏幕下截图后，在非retina屏幕下图片会非常大，很难看，所以使用`img`标签的属性保证图片的大小和质量。

如果想改变格式，可以参考我的代码实现：[github项目地址](https://github.com/kaito-kidd/markdown-image-alfred)

有了这个工具后，不管插入多少图片，都是一键化操作，大大简化了之前的插入流程，这样就能专注内容，提高产出。

