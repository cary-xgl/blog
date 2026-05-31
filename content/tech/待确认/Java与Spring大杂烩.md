---
title: "Java 与 Spring 大杂烩"
date: 2026-05-31
tags: ["待确认", "Evernote"]
categories: ["技术"]
---

> 这部分覆盖面太大，强拆容易把上下文拆散，先保留原笔记。
<!--more-->

## java-base
## abstract class & interface
抽象类可以定义变量； 
接口只能定义常量；

## lambda
@see https://blog.csdn.net/ioriogami/article/details/12782141

## 约定大于配置
约定优于配置，也称作按约定编程，是一种软件设计范式，旨在减少软件开发人员需做决定的数量，获得简单的好处，而又不失灵活性。
本质是说，开发人员仅需规定应用中不符约定的部分。例如，如果模型中有个名为Sale的类，那么数据库中对应的表就会默认命名为sales。只有在偏离这一约定时，例如将该表命名为”products_sold”，才需写有关这个名字的配置。
如果您所用工具的约定与你的期待相符，便可省去配置；反之，你可以配置来达到你所期待的方式

动机：设计不好的框架通常需要多个配置文件，每一个都有许多配置，太多参数的配置文件通常是过度复杂应用设计的代码

使用：按照一般的规则，我们不希望造出一个奇怪的类，而是希望在运行或加载类的时候给他默认的缺省行为，如果有不符合的，那么可以通过类似继承的方式对类进行重写，以达到个性化设计的目的

## exception & error (base on Throwable)

## UUID
java.util.UUID包下（生成出来的uuid是带'-'分隔符的，可以手动去掉） UUID.randomUUID()

## 面向对象6大设计原则
### 里式替换原则（LCP）
里式替换原则：派生类型（子类）必须能替换掉他们的的基类（父类），而使用者无需了解其中的差异
最早的定义："这里需要如下的替换性质：若对类型S的每一个对象O1,都存在一个类型T的对象O2，使得在所有针对T编写的程序P中，用O1替换O2后，程序P的行为功能不变，则S是T的子类型。"

就是对于基类中定义的所有方法或行为，子类都不可对其进行更改，而只能派生出新的行为，这样才是做到真正的复用；

是否违反了java多态性?
不违反，因为子类可以重写父类的方法，只是不能改变行为，可能是实现方式的改变，比如父类定义了一个排序方法（冒泡排序实现），子类在继承的时候就可以选择性优化，比如用快排或堆排，
但是不能改变行为，比如重写的方法可能改变了排序的方向啥的，这种就违反了里式替换原则

## 类加载过程
java类加载机制：
一般分为七个阶段
加载->验证->准备->解析->初始化->使用->卸载
加载、验证、准备和初始化这四个阶段发生的顺序是确定的，而解析阶段则不一定，它在某些情况下可以在初始化阶段之后开始，这是为了支持Java语言的运行时绑定（也成为动态绑定或晚期绑定）。另外注意这里的几个阶段是按顺序开始，而不是按顺序进行或完成，因为这些阶段通常都是互相交叉地混合进行的，通常在一个阶段执行的过程中调用或激活另一个阶段。
静态绑定：比如static final 构造方法等都属于静态绑定
动态绑定：就是后期绑定，一般在运行时期根据对象的类型进行绑定

> 原笔记此处有一张配图，资源路径还没整理过来。
### 加载阶段：
分为图中这四种类加载器，这种模型我们称之为双亲委派模型，上层的类成为下层类的父类（并不是严格意义上继承的父类，而是通过一种组合关系复用父加载器的代码），当一个类加载时选择一个类加载器，而这个类加载器会把请求传给父类，一直传到顶层，此时会从顶层类加载器中寻找有无此类，若是有，则加载，没有，再向下传请求，这样做的好处是设计了一种层次级的优先关系，保证了Java程序的稳定性，保证了各种类加载器加载的都是同一个类
其中启动类加载器不是继承的java.lang.ClassLoader，因为他在jvm内部使用c/c++实现，而不是用java实现的

### 验证阶段
确保当前的class文件中字节流的数据符合当前虚拟机的要求，不会危害虚拟机的安全
大致会完成以下四个阶段
文件格式的验证、元数据的验证、字节码验证和符号引用验证

### 准备阶段
此时进行的是为类变量进行内存分配（ 不包括实例变量），并进行初始赋值（例子：此时的初始赋值不是说执行a=1这个操作，而是给变量a一个初始值0）
如果是被static 和 final同时修饰的，则必须在声明的时候就为其赋初始值，并且在此阶段变量就会被赋值（例如：static final int d=4；则准备阶段就会为d赋值4，并放入常量池中）；而如果只是final声明的变量，则也可以在类初始化的时候进行赋值
```
public class Test{
    static int a=1;//静态变量也称类变量
        int b=2;//成员变量也称实例变量，全局变量
        public void methodTest（）{
        int c=3;//局部变量，必须赋值才能使用
    }
}
```

### 解析阶段：
解析阶段是将常量池中的符号引用转化为直接引用的过程 ，而解析阶段可以开始于初始化阶段之前，也可以在其之后，虚拟机会根据需要去判断到底是在类加载器加载时就解析（初始化之前），还是在需要的时候再去解析（初始化之后）。
对一个符号引用进行多次解析是很常见的事情，虚拟机会将第一次解析的结果进行缓存，避免重复解析
> 原笔记此处有一张配图，资源路径还没整理过来。

### 初始化阶段：
Java虚拟机规范中严格规定了有且只有五种情况必须对类进行初始化：
1、使用new字节码指令创建类的实例，或者使用getstatic、putstatic读取或设置一个静态字段的值（放入常量池中的常量除外，也就是说当调用静态final变量时不会触发类的初始化），或者调用一个静态方法的时候，对应类必须进行过初始化。
2、通过java.lang.reflect包的方法对类进行反射调用的时候，如果类没有进行过初始化，则要首先进行初始化。
3、当初始化一个类的时候，如果发现其父类没有进行过初始化，则首先触发父类初始化。
4、当虚拟机启动时，用户需要指定一个主类（包含main()方法的类），虚拟机会首先初始化这个类。
5、使用jdk1.7的动态语言支持时，如果一个java.lang.invoke.MethodHandle实例最后的解析结果REF_getStatic、REF_putStatic、RE_invokeStatic的方法句柄，并且这个方法句柄对应的类没有进行初始化，则需要先触发其初始化。
```java

//父类的父类
public class SuperSuperClass {
    //静态块，这个类初始化时会调用
    static{
        System.out.println("父类的fu类初始化！");
    }
    //静态类变量
    static SuperSuperClass s = new SuperSuperClass();
    SuperSuperClass(){
        System.out.println("父类的fu类构造方法初始化！");
    }
}

//父类
public class SuperClass extends SuperSuperClass{
    //静态变量value
    public static int value = 777;
    //静态块，父类初始化时会调用
    static{
        System.out.println("父类初始化！");
    }
}

//子类
public class SubClass extends SuperClass{
    //静态块，子类初始化时会调用
    static{
        System.out.println("子类初始化！");
    }
}

//主类、测试类
public class NotInit {
    public static void main(String[] args){
        System.out.println(SubClass.value);
    }
}
//输出：（可以看到子类并没有初始化，并且静态变量在一个类中的加载有顺序（从上往下））
//父类的fu类初始化！
//父类的fu类构造方法初始化！
//父类初始化！
//777

```
## SimpleDateFormat线程不安全
因为在进行格式化的的时候用到了线程间共享的全局变量
所以在并发环境下可能导致日期不精确

## 集合类
ArrayList:
arrayList是不加锁的，所以在多线程下可能会出现安全问题，此时可以CopyOnWriteArrayList解决问题

CopyOnWriteArrayList：
适用场景：读多写少，并且对数据实时性要求不高，CopyOnWriteArrayList会满足数据的最终一致性
实现原理：和ArrayList一样，都是内部维护一个数组，但每次新增元素或删除元素都会开辟一段新的内存空间，把原有的数组复制一份放过去，操作完成之后把指针指向新的内存空间，原有的会被虚拟机回收掉，内部采用ReentrantLock锁实现多线程之间的顺序访问（FIFO,可重入锁）

## 自动拆箱，装箱
自动拆装箱就是将原始类型值转化为相应的对象，或者将对象转化为相应的原始类型
byte short char int long float double boolean
Byte Short Charater Integer Long Float Double Boolean

注意： 因为自动装箱会隐式创建对象，如果在一个循环体内，会创建许多无用的对象，增加GC压力，拉低程序性能，所以要注意代码的编写

### 引申问题：为什么需要包装类呢
包装类解决了两个问题：
基本类型无法用null,以int举例，0 != null,null可以用来表示一些无意义的值或者用来表示一种异常情况
基本数据类型无法加入集合，集合使用的广泛性也推动了包装类的发展
* 包装类 jdk1.0 
* 集合概念 JDK1.2 
* 自动拆装箱 JDK1.5
并且从类型上来说 int是面向过程的语言 Integer面向对象 更符合java的思想

## 解读volitile
并发的三大概念：
原子性：一套操作要么全部执行成功，要么全部执行失败
可见性：当修改了一个变量之后，对其他的cpu来说如果缓存了该变量的地址，那么会使地址无效
有序性：禁止指令的重排序

volitile关键字实现了可见性（当触发变量的修改时 其他cpu会通过嗅探来监测变量的变化，如果变化则内存地址失效）
有序性（会在当前编译指令前加**Lock指令**作为内存屏障，防止指令重排序（jvm编译会优化指令执行顺序，单线程情况下结果不会发生任何改变，多线程下可能产生一定的影响））

最后的原子性volitile无法保证，因为他是基于无锁结构实现的，所以碰到a++这种执行
* 从内存中读取变量a
* 执行++操作
* 写回内存
所以是三个操作，可以通过cas操作实现，cas底层是c++实现的
通过cpu指令可以把这三个操作捆绑成一个原子性cas指令

## 锁的几种类型
乐观锁、悲观锁
无锁、偏向锁、轻量锁、重量锁
公平锁、非公平锁

## JDK自带的几个调试工具
jps 列出进程pid号 | top:命令 --linux使用
jinfo：实时的得到/修改运行期jvm的参数 或者系统变量（查看）
    其中标记为manageable的可以被实时的修改
jstack: 实时的查看pid中线程的堆栈信息
jstat： 实时的显示jvm的资源信息，包括gc各种新生代老年代等信息
Jmap jhat: 用来实时的导出堆栈映像快照相关的信息 并进行分析

## session
### request.getSession(boolean b);
参数为false 则session不存在的话不会创建，直接返回null;
参数为true 则session不存在的话会 new Session()返回；

## annotation
### @SuppressWarnings
忽略编译器警告信息
比如@SuppressWarnings("unchecked", "deprecation")
编译器编译期间忽略提示中包含unchecked， depreciation的警告

### @Rentention & @Document & @Target
此注解称为元注解，可用来修饰注解

@Rentention：
被@Rentention修饰的注解 共有三种保留策略（即注解保留到什么时期），分别为：
source: 编译成class文件之后不再保留
class: JVM加载字节码文件的时候被遗弃；
runtime:jvm加载之后仍然保留，可通过反射获取到

@Document：
含有此注解会被生成javadoc文档，可能作为公共api使用

@Target：
被此注解修饰过的注解可以 注解在特定的类型上面
比如Field，则注解可以用来修饰字段（method, parameter等）

### @Enumerated
修饰枚举值，可决定存储到数据库中或者转化的是字符串还是原始值（0,1）

### @JoinColumn & @OneToMany & @ManyToMany & @ManyToOne
@JoinColumn
name(String):外键的名，默认主表名加id的形式；
如果联合@OnetoOne 或者@ManyToOne注解，那么外键列应该是在本表中的；
如果联合@OnetoMany注解，那么外键列应该是在target表中的；
如果是ManyToMany的话，最好用JoinTable联合，建立一个中间表进行映射，作为对应两张表的外键而存在；
nullable(boolean):值是否可为空，默认true;

@OneToMany
mapperBy(String):定义了一表 多表的关系，用这个属性时不会生成中间表，ManyToOne中则没有此属性
Cascade(CascadeType):级联属性，是否主随外动等；

@ManyToOne 也可设立Cascade属性
optional(boolean):默认false,如果为true，则不能延迟加载一个非集合映射的实体，除非你记得设置optional = false（因为Hibernate不知道那里应该有代理还是null，除非你告诉它null是不可能的，所以它可以生成 代理人。）
optional=false和nullable=false区别在于optional控制的是运行时的状态，而nullable是用于生成的数据库列值不能为空的指令

@ManyToMany 多对多的映射，此时可以配合@JoinTable生成一张中间表；
JoinColumns(JoinColumn):用于映射当前类的外键
inverseJoinColumns(JoinColumn):用于映射当前类的target类的外键
indexs（Index）:索引列
uniqueConstraints(uniqueConstraint)：表的唯一约束字段

### @Inheritance
继承映射使用@Inheritance来注解，它的strategy属性的取值由枚举InheritanceType来定义
（包括SINGLE_TABLE、TABLE_PER_CLASS、JOINED，分别对应三种继承策略）。

@Inheritance注解只能作用于继承结构的超类上。如果不指定继承策略，默认使用SINGLE_TABLE。

SINGLE_TABLE：一个类继承结构一个表的策略。这是继承映射的默认策略。即如果实体类B继承实体类A，实体类C也继承自实体A，那么只会映射成一个表，这个表中包括了实体类A、B、C中所有的字段，JPA使用一个叫做“discriminator列”来区分某一行数据是应该映射成哪个实体。

TABLE_PER_CLASS：与JOINED相比每个表包括id都是单独的，不会存在外键关系；

JOINED：联合子类策略。这种情况下子类的字段被映射到各自的表中，这些字段包括父类中的字段，并执行一个join操作来实例化子类。注解为：@Inheritance(strategy = InheritanceType.JOINED)
当往子类插入数据的时候，会通过外键查询主表中是否有数据，没有的话则插入一条数据；
比如A为超类，则A中实体类设立一个自动生成主键的字段，B类C类继承A,那么A类中的字段为A的，BC类的字段为各自实体类中的字段加上A的主键，其中A的主键为BC的主键，并且为A的外键；

## Spring

## jpa开启打印sql参数涉及类
logging:
  level:
    org.springframework.security:
      - debug
      - info
    org.springframework.web: error
    org.hibernate.SQL: debug
    org.hibernate.engine.QueryParameters: debug
    org.hibernate.engine.query.HQLQueryPlan: debug
    org.hibernate.type.descriptor.sql.BasicBinder: trace

## BindingResult
用来和表单entity验证相配合得到error信息
没验证一个实体后面就要跟一个BindingResult， 比如下面的User后跟了BindingResult，而如果有个Role结构，那么后面还需要跟BindingResult，而且【要验证的结构和BindingResult】中间不能接其他参数
```
@RequestMapping(value = "/add", method = RequestMethod.GET)
/**
* @Valid 指定需要验证的参数
*/
public String add(@Valid User user, BindingResult bindingResult) {
log.info("has error ? {}", bindingResult.hasErrors());
// 如果有捕获到参数不合法
if (bindingResult.hasErrors()) {
// 得到全部不合法的字段
List<FieldError> fieldErrors = bindingResult.getFieldErrors();
// 遍历不合法字段
fieldErrors.forEach(
fieldError -> {
// 获取不合法的字段名和不合法原因
log.info("error field is : {} ,message is : {}", fieldError.getField(), fieldError.getDefaultMessage());
}
);
}
```
## annotation
### @RequestMapping
value:指定映射的实际地址，即一个url
method:指定请求的类型，如get，post等
consumes:指定处理请求的提交内容类型（Context-type）
produces:指定返回的内容类型
params:指定request必须包含参数时，才能让该方法处理
headers：指定request中必须包含指定的header值，才让该方法处理

### @RequestParam&@RequestAttribute&@RequestHeader
如名所示 从request的不同参数中取所需
值得注意的是 RequestAttribute中取的参数可以通过一些filter/interceptor来设置

### @feign

### @nonnull @nullable
实现了JSR 305标准关于代码的一系列检查，是一套的，并且这部分应该被一些诸如idea的开发工具所使用 以用来在代码的编译期间就能及时检查出问题，只做告警用，并不会对代码产生实质性的改变

值得一提的是lombok内部实现的@nonnull注解，对于加在字段上的注解会实际在方法中产生一个空指针判断生成到class文件之中，并且只提供了这单个的注解，也就是说并没有实现JSR305规范，如果后期JSR出了单个的关于代码检查的规范，lombok后续的版本将删除掉这个注解以免产生误导（所以代码中慎用lombok nonnull注解）

## Q&A
## 为什么局部变量定义的时候必须要初始化

成员变量是放在堆内存中随类在预处理阶段就被分配了内存
局部变量则是放在栈中

1，效率问题
包含局部变量里的成员方法可能会被调用多次，如果每次调用都需要初始化影响效率，而且假设有一个for循环，里面定义了一个局部变量，那么每次执行时都会赋初值，浪费效率
2，自由度问题
不给初值就无法引用，相当于一个变相的提醒，提醒你为什么要定义，引用这个变量，并且如果你定一个了一个局部变量却没有引用他，会给warning提示

## java8 lambda表达式不可修改外部基本类型的变量
lambda表达式本质上是匿名方法（会新开一个方法栈），也就是说其实对于lambda表达式来说传递过来的基本类型的变量本质上是一个值的拷贝，也即是原变量的一个副本，
只能引用它，而不可对其进行修改
所以规定外部变量最好是final的，如果不是final的，可能会在引用这个变量之前虚拟机已经对其进行回收；
另外，对lambda表达式的支持是拥抱函数式编程，而函数式编程本身不应为函数引入状态，所以定义为final可能更符合函数式编程的思想

## bitSet是什么，设计思想又是什么，可用来做什么
适用于只有两种状态的存储（比如true|false,0|1等）用位的状态来存储，
用long类型的数据来存储，可节省64倍存储空间，因为每一个long类型的数据都由64位二进制表示，而64位二进制可以表示64位数据的状态
11000000010110......
64->63->62->61...->2->1
所以bitset设计了一个long类型的数组（word[]），bitindex通过与64取模(结果为wordindex)来判断存储在数组中的具体位置，进一步判断存储在long类型的所在位，相应的置为1/0；
* set words[wordIndex] |= (1L << bitIndex);(true) 
       words[wordIndex] &= ~(1L << bitIndex);(false)

## classpath&classpath*
classpath下的路径必须在这个路径下查找，并且不会去子文件夹下和jar包中查找，所以必须配置好路径，并且重名的配置文件只加载一个
//加载一个文件（）
classpath:/spring/applicationContext.xml
//通配符加载一个文件（？代表任何一个字符）
classpath:/spring/applicationContex?.xml
//通配符加载一个文件（\*代表任意个不同字符）
classpath:/spring/applicationContex*.xml
//通配符加载文件(\*表示任何字符串)
classpath:/spring/\*/applicationContext.xml
//通配符加载文件(\*\*表示任何目录结构，等于遍历这个文件夹)
classpath:/spring/\*\*/applicationContext.xml

classpath\*不仅会查找这个文件夹，而且会自动寻找子文件夹下的和jar包中的配置文件，并且他会加载重名的文件
比如a.jar中有一个applicationcontext.xml,b.jar中也有applicationContext.xml
那么他会把他们全加载出来，如果是classpath则只加载一个，视顺序而定
所以造成classpath\*加载速度慢，如无必要，尽量不用classpath\*，用classpath时注意配置好路径

## Method .. not annotated with HTTP method type
此问题可能是由于spring默认情况下不会采取feign的注解，需配置一个bean设置一下访问feign的契约；
> 原笔记此处有一张配图，资源路径还没整理过来。

## 微服务如何拆分，拆分的方式？
[微服务拆分](http://dockone.io/article/8241)

## CAP理论
分布式系统的CAP不可能同时满足，只能满足其中之二，一般为CP, AP
假设有 A B两个节点，而用户访问的时候执行了一个更新数据的操作，假设访问的是A，此时A需要把数据和B同步，
问题是A和B通信的时候是可能失败的，所以可能需要一直重试直到成功
此时其实是牺牲了可用性来保证一致性的，因为要往B中写入最新的数据，保证数据同步后才能开启读写操作
反之可以保证可用性，但数据可能不是最新的

Consistency 一致性
Availability 可用性
Partition tolerance（分区容错）：区间通信可能失败，这就导致可能出现访问数据时数据不一致的情况，一般情况下分区容错性是分布式系统必须存在的（不然有点像单节点部署），所以P一般都是要满足的，基于此 C A要满足二者其一；

可根据场景确定使用
比如银行这种对数据正确性要求高的一致性是高于可用性的
eureka注册中心保证了 AP 而zookeeper保证了 CP

### 延伸出来的base理论
base理论是 Basically Available(基本可用)，Soft State（软状态）和Eventually Consistent（最终一致性）
无法做到强一致性，但可以通过适当的手段保证最终一致性

## 创建对象的几种方式
new
reflect
序列化
clone

## log.isDebugEnabled()用法
log.isDebugEnabled() （是否需要判断呢？）
此方法是用来判断log的级别的，当为debug级别时才会为true,这样可以避免无用的日志打印；

为什么要提前判断呢？
以前的时候 打印日志的格式为：log.debug("XXXX :" + name)；
这样不管开没开启debug模式，都会进行一次字符串的拼接，而进行判断之后则会避免这种资源的消耗；

而现在log的改进则可以不用判断了，直接  log.debug("XXXX : {}" + name)；
只有开启debug模式才会进行替换拼接

## http status
### 1XX(informational)(http1.1以后有)
100（continue）:表明服务器已经收到一部分请求，并未拒绝，并且服务器期望收到完整的请求以返回一个最终的response;
当请求包含一个请求头为‘100-continue’，服务器返回100状态码则表明客户端可以向服务器发送post请求（携带请求体），否则直接发送请求体可能会被服务器拒绝，造成等待浪费
如果请求体没有携带请求头‘100-continue’，那么浏览器可能会简单的对这个临时响应丢弃，所以客户端不能无限期等待100的回应（没有携带请求头‘100-continue’，后续的请求也不应该携带请求体）
101：

### 2XX(successful)
### 3XX(redirection)
### 4XX(client error)
### 5XX(server error)

## SpringBoot
springboot启动的一个加载过程

应用了springcloud的时候先加载springcloud上下文等信息

1. 初始化beanfactory
2. 创建上下文
3. 准备上下文的时候加载bean定义信息（prepareContext）（BootstrapImportSelectorConfiguration）
4. 刷新上下文（refreshContext）-> 进入spring容器加载过程
    1.  先获得上面创建好的工厂
    2.  工厂做一些初始化操作（prepareBeanFactory）
    3.  postProcessBeanFactory（特定上下文子类进行增强处理工厂，只是定义）
    4.  执行 BeanDefinitionRegistryPostProcessors 
    5.  执行上面定义的增强器
    6.  执行selector加载自动配置的configurition信息 
    7.  加载bean的定义信息

## Spring Session

## session存储策略为redis时config命令被禁用
配置bean ConfigureRedisAction 策略为NO_OP （禁止config命令被使用）
（因为可能采用的是云存储的redis，有些为了安全考虑，可能会禁用掉config命令，所以需要配置此策略）
（spring session所需要的配置可联系运维配置）

## log4j
## 日志输出的级别
DEBUG < INFO < WARN < ERROR < FATAL
> 原笔记此处有一张配图，资源路径还没整理过来。

## 日志的输出（文件/控制台）

## 如何选择日志级别呢
### 选择 DEBUG / INFO
DEBUG 级别比 INFO 低，包含调试时更详细的了解系统运行状态的东西，比如变量的值等等，都可以输出到 DEBUG 日志里。 
INFO 是在线日志默认的输出级别，反馈系统的当前状态给最终用户看的。输出的信息，应该对最终用户具有实际意义的。

从功能角度上说，INFO 输出的信息可以看作是软件产品的一部分，所以需要谨慎对待，不可随便输出。如果这条日志会被频繁打印或者大部分时间对于纠错起不到作用，就应当考虑下调为 DEBUG 级别。
* 由于 DEBUG 日志打印量远大于 INFO，出于前文日志性能的考虑，如果代码为核心代码，执行频率非常高，务必推敲日志设计是否合理，是否需要下调为 DEBUG 级别日志。
* 注意日志的可读性，不妨在写完代码 review 这条日志是否通顺，能否提供真正有意义的信息。
* 日志输出是多线程公用的，如果有另外一个线程正在输出日志，上面的记录就会被打断，最终显示输出和预想的就会不一致。

### 选择 WARN / ERROR 
当方法或者功能处理过程中产生不符合预期结果或者有框架报错时可以考虑使用，常见问题处理方法包括：
* 增加判断处理逻辑，尝试本地解决：增加逻辑判断吞掉报警永远是最优选择
* 抛出异常，交给上层逻辑解决
* 解决记录日志，报警提醒
* 使用返回码包装错误做返回
一般来说，WARN 级别不会短信报警，ERROR 级别则会短信报警甚至电话报警，ERROR 级别的日志意味着系统中发生了非常严重的问题，必须有人马上处理，比如数据库不可用，系统的关键业务流程走不下去等等。错误的使用反而带来严重的后果，不区分问题的重要程度，只要有问题就error记录下来，其实这样是非常不负责任的，因为对于成熟的系统，都会有一套完整的报错机制，那这个错误信息什么时候需要发出来，很多都是依据单位时间内 ERROR 日志的数量来确定的。
### 强调ERROR报警
ERROR 级别的日志打印通常伴随报警通知。ERROR的报出应该伴随着业务功能受损，即上面提到的系统中发生了非常严重的问题，必须有人马上处理。
ERROR日志目标
给处理者直接准确的信息：ERROR 信息形成自身闭环。
问题定位：
* 发生了什么问题，哪些功能受到影响
* 获取帮助信息：直接帮助信息或帮助信息的存储位置
* 通过报警知道解决方案或者找何人解决

## Kubernetes

## Spring Security
## session认证策略

http.sessionManagement() .sessionCreationPolicy(SessionCreationPolicy.IF_REQUIRED)

always – 如果session不存在总是需要创建；
ifRequired – 仅当需要时，创建session(默认配置)；
never – 框架从不创建session，但如果已经存在，会使用该session ；
stateless – Spring Security不会创建session，或使用session

## 开发规范 from alibaba
## 编程规约
java包名统一使用单数形式（类名如果有复数含义，可以使用复数）；

在常量与变量的命名时，表示类型的名词放在词尾，以提升辨识度。 如 startTime / workQueue / nameList 

如果模块、接口、类、方法使用了设计模式，在命名时需体现出具体模式。 如  public class OrderFactory

接口类中的方法和属性不要加任何修饰符号（public 也不要加），保持代码的简洁性

领域模型命名规约    
1） 数据对象：xxxDO，xxx 即为数据表名。    
2） 数据传输对象：xxxDTO，xxx为业务领域相关的名称。  
3） 展示对象：xxxVO，xxx一般为网页名称。    
4） POJO是 DO/DTO/BO/VO的统称，禁止命名成 xxxPOJO。

一方库：本工程中的各模块的相互依赖
二方库：公司内部的依赖库，一般指公司内部的其他项目发布的jar包
三方库：公司之外的开源库， 比如apache、ibm、google等发布的依赖

if/for/while/switch/do 等保留字与括号之间都必须加空格

注释的双斜线与注释内容之间有且仅有一个空格

在进行类型强制转换时，右括号与强制转换值之间不需要任何空格隔开。 

换行时 方法调用的点符号与下文一起换行，在括号前不要换行

【推荐】单个方法的总行数不超过80行  ：代码逻辑分清红花和绿叶，个性和共性，绿叶逻辑单独出来成为额外方法，使主干代码更加清晰；共 性逻辑抽取成为共性方法，便于复用和维护。 

【推荐】不同逻辑、不同语义、不同业务的代码之间插入一个空行分隔开来以提升可读性。 说明：任何情形，没有必要插入多个空行进行隔开。 

OOP规范：
所有的覆写方法，必须加@Override注解。

外部正在调用或者二方库依赖的接口，不允许修改方法签名，避免对接口调用方产生 影响。接口过时必须加@Deprecated注解，并清晰地说明采用的新接口或者新服务是什么

Object的 equals方法容易抛空指针异常，应使用常量或确定有值的对象来调用 equals。

float类型不能直接比较。需要进行相减操作，然后与一个可以接受的误差值比较，或者采用bigdecimal(传入string类型，而不是1.2f这种)

构造方法里面禁止加入任何业务逻辑，如果有初始化逻辑，请放在 init方法中。 

慎用 Object的 clone方法来拷贝对象（浅拷贝）

重写equals必须重写hashcode(hashmap put可为例子)

待续：15页

## hibernate

## 一二级缓存
一级缓存：session级别的缓存，更进一步感觉应该是事务级别的缓存，因为一级缓存不存在并发的问题， 所以如果是在事务执行期间，那么根据hibernate的策略选择对数据库中的数据进行加锁或是其他操作 缓存中的数据不需要与数据库中的数据进行同步；

二级缓存：进程或集群共享的缓存（需引用实现好的jar包 如ehcache等）

## 对象的状态

### 持久态
比如从数据库查询数据，会把查询出来的对象变为持久态
### 瞬时态
比如刚初始化了一个对象，此时还没有和hibernate session联系在一起，如果没有引用，就会被java虚拟机回收带哦
### 游离态
游离态是从持久态转化的状态，持久态的session关闭了之后就会变为游离态，已经变为游离态的对象可以再次向持久态转化，同样，持久态的数据也可以转化为游离态 (entitymanager.detect)

### 设置flushMode
FlushMode 有四种状态  manual commit auto always,随着级别的增高，效率也会逐渐降低，比如最高的always 每次查询都会执行flush操作（相当于把事务先提交一部分，以便于在数据库中能直接查询到）

