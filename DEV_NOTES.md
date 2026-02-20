# DEV NOTES — Digitaldeyim

> Son güncelleme: 2026-02-20
> Model: claude-sonnet-4-6

---

## ✅ Tamamlanan Oturumlar

### Session 1 — 2026-02-20: Firebase / Google Sign-In Düzeltmesi

Tüm 4 katmandaki Firebase/Google Sign-In sorunları giderildi:

| Dosya | Yapılan |
|---|---|
| `ios/Runner/GoogleService-Info.plist` | `CLIENT_ID` + `REVERSED_CLIENT_ID` eklendi (gerçek OAuth client) |
| `android/app/google-services.json` | `oauth_client` dolduruldu (type 1 native + type 3 web) |
| `ios/Runner/Info.plist` | `GIDClientID` + `CFBundleURLSchemes` placeholder → gerçek değer |
| `lib/firebase_options.dart` | iOS `clientId` eklendi |
| `lib/core/services/auth_service.dart` | `GoogleSignIn(serverClientId: ...)` — Android idToken fix |

---

## 🔴 Aktif Sorun: Firebase / Google Sign-In Entegrasyonu

### Kök Neden Analizi

Google Sign-In şu an **4 ayrı katmanda** eksik/yanlış yapılandırılmış:

---

### Sorun 1 — `android/app/google-services.json` → `oauth_client` boş

```json
"oauth_client": []   ← BOŞU  Bu dolu olmalı
```

Android'de Google Sign-In çalışması için `client_type: 3` olan bir Web OAuth client kaydının bu array'de bulunması gerekir. Yoksa `GoogleSignIn().signIn()` → **`DEVELOPER_ERROR (ApiException: 10)`** ile fail olur.

**Kök neden:** Firebase Console → Authentication → Sign-in method → Google etkinleştirilmemiş VEYA Android app'e SHA fingerprint eklenmemiş.

---

### Sorun 2 — `ios/Runner/GoogleService-Info.plist` → `CLIENT_ID` ve `REVERSED_CLIENT_ID` eksik

Mevcut plist'te sadece şunlar var: `API_KEY`, `GCM_SENDER_ID`, `BUNDLE_ID`, `PROJECT_ID`, `STORAGE_BUCKET`, `GOOGLE_APP_ID`.

Eksik olan critical key'ler:
```xml
<key>CLIENT_ID</key>
<string>349706854240-XXXXXXXX.apps.googleusercontent.com</string>
<key>REVERSED_CLIENT_ID</key>
<string>com.googleusercontent.apps.349706854240-XXXXXXXX</string>
```

---

### Sorun 3 — `ios/Runner/Info.plist` → PLACEHOLDER değerler

```xml
<key>GIDClientID</key>
<string>349706854240-placeholder00000000000000.apps.googleusercontent.com</string>

<key>CFBundleURLSchemes</key>
<array>
  <string>com.googleusercontent.apps.349706854240-placeholder00000000000000</string>
</array>
```

Bu iki key `GoogleService-Info.plist`'teki gerçek `CLIENT_ID` ile güncellenmelidir.

---

### Sorun 4 — `lib/firebase_options.dart` → iOS `clientId` eksik

```dart
static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'AIzaSy...',
  appId: '1:349706854240:ios:7d96bb90a0d4a6febb4805',
  messagingSenderId: '349706854240',
  projectId: 'digitaldeyim',
  storageBucket: 'digitaldeyim.firebasestorage.app',
  iosBundleId: 'com.example.digitaldeyim',
  // ❌ EKSIK: clientId: 'YOUR_OAUTH_CLIENT_ID.apps.googleusercontent.com',
);
```

---

### Sorun 5 — Bundle ID tutarsızlığı (ikincil)

| Dosya | Bundle ID |
|---|---|
| `android/app/build.gradle.kts` | `com.example.digitaldeyim` |
| `ios/Runner/GoogleService-Info.plist` | `com.example.digitaldeyim` |
| `PIPELINE_SETUP.md` (CI/CD hedef) | `com.digitaldeyim.app` |

Prodüksiyon öncesi `com.digitaldeyim.app`'e migrate edilmeli.

---

## 🔧 Düzeltme Planı

### Adım 1 — Firebase Console'da Google Sign-In'ı Etkinleştir (Kullanıcı yapacak)

1. [Firebase Console](https://console.firebase.google.com) → Proje: `digitaldeyim`
2. **Authentication** → **Sign-in method** → **Google** → Enable → **Save**
3. **Project Settings** → **General** → **Your apps** → Android app:
   - SHA-1 fingerprint ekle (debug için): `cd android && ./gradlew signingReport`
   - Ardından "Download google-services.json" → projeye kopyala
4. Aynı sayfada iOS app → "Download GoogleService-Info.plist" → projeye kopyala

### Adım 2 — iOS OAuth Client ID'yi Bul

`GoogleService-Info.plist` indirildikten sonra içindeki `CLIENT_ID` değerini al. Format: `349706854240-XXXXXXXX.apps.googleusercontent.com`

### Adım 3 — Kod Düzeltmeleri (Claude yapacak — CLIENT_ID alındıktan sonra)

- [ ] `lib/firebase_options.dart` → iOS options'a `clientId` ekle
- [ ] `ios/Runner/Info.plist` → `GIDClientID` ve `CFBundleURLSchemes` güncelle
- [ ] `ios/Runner/GoogleService-Info.plist` → yeni dosya ile replace et
- [ ] `android/app/google-services.json` → yeni dosya ile replace et

---

## 📋 Kullanıcıdan Beklenenler (Bu Session İçin)

Firebase Console'dan alınması gereken bilgiler:

| Bilgi | Nereden | Ne İçin |
|---|---|---|
| Güncel `google-services.json` | Firebase → Project Settings → Android app (SHA ekledikten sonra) | Android Google Sign-In |
| Güncel `GoogleService-Info.plist` | Firebase → Project Settings → iOS app | iOS `CLIENT_ID` |
| iOS OAuth `CLIENT_ID` | `GoogleService-Info.plist` içinden | `firebase_options.dart` + `Info.plist` |

**Alternatif:** Sadece `CLIENT_ID` değerini chat'e yapıştırırsan gerisini hallederim.

---

## 🗺️ Sonraki Session Görevleri (Sıradaki Tasklar)

1. ~~**Bundle ID migration**~~ — ✅ **Tamamlandı** (Xcode zaten `com.digitaldeyim.app`, kod tarafı güncellendi)
2. **Anonymous / Dev Sign-In'ı gerçek hale getir** — Login screen'deki `_handleDevSignIn` şu an sadece `devModeProvider`'ı true yapıyor, gerçek Firebase anonymous auth ile bağlanmalı
3. **Firestore user collection** — `users/{uid}` dökümanı oluştur (`UserProfile.toJson` → Firestore write)
4. **Auth guard testi** — `app_router.dart`'taki route guard'ların `authStateProvider` ile doğru çalıştığını doğrula

---

## 🏗️ Mimari Durum Özeti

| Katman | Durum |
|---|---|
| Firebase Core init (`main.dart`) | ✅ |
| `AuthService` (signInWithGoogle, signOut) | ✅ |
| `LoginScreen` UI + error handling | ✅ |
| `authStateProvider` (StreamProvider) | ✅ |
| `google-services.json` (Android OAuth) | ✅ oauth_client dolu |
| `GoogleService-Info.plist` (iOS OAuth) | ✅ CLIENT_ID + REVERSED_CLIENT_ID mevcut |
| `Info.plist` (GIDClientID + URL scheme) | ✅ Gerçek değerler |
| `firebase_options.dart` iOS clientId | ✅ Eklendi |
| `AuthService` serverClientId (Android idToken) | ✅ Web client type 3 eklendi |
| Bundle ID — iOS kodu | ✅ `com.digitaldeyim.app` (Xcode + firebase_options + plist) |
| Bundle ID — Android kodu | ✅ `com.digitaldeyim.app` (build.gradle.kts) |
| Bundle ID — Firebase Console iOS kaydı | ⚠️ Güncellenmeli → yeni GoogleService-Info.plist indir |
| Bundle ID — Firebase Console Android kaydı | ⚠️ Güncellenmeli → yeni google-services.json indir |
