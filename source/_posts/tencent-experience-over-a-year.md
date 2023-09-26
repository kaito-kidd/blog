---
title: 聊一聊我来腾讯一年多的感受
date: 2023-08-08 16:17:34
categories: 程序人生
tags: [腾讯]
---

你好，我是 Kaito。

很多关注我比较早的读者都知道，我的公众号（二维码在文末）去年断更了一年，原因是因为去年换了工作来到了腾讯，因为工作方向也发生了一些变化，从舒适区跨入陌生领域，所以更多时间花在了工作上，当时无奈公众号更新只能暂时搁置。

上周在公众号也发了个通知，最近又换了新工区了（搬到了腾讯北京总部大楼），算了一下，来腾讯已经一年多了，借这个机会写篇文章记录下这一年来的感受吧。

<!-- more -->

先说下我的基本情况，我从 2013 年毕业来到北京，到目前为止只换过这一次工作，是不是挺惊讶的。

来腾讯之前，我在一家中等体量的互联网公司待了 7 年多。

毕业从一名业务开发干起，从技术菜鸟一路打怪升级，做到了基础架构（中间件、多活），中间虽然一直没换公司，但换过 3 个技术团队，直到去年初终于跳槽，换到了大厂腾讯（**现在做中间件、云原生、云计算方向**）。

在近 10 年的职业道路上，遇到过不少抉择。**这次先聊一聊这一年多在腾讯的感受，下篇文章来重点聊一聊，我职业道路上的思考和抉择。**

**先说说腾讯的优点。**

1、福利方面没得说，上下班不打卡，包早晚餐，年假可预支，一年带薪病假有 30 天，过年过节有礼品，每月发 Q 币（充腾讯视频会员，看剧无忧）。

2、办公配套成熟，例如办入职、领东西、换电脑、申请办公用品、设备维修都是自助式的，线上系统申请，会有「专人」协助处理，每项流程都有内部客服对接，有的甚至 7*24 小时服务。

3、项目开发流程比较规范，类似于开源项目的开发模式，代码写完提 PR，找人 Review 代码，Review 通过后代码才能被合入。

4、开发提交的代码，都会有代码扫描，例如代码风格、注释、编程规范、安全漏洞，系统会定期发代码评分出来，评分太低的会被要求优化。

5、基础平台比较成熟，例如代码仓库、镜像仓库、DevOps 流水线、开发机等等，这些都是腾讯内部打磨非常久的产品，有些甚至已经打包成产品对外售卖。

6、在线办公配套非常成熟，企业微信 + 腾讯会议 + 腾讯文档，腾讯员工遍布全国，员工之间「异地协作」都是通过这三大件完成。不得不说腾讯文档是真的好用，来腾讯后工作协作重度依赖文档，现在都是在线搞定，再也不用搞一堆 Word、Excel 传来传去。

7、因为这些办公配套让工作都在线化了，所以工作不再受地域限制，之前疫情期间在家办公，几乎是无缝切换，完全没感觉到不适应，在家还是在公司办公，差别可能就是公司管饭（平时如果有特殊情况也可以申请在家办公）。

8、牛人多，内网干货技术文章也不少，认真读一读能学到不少东西，内网论坛有一个专门的团队负责运营，每日推荐优秀文章，做各种活动鼓励员工输出（我之前在内网发的技术文，上了热榜第一，后来还被邀请在鹅厂视频号做了场直播）。

9、分享和讲座多，几乎每周都会有，因为腾讯体量很大，产品线成百上千个应该是有的，很多部门为了推广自己的产品，都会在内部做分享，对于提高自己产品和技术「视野」还是有帮助的，例如最近很火的 AIGC，腾讯内部关于这个话题的分享应该不下 20 次了。

10、下班自由，不强制加班，至少我待的团队是这样，不像字节那样每天必须干到 10 点才能走​——公司几乎买断你的业余时间。腾讯在所有大厂里这方面做的好一些，至少保证还有自己的​生活时间。

**再说说缺点。**

1、可能是大公司通病，因为公司大，人也多，如果对接的业务线多起来，有问题会被拉到各种群解决问题，每天企微群消息「轰炸」，不得不屏蔽各种群减少噪声。

2、处理问题流程长，有时反馈一个问题，随着问题的深入，群里拉进来的人越来越多，每个人负责不同的模块，这个模块问题解决完，发现是另一个模块的问题，只能一层层拉人。曾经看到内网有个帖子，一个离职员工交接系统权限，好像是因为权限归属问题，离职走的当天还拉了 N 个群，才完成权限交接。

3、有时候因为处理各种问题和回企微消息，白天没时间写代码，只能晚上等没人打扰了才能安静写代码。

4、企微很难用，群消息没有重复信息的聚合能力，经常被群里的点赞长龙刷屏，不能单独设置@消息特殊提醒，对于消灭未读强迫症患者非常难受（上家公司用飞书，感觉很好用）。

5、最让我想吐槽的是企微的开会功能，之前线上开会用腾讯会议，一般都是拉会人把腾讯会议链接先发出来，大家自行点击链接参会。可能是觉得员工参会效率低，企微后来不仅把腾讯会议「集成」到了企微里，还在企微里搞了个「一键开会」功能，如果是私聊窗口点了这个按钮，还不会不停滴滴滴地呼叫对方，催你赶紧参会（就像打语音电话 call 你一样），如果你不参会，他还可以一键打到你的手机上。我觉得这玩意非常烦，让本来专注的工作进程，总是被别人拉的会议强制打断，我本身就讨厌开会，有了这个功能更加厌恶开会。

6、搞出这个功能的产品经理，肯定也想过用户体验会很差，但为了拉会效率高，只能选择后者。

7、人文关怀有，但感受不深，因为部门多人也多，行政小姐姐发通知，只能是拉个大群在群里@大家（例如领东西，通知参加活动）。而且行政岗很多是外包，经常换人，一年下来，我也没见过几次面，大家都只是完成自己的工作，很少能像中小公司那样打成一片。

8、归属感差一些，优秀的人多，有想法的人也多，比较卷，逼着你不能躺平。有时候有心无力，比较无奈，工作上没什么想法的人，每个月总有那么几天会思考自己在这里工作的意义是什么，就像工厂里的一颗螺丝钉，哪里需要就去哪里。

我待的团队接近 30 人，整个团队分布在全国各地（北京、上海、杭州、深圳、成都、武汉）。

组内和我工作交互比较多的人不在北京，所以平时交流只能是线上，这一点和之前工作都在一起的模式相比，当时还是适应了挺久的。

毕竟如果大家在一起，能沟通的时间也多（吃饭间隙都可以交流），异地线上沟通，只能提前约时间，无法做到随时交流。

我之前一直是做 ToC 方向的基础架构，来腾讯后开始做 ToB 方向（腾讯 CSIG 事业群），刚来的那半年感觉很不适应，因为 B 端客户的需求和 C 端差异还是挺大的（B 端更关注资源、成本、安全）。

另外，腾讯这种 ToB 部门是非常关注营收和成本的，如果亏损严重就有可能裁员甚至整个部门被干掉，压力会大一些，有时候为了拿下客户，不得不做一些商业上合理，但技术没收益的事情（说白了就是向钱看齐），没办法，商业就是这样。

来腾讯一年多，技术上提升最大的是开始接触 **K8s、云原生、云计算**方向，这块也是近几年一直很火的方向，当然挑战也大。中间件本身就不好搞，加上 K8s 难上加难，踩坑不少。

简单总结下，总的来说，**在大厂工作，条条框框的东西比较少，该给的配套都给足了，剩下的就是自驱，把事情落地好。当然最好还要学会推销自己，大厂人才很多，不会发声很容易被埋没。**

**专业方面，在大厂工作需要很强的「抗造」能力，以及「多线程」处理事情的能力。**

对于刚毕业的学生党来说，我还是挺推荐来大厂的，标准化的流程规范，前沿的技术视野都很有吸引力。对于有经验的跳槽者，就看能否自己能否把专业的能力和大厂做融合，从而进一步提升自己的能级。