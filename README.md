# Flutter Fillarit sample

Show citybike stations on the map with Flutter

Don't forget to provide Google Maps API key.

At `ios/Runner/AppDelegate.m`
```
[GMSServices provideAPIKey:@"YOUR KEY HERE"];
```

At `android/app/src/main/AndroidManifest.xml`
```
<meta-data android:name="com.google.android.geo.API_KEY"
           android:value="YOUR_GOOGLE_MAPS_KEY_HERE"/>
```
