# Vendor Admin App Architecture

## Overview
A modern vendor admin app for managing multi-type businesses (stores, restaurants, pharmacies) with registration, authentication, order management, product management, and statistics dashboard.

## Core Features (MVP)
1. **Authentication System**
   - Registration with business type selection
   - Login/logout functionality
   - Profile management

2. **Business Setup**
   - Store details configuration
   - Business type selection (Store/Restaurant/Pharmacy)
   - Profile information management

3. **Dashboard & Statistics**
   - Revenue analytics
   - Order statistics
   - Product performance metrics
   - Visual charts and graphs

4. **Order Management**
   - Latest orders display
   - Order status tracking
   - Order details view

5. **Product Management**
   - Add new products form
   - Product category management
   - Product listing and editing

## Technical Architecture

### File Structure (11 files total)
1. `lib/main.dart` - App entry point with routing
2. `lib/theme.dart` - Updated theme for vendor admin app
3. `lib/models/vendor.dart` - Vendor data model
4. `lib/models/product.dart` - Product data model
5. `lib/models/order.dart` - Order data model
6. `lib/screens/auth/login_screen.dart` - Login interface
7. `lib/screens/auth/register_screen.dart` - Registration with business setup
8. `lib/screens/home/dashboard_screen.dart` - Main dashboard with statistics
9. `lib/screens/orders/orders_screen.dart` - Orders management
10. `lib/screens/products/add_product_screen.dart` - Product creation form
11. `lib/services/local_storage.dart` - Data persistence service

### Data Models
- **Vendor**: ID, name, email, business type, store details, profile info
- **Product**: ID, name, description, price, category, vendor ID, images
- **Order**: ID, customer info, items, total, status, timestamp, vendor ID

### UI Design Principles
- Material 3 design with purple theme
- Modern card-based layouts
- Smooth animations and transitions
- Responsive design for tablets
- Intuitive navigation patterns

### Business Types
1. **Store** - General merchandise
2. **Restaurant** - Food & beverages  
3. **Pharmacy** - Medical products & prescriptions

### Sample Data
- Pre-populated orders for demonstration
- Sample products for each business type
- Mock statistics and analytics data

## Implementation Steps
1. Update theme colors for vendor admin aesthetic
2. Create data models and storage service
3. Implement authentication screens with modern UI
4. Build registration flow with business setup
5. Create dashboard with statistics and charts
6. Implement orders management screen
7. Build product addition form
8. Add sample data and test all flows
9. Final compilation and debugging