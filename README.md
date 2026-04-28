# LoanTrack – Full-Stack Mobile Application

LoanTrack is a full-stack fintech mobile application designed for mortgage professionals to manage leads, calculate loans, and interact with real-time backend services.

Built using modern iOS technologies with a scalable backend architecture, the project demonstrates real-world mobile development, API integration, and product-oriented design.

---

##  Overview

* **iOS App**: Built with Swift and SwiftUI
* **Backend API**: Node.js + Express
* **Database**: Supabase (PostgreSQL)
* **Authentication**: JWT-based login system
* **Use Case**: Lead management + mortgage calculation for financial workflows

---

##  Project Structure

```
LoanTrack/
 ├── ios-app/        # SwiftUI iOS application
 ├── backend/        # Node.js REST API
 └── README.md
```

---

## Features

###  iOS Application (SwiftUI)

#### Mortgage Calculator

* Real-time loan calculations using amortization formulas
* Inputs: loan amount, interest rate, term, down payment
* Outputs: monthly payment, total cost, interest breakdown

#### Lead Management (CRM)

* Full CRUD operations (Create, Read, Update, Delete)
* Lead pipeline: New → Contacted → Qualified → Closed → Lost
* Search and filtering functionality
* Lead detail view with notes and financial data

#### Dashboard

* Real-time metrics (total leads, qualified, closed)
* Pipeline value calculation
* Recent leads overview

---

### Backend API (Node.js)

* RESTful API architecture
* Authentication with JWT
* Role-based access control
* Lead management endpoints
* PDF generation service
* Scoring system for lead evaluation
* Integration-ready with frontend (iOS app)

---

## Tech Stack

### iOS

* Swift 5+
* SwiftUI (with UIKit interoperability)
* MVVM Architecture
* State Management: `@StateObject`, `@EnvironmentObject`

### Backend

* Node.js / Express
* Supabase (PostgreSQL)
* REST APIs
* Authentication Middleware

### Tools & Integrations

* Firebase (Crashlytics, Analytics – planned / optional)
* Alamofire (network layer – planned integration)

---

## Architecture

### iOS (MVVM)

```
Views → ViewModels → Services → API → Backend
```

* Clean separation of concerns
* Reactive UI updates via SwiftUI
* Scalable for future integrations

---

## Data Flow

```
User Interaction (SwiftUI)
        ↓
ViewModel Logic
        ↓
API Request (REST)
        ↓
Node.js Backend
        ↓
Database (Supabase)
        ↓
Response → UI Update
```

---

## Current Status

Active development

Recent updates:

* Backend API integration
* Authentication system
* Improved app structure (full-stack separation)

---

## Roadmap

* Full API integration using Alamofire
* Firebase integration (Analytics & Crashlytics)
* Push notifications (follow-ups & reminders)
* Advanced analytics dashboard
* AI-powered lead scoring
* App Store deployment

---

## Author

**Saad El Mouataz**

Full-stack developer with a strong background in fintech operations, specializing in building real-world mobile applications that combine business logic with modern technologies.

---

## Getting Started

### Clone the repository

```
git clone https://github.com/saadvarg/LoanTrack.git
cd LoanTrack
```

### Run iOS App

```
cd ios-app
open LoanTrack.xcodeproj
```

Then press `Cmd + R` in Xcode

---

### Run Backend API

```
cd backend
npm install
npm run dev
```

---

## Requirements

* macOS with Xcode 15+
* iOS 16+ simulator
* Node.js installed

---

##  License

MIT License — free to use, modify, and distribute.

---

##  Note

This project is actively evolving and demonstrates practical experience in:

* iOS development with SwiftUI
* API integration and backend systems
* Real-world product design and architecture

---

Built with SwiftUI · Designed for real-world fintech workflows
