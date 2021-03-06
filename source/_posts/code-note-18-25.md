title: "《编码：隐匿在计算机软硬件背后的语言》读书笔记18-25"
date: 2016-06-24 09:55:55
categories: 计算机组成原理
tags: [图书, 计算机组成原理, 编码]
---

# 18、从算盘到芯片

> 历史上，人们为了简化数学运算，发明了很多精巧的工具和机器。

早期人类社会使用如下工具计算：

- 古希腊和美洲土著：小卵石或谷粒


- 欧洲：计数板


- 中东和中国：算盘

由于这些工具无法做乘法和除法，苏格兰数学家发明了**对数**：A乘以B等于A和B对数之和，即先在对数表查找这2个值，相加后再在对数表逆向寻找其乘积。

随后的400年里，人们致力于建立对数表的工作，也有一些人设计出一些小装置代替对数表：**带对数刻度的滑尺**。

其次**手持计算器**出现，利用由刻在骨头、牛角、象牙上的数字条组成的乘法辅助器，从而制造出最早的机械计算器。但一个加法器的关键是处理进位能否成功。直到19世纪后半叶，机械计算器才得以出现并使用。

而在18世纪初，人类发明了自动织布机，使用**打孔的金属卡片**控制织物的图案，这对计算的历史产生了深远的影响。

在18世纪，人类依赖计算器的计算功能，但是此时的对数表使用起来耗费时间，英国数学家和经济学家发明了选择性的对数计算，即**差分法**，然后其设计出了**差分机**，其本质就是一个大型机械加法器，但这个差分机没有完成过。随后，这个数学家有了更好的想法，这就是**解析机**，解析机包含一个存储部件（类似存储器的概念）和一个运算部件（类似算数逻辑单元），乘法可以通过重复加法求解，除法通过重复减法求解。

此解析机可以使用改造后的织布机的卡片来编程，解析机编织出了代数的结构模型。

这个英国数学家是第一个意识到**条件跳转**在计算机中重要性的人。

但到18世纪中期，差分机最终由一对父子制造出来，人们已经遗忘了之前的英国数学家设计的差分机。

计算史另一个转折点源于美国宪法，其中有一条要求每10年进行一次人口普查，此时的人口普查数据采集工作大约要花费7年以上的时间，这个时间太久了，因此有人开始研究**自动系统**可能性。此时使用了穿孔卡片记录每个人的特征，但这不是二进制编码的，原因是：对于此时的人来说，将年龄转换为二进制数要求太高了，而且真正的二进制系统是可以将所有孔打穿的，这将会使卡片破裂。

之后，为了对人口数据进行统计，人们发明了**制表机**。

在当时的人口普查中使用这种自动化技术实验取得了重大成就，在实验中使用超过6200万张卡片，是人口普查的2倍，但时间却缩短了三分之一。

这个创造这种机器设备的人1896年创办了**制表机公司**，租借并出售穿孔卡片设备。到1911年公司合并，公司更名为**计算制表记录公司**，也叫**C-T-R公司**。再到1915年，托马斯·J·华盛顿成为这个公司的总裁，在1924年将公司更名为**国际商业机器公司**，即**IBM**。

在1928年，人口普查使用的卡片逐渐演变为IBM卡片，之后使用了将近50年。

第一台**继电式计算机**在1935年被制造出来，使用了二进制数，到了1937年，贝尔实验室的一个人在厨房中连接了一个1位加法器，称为K机器，这促使1939年贝尔实验室中复数计算机的诞生。

同一时期，哈佛大学研究生与IBM合作，在1943年创造出一台**自动连续可控计算机**，也就是闻名世界的**Harvard Mark I**，这是一台可以打印表格的数字计算机。

但继电器不是最完美的设备，频繁工作会导致断裂，如果其中有污垢也会导致失效。

在20世纪40年代，真空管已被广泛引用于放大电话信号，真空管同样可以连接成**与门、或门、与非门、与或门**，那么就可以制造出**加法器、选择器、解码器、触发器、计数器**。

但真空管同样存在价格昂贵、耗电量大、产生热量多等缺点，但好处是真空管可以在百万分之一秒内发生转变，要比继电器快1000倍。

到了20世纪40年代初期，新设计的计算机使用真空管取代继电器。

1937年**艾伦·M·图灵**在破译德国代码生成器生成的代码项目中，发表2篇论文，首次提出**可计算性概念**和**测试机器智能的方法**，这对计算机的发展产生深远影响。

1945年人们设计出了曾经最大的计算机，但设计的并不理想，到1946年，**约翰·冯·诺依曼**提出计算机应该使用二进制，并且应当拥有**存储器**，并且可以在存储器中进行寻址操作取得代码执行并保存数据，也允许**条件跳转**，这就是著名的**存储程序概念**，这个阶段被称为**冯·诺依曼结构**。但这个结构也有问题，因为在执行命令中，**从存储器取指令**要花费3/4的时间。

考虑到成本效益，人们开发出了**磁芯存储器**。

1948年在贝尔实验室工作的**克劳德·香农**发表文章，首次将**“位”**的概念介绍给世界，并开创了**“信息论”**研究领域。

与此同时，哈佛大学的**诺博尔特·韦纳**提出了**控制论**，表示计算机和机器人的机械原理之间的关系。

1948年IBM发布了第一个商用计算机系统，代号701。

而在1947年，贝尔实验室的两个物理学家制造出**晶体管**，晶体管开创了固态电子器件的时代。但晶体管刚开始是商用与助听器。

1956年，肖克利离开了贝尔实验室，成立了半导体实验室，地点在加利福尼亚帕罗奥图市，其他半导体和计算机公司相继再此建立基业，这个地方就是**硅谷**。

晶体管同样可以连接成**振荡器、加法器、选择器、解码器**，振荡器可以组成**锁存器或RAM阵列**。

1958年，人们想到了可以在一块硅片制造出多个晶体管、电阻和其他电子元件的方法，由此演化出**集成电路**。之后便有了**摩尔定律：每18个月同一块芯片上集成晶体管数目会翻一倍**。

影响集成电路性能的最重要因素是**传播时间**，即输入端发生变化引起输出端发生变化所需要的时间，传播时间单位是**纳秒(ns)**。

- 1秒 = 1000毫秒(千分之一秒)


- 1秒 = 1000000微妙(百万分之一秒)


- 1秒 = 10亿分之一秒

通常情况下，每秒至少震荡一百万个周期，称为1兆**赫兹(MHz)**。

1970年，真正在使用集成电路在一块电路板上制造出完整的计算机处理器的公司是**英特尔**公司，发布的第一款产品是一个可以存储1024位数据的芯片。

英特尔为了做出通用性的计算机，然后制造出了Intel 4004，它是第一块**微处理器**。

它是一个4位微处理器，其每秒的最大时钟频率为108KHz，最大时钟频率也叫**主频**，时钟频率决定了执行一条指令所需要的时间，处理器的**位数**也影响处理器的速度。

到了1972年4月，英特尔发布了**8008芯片**，时钟频率200KHz、可寻址空间16KB的8位处理器。

再后来到了1974年5月，英特尔和摩托罗拉同时发布了8008微处理器的改进版——**8080处理器和6800处理器**，这两款芯片改变了整个世界。

# 19、两种典型的微处理器

1974年英特尔和摩托罗拉分别推出了8080处理器和6800处理器，这两个都是8位的微处理器，运行时钟频率分别为2MHz和1MHz，寻址空间都是64KB。

这两个微处理器都是40个管脚的集成电路，其中包括：**电源输入、输入信号、输出信号、控制信号**。

微处理器只会读取二进制数，计算，然后输出二进制数。

为了方便编程和记忆，可以为每个处理器操作码指派一个**助记符**，其中加载、保存和内容转移的助记符分别为**STA、LDA、MOV**，8080微处理器内部还设置了6个8位寄存器，这些寄存器本质上都是锁存器。

处理器中有寄存器的好处是，当计算机程序同时用到多个数据，这些数据存放在寄存器比存放在存储器更方便访问，速度更快。

微处理器的寻址方式分为：

- 直接寻址


- 间接寻址


- 立即数寻址

8080处理器也包含了**标志位寄存器**，并可以通过运算改变标志位的值，这些标志位可以帮助处理器完成各种**运算逻辑和跳转逻辑**。

微处理器可以寻址的存储器叫做**随机存储器（RAM）**，主要原因是：只要提供了存储器地址，微处理器就可以用非常简便的方式访问存储器的任意存储单元，RAM就像一本书，可以翻到它的任意一页。

在某些情况下，使用不同的寻址方式访问存储器也是有好处的，例如一项工作既不是随机也不是顺序的，解决这种工作的存储方式叫做**堆栈(stack)**，特点是：**最先保存的数据最后取出，最后保存的数据最先取出**，对应的操作分别为**压栈(push)和弹栈(pop)**。

在编写汇编程序时，使用**堆栈和标志位**，就可以完成**函数的调用和返回**。

微处理器并不是只连接存储器，完整的计算机系统需要**输入/输出设备(I/O)**以实现人机交互。微处理器与外设通信，是**通过与外设对应的特定地址(接口)对其进行读写操作**。

外设操作时，是如何引起微处理器的注意呢？也就是说，外设的行为需要马上得到处理器的响应，这个过程叫做**中断**。

以上介绍的均为8080微处理器，下面来看摩托罗拉的6800处理。

6800微处理器与8080非常相似，也有40个管脚进行输入、输出、控制。6800处理器有一个16位的程序计数器PC、一个16位的堆栈指针SP、一个8位的状态寄存器，以及两个8位的累加器A、B。但6800没有设置其他的8位寄存器。

6800同样可以时间加载、保存、跳转，但其**操作码对应的助记符完全不同**，而且其标志位也与8080不同。

还有一个很重要的区别是：**两个微处理器在保存多字节数据时，地址排序不同，分别为从小到大和从大到小**。

两种微处理器的操作码不同，导致的问题就是处理器的汇编语言不同。

1975年，英特尔8080处理器被应用在**第一台个人电脑上**。

在8080之后，英特尔又推出**8085芯片**，而其竞争对手也推出了**Z-80芯片**，Z-80与8080完全兼容，而且增加了很多非常有用的指令。

同样，在1977年，由**斯蒂夫·乔布斯和史蒂芬·沃兹内卡**创立的**苹果**计算机公司推出了新一代产品**Apple II**，但它没有使用8080和6800，而是使用了基于MOS技术更加便宜的**6502芯片**，它是**6800的改进增强版本**。

1978年6月，英特尔推出**8086芯片，它是一个16位的微处理器，寻址空间1MB**。但8086与8080操作码不兼容，但它包含了**乘法和除法指令**。

一年后，英特尔又推出了**8088芯片**，内部结构与8086完全相同，但外部仍以字节为单位访问存储器。

IBM在个人计算机中使用了8088芯片，这种计算机叫做**IBM PC**。

IBM大举进军个人计算机市场，使用的都是英特尔处理器。英特尔相继发布了**186芯片、286芯片、386芯片、486芯片**，到了1993年，发布**Intel奔腾系列微处理器**。这些芯片的指令集都是兼容8086操作码的。

苹果公司的**Macintosh**发布于1984年，采用**68000微处理器**，它是16位微处理器，是6800的下一代产品。

到了1994年，Macintosh计算机开始使用**PowerPC微处理器**，此处理器由摩托罗拉、IBM以及苹果联合开发。

**PowerPC采用RISC（精简指令集计算机）微处理器体系结构设计。**其内部设置了大量的寄存器，运算速度非常快。

微处理器发展到现代，采用多种技术来提高运行速度。其中一种就是**流水线技术**，还有**高速缓存技术**。

# 20、ASCII码和字符转换

> 计算机中存储器唯一可以存储的是比特，因此如果想要在计算机中处理信息，必须按位存储。那么计算机是如何用它来存储文本的？

为了将文本表示数字形式，我们需要构建一种系统为每一个字母赋予一个唯一的编码，包括数字和标点符号。具有这种功能的系统被称为**字符编码集**，系统内每个独立编码称为**字符编码**。

那么构建这些编码需要多少比特？

就英语而言，所有大小写字母一共需要52个编码，0-9数字需要10个编码，一共62个编码，加上标点符号，数量超过64个，也就是说，一个编码至少需要6个比特。但无论如何字符数应该不超过128个，而且远远不够128个，也就是说编码长度不会超过**8位**。

所以答案就是**7位**编码时，不需要转义字符，而且可以区分大小写字母。

如何指派这些编码？当然，自己造一台计算机，可以任意指定字符对应的编码。但是这是不通用的，也与其他计算机不兼容。

这样一来，随意编码就不合适了。如果在处理文本时，字母表的编码是按**顺序**来的，那么工作起来就会很便利，优点是：**字母排序和分类将变得简单**。

于是就产生了一种标准，被称为**美国信息交换标准码，简称ASCII码**。

ASCII码是7位编码，二进制取值范围是0000000~1111111，对应十六进制是00h~7Fh。

**在ASCII码中，大写字母与其对应的小写字母ASCII码相差20h。（大写字母=小写字母-20h）**

这种规律大大简化了程序代码的编写。

ASCII码中有95个编码称为**图形文字**，因为其可以显示出来，还有33个**控制字符**，它们用来执行某一特定功能，因而不用显示出来。

其中，**回车符**使打印头换行并转移至当前页的最前端，**换行符**使打印头转移至当前位置下一行。

尽管ASCII码是计算机领域最重要的标准，但其缺点是：只能用于美国。其他国家有太多字符无法表示。

于是就想到一种**扩展ASCII字符集**的方案，计算机采用8位编码存储字符，这样就可以保存256个字符。在这个字符集中，编码00h~7Fh与原ASCII码保持一致。编码80h~FFh用来引入其他字符：例如重音字母以及非拉丁字母。

但是这种扩展ASCII码的思想开始被滥用，随之而来就产生了不同版本扩展的ASCII码，导致编码不一致。

由此，业界打算建立一个独一无二的字符编码系统，它可以用于全世界所有的语言文字。

1988年开始，几大著名计算机公司合作研究一种替代ASCII码的编码系统，取名**Unicode码**。

Unicode码采用16位编码，每一个字符需要2个字节，00000h~FFFFh共计65536个不同字符，全世界所有人类语言，都可以使用同一个编码系统，而且具有很高的扩展性。

Unicode码前128字符编码是与ASCII码一致的，也就是兼容ASCII码。

**Unicode码优点是可以表示世界所有语言，但缺点是存储空间比ASCII码要大一倍。**

<!-- more -->

# 21、总线

> 在一台计算机中，随机存储器（RAM)存放着处理器要执行的机器代码指令，但CPU是通过怎样的方法把指令加载到RAM中的？

搭建一台完整的计算机需要很多集成电路，这些集成电路都必须挂在到电路板上。计算机的各个部件按照功能被分别安装在多个电路板上，这些电路板之间通过**总线**通信。

**总线就是数字信号的集合，这些信号被提供给计算机的每块电路板。**

总线信号分类如下：

- 地址信号，CPU产生，通常用来对RAM寻址，也可对外设寻址


- 数据输出信号，CPU产生，用来把数据写入RAM或外设


- 数据输入信号，外部产生，CPU读取


- 控制信号，CPU和外部设备都可以产生，例如CPU把数据写入特定内存单元时

总线还可以为计算机不同电路板供电。

最早比较流行的是S-100总线，适用于8080和6800处理器，它有16个地址信号，8个数据输入信号和8个数据输出信号，它还含有8个中断信号。

总线规范慢慢使得**总线标准**的产生。

1981年，IBM个人PC问世，并公布了整个计算机的电路图。工业标准的体系结构总线，是IBM为最初的PC设计的。

此扩展板上有62针连接插头。有20个地址信号，8个输入/输出信号，6个中断信号，3个直接存储器访问请求信号(DMA)。

**DMA可以其他设备部通过CPU而获得总线控制权，直接对内存进行读写。**

1984年，IBM推出个人计算机AT，采用16位Intel 80286处理器，寻址空间16MB。处理器的数据宽度增大，总线就要升级。

1987年，IBM推出**微通道体系结构(MCA)总线**，但由于称为IBM专利，所以没能称为工业标准。

1988年，9家公司联合推出**32位EISA总线**取代了MCA总线，成为了**工业标准**。

# 22、操作系统

> 当我们把微处理器(CPU)、随机访问存储器(RAM)、键盘、显示器、磁盘驱动器连接在一起后，就可以使它们按照我们的意愿工作吗？

当然，也许是可行的，我们需要编写汇编指令针对硬件编程，但是使用成本是非常高的。

所以我们需要一个软件系统来帮我们协助工作，这个软件就是**操作系统**。

操作系统是许多软件构成的庞大程序集合。

我们编写的程序代码最终是存在磁盘上的，这样才会保证断电后不会丢失，但磁盘的结构是复杂的，读写数据复杂，由于这种原因，**文件系统**应运而生。

**文件系统是磁盘的抽象，把数据组织成文件，文件是数据的集合。文件系统属于操作系统的一部分。**

操作系统作用：

- 对硬件进行抽象，提供文件系统、虚拟地址空间等
- 提供程序运行的环境，帮助程序加载和执行
- 屏蔽硬件的差异，提供程序访问硬件资源的API，即**应用程序接口**

**Unix操作系统**在20世纪70年代初在贝尔实验室开发出来。

1973年初，很多大学、公司和政府机构被授权使用和研究Unix，这促进了Unix的发展。

渐渐地，操作系统发展为**多任务操作系统**。

Unix的发展也来自无数人的贡献，其中GNU项目是创建一个与Unix系统兼容，但不受私有限制的操作系统和开发环境。

在这个项目驱动下，产生出许多和Unix兼容的应用程序和工具，其中最著名的就是**Linux操作系统**。

到了20世纪80年代，开发大型、复杂度更好的系统成为操作系统发展的趋势，同时也融合了图形化和高级可视化显示技术，使应用程序变得更易于使用。

# 23、定点数和浮点数

在计算机存储中，所有的数字都是以位的形式存储的。

我们平时说的整数，也叫**自然数**，其中包括**正整数和负整数**。

两个整数的比值叫做**有理数或分数**。

- 3/4是一个有理数，它的值是0.75，它是整数3和4的比
- 1/3也是一个有理数，它的值虽然是0.3333333....，但是本质上它也是两个整数的比

有理数都可以用10的幂形式表示，例如:

42705.684 = 4\*10^4 + 2\*10^3 + 7\*10^2 + 0\*10^1 + 5\*10^0 + 6\*10^-1 + 8\*10^-2 + 4\*10^-3

**无理数**不能表示两个整数的比，例如2的平方根就是无理数，它不能表示两个整数的比，这意味着小数部分是无穷且无规律的，并且没有循环。

其实2的平方根方程式为：x^2 - 2 = 0

如果某个数不是任何以整数为系数的代数方程的解，那么这个数称为**超越数**，所有的超越数都是无理数，但是反之不成立。

π就是典型的超越数，近似值是3.141592653....。

**有理数和无理数统称为实数，还有一种叫做虚数（例如负数的平方根）。**

**实数与虚数构成了复数。**

任意给出2个有理数，我们都可以找出位于它们之间的数，但是对于计算机来说对连续数据却不行，因为二进制每一位非0即1，两者之间没有任何数，这一特点决定了计算机智能处理**离散数据**。

小数也可以表示为二进制数，最简单的方法是**BCD码**，BCD码是将十进制数以二进制的形式编码。

通常把2个BCD数字存放在一个字节，这叫做**压缩BCD**，由于2的补数不和BCD数一起使用，因此压缩BCD增加了1位用于标识数的正负的**符号位**。

这种基于二进制的存储和标记方式被称作**定点格式**，即小数点的位置总是在数的某个特定位置。

如果想表示非常大或非常小的数，那么定点格式数是不适合的。

科学家们使一种叫做**科学计数法**的方法记录这类较大或较小的数，利用这种计数系统可以更好的在计算机中存储这些数。科学计数法用10的幂乘积形式表示，这样可以避免写一长串的0，例如：

- 490,000,000,000 = 4.9\*10^11
- 0.00000000026 = 2.6\*10^-10

其中4.9和2.6叫做**小数部分或首数**，也叫做**有效数**。

一般有效数的取值范围大于等于1且小于10。

这样**指数部分**可用来表示10的几次幂，指数表明小数点相对于有效数移动的距离

在计算机中，除了定点格式存储，还有一种叫做**浮点格式**，浮点格式是基于科学计数法的，所以它是存储极大或极小数理想方式，但计算机中的浮点格式是用**二进制**实现的科学计数法。

例如二进制数101.1101 = 1\*2^2 + 0\*2^1 + 1\*2^0 + 1\*2^-1 + 1\*2^-2 + 0\*2^-3 + 1\*2^-4

即二进制101.1101是与十进制数5.8125相等的。

而进制数的科学计数法也规范有效数大于或等于1且小于10(即十进制的2)。

所以二进制101.1101 = 1.011101 \* 2^2

这样就产生一个规则，**小数点左边通常只有一个1**，没有其他数字。

于是1985年IEEE(美国电气和电子工程师协会)就指定了**浮点数标准和运算标准**。

IEEEE浮点数标准定义了2种基本格式：

- 以4个字节表示的单精度格式，其中1位符号，8位指数，23位有效数
- 以8个字节表示的双精度格式，其中1位符号，11位指数，52位有效数

这样一来10位的二进制数可以近似的用3位十进制表示，即2^10≈10^3。

单精度浮点数的精度为1/2^24，或1/16777216，或百万分之六。

这意味着，**在单精度浮点数格式下16777216和16777217将表示成同一个数，且处于这两个数之间的所有书也将表示同一个数。**

双精度浮点数与单精度浮点数类似，只是指数位和有效数位变大，格式虽然有所改进，但是仍然避免不了这个问题。

浮点数的运算对于计算机来说是必须支持的，这表示着计算机将能计算更多的事情。

# 24、高级语言与低级语言

使用机器码编写程序是非常痛苦的，使处理器完成最简单的工作也需要写大量的机器码。

于是就产生了**汇编语言**，汇编语言是**低级语言**。

汇编语言的**助记符**是与机器码一一对应的，使用助记符编程减少了错误率且代码量减少了许多。

但是汇编语言还是针对机器编程，如果硬件发生变化，那么代码则不能使用，所以汇编语言最大的缺点是：

- 针对芯片级编程，需考虑硬件的每个细节
- 不可移植

于是人们就想到一种替代策略，类似于经典的数据表达式的方式来描述复杂的运算，于是就产生了**高级语言**。

设计高级语言依赖3种条件：

- 定义
- 语法
- 编译器

高级语言的优点：

- 易于阅读
- 代码少，开发效率高
- 屏蔽硬件细节
- 可移植性高

由于高级语言重新定于了语法，所以需要编译器最终编译成机器语言，所以缺点是：**执行效率没有低级语言快**。

**ALGOL**是高级语言的鼻祖，ALGOL的语言思想奠定了之后高级语言设计的基础。

**它定义了变量、代码块、跳转、循环。**

第一个成功的高级语言是**COBOL**，它是为商务使用使用设计的语言。

之后出现了**BASIC语言**，**比尔盖茨**就是通过BASIC语言创建了微软公司。

慢慢的发展出语言的编辑器，集成开发环境等。

随后产生了**C语言**，C语言是贝尔实验室丹尼斯M里奇开发的，从1969年设计到1973年开发完成。

C语言的前身是**B语言**，B语言是**BCPL语言**的精简版本，BCPL来源于CPL。

**Unix操作系统**当时是基于某个处理器用**汇编语言**编写的，不具有可移植性。

而在1973年，Unix系统采用C进行了**重写**。

# 25、图形化革命

> 计算机的渐渐发展，体积越来越小，处理速度越来越快，价格也越来越便宜， 这种趋势使得每个人都有自己的个人计算机成为了可能。

那么为了充分利用计算机的运算和处理能力，较好的一种方法就是不断改进**用户界面**——它是人机交互的核心。

运算需求和硬件的发展也会驱动着人机交互发展，慢慢发展出**键盘、鼠标**来辅助人类进行计算机操作。

渐渐地各个操作系统从**命令行**模式开始转变为**用户界面**模式，操作系统封装通过图形界面封装好对底层的操作，以更友好的方式展示给用户。

同时操作系统提供了一系列的**图形化编程的函数**，例如：画线、画矩阵、画椭圆等。

在图形化操作系统中，已经不再使用汇编语言进行开发，在1972年，PARC的研究员开始研发一种为**Smalltalk**的语言，这种语言嵌入了**面向对象程序设计思想**，也就是**OOP**。

在面向对象程序设计中，**对象**表示代码和数据，在对象内部，与其关联的代码决定了数据存在的意义。

**C++**的最初是作为C的面向对象思想的扩展产生的，它最开始是作为一种**转换程序**，按照面相对象思想的编程方式，最终**转换**为C程序。

慢慢的由于图形界面的发展，**集成开发环境IDE**也发展起来，这样大大简化了程序开发任务，此后开始了**可视化编程**，即通过鼠标“拖拽”就可以完成一部分开发任务。

计算机图形发展产生2个分支：

- 矢量图形：利用直线、曲线及填充区域生成图形


- 位图：将图像以矩阵阵列的形式编码，阵列中每个单位对应输出设备的像素点

位图存储在计算机中很大，慢慢就发展出**数据压缩**的算法来减少存储。

慢慢又发展出了**GIF、JPEG和OCR技术**。

图像可以转化为数字化的可视信息，同样的，**音频**也可以转化成比特和字节。

然后**CD和CD-ROM**发展起来。

把一系列静止图像快速播放，可以达到图像中物体移动的效果，这其中每个图像叫做**帧**，**数字化电影**发展起来。

由于电影文件附带声音和图像，所以存储要求非常大，渐渐发展出了**DVD和DVD-ROM**来存储电影文件。

人类慢慢的开始研究**远程操作技术**，这就产生了**Internet**的发展，**Internet本质上是一组协议的集合。**

**其中TCP/IP协议(传输控制协议和网际协议)，使得传输过程变得规则化。**

然后就有了**HTTP协议**在显示层面上工作，**HTML（超文本标记语言）**产生，它可以显示文字、图像等。

有了网页的产生，则在浏览页面时需要进行一些操作，这就划分了**服务端和客户端**。

服务端产生了**Java语言**，一种面向对象程序设计语言，且它是不受限于机器和操作系统类型的，具有**平台无关性**。

客户端程序产生出**JavaScript**，可在浏览器中执行的程序。


