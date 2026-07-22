# MenuetOS Web

在浏览器中直接运行 MenuetOS。页面通过 GitHub Pages 托管，使用 v86 将 x86 指令转换为 WebAssembly，并从本地软盘镜像启动 Menuet32 0.86B。定制镜像会自动启用 RTL8029 兼容网卡，并通过 WISP 接入网络。

## 工作原理

```text
浏览器访问 github.io
        |
        v
加载 HTML + v86 JS/WASM + BIOS + 1.44MB 软盘镜像
        |
        v
v86 模拟 x86 PC、VGA、键盘、鼠标和软盘控制器
        |
        v
SeaBIOS 从虚拟软盘启动 Menuet32
        |
        v
RTL8029/NE2000 <-> v86 WISP <-> Internet
```

这与原仓库的 iPXE 方案不同。iPXE 在真实电脑上下载 Linux 内核和 initramfs，然后把控制权交给内核；普通网页没有原生启动硬件的权限，因此浏览器版本必须模拟整台 x86 PC。

## 本地运行

静态资源由 XHR 加载，不能直接双击 `index.html`。在仓库根目录启动 HTTP 服务：

```bash
python3 -m http.server 8000
```

然后打开 `http://localhost:8000/`。

## 发布到 GitHub Pages

1. 把当前目录推送到 GitHub 仓库的默认分支。
2. 打开仓库的 `Settings > Pages`。
3. 在 `Build and deployment` 中选择 `Deploy from a branch`。
4. 选择默认分支和 `/ (root)`，保存。

页面地址通常是：

```text
https://<用户名>.github.io/<仓库名>/
```

所有资源都使用相对路径，因此项目 Pages 和用户主页 Pages 都可部署，不需要修改 URL。

## 网络

GitHub Pages 默认使用 `wisps://wisp.mercurywork.shop/`，本地页面默认使用 `wss://relay.widgetry.org/`。也可以通过 `?network=wisp`、`?network=wsproxy` 或 `?network=fetch` 手动选择后端。

定制内核启动时会自动探测 v86 的 RTL8029 兼容网卡，并应用以下配置：

```text
IP      192.168.86.100
Gateway 192.168.86.1
Subnet  255.255.255.0
DNS     192.168.86.1
```

Menuet32 0.86B 自带的 `HTTPC` 是早期纯 HTTP 浏览器，不支持现代 HTTPS 和 JavaScript。可使用 `http://neverssl.com/` 测试网页访问；网络状态可从系统的 `NET` 菜单打开 `ETHSTAT` 或 `STACKCFG` 查看。

### 重建联网内核

官方内核源码中的 `STACK.INC` 使用 CRLF 换行。解压 `sources/K086B.ZIP` 后先统一该文件的换行，再应用补丁并使用 FASM 1.73.32 编译：

```bash
sed -i 's/\r$//' STACK.INC
patch -p0 < menuetos-v86-network.patch
fasm KERNEL.ASM kernel.mnt
```

生成的 `kernel.mnt` SHA-256 应为 `042784d9376905e4d6256ce39a578a69801067003d2a5c59a878b8f1a245024e`。

## 目录结构

```text
.
├── index.html                     # 页面结构
├── styles.css                     # 模拟器界面
├── app.js                         # v86 初始化与控制逻辑
├── assets/menuetos-0.86b.img      # 官方原始启动软盘
├── assets/menuetos-0.86b-network.img # 自动启用 v86 网络的定制启动软盘
├── vendor/v86/                    # v86、WASM、SeaBIOS、VGA BIOS
├── sources/K086B.ZIP              # Menuet32 内核源码
├── sources/A086B.ZIP              # Menuet32 应用源码
└── licenses/                      # 第三方许可
```

## 版本与许可

- Menuet32 0.86B 采用 GPLv2。启动镜像和对应源码来自 MenuetOS 官方 SourceForge 发布目录。
- 定制内核的源码改动见 `sources/menuetos-v86-network.patch`。
- v86 0.5.424 采用 BSD-2-Clause。
- SeaBIOS/VGABIOS 随 v86 官方仓库发布，各组件许可见上游项目。

本项目使用 Menuet32 而不是 Menuet64。Menuet64 许可禁止未经版权所有者同意进行再分发，而且 v86 当前不模拟 x86-64 指令集；把 Menuet64 镜像提交到公开 Pages 仓库既不合规，也无法由当前 v86 启动。

第三方来源与校验值见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
