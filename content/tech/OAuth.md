---
title: "OAuth"
date: 2020-04-28
tags: ["OAuth", "认证授权"]
categories: ["技术"]
---

> OAuth 的几种授权模式
<!--more-->

## OAuth 是什么
OAuth 是一个授权标准，重点是“授权”，不是“认证”。

常见场景是，用户要让一个第三方应用访问自己在某个平台上的部分资源，但又不想把账号密码直接给这个第三方应用。这个时候就会用到 OAuth。

第三方应用要先在服务提供方那里注册。注册完成后，一般会拿到：

- `client_id`
- `client_secret`

后面申请 token 时，会用到这两个值。

## 先把几个角色分清

- `Third-party application`：第三方应用，也就是客户端 `client`
- `HTTP service`：服务提供方
- `Resource Owner`：资源所有者，也就是用户
- `User Agent`：用户代理，通常就是浏览器
- `Authorization Server`：认证服务器，专门处理授权
- `Resource Server`：资源服务器，存放资源

资源服务器和认证服务器可以在一台机器上，也可以分开。

## OAuth 的思路

OAuth 的核心思路，就是在客户端和服务提供方之间加一层授权。

客户端不能直接拿用户账号密码去登录服务提供方，而是先去拿授权。拿到授权之后，再换 token，最后再拿 token 去访问资源。

这样做的好处是：

- 用户不用把密码给第三方应用
- 权限可以收敛，只开放一部分资源
- token 可以设置有效期，过期之后重新获取

## 以授权码模式看一遍流程

授权码模式最常见，可以先用它把整体流程过一遍。

<img src="/images/oauth/authorization-code.svg" alt="OAuth 授权码模式流程" style="width: 100%; max-width: 760px; height: auto;">

大致流程是这样：

1. 用户访问第三方应用，也就是客户端。
2. 客户端把用户重定向到认证服务器。
3. 请求里会带上 `response_type=code`、`client_id`、`redirect_uri`、`scope` 这些参数。
4. 用户同意授权后，认证服务器重定向回 `redirect_uri`，并附带授权码 `code`。
5. 客户端再拿 `client_id`、`client_secret` 和 `code` 去认证服务器换 token。
6. 认证服务器校验通过后，会返回 `access_token`，很多时候也会一起返回 `refresh_token`。
7. 客户端再拿 `access_token` 去资源服务器取资源。

这里有两个点比较关键：

- 授权码模式下，客户端不会直接拿到用户密码
- 换 token 这一步通常发生在服务端，对用户不可见

## 几种授权模式

### 授权码模式

这是最常见的一种。

<img src="/images/oauth/authorization-code.svg" alt="授权码模式" style="width: 100%; max-width: 760px; height: auto;">

特点：

- 安全性相对更好
- 适合有后端的应用
- 也是现在最常用的一种模式

### 简化模式

简化模式会直接把 `access_token` 放在重定向 URI 里返回，不再经过“先拿 code 再换 token”这一步。

<img src="/images/oauth/implicit.svg" alt="简化模式" style="width: 100%; max-width: 760px; height: auto;">

特点：

- 流程更短
- token 直接暴露在前端环境里
- 现在已经不太推荐了

### 密码模式

密码模式最直接，用户把账号密码直接给客户端，客户端再拿着账号密码去认证服务器换 token。

<img src="/images/oauth/password.svg" alt="密码模式" style="width: 100%; max-width: 760px; height: auto;">

特点：

- 流程简单
- 客户端直接接触用户密码
- 只有在高度信任客户端时才会考虑

### 客户端模式

客户端模式不涉及用户，直接由客户端以自己的身份去申请 token。

<img src="/images/oauth/client-credentials.svg" alt="客户端模式" style="width: 100%; max-width: 760px; height: auto;">

特点：

- 不面向用户授权
- 更像服务和服务之间调用
- 常见于内部服务、后台任务这类场景
