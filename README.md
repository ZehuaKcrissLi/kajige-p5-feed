# 咔鸡哥 P6 团本训练服 · 清单镜像

这个仓库只放几个很小的清单文件，体积刻意控制在 jsDelivr 的 50 MB 整仓上限之内，
好让启动器在中国大陆多一条独立线路来读取更新清单。

安装包、资源包和增量更新数据在主镜像仓：
<https://github.com/ZehuaKcrissLi/kajige-p5-dist>

普通玩家不需要来这里，直接去主镜像仓下载安装器即可。

## 内容

| 路径 | 说明 |
| --- | --- |
| `release.json` | 发布清单，含全部文件大小、SHA-256 与镜像配置 |
| `SHA256SUMS.txt` | 站点根目录全部文件的校验值 |
| `install-mac.sh` | macOS 一行命令安装脚本 |
| `client-sources-v1.json`(`.sig`) | 已签名的客户端下载源清单 |
| `updates/stable/manifest-v2.json`(`.sig`) | Ed25519 签名的增量更新清单 |
| `*.torrent` | 简中 12340 客户端种子元数据 |

路径与官方站点 <https://kaji-training.kcriss.dev> 一一对应，例如
`https://kaji-training.kcriss.dev/updates/stable/manifest-v2.json` 对应
`https://cdn.jsdelivr.net/gh/ZehuaKcrissLi/kajige-p5-feed@main/updates/stable/manifest-v2.json`。

所有内容都带 Ed25519 签名或固定 SHA-256 校验，镜像只影响下载速度，不影响安装内容。
