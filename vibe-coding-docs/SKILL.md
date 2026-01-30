---
name: vibe-coding-docs
description: 管理 vibe-coding 项目的计划、过程文档。负责维护项目文档的完整性、一致性和规范性。在以下场景使用此技能：(1) 需要更新项目文档以反映代码变更时，(2) 需要校验文档与项目进度一致性时，(3) 需要创建新的技术文档或变更记录时，(4) 需要查询或浏览项目文档状态时。所有交互使用中文。
---

# Vibe Coding 文档管理

## 概述

管理 vibe-coding 项目的计划、过程文档，确保文档与项目进度保持同步，维护文档的整洁性和可维护性。

## 工作流程

### 场景判断

首先判断当前情况：

**场景 1: 无修改状态**
- 用户未进行代码修改
- 需要校验或查看文档

**场景 2: 有修改状态**
- 用户已完成代码修改
- 需要更新文档

### 场景 1: 无修改状态

#### 1.1 询问是否需要校验

```
在进行文档管理之前，建议先校验文档与实际项目进度的一致性。
是否需要进行文档校验？
```

如果用户同意，执行校验；否则跳过。

#### 1.2 执行校验（如需要）

1. 读取 `docs/plan/plan.md` 获取：
   - 当前版本号
   - 已实现内容
   - 待实现内容

2. 验证一致性：
   - 检查项目代码是否与"已实现内容"匹配
   - 检查 `docs/archive/` 和 `docs/technical/` 是否有对应版本目录
   - 检查 CLAUDE.md 中的文档索引是否准确

3. 生成校验报告：
   - 列出发现的不一致项
   - 提供修正建议

#### 1.3 响应用户需求

根据用户的具体需求（查询、浏览、统计等）读取相应文档并返回结构化信息。

### 场景 2: 有修改状态

#### 2.1 确定版本号

询问用户当前版本号，格式：`v{MAJOR}.{MINOR}`

如果版本目录不存在，创建：
- `docs/archive/v{VERSION}/`
- `docs/technical/v{VERSION}/`

#### 2.2 收集变更信息

通过以下方式收集：
- 查看 `git status` 或 `git diff` 了解修改内容
- 询问用户：本次修改的目的、影响范围、是否涉及技术细节

#### 2.3 更新 plan.md

1. **更新版本信息**：修改"当前版本"和"最后更新"日期
2. **更新已实现内容**：将新完成的功能从"待实现"移至"已实现"
3. **调整待实现内容**：根据实际情况增删任务
4. **保持整洁**：
   - 使用列表而非段落
   - 避免冗长描述
   - 详细内容使用相对路径引用子文档

示例：
```markdown
## 已实现内容

### 版本 v1.1
- 用户认证系统
- 数据库连接池

详细实现见: [v1.1 技术文档](../technical/v1.1/)
```

#### 2.4 创建 archive 文档

1. 在 `docs/archive/v{VERSION}/` 创建文件
2. 文件命名：`YYYY-MM-DD-{标题}.md`
3. 使用模板：[assets/archive_template.md](assets/archive_template.md)
4. 记录内容：
   - 变更概述
   - 详细变更项（含相关文件路径）
   - 测试结果（如适用）

#### 2.5 创建 technical 文档（如需要）

当修改涉及以下情况时创建：
- 技术方案设计
- Bug 修复
- 架构变更
- 代码实现细节

1. 在 `docs/technical/v{VERSION}/` 创建文件
2. 文件命名：`YYYY-MM-DD-{标题}.md`
3. 使用模板：[assets/technical_template.md](assets/technical_template.md)
4. 记录内容：
   - 问题描述
   - 解决方案（含代码示例）
   - 相关文件
   - 测试验证
   - 使用 mermaid 绘制流程图（可选）

#### 2.6 检查文档长度

- **plan.md**: 超过 500 行时，将详细规划拆分到子文档
- **archive/technical 文档**: 超过 800 行时，按主题拆分为多个子文档
- 使用相对路径引用：
  ```markdown
  详细信息见: [子文档标题](./subdoc.md)
  ```

#### 2.7 更新 CLAUDE.md

1. 定位到项目文档章节
2. 更新内容：

```markdown
## 项目文档

### 文档结构
- [项目计划](docs/plan/plan.md) - 当前版本: v{VERSION} | 已实现: X 项 | 待实现: Y 项
- [历史记录](docs/archive/) - 按版本归档的变更和测试记录
- [技术文档](docs/technical/) - 按版本归档的技术细节和方案

### 快速导航

#### v{VERSION} (当前)
- 计划: [plan.md](docs/plan/plan.md)
- 变更记录: [最新变更](docs/archive/v{VERSION}/YYYY-MM-DD-变更记录.md)
- 技术文档: [技术方案](docs/technical/v{VERSION}/YYYY-MM-DD-技术方案.md)

#### 历史版本
- v{PREV_VERSION}: [归档](docs/archive/v{PREV_VERSION}/) | [技术](docs/technical/v{PREV_VERSION}/)
```

3. 确保所有新创建的文档都有对应的链接和概要

## 文档结构规范

详细规范见 [references/document-structure.md](references/document-structure.md)

### 目录结构

```
docs/
├── plan/
│   └── plan.md                 # 项目主计划（唯一）
├── archive/
│   ├── v1.0/
│   │   ├── 2025-01-15-变更记录.md
│   │   └── 2025-01-20-测试记录.md
│   └── v1.1/
│       └── 2025-02-01-发布记录.md
└── technical/
    ├── v1.0/
    │   ├── 2025-01-10-认证方案.md
    │   └── 2025-01-18-Bug修复.md
    └── v1.1/
        └── 2025-02-05-数据库设计.md
```

### 命名规范

- **版本目录**: `v{MAJOR}.{MINOR}`
- **文档文件**: `YYYY-MM-DD-{标题}.md`

## 工作原则

1. **初始校验优先**: 无修改时先询问是否需要校验
2. **同步更新**: 修改后立即更新所有相关文档
3. **保持整洁**: plan.md 绝对整洁，其他文档避免过长
4. **索引维护**: 每次操作后更新 CLAUDE.md 文档索引

## 资源

### assets/

文档模板，用于创建新文档：

- **plan_template.md**: 项目计划模板
- **archive_template.md**: 变更记录模板
- **technical_template.md**: 技术文档模板

使用方式：复制模板到目标位置，替换占位符（`{VERSION}`, `{DATE}`, `{TITLE}` 等）

### references/

- **document-structure.md**: 详细的文档结构规范
- **workflow-guide.md**: 完整的工作流程指南

在需要深入了解规范或流程时参考这些文档。
