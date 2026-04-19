# LoanTrack iOS

> A fintech iOS application for mortgage calculation and lead management, 
> built with SwiftUI. Designed for mortgage brokers, loan officers, 
> and real estate professionals.

![Platform](https://img.shields.io/badge/Platform-iOS%2016%2B-blue)
![Language](https://img.shields.io/badge/Language-Swift%205.9-orange)
![Framework](https://img.shields.io/badge/Framework-SwiftUI-purple)
![Status](https://img.shields.io/badge/Status-Active%20Development-green)

---

## Screenshots

> Dashboard · Calculator · Leads · Lead Detail



---

## Features

### Mortgage Calculator
- Real-time payment calculation using standard amortization formula
- Inputs: loan amount, down payment, interest rate, loan term
- Outputs: monthly payment, total payment, total interest paid
- Animated results with clean financial formatting

### Lead Management (CRM)
- Full CRUD — add, view, edit, delete leads
- Lead status pipeline: New → Contacted → Qualified → Closed → Lost
- Search and filter leads by name or email
- Persistent local storage — data survives app restarts
- Lead detail screen with contact info, loan amount, and notes

### Dashboard
- Real-time pipeline metrics — total leads, new, qualified, closed
- Total pipeline value calculation
- Recent leads quick view with navigation
- Time-aware greeting

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Language | Swift 5.9 |
| Framework | SwiftUI |
| Architecture | MVVM |
| Data Persistence | UserDefaults (JSON encoded) |
| State Management | @StateObject / @EnvironmentObject |
| Minimum iOS | iOS 16+ |

---

## Architecture
