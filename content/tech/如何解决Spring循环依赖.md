---
title: "如何解决Spring循环依赖"
date: 2022-04-23
tags: ["Spring"]
categories: ["技术"]
---

> 只记属性注入这条线里，Spring 怎么把循环依赖兜住。
<!--more-->

## 前提

这里只看一种情况：

- A 依赖 B；
- B 也依赖 A；
- 两边都是属性注入。

构造器注入不在这篇里，Spring 也兜不住。

## 先看三级缓存里放的是什么

Spring 处理单例 Bean 时，常会看到三层缓存：

- 一级缓存：`singletonObjects`，放完整创建好的单例对象；
- 二级缓存：`earlySingletonObjects`，放提前暴露出来的对象；
- 三级缓存：`singletonFactories`，放 `ObjectFactory`。

三级缓存不直接放对象，放的是一个延迟执行的 lambda。真有人来取时才执行。

```java
addSingletonFactory(beanName, () -> getEarlyBeanReference(beanName, mbd, bean));
```

## 创建 A 时做了什么

Spring 开始创建 A 时，先查缓存。

如果一级缓存里没有 A，就进入创建流程，并把 A 记到 `singletonsCurrentlyInCreation`，表示这个 Bean 正在创建中。

接着进入 `doCreateBean`：

1. 先根据构造函数把 A 实例化出来；
2. 如果它是单例、允许循环依赖，而且当前确实在创建中，就把 A 的工厂放进三级缓存；
3. 再开始填充 A 的属性。

关键点在这里：A 这时只是实例化出来了，还没填充属性，也没初始化完。

## A 依赖 B，B 又依赖 A

A 在填充属性时发现自己依赖 B，Spring 就去创建 B。

B 的流程和 A 基本一样：

1. 实例化 B；
2. 把 B 的工厂放进三级缓存；
3. 开始填充 B 的属性。

然后 B 又发现自己依赖 A。这时候 A 还没创建完，但已经在创建中了，所以 Spring 会去拿 A 的“早期引用”。

查找顺序一般是：

- 一级缓存；
- 二级缓存；
- 三级缓存。

A 这时不在一级缓存里。如果二级缓存也没有，就会从三级缓存里拿到对应工厂，再调用 `getObject()`。

## 提前拿到的是原对象还是代理对象

这里要看 A 有没有被 AOP 提前代理。

```java
protected Object getEarlyBeanReference(String beanName, RootBeanDefinition mbd, Object bean) {
    Object exposedObject = bean;
    if (!mbd.isSynthetic() && hasInstantiationAwareBeanPostProcessors()) {
        for (SmartInstantiationAwareBeanPostProcessor bp : getBeanPostProcessorCache().smartInstantiationAware) {
            exposedObject = bp.getEarlyBeanReference(exposedObject, beanName);
        }
    }
    return exposedObject;
}
```

如果只是普通对象，这里返回的就是原对象。

如果这个 Bean 后面要走 AOP，而且 `SmartInstantiationAwareBeanPostProcessor` 介入了，这里返回的就是提前代理过的对象，不再是原始对象。

拿出来之后，Spring 会把这个对象从三级缓存挪到二级缓存，表示它已经提前暴露过了。

## 后面的流程

后面就顺了：

- B 拿到 A，完成自己的属性填充；
- B 初始化完成，进入一级缓存；
- 回到 A，继续完成属性填充；
- A 初始化完成，也进入一级缓存。

这一轮循环依赖就到这里。

## 为什么二级缓存不够，还要三级缓存

问题不在“能不能提前放一个对象出来”，而在“要不要这么早就把它准备好”。

如果只有二级缓存，Spring 想提前暴露 A，就得先把 A 真正放进去。可如果 A 后面还要做 AOP，Spring 就得更早决定是不是要生成代理。

这就别扭了。

因为循环依赖会不会发生，在 A 刚实例化出来时其实还不知道。要是所有 Bean 都为了防循环依赖，先把可能的代理对象准备好，代价太大，也不符合 Spring 原本的初始化节奏。

有了三级缓存就不一样了。Spring 先放一个工厂进去，只有真的发生循环依赖、真的有人来拿 A 时，才决定返回原对象还是代理对象。

所以三级缓存解决的不是“有没有地方放”，而是“把提前暴露这件事拖到真要用的时候再做”。

## 三级缓存会不会提高效率

<img src="no_aop.png" alt="no_aop" style="width: auto; max-height: 500px;">
<img src="aop.png" alt="aop" style="width: auto; max-height: 500px;">

如果只看效率，结论基本是：三级缓存不是为了提速。

有 AOP 时，只是 A 的代理对象创建时机变了。

没 AOP 时，提前暴露出去的本来就是原对象，二级和三级在结果上也没什么差别。

它主要是在兜创建流程，不是在做性能优化。
