# App Icon Conversion Instructions

## Current Image
- Source: `assets/icons/WhatsApp Image 2025-09-13 at 16.03.16_104a23fc.jpg`

## Required Android Icon Sizes
You need to convert your image to PNG format and create the following sizes:

### Android Drawable Folders
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` - 48x48 px
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` - 72x72 px  
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` - 96x96 px
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` - 144x144 px
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` - 192x192 px

## Steps to Convert:

### Option 1: Online Tool
1. Go to https://appicon.co/ or https://icon.kitchen/
2. Upload your `WhatsApp Image 2025-09-13 at 16.03.16_104a23fc.jpg`
3. Download the Android icon pack
4. Replace the existing `ic_launcher.png` files in each mipmap folder

### Option 2: Manual Conversion
1. Open your image in any image editor (GIMP, Photoshop, Paint.NET, etc.)
2. Resize to each required size
3. Save as PNG format
4. Replace the files in the respective folders

### Option 3: Using ImageMagick (if installed)
```bash
# Install ImageMagick first, then run:
magick "assets/icons/WhatsApp Image 2025-09-13 at 16.03.16_104a23fc.jpg" -resize 48x48 android/app/src/main/res/mipmap-mdpi/ic_launcher.png
magick "assets/icons/WhatsApp Image 2025-09-13 at 16.03.16_104a23fc.jpg" -resize 72x72 android/app/src/main/res/mipmap-hdpi/ic_launcher.png
magick "assets/icons/WhatsApp Image 2025-09-13 at 16.03.16_104a23fc.jpg" -resize 96x96 android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
magick "assets/icons/WhatsApp Image 2025-09-13 at 16.03.16_104a23fc.jpg" -resize 144x144 android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
magick "assets/icons/WhatsApp Image 2025-09-13 at 16.03.16_104a23fc.jpg" -resize 192x192 android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
```

## After Conversion
1. Clean and rebuild the app:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. Your new icon will appear on the app launcher!

## Note
The app name is already set to "MedVita" in the AndroidManifest.xml file, so your new icon will show with the correct app name.