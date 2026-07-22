"use strict";

const ISO_FILENAME = "alpine-v86-260722-x86.iso";
const RELEASE_ISO_URL =
  "https://github.com/gmicroul/gmicroul.github.io/releases/download/tinycore-browser-fixed/" + ISO_FILENAME;

const ui = {
  screen: document.getElementById("screen-container"),
  loading: document.getElementById("loading-layer"),
  loadingTitle: document.getElementById("loading-title"),
  loadingDetail: document.getElementById("loading-detail"),
  progress: document.getElementById("progress-bar"),
  error: document.getElementById("error-layer"),
  errorMessage: document.getElementById("error-message"),
  statusDot: document.getElementById("status-dot"),
  statusText: document.getElementById("status-text"),
  displayMode: document.getElementById("display-mode"),
  memorySize: document.getElementById("memory-size"),
  runToggle: document.getElementById("run-toggle"),
  runIcon: document.getElementById("run-icon"),
  restart: document.getElementById("restart"),
  screenshot: document.getElementById("screenshot"),
  fullscreen: document.getElementById("fullscreen"),
  retry: document.getElementById("retry"),
};

let emulator = null;
let isRunning = false;
let isRetrying = false;

function getIsoConfig() {
  const requested = new URLSearchParams(window.location.search).get("iso");
  const localIsoUrl = `dist/${ISO_FILENAME}`;
  const ranged = url => ({
    url,
    async: true,
    fixed_chunk_size: 4 * 1024 * 1024,
  });
  if (requested) return ranged(requested);

  if (window.location.hostname.endsWith(".github.io")) {
    return ranged(RELEASE_ISO_URL);
  }

  if (window.location.port === "8001") {
    return ranged(localIsoUrl);
  }

  // Basic local static servers often do not implement HTTP Range requests.
  return { url: localIsoUrl, async: false };
}

function getMemorySize() {
  const requested = Number(new URLSearchParams(window.location.search).get("memory"));
  if (Number.isFinite(requested) && requested >= 64 && requested <= 1024) {
    return requested * 1024 * 1024;
  }
  return 512 * 1024 * 1024;
}

function getNetworkRelay() {
  const requested = new URLSearchParams(window.location.search).get("network");
  if (requested === "fetch") return "fetch";
  if (requested === "wsproxy") return "wss://relay.widgetry.org/";
  if (requested === "wisp") return "wisps://wisp.mercurywork.shop/";

  return window.location.hostname.endsWith(".github.io")
    ? "wisps://wisp.mercurywork.shop/"
    : "wss://relay.widgetry.org/";
}

function setStatus(kind, text) {
  ui.statusDot.className = `status-dot is-${kind}`;
  ui.statusText.textContent = text;
}

function setControlsEnabled(enabled) {
  ui.runToggle.disabled = !enabled;
  ui.restart.disabled = !enabled;
  ui.screenshot.disabled = !enabled;
  ui.fullscreen.disabled = !enabled;
}

function setRunning(running) {
  isRunning = running;
  ui.runIcon.innerHTML = running ? "&#x23F8;" : "&#x25B6;";
  ui.runToggle.setAttribute("aria-label", running ? "暂停" : "继续");
  ui.runToggle.title = running ? "暂停" : "继续";
  setStatus(running ? "running" : "paused", running ? "正在运行" : "已暂停");
}

function showError(message) {
  ui.loading.classList.add("is-hidden");
  ui.error.hidden = false;
  ui.errorMessage.textContent = message;
  setControlsEnabled(false);
  setStatus("error", "启动失败");
}

async function disposeEmulator() {
  const instance = emulator;
  emulator = null;
  isRunning = false;
  if (!instance) return;

  try {
    await instance.destroy();
  } catch (error) {
    console.warn("Failed to release the v86 instance", error);
  }
}

function updateDownload(progress) {
  if (!progress.lengthComputable || !progress.total) {
    ui.loadingDetail.textContent = "正在读取启动文件";
    return;
  }

  const percent = Math.min(100, Math.round(progress.loaded / progress.total * 100));
  ui.progress.style.width = `${percent}%`;
  ui.loadingDetail.textContent = `${percent}%`;
}

function initialize() {
  const memorySize = getMemorySize();

  ui.error.hidden = true;
  ui.loading.classList.remove("is-hidden");
  ui.loadingTitle.textContent = "正在加载 Alpine Linux";
  ui.loadingDetail.textContent = "0%";
  ui.progress.style.width = "0";
  setControlsEnabled(false);
  setStatus("loading", "正在加载运行环境");
  ui.memorySize.textContent = `${memorySize / 1024 / 1024} MB`;

  if (typeof WebAssembly !== "object") {
    showError("当前浏览器不支持 WebAssembly，请使用较新的 Chrome、Edge、Firefox 或 Safari。");
    return;
  }
  if (typeof V86 !== "function") {
    showError("v86 运行时没有加载成功，请检查 vendor/v86 目录后重试。");
    return;
  }

  try {
    const instance = new V86({
      wasm_path: "vendor/v86/v86.wasm",
      memory_size: memorySize,
      vga_memory_size: 16 * 1024 * 1024,
      screen: { container: ui.screen, use_graphical_text: true },
      bios: { url: "vendor/v86/seabios.bin" },
      vga_bios: { url: "vendor/v86/vgabios.bin" },
      cdrom: getIsoConfig(),
      net_device: {
        type: "virtio",
        relay_url: getNetworkRelay(),
      },
      boot_order: 0x213,
      fastboot: true,
      autostart: true,
      disable_speaker: true,
    });
    emulator = instance;

    instance.add_listener("download-progress", progress => {
      if (emulator === instance) updateDownload(progress);
    });
    instance.add_listener("download-error", event => {
      if (emulator !== instance) return;
      const file = event?.file_name ? `（${event.file_name}）` : "";
      showError(`启动文件下载失败${file}。请确认 GitHub Release 中的 ISO 已上传且允许 Range 请求。`);
      void disposeEmulator();
    });
    instance.add_listener("emulator-ready", () => {
      if (emulator !== instance) return;
      ui.loadingTitle.textContent = "正在启动 Alpine 桌面";
      ui.loadingDetail.textContent = "ISO 和 virtio 网卡已就绪";
      ui.progress.style.width = "100%";
      setControlsEnabled(true);
    });
    instance.add_listener("emulator-started", () => {
      if (emulator !== instance) return;
      setRunning(true);
      window.setTimeout(() => ui.loading.classList.add("is-hidden"), 350);
    });
    instance.add_listener("emulator-stopped", () => {
      if (emulator === instance) setRunning(false);
    });
    instance.add_listener("screen-set-size", size => {
      if (emulator !== instance) return;
      const [width, height] = size;
      if (width && height) ui.displayMode.textContent = `${width} x ${height}`;
    });
  } catch (error) {
    console.error(error);
    showError(error instanceof Error ? error.message : "初始化模拟器时发生未知错误。");
    void disposeEmulator();
  }
}

ui.runToggle.addEventListener("click", async () => {
  if (!emulator) return;
  ui.runToggle.disabled = true;
  try {
    if (isRunning) await emulator.stop();
    else {
      await emulator.run();
      ui.screen.focus();
    }
  } finally {
    ui.runToggle.disabled = false;
  }
});

ui.restart.addEventListener("click", () => {
  if (!emulator) return;
  emulator.restart();
  setStatus("loading", "正在重新启动");
  ui.screen.focus();
});

ui.fullscreen.addEventListener("click", () => {
  if (!emulator) return;
  emulator.screen_go_fullscreen();
  ui.screen.focus();
});

ui.screenshot.addEventListener("click", () => {
  if (!emulator) return;
  const image = emulator.screen_make_screenshot();
  image.addEventListener("load", () => {
    const link = document.createElement("a");
    link.download = `alpine-v86-${new Date().toISOString().replace(/[:.]/g, "-")}.png`;
    link.href = image.src;
    link.click();
  }, { once: true });
});

ui.retry.addEventListener("click", async () => {
  if (isRetrying) return;
  isRetrying = true;
  ui.retry.disabled = true;
  await disposeEmulator();
  initialize();
  ui.retry.disabled = false;
  isRetrying = false;
});

ui.screen.addEventListener("pointerdown", () => ui.screen.focus());

initialize();
