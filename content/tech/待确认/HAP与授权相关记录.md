---
title: "HAP 与授权相关记录"
date: 2026-05-31
tags: ["待确认", "Evernote"]
categories: ["技术"]
---

> 这里有不少内部系统和认证授权相关的记录，先原样留在待确认。
<!--more-->

## 对于filter的使用
Debugfilter: 用来打印日志CommonsRequestLoggingFilter

>引申：对于filter和aop记录日志的使用：
>- 使用filter: 适用于server api这种，记录请求体，path之类的
>- 使用aop：aop适合做日志的审计，比如可能某些service要记录特定的日志，适合于不同的场景，偏向业务

prefilter:
对于全局session唯一的处理：使用threadlocal进行存储
比如host locale这些参数，以及一些定制化参数

oauth filter:
请求头中携带 header (Authorization: Bear token), 会去oauth校验并解析出来用户放到request中

cas 单点登出filter(直接从cas jar包中引用注册即可)：

cas 登录filter:
- 校验是否为需要校验的path(包括根路径)
- 校验是否有ticket, 没有的话需要redirect到casServerLoginUrl，有的话跳到ticket filter

ticket filter：校验ticket(cas包提供)

## 对于session的存储策略
redis: 最常用的
hazelcast: 类似于redis（不过不常用）
jdbc: 不推荐用，JDBC是面向关系型数据库的，不该用来设计存储session
none: 不存储session, 每次现场校验
等等

>spring.session.store-type: redis
>spring.session.redis.namespace: dddd
>spring.session:timeout: 7200

## 密码加密策略

前端传输的密码采用rsa公钥加密之后传给后端，后端使用私钥解密，存储到数据库中的密码做md5摘要（不可还原）

## 刷新配置
注册bean（构造器或者其他方式）的时候声明类可以被刷新，比如一些配置项类；有改变的时候手动调用下刷新的接口（扫描所有注册为可被刷新的类，调用刷新）即可

```java
public interface Refreshable { void refresh(); }
```

## 操作日志的追踪（通过注解扫描对应的方法）
操作人
操作类型 比如如下的类型
>新建用户
>编辑用户
>更新密码
>授权应用
>取消授权应用
>启用用户
>停用用户
>创建用户组
>编辑用户
>对接应用
>取消对接应用
>启用用户组
>停用用户组
>新建应用
>编辑应用
>启用应用
>停用应用
>编辑个人信息

操作前
操作后
操作时间

## 授权应用
页面上授权给用户或者用户组应用，然后内部先改为等待，在通过消息publish出去， 等应用回复消息再改为成功或者失败

增加定时任务扫描trace日志，规定时间内应用为回复消息则标记为授权失败

## 对接freeipa

请求api失败的几种情况：
- 密码太短
- 密码太简单
- 原始密码错误

## 当用户停用，此用户正在登录状态的处理
给session打标记，标记过的用户的所有关联的session；
- filter掉请求重定向到登录页面（好处是可能是误操作，然后启用之后就能回复session的状态）
- 直接清除session

当停用用户时广播调用各应用接口 以便应用能停用此用户
其中使用@RequestLine(POST {uriPath}) 形如此形式，可以做到通过参数的替换来实现动态的请求各个应用（这是使用feign注解调用的形式，如果其他rest客户端，则直接传递path就好了）

## 外部open api
- 查询用户状态
- 查询用户语言
- 查询用户是否为超管
- 查询应用的授权状态

等等

## ldap 和 freeipa
freeipa 内部对接了ldap协议数据库，所以代码可以对接标准的ldap api进行用户的认证等操作
ldap 是一个访问目录的协议，存储账号密码，并提供认证的方式
kerberos 是一个认证和单点登录中心，各应用通过ticket进行交互，避免用户再次认证，并且也有存储用户的能力

freeipa可以将二者打通，结合使用，ldap用来存储用户信息，kerberos用来提供认证

[关于LDAP和Kerberos](https://mikolaje.github.io/2020/ldap_kerberos.html)

## jwt

jwt最大的特点是客户端存储的，解决了后端分布式的问题
```
三部分组成
Header（头部）存放一些元数据
Payload（负载）存放jwt基本信息+自定义的信息，json存储
Signature（签名）服务端根据密钥算出来的
```
因为密钥是一样的，所以服务端的任何一台机器都可以判断此jwt token是否有效; 有个缺点是删除只能在客户端删除，服务端无法做控制

[JSON Web Token 入门教程](https://www.ruanyifeng.com/blog/2018/07/json_web_token-tutorial.html)

## 关于contentType
spring默认支持表单提交
- 可以自己写filter进行对request的json增强
- 或者直接继承WebMvcConfigurer spring mvc会有默认的增强器进行处理各种格式的contentType

## todo

## oauth
## 校验用户token
支持的几种校验方式：
- 直接存储到数据库，所以直接查询数据库验证
- 远程验证，有一个单独的用户服务（比如account), 验证此用户名密码是否正确
- freeipa: freeipa提供了ui，及封装的几个接口用来验证用户或者一些其他操作
- ldap: 直接对接ldap协议的接口

不管是哪种方式对接，都会去account数据库中查询用户（因为权限role的信息是维护在数据库中的）

## 接口

清除缓存的接口：/api/clear/redis-cache
和前端交互是rsa加密过的，其中oauth和account都会提供加解密的服务，因为oauth主要是用来验证登录用的，而account是新建用户或者修改密码等用的（验证码接口也同样）

## nacos

## 对接secret manager(nike)
ApplicationEnvironmentPreparedEvent 启动前的事件：启动前根据已有的信息对接secret manager等外部存储，然后获取到的数据库信息转化为自己的一个命名空间 进行存储
> 原笔记此处有一张配图，资源路径还没整理过来。

## 网关
## 关于路由
从数据库中加载路由，和nacos中(或者configmap 走配置,推荐使用configmap)加载路由，二者冲突了（如果数据库中有某host对应的路由，则所有此host的路由都从数据库加载，nacos(或configmap)的自动忽略）以数据库的为准

其中数据库的路由是自己添加的 
nacos中的路由是devops上面可编辑的，编辑之后自动同步

nacos vs configmap: nacos的方式是挂载到saas环境上面的nacos，这样只要saas环境上面的nacos不可访问，则所有依赖devops部署的路由都不可用；改为configmap 之后可以挂载到每个k8s集群的configmap上面，这样其他环境不会对saas的nacos强依赖

