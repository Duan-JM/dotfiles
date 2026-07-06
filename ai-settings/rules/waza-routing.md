# Waza Routing

Waza ships eight installed skills. When a request matches a trigger below, prefer the matching skill over a generic implementation. Do not reimplement the workflow from scratch.

| skill   | use when                                                                                  |
|---------|-------------------------------------------------------------------------------------------|
| think   | new feature / architecture / "怎么设计" / "有没有必要" / "值不值得" / product judgment    |
| ui      | UI / page / component / frontend / typography / screenshot says "丑/不清晰/不和谐"        |
| check   | review / "看看代码" / pre-merge / "继续优化" / release / push / close issue / project audit |
| hunt    | error / crash / regression / test failure / "以前是好的" / screenshot proves regression    |
| write   | draft / rewrite / proofread / "去 AI 味" / tweet / launch copy / document review          |
| learn   | deep dive into an unfamiliar domain / compile a batch of sources into one article         |
| read    | message contains an http(s) URL or PDF path / "看这个链接" / "读一下"                      |
| health  | Claude/Codex/Pi ignores instructions / hook misfire / config drift / agent config audit / rot |

When two skills both match, read both `SKILL.md` "Not for" sections to disambiguate. Still ambiguous, ask the user. Never silently pick one.

Full routing table with chaining and disambiguation: <https://github.com/tw93/Waza/blob/main/skills/RESOLVER.md>
