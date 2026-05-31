---
title: "Java 集合与限流杂记"
date: 2026-05-31
tags: ["Java", "Guava", "限流"]
categories: ["技术"]
---

> 这一篇偏杂，但几块都还是 Java 日常里常碰到的东西。
<!--more-->

## 网关限流算法
为什么要做限流：

* 一方面是为了防止大量请求过来导致服务器过载，服务不可用
* 另一方面是防止一些网络攻击，比如某一时刻建立很多tcp连接导致正常的访问不可用

限流算法：

* 令牌桶算法：每隔多长时间就往桶里放token,相当于有个水龙头在不断往桶里加水，如果桶满了就不在加了；如果请求过多，多余的请求同样做拒绝处理
    * 令牌以固定的速率往桶里放
    * 多余的请求会被丢弃
* 漏桶算法：请求从外部流入水桶，水桶以一定的速率向外流出，桶的大小就是缓冲区的大小
    * 桶的大小：缓冲区（可以设置也可以不设置）
    * 漏斗大小：请求漏出的固定速率
    * 在桶满之后，请求有两种处理方式：一种是暂时截住上方的请求，等桶里的水出去一部分再放进来（相当于缓冲区），另一种是直接抛弃

可以看出令牌桶算法更适用与某一时刻突发流量的处理，但是平时的话，多余产生的token会被丢弃，浪费资源；而漏桶算法更平稳，如果某一时刻请求过多，会阻塞住。但对多余的请求可能返回503；

常见的nginx就采用优化过的漏桶算法，可以限制速率，也可以通过配置参数应对突发情况，

* burst参数：假设配置是5，速率是每秒一个请求的情况下，压测发过来10个请求，只有一个能处理成功。5个会阻塞至队列中等待消费，每隔一秒消费一个，剩下4个503拒绝处理
* nodelay参数：在上面的基础上配置了无需等待，就是说依然是4个被拒绝处理，但是可以同时处理1+5个请求，可以应对某时刻的突发情况

spring cloud gateway网关实现的限流算法：
基于令牌桶算法，可以对IP,用户，接口等限流

## forkjoin
为什么先尝试偷取，而不是处理自己队列的任务

## java中的日志框架
采用门面设计模式
slf4j是一套抽象的日志框架接口，在其底下的实现有log4j , logback , log4j2 推荐顺序由左及右为最新的框架，更为推荐log4j2,其中jdk也有一套实现jul

这样使用的话每个类都要加一条类似于 private static final Logger log = LoggerFactory.getLogger(AuroraQueueListener.class);
而使用lombok的话，只需要加一个注解@slf4j即可使用，因为他会在编译期间生成这个代码，并嵌入class文件之中
在开发期间因为要使用log变量，而idea如果不配置是识别不了这个变量的，【必须加上lombok插件才可以】，所以如果是对外提供的jar包，是不推荐用lombok注解的，内部用的话使用插件可以极大提高开发效率

## java中的异常
unchekced异常，也成为运行时异常，继承自runtimeexception的所有类
checked异常，除了上面的统称为检查时异常

from guava 异常处理Preconditions类：
Preconditions的异常类型问题 牵扯到设计准则，后面的章节‘Throwables’也提到了一点。一般准则认为，违反方法契约（包括方法所使用的对象或外部数据状态）时抛出UncheckedException，其定义方法的可用性范畴；而方法因为不可控原因无法履行契约，则抛出CheckedException。 所以Preconditions就跟它的名字一样，是用来定义方法契约的，这样方法才算完整地自描述和可重用了。**对设计理想的应用来说，Runtimeexception应该绝少触发**。当调用这些方法时，你可以根据领域对象的业务含义，在调用方预先作检查，比如bean-validator这样的手段。而详细去看bean-validator的定义时，你就会发现它完全撇清了检查和异常的概念。

Preconditions类和spring中的assert 类似，都是可控的检查时异常，而我们认为这种运行时异常应该是尽量少触发的，预期就应该是触发不了的，如上面说的一样；而检查时异常必须在编译期间处理，即必须把不可控的因素约定怎么处理，下层处理不了就抛给上层处理

## guava
### 不可变集合
为什么需要不可变集合：

* 保证线程安全性
* 提供给外部访问时是安全的
* 节省扩容检查等开销

首先jdk中的不可变集合比如
Collections.unmodifiableList(new ArrayList<>())，可以看到他是接受了一个list作为参数，内部的话是创建了继承自List的实现子类，但是有一个参数放置list，调用比如get方法还是拿的参数然后调取他本身的get方法，这样做有几个坏处：

* 作为参数传入的list可能是多线程下安全的，所以会有很多锁的开销，并且不可变集合其实是不用扩充缩减集合的，所以并不需要某些检查的开销
* 如果修改了原有list，那么其实还是不可变集合元素也发生了改变

guava提供的，每次创建一个不可变集合都是利用了copy或者clone操作，等于创建了一个新的list，所以没有jdk提供的不可变集合的缺点，但是因为本质上还是采用clone浅拷贝的方式进行，所以如果比如list对象里存在引用属性，那么这部分元素的修改还是会影响到现有集合

### 新集合类型
#### Multiset
继承自jdk collection接口，实现了类似于set的功能，不过会存储重复元素
比如size方法返回的是所有元素（包含每个重复元素）；count（elem）返回elem重复元素的数量，类似于一个统计数量的map<Integer-count, elem>

#### Multimap
类似于jdk中map<key, list<V>>,统计映射元素，multimap内部含有一个上述的结构，等于是封装了一层；对外提供put<key, V>的操作等；

#### BiMap
维护一个双向映射
map<K,V> <-> map<V,K> 本质上是基于map的，而map key 不能重复，所以对应到此特殊结构value也不能重复
内部采用内部类 视图的方式维护反转变量（不额外存储一份，所以对原有map的修改会影响到映射map）
inverse类只重写方法，变量采用外部持有的，如下
```
class {
    bimap$reverse inverse;
}
private final class Inverse extends IteratorBasedAbstractMap<V, K>    implements BiMap<V, K>, Serializable {  
    BiMap<K, V> forward() {    
        return HashBiMap.this;  .//指向外部变量
    }  
    @Override  public boolean containsKey(@Nullable Object value) {    
        return forward().containsValue(value);  
    }
    @Overridepublic BiMap<K, V> inverse() {  
        return forward();
    }
}
```

#### table
类似于Map<FirstName, Map<LastName, Person>>结构

### splitter joiner设计
可复用的连接/分割器
内部维护迭代器
通过this不断调用，返回新对象，新对象的比如strategy limit使用this对象的，然后返回一个新对象，并且独特的定义了trimmer，其他参数也类似，形成了一个流式的定义对象的操作，但每次经过流都会定义一个新的对象，是一个不断抛弃上层对象的过程
> 原笔记此处有一张配图，资源路径还没整理过来。

### ## java中的集合杂谈
### 易混淆的两个概念Iterable & Iterator
#### Iterable 真.顶层接口 （可迭代的）
> 原笔记此处有一张配图，资源路径还没整理过来。
常见的collection接口就继承自此接口
一个集合如果想要迭代比如遍历元素就必须继承这个接口，以表示自己是可迭代的，并且要返回一个特定的迭代器

### Iterator 迭代器
> 原笔记此处有一张配图，资源路径还没整理过来。
用来对集合中的元素进行操作
并且将这两者分离有个好处，就是如果一个集合需要实现多个迭代器，这样也方便
但是如果将迭代器和上述接口集成在一起，那么集合只支持单迭代器了

### Spliterator 迭代器
> 原笔记此处有一张配图，资源路径还没整理过来。
多线程迭代器，Iterator是供单线程下使用的迭代器，而此则是可分割多个线程协同处理的迭代器
常用函数
Characteristics（特征）：

* ORDERED 顺序排列的，按照元素输入的顺序
* DISTINCT 元素不可重复
* IMMUTABLE 不可变的
* NONNULL 元素非null
* SIZED ： 可以看到spliterator有一个默认的实现方法getExactSizeIfKnown，用来返回迭代器确定元素的大小【return (characteristics() & SIZED) == 0 ? -1L : estimateSize();】，如果元素大小是可确定的返回 估算大小（等于实际大小） ，否则是不可预知的
* SORTED 需传入一个比较器用来排序
* SUBSIZED： 分割后的迭代器也具有sized特性
* CONCURRENT 元素可在多线程下操作

tryAdvance：尝试消费元素，如果元素已经被消费完了，返回false
trySplit: 尝试分割一个新的子迭代器
EstimateSize：返回元素总数估值 （主要作用是用来判断是否还要分割，比如如果估算值是1，那么程序一般就以单线程运行了，否则视情况是否分割）
forEachRemaining：一般会提供一个默认的实现类似于下面
```
do{}while (tryadvance(action))
```

### Spliterators
内部维护了一系列静态迭代器，供外部调用

### collection设计原则
> 原笔记此处有一张配图，资源路径还没整理过来。
collection是继承自Iterable接口的，可以看到二者都定义了iterator接口，其中collection并未对此接口做啥操作，这里主要是为了向使用者清晰说明，继承此接口要返回一个迭代器
此外还提供了供流使用的stream 和 parallelStream两个方法供下层重写
retainall(collection) 仅保留collection的元素，删除其他的,如果删除了则返回true，否则返回false,最后的结果是求的交集
spliterator: 并行迭代器

### list
> 原笔记此处有一张配图，资源路径还没整理过来。
新方法：
replaceAll: 接受一个function<T, T> ,对所有元素进行统一操作返回一个相同类别的元素
sort：接受一个比较器，返回排序好的元素
listIterator： 返回list迭代器; 有参（index）代表索引，从此索引开始返回迭代器
sublist: 截取区间，返回一个新的list**【注意：这里的list和父list是同一个对象，修改父类的对象会影响到子list,可以看出并不是创建真的新list,只是在原有list上加了索引数】**，不会对原有list进行操作 参数（start ,end），包含start索引，不包含end索引
> 原笔记此处有一张配图，资源路径还没整理过来。
可以看到list提供了一个默认的并发迭代器，并且并发迭代器的特征是**有序的**

### AbstractList
> 原笔记此处有一张配图，资源路径还没整理过来。
> 原笔记此处有一张配图，资源路径还没整理过来。
Itr迭代器方法：
此抽象实现类采用快速失败的策略，也就是不会单独维护一份集合数据，采取的还是外部的数据，每次进行next或者remove的时候需要先检查外部元素数量有没有变化（具体值不需要考虑），因为如果外部已经删除了元素，那么迭代器取的时候可能回数组越界等；
迭代器在迭代的时候可以进行remove的操作，迭代器内部会维护指针指向当前迭代的元素，因为迭代器是不可逆的，所以迭代的时候只能选取移除前一个元素，**并且不支持继续向前移动，开始迭代的时候调用remove必然会失败，因为此时没有元素在前面**

listItr在上述方法中加入了previous方法，可以查看前一个元素；add,set等方法，同样采取快速失败的策略（一般不推荐在迭代器里进行增删等操作）

sublist子类就是上层list调用sublist得到的实例对象

## 流再次探寻
//todo

### Linux IO模式及 select、poll、epoll

### 文件描述符

