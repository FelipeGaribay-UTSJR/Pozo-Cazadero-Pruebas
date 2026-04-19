importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

// Pega aquí la misma configuración que tienes en firebase_options.dart
// (Puedes encontrar estos datos en Firebase Console > Configuración > General > Tus apps > Web)
firebase.initializeApp({
  apiKey: "AIzaSyCsWthGOlpMjSqDDJ8eybXvQoyxd5FvG5E",
  authDomain: "agua-pwa-22618.firebaseapp.com",
  projectId: "agua-pwa-22618",
  storageBucket: "agua-pwa-22618.firebasestorage.app",
  messagingSenderId: "804181704830",
  appId: "1:804181704830:web:8b141067b7c02b94ca982f"
});

const messaging = firebase.messaging();

// Esto maneja las notificaciones cuando la app está en segundo plano (cerrada)
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Notificación recibida:', payload);
  
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png' // Asegúrate de tener este icono
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});