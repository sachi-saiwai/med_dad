const CACHE_PREFIX = "medlicense-pwa";
const CACHE_VERSION = "v1";
const APP_CACHE = `${CACHE_PREFIX}-${CACHE_VERSION}`;
const APP_SHELL = [
  "/",
  "/index.html",
  "/flutter.js",
  "/flutter_bootstrap.js",
  "/main.dart.js",
  "/manifest.json",
  "/favicon.png",
  "/icons/Icon-192.png",
  "/icons/Icon-512.png",
  "/icons/Icon-maskable-192.png",
  "/icons/Icon-maskable-512.png",
  "/assets/AssetManifest.bin",
  "/assets/AssetManifest.bin.json",
  "/assets/FontManifest.json",
  "/assets/fonts/MaterialIcons-Regular.otf",
  "/assets/packages/cupertino_icons/assets/CupertinoIcons.ttf",
  "/assets/shaders/ink_sparkle.frag",
  "/assets/shaders/stretch_effect.frag",
  "/canvaskit/canvaskit.js",
  "/canvaskit/canvaskit.wasm",
  "/canvaskit/chromium/canvaskit.js",
  "/canvaskit/chromium/canvaskit.wasm",
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(APP_CACHE).then((cache) => cache.addAll(APP_SHELL)).then(() => self.skipWaiting())
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(
          keys
            .filter((key) => key.startsWith(CACHE_PREFIX) && key !== APP_CACHE)
            .map((key) => caches.delete(key))
        )
      )
      .then(() => self.clients.claim())
  );
});

async function networkFirst(request, fallbackUrl) {
  const cache = await caches.open(APP_CACHE);
  try {
    const response = await fetch(request);
    if (response.ok) await cache.put(request, response.clone());
    return response;
  } catch (_) {
    return (await cache.match(request)) || (fallbackUrl ? await cache.match(fallbackUrl) : undefined);
  }
}

async function cacheFirst(request) {
  const cache = await caches.open(APP_CACHE);
  const cached = await cache.match(request);
  if (cached) return cached;
  const response = await fetch(request);
  if (response.ok) await cache.put(request, response.clone());
  return response;
}

self.addEventListener("fetch", (event) => {
  const request = event.request;
  if (request.method !== "GET") return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin || url.pathname.startsWith("/api/")) return;

  if (request.mode === "navigate") {
    event.respondWith(networkFirst(request, "/index.html"));
    return;
  }

  if (
    url.pathname === "/flutter_bootstrap.js" ||
    url.pathname === "/main.dart.js" ||
    url.pathname === "/manifest.json"
  ) {
    event.respondWith(networkFirst(request));
    return;
  }

  event.respondWith(cacheFirst(request));
});

self.addEventListener("push", (event) => {
  let payload = {};
  try {
    payload = event.data ? event.data.json() : {};
  } catch (_) {
    payload = { body: event.data ? event.data.text() : "" };
  }

  const title = payload.title || "資格更新ノート";
  event.waitUntil(
    self.registration.showNotification(title, {
      body: payload.body || "更新期限をご確認ください。",
      icon: "/icons/Icon-192.png",
      badge: "/icons/Icon-192.png",
      tag: payload.tag || "credential-reminder",
      renotify: false,
      data: { url: payload.url || "/" },
    })
  );
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  const destination = new URL(event.notification.data?.url || "/", self.location.origin).href;
  event.waitUntil(
    self.clients.matchAll({ type: "window", includeUncontrolled: true }).then(async (clients) => {
      for (const client of clients) {
        if ("focus" in client) {
          if ("navigate" in client) await client.navigate(destination);
          return client.focus();
        }
      }
      return self.clients.openWindow ? self.clients.openWindow(destination) : undefined;
    })
  );
});
