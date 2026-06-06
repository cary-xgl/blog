---
title: "MySQL的几种日志"
date: 2021-03-16
tags: ["MySQL"]
categories: ["技术"]
---

> binlog、redo log、undo log
<!--more-->

## mysql三种日志

binlog 是 server 层的，redo log 和 undo log 是引擎层的，主要说的就是 InnoDB 这套。

顺手记两个前置概念：

- 脏页：内存里的数据页和磁盘上不一致时，这个内存页就叫脏页
- InnoDB buffer pool：InnoDB 的缓冲区，里面会缓存数据页，也会管这些脏页什么时候刷盘

buffer pool 里有很多链表，这里只记两个：

- LRU list：保存从磁盘读进来的数据页，按最近最少使用淘汰
- flush list：里面放的都是脏页，按 `oldest_modification` 排序，后面刷盘时会用到

redo log 记的是物理变化，偏数据页这层；undo log 更接近逻辑变化，记的是一条数据怎么回退。

### binlog

常见场景：

* 主从复制：在master端开启binlog,然后将binlog发送到各个slave端，slave重放binlog达到数据一致
* 数据恢复：通过mysql binlog工具来恢复数据（binlog保存的是二进制文件）

binlog 什么时候刷盘，主要看 `sync_binlog`，取值范围是 `0-N`，默认是 `1`：

* 0:不强制要求，有系统自行判定选择合适的时机刷入磁盘
* 1：每次commit都会刷入磁盘
* N: 每隔n个事务刷入磁盘

binlog 的记录格式一般就是 `ROW`、`STATEMENT`、`MIXED` 这几种。

### redo log 重做日志

为什么需要 redo log。

因为 InnoDB 为了性能，不会每次都直接改磁盘，而是先改内存里的 buffer pool。这样机器一旦崩了，内存里的修改就没了，所以要先把这次修改记到 redo log 里。后面真出故障，再靠 redo log 把数据补回来。

所以 redo log 主要是用来保证事务持久性。

redo log 这东西，大概有几个要求：

* 数据量尽量小，不然会拖吞吐
* 要保证幂等，不然重放时容易重复恢复
* 记录粒度要合适，不能慢

格式类似于：（Page ID，Record Offset，(Filed 1, Value 1) … (Filed i, Value i) … )

redo 的核心顺序是：先写日志，再刷数据页。

redo log 分成两部分：

- redo buffer：内存里
- redo log file：磁盘上

MySQL 执行语句时，会先把相关内容写进 redo buffer，后面再找时机刷到磁盘日志里。

> 先写日志，再写数据页，这套就叫 WAL（Write-Ahead Logging）。

InnoDB 把 redo buffer 刷到磁盘 redo log 的策略，主要看 `innodb_flush_log_at_trx_commit`。

这里会先经过操作系统缓存，再由 `fsync()` 真正刷到日志文件。
<img src="write_log.png" alt="write_log" style="width: auto; max-height: 500px;">

* `0`：延迟写。由后台线程定时刷，性能更好，但这段时间里如果 DB 崩了，数据可能丢
* `1`：每次提交都写并刷，最稳，但磁盘交互最多
* `2`：每次提交先写到 OS 缓存，再定时刷盘。如果 OS 崩了，还是可能丢

不同策略下，commit 线程都会在这里有不同程度的等待。

mtr 就是 mini-transaction。

如果一次操作里要改多个地方，InnoDB 会先给它分一块内存，把这次原子操作相关的 redo 先记在里面，等操作结束后，再统一拷到 log buffer。
<img src="mtr.png" alt="mtr" style="width: auto; max-height: 500px;">

checkpoint 可以理解成一个“到这里为止已经刷盘”的位置。

redo log file 是循环写的，所以要不断推进 checkpoint，才能知道前面的空间是不是可以复用。

这里会涉及 LSN（Log Sequence Number）。redo log 有 LSN，数据页自己也有 LSN，恢复时就靠这个来判断这页数据到底要不要重放。

### undo log

undo log 主要是拿来回滚的。

比如一条 insert，对应的 undo 就可以理解成 delete。更新操作会更复杂一点，因为它还会牵扯版本链、可见性这些东西，也就是后面常说的 MVCC。

真正的删除清理一般交给 purge 线程去做，因为有些旧版本在事务还没结束前，可能还不能立刻扔。

insert 的 old version 没什么意义，所以这类 undo 在 commit 之后通常就可以释放。

所以 undo log 的作用主要是：

* 事务回滚
* MVCC

undo log 一般是在 DML 真正修改聚簇索引之前就先记下来的。

undo log 存在回滚段里。每个回滚段下面又会挂很多 undo log segment，再往下分配具体的 undo 页。
