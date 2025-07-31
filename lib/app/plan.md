. Ilova Strukturasi (App Architecture)

@info.md birinchi ilova haqida tushunib ol

1.1. Asosiy Ekranlar

Splash Screen – Ilova yuklanmoqda.

Onboarding Screens – Ilova haqida qisqacha ma'lumot, ruxsat so‘rash.

Home Screen –

Bugungi qadamlar

Yig‘ilgan tanga

"Challenge" banneri

"Tanga do‘koni", "Statistika", "Referal" tugmalari

Step Counter (Background Service) – Telefon sensoridan qadamlarni aniqlaydi

Coin Wallet Screen –

Coin balansi

Pulga yechish

Tangani ishlatish (bonus/chegirma)

Challenge Screen – Kunlik vazifalar va bonuslar

Leaderboard Screen – Haftalik va oylik reyting

Referral Screen – Taklif havolasi va bonus haqida

Shop (Coin Store) – Mahsulotlar, internet paketlar, chegirmalar

Withdraw Form – Karta raqami + coin miqdorini yuborish

Statistics Screen – Qadam va coinlar tarixiy statistikasi

Support Chat – Telegram bot yoki ichki chat

Notifications – Bildirishnomalar oynasi

1.2. Backend API

Foydalanuvchini ro‘yxatdan o‘tkazish / kirish

Qadamlar + coin sinxronizatsiyasi

Coin balans, yechish, ishlatish

Challengelar, do‘kon ma’lumotlari

Liderlar reytingi, referal tizimi

Bildirishnomalar

2. Flowchart (Soddalashtirilgan)

[Splash Screen]
     ↓
[Onboarding] → [Sensor ruxsati so‘raladi]
     ↓
[Home Screen] → [Step Count Service Start]
     ↓             ↓            ↓              ↓
 [Challenge]  [Coin Wallet] [Leaderboard] [Referral]
                     ↓
              [Withdraw Form]
                     ↓
                [Admin Approval]
                     ↓
                  [To‘lov yuboriladi]

[Coin Shop] ← [Coin Wallet]
[Statistics] ← [Home Screen]
[Support Chat] ← [Help Button]

3. plan.md – Tasklar (Ketma-ketlik)

# Qadam++ MVP Task Plan

## 1. Ilk Tayyorlov
- [ ] Texnik topshiriqni yakunlash
- [ ] Platformani tanlash (Flutter)
- [ ] Sensor orqali qadam hisoblash test qilish
- [ ] Backend texnologiyasi (Node.js + Firebase yoki Supabase)

## 2. UI Dizayn (Figma yoki Flutter UI)
- [ ] Splash, Onboarding
- [ ] Home Screen
- [ ] Wallet Screen
- [ ] Challenge, Leaderboard
- [ ] Coin Do‘kon, Referal
- [ ] Withdraw form, Statistics
- [ ] Support chat oynasi

## 3. Frontend Ishlari
- [ ] Sensor va background qadam hisoblash integratsiyasi
- [ ] Coin hisoblash va kunlik limit
- [ ] UI sahifalarni kodlash
- [ ] Referral tizimi
- [ ] Leaderboard UI + data
- [ ] Bildirishnoma integratsiyasi (Firebase)

## 4. Backend Ishlari
- [ ] Auth (phone/email)
- [ ] Qadam + coin API
- [ ] Challenge va leader board logikasi
- [ ] Withdraw API + admin panel
- [ ] Coin shop backend
- [ ] Notification backend

## 5. Integratsiyalar
- [ ] Payme/Click API sinov
- [ ] Telegram bot bilan bog‘lash
- [ ] Firebase messaging

## 6. Sinov va Testlar
- [ ] Unit testlar (qadam, coin hisoblash)
- [ ] UI/UX testlar (real foydalanuvchi)
- [ ] Backend test (withdraw, referral)

## 7. MVP Tayyorlash va Launch
- [ ] Admin tasdiqlovchi panel tayyorlash
- [ ] Google Play va App Store uchun tayyorlash
- [ ] Beta testga chiqarish (yopiq)

Agar xohlasangiz, siz uchun Figma UI dizayn namunasi yoki admin panel strukturasini ham ishlab chiqib bera olaman.

