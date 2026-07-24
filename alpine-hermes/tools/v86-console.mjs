#!/usr/bin/env node

const endpoint = process.env.CDP_URL;
const command = process.argv.slice(2).join(" ");

if (!endpoint) {
  console.error("Usage: CDP_URL=ws://... node tools/v86-console.mjs [command...]");
  process.exit(2);
}

const socket = new WebSocket(endpoint);
let requestId = 0;

function evaluate(expression) {
  socket.send(JSON.stringify({
    id: ++requestId,
    method: "Runtime.evaluate",
    params: { expression, returnByValue: true },
  }));
}

socket.addEventListener("open", () => {
  if (command) {
    evaluate(`emulator.keyboard_send_text(${JSON.stringify(`${command}\n`)})`);
  }
  const delay = Number(process.env.WAIT_MS || 5000);
  setTimeout(() => evaluate("emulator.screen_adapter.get_text_screen()"), command ? delay : 0);
});

socket.addEventListener("message", event => {
  const response = JSON.parse(event.data);
  if (response.id !== (command ? 2 : 1)) return;
  console.log(response.result?.result?.value ?? "");
  socket.close();
});

socket.addEventListener("error", () => process.exit(1));
