importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyAxFud_jk_LJdQOVfNgZ8dOMkYPxCX-cbQ",
  authDomain: "likealocal-1.firebaseapp.com",
  projectId: "likealocal-1",
  storageBucket: "likealocal-1.firebasestorage.app",
  messagingSenderId: "333393354804",
  appId: "1:333393354804:web:1b09e18ff64ccf787aea61"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('Background message received:', payload);
});