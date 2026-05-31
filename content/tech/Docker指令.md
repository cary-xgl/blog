---
title: "Docker 指令"
date: 2026-05-31
tags: ["Docker"]
categories: ["技术"]
---

> 先把常用命令和 Dockerfile 相关的东西收在一起，后面查起来方便。
<!--more-->

### docker container
容器相关指令：
当利用 docker run 来创建容器时，Docker 在后台运行的标准操作包括：
检查本地是否存在指定的镜像，不存在就从公有仓库下载利用镜像创建并启动一个容器分配一个文件系统，并在只读的镜像层外面挂载一层可读写层从宿主主机配置的网桥接口中桥接一个虚拟接口到容器中去从地址池配置一个 ip 地址给容器执行用户指定的应用程序执行完毕后容器被终止

启动容器：
docker <container --可省略> start <containerid>
暂停容器：
docker <container --可省略> stop<containerid>
重启容器:
docker <container --可省略> restart <containerid>
列出容器：
docker container ls -a/docker ps -a

docker 加入环境变量配置文件
docker run --env-file ./my_env

容器守护态运行：
docker run -d ubuntu:18.04 /bin/sh -c "while true; do echo hello world; sleep 1; done"
-d:把容器的输出结果在后台打印，不会打印在宿主机界面上
可通过docker container logs [container ID or NAMES] 查看容器日志

进入容器：
docker exec/attach
exec ：exit后不会导致容器的停止
attach：exit后会导致容器的停止
docker exec -it containername/id bash

删除容器：
docker container rm
-f：可以删除一个正在运行中的容器
docker container prune --清理所有处于终止状态的容器

### docker compose

### docker images
docker pull（拉取镜像文件）
docker pull [选项] [Docker Registry 地址[:端口号]/]仓库名[:标签]
仓库名:默认是<用户名>/<软件名>,如果不给出用户名，则默认为library,也就是官方镜像
docker仓库地址：如果不给出地址，默认配置好的镜像仓库地址

docker run（以一个镜像为基础启动一个容器）
docker run -it --rm ubuntu:18.04 bash
-i:交互式操作
-t:终端terminal
--rm:容器退出之后自动删除这个容器（进入终端之后exit退出就自动把此容器删除掉）
bash:放在镜像后面的是命令，这里我们希望有一个交互式shell，所以用bash

docker image（列出镜像文件）
docker image ls = docker images
docker image ls -q : 列出镜像id（可用于批量操作镜像）

docker image rm（删除镜像文件）
docker image rm [选项] <镜像1> [<镜像2> ...]

docker commit(推送新镜像文件，慎用)
docker commit 意味着所有对镜像的操作都是黑箱操作，生成的镜像也被称为 黑箱镜像，换句话说，就是除了制作镜像的人知道执行过什么命令、怎么生成的镜像，别人根本无从得知。而且，即使是这个制作镜像的人，过一段时间后也无法记清具体在操作的。虽然 docker diff 或许可以告诉得到一些线索，但是远远不到可以确保生成一致镜像的地步。这种黑箱镜像的维护工作是非常痛苦的。
而且，回顾之前提及的镜像所使用的分层存储的概念，除当前层外，之前的每一层都是不会发生改变的，换句话说，任何修改的结果仅仅是在当前层进行标记、添加、修改，而不会改动上一层。如果使用 docker commit 制作镜像，以及后期修改的话，每一次修改都会让镜像更加臃肿一次，所删除的上一层的东西并不会丢失，会一直如影随形的跟着这个镜像，即使根本无法访问到。这会让镜像更加臃肿。

### docker volumn
* 创建一个数据卷：
docker volume create my-vol
* 查看所有的数据卷：
docker volume ls
* 删除数据卷：
docker volume rm my-vol
* 清理所有数据卷：
docker volume prune
* 查看web容器的详细信息
docker inspect web

### docker cp
* 从容器向宿主机拷贝文件
docker cp container:/usr/local/tomcat/Logs /root/Logs

### docker logs
* 导出容器的日志到文件中
docker logs containerId > container_file.logs

## Dockerfile
Dockerfile 是一个文本文件；
其内包含了一条条的 指令(Instruction)；
每一条指令构建一层镜像，因此每一条指令的内容，就是描述该层应当如何构建；

COPY 复制文件
COPY [--chown=<user>:<group>] <源路径>... <目标路径>COPY [--chown=<user>:<group>] ["<源路径1>",... "<目标路径>"]
比如：COPY package.json /usr/src/app/
COPY 指令将从构建上下文目录中 <源路径> 的文件/目录复制到新的一层的镜像内的 <目标路径> 位置。

add命令大体和copy命令相同：
当需要复制文件的时候用copy；当需要自动解压缩的场合用add；
因为add语义并不是特别明确，可能会增加一些无用的工作；

CMD容器启动命令:
分为exec格式 和shell 格式；

ENTRYPOINT 入口点大体上通cmd命令，可以进行预处理的工作比如
ENTRYPOINT ["docker-entrypoint.sh"]

ENV 设置环境变量
ENV <key> <value>ENV <key1>=<value1> <key2>=<value2>...

ARG 构建参数
ARG <参数名>[=<默认值>]
构建参数和 ENV 的效果一样，都是设置环境变量。所不同的是，ARG 所设置的构建环境的环境变量，在将来容器运行时是不会存在这些环境变量的

VOLUMN 卷挂载
容器运行时应尽量保证容器存储层不发生写操作，对于数据库需要动态保存数据之类的应用，则应该把存储挂载出来

Expose 和 -p <宿主端口>:<容器端口>
-p映射端口，将容器内的开发端口通过宿主机映射给外界访问；
Expose只是声明要开启什么端口，并不会自动映射；

Workdir指定工作目录：
User指定当前用户；

Healthcheck执行健康与否检查；
可设置时间间隔，临界值等
比如：HEALTHCHECK --interval=5s --timeout=3s （每5秒检查一次，超过三秒没响应就算失败）

写好Dockerfile之后就可以运行命令直接打包成docker镜像
docker build -t imageName (-t 类似于tag)

Onbuild 待续

### Run vs Entrypoint vs Cmd
run是新建了docker的一层，通常用于安装一些软件
CMD 设置默认命令行 或参数，可以在 docker 容器运行时从命令行覆盖。比如docker run ... image tail -f /dev/null,如果最后跟了比如（tail -f /dev/null）命令则执行跟随的命令（cmd被忽略），否则执行cmd里面默认的命令
ENTRYPOINT 类似于cmd，区别是entrypoint的命令不会被忽略，优先选择entrypoint

上述三种命令都可以用shell(脚本)的形式，或者exec 的形式展现
比如shell：> 原笔记此处有一张配图，资源路径还没整理过来。
比如exec：> 原笔记此处有一张配图，资源路径还没整理过来。
```
ENV name John Dow
ENTRYPOINT ["/bin/echo", "Hello, $name"]
```
当命令直接执行类似于上述代码块的形式，输出的变量不会做替换，是直接调用的echo可执行程序， 不会进行shell的处理，如果想正确的处理，可以调用
ENTRYPOINT ["/bin/bash", "-c", "echo Hello, $name"] 指定shell解释器

下面可以看出cmd变量被覆盖了，但entrypoint变量不会被覆盖 
> 原笔记此处有一张配图，资源路径还没整理过来。

## Q&A
### docker save [Repository] 注意的地方
当docker保存镜像的日后，比如打个压缩包
docker save reg2.hypers.cc/base/insight-web:1.2.0 | gzip -c > insight-web.tar.gz
如果镜像后面不跟版本号（latest也省略），则会把本地所有存在的版本都打进去压缩（包括none）

