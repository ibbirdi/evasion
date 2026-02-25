from PIL import Image

def analyze_image(path):
    print(f"Analyzing {path}")
    img = Image.open(path).convert('RGBA')
    width, height = img.size
    print(f"Size: {width}x{height}")
    
    # Assume background is #121212 or transparent
    # Let's find where the non-background pixels are
    # Sum across rows to find horizontal bands of content
    
    pixels = img.load()
    bg_color = pixels[0, 0]
    print(f"Top-left corner color: {bg_color}")
    
    # Check rows
    y_bands = []
    in_band = False
    start_y = 0
    
    for y in range(height):
        is_empty_row = True
        for x in range(width):
            p = pixels[x, y]
            # check if different from background
            # we support transparent background or solid
            if p[3] > 0: # not fully transparent
                if p[:3] != bg_color[:3] and p[:3] != (18, 18, 18): # neither top-left nor #121212
                    is_empty_row = False
                    break
                    
        if not is_empty_row and not in_band:
            in_band = True
            start_y = y
        elif is_empty_row and in_band:
            in_band = False
            y_bands.append((start_y, y))
            
    if in_band:
        y_bands.append((start_y, height))
        
    print(f"Content vertical bands: {y_bands}")

analyze_image('assets/splash-icon.png')
