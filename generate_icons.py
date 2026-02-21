import os
import json
from PIL import Image, ImageDraw, ImageFont

# Configuration
SOURCE_ICON = "ios/Evasion/Images.xcassets/AppIcon.appiconset/Icon-iOS-Default-1024x1024@1x.png"
OUTPUT_DIR = "ios/Evasion/Images.xcassets/AppIcon.appiconset"
ASSETS_DIR = "assets"

# Standard iOS Icon Sizes
ICON_SIZES = [
    (20, 1, "-20x20@1x"), (20, 2, "-20x20@2x"), (20, 3, "-20x20@3x"),
    (29, 1, "-29x29@1x"), (29, 2, "-29x29@2x"), (29, 3, "-29x29@3x"),
    (40, 1, "-40x40@1x"), (40, 2, "-40x40@2x"), (40, 3, "-40x40@3x"),
    (60, 2, "-60x60@2x"), (60, 3, "-60x60@3x"),
    (76, 1, "-76x76@1x"), (76, 2, "-76x76@2x"),
    (83.5, 2, "-83.5x83.5@2x"),
    (1024, 1, "-1024x1024@1x")
]

def add_corners(im, rad):
    circle = Image.new('L', (rad * 2, rad * 2), 0)
    draw = ImageDraw.Draw(circle)
    draw.ellipse((0, 0, rad * 2 - 1, rad * 2 - 1), fill=255)
    alpha = Image.new('L', im.size, 255)
    w, h = im.size
    alpha.paste(circle.crop((0, 0, rad, rad)), (0, 0))
    alpha.paste(circle.crop((0, rad, rad, rad * 2)), (0, h - rad))
    alpha.paste(circle.crop((rad, 0, rad * 2, rad)), (w - rad, 0))
    alpha.paste(circle.crop((rad, rad, rad * 2, rad * 2)), (w - rad, h - rad))
    im_copy = im.copy()
    im_copy.putalpha(alpha)
    return im_copy

def generate_icons():
    if not os.path.exists(SOURCE_ICON):
        print(f"Error: Source icon not found at {SOURCE_ICON}")
        return

    try:
        img = Image.open(SOURCE_ICON)
        # Force convert RGBA to RGB using a dark background if alpha exists
        if img.mode in ('RGBA', 'LA') or (img.mode == 'P' and 'transparency' in img.info):
            background = Image.new('RGB', img.size, (18, 18, 18))
            img = img.convert("RGBA")
            background.paste(img, mask=img.split()[3])
            img_no_alpha = background
        else:
            img_no_alpha = img.convert('RGB')
    except Exception as e:
        print(f"Error opening source image: {e}")
        return

    # 1. Generate AppIcon.appiconset
    final_images = []
    
    # iPhone
    for s, sc in [(20, 2), (20, 3), (29, 2), (29, 3), (40, 2), (40, 3), (60, 2), (60, 3)]:
        filename = f"Icon-App-{s}x{s}@{sc}x.png"
        sz = int(s * sc)
        resized = img_no_alpha.resize((sz, sz), Image.Resampling.LANCZOS)
        resized.save(os.path.join(OUTPUT_DIR, filename))
        final_images.append({
            "size": f"{s}x{s}", "idiom": "iphone",
            "filename": filename, "scale": f"{sc}x"
        })
    
    # iPad
    for s, sc in [(20, 1), (20, 2), (29, 1), (29, 2), (40, 1), (40, 2), (76, 1), (76, 2), (83.5, 2)]:
        str_size = "83.5x83.5" if s == 83.5 else f"{s}x{s}"
        filename = f"Icon-App-{str_size}@{sc}x.png"
        sz = int(s * sc)
        resized = img_no_alpha.resize((sz, sz), Image.Resampling.LANCZOS)
        resized.save(os.path.join(OUTPUT_DIR, filename))
        final_images.append({
            "size": str_size, "idiom": "ipad",
            "filename": filename, "scale": f"{sc}x"
        })
        
    # App Store
    store_file = "Icon-App-1024x1024@1x.png"
    img_no_alpha.resize((1024, 1024), Image.Resampling.LANCZOS).save(os.path.join(OUTPUT_DIR, store_file))
    final_images.append({
        "size": "1024x1024", "idiom": "ios-marketing",
        "filename": store_file, "scale": "1x"
    })

    with open(os.path.join(OUTPUT_DIR, "Contents.json"), "w") as f:
        json.dump({"images": final_images, "info": {"version": 1, "author": "xcode"}}, f, indent=2)
    print("Updated AppIcon Contents.json")

    # 2. Update assets/icon.png
    os.makedirs(ASSETS_DIR, exist_ok=True)
    img_no_alpha.resize((1024, 1024), Image.Resampling.LANCZOS).save(os.path.join(ASSETS_DIR, "icon.png"))
    print("Updated assets/icon.png")

    # 3. Generate assets/splash-icon.png
    print("Generating splash screen...")
    # Create canvas 1200x1200, transparent
    splash = Image.new('RGBA', (1200, 1200), (0, 0, 0, 0))
    
    # Icon with rounded corners, size 400x400
    icon_rounded = add_corners(img_no_alpha.resize((400, 400), Image.Resampling.LANCZOS), rad=90)
    splash.paste(icon_rounded, (400, 300), icon_rounded)

    draw = ImageDraw.Draw(splash)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 80)
    except IOError:
        font = ImageFont.load_default()

    text = "EVASION"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_w = bbox[2] - bbox[0]
    draw.text((600 - text_w // 2, 750), text, font=font, fill=(255, 255, 255, 255))
    
    splash.save(os.path.join(ASSETS_DIR, "splash-icon.png"))
    print("Updated assets/splash-icon.png")

if __name__ == "__main__":
    generate_icons()
