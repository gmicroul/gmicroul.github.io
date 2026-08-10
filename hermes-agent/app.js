"use strict";

const ISO_FILENAME = "alpine-v86-260722-x86.iso";
const ISO_SIZE = 223346688;
const ISO_PART_SIZE = 16 * 1024 * 1024;

const ui = {
  screen: document.getElementById("screen_container"),
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
  pasteClipboard: document.getElementById("paste-clipboard"),
  copyScreenText: document.getElementById("copy-screen-text"),
  retry: document.getElementById("retry"),
};

let emulator = null;
let isRunning = false;
let isRetrying = false;

function getIsoConfig() {
  const params = new URLSearchParams(window.location.search);
  const requested = params.get("iso");
  const localIsoUrl = `dist/${ISO_FILENAME}`;
  const ranged = url => ({
    url,
    async: true,
    fixed_chunk_size: 4 * 1024 * 1024,
  });
  const parts = url => ({
    url,
    size: ISO_SIZE,
    async: true,
    fixed_chunk_size: ISO_PART_SIZE,
    use_parts: true,
  });
  if (requested) return ranged(requested);

  if (window.location.hostname.endsWith(".github.io") || params.get("parts") === "1") {
    const partsUrl = new URL(`assets/${ISO_FILENAME}`, document.baseURI).href;
    return parts(partsUrl);
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
  return 1024 * 1024 * 1024;
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
  ui.pasteClipboard.disabled = !enabled;
  ui.copyScreenText.disabled = !enabled;
}

function setRunning(running) {
  isRunning = running;
  ui.runIcon.innerHTML = running ? "&#x23F8;" : "&#x25B6;";
  ui.runToggle.setAttribute("aria-label", running ? "鏆傚仠" : "缁х画");
  ui.runToggle.title = running ? "鏆傚仠" : "缁х画";
  setStatus(running ? "running" : "paused", running ? "姝ｅ湪杩愯" : "宸叉殏鍋�");
}

function enableInput(instance = emulator) {
  ui.screen.focus({ preventScroll: true });
  if (!instance) return;
  instance.keyboard_set_status(true);
  instance.mouse_set_status(true);
}

function showError(message) {
  ui.loading.classList.add("is-hidden");
  ui.error.hidden = false;
  ui.errorMessage.textContent = message;
  setControlsEnabled(false);
  setStatus("error", "鍚姩澶辫触");
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
    ui.loadingDetail.textContent = "姝ｅ湪璇诲彇鍚姩鏂囦欢";
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
  ui.loadingTitle.textContent = "姝ｅ湪鍔犺浇 Alpine Linux";
  ui.loadingDetail.textContent = "0%";
  ui.progress.style.width = "0";
  setControlsEnabled(false);
  setStatus("loading", "姝ｅ湪鍔犺浇杩愯鐜");
  ui.memorySize.textContent = `${memorySize / 1024 / 1024} MB`;

  if (typeof WebAssembly !== "object") {
    showError("褰撳墠娴忚鍣ㄤ笉鏀寔 WebAssembly锛岃浣跨敤杈冩柊鐨� Chrome銆丒dge銆丗irefox 鎴� Safari銆�");
    return;
  }
  if (typeof V86 !== "function") {
    showError("v86 杩愯鏃舵病鏈夊姞杞芥垚鍔燂紝璇锋鏌� vendor/v86 鐩綍鍚庨噸璇曘€�");
    return;
  }

  try {
    const instance = new V86({
      wasm_path: "vendor/v86/v86.wasm",
      memory_size: memorySize,
      vga_memory_size: 16 * 1024 * 1024,
      screen_container: ui.screen,
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
      const file = event?.file_name ? `锛�${event.file_name}锛塦 : "";
      showError(`鍚姩鏂囦欢涓嬭浇澶辫触${file}銆傝纭 assets 涓殑 ISO 鍒嗙墖宸茬粡瀹屾暣涓婁紶銆俙);
      void disposeEmulator();
    });
    instance.add_listener("emulator-ready", () => {
      if (emulator !== instance) return;
      ui.loadingTitle.textContent = "姝ｅ湪鍚姩 Alpine 妗岄潰";
      ui.loadingDetail.textContent = "ISO 鍜� virtio 缃戝崱宸插氨缁�";
      ui.progress.style.width = "100%";
      setControlsEnabled(true);
    });
    instance.add_listener("emulator-started", () => {
      if (emulator !== instance) return;
      enableInput(instance);
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
    showError(error instanceof Error ? error.message : "鍒濆鍖栨ā鎷熷櫒鏃跺彂鐢熸湭鐭ラ敊璇€�");
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
      enableInput();
    }
  } finally {
    ui.runToggle.disabled = false;
  }
});

ui.restart.addEventListener("click", () => {
  if (!emulator) return;
  emulator.restart();
  setStatus("loading", "姝ｅ湪閲嶆柊鍚姩");
  enableInput();
});

ui.fullscreen.addEventListener("click", () => {
  if (!emulator) return;
  emulator.screen_go_fullscreen();
  enableInput();
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

/* === 鍓创鏉匡細绮樿创涓绘満鍓创鏉垮埌铏氭嫙鏈� === */
ui.pasteClipboard.addEventListener("click", async () => {
  if (!emulator) return;
  try {
    const text = await navigator.clipboard.readText();
    if (!text) {
      setStatus("paused", "鍓创鏉夸负绌�");
      setTimeout(() => setStatus(isRunning ? "running" : "paused", isRunning ? "姝ｅ湪杩愯" : "宸叉殏鍋�"), 2000);
      return;
    }
    enableInput();
    // v86 keyboard_send_text simulates typing the text into the guest
    emulator.keyboard_send_text(text);
    setStatus("running", `宸茬矘璐� ${text.length} 瀛楃`);
    setTimeout(() => setStatus(isRunning ? "running" : "paused", isRunning ? "姝ｅ湪杩愯" : "宸叉殏鍋�"), 2000);
  } catch (err) {
    // clipboard API might be blocked; fall back to a prompt
    const text = prompt("绮樿创鏂囨湰鍒拌櫄鎷熸満锛圕trl+V 绮樿创鍒版澶勶級锛�");
    if (text && emulator) {
      enableInput();
      emulator.keyboard_send_text(text);
      setStatus("running", `宸茬矘璐� ${text.length} 瀛楃`);
      setTimeout(() => setStatus(isRunning ? "running" : "paused", isRunning ? "姝ｅ湪杩愯" : "宸叉殏鍋�"), 2000);
    }
  }
});

/* === 鍓创鏉匡細澶嶅埗铏氭嫙鏈哄睆骞曟枃鏈埌涓绘満鍓创鏉� === */
ui.copyScreenText.addEventListener("click", async () => {
  if (!emulator) return;
  try {
    // v86 exposes the text screen via the screen_container DOM
    // The text-screen div holds the VGA text buffer content
    const textScreen = ui.screen.querySelector(".text-screen");
    let text = "";
    if (textScreen) {
      text = textScreen.textContent || textScreen.innerText || "";
    }
    if (!text || !text.trim()) {
      // fallback: try screen_make_screenshot and copy as image (not text)
      setStatus("paused", "灞忓箷鏃犲彲澶嶅埗鏂囨湰");
      setTimeout(() => setStatus(isRunning ? "running" : "paused", isRunning ? "姝ｅ湪杩愯" : "宸叉殏鍋�"), 2000);
      return;
    }
    // trim trailing whitespace per line but keep structure
    text = text.split("\n").map(l => l.replace(/\s+$/, "")).join("\n").replace(/\n+$/, "\n");
    await navigator.clipboard.writeText(text);
    setStatus("running", `宸插鍒� ${text.length} 瀛楃`);
    setTimeout(() => setStatus(isRunning ? "running" : "paused", isRunning ? "姝ｅ湪杩愯" : "宸叉殏鍋�"), 2000);
  } catch (err) {
    // fallback: create a textarea and select it
    const textScreen = ui.screen.querySelector(".text-screen");
    const text = textScreen ? (textScreen.textContent || "") : "";
    if (text) {
      const ta = document.createElement("textarea");
      ta.value = text;
      document.body.appendChild(ta);
      ta.select();
      try { document.execCommand("copy"); } catch (e) {}
      document.body.removeChild(ta);
      setStatus("running", `宸插鍒� ${text.length} 瀛楃`);
      setTimeout(() => setStatus(isRunning ? "running" : "paused", isRunning ? "姝ｅ湪杩愯" : "宸叉殏鍋�"), 2000);
    }
  }
});

/* Also support Ctrl+V / Cmd+V paste directly into the emulator screen */
ui.screen.addEventListener("paste", async (e) => {
  if (!emulator) return;
  e.preventDefault();
  const items = e.clipboardData?.items || [];
  for (const item of items) {
    if (item.type === "text/plain") {
      const text = item.kind === "string" ? item.getData("text/plain") : "";
      if (text) {
        enableInput();
        emulator.keyboard_send_text(text);
        setStatus("running", `宸茬矘璐� ${text.length} 瀛楃`);
        setTimeout(() => setStatus(isRunning ? "running" : "paused", isRunning ? "姝ｅ湪杩愯" : "宸叉殏鍋�"), 2000);
      }
    }
  }
});

ui.screen.addEventListener("pointerdown", () => enableInput());

initialize();
