# MenuetOS Web

在浏览器中直接运行 MenuetOS。页面通过 GitHub Pages 托管，使用 v86 将 x86 指令转换为 WebAssembly，并从本地软盘镜像启动 Menuet32 0.86B。

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

## 目录结构

```text
.
├── index.html                     # 页面结构
├── styles.css                     # 模拟器界面
├── app.js                         # v86 初始化与控制逻辑
├── assets/menuetos-0.86b.img      # Menuet32 启动软盘
├── vendor/v86/                    # v86、WASM、SeaBIOS、VGA BIOS
├── sources/K086B.ZIP              # Menuet32 内核源码
├── sources/A086B.ZIP              # Menuet32 应用源码
└── licenses/                      # 第三方许可
```

## 版本与许可

- Menuet32 0.86B 采用 GPLv2。启动镜像和对应源码来自 MenuetOS 官方 SourceForge 发布目录。
- v86 0.5.424 采用 BSD-2-Clause。
- SeaBIOS/VGABIOS 随 v86 官方仓库发布，各组件许可见上游项目。

本项目使用 Menuet32 而不是 Menuet64。Menuet64 许可禁止未经版权所有者同意进行再分发，而且 v86 当前不模拟 x86-64 指令集；把 Menuet64 镜像提交到公开 Pages 仓库既不合规，也无法由当前 v86 启动。

第三方来源与校验值见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
