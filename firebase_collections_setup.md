# 🔥 REAL-TIME COMPETITIVE RANKING SYSTEM

## 🎯 **MAQSAD:**
Faqat haqiqiy qadam bosayotgan va faol foydalanuvchilar reytingda ko'rinadi. Avtomatik haftalik mukofotlar taqsimlanadi va real-time raqobat yaratiladi!

## 📋 **FIREBASE COLLECTIONS YARATISH KERAK:**

### 1. **** Collection
```javascript
// Document ID: userId (auto-generated yoki custom)
{
  "name": "Ahmad Karimov",
  "email": "ahmad@example.com", 
  "displayName": "Ahmad Karimov",
  "photoUrl": null,
  "totalSteps": 15000,
  "weeklySteps": 3500,
  "monthlySteps": 15000,
  "totalCoins": 500,
  "level": 5,
  "createdAt": 1704067200000,
  "lastUpdated": 1704067200000,
  "friends": [],
  "achievements": [],
  "isActive": true
}
```

### 2. **rankings** Collection  
```javascript
// Document ID: userId
{
  "userId": "sample_user_0",
  "totalSteps": 22000,
  "rank": 1,
  "lastUpdated": 1704067200000
}
```

### 3. **weekly_rankings** Collection
```javascript
// Document ID: {weekStart}_{userId}
{
  "userId": "sample_user_0",
  "steps": 5000,
  "rank": 1,
  "weekStart": 1704067200000,
  "lastUpdated": 1704067200000
}
```

### 4. **monthly_rankings** Collection
```javascript
// Document ID: {monthStart}_{userId}
{
  "userId": "sample_user_0", 
  "steps": 22000,
  "rank": 1,
  "monthStart": 1704067200000,
  "lastUpdated": 1704067200000
}
```

### 5. **active_users** Collection (YANGI!)
```javascript
// Document ID: userId
{
  "userId": "sample_user_0",
  "lastSeen": 1704067200000,
  "isActive": true,
  "lastStepUpdate": 1704067200000,
  "currentSteps": 15000,
  "realStepsDetected": true
}
```

### 6. **weekly_rewards_history** Collection (YANGI!)
```javascript
// Document ID: auto-generated
{
  "weekStart": 1704067200000,
  "weekEnd": 1704067800000,
  "distributedAt": 1704067800000,
  "totalActiveUsers": 25,
  "rewardedUsers": [
    {
      "userId": "sample_user_0",
      "name": "Sardor Umarov",
      "position": 1,
      "reward": 200,
      "totalSteps": 22000
    }
  ],
  "totalCoinsDistributed": 350
}
```

### 7. **daily_bonuses** Collection (YANGI!)
```javascript
// Document ID: auto-generated
{
  "userId": "sample_user_0",
  "amount": 25,
  "date": 1704067200000,
  "streakDays": 5,
  "rankingBonus": 10,
  "weeklyPosition": 1,
  "createdAt": 1704067200000
}
```

### 8. **coin_transactions** Collection (YANGI!)
```javascript
// Document ID: auto-generated
{
  "userId": "sample_user_0",
  "amount": 200,
  "type": "weekly_ranking_reward",
  "description": "Haftalik reyting mukofoti - 1-o'rin",
  "position": 1,
  "weekStart": 1704067200000,
  "createdAt": 1704067200000,
  "metadata": {
    "totalSteps": 22000,
    "weeklySteps": 5000,
    "rank": 1
  }
}
```

## 🎯 **SAMPLE DATA YARATISH:**

### **TOP 5 USERS:**

#### 1. **Sardor Umarov** (1-o'rin) 🥇
```javascript
// users/sample_user_0
{
  "name": "Sardor Umarov",
  "email": "sardor@example.com",
  "displayName": "Sardor Umarov", 
  "photoUrl": null,
  "totalSteps": 22000,
  "weeklySteps": 5000,
  "monthlySteps": 22000,
  "totalCoins": 800,
  "level": 7,
  "createdAt": 1704067200000,
  "lastUpdated": 1704067200000,
  "friends": [],
  "achievements": [],
  "isActive": true
}
```

#### 2. **Bobur Aliyev** (2-o'rin) 🥈
```javascript
// users/sample_user_1
{
  "name": "Bobur Aliyev",
  "email": "bobur@example.com",
  "displayName": "Bobur Aliyev",
  "photoUrl": null,
  "totalSteps": 18000,
  "weeklySteps": 4000,
  "monthlySteps": 18000,
  "totalCoins": 600,
  "level": 6,
  "createdAt": 1704067200000,
  "lastUpdated": 1704067200000,
  "friends": [],
  "achievements": [],
  "isActive": true
}
```

#### 3. **Ahmad Karimov** (3-o'rin) 🥉
```javascript
// users/sample_user_2
{
  "name": "Ahmad Karimov",
  "email": "ahmad@example.com",
  "displayName": "Ahmad Karimov",
  "photoUrl": null,
  "totalSteps": 15000,
  "weeklySteps": 3500,
  "monthlySteps": 15000,
  "totalCoins": 500,
  "level": 5,
  "createdAt": 1704067200000,
  "lastUpdated": 1704067200000,
  "friends": [],
  "achievements": [],
  "isActive": true
}
```

#### 4. **Malika Tosheva** (4-o'rin)
```javascript
// users/sample_user_3
{
  "name": "Malika Tosheva",
  "email": "malika@example.com",
  "displayName": "Malika Tosheva",
  "photoUrl": null,
  "totalSteps": 12500,
  "weeklySteps": 3200,
  "monthlySteps": 12500,
  "totalCoins": 400,
  "level": 4,
  "createdAt": 1704067200000,
  "lastUpdated": 1704067200000,
  "friends": [],
  "achievements": [],
  "isActive": true
}
```

#### 5. **Dilnoza Rahimova** (5-o'rin)
```javascript
// users/sample_user_4
{
  "name": "Dilnoza Rahimova",
  "email": "dilnoza@example.com",
  "displayName": "Dilnoza Rahimova",
  "photoUrl": null,
  "totalSteps": 9500,
  "weeklySteps": 2800,
  "monthlySteps": 9500,
  "totalCoins": 300,
  "level": 3,
  "createdAt": 1704067200000,
  "lastUpdated": 1704067200000,
  "friends": [],
  "achievements": [],
  "isActive": true
}
```

## 🏆 **REWARDS SYSTEM:**

### **Haftalik Mukofotlar:**
- 🥇 **1-o'rin**: 200 tanga
- 🥈 **2-o'rin**: 100 tanga  
- 🥉 **3-o'rin**: 50 tanga

### **Oylik Mukofotlar:**
- 🥇 **1-o'rin**: 400 tanga (2x)
- 🥈 **2-o'rin**: 200 tanga (2x)
- 🥉 **3-o'rin**: 100 tanga (2x)

## 📊 **FIRESTORE INDEXES KERAK:**

### **Composite Indexes:**
1. **users**: `totalSteps` (descending)
2. **weekly_rankings**: `weekStart` (ascending), `steps` (descending)  
3. **monthly_rankings**: `monthStart` (ascending), `steps` (descending)
4. **ranking_rewards**: `userId` (ascending), `createdAt` (descending)
5. **users**: `totalSteps` (greater than) - for ranking position queries

## 🔧 **MANUAL SETUP STEPS:**

### **1. Firebase Console ga kiring:**
- https://console.firebase.google.com/
- Loyihangizni tanlang

### **2. Firestore Database ga o'ting:**
- Cloud Firestore > Data

### **3. Collections yarating:**
- `users`, `rankings`, `weekly_rankings`, `monthly_rankings`, `ranking_rewards`

### **4. Sample data qo'shing:**
- Yuqoridagi JSON ma'lumotlarni copy-paste qiling

### **5. Security Rules o'rnating:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Rankings are read-only for users
    match /rankings/{document} {
      allow read: if request.auth != null;
    }
    
    match /weekly_rankings/{document} {
      allow read: if request.auth != null;
    }
    
    match /monthly_rankings/{document} {
      allow read: if request.auth != null;
    }
    
    match /ranking_rewards/{document} {
      allow read: if request.auth != null;
    }
  }
}
```

## ✅ **TEKSHIRISH:**

1. **App ishga tushganda:**
   - Firebase Collections yaratiladi
   - Sample data qo'shiladi
   - Ranking Screen ochiladi

2. **Ranking Screen da:**
   - Top 3 podium ko'rinadi
   - Global, Haftalik, Oylik, Do'stlar tab'lari ishlaydi
   - Mukofotlar ko'rsatiladi

3. **Step Counter ishlaganda:**
   - Ranking avtomatik yangilanadi
   - Real-time updates ishlaydi

## 🚀 **KEYINGI QADAMLAR:**

1. **Cloud Functions** (mukofotlarni avtomatik berish)
2. **Push Notifications** (ranking o'zgarishida)
3. **Leaderboard Animations** (podium animatsiyalari)
4. **Social Features** (do'stlar qo'shish)
5. **Achievement System** (yutuqlar tizimi)

---

**🎯 MAQSAD:** Eng ko'p qadam bosgan TOP 50 foydalanuvchi reytingda ko'rinadi va eng yaxshi 3tasi mukofot oladi!
