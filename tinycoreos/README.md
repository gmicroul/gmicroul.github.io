# TinyCore Web Desktop

通过浏览器运行带图形桌面的 TinyCore Linux。项目是纯静态 GitHub Pages 应用：v86 在 WebAssembly 中模拟 x86 PC，SeaBIOS 从本地 TinyCore ISO 启动系统。

## 工作原理

```text
浏览器访问 GitHub Pages
        |
        v
加载 v86 JS/WASM、SeaBIOS、VGA BIOS 和 TinyCore ISO
        |
        v
v86 模拟 x86 CPU、VGA、键盘、鼠标、IDE CD-ROM
        |
        v
SeaBIOS 从虚拟 CD-ROM 启动 TinyCore 16.2
        |
        v
TinyCore 自动启动 Xvesa + FLWM 桌面
```

网页本身不能直接执行内核或访问真实硬件，因此这里使用的是整机模拟。TinyCore 的文件系统在虚拟机内存中运行，刷新页面后系统状态会丢失。

## 本地运行

```bash
python3 -m http.server 8000
```

打开 `http://localhost:8000/`。不能直接双击 `index.html`，因为 v86 需要通过 HTTP 读取 WASM、BIOS 和 ISO。

## 发布到 GitHub Pages

1. 将本目录推送到 GitHub 仓库。
2. 在 `Settings > Pages` 中选择 `Deploy from a branch`。
3. 选择默认分支和 `/ (root)`，保存。
4. 访问 `https://<用户名>.github.io/<仓库名>/`。

页面使用相对路径，项目 Pages 和用户主页 Pages 都不需要额外改 URL。

## 目录结构

```text
.
├── index.html                    # 页面和模拟器屏幕
├── styles.css                    # 深色工作台界面
├── app.js                        # v86 初始化、控制和错误状态
├── assets/TinyCore-16.2.iso      # 24MB，带 FLWM 桌面的 x86 ISO
├── vendor/v86/                   # v86、WASM、SeaBIOS、VGA BIOS
└── licenses/                    # 第三方许可文本
```

## 注意事项

- 首次启动需要等待浏览器下载并解压 ISO，速度取决于设备 CPU 和内存。
- 建议至少分配给浏览器 512MB 可用内存；模拟器本身使用 128MB 客体内存。
- GitHub Pages 默认使用 v86 内建的 `fetch` 网络后端。它在浏览器中提供 DHCP、ARP、DNS 和 ICMP ping，避免系统代理中断原始以太网 WebSocket；客体通常会获得 `192.168.86.100/24`，网关为 `192.168.86.1`。
- localhost 默认使用功能更完整的 `wsproxy` 后端，通过 `wss://relay.widgetry.org/` 转发以太网帧。
- 可用 `?network=fetch` 或 `?network=wsproxy` 手动选择后端。`fetch` 后端的外网访问受浏览器 CORS 限制，主要支持客体的 HTTP 请求，不等同于完整 TCP/IP 转发。

启动桌面后，在终端执行以下命令测试网络：

```sh
sudo udhcpc -i eth0
ifconfig eth0
ping 8.8.8.8
```

使用 GitHub Pages 默认的 `fetch` 后端时，`eth0` 应显示 `192.168.86.100`。
- 页面按钮支持暂停、继续、重启、全屏和截图；点击桌面区域后可向虚拟机发送键盘和鼠标输入。

## 许可和来源

TinyCore ISO 来自官方 x86 发行目录，源码和发行说明见 `THIRD_PARTY_NOTICES.md`。v86 使用 BSD-2-Clause；BIOS 文件随 v86 官方项目发布。
