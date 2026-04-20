# Doc Evolution Architecture

## 系统目标

> 构建一个**基于语义索引的文档维护系统**，在代码变更后自动感知影响、判断文档是否过期，并以最小修改方式持续更新文档，保证文档长期不过期。

核心特征:

- 渐进式分析 (避免全量扫描)
- 语义判断 (而非规则判断)
- 最小修改 (patch级更新)
- 弱自动化 (可控，不强制阻断)
- 上下文隔离 (控制 token 成本)

---

## 整体架构

```text
Code Change
    ↓
[doc.check]
(渐进式语义分析)
    ↓
Structured Decisions
    ↓
┌───────────────┬───────────────┬───────────────┐
↓               ↓               ↓               ↓
high            medium          low             ↓
↓               ↓               ↓               ↓
doc.update      建议 doc.gen     忽略           doc.index
    ↓                                           ↑
[doc.index] (状态更新) ←─────────────────────────┘
```

### Git-History Batch Sync Flow

```text
"doc-evolution --sync"
    ↓
Read _meta.lastDocSyncRef from graph.json
    ↓ (fallback: git log -1 -- docs/)
git diff <ref>..HEAD -- ':(exclude)docs/**'
    ↓
┌─────────────┐
│ Empty diff? │──YES──→ Report "no changes", exit
└──────┬──────┘
       NO
       ↓
[doc.check] (two-phase analysis)
       ↓
Process by certainty (high→update, medium→recommend)
       ↓
[doc.index] (refresh signatures)
       ↓
Write _meta.lastDocSyncRef = HEAD hash
```

## 四者关系

| Skill | 职责 | 触发条件 |
|-------|------|----------|
| doc.index | 语义索引（基础设施） | 初始化/定期维护 |
| doc.check | 影响分析（感知层） | 代码变更后 |
| doc.update | 局部修复（维护层） | certainty = high |
| doc.gen | 生成/重构（演化层） | certainty = medium |

---

## 目录结构 (最终版)

```bash
/docs
  graph.json          # 机器可读索引（直接放在 docs/ 下，不建子目录）
  index.md            # 人类可读状态报告（与 graph.json 同级）

  /design
    /modules/{module}/index.md
    /system

  /api
    /rest/{module}.md
    openapi.yaml

  /dev
    setup.md
    conventions.md

  /ops
    deploy.md
    ci-cd.md

  /user
    {module}.md
```

---

## 核心数据模型 (docs/graph.json)

### 完整结构

```json
{
  "_meta": {
    "lastDocSyncRef": "9f2ca690b41e11c3"
  },
  "auth": {
    "code_paths": ["src/modules/auth/**"],
    "module_summary": "Authentication subsystem responsible for identity verification, token lifecycle, and OAuth integration.",
    "docs": {
      "design": {
        "path": "docs/design/modules/auth/index.md",
        "summary": "Describes authentication mechanisms including login flows, token lifecycle, and OAuth integration."
      },
      "api": {
        "path": "docs/api/rest/auth.md",
        "summary": "Defines authentication endpoints such as login, logout, token refresh, and OAuth callbacks."
      },
      "user": {
        "path": "docs/user/auth.md",
        "summary": "Explains how users sign in, manage sessions, and use third-party login options."
      }
    }
  }
}
```

### 三层语义结构

| 层级 | 作用 |
|---|---|
| code_paths | 硬过滤 |
| module_summary | 模块级语义匹配 |
| doc.summary | 文档级精细匹配 |

### Sync Reference 管理

`_meta.lastDocSyncRef` 是 `graph.json` 中的顶层元数据字段，用于记录文档最后一次同步的 git commit。

| 属性 | 值 |
|---|---|
| 字段路径 | `_meta.lastDocSyncRef` |
| 格式 | 16 字符 short git hash |
| 更新时机 | doc-sync 完成后 / index 完整重建后 |
| 回退策略 | 缺失/无效时用 `git log --format="%H" -1 -- docs/` |
| 验证方式 | `git cat-file -t <ref>` 确认是有效 commit |

### summary 写作规范 (强约束)

每个 summary 必须:

```text
[Scope] + [Core Responsibility] + [Key Concepts]
```

示例:

```text
"Handles authentication including credential login, token lifecycle, and OAuth flows."
```

---

## doc.check (渐进式语义分析)

### 两阶段机制

#### Phase 1: 过滤 (低成本)

```text
Level 0: 路径匹配 (code_paths)
Level 1: diff summary (AI生成一句话)
Level 2: module_summary 语义匹配
Level 3: doc.summary 精细匹配
```

目标: **尽量不进入文档读取**

#### Phase 2: 理解 (高成本)

仅对候选文档:

- 加载文档内容
- 对比 diff
- 进行语义判断

### 输出结构 (固定)

```json
{
  "module": "auth",
  "decisions": [
    {
      "doc": "design",
      "decision": "update_required",
      "certainty": "high",
      "reason": "Authentication flow changed (OAuth added)"
    }
  ]
}
```

### 三态判断 (替代 confidence)

| certainty | 含义 | 行为 |
|---|---|---|
| high | 明确影响 | 自动 doc.update |
| medium | 可能影响 | 建议 doc.gen |
| low | 无影响 | 忽略 |

---

## doc.update (最小上下文更新)

### 核心原则

> doc.update = 单文档、最小上下文、patch级修改

### 输入结构

```json
{
  "doc_path": "...",
  "doc_type": "design",
  "diff_summary": "...",
  "reason": "...",
  "relevant_code": "..."
}
```

### 上下文限制

只加载:

- 当前文档 (必须)
- diff (必须)
- 少量相关代码 (可选)
- index元信息 (极小)

### 禁止加载

- 其他模块文档
- 全局上下文
- 整个 repo

### 输出形式 (必须)

```diff
## Authentication Flow

+ ### OAuth Login
+ - Redirect to provider
+ - Handle callback
```

### 更新策略

| doc 类型 | 默认策略 |
|---|---|
| design | modify |
| api | safe (新增) |
| user | safe |

### 行为模式

#### 自动触发 (doc.check -> doc.update)

```text
if certainty == high → 自动执行
```

#### 用户触发

```bash
claude skill doc.update auth design
```

---

## doc.index (索引系统)

### 职责

1. 构建 graph.json
2. 维护 summary
3. 提供文档状态视图

### index.md (人类可读)

```md
## Modules

| Module | Design | API | User | Status |
|--------|--------|-----|------|--------|
| auth   | ⚠️ outdated | ⚠️ | ✅ | needs update |
```

### graph.json (机器用)

- 路径映射
- 语义描述
- 文档定位

---

## Hook / 触发机制 (弱自动化)

### 推荐触发点

#### 1. post-commit

```bash
→ doc.check
→ 输出分析
```

#### 2. PR Hook (最佳)

输出:

```text
📄 Documentation Impact

auth:
- design → update required
- api → update required
```

#### 3. CI

```bash
doc.check → report
```

(不阻断)

---

## 关键约束 (保证系统稳定)

### 1. 渐进式加载 (必须)

```text
不相关文档 = 永远不加载
```

### 2. 最小修改原则

- 不重写全文
- 不破坏结构
- 优先修改已有 section

### 3. 结构锁

AI不能:

- 删除章节
- 重排结构

### 4. 风格继承

doc.update 必须遵循:

- 原有术语
- 标题层级
- 表达风格

---

## doc.gen (生成/重构系统)

### 核心定义

> doc.gen = 文档结构与内容的**构建与重构能力**

### 三种模式

| 模式 | 用途 | 输出 |
|------|------|------|
| Init | 新模块/新文档 | 结构框架 (## Overview / ## Architecture / ## Flow) |
| Augment | 补全缺失内容 | diff 格式增量 |
| Refactor | 重构混乱文档 | 新结构建议 + 内容迁移方案 |

### doc.gen 特权 (vs doc.update)

| 能力 | doc.update | doc.gen |
|------|------------|---------|
| 小改 | ✅ | ❌ |
| 补内容 | ⚠️ | ✅ |
| 新文档 | ❌ | ✅ |
| 改结构 | ❌ | ✅ |

### 上下文策略

| Level | 内容 |
|-------|------|
| L1 | 当前文档 |
| L2 | diff / code |
| L3 | 同模块文档（仅 refactor） |

---

## 系统本质 (最终抽象)

> **Context-Aware Documentation Maintenance Pipeline**

核心能力:

1. 感知代码变化
2. 基于语义索引过滤上下文
3. 判断文档是否过期
4. 自动生成最小修复补丁

---

## 最小实现路径 (建议落地顺序)

### Step 1: 定义 graph.json (手动)

- module_summary
- doc.summary

👉 这是整个系统的"语义基础设施"

### Step 2: 实现 doc.check (简化版)

- path -> summary 匹配
- 输出 decisions (不自动更新)

### Step 3: 实现 doc.update (patch模式)

- 单文档
- diff -> patch

### Step 4: 接入 PR Hook

- 自动输出影响分析

### Step 5: 接入自动更新 (可选)

- 仅限 certainty = high

---

## 一句话总结

> **doc.check 保证"知道何时过期"，
> doc.update 保证"不会过期"，
> doc.gen 保证"持续进化"。**
