# Personal Expense Tracker V2 Roadmap

## Vision

Replace monthly Google Sheets with a fast, local-first expense tracker
tailored to my workflow while adding intelligent budgeting, insights,
and AI recommendations.

## Core Principles

-   Local-first (works offline)
-   Fast expense entry (\<5 seconds)
-   Clear separation between planning and tracking
-   AI assists decisions instead of replacing them
-   Designed for one user (me)

------------------------------------------------------------------------

# Architecture

## Frontend

-   Flutter
-   Riverpod (recommended)
-   Material 3 UI
-   Drift (SQLite) or Hive for local storage

## Backend (Free)

-   Render API (AI endpoints, notifications, backup)
-   OpenRouter for LLMs
-   Firebase Cloud Messaging for push notifications

## Storage Strategy

Primary storage: - Local database

Backend responsibilities: - AI analysis - Push notifications - Optional
backup/sync

------------------------------------------------------------------------

# Data Model

## Budget Plan

Stores planned monthly allocations. - Month - Category - Subcategory -
Planned amount

## Transactions

Real spending history. Types: - Expense - Transfer - Income

Fields: - Amount - Category - Date - Notes - Payment method - Tags

## Fixed Allocations

-   Charity
-   Savings
-   Investments
-   Subscriptions

These are tracked separately from daily expenses.

------------------------------------------------------------------------

# Application Structure

## Dashboard

Shows: - Today's spending - Remaining daily budget - Monthly remaining -
Envelope progress - AI insight of the day - Quick Add button

## Planning

Spreadsheet replacement. Features: - Monthly budget planning - Copy
previous month - Planned vs Actual - Envelope visualization - Remaining
allocation

## Daily Tracking

Only personal spending: - Food - Transport - Shopping - Entertainment -
Miscellaneous

Fast entry with: - Amount - Category - Note

No savings or subscriptions shown here.

## Fixed Expenses

Manual or recurring: - Charity - Savings - Investments - Subscriptions

------------------------------------------------------------------------

# Features

## Existing

-   Monthly planning
-   Daily tracking
-   Planned vs actual

## New V2

### Budgeting

-   Envelope budgeting
-   Remaining safe-to-spend per day
-   Planned vs Actual comparison
-   Automatic monthly allocation

### Insights

-   Weekly review report
-   Spending trends
-   Budget drift detection
-   Overspending alerts

### AI

-   Budget recommendations
-   Weekly suggestions
-   Spending pattern analysis
-   Category recommendations

### Notifications

-   Daily reminder
-   Overspending alerts
-   Weekly summary
-   Subscription reminders

### UX

-   Modern dashboard
-   Cleaner cards
-   Bottom navigation
-   Dark mode optimized
-   Faster expense entry

------------------------------------------------------------------------

# Requested New Features

## 1. End of Day Summary

Displays: - Total spent - Largest category - Remaining budget -
Comparison with yesterday

## 2. Anomaly Detection

Detect: - Unusually large expenses - Rare categories - Spending spikes

## 3. Home Screen Widget

Shows: - Today's spending - Remaining budget - Quick Add shortcut

## 4. Smart Search

Search by: - Category - Date - Amount - Note - Tags

## 5. Timeline / History View

Interactive timeline to: - Browse daily spending - View monthly
evolution - Undo/edit recent entries

## 6. Envelope Visualization

Every category becomes a budget jar showing: - Planned - Used -
Remaining - Color state

## 7. Safe-to-Spend Metric

Calculates: Remaining Monthly Budget / Remaining Days

Displayed prominently on the dashboard.

## 8. Weekly Review

Automatic report: - Total spending - Biggest category - Compared to
previous week - AI insights - Budget health score

------------------------------------------------------------------------

# Future Ideas

## AI Chat

Ask: - Why did I overspend? - Where can I save? - Predict month-end
balance.

## Voice Input

"Spent 450 on lunch."

## Auto Categorization

Keyword-based first, AI-assisted later.

## Split Transactions

One transaction across multiple categories.

## Goals

Savings progress: - Laptop - Germany - Emergency fund

------------------------------------------------------------------------

# UI Refresh

Replace spreadsheet appearance with: - Cards - Progress bars - Circular
envelope indicators - Better spacing - Material 3 design - Responsive
layouts

Navigation: 1. Dashboard 2. Daily 3. Planning 4. Fixed 5. Insights 6.
Settings

------------------------------------------------------------------------

# Milestones

## V2.0

-   New UI
-   Local database
-   Budget planner
-   Daily tracking separation
-   Fixed expenses
-   Envelope budgeting

## V2.1

-   Weekly reports
-   AI suggestions
-   Notifications
-   Safe-to-spend
-   Anomaly detection

## V2.2

-   Widget
-   Smart search
-   Timeline
-   Goals
-   Voice input
-   Optional cloud backup

------------------------------------------------------------------------

# Success Criteria

-   Completely replaces monthly spreadsheets.
-   Daily expense entry under 5 seconds.
-   Budget health visible at a glance.
-   AI provides actionable recommendations.
-   Works fully offline with optional cloud enhancements.
