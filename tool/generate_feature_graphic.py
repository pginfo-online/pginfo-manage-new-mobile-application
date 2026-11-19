import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

def create_feature_graphic(logo_path, output_path):
    width, height = 1024, 500
    base = Image.new("RGB", (width, height), (15, 23, 42))
    draw = ImageDraw.Draw(base)

    # Smooth subtle diagonal gradient
    c1 = (12, 20, 50)      # Deep Midnight Navy
    c2 = (30, 64, 175)     # Deep Blue
    c3 = (49, 86, 245)     # Brand Blue
    
    for x in range(width):
        t = x / width
        r = int((1 - t) * c1[0] + t * c2[0])
        g = int((1 - t) * c1[1] + t * c2[1])
        b = int((1 - t) * c1[2] + t * c2[2])
        draw.line([(x, 0), (x, height)], fill=(r, g, b))

    # Glow & light overlays
    overlay = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    ov_draw = ImageDraw.Draw(overlay)
    
    # Warm orange ambient glow at bottom-right
    ov_draw.ellipse([width - 320, height - 300, width + 180, height + 200], fill=(249, 115, 22, 50))
    # Cyan/blue ambient glow at top-center
    ov_draw.ellipse([340, -180, 800, 260], fill=(59, 130, 246, 45))
    # Elegant concentric rings in background
    for radius_offset in [0, 40, 80]:
        ov_draw.ellipse([width - 360 - radius_offset, -60 - radius_offset, width + 80 + radius_offset, 380 + radius_offset], outline=(255, 255, 255, 12), width=1)

    base = Image.alpha_composite(base.convert("RGBA"), overlay)

    # Load and place Logo
    if os.path.exists(logo_path):
        logo = Image.open(logo_path).convert("RGBA")
        logo_size = 330
        logo = logo.resize((logo_size, logo_size), Image.LANCZOS)

        # Drop shadow for logo
        shadow = Image.new("RGBA", (logo_size + 60, logo_size + 60), (0, 0, 0, 0))
        sh_draw = ImageDraw.Draw(shadow)
        sh_draw.ellipse([30, 30, logo_size + 30, logo_size + 30], fill=(0, 0, 0, 140))
        shadow = shadow.filter(ImageFilter.GaussianBlur(20))

        logo_x = 75
        logo_y = (height - logo_size) // 2

        base.paste(shadow, (logo_x - 30, logo_y - 20), shadow)
        base.paste(logo, (logo_x, logo_y), logo)

    # Typography
    draw = ImageDraw.Draw(base)

    font_title = None
    font_sub = None
    font_desc = None
    font_badge = None

    for fn in ["C:\\Windows\\Fonts\\segoeuib.ttf", "C:\\Windows\\Fonts\\arialbd.ttf"]:
        if os.path.exists(fn):
            try:
                font_title = ImageFont.truetype(fn, 58)
                font_badge = ImageFont.truetype(fn, 16)
                break
            except Exception:
                pass

    for fn in ["C:\\Windows\\Fonts\\segoeui.ttf", "C:\\Windows\\Fonts\\arial.ttf"]:
        if os.path.exists(fn):
            try:
                font_sub = ImageFont.truetype(fn, 25)
                font_desc = ImageFont.truetype(fn, 17)
                break
            except Exception:
                pass

    if not font_title:
        font_title = ImageFont.load_default()
    if not font_sub:
        font_sub = ImageFont.load_default()
    if not font_desc:
        font_desc = ImageFont.load_default()
    if not font_badge:
        font_badge = ImageFont.load_default()

    text_x = 445
    # App Title
    draw.text((text_x, 105), "PG info", font=font_title, fill=(255, 255, 255, 255))
    
    # Subtitle
    draw.text((text_x, 180), "Smart PG & Hostel Management", font=font_sub, fill=(249, 115, 22, 255))
    
    # Description
    draw.text((text_x, 222), "Streamline properties, rooms, tenants, and collections.", font=font_desc, fill=(219, 234, 254, 220))

    # Feature badges with colored icon accents
    badges = [
        ("Properties & Rooms", (59, 130, 246)),
        ("Tenant Management", (16, 185, 129)),
        ("Rent & Dues Tracking", (249, 115, 22)),
        ("Financial Analytics", (168, 85, 247))
    ]
    
    badge_y = 285
    pill_w = 250
    pill_h = 44
    for i, (text, dot_color) in enumerate(badges):
        bx = text_x + (i % 2) * (pill_w + 16)
        by = badge_y + (i // 2) * (pill_h + 16)
        
        # Draw translucent pill
        pill = Image.new("RGBA", (pill_w, pill_h), (255, 255, 255, 22))
        base.paste(pill, (bx, by), pill)
        draw.rounded_rectangle([bx, by, bx + pill_w, by + pill_h], radius=10, outline=(255, 255, 255, 55), width=1)
        
        # Color dot indicator
        dot_radius = 4
        dot_cy = by + pill_h // 2
        dot_cx = bx + 22
        draw.ellipse([dot_cx - dot_radius, dot_cy - dot_radius, dot_cx + dot_radius, dot_cy + dot_radius], fill=dot_color)
        
        draw.text((bx + 36, by + 13), text, font=font_badge, fill=(255, 255, 255, 245))

    # Save as 24-bit RGB PNG (Play Store requirement: no transparency)
    final_img = base.convert("RGB")
    final_img.save(output_path, "PNG", quality=95)
    print(f"Created Play Store feature graphic: {output_path} ({width}x{height})")

if __name__ == "__main__":
    src_logo = r"c:\Users\ADMIN\Desktop\2030\PgInfoManage\mobile\ui\logo_1024.png"
    out_graphic = r"c:\Users\ADMIN\Desktop\2030\PgInfoManage\mobile\ui\play_store_feature_graphic_1024x500.png"
    create_feature_graphic(src_logo, out_graphic)
