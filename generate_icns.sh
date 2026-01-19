#!/bin/bash
set -e

SOURCE_SVG="beacon_dns.svg"
ICONSET_DIR="BeaconDNS.iconset"
OUTPUT_ICNS="AppIcon.icns"

if [ ! -f "$SOURCE_SVG" ]; then
    echo "Error: $SOURCE_SVG not found!"
    exit 1
fi

echo "🎨 Generatings icons from $SOURCE_SVG..."
mkdir -p "$ICONSET_DIR"

# Generate PNGs at required sizes using rsvg-convert
rsvg-convert "$SOURCE_SVG" --width 16 --height 16 --background-color=transparent > "$ICONSET_DIR/icon_16x16.png"
rsvg-convert "$SOURCE_SVG" --width 32 --height 32 --background-color=transparent > "$ICONSET_DIR/icon_16x16@2x.png"
rsvg-convert "$SOURCE_SVG" --width 32 --height 32 --background-color=transparent > "$ICONSET_DIR/icon_32x32.png"
rsvg-convert "$SOURCE_SVG" --width 64 --height 64 --background-color=transparent > "$ICONSET_DIR/icon_32x32@2x.png"
rsvg-convert "$SOURCE_SVG" --width 128 --height 128 --background-color=transparent > "$ICONSET_DIR/icon_128x128.png"
rsvg-convert "$SOURCE_SVG" --width 256 --height 256 --background-color=transparent > "$ICONSET_DIR/icon_128x128@2x.png"
rsvg-convert "$SOURCE_SVG" --width 256 --height 256 --background-color=transparent > "$ICONSET_DIR/icon_256x256.png"
rsvg-convert "$SOURCE_SVG" --width 512 --height 512 --background-color=transparent > "$ICONSET_DIR/icon_256x256@2x.png"
rsvg-convert "$SOURCE_SVG" --width 512 --height 512 --background-color=transparent > "$ICONSET_DIR/icon_512x512.png"
rsvg-convert "$SOURCE_SVG" --width 1024 --height 1024 --background-color=transparent > "$ICONSET_DIR/icon_512x512@2x.png"

echo "🔨 Compiling .icns file..."
iconutil -c icns "$ICONSET_DIR" -o "$OUTPUT_ICNS"

# Cleanup
rm -rf "$ICONSET_DIR"

echo "✅ Generated $OUTPUT_ICNS"
