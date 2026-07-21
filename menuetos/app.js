"use strict";

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
  runToggle: document.getElementById("run-toggle"),
  runIcon: document.getElementById("run-icon"),
  restart: document.getElementById("restart"),
  screenshot: document.getElementById("screenshot"),
  fullscreen: document.getElementById("fullscreen"),
  retry: document.getElementById("retry"),
};

let emulator = null;
let isRunning = false;

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
  ui.error.hidden = true;
  ui.loading.classList.remove("is-hidden");
  ui.loadingTitle.textContent = "准备虚拟机";
  ui.loadingDetail.textContent = "0%";
  ui.progress.style.width = "0";
  setControlsEnabled(false);
  setStatus("loading", "正在加载运行环境");

  if (typeof WebAssembly !== "object") {
    showError("当前浏览器不支持 WebAssembly，请使用较新的 Chrome、Edge、Firefox 或 Safari。");
    return;
  }

  if (typeof V86 !== "function") {
    showError("v86 运行时没有加载成功，请检查静态文件路径后重试。");
    return;
  }

  try {
    emulator = new V86({
      wasm_path: "vendor/v86/v86.wasm",
      memory_size: 32 * 1024 * 1024,
      vga_memory_size: 4 * 1024 * 1024,
      screen: {
        container: ui.screen,
        use_graphical_text: true,
      },
      bios: { url: "vendor/v86/seabios.bin" },
      vga_bios: { url: "vendor/v86/vgabios.bin" },
      fda: { url: "assets/menuetos-0.86b.img" },
      boot_order: 0x231,
      fastboot: true,
      autostart: true,
      disable_speaker: true,
    });

    emulator.add_listener("download-progress", updateDownload);
    emulator.add_listener("download-error", event => {
      const file = event.file_name ? `（${event.file_name}）` : "";
      showError(`启动文件下载失败${file}。请检查 GitHub Pages 是否完整发布了 assets 和 vendor 目录。`);
    });
    emulator.add_listener("emulator-ready", () => {
      ui.loadingTitle.textContent = "正在启动 MenuetOS";
      ui.loadingDetail.textContent = "BIOS 已就绪";
      ui.progress.style.width = "100%";
      setControlsEnabled(true);
    });
    emulator.add_listener("emulator-started", () => {
      setRunning(true);
      window.setTimeout(() => ui.loading.classList.add("is-hidden"), 350);
    });
    emulator.add_listener("emulator-stopped", () => setRunning(false));
    emulator.add_listener("screen-set-size", size => {
      const [width, height] = size;
      if (width && height) {
        ui.displayMode.textContent = `${width} x ${height}`;
      }
    });
  } catch (error) {
    console.error(error);
    showError(error instanceof Error ? error.message : "初始化模拟器时发生未知错误。");
  }
}

ui.runToggle.addEventListener("click", async () => {
  if (!emulator) return;

  ui.runToggle.disabled = true;
  try {
    if (isRunning) {
      await emulator.stop();
    } else {
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
    link.download = `menuetos-${new Date().toISOString().replace(/[:.]/g, "-")}.png`;
    link.href = image.src;
    link.click();
  }, { once: true });
});

ui.retry.addEventListener("click", async () => {
  if (emulator) {
    await emulator.destroy();
    emulator = null;
  }
  initialize();
});

ui.screen.addEventListener("pointerdown", () => ui.screen.focus());

initialize();
