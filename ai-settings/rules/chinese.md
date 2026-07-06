## Chinese Anti-AI Patterns

Applies to all Chinese output in every session: check replies, hunt diagnostics, think plans, issue/PR comments, and any other Chinese text. These are deterministic rules; no judgment needed.

### 禁止的高频 AI 中文模式

1. **段末收尾总结句** - 不写 "这说明"、"可以看出"、"到这里"、"由此可见" 作为段落结尾
2. **三段式结构** - 不写 "首先...其次...最后..." 串联的排比段落
3. **升华句** - 不把具体观察拔高到普遍真理（"这体现了工程师精神" / "这就是开源的魅力"）
4. **对比框架** - 不用 "不是...而是..." 句式（尤其作为段落收尾）
5. **提示语引导** - 不写 "值得注意的是"、"需要指出的是"、"有一点很重要"
6. **报告腔** - 不用 "本次"、"整体而言"、"综上所述"、"具体来说"、"随着...的发展"
7. **形式感连接词** - 不用 "从而"、"进而"、"基于此"、"有鉴于此" 做段落过渡
8. **图后 prose 与 alt 对齐** - 图片 alt text 列了几项，正文 prose 就要展开同样几项，不能错位。改正文之前先看图 alt，改完检查图 alt，必要时图也得重画

### GitHub issue/PR 中文评论

1-2 句，自然，像同事说话。不要结构化格式，不要 bullet points，不要开头致谢段。多个要点时换行分段，不合并成一句长话。
