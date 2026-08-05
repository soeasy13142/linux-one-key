# Third-Party Notices

本项目在遵守各上游许可的前提下，包含/引用了以下第三方代码与资源。

## Vendored Code

### SuperManito/LinuxMirrors — 软件源更换功能

- **源项目**: https://github.com/SuperManito/LinuxMirrors
- **作者**: [SuperManito](https://github.com/SuperManito)
- **许可**: MIT License
- **用途**: 主菜单「更换软件源」选项的核心换源逻辑与完整交互流程
- **涉及文件**:
  - `scripts/server/mirrors/lm_core.sh` — 改编自上游 `ChangeMirrors.sh`（完整版）
- **改编说明**: 仅替换了 i18n 层（`msg()` 改读宿主项目 `MSG_MIRROR_*` 语言键，语言包移入 `scripts/lang/zh.sh` / `scripts/lang/en.sh`）并将脚本尾部自动执行改为入口函数 `lm_main()`（由宿主在 subshell 内调用）。其余换源逻辑、发行版 repo 生成器、交互流程均原样保留。

#### MIT License

```
MIT License

Copyright (c) 2026 SuperManito

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Reference Material (not vendored)

其他仅作为设计参考的非代码资源（安全基准、框架等）见 [`README.md`](README.md) 的「参考资料 / References」与「致谢 / Acknowledgements」章节。
