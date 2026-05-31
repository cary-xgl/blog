---
title: "Spring Data JPA 中的 Batch 操作"
date: 2023-09-05
tags: ["Spring-Data-JPA"]
categories: ["技术"]
---

> 这篇主要记录一个很具体的问题：怎么判断 JPA 到底有没有真正执行批量操作。
<!--more-->

以下内容基于：

- MySQL 8.1
- Hibernate 5.4

## 如何确认是否真的执行了批量操作

### 代码层面

Hibernate 打出来的日志比较偏抽象，只看它输出的 SQL，不一定能判断数据库层面最终是怎么执行的。  
所以这里更稳的办法，是在数据源这一层做代理，直接跟踪实际发出去的 SQL。

Maven 依赖：

```xml
<dependency>
  <groupId>net.ttddyy</groupId>
  <artifactId>datasource-proxy</artifactId>
  <version>[LATEST_VERSION]</version>
</dependency>

<!-- see https://github.com/jdbc-observations/datasource-proxy -->
```

和 Spring 集成时，可以直接包一层 `DataSource`：

```java
@Component
public class DatasourceProxyBeanPostProcessor implements BeanPostProcessor {
  @Override
  public Object postProcessBeforeInitialization(final Object bean, final String beanName) throws BeansException {
    return bean;
  }

  @Override
  public Object postProcessAfterInitialization(final Object bean, final String beanName) throws BeansException {
    if (bean instanceof DataSource) {
      DataSource dataSourceBean = (DataSource) bean;
      return ProxyDataSourceBuilder
          .create(dataSourceBean)
          .name("Batch-Insert-Logger")
          .logQueryToSysOut()
          .asJson()
          .countQuery()
          .build();
    }
    return bean;
  }
}
```

这样可以更直接地看到 SQL 的执行情况，而不是只看 Hibernate 上层的日志。

### 数据库层面

如果想再确认一层，可以直接打开 MySQL 的 `general_log`，把客户端实际执行过的 SQL 记下来。

不过这个日志一定要记得及时关闭，不然磁盘空间会涨得很快。

```sql
# 开启日志记录，关闭时改为 OFF
SET GLOBAL general_log = 'ON';

# 设置日志文件路径
SET GLOBAL general_log_file = "L://logfile.log";

# 输出到文件，也可以改成 TABLE
SET GLOBAL log_output = "FILE";
```

## 调试

根据 Hibernate 官方文档，JPA 在批量插入时主要受下面几个参数影响：

![参数配置](image.png)

例如可以这样配置：

```yaml
spring:
  jpa:
    properties:
      hibernate.jdbc.batch_size: 4
      hibernate.order_inserts: true
      hibernate.order_updates: true
      hibernate.batch_versioned_data: true
```

这里的意思是：

- 每批最多按 4 条来处理
- `insert` 和 `update` 会尽量按顺序整理，方便批量发送

举个例子，如果一共要插入 10 条数据，`batch_size` 设成 4，那么预期上会被拆成 3 批：`4 + 4 + 2`。

### ID 生成策略的影响

JPA 里的 `@GeneratedValue` 常见有 4 种策略：

- `TABLE`
- `SEQUENCE`
- `IDENTITY`
- `AUTO`

#### `TABLE`

可以理解成额外建一张表，用它来统一管理主键增长。  
如果多个业务表都依赖这张表生成 ID，那么事务之间就会去竞争这张表上的锁，性能一般不会太好。

#### `SEQUENCE`

要求数据库本身支持 `sequence`，例如 Oracle、PostgreSQL。

通常会配合下面这种方式使用：

```java
@SequenceGenerator(
    name = "id_generator",
    sequenceName = "id_seq",
    allocationSize = 50
)
```

这里几个参数的含义分别是：

- `name`：生成器名称
- `sequenceName`：数据库里的序列名
- `allocationSize`：一次从序列里预分配多少个 ID

这种方式通常更适合和批量插入配合。

#### `IDENTITY`

这种方式依赖数据库自己的自增列，比如 MySQL 的 `AUTO_INCREMENT`。

问题在于：插入前 Hibernate 并不知道主键值是多少，而它又需要在插入后拿回生成的主键。  
因此在这种策略下，Hibernate 往往没法把这类插入真正合并成批量操作。

这也是为什么很多场景里，一旦主键策略用了 `IDENTITY`，批量插入就很难真正生效。

#### `AUTO`

由持久化提供方，也就是 Hibernate，自己决定最终使用哪一种策略。

如果没有显式指定生成策略，而主键又不是业务侧提前生成的，例如代码里自己生成 UUID，那就要特别留意 Hibernate 最终替你选了什么。

### `sequence` 和 `table`

从数据库实现层面看，`sequence` 一般会比 `table` 方案更轻，也更适合高并发场景。

简单总结一下：

- 底层数据库是 MySQL：通常只能落在 `IDENTITY`
- 底层数据库是 Oracle、PostgreSQL：更推荐 `SEQUENCE`

### 数据库连接参数的影响

如果底层是 MySQL，连接串里通常还需要显式加上：

`rewriteBatchedStatements=true`

这个参数默认是 `false`。  
不开的话，就算应用层面已经按批次组织好了语句，JDBC 驱动也可能不会按你预期的方式去重写和发送批量 SQL。

这一点经常被忽略。

### JPQL、HQL、NativeQuery 的情况

JPQL、HQL、NativeQuery 本身不会自动把普通写法“变成批量操作”。  
如果要做真正的批量更新或批量插入，通常还是要从语句组织方式和执行方式本身来处理，不能只指望 Hibernate 自动优化。

## 批量更新

批量更新这一块相对更复杂。  
目前这里先记一个结论：很多场景下看起来像“批量更新”，其实不一定是真正意义上的批量执行。

这部分后面还需要结合更具体的 SQL 日志和测试案例再继续拆。

## 引用

[Hibernate ORM 5.5.9.Final User Guide](https://docs.jboss.org/hibernate/orm/5.5/userguide/html_single/Hibernate_User_Guide.html)

[Batch Insert/Update with Hibernate/JPA](https://www.baeldung.com/jpa-hibernate-batch-insert-update)

[聊聊 Java 里 MySQL 的 batch 操作](https://www.modb.pro/db/168717)

[Is Hibernate batching with IDENTITY generation possible?](https://stackoverflow.com/questions/63422129/is-hibernate-batching-with-identity-generation-possible)

[Generate Primary Keys Using JPA and Hibernate](https://thorben-janssen.com/jpa-generate-primary-keys/)

[Configuring a datasource-proxy in Spring Boot](https://arnoldgalovics.com/spring-boot-datasource-proxy/)
