title: "从最基础开始配置VIM"
date: 2015-03-11 23:39:06
tags: [vim]
---

> 本文主要介绍了从最基础配置属于自己的`VIM`。
> 主要分为：1、基础配置，2、插件管理。
> 可以参考[我的vim配置](https://github.com/kaito-kidd/kaito-vim)。

## ~/.vimrc基础配置

	syntax on                   "语法高亮

	" 加载插件
	so ~/.vim/bundles.vim		在下面有说明
	
	set fileencodings=utf-8,gbk
	set backspace=indent,eol,start
	set tabstop=4               "tab为4个空格
	set number                  "显示行号
	set hlsearch                "开启搜索高亮  
	set incsearch               "输入搜索字符串的同时进行搜索  
	"set ignorecase              "搜索时忽略大小写  
	set ruler                   "开启光标位置提示
	set cmdheight=1             "命令部分高度为1
	"set autoindent              "自动缩进 
	set showmatch               "显示匹配的括号 
	"set smartindent             "智能缩进
	set smarttab
	set expandtab
	set shiftwidth=4            " 设定 << 和 >> 命令移动时的宽度为 4
	set softtabstop=4           " 使得按退格键时可以一次删掉 4 个空格
	set laststatus=2            " 显示状态栏 (默认值为 1, 无法显示状态栏)
	
	" Set leader，必须加上以下此项,后面插件会用到
	let mapleader = "," 
	let g:mapleader = "," 
	
<!-- more -->

## 安装插件


### 插件管理器Vundle

安装

	git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle

	看到~/.vim/bundle/vundle存在即安装成功

配置Vundle，创建`~/.vim/bundles.vim`，内容如下（类似于一个模板）：

	set nocompatible                " be iMproved
	filetype off                    " required!
		
	set rtp+=~/.vim/bundle/vundle/
	call vundle#rc()
		
	" 注意：让Vundle管理插件，必须有这一行配置
	Bundle 'gmarik/vundle'

	" 插件主要分为三大类：
	" 1、Github vim-scripts 用户下的repos,只需要写repos名称
	"Bundle 'xxx'
		
	" 2、在Github其他用户下的repos,写出'用户名/repo名'
	"Bundle 'xxx/xxx'

	" 3、不在Github上的插件，需要写出git全路径,例如：
	" Bundle 'git://git.xxxx.com/others.git'
		
	filetype plugin indent on     " required!

管理插件命令：

	安装插件：:BundleInstall
	
	更新插件：BundleUpdate

	清除不再使用的插件：BundleClean(需先在插件配置文件注释此插件名称)

	列出所有插件：BundleList

	查找插件：BundleSearch

> 下面举几个例子来说明插件的安装与使用。

### 安装The-NERD-tree插件(树状目录)

在~/.vim/bundles.vim的`vim-scripts`下添加：

	Bundle 'The-NERD-tree'

保存退出，打开vim执行如下命令：

	:BundleInstall
完成后会看到~/.vim/bundle/vundle下有此插件目录即成功。

配置：在`.vimrc`加入以下命令，表示快速启动该插件，完成后在vim中使用快捷键 `, + e` 即可打开/关闭此插件：

	" 快速打开插件（在上面基础配置中已经配置了<leader>快捷键）
	nnoremap <leader>e :NERDTreeToggle<cr>

	
### 安装syntastic插件(语法检测)

在~/.vim/bundles.vim的`name/repo`下添加：

	Bundle 'scrooloose/syntastic'

保存退出，打开vim执行如下命令，完成后会看到~/.vim/bundle/vundle下有此插件目录即成功：

	:BundleInstall

配置，在`.vimrc`加入以下命令，以后在VIM使用`F7`即检查代码格式：

	" 快速语法检测
	map <F7> :SyntasticCheck<cr>


### 同理，安装其他插件

方法同上：
- 在`bundles.vim`添加需要安装的插件名称；
- 执行`BundleInstall`安装；
- 在`vimrc`配置相关快捷键操作；




