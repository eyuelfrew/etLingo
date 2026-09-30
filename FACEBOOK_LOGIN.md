# Facebook Login (Firebase)

Sign-in flow: **Facebook → Firebase Auth → etLingo session JWT** (same as Google).

## 1. Facebook for Developers
1. Create an app at https://developers.facebook.com (Consumer / Login).
2. Add product **Facebook Login**.
3. Set **Valid OAuth Redirect URIs** (Firebase):
   - `https://<project-id>.firebaseapp.com/__/auth/handler`
4. Note **App ID** and **App Secret**.

## 2. Firebase console
1. Authentication → Sign-in method → **Facebook** → Enable.
2. Paste Facebook **App ID** + **App Secret**.
3. Copy the OAuth redirect URI into the Facebook app (step 1.3).
4. (Optional) Add SHA-1 / bundle id for Android/iOS as usual.

## 3. Flutter app
`flutter pub get` already includes `flutter_facebook_auth`.

### Android
- `android/app/src/main/res/values/strings.xml`:
  ```xml
  <string name="facebook_app_id">YOUR_FB_APP_ID</string>
  <string name="facebook_client_token">YOUR_CLIENT_TOKEN</string>
  ```
- `AndroidManifest.xml` inside `<application>`:
  ```xml
  <meta-data android:name="com.facebook.sdk.ApplicationId"
             android:value="@string/facebook_app_id"/>
  <meta-data android:name="com.facebook.sdk.ClientToken"
             android:value="@string/facebook_client_token"/>
  <activity android:name="com.facebook.FacebookActivity"
            android:configChanges="keyboard|keyboardHidden|screenLayout|screenSize|orientation"
            android:label="etLingo" />
  ```
- Package name must match Facebook app settings.

### iOS
- `Info.plist`:
  ```xml
  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleURLSchemes</key>
      <array><string>fbYOUR_FB_APP_ID</string></array>
    </dict>
  </array>
  <key>FacebookAppID</key><string>YOUR_FB_APP_ID</string>
  <key>FacebookClientToken</key><string>YOUR_CLIENT_TOKEN</string>
  <key>FacebookDisplayName</key><string>etLingo</string>
  <key>LSApplicationQueriesSchemes</key>
  <array><string>fbapi</string><string>fb-messenger-share-api</string></array>
  ```

## 4. Backend
Already done:
- `POST /api/v1/app/auth/facebook` `{ idToken }` → same as Google.
- `app_users.provider` includes `facebook`.

## 5. Test
1. Sign-in screen → **በ Facebook ይግቡ**.
2. First login creates a learner (`provider=facebook`).
3. Progress / likes work with the same app JWT.

## Notes
- Keep Google + Facebook side by side (don’t replace Google).
- Facebook app review may be required for advanced permissions (email is default public profile).
- Guest login stays available.
