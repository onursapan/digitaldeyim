# CI/CD Pipeline Kurulum Rehberi

GitHub Actions + Fastlane match ile TestFlight otomatik dağıtım.

---

## Gereksinimler

- Apple Developer Program ($99/yıl) — aktif olmalı
- Xcode'da Bundle ID: `com.digitaldeyim.app` ile app oluşturulmuş olmalı
- App Store Connect'te uygulama kaydı yapılmış olmalı

---

## Adım 1 — App Store Connect API Key

1. [App Store Connect](https://appstoreconnect.apple.com) → Users and Access → Integrations → App Store Connect API
2. **New Key** → Name: `GitHub Actions`, Access: `App Manager`
3. İndirilen `.p8` dosyasını sakla (bir kez indirilir)
4. `Key ID` ve `Issuer ID`'yi not al

---

## Adım 2 — Fastlane Match için Sertifika Repo'su

```bash
# Sertifikaları saklayacak private repo oluştur (GitHub'da)
# Örn: github.com/onursapan/digitaldeyim-certificates

# Lokal kurulum
cd ios
gem install fastlane
fastlane match init
# → Repo URL'ini gir: git@github.com:onursapan/digitaldeyim-certificates.git

# İlk sertifika oluşturma (tek seferlik)
fastlane match appstore
# → Şifre belirle (MATCH_PASSWORD olarak saklanacak)
```

---

## Adım 3 — GitHub Repository Secrets

GitHub repo → Settings → Secrets and variables → Actions → New repository secret:

| Secret Adı | Değer | Açıklama |
|---|---|---|
| `MATCH_GIT_PRIVATE_KEY` | SSH private key | Sertifika repo'suna erişim |
| `MATCH_GIT_URL` | `git@github.com:onursapan/digitaldeyim-certificates.git` | Sertifika repo URL'i |
| `MATCH_PASSWORD` | match init'te belirlenen şifre | ARB şifreleme anahtarı |
| `ASC_PRIVATE_KEY_BASE64` | `.p8` dosyasının base64 çıktısı | `base64 -i AuthKey_XXX.p8` |
| `ASC_KEY_ID` | App Store Connect Key ID | Örn: `ABCDEF1234` |
| `ASC_ISSUER_ID` | App Store Connect Issuer ID | UUID formatında |
| `FASTLANE_USER` | Apple Developer e-posta | `onur@example.com` |
| `FASTLANE_TEAM_ID` | Apple Developer Team ID | Xcode → Signing bölümünden |

### SSH key oluşturma:
```bash
ssh-keygen -t ed25519 -C "github-actions-match" -f ~/.ssh/match_key
# Public key'i sertifika repo'sunun Deploy Keys'ine ekle (write izni gerekli)
# Private key içeriğini MATCH_GIT_PRIVATE_KEY secret'ına yapıştır
```

### .p8 → base64:
```bash
base64 -i AuthKey_KEYID.p8 | pbcopy
# Kopyalananı ASC_PRIVATE_KEY_BASE64 secret'ına yapıştır
```

---

## Adım 4 — TestFlight Internal Group

1. App Store Connect → TestFlight → Internal Testing
2. **+** ile yeni group → adı: `Developers`
3. Testers ekle (Apple ID ile davet)
4. **Automatic Distribution** → ON
   - Artık her yüklenen build group'a otomatik gönderilir

---

## Adım 5 — İlk Pipeline Tetikleme

```bash
# main'e push → pipeline otomatik tetiklenir
git push origin main

# Veya versiyonlu release tag'i
git tag v1.0.0
git push origin v1.0.0
```

---

## Pipeline Akışı

```
push to main / v* tag
        │
        ▼
  [analyze job]          ← ubuntu-latest (ücretsiz, hızlı)
  flutter analyze
  flutter test
        │
        ▼ (sadece main / tag)
  [deploy_ios job]       ← macos-15 (~15-25 dk)
  flutter pub get
  fastlane match (sertifika indir)
  flutter build ipa
  upload_to_testflight
        │
        ▼
  TestFlight Internal Group → testers e-posta alır
```

---

## PR Akışı (dev → main)

```
feature/* → dev (sadece analyze çalışır)
dev → main PR (analyze çalışır, iOS build ÇALIŞMAZ)
main'e merge → iOS build + TestFlight upload
```

---

## Aylık Maliyet

| Kaynak | Maliyet |
|---|---|
| GitHub Actions (private repo, macOS) | ~15-25 dk × 10x çarpan = 150-250 dk/build |
| Ücretsiz limit | 2000 dk/ay = ~8-13 build |
| Aşım ücreti | $0.08/dk (macOS) |
| Apple Developer Program | $99/yıl |
| Fastlane, match, GitHub Actions | Ücretsiz |

**Public repo ise macOS dakikaları sınırsız ücretsiz.**

---

## Sorun Giderme

### "No certificate found"
```bash
# Lokal sertifika yenile
cd ios && fastlane match appstore --force
```

### Build numarası çakışması
GitHub Actions `run_number` kullanılıyor — her push'ta otomatik artar.

### Match şifre hatası
`MATCH_PASSWORD` secret'ının doğru set edildiğini kontrol et.
