---
name: doc-evolution
description: "当需要：(1) 更新代码后自动同步文档，(2) 根据 git diff 识别需要更新的文档，(3) 通过 intent 查询相关文档和 anchor，(4) 维护文档与代码的同步时使用。"
---

# doc-evolution

Context-Aware Documentation Maintenance Pipeline (基于语义索引的文档自维护机制).

## 触发条件

在以下场景使用此 skill:

1. 代码变更后需要同步更新文档
2. 需要根据 git diff 识别受影响的文档
3. 需要通过 intent 查询相关文档和 anchor
4. 需要维护文档与代码的长期同步

## 工作流程编排

```
Code Change
    ↓
[doc.check] (渐进过滤 + 语义判断)
    ↓
Structured Decisions (high/medium/low)
    ↓
┌───────────────┬───────────────┬───────────────┐
↓               ↓               ↓               ↓
high            medium          low            ↓
↓               ↓               ↓              ↓
doc.update      建议 doc.gen     忽略        doc.index
    ↓                                           ↑
[doc.index] (更新索引状态) ←─────────────────┘
```

### 决策处理

| certainty | 含义 | 行为 |
|-----------|------|------|
| high | 明确影响 | 自动触发 doc.update |
| medium | 可能影响 | 建议 doc.gen（补全或重构） |
| low | 无影响 | 忽略，无需操作 |

## 子 skill 调用规则

### 1. 调用 doc.check

当需要分析代码变更对文档的影响时:
- 输入: git diff 或代码变更内容
- 输出: 结构化决策列表 (certainty: high/medium/low)

```bash
# 触发 doc.check 分析
doc.check --diff <变更内容>
```

### 2. 调用 doc.update

当 doc.check 返回 high certainty 时:
- 输入: doc_path, doc_type, diff_summary, reason
- 输出: patch 格式的文档更新
- 约束: 只做局部修改，不改结构

```bash
# 自动执行 doc.update (certainty = high)
doc.update --doc-path <路径> --doc-type <类型> --reason <原因>
```

### 3. 调用 doc.gen

当 doc.check 返回 medium certainty 时:
- 输入: doc_path, mode (Init/Augment/Refactor), reason
- 输出: 文档结构生成或重构
- 特权: 可以改结构、新文档、跨文档

```bash
# 补全缺失内容 (Augment)
doc.gen --doc-path <路径> --mode augment --reason <原因>

# 重构混乱文档 (Refactor)
doc.gen --doc-path <路径> --mode refactor --reason <原因>

# 初始化新模块文档 (Init)
doc.gen --module <模块名> --mode init
```

### 4. 调用 doc.index

当 doc.update 完成后:
- 输入: 更新的文档路径
- 输出: 更新后的 graph.json 和 index.md

```bash
# 刷新索引
doc.index --update --path <文档路径>
```

## 输出格式

### 状态报告结构

```markdown
## Documentation Evolution Report

### Analysis Summary
- Modules affected: <数量>
- Docs to update (high): <数量>
- Docs to review (medium): <数量>
- Docs ignored (low): <数量>

### Detailed Decisions
| Module | Doc Type | Decision | Certainty | Reason |
|--------|----------|----------|-----------|--------|
| auth   | design   | update_required | high | OAuth flow added |

### Actions Taken
- Updated: <文件路径>
- Pending review: <文件路径>

### Index Status
- graph.json: updated
- index.md: updated
```

### 错误处理

- doc.check 失败: 报告错误，终止流程
- doc.update 失败: 回滚更改，报告错误
- doc.index 失败: 警告但继续 (索引可手动修复)

## 调用示例

### 完整流程

```bash
# 1. 代码变更后触发分析
doc-evolution --trigger post-commit

# 2. 仅查询影响 (不更新)
doc-evolution --check-only --diff $(git diff HEAD~1)

# 3. 强制刷新索引
doc-evolution --reindex

# 4. 查看状态
doc-evolution --status
```

### 单步操作

```bash
# 仅检查影响
doc-evolution check --module auth

# 仅更新指定文档 (high certainty)
doc-evolution update --doc-path docs/design/modules/auth/index.md

# 补全缺失内容 (medium certainty)
doc-evolution gen --doc-path docs/design/modules/auth/index.md --mode augment

# 重构文档结构 (medium certainty)
doc-evolution gen --doc-path docs/design/modules/auth/index.md --mode refactor

# 初始化新模块文档
doc-evolution gen --module auth --mode init

# 仅刷新索引
doc-evolution index
```

## 约束原则

1. **渐进式加载**: 不相关文档永不加载
2. **最小修改**: patch 级修改，不重写全文
3. **结构锁**: 不删除章节、不重排结构
4. **风格继承**: 遵循原有术语、标题层级、表达风格
