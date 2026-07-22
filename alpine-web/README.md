# Alpine v86 Web Desktop

这是一个可部署到 GitHub Pages 的 Alpine Linux 3.24 图形系统。浏览器中的
v86 模拟 32 位 x86 PC，并从自定义 ISO 启动 Openbox 桌面。

系统预装 NetSurf、`wget`、`curl`、`fastfetch`、Openbox、tint2 和 xterm。
它会自动登录 `alpine` 用户、通过 `eth0` DHCP 联网、以 1024x768 启动 Xorg，
然后打开 NetSurf 和 fastfetch 终端。`alpine` 可免密码执行 `doas`。

客体系统使用 Alpine 官方 32 位 x86 仓库中的 NetSurf 3.11。NetSurf 适合普通
HTTP/HTTPS 页面，但不适合依赖大量 JavaScript 的现代 Web 应用。

## 生成的 ISO

```text
dist/alpine-v86-260722-x86.iso
SHA-256: 3d338f7998e2e861197d4324b3fd79270410f16a64e676c41ac04228b1858202
```

ISO 约 170 MB，不能作为单个文件提交到 GitHub 仓库。GitHub Pages 版本使用
同源 16 MB 分片，放在 `alpine-web/assets/`，页面会按需读取分片；Release 中的
原始 ISO 仅作为备份保存。

```text
alpine-v86-260722-x86.iso
```

页面在 `github.io` 上会自动读取：

```text
https://github.com/gmicroul/gmicroul.github.io/releases/download/tinycore-browser-fixed/alpine-v86-260722-x86.iso
```

不要用导入 Action 把该 ISO 下载到 `alpine-web/dist/` 后提交；GitHub 普通 Git
对象的单文件上限是 100 MB。需要上传 `assets/` 下生成的分片文件，而不是原始 ISO。

CD-ROM 使用 HTTP Range 以 4 MB 固定块按需读取，不必先完整下载 170 MB ISO，
同时避免 v86 按磁盘扇区产生大量小请求。

## 本地运行

```sh
cd /home/phablet/alpine-browser-iso
python3 tools/serve-range.py
```

打开 `http://127.0.0.1:8001/`。该服务支持 Range，本地测试也会按 4 MB 块读取
`dist` 中的 ISO；GitHub Pages 模式读取同目录下的 `assets` 分片。页面可用
`?iso=<URL>` 指定其他 ISO，并可用
`?network=wisp`、`?network=wsproxy` 或 `?network=fetch` 切换网络后端。
可用 `?memory=512`、`?memory=768` 或 `?memory=1024` 手动指定客体内存；省略
该参数时生产默认值为 512 MB。Alpine diskless 模式会把约 370 MB 系统文件
解压到 RAM，因此系统还会自动建立 256 MB zram swap，缓冲 NetSurf 和 GTK
的内存峰值。部分浏览器无法稳定承受大于 512 MB 的 v86 WebAssembly 内存。

本地打开 `http://127.0.0.1:8001/?parts=1` 可以验证 GitHub Pages 使用的分片模式。

## GitHub Pages 文件

提交 `index.html`、`styles.css`、`app.js`、`assets/`、`vendor/`、`licenses/`
以及构建脚本。`dist/*.iso` 已由 `.gitignore` 排除，原始 ISO 不提交到仓库。

v86 默认分配 512 MB 客体内存，使用 virtio 网卡。GitHub Pages 默认连接
`wisps://wisp.mercurywork.shop/`，本地默认使用
`wss://relay.widgetry.org/`。

## 构建输入

- Alpine Linux 3.24 x86 repositories
- Alpine `aports` branch `3.24-stable`
- v86 profile: `mkimg.alpine-v86.sh`
- Alpine overlay: `genapkovl-alpine-v86.sh`
