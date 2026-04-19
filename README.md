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
<img width="358" height="815" alt="Screenshot 2026-04-19 at 11 13 23" src="https://github.com/user-attachments/assets/bb6837eb-7722-4358-aedd-8e973bdf5f49" />

<img width="355" height="767" alt="Screenshot 2026-04-19 at 11 13 32" src="https://github.com/user-attachments/assets/7762a8fb-eefd-43ef-b8c2-bb944a8043f9" />

<img width="368" height="808" alt="Screenshot 2026-04-19 at 11 13 13" src="https://github.com/user-attachments/assets/617b742c-c080-4cec-9319-4299591dc1b6" />

<img width="365" height="817" alt="Screenshot 2026-04-19 at 11 12 51" src="https://github.com/user-attachments/assets/2390602a-3456-417f-9c10-812155db4e9a" />

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
