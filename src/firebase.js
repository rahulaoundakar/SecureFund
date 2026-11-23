// src/firebase.js

// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
import { getStorage } from "firebase/storage";

// Import the functions you need from the SDKs you need
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyCmPnTmcFimqD4XAsqB9tWkNVpmYspVbZw",
  authDomain: "fund-52ab9.firebaseapp.com",
  projectId: "fund-52ab9",
  storageBucket: "fund-52ab9.firebasestorage.app",
  messagingSenderId: "316662029579",
  appId: "1:316662029579:web:e7ed55c268c9865a49960e",
  measurementId: "G-EPN0055F3W",
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize Firebase services and export them
export const analytics = getAnalytics(app);
export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);
