(function () {
  "use strict";

  function urlBase64ToUint8Array(value) {
    const padding = "=".repeat((4 - (value.length % 4)) % 4);
    const normalized = (value + padding).replace(/-/g, "+").replace(/_/g, "/");
    const raw = window.atob(normalized);
    return Uint8Array.from(raw, (character) => character.charCodeAt(0));
  }

  window.medlicensePush = {
    isSupported: function () {
      return Boolean(
        window.isSecureContext &&
          "serviceWorker" in navigator &&
          "PushManager" in window &&
          "Notification" in window
      );
    },

    subscribe: async function (applicationServerKey) {
      if (!window.medlicensePush.isSupported()) {
        throw new Error("このブラウザはWeb Pushに対応していません。");
      }

      const permission = await Notification.requestPermission();
      if (permission !== "granted") {
        throw new Error("通知が許可されませんでした。ブラウザの設定をご確認ください。");
      }

      const registration = await navigator.serviceWorker.ready;
      let subscription = await registration.pushManager.getSubscription();
      if (!subscription) {
        subscription = await registration.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: urlBase64ToUint8Array(applicationServerKey),
        });
      }
      return JSON.stringify(subscription.toJSON());
    },
  };

  window.medlicensePwa = {
    requestPersistentStorage: async function () {
      if (!navigator.storage || !navigator.storage.persist) return false;
      if (navigator.storage.persisted && (await navigator.storage.persisted())) {
        return true;
      }
      return navigator.storage.persist();
    },
  };

  window.addEventListener("load", function () {
    if ("serviceWorker" in navigator) {
      navigator.serviceWorker.register("/service_worker.js", { scope: "/" }).catch(function (error) {
        console.error("Service Worker registration failed", error);
      });
    }
  });
})();
