---
title: "记一次 OOM 的问题排查"
date: 2023-04-24
tags: ["问题排查"]
categories: ["技术"]
---

> 一次 Hibernate Query Plan Cache 引起的 OOM。
<!--more-->

## 现象

数据使用概览任务触发后，服务内存持续上涨，最后抛出 OOM。

对应的查询来自下面两个 HQL：

```java
@Query("select distinct r.entityId from TraitsTrendsReport r where r.reportDate = ?1 and r.entityId in ?2 and r.latestUv > 0")
Set<Long> findLatestUvNonEmptyIdPackageId(Date reportDate, Set<Long> entityIds);

@Query("select distinct r.entityId from TraitsTrendsReport r where r.reportDate = ?1 and r.entityId in ?2 and r.allUv > 0")
Set<Long> findAllUvNonEmptyIdPackageId(Date reportDate, Set<Long> entityIds);
```

数据使用概览会查最近 30 天每天创建的标签，并分别判断 `latestUv` 和 `allUv`。也就是说，一次调用就会触发 `30 * 2` 次查询。

问题出在 `in` 条件上。Hibernate 会维护 Query Plan Cache，同一个 HQL 如果 `in` 参数数量不同，会生成不同的查询计划并缓存下来。这里每天创建的标签数量几乎都不一样，所以缓存很容易被打散。

当时观察到一个查询计划缓存大约 100M。一次调用下来，缓存体积会快速堆上去。而这部分对象由 JPA/Hibernate 持有，Full GC 也回收不掉。

默认配置里，HQL 查询计划缓存数量比较大：

```properties
hibernate.query.plan_cache_max_soft_reference=2048
```

所以这类查询连续触发后，内存只会越来越高。第二天再查数据使用概览时，前 29 天可能会命中一部分缓存，但标签停启用、取消共享之类的操作又会改变参数数量，缓存仍然会继续增长。调大内存只能拖一会儿，不能解决问题。

## 排查过程

先看服务日志，最后的异常是 OOM，方向基本确定为内存问题。

继续翻任务日志，发现数据使用概览只有 `start`，没有对应的 `end`。这里先怀疑问题出在数据使用概览，后面通过后台接口复现也确认了这一点。

最开始怀疑过业务代码里有大对象，比如某些 Map 结构一直堆着。但类似结构在系统里并不少，如果它本身会导致 OOM，其他场景应该也会出问题。这个方向很快排除了。

<img src="1.png" alt="数据使用概览日志" style="width: 100%; max-height: 500px; object-fit: contain;">

重启后，通过后台接口反复触发数据使用概览，同时观察 GC。服务配置了 12G 内存，触发几次不同日期的请求后，老年代增长很快，接近 10G 后开始频繁 Full GC。

但 Full GC 基本回收不掉这部分内存，最后还是 OOM。到这里，基本可以判断有对象被长期引用着。

<img src="2.png" alt="GC 观察结果" style="width: 100%; max-height: 500px; object-fit: contain;">

代码层面没直接看出问题，于是导出堆内存统计：

```bash
jmap -histo:live
```

当时导出的日志大概 8G，是在内存接近 75% 时拿的。用 JProfiler 分析后，发现 `QueryPlanCache` 占用明显偏高。

继续查资料时，看到一个类似问题：

https://stackoverflow.com/questions/31557076/spring-hibernate-query-plan-cache-memory-usage

再回到代码里查 `@Query` HQL，最终定位到前面两个带 `in` 条件的查询。

<img src="3.png" alt="QueryPlanCache 内存占用" style="width: 100%; max-height: 500px; object-fit: contain;">

## 解决方案

当时有三个选择。

第一种是调小 HQL 查询计划缓存数量，比如把 `hibernate.query.plan_cache_max_soft_reference` 改到几十。这样能压住内存，但缓存命中会很差。这个场景确实不太需要缓存，不过影响面还是偏大。

第二种是开启 `in` 参数 padding：

```properties
hibernate.query.in_clause_parameter_padding=true
```

开启后，Hibernate 会把 `in` 参数数量向上补齐到 2 的幂。比如参数数量分别是 `3、4、5、6、7、8`，不开启时可能会缓存多份查询计划；开启后会收敛到少数几个数量档位。缓存数量降下来后，内存也就稳定了。

第三种是改代码，不再使用 HQL，或者避开 `in`，比如换成 `any`。这条路需要改业务代码和查询适配，成本更高。

最后选了第二种。改动小，风险低，也正好打在这次问题的根因上。
