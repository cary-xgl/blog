---
title: "Redis 数据结构"
date: 2021-04-18
tags: ["Redis"]
categories: ["技术"]
---

> Redis 常用底层数据结构
<!--more-->

## SDS 字符串

结构里主要有这几个东西：

* 已使用长度
* 空闲长度
* `char` 数组

所以拿字符串长度是 `O(1)`。

它比 C 里的裸字符串安全一些。如果没有提前扩容，C 字符串很容易写出缓冲区。

它也保留了 C 字符串末尾结束符的习惯，所以一部分 C 函数还能复用。

内存释放这块也是惰性的。

## 链表
```
typedef struct listnode{
    struct listNode * pre;
    struct listNode * next;
    void * value;
}listnode

typedef struct list {
    listNode *head;
    listNode *tail;
    void *(*dup)(void *ptr);//用于复制结点值
    void (*free)(void *ptr);//用于释放结点值
    int (*match)(void *ptr, void *key);//是否与此结点值匹配
    unsigned long len;
} list;

```
可以看出这是个双端链表，又额外用一个 `list` 结构把头尾节点和长度都包起来了，所以拿头节点、尾节点，还有链表长度，都是 `O(1)`。

## 字典 Map
```
//hash表
typedef struct dictht {
    dictEntry **table;//hash数组
    unsigned long size;//hash表大小
    unsigned long sizemask;//掩码 也即size-1，用于计算索引
    unsigned long used;//已使用结点的数量
} dictht;

typedef struct dictEntry {
    void *key; //键
    //值
    union {
        void *val;
        uint64_t u64;
        int64_t s64;
        double d;
    } v;
    struct dictEntry *next;//hash冲突时的链表,链地址法与java hashmap以前使用的类似
} dictEntry;

//字典
typedef struct dict {
    dictType *type;//类型特定函数，见下面
    void *privdata;//参数，用于传给上面的特定函数的可选参数
    dictht ht[2];//hash表，一般来说只会使用ht[0],只有rehash的时候才会使用ht[1]
    //记录rehash的进度
    long rehashidx; /* rehashing not in progress if rehashidx == -1 */  
    //标记作用于当前字典的迭代器的使用数量，大于0则不能进行rehash
    unsigned long iterators; /* number of iterators currently running */
} dict;

typedef struct dictType {
    //计算hash值
    uint64_t (*hashFunction)(const void *key);
    //复制键
    void *(*keyDup)(void *privdata, const void *key);
    //复制值
    void *(*valDup)(void *privdata, const void *obj);
    //对比键等..
    int (*keyCompare)(void *privdata, const void *key1, const void *key2);
    void (*keyDestructor)(void *privdata, void *key);
    void (*valDestructor)(void *privdata, void *obj);
} dictType;

```
扩容时一般是 2 倍扩容，收缩也是类似的思路。

`ht[0]` 会慢慢 rehash 到 `ht[1]`。等迁完以后，`ht[1]` 变成新的 `ht[0]`，原来的再清掉。

什么时候会扩容，收缩也是差不多的判断：

* 没有执行BGSAVE命令或者BGREWRITEAOF
* 或者服务器目前正在执行BGSAVE命令或者BGREWRITEAOF命令，并且哈希表的负载因子大于等于5。

Redis 的 rehash 是渐进式的，不会因为正在 rehash 就把整个字典停住。

比如新增只会往 `ht[1]` 里放；删除和更新要看两个表；查找时先查 `ht[0]`，没有再去 `ht[1]`。等全部迁完，再把标志位改成 `-1`，表示这轮 rehash 结束。

## 跳跃表 skiplist

它是个有序结构。节点上会维护多层指针，目的就是少走几步，尽快跳到目标位置。
```
typedef struct zskiplistNode {
    //值
    sds ele;
    //分值
    double score;
    struct zskiplistNode *backward;
    //层级，就是一个数组，初始化的时候根据幂次定律随机一个1-32的值作为数组大小!跳跃核心
    //排序根据跨度，层级可以当做第几级索引来理解
    struct zskiplistLevel {
        //前进指针
        struct zskiplistNode *forward;
        //跨度，距离当前节点的距离
        unsigned long span;
    } level[];
} zskiplistNode;

typedef struct zskiplist {
    struct zskiplistNode *header, *tail;
    unsigned long length;//表中节点的数量
    int level;//表中层数最大的节点的层数
} zskiplist;

```
从前往后遍历时，每个节点只要记住自己的后继节点就够了，`length` 为 1。

跳跃表里的节点会按分值从小到大排，分值相同再按 `ele` 的自然顺序排。

插入、查找、删除，平均时间复杂度都是 `O(logn)`。

<img src="image.png" alt="跳表" style="width: auto; max-height: 500px;">
如果把每一层理解成不同密度的索引，其实就有点像在做分层查找。层级越高，单次跨得越远，空间也会多一些，但整体还是 `O(n)`。

问题在于，插入和删除时不可能每次都硬维护出一套特别整齐的索引，那样代价太高。

Redis 用的是另一种做法：每插一个元素，就按概率决定它有多少层。数据少的时候，就算层级不太理想，影响也不大；数据多起来以后，整体上又会慢慢接近一个比较均匀的跳表结构。Redis 默认概率是 `0.25`。

跳表相对红黑树的一个好处，是范围查找会更顺一些。其他像插入、删除这类场景，和红黑树差得不大。


## 压缩列表 ziplist

压缩列表可以看成双端链表的一种变种实现，用的是连续内存，更适合小数据量场景。

和正常双端链表比，会更省内存。

## 对象

Redis 上层那些基本类型，底下就是靠前面这些结构撑起来的。

一般来说，`key` 总是一个 string。

`value` 可以是 list、string、hash 这些。
```
typedef struct redisObject {
    unsigned type:4;//保存具体的类型 list hash等
    unsigned encoding:4;
    //保存最后一次访问键值对的时间，可用于内存不足进行回收的策略
    unsigned lru:LRU_BITS; /* LRU time (relative to global lru_clock) or
                            * LFU data (least significant 8 bits frequency
                            * and most significant 16 bits access time). */
    int refcount;//引用计数，无引用则回收，因为redis的对象都是自己创建，并且指向底层的指针就是下面这个，底层的指针没有指向此数据结构的的引用，所以不存在循环引用
    void *ptr;//指向底层数据结构的指针
} robj;

```
Redis 默认会初始化 `0-9999` 这些整数字符串对象，后面要用时就直接加引用，参数也可以配。

为什么不把其他相同字符串对象也都共享掉？

因为共享字符串确实省内存，但字符串越复杂，判断和维护共享关系的 CPU 成本也会越高。

### String

### list

### hash

list 和 hash 都可以用 ziplist 存，但要满足一些条件，比如键值都小于 64 字节，数量小于 512，这些也都支持配置。

超过阈值以后，就会换成对应的双端链表或者 hashtable。

### set

小数据量而且元素都是整数时，可以用 intset。

超过阈值后会转成真正的 hash 结构。这里不能用 ziplist，因为 set 本身要去重，而且是无序的。

### zset（有序集合）

元素少时可以用 ziplist，数据量大了就用 skiplist 加字典。

skiplist 主要是方便按 score 做范围查找；如果是按成员查 score，单用 skiplist 时间复杂度是 `O(logn)`，但字典可以做到 `O(1)`。

所以 Redis 干脆两个都留着。

而且这两个结构会共享节点，所以额外空间也没有想象中那么大。
