---
title: "Spring 容器与 Bean"
date: 2026-05-31
tags: ["Spring"]
categories: ["技术"]
---

> 先把 Spring 容器、Bean 生命周期和自动装配这些基础问题放一起。
<!--more-->

## 如何解决循环依赖
前提 A依赖B B依赖A(A B采用属性注入的方式)

* 开始创建A
    * 先去以及缓存里查看是否有A,并且A正在被创建，才会返回A或者A的代理（可以从二级，三级缓存中取，顺序是一级 二级 三级这样子）
    * 取不到的话，要进行创建，创建的过程中会进行一系列的检查，比如创建这个bean要依赖哪个bean先创建都必须先检查一边才能进行创建

>lambda表达式作为一个参数传入，会延迟执行，直到调用的时候才会进行真正的执行，比如（）->return Object,会真正调用比如get()时候才会把Object返回

* 进行创建A,加入singletonsCurrentlyInCreation（和三级缓存一个地方），表示A正在被创建
* 进行doCreateBean
    * 根据构造函数创建bean
    *  创建出来的bean 判断（是否单例，是否允许循环依赖，是否正在被创建）都判断成功进入下一步，也就是添加进三级缓存中，注意，添加进去的是个lambda表达式，实际取出的时候才会执行 --循环依赖是可以关闭的
    *  > 原笔记此处有一张配图，资源路径还没整理过来。
    * 注意：如果是普通的对象就直接返回原对象，也就是和二级缓存没什么关系，如果是aop（继承Smart...如图），那么返回的其实是aop代理过的对象（不是原对象）> 原笔记此处有一张配图，资源路径还没整理过来。
    * 如果一级缓存不存在，那么移除二级缓存中的bean,添加进三级缓存addSingletonFactory
    * 然后是填充A的属性 ->寻找B,B不存在，开始进行创建B,流程和上面一样，直到填充B,查找A,发现A在三级缓存中，取出具体的对象注入getObject从三级缓存工厂，然后对A,三级缓存移除，二级缓存加入，对于B 加入三级缓存
    * B初始化完成 从三级缓存中移除，加入一级缓存
    * 然后A属性填充玩，进入二级缓存，初始化完成之后移入一级缓存

问题：二级缓存应该可以解决循环依赖，为什么需要三级缓存
如果只有二级缓存，那么a进行属性注入前，就要完成自身的aop(如果有)，【预防循环依赖，因为循环依赖是不可预知的】，这违背了spring设计的初衷，因为aop属于bean的增强其，所以要在bean的初始化阶段完成aop；而如果有了三级缓存，那么只有发生循环依赖的情况下，才会提前进行aop代理，其他情况下都是走正常流程

问题：三级缓存是否提高了效率
> 原笔记此处有一张配图，资源路径还没整理过来。
> 原笔记此处有一张配图，资源路径还没整理过来。
这个是有aop的情况下，结论是没有，只是为A对象创建代理的时机不同
没有aop，就直接返回原对象了，所以也没有区别
    
## spring bean是线程安全的吗
首先明确spring bean的 作用域：

* singleton:单例，默认作用域。
* prototype:原型，每次创建一个新对象。
* request:请求，每次Http请求创建一个新对象，适用于WebApplicationContext环境下。
* session:会话，同一个会话共享一个实例，不同会话使用不用的实例。

所以看bean的作用域即可，值得提一句，单例模式下虽然是不安全的，但平时使用的单例类大多都是无状态的类，一般不涉及多个线程的共享变量操作，并且多线程调用同一个实例的方法，多线程调用同一个实例的方法，每个方法在执行的同时都会创建一个栈帧用来保存变量，这部分的变量是从内存中复制的，保存在线程自己的工作内存下，是线程安全的
>有状态：有数据保存功能
>无状态：无数据保存功能

## Springboot 自动装配
什么是自动装配：
SpringBoot 定义了一套接口规范，这套规范规定：SpringBoot 在启动时会扫描外部引用 jar 包中的META-INF/spring.factories文件，将文件中配置的类型信息加载到 Spring 容器（此处涉及到 JVM 类加载机制与 Spring 的容器知识），并执行类中定义的各种操作。对于外部 jar 来说，只需要按照 SpringBoot 定义的标准，就能将自己的功能装置进 SpringBoot

spring是如何实现自动装配的：
首先要开启自动装配，默认是开启的
在处理beanFactory的增强器的时候会进行自动装配，具体来说是扫描所有外部jar包下的META-INF/spring.factories，并把EnableAutoConfiguration下的类自动加载进来，等待实例化为bean

其中一般用来自动装配的bean都会加开关控制，比如@ConditionOnClass @ConditionOnProperty等控制bean的加载，这样就可以按需加载所需要的bean了

## aware接口
常见的接口比如
BeanNameAware：获取容器中bean的名称
BeanFactoryAware：获取加载bean的beanFactory
ResourceLoaderAware：获取bean的资源加载器

为了让bean能够感知到外部环境的变化，一般都是在initializeBean 初始化bean的时候调用的，并且是在初始化方法代码最前面执行，所以我们可以在初始化的过程中使用aware的信息

## bean的生命周期

* 先创建bean工厂
* 进行实例化bean
* 属性赋值 Populate
* 初始化 Initialization
* 销毁bean

InstantiationAwareBeanPostProcessor（继承自和BeanPostProcessor）和BeanPostProcessor
其中InstantiationAwareBeanPostProcessor除了BeanPostProcessor提供的两个方法之外，还提供了三个方法，算是一种特殊的增强器
具体如图
> 原笔记此处有一张配图，资源路径还没整理过来。
InstantiationAwareBeanPostProcessor也是可以作用于bean的初始化阶段，不过只作用于初始化阶段可以用BeanPostProcessor

BeanPostProcessor也是作为spring容器中的bean存在的，所以在refresh方法中先执行registerBeanPostProcessors注册BeanPostProcessor，再执行finishBeanFactoryInitialization完成bean的加载

BeanPostProcessor执行顺序：

* 先根据PriorityOrdered排序
* 再根据Ordered排序
* 都没有就按照自然排序

其中 Lower values have higher priority

总结：可以看出springbean的生命周期有固定的几个阶段，但可以在特定的阶段做扩展操作，其中aop相关的AbstractAutoProxyCreator
类（继承InstantiationAwareBeanPostProcessor），其中> 原笔记此处有一张配图，资源路径还没整理过来。，如果是自定义代理（自己继承TargetSource），那么在bean实例化的时候返回的就是代理对象，否则要在bean正常初始化之后调用postProcessAfterInitialization
返回代理对象

## ApplicationContext和BeanFactory的区别
首先都是IOC容器，DefaultListableBeanFactory是比较常见的默认IOC容器
ApplicationContext包含BeanFactory的所有功能，BeanFactory只是作为ApplicationContext一小部分，ApplicationContext还包括如图所示的几种功能，对于许多扩展的功能，比如注册Aop等BeanPostProcessor对于IOC来说是必不可少的，如果使用DefaultListableBeanFactory，那么需要自己处理这些BeanPostProcessor等等的功能，但使用ApplicationContext(如处理注解的)，那么refresh方法已经把这些都实现好了，无需手动实现；

什么情况下会用到DefaultListableBeanFactory？
除非需要对bean进行更精细的控制，比如在ApplicationContext(例如GenericApplicationContext实现)中，有几种bean是按约定检测的(即按bean名称或bean类型，特别是后处理器)，而普通的DefaultListableBeanFactory不知道任何特殊bean，所以当只按需加载bean的时候那么此时可能选用beanFactory来使用
> 原笔记此处有一张配图，资源路径还没整理过来。

## 请求在spring转发的流程

## FactoryBean vs BeanFactory
beanfactory是一个IOC容器的核心顶级接口，更像是一个容器，而不是一个工厂（因为工厂是用来生产对象的，而比如DefaultListableBeanFactory这种ioc容器是用来保存bean的），提供了比如getBean(),containsBean() 这种方法，用来把符合条件的bean筛选出来返回；
而FactoryBean相当于是一个对象工厂，并且也作为一个bean存在，交由beanfactory管理，核心方法是getObject,一般提供一种泛型类的对象，如果要获取这个工厂对象本身，可以用getObject(&+name)获得对象的工厂类，一般来说，factorybean就是用来生产bean的，比如常见的AOP代理对象的生成就用了FatcoryBean作为上层接口；

## component configuration
configuration会走代理创建
component不会走代理
```
@Configuration
public class MyBeanConfig {

    @Bean
    public Country country(){
        return new Country();
    }

    @Bean
    public UserInfo userInfo(){
        return new UserInfo(country());
    }

}
```
上面的话MyBeanConfig是代理bean，里面具体的bean则是通过代理创建出来的普通bean
而如果是component,则都是普通bean，并且userinfo调用的country需要创建一个新对象，相当于和上面的bean无法复用

```
@Component
public class MyBeanConfig {

    @Autowired
    private Country country;

    @Bean
    public Country country(){
        return new Country();
    }

    @Bean
    public UserInfo userInfo(){
        return new UserInfo(country);
    }

}
```
上面这种方式则不会创建新的country对象

代理是用beanfactory的增强器实现的，所以必须指明一个beanfactory的上下文，而component则不需要，因为他就是一个普通的bean
> 原笔记此处有一张配图，资源路径还没整理过来。

