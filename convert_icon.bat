@echo off
echo Converting app icon to different sizes...

REM Check if ImageMagick is installed
magick -version >nul 2>&1
if %errorlevel% neq 0 (
    echo ImageMagick is not installed or not in PATH
    echo Please install ImageMagick from https://imagemagick.org/script/download.php#windows
    echo Or use the online tool instructions in icon_conversion_instructions.md
    pause
    exit /b 1
)

REM Create icon sizes
echo Creating mdpi (48x48)...
magick "assets\icons\WhatsApp Image 2025-09-13 at 16.03.16_104a23fc.jpg" -resize 48x48 "android\app\src\main\res\mipmap-mdpi\ic_launcher.png"

echo Creating hdpi (72x72)...
magick "assets\icons\WhatsApp Image 2025-09-13 at 16.03.16_104a23fc.jpg" -resize 72x72 "android\app\src\main\res\mipmap-hdpi\ic_launcher.png"

echo Creating xhdpi (96x96)...
magick "assets\icons\WhatsApp Image 2025-09-13 at 16.03.16_104a23fc.jpg" -resize 96x96 "android\app\src\main\res\mipmap-xhdpi\ic_launcher.png"

echo Creating xxhdpi (144x144)...
magick "assets\icons\WhatsApp Image 2025-09-13 at 16.03.16_104a23fc.jpg" -resize 144x144 "android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png"

echo Creating xxxhdpi (192x192)...
magick "assets\icons\WhatsApp Image 2025-09-13 at 16.03.16_104a23fc.jpg" -resize 192x192 "android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png"

echo Icon conversion completed!
echo Run 'flutter clean && flutter pub get && flutter run' to see the new icon
pause