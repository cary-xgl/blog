---
title: "Maven 笔记"
date: 2026-05-31
tags: ["Maven"]
categories: ["技术"]
---

> Maven 这块以坐标、属性和冲突处理为主，够用就先记下来。
<!--more-->

## maven结构
maven坐标：（groupid[分组信息]，artifactid[标识符]， version[时间戳]）此三者可唯一定义一个maven依赖

## maven 属性
### profile
profiles的独特之处在于
它们不定义项目构建环境的设置，而是告诉Maven在不同环境下如何做出反应

### dependencymanagement
版本号的管理：
统一管理项目的版本号，确保应用的各个项目的依赖和版本一致，才能保证测试的和发布的是相同的成果，因此，在顶层pom中定义共同的依赖关系。同时可以避免在每个使用的子项目中都声明一个版本号，这样想升级或者切换到另一个版本时，只需要在父类容器里更新，不需要任何一个子项目的修改；如果某个子项目需要另外一个版本号时，只需要在dependencies中声明一个版本号即可。子类就会使用子类声明的版本号，不继承于父类版本号。

相对于dependencyManagement，所有生命在dependencies里的依赖都会自动引入，并默认被所有的子项目继承

## Q&A
### 如何解决maven冲突
optional; exclusions

optional定义过的依赖不会被子类继承
为什么要用到optional呢？
官方文档上这样解释：
Optional dependencies save space and memory. They prevent problematic jars that violate a license agreement or cause classpath issues from being bundled into a WAR, EAR, fat jar, or the like.
optional定义过的依赖会节省空间和内存，并且可以有效防止有问题的jar？

exclusions用来排除传递依赖过来的其他依赖；
比如A依赖B,B依赖于C,D,
A通过exclusion排除CD，则不会依赖CD，对于依赖冲突时排除依赖比较好用

通过这种方式控制依赖，保证了依赖关系图是可预测的，如果希望统一版本处理，则应该可以通过强制依赖或者禁用依赖（可控制某一版本）来处理；

