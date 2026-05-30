# Git 提交规范

本项目使用 Conventional Commits 简化格式：

```text
<type>: <subject>
```

## type 类型

- `feat`: 新功能、新页面、新主题能力
- `fix`: 修复错误、构建失败、页面异常
- `docs`: 文档修改
- `style`: 样式、排版、格式调整，不改变内容逻辑
- `refactor`: 代码或模板重构，不改变功能
- `chore`: 配置、依赖、子模块、构建工具调整
- `content`: 博客正文、图片、文章元信息修改

## subject 写法

- 使用中文或英文均可，但同一次提交保持一致
- 用一句话说明这次提交做了什么
- 不以句号结尾
- 尽量控制在 50 字以内

## 示例

```text
feat: 切换博客主题为 Hugo Archie
style: 调整 Archie 主题下的文章阅读样式
docs: 添加 Git 提交规范
content: 更新热量相关概念文章
fix: 修复搜索页无法生成的问题
chore: 更新 Hugo 主题子模块
```

## 提交建议

一次提交只做一类事情。主题切换、文章修改、样式调整、文档补充尽量分开提交。
