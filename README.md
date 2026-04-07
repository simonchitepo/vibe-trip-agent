# 🌍 Vibe Trip Agent

### *One vibe in. One tap. Full trip.*

**Vibe Trip Agent** is an AI-powered travel planning assistant that transforms a simple "vibe" into a comprehensive, multi-day itinerary. By bridging the gap between inspiration and logistics, it handles flights, stays, transit, and dining recommendations in a single, fluid experience.

[![Platform - Android](https://img.shields.io/badge/Platform-Android-green?logo=android)](https://play.google.com/store)
[![Platform - Windows](https://img.shields.io/badge/Platform-Windows-blue?logo=windows)](https://apps.microsoft.com)
[![Framework - Flutter](https://img.shields.io/badge/Framework-Flutter-02569B?logo=flutter)](https://flutter.dev)
[![Backend - Cloud Run](https://img.shields.io/badge/Backend-Cloud_Run-4285F4?logo=google-cloud)](https://cloud.google.com/run)
[![AI - Gemini](https://img.shields.io/badge/AI-Gemini-4285F4?logo=google)](https://deepmind.google/technologies/gemini/)
[![License - MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## 📖 Table of Contents
- [Overview](#-overview)
- [Problem Statement](#-problem-statement)
- [Solution](#-solution)
- [Core Features](#-core-features)
- [Tech Stack](#-tech-stack)
- [System Architecture](#-system-architecture)
- [UML Diagrams](#-uml-diagrams)
- [Project Structure](#-project-structure)
- [Installation & Setup](#-installation--setup)
- [Environment Configuration](#-environment-configuration)
- [Deployment](#-deployment)
- [API Documentation](#-api-documentation)
- [Use Cases](#-use-cases)
- [Roadmap](#-roadmap)
- [Contributing](#-contributing)
- [License](#-license)
- [Support](#-support)

---

## 🚀 Overview

Traditional travel planning is fragmented across dozens of tabs, apps, and booking sites. **Vibe Trip Agent** simplifies this by using **Generative AI** to process a user's mood, budget, and travel dates into a structured, actionable plan.

Designed for speed and a premium user experience, Vibe Trip Agent serves as a **personal concierge in your pocket** — available on Android and Windows, powered by scalable Google Cloud infrastructure.

### Key Metrics
- ⚡ **5-second** itinerary generation
- 🌍 **150+** destinations covered
- 💬 **Real-time** chat with providers
- 📱 **Cross-platform** support

---

## ❗ Problem Statement

Traditional travel platforms suffer from:

| Problem | Impact |
|---------|--------|
| **Generic, non-personalized recommendations** | Wasted time, irrelevant suggestions |
| **Fragmented booking processes** | Users leave platform to book elsewhere |
| **Lack of real-time interaction with providers** | Delayed responses, missed opportunities |
| **Static listings without contextual matching** | No "vibe" or mood-based discovery |
| **Information overload** | Decision paralysis |

---

## 💡 Solution

Vibe Trip Agent solves these problems with:

| Solution | Benefit |
|----------|---------|
| **AI-powered vibe matching** | Personalized recommendations in seconds |
| **Unified booking interface** | End-to-end trip planning without leaving app |
| **Real-time chat with providers** | Instant negotiation and confirmation |
| **Dynamic, contextual recommendations** | "Vibe in, trip out" — no manual searching |
| **Smart itinerary generation** | Structured plans with flights, stays, transit, dining |

---

## 🧠 Core Features

### ✨ 1. Vibe-Based Travel Discovery
- Users select or input their mood (e.g., "adventure", "luxury", "chill", "cyberpunk")
- Intelligent recommendation engine suggests destinations & experiences
- Real-time vibe validation against current travel trends

### 💬 2. Real-Time Chat System
- Direct communication between customers and providers
- Instant negotiation, inquiry, and booking confirmation
- Typing indicators, read receipts, message history

### 📅 3. Booking Management
- End-to-end booking workflow (search → select → book → confirm)
- Status tracking: Pending → Confirmed → Completed → Cancelled
- Calendar integration and reminders

### 👤 4. User Profiles
- Personalized preferences and saved vibes
- Travel history and past itineraries
- Favorite destinations and providers

### 🧑‍💼 5. Provider Dashboard
- Manage listings, availability, and pricing
- Respond to customer inquiries in real-time
- Analytics and booking insights

### 🔔 6. Smart Notifications
- Booking confirmations and updates
- New chat messages
- Personalized recommendations based on saved vibes
- Price drop alerts

### 🤖 7. AI Itinerary Generation
- Natural language vibe input
- Structured day-by-day plans
- Flight, hotel, transit, and dining suggestions
- Budget optimization

---

## 🏗️ Tech Stack

### 📱 Frontend
| Technology | Purpose |
|------------|---------|
| **Flutter 3.16+** | Cross-platform UI framework |
| **Dart** | Programming language |
| **Riverpod** | State management |
| **GoRouter** | Navigation & routing |
| **Material 3** | UI components & theming |

### ☁️ Backend & Infrastructure
| Technology | Purpose |
|------------|---------|
| **Google Cloud Run** | Serverless containerized backend |
| **Cloud Firestore** | Real-time NoSQL database |
| **Firebase Authentication** | User management & security |
| **Firebase Cloud Messaging** | Push notifications |
| **Cloud Storage** | Media & file storage |
| **Cloud Functions** | Serverless event-driven logic |

### 🧠 AI & Intelligence
| Technology | Purpose |
|------------|---------|
| **Google Gemini API** | Itinerary generation & vibe matching |
| **OpenAI GPT (fallback)** | Natural language processing |
| **Custom recommendation engine** | Destination matching |

### 🌐 Hosting & Deployment
| Platform | Purpose |
|----------|---------|
| **Google Cloud Platform** | Primary cloud infrastructure |
| **cPanel** | Static asset hosting |
| **GitHub Actions** | CI/CD pipeline |

---

## 🧩 System Architecture

```mermaid
graph TB
    subgraph "Client Layer"
        A[Flutter App - Android] 
        B[Flutter App - Windows]
    end
    
    subgraph "Google Cloud Platform"
        C[Cloud Run - Backend API]
        D[Firebase Auth]
        E[Cloud Firestore]
        F[Cloud Storage]
        G[Cloud Functions]
    end
    
    subgraph "AI Layer"
        H[Google Gemini API]
        I[OpenAI GPT]
    end
    
    subgraph "External Services"
        J[Flight APIs]
        K[Hotel APIs]
        L[Payment Gateways]
    end
    
    A --> C
    B --> C
    A --> D
    B --> D
    C --> E
    C --> F
    C --> G
    C --> H
    C --> I
    C --> J
    C --> K
    C --> L
    E --> A
    E --> B

    sequenceDiagram
    participant User
    participant App as Flutter App
    participant API as Cloud Run API
    participant AI as Gemini AI
    participant DB as Firestore
    participant Provider as Service Provider
    
    User->>App: Enter vibe ("Cyberpunk Tokyo")
    App->>API: POST /api/generate-itinerary
    API->>AI: Generate travel plan
    AI-->>API: Structured itinerary JSON
    API-->>App: Return itinerary
    App->>User: Display trip plan
    
    User->>App: Select & book
    App->>DB: Save booking
    DB->>Provider: Send notification
    Provider-->>DB: Confirm booking
    DB-->>App: Update status
    App->>User: "Booking confirmed!"

    graph LR
    subgraph "Actors"
        User[👤 Customer]
        Provider[🧑‍💼 Provider]
        Admin[🔧 Admin]
    end
    
    subgraph "Use Cases"
        UC1[Browse Vibes]
        UC2[Generate Itinerary]
        UC3[Chat with Provider]
        UC4[Book Trip]
        UC5[Manage Listings]
        UC6[Respond to Chats]
        UC7[Confirm Bookings]
        UC8[Analytics Dashboard]
    end
    
    User --> UC1
    User --> UC2
    User --> UC3
    User --> UC4
    
    Provider --> UC5
    Provider --> UC6
    Provider --> UC7
    
    Admin --> UC8

    sequenceDiagram
    autonumber
    actor User
    participant App as Flutter App
    participant API as Cloud Run API
    participant AI as Gemini AI
    participant DB as Firestore
    participant FCM as Firebase Cloud Messaging
    actor Provider
    
    User->>App: Input vibe + dates
    App->>API: Generate itinerary request
    API->>AI: Process vibe prompt
    AI-->>API: Return structured plan
    API-->>App: Display itinerary
    
    User->>App: Select provider
    User->>App: Send inquiry message
    App->>DB: Store message
    DB->>FCM: Trigger notification
    FCM->>Provider: "New inquiry received"
    
    Provider->>App: View & respond
    App->>DB: Store response
    DB->>FCM: Customer notification
    FCM->>User: "Provider responded"
    
    User->>App: Confirm booking
    App->>DB: Create booking record
    DB->>FCM: Notify provider
    FCM->>Provider: "New booking request"
    
    Provider->>App: Accept booking
    App->>DB: Update status to "confirmed"
    DB->>FCM: Customer notification
    FCM->>User: "Booking confirmed!"
    
    App->>User: Show confirmation screen

    classDiagram
    class User {
        +String id
        +String name
        +String email
        +List~String~ preferences
        +List~String~ savedVibes
        +List~Booking~ bookings
        +login()
        +savePreferences()
        +viewBookings()
    }
    
    class Provider {
        +String id
        +String businessName
        +String category
        +List~Listing~ listings
        +List~Booking~ bookings
        +updateAvailability()
        +respondToChat()
        +confirmBooking()
    }
    
    class Vibe {
        +String id
        +String mood
        +List~String~ keywords
        +List~Destination~ destinations
        +matchScore()
    }
    
    class Itinerary {
        +String id
        +String userId
        +String vibe
        +DateTime startDate
        +DateTime endDate
        +List~Day~ days
        +double budget
        +generate()
        +optimize()
    }
    
    class Booking {
        +String id
        +String userId
        +String providerId
        +String itineraryId
        +BookingStatus status
        +double totalPrice
        +DateTime createdAt
        +confirm()
        +cancel()
        +updateStatus()
    }
    
    class Chat {
        +String id
        +String bookingId
        +List~Message~ messages
        +sendMessage()
        +markAsRead()
    }
    
    class Message {
        +String id
        +String senderId
        +String content
        +DateTime timestamp
        +bool isRead
    }
    
    User "1" -- "*" Booking
    User "1" -- "*" Itinerary
    Provider "1" -- "*" Booking
    Booking "1" -- "1" Chat
    Chat "1" -- "*" Message
    Itinerary "1" -- "*" Booking
    Vibe "*" -- "*" Destination
