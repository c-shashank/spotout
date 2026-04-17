// Firebase Messaging service worker for web push notifications.
// This file must be at /firebase-messaging-sw.js (served from root).
// See: https://firebase.google.com/docs/cloud-messaging/js/receive

importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// The config here is safe to expose — it identifies the project, not secrets.
// Replace with values from Firebase Console → Project Settings → Web app.
firebase.initializeApp({
  apiKey: 'AIzaSyA3Dq1UpqSRE9MS9FY4M1EIYmwerOOOXlk',
  authDomain: 'jawabdo-da4d6.firebaseapp.com',
  projectId: 'jawabdo-da4d6',
  storageBucket: 'jawabdo-da4d6.firebasestorage.app',
  messagingSenderId: '987713325339',
  appId: '1:987713325339:web:144f79298e3ff9d92eabbe',
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  const { title, body } = payload.notification ?? {};
  if (title) {
    self.registration.showNotification(title, { body });
  }
});
