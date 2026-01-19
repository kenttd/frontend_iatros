importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-messaging.js");

firebase.initializeApp({
    apiKey: "AIzaSyBWDkk1bFVYL3tyF6aunatgecx8RD_cvOM",
    appId: "1:102927143840:web:73767ef78906f410354ac5",
    messagingSenderId: "102927143840",
    projectId: "iatros-478211",
    authDomain: "iatros-478211.firebaseapp.com",
    storageBucket: "iatros-478211.firebasestorage.app",
    measurementId: "G-QDDSQHBC94"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);
    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
        icon: '/icons/Icon-192.png'
    };

    self.registration.showNotification(notificationTitle,
        notificationOptions);
});
