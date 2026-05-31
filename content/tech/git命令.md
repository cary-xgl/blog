---
title: "Git命令"
date: 2022-05-06
tags: ["Git"]
categories: ["技术"]
---


> 常见的git命令
<!--more-->

## Git 分布式版本控制系统

## 提交规范

- 功能：实现新功能
- 修复：修复漏洞
- 重构：对已有功能做修改，既不属于功能，也不属于修复，但涉及代码逻辑调整
- 文档：新增或修改文档、注释
- 格式化：只做代码格式调整，比如缩进、多余空行
- 测试：新增或修改测试用例
- 框架：新增或修改独立配置文件，或者升级依赖版本
- Merge：Hotfix、Release 关闭时，需要审查者手动合并分支时使用

## git flow

`git flow` 本质上是把 Git 的一些常用流程封装起来，方便团队约定分支规范。

默认一般会设两个主分支：

- `master`
- `develop`

常见的约定分支还有：

- `feature/...`：新功能
- `release/...`：版本分支
- `hotfix/...`：紧急 bug

## user & email

安装完 Git 后，一般先设置用户名和邮箱。`--global` 表示这台机器上的所有 Git 仓库都会使用这个配置。

```bash
git config --global user.name "Your Name"
git config --global user.email "email@example.com"
```

## 设置版本库

`git init` 默认会在当前目录初始化版本库，执行后目录下会出现一个 `.git` 文件夹。  
也可以在后面指定目录，比如 `/d/test`。

```bash
git init
```

## 常用命令

### 查看状态

```bash
git status
```

查看当前工作区的状态。

### add 与 commit

```bash
git add test.txt
git add file2.txt file3.txt
git commit -m "这是一些提示信息，用来告诉查看者这个文件做了什么修改"
```

- `git add` 是把工作区里的修改放进暂存区
- `git commit` 是把暂存区里的内容提交到分支上
- 一次 `commit` 会把暂存区当前的内容一起提交

`master` 里有一个 `HEAD` 指针，用来指向最近一次提交。因为是基于指针在走，所以回退这类操作通常很快。

有个容易漏的点：

如果第一次改完后执行了 `git add test.txt`，随后你又继续改了这个文件，那么这第二次修改并不会自动进暂存区。此时 `git commit` 提交的仍然只是第一次 `add` 进去的内容，要想把后面的修改也提交上去，还得再执行一次 `git add`。  
所以 Git 提交的是“修改”，不是“文件”。

### merge

```bash
git merge --no-ff -m "merge with no-ff" dev
```

强制不走快速合并，这样可以保留分支信息。`-m` 后面跟的是这次合并的说明。

### stash

```bash
git stash
git stash pop
```

- `git stash`：先把现场藏起来，适合中途去处理别的紧急事情
- `git stash pop`：回到之前的工作现场

### 远程相关

```bash
git remote -v
git push origin master
git checkout -b dev origin/dev
git push origin dev
git pull origin 分支名
git branch --set-upstream-to=origin/dev dev
git push origin v1.0
```

- `git remote -v`：查看远程库信息
- 本地新建的分支如果不推送到远程，别人是看不到的
- 远程默认一般叫 `origin`
- `git checkout -b dev origin/dev`：创建远程分支对应的本地分支，最好命名一致
- `git pull` 基本可以理解成 `git fetch + git merge`

### 别名

```bash
git config --global alias.st status
```

给命令配别名，主要是偷懒用。

### blame

```bash
git blame -L 150,+10 file_path
```

查看某个文件某一段的变动历史。

### diff

```bash
git diff test.txt
git diff HEAD -- readme.txt
```

- `git diff test.txt`：配合 `git status` 看某个文件改了什么
- `git diff HEAD -- readme.txt`：看工作区和版本库最新版本之间的区别

### 分支操作

```bash
git checkout -b dev
git branch dev
git checkout dev
git branch
git merge dev
git branch -d dev
git branch -D dev_test
```

- `git checkout -b dev` 相当于先创建分支，再切换过去
- `git branch` 用来查看所有分支，当前分支前面会有 `*`
- `git branch -D` 用来强制删除一个还没合并的分支

### 放弃修改、删除文件、SSH

```bash
git checkout -- test.txt
git rm test.txt
ssh-keygen -t rsa -C "youremail@example.com"
git remote add origin git@github.com:michaelliao/learngit.git
```

- `git checkout -- test.txt`：让文件回到最近一次 `git commit` 或 `git add` 时的状态
- `git rm test.txt`：删除本地文件，配合 `git commit` 可以把版本库中的文件也删掉；如果是误删，也可以再从版本库里恢复
- `ssh-keygen` 用来生成 SSH 密钥，会生成 `id_rsa` 和 `id_rsa.pub`
- `git remote add origin ...` 用来把本地仓库和远程仓库关联起来，用户名记得替换成自己的

从远程仓库拉代码到本地时，用 `clone` 即可，协议可以是 SSH，也可以是 HTTP。

## git log

```bash
git log --pretty=oneline
git log --graph
```

- `git log --pretty=oneline`：过滤输出信息，只保留一行，前面是唯一的版本号 id，后面是提交说明
- `git log --graph`：查看分支合并图

## 回退版本

```bash
git reset --hard HEAD^
git reset HEAD test.txt
git reflog
```

- `git reset --hard HEAD^`：当前版本回退到上一个版本
- `HEAD^^`：回退两个版本
- `HEAD~10`：回退十个版本
- `git reset HEAD test.txt`：把暂存区里的文件退回工作区
- `git reflog`：记录每一次命令，适合回退之后又想回到新版本的时候用

如果文件只是提交到了本地版本库，回退通常还能处理；但如果已经推到远程了，处理起来就会麻烦很多。

## git tag

```bash
git tag v1.0
git tag
git tag v0.9 f52c633
git tag -a v0.1 -m "version 0.1 released" 1094adb
git show v0.1
git tag -d v0.1
git push origin :refs/tags/v0.9
```

- `git tag v1.0`：打标签，有点像给当前提交做一个快照
- `git tag`：查看所有标签
- `git tag v0.9 f52c633`：给历史上的某个提交打标签
- `git tag -a ... -m ...`：创建带说明文字的标签
- `git show v0.1`：查看标签对应的信息
- 标签总是和 `commit` 挂钩，如果某个提交同时出现在 `master` 和 `dev` 上，这两个分支都能看到这个标签
- 标签如果已经推到远程，要先删本地，再删远程

## cherry-pick

```bash
git cherry-pick [commit]
```

可以把某个分支上的单个或多个提交拿到另一个分支，而不用把整个分支都合过来。

比如现在在 `dev` 分支上，只想把某个 `feature` 的几个提交拿过来，直接执行 `git cherry-pick [commit]` 就行，不必把整个分支一起带过来。

## git rebase

`git rebase` 常用在本地分支和远程分支有冲突的时候。

比如：

- 远程分支当前是 `O1`
- 本地分支当前是 `L1`

你在本地做了修改，提交时也没有先执行 `pull`，这时候再去 `push`，如果发现有冲突，通常说明已经有人先一步把代码提交到了远程，此时远程分支就变成了 `O2`。

如果你这时直接在本地 `merge` 完再提交到远程，Git 提交曲线通常会多出一条分叉；  
如果先执行 `git rebase`，再推到远程，最后的提交历史通常会更像一条直线。

