title: VPS搭建Shadowsocks代理服务
date: 2017-01-11 11:12:22
tags: [shadowsocks, 代理]
---

> 之前买的科学上网服务从不稳定到不可用，也没有通知一声，貌似跑路了，太没有职业道德，这年头只想稳定的上网真的这么难么？
>
> 还好，之前买过一台VPS，本想业余时间开发一些小东西，目前只部署了个爬虫在上面跑，这次先用它搭个梯子代理，至少自己动手，比别人的要稳定吧！

# 原理

首先说一下`shadowsocks`的工作原理，正常情况下，如果你想访问外面的世界，由于有GFW的存在，直连是访问不了的，但如果你有一台外面世界的VPS，而你可以直连到这台VPS上，那么就可以通过这台VPS搭一条通道，也就是所谓的梯子，来让我们间接的连通外面的世界。

说白了就是在这台VPS上自己搭建一个服务，可以使我们的请求数据包经过这个服务转发出去，然后将响应数据包再通过这个服务正常返回给我们，但是由于我们上网都会经过GFW，它会验证我们的数据包，如果是被屏蔽的域名或IP，则会拒绝访问。怎样才能跨越屏障呢？

那就是在发送请求数据给代理服务时，先进行加密，这样就能跨越GFW到达代理服务，代理服务再通过同样的算法解密数据包，然后转发到我们请求的网站，之后得到响应后再通过先加密后解密的方式返回到我们本机，这样就能实现与外部连通。所以我们需要**客户端**和**服务端**配合来完成，大致流程如下：

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1484119054.png" width="1457" height="371" />

明白了原理之后，我们怎样搭建这样一个服务呢？

`shadowsocks`就已经实现了这些东西，我们只需要经过配置就可以轻松完成这个服务。

<!-- more -->

# 安装依赖

这里主要介绍`Linux`系统服务器装过程，由于`Linux`系统已自带`Python`，我们只需要安装`shadowsocks`模块搭建代理服务就可以了。

安装`shadowscoks`：

- Debian / Ubuntu：

  ```shell
  # 安装shadowsocks依赖的加密库
  apt-get install python-m2crypto
  # 安装shadowsocks
  pip install shadowsocks
  ```

- CentOS：

  ```shell
  # 安装shadowsocks依赖的加密库
  yum install m2crypto
  # 安装pip
  yum install python-setuptools && easy_install pip
  # 安装shadowsocks
  pip install shadowsocks
  ```

- Windows：

  参考[这里](https://github.com/shadowsocks/shadowsocks/wiki/Install-Shadowsocks-Server-on-Windows)

# 服务端配置

安装完成后，然后进行服务端配置，例如端口、密码等信息。

创建配置文件`/etc/config.json`：

```json
{
    "server":"0.0.0.0",
    "server_port": 9988,
    "local_address": "127.0.0.1”,
    "local_port": 1080,
    "password": "your-password",
    "method": "aes-256-cfb"
}
```

各配置信息：

- server：服务端IP，填写你VPS的IP地址
- server_port：服务端监听端口
- local_address：客户端服务IP，一般写本机127.0.0.1
- local_port：客户端监听端口
- password：密码，服务端指定后，客户端连接需填写此密码
- method：传输数据的加密方式

这里指定了服务端的端口是9988，客户端的端口是1080，这个客户端端口最好不要修改，因为Mac的`shadowsocks`客户端不能修改端口，而默认指定就是1080端口。如果是Windows客户端则可以随意修改，自己指定即可。

# 启动/停止服务

- 后台启动：

```shell
ssserver -c /etc/config.json -d start --log-file /tmp/shadowsocks.log --pid-file /tmp/shadowsocks.pid
```

- -c：指定配置文件
- -d start：模式：启动
- —log-file：日志路径
- —pid-file：`pid`进程号文件

查看日志文件，如果显示`starting server at x.x.x.x:xxxx`即为启动成功。

- 停止服务：

```shell
ssserver -d stop --pid-file /tmp/shadowsocks.pid
```

# 配置防火墙

`shadowsocks`服务启动成功后，就会在配置的端口监听服务，客户端要想通过此端口访问，首先配置防火墙，打开端口访问，默认端口应该都是被关闭的。如何配置防火墙，请参考`iptables`文档，这里不再阐述。

# 客户端配置

服务端配置完成之后，就需要本地下载客户端来连接此服务了。

下载客户端：[http://sourceforge.net/projects/shadowsocksgui/files/dist/](http://sourceforge.net/projects/shadowsocksgui/files/dist/)

Mac和Windows平台请自行根据后缀名和日期下载最新版即可。

以为Mac客户端为例，打开客户端，找到`Servers`，打开配置：

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1484118589.png" width="628" height="437" />

按照上面服务端的配置，填写IP、端口、密码、加密方式，保存。

选择`Turn On`启动客户端即可：

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1484118706.png" width="257" height="359" />

试着访问google、twitter、youtube等网站，然后观察服务端的日志文件，看是否有请求进来，如果网站可以正常访问，且日志有访问记录，则说明配置正确，现在就可以愉快的科学上网了！

客户端默认是以`Auto Proxy Mode`方式启动的，也就是自动分流方式，没有被屏蔽的网站，还是走本机直连方式，只有被屏蔽的网站才会走`shadowsocks`代理访问。

你也可以选择`Global Mode`全局代理模式，即所有流量都走代理访问。当然还是推荐使用自动分流模式，这样保证访问速度的同时还可节省VPS的流量。

# 配合SwitchyOmega使用

其实到上面为止，你的本机已经可以正常访问外面的世界了。

但如果你在工作中，例如访问线上服务需要使用HTTP代理来访问，例如访问线上服务`http://192.168.3.22`，需要通过HTTP代理，而其他网站则不使用代理。那么你可能要用到`Chrome`的插件`SwitchyOmega` 来进行自动分流。

一般配置为，先建立一个`Proxy Profile`配置，名字叫`Online Proxy`（线上服务代理），配置HTTP代理的IP和端口，例如：

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1484122704.png" width="857" height="190" />

然后建立一个`Switch Profile`配置，名字叫`Auto Switch`（自动切换），然后匹配规则如果是访问线上服务器`192.168.3.22`的服务，则自动使用上面建立的`Online Proxy`规则：

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1484122974.png" width="1046" height="237" />

而默认使用的是`Direct`，意为本机直连，也就是说，如果没有匹配到上面的规则，则默认使用直连方式进行访问，不会走任何代理。

如果没有使用`shadowsocks`之前，按照上面的配置就可以访问线上服务和正常浏览网站了，但现在我们想访问外面的世界，按照上面`shadowsocks`的配置，然后使用`Chrome`还是无法访问的。问题就是因为我们配置了`SwitchyOmega`，默认匹配不到任何规则，则使用直连的方式访问网络的，不会经过我们配置的`shadowsocks`代理。

那么怎么才能使`Chrome`既能像之前那样可以访问线上服务，又可以通过代理服务访问被屏蔽的那些网站呢？

其实，在我们打开`shadowsocks`客户端时，只要代理配置正确，不管你是否开启代理服务（`Turn On`），都会在本机启动2个服务，监听2个端口：1080端口、8090端口，使用命令可以查看到：

```shell
# 查看1080端口
>> netstat -ant | grep 1080 | grep LISTEN
tcp4       0      0  *.1080                 *.*                    LISTEN

# 查看8090端口
>> netstat -ant | grep 8090 | grep LISTEN
tcp4       0      0  *.8090                 *.*                    LISTEN
```

这到底是什么情况？你可以仔细观察一下，就算你在客户端点击`Turn Off`，使用上面命令查看着2个端口还是存在的。如果你撤掉关掉了客户端，那么这2个端口服务将被关闭。

打开/关闭客户端发生了什么？

打开`shadowsocks`客户端，`shadowsocks`会在本机启动上面2个服务，关闭客户端同时停止这2个服务。

这2个服务的功能：

- 1080端口：提供`SOCKS v5`代理，真正的请求代理入口，本机通过此端口转发请求
- 8090端口：提供`PAC`服务，`shadowsocks`点击`Turn On`，会配置`PAC`地址到系统代理

`Turn On/Off`发生了什么？

在我们的系统配置中，找到`网络` -> `Wi-Fi` -> `高级`-> `代理` -> `自动代理配置`，你会看到URL配置会随着你`Turn On/Off`打开和关闭，然后填充配置/删除配置。

这个配置地址是：`http://127.0.0.1:8090/proxy.pac`，访问这个地址，你就会得到一个`proxy.pac`的文件，这个配置文件是用`JavaScript`编写的，而在第一行也会看到我们熟悉的代码：

```javascript
var proxy = "SOCKS5 127.0.0.1:1080; SOCKS 127.0.0.1:1080; DIRECT;";
```

后面的逻辑大致就是，配置了一系列的域名，还有一些逻辑判断，意思为，如果我们访问的域名能匹配到这一些列域名，则使用`SOCK5 127.0.0.1:1080`代理访问，否则直连访问，这个文件就是一个自动分流的逻辑。

也就是说，我们`Turn On/Off`也就是给系统加上了这个自动分流的逻辑，而这个代理入口，就是使用的1080端口这个服务！

得知此结论后，那我们的使用就很方便了，如果想通过代理访问，使用`SOCK5 127.0.0.1:1080`访问即可，如果想使用分流代理，使用`http://127.0.0.1:8090/proxy.pac`这个地址即可。

那么我们就可以在`SwitchyOmega`上再建一个`Proxy Profile`规则，叫做`Global Proxy`（全局代理），使用这个代理，就强制所有的请求都通过代理访问：

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1484125248.png" width="870" height="191" />

配置完成后，我们在使用`Chrome`时，在地址栏的右边，就可以通过点击`SwitchyOmega`按钮来手动切换使用哪个模式进行访问了。这样既可以访问线上服务，也可以切换到代理模式访问外面世界了！

到这里我们还是需要手动切换来达到我们想要的效果，那我们可不可以让这些模式自动切换呢？答案是可以的。

新建一个`PAC Profile`规则，叫做`Auto Shunt`（自动分流），配置上面的`PAC`地址：

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1484125504.png" width="755" height="163" />

配置完成后，切换到之前配置好的`Auto Switch`（自动切换模式）规则，把`Default`选择为刚才配置好的`Auto Shunt`模式即可，最后配置如下：

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1484125619.png" width="1065" height="237" />

最后选择使用`Auto Switch`模式：

<img src="https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1484125950.png" width="194" height="275" />

使用如上的配置后，访问线上服务时，会走HTTP代理访问，而其他网站默认通过`PAC`规则，这个`PAC`规则会再次匹配访问网站是否为配置文件中那一系列域名网站，如果能匹配到，那么使用`SOCK 127.0.0.1`代理服务访问，否则直连访问。

到此为止，相当于3个规则根据配置自动切换，省去了手动切换的烦恼！当然，上面也保留了`Global Proxy`（全局代理）配置，如果在无法直连某个网站，且`PAC`配置文件中没有配置时，可以强制选择使用此模式进行访问。

通过上面的配置只是对`Chrome`生效，当然我们最好还是开启客户端的`Turn On`，这样其他浏览器访问网络时，也会通过`PAC`规则进行智能分流访问。

