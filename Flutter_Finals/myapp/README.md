# ApliMart — Appliance Marketplace App

A full-stack mobile marketplace for buying and selling home appliances. Built with Flutter and powered by Supabase as the backend.

---

## About the App

ApliMart lets customers browse appliances, add them to cart, and place orders. An admin panel manages products, approves orders, and assigns riders. Riders have their own delivery dashboard to accept pickups and track deliveries in real time.

**Key features:**
- Browse appliances by category (TV, Refrigerator, Washing Machine, AC, Fan, Microwave, Vacuum)
- Flash Sale section with discount badges
- Cart and checkout with Cash on Delivery
- Order tracking with status notifications
- Customer support chat (Messages)
- Admin dashboard — product CRUD, order management, rider assignment
- Rider delivery dashboard — accept pickups, mark on-the-way, confirm delivery
- Image upload for products via Supabase Storage
- Real-time order updates via Supabase Realtime

---

## Technology Stack

| Layer | Technology |
|-------|-----------|
| Language | Dart 3 |
| Framework | Flutter 3 |
| Backend / Database | Supabase (PostgreSQL) |
| Authentication | Supabase Auth |
| File Storage | Supabase Storage (`product-images` bucket) |
| Real-time | Supabase Realtime (Postgres CDC) |
| State Management | Provider (ChangeNotifier) |
| Image Loading | cached_network_image + shimmer |
| Image Picker | image_picker |
| Notifications | In-app (notifications table) |

---

## Project Structure

```
lib/
├── config/          # Supabase credentials, app theme
├── models/          # Product, Order, CartItem, etc.
├── providers/       # AuthProvider, CartProvider, ProductProvider, ...
├── screens/
│   ├── admin/       # Admin dashboard (products, orders, riders)
│   ├── auth/        # Login, Register
│   ├── cart/        # Cart screen
│   ├── checkout/    # Checkout flow
│   ├── delivery/    # Rider delivery dashboard
│   ├── home/        # Home screen + widgets
│   ├── orders/      # Order list and detail
│   ├── product/     # Product detail
│   └── profile/     # Profile, addresses, payment methods
├── services/        # ProductService, RiderAccountService, ...
└── widgets/         # Shared widgets
```

---

## Database Setup (Supabase)

### 1. Create a Supabase project
Go to [https://supabase.com](https://supabase.com), create a new project, and note your **Project URL** and **API Keys**.

### 2. Run the setup SQL
In your Supabase project → **SQL Editor**, paste and run the full contents of `supabase_setup.sql` found in the project root. This creates:
- `products`, `profiles`, `orders`, `notifications`, `messages` tables
- Row Level Security (RLS) policies for customers, admins, and riders
- `product-images` storage bucket with public read access

### 3. Clear any old product rows (optional)
If you re-run the SQL, it automatically runs `DELETE FROM public.products` at the top so the table starts clean. Add products through the Admin panel.

### 4. Set admin user
After registering your admin account in the app, go to Supabase → **Authentication → Users** → find your user → **Edit** → add to `raw_user_meta_data`:
```json
{ "is_admin": true }
```

### 5. Add the `rider_id` column (if not already present)
If upgrading from an older version, run this once:
```sql
alter table public.orders
  add column if not exists rider_id uuid references auth.users(id);
```

---

## Running on an Android Phone

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed
- Android Studio or VS Code with Flutter extension
- A physical Android phone **or** an emulator

### Step 1 — Clone / open the project
```
cd Flutter_Finals/myapp
```

### Step 2 — Add Supabase credentials
Open `lib/config/supabase_config.dart` and fill in your project values:
```dart
static const supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
static const supabasePublishableKey = 'sb_publishable_...';
static const serviceRoleKey = 'sb_secret_...';   // for rider account creation
```

### Step 3 — Install dependencies
```bash
flutter pub get
```

### Step 4 — Connect your Android phone
1. On your phone, go to **Settings → About Phone** → tap **Build Number** 7 times to enable Developer Mode.
2. Go to **Settings → Developer Options** → enable **USB Debugging**.
3. Connect your phone via USB cable.
4. Run `flutter devices` to confirm your phone is listed.

### Step 5 — Run the app
```bash
flutter run
```
Flutter will build and install the app on your phone automatically.

### Step 6 — Build a release APK (optional)
To share the APK without a computer:
```bash
flutter build apk --release
```
The APK is saved to `build/app/outputs/flutter-apk/app-release.apk`. Transfer it to any Android phone and install it (enable "Install from unknown sources" in settings).

---

## User Roles

| Role | How to Set | What They Can Do |
|------|-----------|-----------------|
| Customer | Register normally | Browse, buy, track orders |
| Admin | Set `is_admin: true` in Supabase user metadata | Full admin dashboard |
| Rider | Created by admin inside the app | Delivery dashboard |

---

## Notes

- The app requires an active internet connection to reach Supabase.
- All product images are uploaded to Supabase Storage and served via public CDN URL.
- Orders without an assigned rider cannot be marked as "Picked Up" — the admin must assign a rider first.
