# LoanTrack – Full-Stack Fintech Mobile Application

[
](https://saadvarg.github.io/LoanTrackWeb/images/Simulator_Screenshot_-_iPhone_17_Pro_-_2026-05-07_at_13.25.04-1.png)
[
](https://saadvarg.github.io/LoanTrackWeb/images/Simulator_Screenshot_-_iPhone_17_Pro_-_2026-05-07_at_13.25.15-1.png)
[
](https://saadvarg.github.io/LoanTrackWeb/images/Simulator_Screenshot_-_iPhone_17_Pro_-_2026-05-07_at_13.25.15-1.png)

A production-ready fintech iOS application demonstrating full-stack development with Swift/SwiftUI frontend, Node.js/Express backend, and Supabase PostgreSQL database.

> **Watch the app in action:** [App Walkthrough Video](https://youtu.be/ZNXLBsGXSeE?si=v6bO7Q7gmtligBMd) | **See the demo:** [Live Web Interface](https://saadvarg.github.io/LoanTrackWeb/) | **Learn more:** [iOS Developer Portfolio](https://www.youtube.com/watch?v=rrBVHWx6H7E)

---

## 🎬 Quick Links

| **Resource** | **Link** |
|---|---|
| 🌐 **Live Web Demo** | https://saadvarg.github.io/LoanTrackWeb/ |
| 🎥 **App Feature Walkthrough** | https://youtu.be/ZNXLBsGXSeE?si=v6bO7Q7gmtligBMd |
| 💼 **iOS Developer Portfolio** | https://www.youtube.com/watch?v=rrBVHWx6H7E |
| 🔗 **GitHub Repository** | https://github.com/saadvarg/LoanTrack-iOS |
| 📧 **Contact** | elmouataz.saad@gmail.com |

---

## Overview

LoanTrack is a **full-stack fintech application** built from the ground up to demonstrate production-grade iOS development combined with scalable backend architecture. Designed for mortgage professionals to manage leads, calculate loans, and interact with real-time backend services.

**Key Highlights:**
- ✅ **Shipped to production** with real users
- ✅ **Full-stack ownership:** SwiftUI frontend → Node.js backend → PostgreSQL database
- ✅ **Production security:** JWT authentication, role-based access control, encrypted data
- ✅ **Real-world complexity:** Multi-user systems, concurrent API calls, state management at scale
- ✅ **Solo shipped:** Built in 6 months while maintaining freelance clients

---

## 🎯 Features

### iOS Application (SwiftUI)

**Mortgage Calculator**
- Real-time amortization calculations
- Inputs: loan amount, interest rate, term, down payment
- Outputs: monthly payment, total cost, interest breakdown

**Lead Management (CRM)**
- Full CRUD operations (Create, Read, Update, Delete)
- Pipeline tracking: New → Contacted → Qualified → Closed → Lost
- Search, filter, and sort leads
- Lead detail view with notes, contact history, financial data
- PDF export of lead summaries

**Analytics Dashboard**
- Real-time metrics: total leads, qualified count, closed deals
- Pipeline value calculation and conversion rates
- Recent leads overview with status indicators

**Multi-User System**
- 4-tier role system: Superadmin → Admin → Agent → Viewer
- Role-based access control (RBAC)
- Secure JWT authentication with token refresh
- User profile management

### Backend API (Node.js)

- RESTful architecture with 20+ endpoints
- JWT authentication and secure token refresh
- Role-based access control preventing privilege escalation
- Lead management endpoints (CRUD + filtering)
- PDF generation service
- Lead scoring system (AI/ML integration ready)
- Supabase PostgreSQL integration

---

## 🏗️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **iOS** | Swift 5.9+ / SwiftUI |
| **Backend** | Node.js 18+ / Express |
| **Database** | Supabase (PostgreSQL) |
| **Authentication** | JWT with refresh tokens |
| **Architecture** | MVVM (iOS) + RESTful APIs |
| **Deployment** | Vercel (backend) + GitHub Pages (web) |

---

## 📁 Project Structure

```
LoanTrack/
├── ios-app/              # SwiftUI iOS Application
│   ├── Views/           # UI components
│   ├── ViewModels/      # MVVM business logic
│   ├── Services/        # API calls & networking
│   ├── Models/          # Data structures
│   └── LoanTrack.xcodeproj
│
├── backend/             # Node.js/Express Backend
│   ├── routes/          # API endpoints
│   ├── controllers/     # Request handlers
│   ├── middleware/      # Auth, validation, logging
│   ├── package.json
│   └── server.js
│
└── README.md
```

---

## 🎨 Architecture

**iOS MVVM Pattern:**
```
SwiftUI Views
    ↓
ViewModels (State Management)
    ↓
Services (API Calls)
    ↓
URLSession (Network Layer)
    ↓
Backend (Node.js + PostgreSQL)
```

**Data Flow:**
```
User Action → ViewModel → API Request → Backend → Database → Response → UI Update
```

---

## 🚀 Getting Started

### Prerequisites
- macOS 12+ with Xcode 15+
- iOS 16+ (simulator or device)
- Node.js 18+ and npm
- Git

### Clone Repository

```bash
git clone https://github.com/saadvarg/LoanTrack-iOS.git
cd LoanTrack
```

### Run iOS App

```bash
cd ios-app
open LoanTrack.xcodeproj
```

Press **Cmd + R** in Xcode to build and run.

### Run Backend API

```bash
cd backend
npm install
cp .env.example .env
# Edit .env with your Supabase credentials
npm run dev
# Server runs on http://localhost:3000
```

### Database Setup (Supabase)

1. Create account at [supabase.com](https://supabase.com)
2. Create new project
3. Copy `DATABASE_URL` to `.env`
4. Run migrations: `npm run migrate`

---

## 🔐 Security Features

- ✅ JWT authentication with secure token refresh
- ✅ Role-based access control (4-tier permission system)
- ✅ Password hashing with bcrypt
- ✅ SQL injection prevention via parameterized queries
- ✅ CORS configuration for secure cross-origin requests
- ✅ HTTPS only for API communication

---

## 📈 Current Status

**Active Development**

- ✅ Backend API fully integrated
- ✅ Authentication system (JWT login/refresh)
- ✅ Mortgage calculator with real-time amortization
- ✅ Lead management CRM (full CRUD)
- ✅ Role-based access control (4-tier)
- ✅ Analytics dashboard with real-time metrics
- ✅ PDF generation for lead reports
- ⏳ Advanced AI-powered lead scoring
- ⏳ Push notifications (reminders & follow-ups)
- ⏳ App Store deployment (TestFlight beta)

---

## 👨‍💻 About the Author

**Saad El Mouataz** — Full-stack developer with 9+ years in fintech operations, specializing in building production-grade mobile applications.

**Background:**
- Fintech operations at CR Equity AI
- CRM systems at Avail (Realtor.com)
- Fintech consulting (Top Rated on Fiverr)
- Education: Master's in Business/Marketing (HEM), Bachelor's in progress (CS, ISMAGI)

**Links:**
- 💼 [Live Demo](https://saadvarg.github.io/LoanTrackWeb/)
- 🎥 [App Walkthrough](https://youtu.be/ZNXLBsGXSeE?si=v6bO7Q7gmtligBMd)
- 📱 [Developer Portfolio](https://www.youtube.com/watch?v=rrBVHWx6H7E)
- 🌐 [GitHub](https://github.com/saadvarg)
- 💻 [Fiverr Profile](https://www.fiverr.com/saadvarg)
- 📧 [Email](mailto:elmouataz.saad@gmail.com)

---

## 📄 License

MIT License — Free to use, modify, and distribute. See LICENSE for details.

---

## 🎯 What This Demonstrates

1. **Production-Grade iOS Development** — Modern SwiftUI patterns, async/await, MVVM architecture
2. **Backend Engineering** — RESTful APIs, authentication, database design, deployment
3. **Full-Stack Thinking** — Understanding trade-offs between frontend/backend, product-oriented design
4. **Shipping Quality** — Security, error handling, scalability from day one

---

<div align="center">

**Built with SwiftUI · Production-Ready Architecture · Fintech-Grade Security**

[🌐 Live Demo](https://saadvarg.github.io/LoanTrackWeb/) • [🎥 App Video](https://youtu.be/ZNXLBsGXSeE?si=v6bO7Q7gmtligBMd) • [💼 Portfolio](https://www.youtube.com/watch?v=rrBVHWx6H7E) • [👨‍💻 GitHub](https://github.com/saadvarg)

</div>
