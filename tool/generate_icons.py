"""
Generate all Android launcher icons, adaptive icon layers, web icons,
and Play Store assets from a single 1024x1024 source logo.

Usage:
    python tool/generate_icons.py <source_logo_1024.png>
"""
import sys
import os
from pathlib import Path
from PIL import Image, ImageDraw

def ensure_dir(path):
    Path(path).mkdir(parents=True, exist_ok=True)

def generate_android_icons(source: Image.Image, res_dir: str):
    """Generate standard mipmap launcher icons for all Android densities."""
    densities = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, size in densities.items():
        out_dir = os.path.join(res_dir, folder)
        ensure_dir(out_dir)
        icon = source.resize((size, size), Image.LANCZOS)
        icon.save(os.path.join(out_dir, "ic_launcher.png"), "PNG")
        print(f"  ✓ {folder}/ic_launcher.png ({size}x{size})")

def generate_adaptive_icon_layers(source: Image.Image, res_dir: str):
    """Generate foreground layer for adaptive icons (108dp with 72dp safe zone centered)."""
    densities = {
        "mipmap-mdpi": (108, 48),
        "mipmap-hdpi": (162, 72),
        "mipmap-xhdpi": (216, 96),
        "mipmap-xxhdpi": (324, 144),
        "mipmap-xxxhdpi": (432, 192),
    }
    for folder, (canvas_size, logo_size) in densities.items():
        out_dir = os.path.join(res_dir, folder)
        ensure_dir(out_dir)
        
        # Foreground: logo centered on transparent canvas
        fg = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
        logo = source.resize((logo_size, logo_size), Image.LANCZOS)
        offset = (canvas_size - logo_size) // 2
        fg.paste(logo, (offset, offset), logo if logo.mode == "RGBA" else None)
        fg.save(os.path.join(out_dir, "ic_launcher_foreground.png"), "PNG")
        print(f"  ✓ {folder}/ic_launcher_foreground.png ({canvas_size}x{canvas_size})")

def generate_round_icons(source: Image.Image, res_dir: str):
    """Generate round launcher icons."""
    densities = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, size in densities.items():
        out_dir = os.path.join(res_dir, folder)
        ensure_dir(out_dir)
        
        icon = source.resize((size, size), Image.LANCZOS).convert("RGBA")
        # Create circular mask
        mask = Image.new("L", (size, size), 0)
        draw = ImageDraw.Draw(mask)
        draw.ellipse((0, 0, size, size), fill=255)
        
        result = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        result.paste(icon, (0, 0), mask)
        result.save(os.path.join(out_dir, "ic_launcher_round.png"), "PNG")
        print(f"  ✓ {folder}/ic_launcher_round.png ({size}x{size})")

def generate_web_icons(source: Image.Image, web_dir: str):
    """Generate web favicon and PWA icons."""
    # Favicon 16x16
    favicon = source.resize((16, 16), Image.LANCZOS)
    favicon.save(os.path.join(web_dir, "favicon.png"), "PNG")
    print(f"  ✓ favicon.png (16x16)")
    
    icons_dir = os.path.join(web_dir, "icons")
    ensure_dir(icons_dir)
    
    web_sizes = {
        "Icon-192.png": 192,
        "Icon-512.png": 512,
        "Icon-maskable-192.png": 192,
        "Icon-maskable-512.png": 512,
    }
    for name, size in web_sizes.items():
        icon = source.resize((size, size), Image.LANCZOS)
        icon.save(os.path.join(icons_dir, name), "PNG")
        print(f"  ✓ icons/{name} ({size}x{size})")

def generate_play_store_icon(source: Image.Image, output_dir: str):
    """Generate 512x512 Play Store high-res icon."""
    ensure_dir(output_dir)
    icon = source.resize((512, 512), Image.LANCZOS)
    icon.save(os.path.join(output_dir, "play_store_icon_512.png"), "PNG")
    print(f"  ✓ play_store_icon_512.png (512x512)")
    
    # Also save the full 1024 for other uses
    source.save(os.path.join(output_dir, "app_icon_1024.png"), "PNG")
    print(f"  ✓ app_icon_1024.png (1024x1024)")

def generate_adaptive_icon_xml(res_dir: str):
    """Generate adaptive icon XML resources."""
    # ic_launcher.xml
    drawable_v26 = os.path.join(res_dir, "mipmap-anydpi-v26")
    ensure_dir(drawable_v26)
    
    ic_launcher_xml = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
'''
    with open(os.path.join(drawable_v26, "ic_launcher.xml"), "w") as f:
        f.write(ic_launcher_xml)
    print(f"  ✓ mipmap-anydpi-v26/ic_launcher.xml")
    
    ic_launcher_round_xml = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
'''
    with open(os.path.join(drawable_v26, "ic_launcher_round.xml"), "w") as f:
        f.write(ic_launcher_round_xml)
    print(f"  ✓ mipmap-anydpi-v26/ic_launcher_round.xml")
    
    # Background color resource
    values_dir = os.path.join(res_dir, "values")
    ensure_dir(values_dir)
    
    colors_xml_path = os.path.join(values_dir, "ic_launcher_background.xml")
    colors_xml = '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#FFFFFF</color>
</resources>
'''
    with open(colors_xml_path, "w") as f:
        f.write(colors_xml)
    print(f"  ✓ values/ic_launcher_background.xml")


def main():
    if len(sys.argv) < 2:
        print("Usage: python generate_icons.py <source_logo.png>")
        sys.exit(1)
    
    source_path = sys.argv[1]
    if not os.path.exists(source_path):
        print(f"Error: Source file not found: {source_path}")
        sys.exit(1)
    
    source = Image.open(source_path).convert("RGBA")
    if source.size != (1024, 1024):
        print(f"Warning: Source is {source.size}, resizing to 1024x1024")
        source = source.resize((1024, 1024), Image.LANCZOS)
    
    # Determine project paths
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.dirname(script_dir)
    res_dir = os.path.join(project_dir, "android", "app", "src", "main", "res")
    web_dir = os.path.join(project_dir, "web")
    ui_dir = os.path.join(project_dir, "ui")
    
    print("\n🎨 Generating Android launcher icons...")
    generate_android_icons(source, res_dir)
    
    print("\n🎨 Generating Android adaptive icon layers...")
    generate_adaptive_icon_layers(source, res_dir)
    
    print("\n🎨 Generating Android round icons...")
    generate_round_icons(source, res_dir)
    
    print("\n📋 Generating adaptive icon XML resources...")
    generate_adaptive_icon_xml(res_dir)
    
    print("\n🌐 Generating web icons...")
    generate_web_icons(source, web_dir)
    
    print("\n📱 Generating Play Store assets...")
    generate_play_store_icon(source, ui_dir)
    
    print("\n✅ All icons generated successfully!")

if __name__ == "__main__":
    main()
