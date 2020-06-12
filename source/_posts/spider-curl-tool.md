title: "爬虫工具之curl"
date: 2015-04-11 00:25:08
tags: [爬虫, curl]
---


> 解析页面肯定是写爬虫遇到的最常见的工作，但不要小看这个这个过程，有时它也会令你抓狂。这次写一下关于`curl`工具的使用，主要介绍一下平时很常用的几项。

> `curl`是利用`URL`语法在命令行方式下工作的开源文件传输工具，使用这个工具，就能在命令行发起请求，获得响应，而且其命令简单且强大，非常适合用作写爬虫时，解析页面前的模拟工作。

# 基础

	# 发起HTTP请求，并把返回的网页内容显示在屏幕
	curl "http://www.example.com"
	
	# 发起HTTP请求，并把返回的网页内容输出到文件
	curl "http://www.example.com" > test.html
	
	# 或者用命令-o参数也可达到同样的效果
	curl -o test.html "http://www.example.com"
	
**注意：URL地址带上双引号是比较好的习惯，防止URL中带有特殊符号，导致不能解析报错情况。**

# 伪装头信息

有时`curl`直接访问页面，会得到与浏览器打开不同的结果，所以此时就要伪装头信息，来模拟浏览器的行为，这样返回的数据就跟浏览器看到的一样了。

	# 使用-A参数定义User-Agent，模拟浏览器行为
	curl -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.118 Safari/537.36" "http://www.example.com"
	
	# 使用-e参数定义Referer，表示从哪个页面跳过来的，解决防盗链问题
	curl -e "http://www.example.com" "http://detail.example.com"

	# 或者使用-H参数自定义头信息，也可定义User-Agent、Referer、Content-Type等信息
	curl -H "my-header:xxxxx" "http://www.example.com"
	
# 代理访问

或者你用程序频繁访问某个网站，结果人家把你`IP`封禁了，这时就可以用`代理`来进行访问。

	# 使用-x参数使用代理访问
	curl -x "123.45.67.89:8102" "http://www.example.com"
	
<!-- more -->
	
# 自动跳转

有时访问某个网页，这个网页会返回`302`状态码，表示重定向某个页面，页面地址会写在头的`Location`中。如果是浏览器访问，则会自动跳转到指定页面并展示，同样用`curl`也可以完成这个工作。

	# 使用-L参数自动重定向
	curl -L "http://www.example.com"
	
# 显示响应头信息

如果想详细了解上述重定向的情况，可以使用`-i`参数显示响应头信息，也可以使用`-D`参数把响应头信息写入文件，用来更方便的观察响应数据中的其他信息，进行下一步分析解析。

	# 使用-i参数显示响应头信息和内容，使用-I则只显示头信息
	curl -i "http://www.example.com"
	
	# 使用-D参数把响应头信息写到文件中
	curl -D "http://www.example.com"
	
# POST访问

以上访问方式都是默认`GET`方式访问的，但很多页面都需要带有参数信息，所以`GET`方式访问只能将参数拼在`URL`后面，但其参数是有长度限制的，此时建议使用`POST`方式访问。

	# GET方式访问带有参数的页面
	curl "http://www.example.com?p1=a&p2=b&p3=c"
	
	# POST方式访问
	curl -d "p1=a&p2=b&p3=c" "http://www.example.com"

	# POST方式访问，参数带有中文或空格，将参数编码
	curl --data-urlencode "name=张三" --data-urlencode "date=April 1" "http://www.example.com"
	
以上方式就可以模拟一个`表单`提交了，使用最多的就是用来模拟登录。
	
# 文件上传

`curl`同样也支持文件上传操作，实际上也还是模拟了一个表单，等同于一个页面表单是这样的：`<form method="POST" enctype='multipart/form-data'>`。
  
	# 模拟表单上传文件
	curl -F uploadfile=@test.txt -F title=xxx "http://example.com/upload"
	
# Cookie

有时有些网站是需要根据`Cookie`来进行校验身份或状态的，这时只需发送服务端需要的值即可。

	# 发送Cookie，键值方式
	curl -b "name=xxx" "http://example.com/index"
	
	# 发送Cookie，读取cookie文件方式
	curl -b cookie.txt "http://example.com/index"

# 下载文件

同样`curl`也支持下载文件，可根据`-o`，`-O`参数来进行文件的下载，前提是`URL`对应的一个文件资源。

	# 类似第一个例子，把文件数据输出到指定文件中
	curl -o "test.jpg" "http://example.com/test.jpg"
	
	# 使用-O参数就不用指定文件名，默认是URL里的资源名称 
	curl -O "http://example.com/test.jpg"

	# 批量下载
	curl -O "http://example.com/test[1-10].jpg"
	
	
> 有了这些功能，就不用每次解析或调试页面都在代码里debug了。直接用这个工具在命令行中测试即可，基本上能模仿浏览器90%或更多。更详细的命令可参考<a href="http://baike.baidu.com/link?url=FkaB8_zagdr7hYrPW272shZnx_OHXK9dYNP8K8hVIVTAyHkSGB6DARVFdgJS3A3ixtzAetaZtYQQxXw3XSPJya#2" target="_blank">这里</a>。
	
	
	

