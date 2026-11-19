# Google Play Store Deployment & Publishing Guide for PG info

This guide details the release specifications, generated assets, and step-by-step instructions to publish **PG info** (`com.pginfo.manage`) on the Google Play Console.

---

## 1. Release Artifacts & Credentials Summary

| Property | Value |
| :--- | :--- |
| **App Name** | `PG info` |
| **Package Name / Application ID** | `com.pginfo.manage` |
| **Version** | `1.0.0` (Version Code `1`) |
| **Production AAB Location** | `mobile/release/PGinfo_v1.0.0_release.aab` (and `mobile/build/app/outputs/bundle/release/app-release.aab`) |
| **Backend API Base URL** | `https://pginfo.space/api/v1` |
| **Signing Keystore** | `mobile/android/keystores/pginfo-upload-new.jks` |
| **Key Alias** | `upload` |
| **Key & Store Password** | `pginfo2030` |
| **Keystore Configuration** | `mobile/android/key.properties` |

> [!IMPORTANT]
> **Backup your Keystore**: Save `pginfo-upload-new.jks` and `key.properties` in a secure password manager or encrypted drive. Once uploaded to Google Play, all future app updates must be signed with this upload key (or Google Play App Signing key).

---

## 2. Store Assets Generated & Ready to Upload

All assets are located in the `mobile/ui/` directory:

1. **App Icon (512x512)**
   - Path: `mobile/ui/play_store_icon_512.png`
   - Format: 32-bit PNG with alpha, 512 × 512 px, < 1 MB.
2. **Feature Graphic (1024x500)**
   - Path: `mobile/ui/play_store_feature_graphic_1024x500.png`
   - Format: 24-bit PNG (no transparency), 1024 × 500 px.
3. **Master Logo (1024x1024)**
   - Path: `mobile/ui/logo_1024.png`
   - High-resolution transparent PNG badge.

---

## 3. Step-by-Step Google Play Console Publishing

### Step 1: Create Application on Google Play Console
1. Log in to [Google Play Console](https://play.google.com/console).
2. Click **Create app** (top-right).
3. Fill in:
   - **App name**: `PG info`
   - **Default language**: English (United States) or English (India)
   - **App or game**: App
   - **Free or paid**: Free (or Paid depending on your business model)
4. Accept the Declarations and click **Create app**.

### Step 2: Set Up Main Store Listing
Go to **Grow > Store presence > Main store listing**:
- **Short description** (up to 80 chars):
  > *Smart PG & hostel management. Track rooms, tenants, rent dues, and analytics.*
- **Full description** (up to 4000 chars):
  > *PG info is a comprehensive property and tenant management application built for PG owners, hostel managers, and coliving operators.*
  > 
  > *Key Features:*
  > - *Property & Room Configuration: Easily configure multi-sharing rooms, amenities, and bed allocations.*
  > - *Tenant Management: Seamless onboarding with digital records, contact info, and room mapping.*
  > - *Rent & Dues Tracking: Monitor monthly collections, pending balances, discounts, and payment histories.*
  > - *Financial Analytics: Real-time insights into occupancy rates, revenue, and pending dues.*
  > - *Secure Cloud Sync: High performance, encrypted cloud backup powered by https://pginfo.space.*
- **App icon**: Upload `mobile/ui/play_store_icon_512.png`.
- **Feature graphic**: Upload `mobile/ui/play_store_feature_graphic_1024x500.png`.
- **Phone screenshots**: Capture and upload 2 to 8 phone screenshots (minimum 1080p, 16:9 or 18:9 ratio) showing login, home dashboard, room view, and tenant details.

### Step 3: Complete App Content Declarations
Navigate to **Policy and programs > App content** and complete each mandatory section:
1. **Privacy Policy**: Enter the privacy policy URL (e.g. `https://pginfo.space/privacy`).
2. **App Access**: Since the app requires authentication, select *"All or some functionality is restricted"* and provide a demo login credential (e.g. email/password) so Google reviewers can log in and test.
3. **Ads**: Select *"No, my app does not contain ads"* (unless ad SDK is added).
4. **Target Audience and Content**: Select target age (e.g., 18 and above).
5. **Data Safety**:
   - Data collection: Personal info (name, email, phone) for account management.
   - Financial info: Rent and billing records.
   - Storage/Files: Profile pictures / ID documents (via camera & photo library).
   - Data encryption in transit: Yes (HTTPS / TLS 1.3).
   - Account deletion: Provide an account deletion link or mechanism.
6. **Financial Features**: Select *"Personal finance / Property management"* if prompted.
7. **Government Apps**: Select *"No"*.

### Step 4: Upload the Release Bundle
1. Go to **Release > Production** (or **Testing > Closed testing** if starting with a closed test).
2. Click **Create new release**.
3. In **App bundles**, click **Upload** and select:
   `mobile/release/PGinfo_v1.0.0_release.aab`
4. Set **Release name**: `1.0.0 (1)`.
5. Enter **Release notes**:
   ```
   Initial production release of PG info:
   - Full property and bed occupancy management
   - Tenant onboarding and payment tracking
   - Real-time financial reports and room analytics
   ```
6. Click **Save** and then **Review release**.
7. If there are any non-blocking warnings, review them and click **Start rollout to Production**.

---

## 4. Building Future Updates

To increment versions and rebuild a new `.aab`:
1. In `mobile/pubspec.yaml`, increment `version: 1.0.1+2` (or increment version code).
2. Run:
   ```cmd
   cd mobile
   flutter build appbundle --release --dart-define=API_BASE_URL=https://pginfo.space/api/v1
   ```
3. The new bundle will be at `mobile/build/app/outputs/bundle/release/app-release.aab`.
