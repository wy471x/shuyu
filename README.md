# 漱玉 Shuyu

> 清泉漱玉,字字珠璣 —— 李清照《漱玉詞》

漱玉是一款为 [Omarchy](https://omarchy.org/) 打造的中文输入法插件,基于 fcitx5 + Rime:

- **漱玉 · 自然码双拼**(主方案)——键位同自然码(sh→U、ch→I、zh→V、iu→Q、uo→O、ou→B、in→N…)
- **漱玉 · 全拼**(副方案)——同一份词库,随时切换
- **漱玉词库**——收录《漱玉词》及唐宋诗词意象词汇(漱玉、疏影、暗香、绿肥红瘦、如梦令、声声慢…),双拼/全拼两方案共用
- **墨玉主题**——宣纸色正文、玉色候选、深墨底色,衬线字体(Noto Serif CJK SC)
- **状态栏组件**——显示当前输入状态,左键切换中英文,右键/滚轮切换双拼/全拼方案

## 依赖

需要以下系统包(安装需 root 权限,通过发行版包管理器完成):

| 包 | 说明 |
|---|---|
| fcitx5 | ≥ 5.1.13(含 `fcitx5-remote` 与 DBus 服务) |
| fcitx5-rime | Rime 引擎封装(提供 `/rime` DBus 接口) |
| rime-double-pinyin | 自然码双拼方案数据(algebra 与词库) |
| noto-fonts-cjk | 墨玉主题使用的衬线字体(可选) |

Omarchy 自带 fcitx5 集成;fcitx5-rime 与 rime-double-pinyin 需另行安装。

## 安装

```bash
# 1. 安装系统依赖
omarchy pkg add fcitx5-rime rime-double-pinyin

# 2. 安装本插件(状态栏组件)
omarchy plugin add https://github.com/wy471x/shuyu --enable
omarchy bar put io.github.wy471x.shuyu --after omarchy.keyboard-layout

# 3. 部署 rime 方案、墨玉主题与 fcitx5 配置
cd ~/.config/omarchy/plugins/io.github.wy471x.shuyu
./deploy.sh

# 4. 重启输入法并切到 rime
omarchy restart xcompose
```

首次切换到 rime 时自动编译方案(数秒)。也可手动部署 rime 词库:

```bash
rime_deployer --build ~/.local/share/fcitx5/rime /usr/share/rime-data
```

## 使用

| 操作 | 方式 |
|---|---|
| 中英文切换 | 左键点击状态栏「漱/EN」,或 Ctrl+Space |
| 双拼 / 全拼切换 | 右键或滚轮状态栏组件,或 Ctrl+Shift+1(双拼)/ Ctrl+Shift+2(全拼) |
| 方案菜单 | Ctrl+` 或 F4 |
| 笔画反查 | ` + 笔画(hspnz = 一丨丿丶乙) |

验收示例(自然码双拼):`uuyu` → 漱玉、`myyt` → 明月、`qyqr` → 清泉、`lvfzhsub` → 绿肥红瘦。

组件可在 `~/.config/omarchy/shell.json` 的布局条目中按需配置:

- `shuangpinSchemaId` / `quanpinSchemaId` — 双拼/全拼方案 id(默认 `shuyu` / `shuyu_pinyin`)
- `pollIntervalMs` — 状态轮询间隔毫秒(默认 500)

## 卸载

```bash
# 1. 撤销 rime 方案、主题与 fcitx5 配置部署(profile 备份保留在原目录 *.bak.* 文件)
cd ~/.config/omarchy/plugins/io.github.wy471x.shuyu && ./deploy.sh remove

# 2. 移除状态栏组件并重启
omarchy plugin remove io.github.wy471x.shuyu
omarchy restart xcompose
```

系统包 fcitx5-rime 与 rime-double-pinyin 可保留,亦可经包管理器移除。

## 安全说明

- 组件运行于 omarchy-shell 进程内,仅通过 `fcitx5-remote` 与 `dbus-send` 查询/切换本机 fcitx5 状态,不访问网络,不修改文件。
- `deploy.sh` 只写入用户级文件(`~/.local/share/fcitx5/`、`~/.config/fcitx5/`),写入前备份 profile,可经 `./deploy.sh remove` 撤销。
- 项目不含任何远程代码下载与执行。

## 许可证

[MIT](LICENSE) · 词库文字取自公有领域古典诗词作品。
