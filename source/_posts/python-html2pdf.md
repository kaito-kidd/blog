title: "python wkhtmltopdf使用与注意事项"
date: 2015-03-12 00:38:06
categories: Python
tags: [python]
---

> Python  `HTML` 导出 `PDF` 用到 `pdfkit` + `wkhtmltopdf`

说明：

	wkhtmltopdf主要用于HTML生成PDF

	pdfkit是基于wkhtmltopdf的python封装，其最终还是调用wkhtmltopdf命令



1、下载并安装：
	
	wkhtmltox-0.12.1_linux-centos6-amd64.rpm

2、安装pdfkit：
	
	pip install pdfkit

3、使用，参考：https://pypi.python.org/pypi/pdfkit/0.4.1

	import pdfkit

	pdfkit.from_url('http://google.com', 'out.pdf')
	pdfkit.from_file('test.html', 'out.pdf')
	pdfkit.from_string('Hello!', 'out.pdf')

<!-- more -->

详细说明：

    需安装模块： 1. wkhtmltopdf, 2. pdfkit

    导PDF使用的是wkhtmltopdf，需安装rpm (wkhtmltox-0.12.1_linux-centos6-amd64.rpm)
    安装完成后可用命令生成PDF，例如：wkhtmltopdf http://www.google.com.hk google.pdf

    pdfkit是python对wkhtmltopdf调用的封装,支持URL，本地文件，文本内容到PDF的转换

    实际转换还是最终调用wkhtmltopdf命令
    
    中文乱码说明：
        1、保证网页编码为UTF-8，GBK、GB2312网上说好像支持不太好，我未测试；
        2、如果导出是乱码，注意不是方框方框，则是网页编码问题；
        3、如果导出是方框方框，表示服务器未安装中文字体，安装字体即可，安装下面说明；

    安装中文字体：
        0、查看目前安装字体：fc-list
        1、下载所需字体,例如msyh.ttf
        2、mkdir /usr/share/fonts/zh_CN
        3、mv msyh.ttf /usr/share/fonts/zh_CN
        4、执行fc-cache -fv
        5、查看是否安装成功：fc-list，查看是已安装


