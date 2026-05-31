---
title: "Spring Data JPA 中的 Batch 操作"
date: 2023-09-05
tags: ["Jpa", "Spring"]
categories: ["技术"]
---

> 怎么确认 JPA 到底有没有真的按 batch 在跑。
<!--more-->

环境信息：

- MySQL 8.1
- Hibernate 5.4

## 怎么确认是不是 batch

### 代码这一层

只看 Hibernate 打出来的日志，不太够。由于 Hibernate 输出的 log 是比较高层的抽象，无法根据 Hibernate 输出的 SQL 来判断实际的 SQL 执行情况，所以此处使用一个数据源代理，来跟踪 SQL 语句的执行情况。

Maven 依赖：

```xml
<dependency>
  <groupId>net.ttddyy</groupId>
  <artifactId>datasource-proxy</artifactId>
  <version>[LATEST_VERSION]</version>
</dependency>

<!-- see https://github.com/jdbc-observations/datasource-proxy -->
```

和 Spring 集成时，直接包一下 `DataSource`：

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

经过上面的包装可以知道 SQL 到底是如何发出去的。

### 数据库层

MySQL 的 `general_log` 记录的是客户端实际执行过的 SQL。  
不过调完记得关，不然日志会一直涨。

```sql
# 开启日志，关闭时改成 OFF
SET GLOBAL general_log = 'ON';

# 日志文件路径
SET GLOBAL general_log_file = "L://logfile.log";

# 输出到文件，也可以改成 TABLE
SET GLOBAL log_output = "FILE";
```

## 调试参数

Hibernate 这一套 batch 能不能生效，至少要先看下面几个配置：

![参数配置](image.png)

比如：

```yaml
spring:
  jpa:
    properties:
      hibernate.jdbc.batch_size: 4
      hibernate.order_inserts: true
      hibernate.order_updates: true
      hibernate.batch_versioned_data: true
```

这里比较关键的是 `hibernate.jdbc.batch_size`。

如果设成 `4`，然后你一次要插 10 条，那预期一般就是拆成三批：`4 + 4 + 2`。

`order_inserts` 和 `order_updates` 也有用，它们会尽量把同类操作整理到一起，这样更容易批量发。

## ID 策略的影响很大

JPA 里 `@GeneratedValue` 常见的几种策略：

- `TABLE`
- `SEQUENCE`
- `IDENTITY`
- `AUTO`

### `TABLE`

可以理解成单独拿一张表管主键。  
如果很多表都靠它分配 ID，那锁竞争一般不会太好。

### `SEQUENCE`

适合本身支持序列的数据库，比如 Oracle、PostgreSQL。

常见写法像这样：

```java
@SequenceGenerator(
    name = "id_generator",
    sequenceName = "id_seq",
    allocationSize = 50
)
```

这里的 `allocationSize` 可以理解成一次先拿一批 ID 过来用。  
从 batch 角度看，这种方式通常会更顺一点。

### `IDENTITY`

MySQL 里最常见的 `AUTO_INCREMENT` 那套。

问题也正出在这里：插入之前，Hibernate 并不知道最终生成的主键是多少；而它插完以后，又得把这个主键拿回来。

所以很多时候，只要主键策略是 `IDENTITY`，真正的 batch 插入就不太容易做。可能配了 `batch_size`，最后看日志，还是一条一条在插。

### `AUTO`

这个就交给 Hibernate 自己选。

如果没有显式指定，而主键也不是代码里自己提前生成的，比如 UUID 这种，那最好还是确认一下它最后到底走了哪条路。是从上述三种来挑选

## `SEQUENCE` VS `TABLE` 

从数据库的原语实现层面， SEQUENCE 要比 TABLE 性能好很多

- MySQL 这边大多还是落到 `IDENTITY`
- Oracle、PostgreSQL 更适合 `SEQUENCE`

## 数据库连接的影响

如果底层是 MySQL，需要确认下连接参数 `rewriteBatchedStatements=true`，参数默认是 `false`。  
不加的话，有时候应用这边看起来已经在按批组 SQL 了，但驱动层并不会替你按 batch 的方式去发。

这一点比较容易漏。

## JPQL、HQL、NativeQuery

这几个东西本身不会自动把普通写法变成 batch。

如果本来写的就是逐条操作，那不要指望 Hibernate 后面 magically 拼成真正的批量。


## 引用

[Hibernate ORM 5.5.9.Final User Guide](https://docs.jboss.org/hibernate/orm/5.5/userguide/html_single/Hibernate_User_Guide.html)

[Batch Insert/Update with Hibernate/JPA](https://www.baeldung.com/jpa-hibernate-batch-insert-update)

[聊聊 Java 里 MySQL 的 batch 操作](https://www.modb.pro/db/168717)

[Is Hibernate batching with IDENTITY generation possible?](https://stackoverflow.com/questions/63422129/is-hibernate-batching-with-identity-generation-possible)

[Generate Primary Keys Using JPA and Hibernate](https://thorben-janssen.com/jpa-generate-primary-keys/)

[Configuring a datasource-proxy in Spring Boot](https://arnoldgalovics.com/spring-boot-datasource-proxy/)
