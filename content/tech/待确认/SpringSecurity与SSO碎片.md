---
title: "Spring Security 与 SSO 碎片"
date: 2026-05-31
tags: ["待确认", "Evernote"]
categories: ["技术"]
---

> 这份内容里主题混得比较杂，先作为待确认材料保留。
<!--more-->

## nio&bio
bio: 阻塞IO（线程池），每次有请求到达，会从线程池取出一个线程处理此请求，如果线程池线程用光了，则请求会阻塞住
nio: 非阻塞IO（采用IO多路复用技术实现少量线程处理大量请求），每次有请求到达，服务器会先接受请求，然后服务器会先生成相应的request信息，然后调用线程来处理（对CPU利用率较高）

## 关于ThreadLocal
通过ThreadLocal创建的变量只能为本地变量所修改和使用，其他线程无法使用（其中InheritableThreadLocal 子类创建的变量可以为子线程所使用）
变量通过保存在当前thread的 threadLocals变量（ThreadLocalMap类型）中（并且当前调用的对象为key）（this,value）

q&a:
线程池中的使用完的线程是不会被回收的，会继续放回到线程池中等待下次分配，所以可能造成一个问题是此变量可能永远不会被回收,因为永远有一个this引用指向当前对象
而ThreadLocalMap通过定义key为弱引用（WeakReference）类型解决了此问题；
弱引用：当没有强引用指向此弱引用指向的内部对象时，此对象会被JVM回收;

## spring security

要求经过验证的用户才能与系统交互
提供了默认登录form页面（user/password(打在控制台中)）
session
login/logout

## spring security
## 提供的几个功能点
要求经过验证的用户才能与系统交互
提供了默认登录form页面（user/password(打在控制台中)）
session
login/logout
## authentiction
### 基本的组件
SecurityContextHolder 存储验证用户的详细信息
SecurityContext 从SecurityContextHolder获得，并包含当前经过身份验证的用户的身份验证。
Authentication 当前用户的信息或者AuthenticationManager提供的
GrantedAuthority 授予用户的权限
AuthenticationManager 定义springsecurty如何验证用户的filter
### 验证的机制
Method security is a bit more complicated than a simple allow or deny rule. Spring Security 3.0 introduced some new annotations in order to allow comprehensive support for the use of expressions.
内置表达 authentication principal haspermission
hasPermission() expressions are delegated to an instance of PermissionEvaluator. It is intended to bridge between the expression system and Spring Security’s ACL system, allowing you to specify authorization constraints on domain objects, based on abstract permissions
## Insight访问权限控制
## 前言
总体上采用SSO(单点登录)控制服务的访问权限 + Spring Security控制内部资源的访问权限权限
## SSO
目前来说支持两种SSO方式：网关模式|CAS模式
## Spring Security 认证&授权

## 前言
Spring Security是一个强大的实现了身份验证加权限控制的框架
## 使用
在spring家族中的maven依赖
```xml
<dependency>  
    <groupId>org.springframework.boot</groupId>  
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
```
## Authentication（认证）
> 原笔记此处有一张配图，资源路径还没整理过来。
**Principal**：通常来说用来表示登录的用户（一般信息会存放在UserDetails）
**Credentials**：一般是用来存储用户的密码，在用户登录验证成功之后会擦除掉
**Authorities**： 存放用户的权限信息(GrantedAuthority)
**Authentication**: 代表经过认证的用户的全部信息
Security
## Authorization（授权）

