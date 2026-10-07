import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { App } from "./app/App";
import { AppProvider } from "./app/AppState";
import "./styles/index.css";

// iOS Safari shows a button's :active (pressed) colour only once the page listens for touches (G 07:38: press like hover)
document.addEventListener("touchstart", () => {}, { passive: true });

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <AppProvider><App /></AppProvider>
  </StrictMode>,
);

// offline support: only in a real build served over http(s), never in the single-file preview
if (import.meta.env.PROD && import.meta.env.MODE !== "preview" && "serviceWorker" in navigator && location.protocol.startsWith("http")) {
  addEventListener("load", () => { void navigator.serviceWorker.register("./sw.js"); });
}
