title: 计算机系统基础（八）虚拟存储器
date: 2018-09-06 14:09:56
categories: 计算机组成原理
tags: [计算机组成原理, 虚拟内存]
---

> 上篇文章讲了CPU在内存中读取数据时，为了提高读取速度，在中间增加了一层缓存，即高速缓存Cache。
> 
> 这篇文章我们的角度下放，重点来看一下程序在运行过程中，内存是如何管理的。

# 内存问题

计算机出现的早期，其工作内容比较简单，同一时间只做一个计算任务，然后输出结果。

但随着人类需求的提高，人们希望计算机能同时计算多个任务，提高计算机的使用率。逐渐地，多任务计算机出现，但要想同时运行多个任务，那各任务之间如何分配和使用计算机资源呢？

为了解决这个问题，人类发明出操作系统，所有的计算机资源交由操作系统统一管理，各程序需要使用资源要向操作系统提出申请，操作系统按照某种规则统一分配和管理，同时保证资源的合理分配。

内存是一段连续的地址空间，如果多个程序同时运行，对于内存的时候一不小心会不会侵入了别的程序，导致运行结果产生错误？那么如何合理地分配和保护内存资源，变得十分重要。

我们都知道，一段程序要想运行必须加载到内存，然后CPU从内存获取指令和数据进行逻辑运算和处理，但如果一段程序运行时需要的内存非常大，超过了计算机的物理内存，这种程序还能否运行呢？

我们整理一下，针对内存资源遇到的问题：

- 多个程序同时运行，如何保证各程序之间内存资源分配合理，且资源互不干扰？
- 程序运行能否突破物理内存的大小？

基于这2个问题，我们来看一下，计算机是如何解决这些问题的，这其中涉及硬件与操作系统共同的协作。

<!-- more -->

# 内存分区和分页

早期计算机同一时间只能运行一个程序，内存中仅包含操作系统和正在执行的一个用户程序，所以内存管理起来很简单，只需要划分操作系统区域和用户区域即可。

现代计算机采用多道程序执行方式，内存中包含操作系统和多个用户程序，为了提高计算机的利用率，应当尽可能地让用户程序使用硬件资源然后工作。

这就需要对内存进行划分和管理，划分的区域主要是“用户区”，而划分的任务交由操作系统管理，这个过程叫做“存储器管理”。

早期经常采用“交换”技术让系统尽量多地把用户程序调入到内存中，“交换“技术的实现方式主要有两种：**分区和分页**。

## 分区

分区方式将内存分为两大区域：操作系统区、用户区域。

然后对用户区域再进行分区，主要有2种方式：**简单固定分区和可变长分区**。

### 简单固定分区

![](https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1536046604.png?imageMogr2/thumbnail/!70p)

如图，系统把”用户区“分成若干不等的固定分区，当一个用户程序调入内存时，分配一个最能够容纳它的最小分区给它。

例如，如果一个用户程序需要196K的内存空间，则将256K的分区给它。

很明显，每个用户程序所需的内存空间不可能正好和这些分区大小相对应，所以这种分区方式会大大浪费内存空间。

### 可变长分区

![](https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1536046839.png?imageMogr2/thumbnail/!70p)

如图，可变长分区方式是根据用户程序所需内存空间直接分配对应大小的空间，刚开始每个程序都能分配到自己所需的内存区域，但如果程序进入IO等待状态，操作系统则将这块空间换出到磁盘，腾出空间等待别的调入其他程序。如果此时另外一个程序被调入内存，但所需空间比之前换出的内存空间小，那么这时就会产生**碎片**。

各程序内存交换的越频繁，碎片就越多，此时内存的利用率下降。

这2种方式都会产生“碎片”，当然，通过移动用户程序可以将“碎片”合并以提高内存利用率，但会增加CPU的额外处理时间，也增加了重定位硬件的开销。

因此，分区方式不是解决多到程序运行的有效办法，现代多任务操作系统已经不再使用这种方法，我们对其有所了解即可。

## 分页

另外一种方式就分页，分页具体方式如下：

- 把物理内存划分成固定且很小的块，称为**页框**，每个进程也划分为固定长的块，称为**页**
- 进程的程序块装到可用的存储块中，且**无须用连续**的页框来存放
- 编写程序不再使用物理地址，所有程序使用统一的**虚拟地址**
- 操作系统提供一个**页表**，提供虚拟地址到物理地址的转换

![](https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1536048323.png?imageMogr2/thumbnail/!70p)

如上图，每个用户进程都使用虚拟地址，然后都通过页表找到对应的物理地址，然后从内存中读取数据。

但一个用户进程想要运行，并没有一次性地将这个进程所有需要的数据调入内存中，而是基于局部性原理，采用了**”请求分页“**的方式管理，即程序运行到哪里，需要哪块的数据，此时再把相应的数据块装入内存页框内，大大提高内存的使用率。

当程序访问的数据所在页不在内存时，则发生**缺页**，此时，操作系统会从磁盘中将数据调入内存。

# 虚拟地址空间

采用虚拟地址这种机制，为程序员提供了一个极大的虚拟地址空间，它是内存和磁盘IO设备的抽象。

由此带来了3个好处：

- 每个进程都具有一致的虚拟地址空间，简化了编写程序的内存地址，方便管理
- 它把内存看成是磁盘的一个缓存，内存只存储活动的程序数据，并根据需要在磁盘和内存之间进行信息交换
- 每个进程的虚拟地址空间都是私有的，可以保护各自进程不被其他进程破坏

一段程序经过编译、汇编、链接处理后生成可执行的二进制机器目标代码后，每个程序的目标代码都被映射到同样的虚拟地址空间，所有用户进程的虚拟地址空间都是一致的。

例如，在Linux上执行一个hello程序，对应的进程虚拟地址空间如下图：

![](https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1536050606.png?imageMogr2/thumbnail/!70p)

- 操作系统内核区：主要存放操作系统内核代码和数据以及每个进程相关数据结构
- 用户栈：存放程序运行时过程调用的参数、返回值、返回地址、过程局部变量，此区动态从高地址向低地址递增或反向减退
- 共享库：存放公共共享函数库代码，例如`printf()`函数
- 堆：存放动态申请空间，例如C语言的`malloc()`函数分配变量区，从低地址向高地址增长，`free()`函数释放内存，从高地址向低地址减退
- 读写数据区：存放用户进程中的静态全局变量
- 只读数据和代码：存放用户进程中的代码和只读数据，例如代码和字符串

有没有发现，这个虚拟地址空间的划分比较有意思：

- 整个区域分为系统内核区和用户区，分别在两端
- 用户区又分为动态区和静态区，分别在两端
- 动态区又分为栈区和堆区分，分别在两端
- 静态区又分为可读写区和只读区，也分别在两端

这样的划分，就是为了便于每个区域的访问权限设置，从而便于存储保护和存储管理。

# 虚拟存储器的实现

虚拟存储器机制与之前讲的高速缓存Cache机制很类似，高速缓存Cache是缓存了内存中的数据，**虚拟存储器是在内存中缓存了磁盘的数据**。

同样，Cache与内存的映射和一致性问题，虚拟存储器同样要解决类似的问题：

- 对于CPU读取数据，如果内存中不存在，磁盘中的数据如何分配到内存中？
- 对于CPU写入数据，如何保证内存和磁盘数据的一致性？

虚拟存储器是缓存了磁盘的数据，如果虚拟存储器中数据不存在，那么需要从磁盘上读取数据，然后放入内存。

由于磁盘的速度要比内存慢10万倍，所以除了必要的情况，应尽量少的从磁盘反复读取数据。所以虚拟存储区采用**全相联映射**的方式，保证内存中尽量装入更多的磁盘数据。

同样，由于对于写操作，由于写磁盘速度很慢，所以每次写操作不能同时写磁盘，应该采用**回写法**的方式，在内存数据发生改变时，再一次性写入磁盘，减少磁盘操作。

虚拟存储器采用全相联映射方式，所以每个虚拟地址可以映射到内存的任何一个空闲位置，因此与Cache类似，虚拟存储器必须有一种方法确定每个进程虚拟地址对应内存的位置或磁盘位置。

映射方式有3种：**分页式、分段式和段页式**，下面我们来逐个分析。

## 分页式虚拟存储器

分页式存储器把内存和虚拟地址空间都划分成**大小相等**的页面，磁盘和内存按页面为单位交换信息。

通常把虚拟地址空间的页面成为**虚拟页/逻辑页（VP）**，内存中的页面成为**页框/物理页（PP）**。

### 页表

操作系统在内存中给每个进程生成一个页表，页表中对应每个虚拟页都有一个表项，表项内容包括**存放位置字段、装入位、修改位、替换控制位、存取权限位、禁止缓存位**。

它们的作用分别如下：

- 存放位置字段：用来建立虚拟页和物理页之间的映射，用于虚拟地址到物理地址的转换
- 装入位：也称有效位或存在位，为1表示磁盘数据已调入内存，位置字段指向物理页号。为0表示磁盘数据没有被调入内存，若位置字段为null则说明此位置空闲，若不为null则说明等待磁盘数据调入内存
- 修改位：标识页面是否被修改过，在执行回写策略时根据此字段判断是否需要把数据写回磁盘
- 替换控制位：标识页面使用情况，配合替换策略设置
- 访问权限位：标识页面是可读可写、只读、只可执行，用于存储保护
- 禁止缓存位：标识页面是否可以装入Cache，保证磁盘、内存、Cache数据一致性

页表、内存、磁盘的映射示意图如下：

![](https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1536137198.png?imageMogr2/thumbnail/!70p)

例如，CPU执行一条指令需要访问数据，该数据正好在虚拟页VP1中，查询页表可知，VP1装入位为1，对应的物理页PP0，这时就可以通过地址转换部件把将虚拟地址转换为物理地址，然后访问PP0的数据。

如果数据在VP6中，VP6对应的装入位为0，表示页面缺失，发生**“缺页”**异常，需要操作系统进行“缺页”异常处理程序处理。“缺页”异常处理程序根据页表中VP6对应的存放位置字段，从磁盘中将数据读出，然后找一个空闲的物理页框存放，若内存中没有空闲的页框，则选择一个页面替换到磁盘上。

因为采用**写回策略**，所以页面淘汰时，需要根据修改位确定是否要写回磁盘。缺页处理过程中需要对页表进行相应的更新。缺页异常处理结束后，程序回到原来发生缺页的指令继续执行。

对于VP0和VP4，随着进程的动态执行，这些页面可能就会有了具体的数据。例如，当调用`malloc`函数时，堆区增长，新增的堆区正好与VP4对应，则操作系统就在磁盘上分配一个存储空间给VP4，同时把VP4页表项中的存放位置字段填上，对应的就是磁盘上的起始地址。之后便等待访问到这页数据时，再次执行上面的缺页异常流程，读取数据。

### 地址转换

上面说完了页表、内存、磁盘的映射关系和数据读取流程，其中有个环节是需要把虚拟地址转换为真正的物理地址，那这个过程是如何转换的呢？

这个转换工作由CPU中的**存储器管理部件（MMU）**完成，具体做法如下：

- 虚拟地址分为两部分：高位为虚拟页号，低位为页内偏移地址
- 物理地址也分为两部分：高位是物理页号，低位为页内便宜地址
- 每个进程都有一个页表基址寄存器，存放该进程页表首地址
- 根据页表基址寄存器找到对应的页表，由虚拟地址高位部分的虚拟页号为索引，找到页表项
- 若装入位为1，则取出对应的物理页号，然后和虚拟页内地址拼接，得到司机的物理地址
- 如装入位为0，则交给操作系统执行“缺页”处理

执行流程如下图：

![](https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1536138435.png?imageMogr2/thumbnail/!70p)

### 快表

从上述过程我们可以看出，每次访问内存都需要先查页表，然后根据规则找出物理地址，然后再访问实际的物理地址对应的数据。

如果发生缺页，还要进行页表替换、页表修改等操作，访问内存的次数就更多。采用虚拟存储器，访问内存的次数增加了很多。那有没有什么办法减少访问次数，还能达到同样的效果呢？

答案是可以的，我们可以把页表中最活跃的几个页表项复制到高速缓存Cache中，这种高速缓存Cache中的页表项组成的页表称为**快表（TLB）**。

这样在进行地址转换时，先查看快表中是否命中，如果命中，则无需访问内存中的页表即可。通过这种方式可大大降低内存访问的次数，提升效率。

到这里，我们可以总结一下CPU访问数据的完整过程：

![](https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1536138788.png?imageMogr2/thumbnail/!70p)

## 分段式虚拟存储器

分页方式的虚拟存储器优点是页长固定，易管理，不存在碎片。但缺点是页长与程序的逻辑大小无关。

例如，某个时刻一段代码有一部分在内存中，另外一部分则在磁盘上，不利于编程时的独立性，且给存储保护和存储共享造成了麻烦。

所以又提出了**分段式**的存储器。把一段程序按照类别划分为段，例如方法、操作数、常数划分到不同的段中，每个段都是一组相对完整的逻辑信息。

这样做的好处是可以按不同类型进行存储管理，也利于多个程序组合时，对同一段逻辑可以组合复用提供了便利。

分段的方式具体如下：

- 虚拟地址由**段号**和**段内地址**组成
- 内存按程序中的段划分，每个段在内存中的位置记录在**段表**中
- 每个进程都有一个段表，每个段在段表中有一个**段表项**，标识段的位置、长度、访问权限、使用和装入情况

分段存储器把虚拟地址转换为物理地址流程如下：

![](https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1536206376.png?imageMogr2/thumbnail/!70p)

分段式虚拟存储器的优点：

- 段的划分与程序的自然分界相对应
- 段的易于编译、管理、修改和保护，也便于多道程序共享
- 段具有动态可变长度，允许自由调度以便利用内存空间

分段式虚拟存储器的缺点：

- 段的长度不相同，起点和终点不固定，给内存分配带来麻烦
- 容易在内存中留下零碎空间，导致空间浪费

分页式和分段式存储管理各有优缺点，那有什么办法结合两者的优点？这就是下面要讲的：**段页式虚拟存储器**。

## 段页式虚拟存储器

段页式虚拟存储器是结合了分页式和分段式的优点，具体方式如下：

- 程序**按模块分段，段内再分页**，用**段表和页表**进行两级定位管理
- 段表中每个表项对应一个段，每个段表中包含一个指向该段页表起始位置以及控制信息和保护信息
- 页表指明该段各页在内存中的位置和是否装入、修改等状态信息

程序数据调入调出按页进行，又可以按段实现共享和保护。缺点是地址映射过程需要多次查表。

每个用户进程有一个基号，标识用户进程，进程的段表起始地址存放在各自对应的基地寄存器中，格式如下：

![](https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1536216325.png?imageMogr2/thumbnail/!70p)

逻辑地址到物理地址的转换过程如下图：

![](https://kaito-blog-1253469779.cos.ap-beijing.myqcloud.com/1536216357.png?imageMogr2/thumbnail/!70p)

# 存储保护

为了避免多个程序运行时互相干扰，或者某个程序不合法地访问了其他程序的数据，我们应该对每个程序进行存储保护，保护的对象包括**操作系统和用户程序**。

对操作系统存储保护主要是硬件提供支持：

- 支持至少2种运行模式：管理模式、用户模式，操作系统在管理模式下管理各种功能，用户进程运行在用户模式下
- 部分CPU状态只能由系统进程写，用户进程只能读：例如段表、页表首地址、TLB内容等
- 提供让CPU在管理模式和用户模式之间切换的机制：通过“异常”处理让CPU从用户模式切换到管理模式，异常处理完成后通过“返回”指令让CPU回到用户模式

对于用户进程的保护主要分为**访问方式保护**和**存储区域保护**：

- 访问方式保护：检查“访问越权”，通过段表或页表的访问权限位控制，例如共享区域只可读不可写，程序段只可执行或只读，未授权区域不可访问等
- 存储区域保护：检查“地址越界”，通过段页的起始地址和终止地址控制

# 总结

虚拟存储器相关的知识点比较多，而且比较零碎，总结如下：

- 多道程序运行时需要解决2个问题：多个程序运行如何互不干扰？程序运行能否突破物理内存大小？
- 针对问题提出了虚拟存储器的方式对内存进行管理
- 虚拟存储器对内存进行了归类划分，有2种方式：分区和分页，现代计算机主要使用分页方式管理
- 虚拟地址空间对程序使用内存进行了统一抽象管理，同时为内存划分和存储保护提供基础
- 虚拟存储器的实现包含分页式、分段式、段页式3种方式，其中段页式结合了分段和分页的优点
- 存储保护的对象包含操作系统和用户程序
- 操作系统的存储保护主要依赖硬件，用户程序的存储保护f通过操作系统控制


