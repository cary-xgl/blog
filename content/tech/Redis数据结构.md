---
title: "Redis 数据结构"
date: 2026-05-31
tags: ["Redis"]
categories: ["技术"]
---

> Redis 先从底层数据结构往上看，很多现象会更好理解。
<!--more-->

### SDS字符串
数据结构
* 已使用
* 空闲
* char数组

所以可以看出获取字符串长度为O(1)
api相比于c来说，安全，因为如果c字符串没有先进行扩容的话可能造成缓存区溢出
遵从C语言字符串规范，末尾结束符相同，可以重用部分c语言函数
内存惰性释放

### 链表
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
可以看出是一个双端链表，并且用一个list结构做了个整合，似的获取头结点和尾结点 以及获取链表长度都是O(1)时间复杂度

### 字典Map
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
hash扩容：
2倍扩容或收缩
ht[0]rehash到ht[1]中，重新计算完成之后ht[1]变为ht[0],同时清空原有的
什么时候发生扩容（收缩同理）：

* 没有执行BGSAVE命令或者BGREWRITEAOF
* 或者服务器目前正在执行BGSAVE命令或者BGREWRITEAOF命令，并且哈希表的负载因子大于等于5。

并且rehash是渐进式的，就是说不是在rehash的过程中不能操作数据，而是比如说增加数据只在ht[1]进行；删除，更新在两个hash表中进行；找先在ht[0]进行，没有再去ht[1中查找，直到执行完成把标志位置为-1表明此rehash完成

### 跳跃表 skiplist
有序的数据结构：节点上维护多个指向其他节点的指针，达到快速访问节点的目的
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
从前往后遍历的时候只需要每个节点保存一个层级用来记录后继节点即可，length为1

跳跃表的所有节点都是按照分值从小到大排序，分值相同的节点按照ele的自然排序来决定
跳跃表的插入 查找 删除的时间复杂度平均是o(logn)
> 原笔记此处有一张配图，资源路径还没整理过来。
如上图所示，如果层级1跳跃1；层级2跳跃2；层级3跳跃4...可以相当于一个二分查找；空间复杂度相应的提升n/2+n/4...最后得出来是o(n),并且可以提高层级跳跃数量

**基本思想是上面列出的，问题是插入或者删除不可能一直维护索引表的结构，代价太大，所以有一种新方法基本思想是每插个元素，根据一个概率函数生成对应的层级，因为redis小数据量就算索引不太合理也不会影响太大，而元素多起来概率上则趋近于一个二分，三分，四分跳跃表（redis默认是0.25）
如图是redis插入节点的层级判断函数，最大64，删除则不用考虑**
跳表相对红黑树的优势：范围查找，红黑树速度无法保证，跳表是有序的则可以保证，其他插入删除场景下时间、空间复杂度基本相同和红黑树比较
> 原笔记此处有一张配图，资源路径还没整理过来。

### 压缩列表 ziplist
压缩列表是双端链表的一种变种实现，是连续的内存结构，适用于小数据量的场景
比正常的双端列表更节省内存
### 对象
根据上面列出的数据结构衍生出的几种基本类型
一般来说key总是一个string
value可以是list string hash 等
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
redis默认会初始化0-9999的整数字符串对象，当服务器需要用到时会增加引用值（参数可配）
为什么不共享相同的字符串对象呢（非0-9999）？
尽管共享字符串可以节省内存，但是如果一个字符串包含的值越复杂，则验证消耗的cpu时间就会越多

#### String

#### list
#### hash
list和hash都可以采用ziplist存储，--满足一定的条件（键值都小于64字节，数量小于512，支持配置）
当超过这个阈值之后就会变为相应的双端链表或者hashtable来存储
#### set
小数据量并且都是整数可以用intset存储，超过阈值转化为具体的hash结构存储（不能用ziplist,因为去重并且随机存储无序）
#### zset(有序集合）
小元素量可以用ziplist 大数据量用skiplist加字典实现
skiplist主要是可以用来根据score做范围查询；而如果想根据成员查找对应的score则时间复杂度为o(logn);但是用字典则查找的时间复杂度是O(1),所以会用两个数据结构来保存；
并且这两个数据结构会共享节点，所以增加的空间并不会很多

## 数据库
```
// key-value存储结构
/* Redis database representation. There are multiple databases identified
 * by integers from 0 (the default database) up to the max configured
 * database. The database number is the 'id' field in the structure. */
typedef struct redisDb {
    dict *dict;                 /* The keyspace for this DB */
    dict *expires;              /* Timeout of keys with a timeout set */
    dict *blocking_keys;        /* Keys with clients waiting for data (BLPOP)*/
    dict *ready_keys;           /* Blocked keys that received a PUSH */
    dict *watched_keys;         /* WATCHED keys for MULTI/EXEC CAS */
    int id;                     /* Database ID */
    long long avg_ttl;          /* Average TTL, just for stats */
    list *defrag_later;         /* List of key names to attempt to defrag one by one, gradually. */
} redisDb;

```
### 过期key删除策略

* 定时删除：创建一个定时器，让定时器在键的过期时间来执行对key的删除操作（主动删除），对内存友好，但是对cpu不友好，过期键比较多的时候，cpu的时间可能会非常紧张，cpu的十几件应尽可能用在处理客户端的请求上（目前不推荐使用）
* 惰性删除：每次从键空间获取的时候，都要进行检查，如果过期则删除，否则返回该键（主动删除）（浪费内存，可能造成内存泄漏--有很多键用不到，但一直没被删除）
* 定期删除：每隔一点时间，程序对数据库进行一次检查，具体删除多少，由具体的算法决定（被动删除）（推荐使用，根据具体的业务确定执行的时长和频率）

redis采用惰性删除+定期删除的策略

### rdb 过期值的处理
生成rdb文件的时候（执行save or bgsave) ,已过期的键不会被保存到文件中去
载入rdb文件的时候 如果是主服务器 则会对文件key进行检查，过期的不会被保存进去；对于从服务器来说，不会检查，全部载入，不过主从同步的时候 从服务器会被清空，所以影响不大

### aof 过期值的处理

