## Firebase Firestore Collections Structure

### 1. users collection
Document ID: user UID
Fields:
- email: string (foydalanuvchi emaili)
- name: string (foydalanuvchi ismi)
- photoURL: string (profil rasmi URL)
- coins: number (joriy tanga miqdori)
- blockedCoins: number (bloklanган tangalar - withdraw pending)
- totalEarned: number (jami ishlab topgan tangalar)
- lastLogin: timestamp (oxirgi kirish vaqti)
- fcmToken: string (push notification uchun)
- createdAt: timestamp (ro'yxatdan o'tgan vaqt)

### 2. coin_transactions collection
Document ID: auto-generated
Fields:
- userId: string (user UID)
- userName: string (foydalanuvchi ismi)
- userEmail: string (foydalanuvchi emaili)
- amount: number (tanga miqdori, + yoki -)
- type: string ("earned", "spent", "bonus", "withdraw_pending", "withdraw_rejected")
- reason: string (sabab, masalan: "Shop purchase: Airpods", "Daily steps", "Ad reward")
- itemId: string (agar shop purchase bo'lsa)
- timestamp: timestamp (tranzaksiya vaqti)

### 3. shop_items collection
Document ID: auto-generated
Fields:
- name: string (mahsulot nomi)
- cost: number (narxi tangalarda)
- imageUrl: string (rasm URL)
- available: boolean (mavjudligi)
- description: string (tavsif)
- category: string (kategoriya: "electronics", "clothing", "food")
- createdAt: timestamp (qo'shilgan vaqt)

### 4. purchases collection
Document ID: auto-generated
Fields:
- userId: string (user UID)
- userName: string (foydalanuvchi ismi)
- userEmail: string (foydalanuvchi emaili)
- itemId: string (sotib olingan mahsulot ID)
- itemName: string (mahsulot nomi)
- itemCategory: string (mahsulot kategoriyasi)
- cost: number (mahsulot narxi tangalarda)
- description: string (mahsulot tavsifi)
- imageUrl: string (mahsulot rasmi URL)
- purchasedAt: timestamp (sotib olingan vaqt)
- status: string ("completed", "pending", "cancelled")

### 5. withdraw_requests collection
Document ID: auto-generated
Fields:
- userId: string (user UID)
- userName: string (foydalanuvchi ismi)
- userEmail: string (foydalanuvchi emaili)
- amount: number (yechish miqdori)
- method: string ("click", "payme", "uzcard")
- cardNumber: string (karta raqami)
- phoneNumber: string (telefon raqami)
- status: string ("pending", "approved", "rejected", "completed")
- requestedAt: timestamp (so'rov vaqti)
- processedAt: timestamp (qayta ishlangan vaqt)
- adminNote: string (admin izohi)

### 6. withdraw_admin_actions collection
Document ID: auto-generated
Fields:
- withdrawRequestId: string (withdraw_requests document ID)
- adminId: string (admin user ID)
- adminName: string (admin ismi)
- action: string ("approved", "rejected", "completed")
- previousStatus: string (oldingi status)
- newStatus: string (yangi status)
- adminNote: string (admin izohi/sababi)
- actionDate: timestamp (harakat vaqti)
- userId: string (foydalanuvchi ID)
- amount: number (miqdor)

### 7. support_tickets collection
Document ID: auto-generated
Fields:
- userId: string (user UID)
- userEmail: string (foydalanuvchi emaili)
- userName: string (foydalanuvchi ismi)
- subject: string (murojaat mavzusi)
- category: string ("texnik_muammo", "hisob_muammosi", "yangi_funksiya", "to'lov_muammosi", "boshqa")
- priority: string ("past", "o'rta", "yuqori")
- status: string ("yangi", "jarayonda", "javob_kutilmoqda", "yopildi")
- createdAt: timestamp (yaratilgan vaqt)
- updatedAt: timestamp (yangilangan vaqt)
- unreadCount: number (foydalanuvchi uchun o'qilmagan admin xabarlari soni)
- imageUrls: array of strings (birinchi xabardagi rasmlar)

### 8. support_tickets/{ticketId}/messages subcollection
Document ID: auto-generated
Fields:
- senderId: string (user yoki admin ID)
- senderName: string (yuboruvchi ismi)
- senderType: string ("user" yoki "admin")
- message: string (xabar matni)
- timestamp: timestamp (yuborilgan vaqt)
- imageUrls: array of strings (xabardagi rasmlar)
- isRead: boolean (o'qilganmi)

### 9. challenges collection
Document ID: auto-generated
Fields:
- title: string (challenge nomi)
- description: string (tavsif)
- targetSteps: number (maqsadli qadamlar soni)
- reward: number (mukofot tangalar)
- duration: number (davomiyligi kunlarda)
- isActive: boolean (faolmi)
- createdAt: timestamp (yaratilgan vaqt)

### 10. user_challenges collection
Document ID: auto-generated
Fields:
- userId: string (user UID)
- challengeId: string (challenge ID)
- startDate: timestamp (boshlangan vaqt)
- endDate: timestamp (tugash vaqti)
- currentSteps: number (joriy qadamlar)
- targetSteps: number (maqsadli qadamlar)
- status: string ("active", "completed", "failed")
- reward: number (mukofot miqdori)
- completedAt: timestamp (yakunlangan vaqt)

### 11. referrals collection
Document ID: auto-generated
Fields:
- referrerId: string (taklif qiluvchi user ID)
- referredId: string (taklif qilingan user ID)
- referralCode: string (referral kod)
- status: string ("pending", "completed")
- reward: number (mukofot miqdori)
- createdAt: timestamp (yaratilgan vaqt)
- completedAt: timestamp (yakunlangan vaqt)

## Firebase Storage Structure
### support_images/{userId}_{timestamp}.jpg
- contentType: image/jpeg
- userId: string
- uploadedAt: string

### shop_images/{itemId}.jpg
- contentType: image/jpeg
- itemId: string
- uploadedAt: string

## Admin Workflow:
### Withdraw Process:
1. **pending → approved**: Admin tasdiqlaydi
2. **approved → completed**: Pul yuborildi
3. **pending → rejected**: Rad etildi, coins qaytariladi

### Support Process:
1. **yangi → jarayonda**: Admin javob berdi
2. **jarayonda → javob_kutilmoqda**: User javob kutilmoqda
3. **javob_kutilmoqda → yopildi**: Muammo hal qilindi





