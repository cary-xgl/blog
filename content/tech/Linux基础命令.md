---
title: "Linux 基础命令"
date: 2026-05-31
tags: ["Linux"]
categories: ["技术"]
---

> 日常最常用的 Linux 命令先归到一篇里，后面补充也方便。
<!--more-->

### sed/scp&rcp/sz&rz
sed命令（直接操作文件中的内容） Stream editor 流编辑器
scp 是 secure copy 的缩写, scp 是 linux 系统下基于 ssh 登陆进行安全的远程文件拷贝命令。
scp 是加密的，rcp 是不加密的，scp 是 rcp 的加强版

sz rz(传输文件命令，需yum)

### 用户配置文件相关etc password
username:password:userId:userGroupId:comment:user_Home:shell命令所在目录
比如：root:x:0:0:root:/root:/bin/bash

### nohup & &
&：linux运行命令最后加一个&  比如 sh test.sh & 会把命令放到后台执行 并且此时可以继续接收命令的执行，执行记录会打印下来，当关闭session时，命令会中断不继续执行
nohup：比如 nohup sh test.sh 不挂断的运行，意思是即使session被终结了，也会继续执行，但是终端不接受新的输入（好像并没有什么影响），并且会自动输出日志到nohup.out中
但是这两个结合起来就可以使程序在后台不中断的执行， nohup sh test.sh &;
重定向日志的输出
nohup sh test.sh >bar.log & (选择性的输出日志位置) 注：输出到/dev/null则是不记录日志的意思，因为这个文件会丢弃所有写入的操作

### > & >> & <
输出流: > >>
输入: <
区别在于>> 是追加日志到文件，而> 是覆盖操作 
注：等同于1>,1>> （1代表什么，见下）

### ＆>filename、2>&1、1>&2 、/dev/null
首先明确下概念：
标准输入 标准输出 错误输出 对应的文件操作符为 0 1 2
而/dev/null 特别之处在于所有写入这个文件的东西他都会丢弃掉
 
 &>filename：把标准输出和错误输出都输出到文件filename中
 2>&1: 就是把标准错误输出重定向到标准输出中
 1>&2: 把标准输出日志重定向到标准错误输出中
 
 经测试 nohup命令 缺省会把标准错误输出重定向到标准输出中
 即nohup [command] > nohup.out 等同于 nohup [command] > nohup.out 2 > &1 (nohup.out 为缺省输出，可自定义文件输出)
 但是可以通过比如：> file.out 2>file.err 这种方式重定向错误输出（一般好像没必要） 
 
 ### chmod&chown&chgrp
 
 #### chmod
 chmod用户更改文件的权限（拥有者，所在组， 其他用户）
 而一个文件的详情（比如通过ls -l查看）
 会发现最开始有文件的权限信息 比如 -rwxr--r--(共10位)
 其中第一位代表文件是否为目录，是的话显示 d 否则 -
 后面九位分别为 拥有者的读/写/执行权限，所属用户组的读/写/执行权限， 其他用户的读/写/执行权限
 chmod命令更改权限时 读写执行权限可以分别用数字代替 读：4 写：2 执行：1
 拥有者可以用 u 表示 组则用 g 表示 其他用户则用 o表示 ，如果是所有的 则可以用 a
 几个例子：
 字母设定：
 chmod u+x filename (给拥有者增加执行权限)
 chmod a+x filename (所有用户增加此文件执行权限)
 chmod go+r filename (组及其他用户增加读权限)
 chmod o-w filename (其他用户减少 写权限)
 chmod o+r, u+w filename (多个操作用逗号隔开，不再赘述)
 数字设定：
 chmod 640 filename (r+w -> user, w -> group , other没有任何权限)
 chmod 777 filename (所有用户可读可写可执行hhh)
 
 #### chown
 chown用来更改文件或目录所属用户
 chown [选项] 用户/组 文件/目录
 -R参数 表示递归的更改此目录下文件的权限
 因为chown可以更改用户组的权限，所以在实际使用中可以替代chgrp命令（感觉，未深入了解）
 
 #### chgrp
 chgrp用来更改文件所属用户组
 chgrp [选项] 用户组 文件/目录
 大体类似于chown,只用来更改用户组
 
 ### history
 history 命令可以查看用户输入的命令记录
 用户输入的命令记录（所有的）保存在家目录 .bash_history文件中
 cat ~/.bash_history
 
 ### Inode
 linux系统的硬盘：文件存储在硬盘上，硬盘的最小存储单位是扇区 每个扇区512b,但操作系统读取的时候不会一个扇区一个扇区的读取，效率太低，所以会一次读取多个扇区，多个扇区可以组成一个块，块是操作系统读取的最小单位（最常见的是4kb）,硬盘格式化的时候会自动将硬盘分成两个区域：

*  一个是数据区
*  一个是inode区，负责存储文件的元数据

一般每1-2kb字节就会设置一个inode (一个inode占据128字节一般)，假设1kb设置一个inode,那么硬盘中这两个区域的比例就是8：1

因为每个文件必须有一个inode，所以可能存在硬盘还未满，但是inode空间已经被耗尽的情况，这时候就无法在硬盘上创建新文件

#### inode包含什么
文件的字节数
文件拥有者的UserId
文件所属组的GroupId
文件的读写执行权限
文件的时间戳 三个【inode上一次变动的时间，文件上一次变动的时间，文件上一次打开的时间】
硬链接数【软硬链接见下面】，指向这个inode的文件名的数量
文件数据的位置

#### inode特殊作用

* 有时文件名包含特殊字符，那么直接删除文件可能删不掉，此时删除inode节点就能起到删除文件的作用
* 移动或者重命名文件，不改变inode
* 打开一个文件，系统已inode识别这个文件，不再考虑文件名，使得软件更新变的简单，如果软件正在运行中，那么就创建一个新的inode,不会影响到正在运行中的文件，等到下次运行这个文件的时候，自动将新的指向这个新inode即可，旧的inode将会被回收

### 文件描述符
> 原笔记此处有一张配图，资源路径还没整理过来。

### select、poll、epoll
阻塞IO:> 原笔记此处有一张配图，资源路径还没整理过来。
非阻塞IO:> 原笔记此处有一张配图，资源路径还没整理过来。
IO多路复用：> 原笔记此处有一张配图，资源路径还没整理过来。

> 原笔记此处有一张配图，资源路径还没整理过来。

### 用户
useradd 增加用户 - 不指定用户组的话会默认加一个相同名的用户组
userdel 删除用户
su - user 切换用户 （高等级用户切换到低等级用户不需要密码，反之需要）
id 查看当前用户

who am i

### 用户组
groupadd groupname 创建组
groupdel groupname 删除组

useradd -g groupname username 增加一个用户并添加到groupname组下
usermod -g groupname username 将用户移到一个新的组中

### 系统级别
0  1 2 3 4等等，可以通过切换系统级别调节 init 3 init 5等，比如5是图形化界面，5是命令行页面
但是现在比如centos成了systemctl
> 原笔记此处有一张配图，资源路径还没整理过来。

### 帮助指令
- help help指令是shell（应用程序）层面的 可以查看shell内置指令的帮助信息（exit cd echo等） 比如echo --help，可以看到没有显示任何信息 > 原笔记此处有一张配图，资源路径还没整理过来。
help echo 可以看到内置指令和外部命令的区别 > 原笔记此处有一张配图，资源路径还没整理过来。

- -- help 通常是shell外部命令携带的（ls vi）等会自带帮助信息 外部命令是linux系统中的实用程序部分，因为实用程序的功能通常都比较强大，所以其包含的程序量也会很大，在系统加载时并不随系统一起被加载到内存中，而是在需要时才将其调用内存。通常外部命令的实体并不包含在shell中，但是其命令执行过程是由shell程序控制的。shell程序管理外部命令执行的路径查找、加载存放，并控制命令的执行。外部命令是在bash之外额外安装的，通常放在/bin，/usr/bin，/sbin，/usr/sbin......等等。 查看命令是内部还是外部> 原笔记此处有一张配图，资源路径还没整理过来。

- man man指令是操作系统层面的，最详细

### 文件目录指令
pwd print working dir

ls 
- -l 列表
- -a 全部 包含隐藏文件

mkdir 
- -p 创建多级目录

rmdir 删除目录（不能删除有文件的目录）
如果要删除用rm -f /dir

touch 创建一个空文件 touch file1 file2...

cp 【选项】 source dest   拷贝
- -r 递归复制整个文件夹 recursion 递归

rm
- -r 递归
- -f 强制 force

mv oldname newfile 重命名
mv /dir/file1 /dir2 file1移动到dir2中

cat [选项] file
- -n显式行号

more 
- 空格键 向下翻页
- enter 向下一行
- q quit
- ctrl+F 向下滚动一屏
- ctrl+B 向上滚动一屏
- = 行号

less 适合查看大文件，因为less不是加载整个文件到内存，需要多少加载多少
- 空白键 向下一页
- enter 按行走
- pagedown 向下 pageup 向上
- /子串 n 向下查找 N 向上查找
- ？子串 n 向上查找 N 向下查找
- qquit

> 输出重定向 >>追加

echo

head 显式文件的前几行 head -n 10 file
tail 显式文件后尾部几行 
- tail -n 5 file
- tail -f file 实时追踪该文件的所有更新 很重要 比如docker防止container退出 tail -f /dev/null + 再加上守护运行 -d，就可以让docker在后台持续运行了 可以执行exec等命令进入docker了

history 10 显示最近10条

date 显示当前日期

### 搜索查询

find 范围【/home, .】 -name file
find /opt/ -user user 按用户查找
find / -size  +20M
find /  -name *.txt 通配符查找

grep -n 查找内容 file        
- -n显式行号
- -i 忽略大小写

### 压缩
gzip 压缩
- gzip  -c file -> file2 保留原有文件，否则将会直接替换为新压缩文件 -c 把压缩、解压后的文件输出到标准输出设备。然后重定向到新文件中
gunzip 解压缩

zip 【】 file.zip file/dir 
- -r 递归压缩目录

unzip  file.zip
- -d dir 制定目录

tar [] XX.tar.gz file1 file2 或者dir
- -c 产生.tar打包文件
- -v 显式详细信息
- -f 制定压缩后的文件名
- -z 压缩成gz格式或者解压
- -x 解压tar文件

常用的 -zcvf XX.tar.gz 打包并压缩 -zxvf 解压
或者只打包 -cvf XX.tar 解压tar -xvf 

### 权限
chown user file 改变文件拥有者 不改变组（组和用户独立）
chgrp grp file 改变文件 拥有者组 （不改变用户）
chown newUser:newgrp file 改变组和用户 

-rw-r--r--  共10位 第一位
- - 普通文件
- d目录
- l 软连接
- b:块文件

后9位 当前用户拥有者权限读写执行 当前组。。。 其他组及用户

u 所有者 g 所在组 o其他人 a 所有人 r读-4 w写-2 x执行 -1
chmod u+X file
chmod g-w
chmod a=rw,g=r file
chmod 777 file

### 定时
crontab -e 编辑定时任务

### su su - sudo
su命令一般用来提升用户权限至root 比如su 然后输入root用户的密码就可以新建一个shell
su - 命令和su命令不同的是 su - 新建的shell是以真正的root用户的环境变量开启的，而su使用的是切换前的用户环境
> 原笔记此处有一张配图，资源路径还没整理过来。
 
 su vs sudo
 sudo和su的最大区别是sudo需要输入当前用户的密码，而su输入的是要切换的用户的密码
 所以就安全来说，sudo显然更好一些，不需要分配给用户比如root的权限密码，而只需要配置sudo这个命令即可，比如配置某个用户或某个用户不可访问某个命令，而且sudo不会开启新的shell，而只会使用提升过的权限执行命令 sudo dokcer start...,而且执行sudo下的命令可以记录是哪个用户操作的，su则是真正的
 root用户

### 磁盘
df -h  查看磁盘使用情况
du -h /dir 查看某个目录磁盘占用情况

grep "" | wc -l 先查询再统计个数
tree  展示目录结构

### 清屏
clear

## 配置文件
### /etc/passwd
放置用户信息

### /etc/group
放置组信息

### /etc/shadow
口令配置文件（加密过后）存放用户密码 最后一次登录时间等

## Q&A
### sh脚本替换字符
#### 通过$0, $1, $2替换
其中$0代表的是文件名，也就是说实际的外部变量替换是从$1开始的
并且最多$9，接下来如果还有参数传入就要 $(10), $(11) 这样传入
$#: 代表的是传递到脚本的参数个数
$\*: 会输出所有传递的参数
$@: 也会输出所有传递的参数，但是和$\*区别是假设输入参数为 1 2 3 ，$\* 会输出1 2 3 而$@会输出 "1" "2" "3"
####  getopts
可以指定参数，比如：
传递的时候就类似于  ./test.sh -a 1 -b 2 -c 3
脚本内容：
```
while getopts ":a:b:c:" opt
do
    case $opt in
        a)
        echo "参数a的值$OPTARG"
        ;;
        b)
        echo "参数b的值$OPTARG"
        ;;
        c)
        echo "参数c的值$OPTARG"
        ;;
        ?)
        echo "未知参数"
        exit 1;;
    esac
```
其中？可以用来处理位置参数 传递的参数也可以不处理 相对来说更灵活，不过还是 $0, 1感觉用着更舒服

### ssh隧道连接的三种方式（端口转发）
ssh -D 8080 user@root;
这时ssh会建立一个socket,去监听本地的8080端口，一旦有数据传向这个端口，就自动把他转移到ssh连接上去，发往远程主机，如果8080端口是一个不加密的端口，现在将变成加密端口（端口最好选择未占用的端口）；

ssh -L "本地端口:目标主机:目标主机端口" jumphost

ssh -R "远程主机端口:目标主机:目标主机端口" jumphost;

###  硬链接&软链接
linux文件由数据块和元数据两部分组成，其中数据块存放的文件的详细数据，而元数据则存放文件的一些附加信息如（文件名称，文件大小，类型，inode号等）
inode是文件的索引号，是linux系统实际查找文件的依据，查看inode号可通过两种方式：
1：stat filename/dir (stat命令用来显示文件/目录的详细信息)
2:  ls -i ( -i 用于列出文件的inode号)

何为硬链接：
硬链接即多个文件有相同的inode号，这些文件被称为硬链接；
既然有相同的inode号，linux是通过inode号来查找数据的，那么修改其中任何一个文件再查看其他的文件都会发现文件已更改，所以硬链接其实相当于c语言中指针的概念

如何创建：
link oldfile newfile 或者 ln oldfile newfile

特点及其限制：
不能交叉文件系统进行硬链接的创建（因为不同的文件系统可能存放相同的inode版本号）；
不存在的文件不能创建硬链接；
不能对目录进行创建硬链接 
（linux文件系统结构决定了不能对人为目录进行硬链接，因为linux在创建目录的时候其实会创建两个硬链接 . .. 分别代表本目录和上级目录的硬链接；
所以如何可以对目录出现硬链接，那么复制过去的目录 .. 究竟代表哪个目录呢，如果代表复制过去的上级目录，那么则可能会产生目录环）；
删除其中一个并不会影响其他的（所以可用来备份数据（其实是备份节点））；

何为软链接（又称符号链接）：
软链接 有自己独立的inode号，但是他的数据块中存放的其实是指向源文件的链接，有点类似于windows快捷方式的概念；

如何创建：
ln -s(symbol) oldfile file_symbol

特点及其限制：
可在软链接的基础上再进行创建软链接 ，最终都指向源文件；
可对不存在的文件或目录进行软链接的创建（但是对软链接文件进行cat的时候则会提示文件or目录并不存在，但如果之后将文件创建出来则会恢复正常）；
软链接可交叉文件系统，并且可对文件或目录进行创建；
创建软链接 源文件链接计数不会增加，硬链接则会加一；

