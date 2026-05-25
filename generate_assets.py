import os
import zlib
import struct

# Pure Python PNG Writer
def write_png(filename, width, height, pixels):
    """
    pixels is a list of rows, where each row is a list of (r, g, b, a) tuples.
    """
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    
    # Compress data using filter type 0 (None) for each scanline
    raw_data = bytearray()
    for y in range(height):
        raw_data.append(0) # Filter type 0
        for x in range(width):
            r, g, b, a = pixels[y][x]
            raw_data.extend([r, g, b, a])
            
    idat = zlib.compress(raw_data)
    
    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data))
        
    png_data = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", idat) + chunk(b"IEND", b"")
    
    # Ensure directory exists
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with open(filename, "wb") as f:
        f.write(png_data)

def hex_to_rgba(hex_str):
    hex_str = hex_str.lstrip("#")
    if len(hex_str) == 6:
        return struct.unpack('BBB', bytes.fromhex(hex_str)) + (255,)
    elif len(hex_str) == 8:
        return struct.unpack('BBBB', bytes.fromhex(hex_str))
    return (0, 0, 0, 0)

# Pixel art helpers
def create_grid(w, h, fill_color_hex="#00000000"):
    fill_color = hex_to_rgba(fill_color_hex)
    return [[fill_color for _ in range(w)] for _ in range(h)]

def draw_rect(pixels, x, y, w, h, color_hex):
    color = hex_to_rgba(color_hex)
    for cy in range(max(0, y), min(len(pixels), y + h)):
        for cx in range(max(0, x), min(len(pixels[0]), x + w)):
            pixels[cy][cx] = color

def draw_outline(pixels, x, y, w, h, color_hex):
    color = hex_to_rgba(color_hex)
    # top/bottom
    for cx in range(max(0, x), min(len(pixels[0]), x + w)):
        if 0 <= y < len(pixels): pixels[y][cx] = color
        if 0 <= y + h - 1 < len(pixels): pixels[y + h - 1][cx] = color
    # left/right
    for cy in range(max(0, y), min(len(pixels), y + h)):
        if 0 <= x < len(pixels[0]): pixels[cy][x] = color
        if 0 <= x + w - 1 < len(pixels[0]): pixels[cy][x + w - 1] = color

def draw_pixel(pixels, x, y, color_hex):
    if 0 <= y < len(pixels) and 0 <= x < len(pixels[0]):
        pixels[y][x] = hex_to_rgba(color_hex)

# --- Asset Generation Functions ---

def generate_tilesheet():
    # 128x128 grid (8x8 tiles of 16x16 each)
    pixels = create_grid(128, 128, "#A2D149") # Fill with base grass
    
    # Palette definition
    c_grass = "#A2D149"
    c_grass_dark = "#91C13B"
    c_grass_light = "#B2DF5A"
    c_soil_dry = "#966A38"
    c_soil_dry_border = "#7E5325"
    c_soil_wet = "#5E3A15"
    c_soil_wet_border = "#3D250D"
    c_path = "#E8D5B5"
    c_path_border = "#D3BA94"
    c_water = "#79C1D9"
    c_water_dark = "#5BA6BF"
    c_water_light = "#98DBED"
    c_wood = "#D6A363"
    c_wood_dark = "#A77A44"
    c_wall = "#FFF0D9"
    c_wall_border = "#DFD1BB"
    c_roof = "#4F596D"
    c_roof_dark = "#3A4252"
    c_fence = "#D29E65"
    c_fence_dark = "#A57342"
    c_lantern_stone = "#545E66"
    c_lantern_glow = "#FFEA73"
    c_bamboo = "#77B73F"
    c_sakura_leaves = "#FFB3C6"
    c_sakura_dark = "#FFA0B5"
    c_sakura_light = "#FFD3DE"
    c_trunk = "#704A3C"

    # Tile 0,0: Grass Base (already done, add details)
    # Add dark grass speckles
    for tx in [0, 1]:
        ox, oy = tx * 16, 0
        # Draw base
        draw_rect(pixels, ox, oy, 16, 16, c_grass)
        # Speckles
        speckles = [(2,3), (6,7), (12,2), (9,11), (3,13), (14,12)]
        for sx, sy in speckles:
            draw_pixel(pixels, ox + sx, oy + sy, c_grass_dark)
        for sx, sy in [(4,2), (10,5), (5,12), (11,10)]:
            draw_pixel(pixels, ox + sx, oy + sy, c_grass_light)
            
    # Tile 1,0 (Alternate Grass with little flower)
    draw_pixel(pixels, 22, 5, "#FFFFFF")
    draw_pixel(pixels, 23, 6, "#FFFFFF")
    draw_pixel(pixels, 21, 6, "#FFFFFF")
    draw_pixel(pixels, 22, 7, "#FFFFFF")
    draw_pixel(pixels, 22, 6, "#FFEA73") # yellow center

    # Tile 2,0: Dry Soil
    ox, oy = 32, 0
    draw_rect(pixels, ox, oy, 16, 16, c_soil_dry)
    draw_outline(pixels, ox, oy, 16, 16, c_soil_dry_border)
    # Clod details
    draw_pixel(pixels, ox + 3, oy + 4, c_soil_dry_border)
    draw_pixel(pixels, ox + 11, oy + 7, c_soil_dry_border)
    draw_pixel(pixels, ox + 6, oy + 12, c_soil_dry_border)

    # Tile 3,0: Watered Soil
    ox, oy = 48, 0
    draw_rect(pixels, ox, oy, 16, 16, c_soil_wet)
    draw_outline(pixels, ox, oy, 16, 16, c_soil_wet_border)
    draw_pixel(pixels, ox + 3, oy + 4, c_soil_wet_border)
    draw_pixel(pixels, ox + 11, oy + 7, c_soil_wet_border)
    draw_pixel(pixels, ox + 6, oy + 12, c_soil_wet_border)

    # Tile 4,0: Path
    ox, oy = 64, 0
    draw_rect(pixels, ox, oy, 16, 16, c_path)
    # Path stones
    draw_rect(pixels, ox + 2, oy + 2, 4, 3, c_path_border)
    draw_rect(pixels, ox + 9, oy + 4, 5, 4, c_path_border)
    draw_rect(pixels, ox + 3, oy + 10, 6, 3, c_path_border)
    draw_rect(pixels, ox + 11, oy + 11, 3, 3, c_path_border)

    # Tile 5,0: Water
    ox, oy = 80, 0
    draw_rect(pixels, ox, oy, 16, 16, c_water)
    # Waves
    draw_line_horizontal(pixels, ox + 2, oy + 3, 5, c_water_light)
    draw_line_horizontal(pixels, ox + 3, oy + 4, 3, c_water_dark)
    draw_line_horizontal(pixels, ox + 9, oy + 9, 5, c_water_light)
    draw_line_horizontal(pixels, ox + 10, oy + 10, 3, c_water_dark)
    draw_line_horizontal(pixels, ox + 1, oy + 12, 4, c_water_light)

    # Tile 6,0: Deep Water
    ox, oy = 96, 0
    draw_rect(pixels, ox, oy, 16, 16, c_water_dark)
    draw_line_horizontal(pixels, ox + 4, oy + 5, 4, c_water)
    draw_line_horizontal(pixels, ox + 10, oy + 12, 4, c_water)

    # Tile 7,0: Shore / Beach Sand
    ox, oy = 112, 0
    draw_rect(pixels, ox, oy, 16, 16, c_path)
    draw_rect(pixels, ox + 8, oy, 8, 16, c_water)
    draw_line_vertical(pixels, ox + 7, oy, 16, c_path_border)
    draw_pixel(pixels, ox + 7, oy + 3, c_water_light)
    draw_pixel(pixels, ox + 7, oy + 11, c_water_light)

    # --- Row 1 (y=16..31) ---
    
    # Tile 0,1: Wood Floor
    ox, oy = 0, 16
    draw_rect(pixels, ox, oy, 16, 16, c_wood)
    draw_line_horizontal(pixels, ox, oy, 16, c_wood_dark)
    draw_line_horizontal(pixels, ox, oy + 8, 16, c_wood_dark)
    draw_line_horizontal(pixels, ox, oy + 15, 16, c_wood_dark)
    draw_line_vertical(pixels, ox + 5, oy, 8, c_wood_dark)
    draw_line_vertical(pixels, ox + 11, oy + 8, 8, c_wood_dark)

    # Tile 1,1: Wall
    ox, oy = 16, 16
    draw_rect(pixels, ox, oy, 16, 16, c_wall)
    draw_rect(pixels, ox, oy, 16, 3, c_wood_dark) # top trim
    draw_rect(pixels, ox, oy + 13, 16, 3, c_wood_dark) # baseboard
    draw_rect(pixels, ox + 2, oy + 3, 2, 10, c_wood_dark) # vertical beam
    draw_rect(pixels, ox + 12, oy + 3, 2, 10, c_wood_dark) # vertical beam

    # Tile 2,1: Roof
    ox, oy = 32, 16
    draw_rect(pixels, ox, oy, 16, 16, c_roof)
    # Shingles pattern
    for ry in [0, 4, 8, 12]:
        draw_line_horizontal(pixels, ox, oy + ry, 16, c_roof_dark)
        for rx in range(0, 16, 4):
            offset = 2 if ry % 8 == 0 else 0
            draw_pixel(pixels, ox + rx + offset, oy + ry + 1, c_roof_dark)
            draw_pixel(pixels, ox + rx + offset, oy + ry + 2, c_roof_dark)

    # Tile 3,1: Fence
    ox, oy = 48, 16
    # Empty background (grass)
    draw_rect(pixels, ox, oy, 16, 16, "#00000000")
    # Draw horizontal rails
    draw_rect(pixels, ox, oy + 4, 16, 2, c_fence)
    draw_rect(pixels, ox, oy + 10, 16, 2, c_fence)
    # Draw vertical posts
    draw_rect(pixels, ox + 2, oy, 3, 16, c_fence_dark)
    draw_rect(pixels, ox + 11, oy, 3, 16, c_fence_dark)
    # Post tops (pointy)
    draw_pixel(pixels, ox + 3, oy, c_fence)
    draw_pixel(pixels, ox + 12, oy, c_fence)

    # Tile 4,1: Stone Lantern OFF
    ox, oy = 64, 16
    draw_rect(pixels, ox, oy, 16, 16, "#00000000")
    # Base
    draw_rect(pixels, ox + 5, oy + 13, 6, 3, c_lantern_stone)
    # Pillar
    draw_rect(pixels, ox + 6, oy + 8, 4, 5, c_lantern_stone)
    # Center box
    draw_rect(pixels, ox + 4, oy + 3, 8, 5, c_lantern_stone)
    draw_rect(pixels, ox + 6, oy + 4, 4, 3, "#444444") # Dark inside
    # Roof/Hat
    draw_rect(pixels, ox + 2, oy + 1, 12, 2, c_lantern_stone)
    draw_rect(pixels, ox + 5, oy, 6, 1, c_lantern_stone)

    # Tile 5,1: Stone Lantern ON
    ox, oy = 80, 16
    draw_rect(pixels, ox, oy, 16, 16, "#00000000")
    # Base
    draw_rect(pixels, ox + 5, oy + 13, 6, 3, c_lantern_stone)
    # Pillar
    draw_rect(pixels, ox + 6, oy + 8, 4, 5, c_lantern_stone)
    # Center box
    draw_rect(pixels, ox + 4, oy + 3, 8, 5, c_lantern_stone)
    draw_rect(pixels, ox + 6, oy + 4, 4, 3, c_lantern_glow) # Glowing inside!
    draw_pixel(pixels, ox + 7, oy + 5, "#FFFFFF") # bright hot spot
    # Roof/Hat
    draw_rect(pixels, ox + 2, oy + 1, 12, 2, c_lantern_stone)
    draw_rect(pixels, ox + 5, oy, 6, 1, c_lantern_stone)

    # Tile 6,1: Shop Table Counter
    ox, oy = 96, 16
    draw_rect(pixels, ox, oy, 16, 16, "#00000000")
    # Countertop
    draw_rect(pixels, ox, oy + 4, 16, 3, c_wood)
    draw_rect(pixels, ox, oy + 3, 16, 1, "#ECC18C") # Highlight top edge
    # Cabinet base
    draw_rect(pixels, ox + 1, oy + 7, 14, 9, c_wood_dark)
    draw_line_vertical(pixels, ox + 8, oy + 7, 9, "#775025") # door slit
    # Knobs
    draw_pixel(pixels, ox + 6, oy + 11, "#FFEAA0")
    draw_pixel(pixels, ox + 10, oy + 11, "#FFEAA0")

    # Tile 7,1: Shop Canopy / Roof
    ox, oy = 112, 16
    draw_rect(pixels, ox, oy, 16, 16, "#00000000")
    # Stripes red & white
    for rx in range(16):
        col = "#E85151" if (rx // 4) % 2 == 0 else "#FFF"
        draw_line_vertical(pixels, ox + rx, oy, 13, col)
    # Canopy bottom scallop
    draw_rect(pixels, ox, oy + 13, 16, 2, c_wood_dark)
    for rx in range(0, 16, 4):
        draw_pixel(pixels, ox + rx + 1, oy + 15, c_wood_dark)
        draw_pixel(pixels, ox + rx + 2, oy + 15, c_wood_dark)

    # --- Row 2 (y=32..47) ---
    
    # Tile 0,2: Tree Trunk
    ox, oy = 0, 32
    draw_rect(pixels, ox, oy, 16, 16, "#00000000")
    draw_rect(pixels, ox + 6, oy, 4, 16, c_trunk)
    draw_line_vertical(pixels, ox + 5, oy + 8, 8, c_trunk) # Roots branching
    draw_line_vertical(pixels, ox + 10, oy + 10, 6, c_trunk)
    draw_pixel(pixels, ox + 7, oy + 3, "#5E3E32") # dark bark lines
    draw_pixel(pixels, ox + 8, oy + 9, "#5E3E32")

    # Tile 1,2: Green Tree Leaves
    ox, oy = 16, 32
    draw_rect(pixels, ox, oy, 16, 16, "#00000000")
    # Large green circle / puff
    draw_circle_filled(pixels, ox + 8, oy + 8, 7, "#65A03A")
    draw_circle_filled(pixels, ox + 6, oy + 6, 5, "#7CB94F") # Highlight top-left
    draw_circle_filled(pixels, ox + 10, oy + 10, 4, "#4C7F27") # Shadow bottom-right

    # Tile 2,2: Sakura Leaves
    ox, oy = 32, 32
    draw_rect(pixels, ox, oy, 16, 16, "#00000000")
    # Pink Sakura puff
    draw_circle_filled(pixels, ox + 8, oy + 8, 7, c_sakura_leaves)
    draw_circle_filled(pixels, ox + 6, oy + 6, 5, c_sakura_light)
    draw_circle_filled(pixels, ox + 10, oy + 10, 4, c_sakura_dark)
    # Add small petal speckles
    draw_pixel(pixels, ox + 3, oy + 11, "#FFFFFF")
    draw_pixel(pixels, ox + 13, oy + 4, "#FFFFFF")

    # Tile 3,2: Bamboo Stalk
    ox, oy = 48, 32
    draw_rect(pixels, ox, oy, 16, 16, "#00000000")
    # Stalk
    draw_rect(pixels, ox + 7, oy, 2, 16, c_bamboo)
    # Ring joints
    for ry in [4, 10]:
        draw_line_horizontal(pixels, ox + 6, oy + ry, 4, "#5F942C")
    # Small side leaves
    draw_pixel(pixels, ox + 5, oy + 2, c_bamboo)
    draw_pixel(pixels, ox + 4, oy + 1, c_bamboo)
    draw_pixel(pixels, ox + 10, oy + 8, c_bamboo)
    draw_pixel(pixels, ox + 11, oy + 7, c_bamboo)

    # Tile 4,2: Bed Pillow & Blanket
    ox, oy = 64, 32
    draw_rect(pixels, ox, oy, 16, 16, c_wood)
    # Red futon mattress
    draw_rect(pixels, ox + 2, oy + 2, 12, 14, "#DE5858")
    # White folded pillow
    draw_rect(pixels, ox + 3, oy + 3, 10, 4, "#FFFFFF")
    draw_outline(pixels, ox + 3, oy + 3, 10, 4, "#D3D3D3")
    # Blanket folded edge
    draw_line_horizontal(pixels, ox + 2, oy + 9, 12, "#B34242")

    # Tile 5,2: Bed wood frame (foot part)
    ox, oy = 80, 32
    draw_rect(pixels, ox, oy, 16, 16, c_wood)
    # Futon extension
    draw_rect(pixels, ox + 2, oy, 12, 14, "#DE5858")
    draw_rect(pixels, ox + 2, oy + 10, 12, 4, "#C64646") # bottom shadow
    # Wood frame edge
    draw_rect(pixels, ox, oy + 14, 16, 2, c_wood_dark)

    # Tile 6,2: Tatami Mat / Rug
    ox, oy = 96, 32
    draw_rect(pixels, ox, oy, 16, 16, "#E1D0AC")
    draw_outline(pixels, ox, oy, 16, 16, "#40301B") # Dark borders
    # Tatami weave lines
    for ry in range(2, 15, 3):
        draw_line_horizontal(pixels, ox + 2, oy + ry, 12, "#CCA875")

    write_png("assets/tilesheet.png", 128, 128, pixels)
    print("Generated: assets/tilesheet.png")

def generate_characters():
    # 128 width, 96 height (character frames of 16x24)
    # Col 0, 1, 2: Player walk cycles. Col 3: NPC Sora.
    pixels = create_grid(128, 96, "#00000000")
    
    # Palette
    c_skin = "#FFE2CC"
    c_hair = "#2B1E19"
    c_hat = "#DEBF81"
    c_hat_shadow = "#B8995E"
    c_clothes = "#3D628A"
    c_clothes_light = "#557FA8"
    c_boots = "#2A2A2D"
    
    # NPC Sora Palette
    c_npc_hair = "#1F1A24"
    c_npc_kimono = "#A478C4"
    c_npc_obi = "#EAEAEA"
    c_npc_obi_red = "#D64545"

    def draw_chibi_player(ox, oy, direction, step):
        # 16x24 area
        # Straw hat (Top y=0..5)
        # Head (y=4..11)
        # Body (y=12..19)
        # Feet (y=20..23)
        
        # Head base
        draw_rect(pixels, ox + 4, oy + 5, 8, 7, c_skin)
        
        # Hat brim (horizontal slice)
        draw_rect(pixels, ox + 1, oy + 4, 14, 2, c_hat)
        draw_rect(pixels, ox + 3, oy + 2, 10, 2, c_hat)
        draw_rect(pixels, ox + 5, oy + 1, 6, 1, c_hat)
        # Hat shadow/band
        draw_line_horizontal(pixels, ox + 3, oy + 4, 10, c_hat_shadow)
        
        # Hair & face details depending on direction
        if direction == "DOWN":
            # Hair on sides
            draw_rect(pixels, ox + 3, oy + 7, 2, 5, c_hair)
            draw_rect(pixels, ox + 11, oy + 7, 2, 5, c_hair)
            # Bangs
            draw_rect(pixels, ox + 4, oy + 5, 8, 2, c_hair)
            # Eyes
            draw_pixel(pixels, ox + 5, oy + 8, "#2F231D")
            draw_pixel(pixels, ox + 10, oy + 8, "#2F231D")
            # Rosy cheeks
            draw_pixel(pixels, ox + 4, oy + 9, "#FFA0B3")
            draw_pixel(pixels, ox + 11, oy + 9, "#FFA0B3")
            
            # Body/Overalls
            draw_rect(pixels, ox + 4, oy + 12, 8, 8, c_clothes)
            draw_rect(pixels, ox + 5, oy + 12, 6, 4, c_clothes_light) # bib
            # Straps
            draw_pixel(pixels, ox + 4, oy + 12, "#E86464") # Red undershirt straps
            draw_pixel(pixels, ox + 11, oy + 12, "#E86464")
            # Arms
            draw_rect(pixels, ox + 2, oy + 13, 2, 5, "#E86464") # sleeves
            draw_rect(pixels, ox + 12, oy + 13, 2, 5, "#E86464")
            draw_rect(pixels, ox + 2, oy + 17, 2, 2, c_skin) # hands
            draw_rect(pixels, ox + 12, oy + 17, 2, 2, c_skin)
            
        elif direction == "UP":
            # Full hair back
            draw_rect(pixels, ox + 3, oy + 5, 10, 8, c_hair)
            # Body back
            draw_rect(pixels, ox + 4, oy + 12, 8, 8, c_clothes)
            # Arms
            draw_rect(pixels, ox + 2, oy + 13, 2, 5, c_clothes)
            draw_rect(pixels, ox + 12, oy + 13, 2, 5, c_clothes)
            
        elif direction == "LEFT":
            # Hair back/front
            draw_rect(pixels, ox + 7, oy + 5, 6, 7, c_hair) # hair back
            draw_rect(pixels, ox + 5, oy + 5, 2, 2, c_hair) # bangs side
            draw_pixel(pixels, ox + 5, oy + 8, "#2F231D") # eye
            draw_pixel(pixels, ox + 4, oy + 9, "#FFA0B3") # cheek
            
            # Body profile
            draw_rect(pixels, ox + 5, oy + 12, 7, 8, c_clothes)
            # Arms moving/idle
            draw_rect(pixels, ox + 7, oy + 13, 3, 5, "#E86464")
            draw_rect(pixels, ox + 7, oy + 17, 2, 2, c_skin)
            
        elif direction == "RIGHT":
            # Hair back/front
            draw_rect(pixels, ox + 3, oy + 5, 6, 7, c_hair)
            draw_rect(pixels, ox + 9, oy + 5, 2, 2, c_hair)
            draw_pixel(pixels, ox + 10, oy + 8, "#2F231D")
            draw_pixel(pixels, ox + 11, oy + 9, "#FFA0B3")
            
            # Body profile
            draw_rect(pixels, ox + 4, oy + 12, 7, 8, c_clothes)
            # Arms
            draw_rect(pixels, ox + 6, oy + 13, 3, 5, "#E86464")
            draw_rect(pixels, ox + 7, oy + 17, 2, 2, c_skin)

        # Feet / Legs animation based on step
        if step == 0: # Idle
            draw_rect(pixels, ox + 4, oy + 20, 3, 3, c_boots)
            draw_rect(pixels, ox + 9, oy + 20, 3, 3, c_boots)
        elif step == 1: # Left foot up
            draw_rect(pixels, ox + 4, oy + 19, 3, 3, c_boots) # raised
            draw_rect(pixels, ox + 9, oy + 20, 3, 4, c_boots) # down
        elif step == 2: # Right foot up
            draw_rect(pixels, ox + 4, oy + 20, 3, 4, c_boots) # down
            draw_rect(pixels, ox + 9, oy + 19, 3, 3, c_boots) # raised

    # Draw player grid
    # Row 0: Down (y=0..23)
    draw_chibi_player(0, 0, "DOWN", 0)
    draw_chibi_player(16, 0, "DOWN", 1)
    draw_chibi_player(32, 0, "DOWN", 2)
    # Row 1: Up (y=24..47)
    draw_chibi_player(0, 24, "UP", 0)
    draw_chibi_player(16, 24, "UP", 1)
    draw_chibi_player(32, 24, "UP", 2)
    # Row 2: Left (y=48..71)
    draw_chibi_player(0, 48, "LEFT", 0)
    draw_chibi_player(16, 48, "LEFT", 1)
    draw_chibi_player(32, 48, "LEFT", 2)
    # Row 3: Right (y=72..95)
    draw_chibi_player(0, 72, "RIGHT", 0)
    draw_chibi_player(16, 72, "RIGHT", 1)
    draw_chibi_player(32, 72, "RIGHT", 2)

    # --- Draw NPC Sora at Col 3 (x=48..63, y=0..23) ---
    nox, noy = 48, 0
    # Head base
    draw_rect(pixels, nox + 4, noy + 5, 8, 7, c_skin)
    # Black hair with bun
    draw_rect(pixels, nox + 3, noy + 4, 10, 3, c_npc_hair)
    draw_rect(pixels, nox + 3, noy + 7, 2, 5, c_npc_hair)
    draw_rect(pixels, nox + 11, noy + 7, 2, 5, c_npc_hair)
    # Hair bun on top
    draw_rect(pixels, nox + 6, noy + 1, 4, 3, c_npc_hair)
    # Purple hair pin
    draw_pixel(pixels, nox + 10, noy + 2, "#DE5273")
    # Eyes
    draw_pixel(pixels, nox + 5, noy + 8, "#2F231D")
    draw_pixel(pixels, nox + 10, noy + 8, "#2F231D")
    # Cheek blush
    draw_pixel(pixels, nox + 4, noy + 9, "#FF7CA0")
    draw_pixel(pixels, nox + 11, noy + 9, "#FF7CA0")
    # Kimono Dress
    draw_rect(pixels, nox + 3, noy + 12, 10, 9, c_npc_kimono)
    # Obi sash (white sash with red center)
    draw_rect(pixels, nox + 3, noy + 15, 10, 3, c_npc_obi)
    draw_line_horizontal(pixels, nox + 3, noy + 16, 10, c_npc_obi_red)
    # Kimono sleeves
    draw_rect(pixels, nox + 1, noy + 12, 2, 6, c_npc_kimono)
    draw_rect(pixels, nox + 13, noy + 12, 2, 6, c_npc_kimono)
    draw_rect(pixels, nox + 1, noy + 18, 1, 1, c_skin) # hands
    draw_rect(pixels, nox + 14, noy + 18, 1, 1, c_skin)
    # Feet
    draw_rect(pixels, nox + 5, noy + 21, 2, 2, "#EAEAEA") # white sandals
    draw_rect(pixels, nox + 9, noy + 21, 2, 2, "#EAEAEA")

    write_png("assets/characters.png", 128, 96, pixels)
    print("Generated: assets/characters.png")

def generate_items():
    # 128x128 grid (8x8 tiles of 16x16)
    pixels = create_grid(128, 128, "#00000000")
    
    # 5 Crops x 4 stages each
    # Row 0: Rice & Carrot (Col 0..3: Rice, Col 4..7: Carrot)
    # Rice
    draw_crop_stages(pixels, 0, 0, ["#8C7053", "#9CDB5E", "#78BD3B", "#DFBA4B"], "RICE")
    # Carrot
    draw_crop_stages(pixels, 64, 0, ["#9C5835", "#74AD4C", "#5D9E31", "#E68333"], "CARROT")
    
    # Row 1: Radish & Tea Leaves (Col 0..3: Radish, Col 4..7: Tea)
    # Radish
    draw_crop_stages(pixels, 0, 16, ["#DED4C5", "#95CF59", "#74AD36", "#EAEAEA"], "RADISH")
    # Tea
    draw_crop_stages(pixels, 64, 16, ["#634B35", "#8ED649", "#58AD39", "#A2E05E"], "TEA")
    
    # Row 2: Bamboo Shoots (Col 0..3)
    draw_crop_stages(pixels, 0, 32, ["#947250", "#876949", "#7B9C49", "#91AB6E"], "BAMBOO")

    # Row 3: Fish (16x16 icons)
    # Koi (Col 0, y=48)
    ox, oy = 0, 48
    draw_fish(pixels, ox, oy, "#FFFFFF", "#F2623F") # White body, orange spots
    # Salmon (Col 1, y=48)
    draw_fish(pixels, 16, 48, "#FFB8B8", "#D97B7B") # Pinkish salmon
    # Catfish (Col 2, y=48)
    draw_fish(pixels, 32, 48, "#65656E", "#48484F") # Dark whiskers fish
    # Tuna (Col 3, y=48)
    draw_fish(pixels, 48, 48, "#3E6A94", "#2A4B6B") # Blue-gray tuna
    # Golden Carp (Col 4, y=48)
    draw_fish(pixels, 64, 48, "#FFC94D", "#E09C1B") # Golden fish

    # Row 4: Tools (16x16 icons)
    # Hoe (Col 0, y=64)
    ox, oy = 0, 64
    draw_rect(pixels, ox + 7, oy + 4, 2, 10, "#9E7345") # Handle
    draw_rect(pixels, ox + 3, oy + 2, 6, 2, "#9FA5AD") # Blade
    draw_pixel(pixels, ox + 3, oy + 4, "#737A82")
    # Watering Can (Col 1, y=64)
    ox, oy = 16, 64
    draw_rect(pixels, ox + 3, oy + 4, 8, 7, "#42A1D9") # Body
    draw_rect(pixels, ox + 1, oy + 6, 2, 2, "#42A1D9") # Spout
    draw_pixel(pixels, ox + 1, oy + 5, "#FFFFFF") # Water drip
    draw_rect(pixels, ox + 11, oy + 5, 2, 5, "#1B628C") # Handle
    # Fishing Rod (Col 2, y=64)
    ox, oy = 32, 64
    draw_line_diagonal(pixels, ox + 2, oy + 13, ox + 13, oy + 2, "#B38450") # Rod
    draw_line_vertical(pixels, ox + 13, oy + 2, 11, "#EAEAEA") # Line
    draw_pixel(pixels, ox + 13, oy + 13, "#FF5252") # Bobber

    # Row 5: UI Elements & Icons (y=80)
    # Coin icon (Col 0, y=80)
    ox, oy = 0, 80
    draw_circle_filled(pixels, ox + 8, oy + 8, 6, "#FFD03B")
    draw_circle_filled(pixels, ox + 8, oy + 8, 4, "#F0B51D")
    draw_pixel(pixels, ox + 8, oy + 8, "#FFE891") # shine
    # Exclamation mark ! (Col 1, y=80)
    ox, oy = 16, 80
    draw_rect(pixels, ox + 7, oy + 2, 2, 7, "#FF3E3E")
    draw_rect(pixels, ox + 7, oy + 11, 2, 2, "#FF3E3E")
    # Seeds Pack (Col 2, y=80)
    ox, oy = 32, 80
    draw_rect(pixels, ox + 3, oy + 3, 10, 11, "#DEC299") # sack
    draw_outline(pixels, ox + 3, oy + 3, 10, 11, "#B38C5B")
    draw_rect(pixels, ox + 6, oy + 7, 4, 3, "#6BB04A") # plant drawing on seed bag

    write_png("assets/items.png", 128, 128, pixels)
    print("Generated: assets/items.png")

def generate_ui():
    # UI Panel Sheet (64x64 pixels)
    pixels = create_grid(64, 64, "#00000000")
    
    # Rounded panel background with cozy dark border and warm beige center
    c_ui_bg = "#FFF7EB"
    c_ui_border = "#B8966E"
    c_ui_shadow = "#D9B890"

    # Draw a 32x32 UI panel component at top left
    draw_rect(pixels, 0, 0, 32, 32, c_ui_bg)
    draw_outline(pixels, 0, 0, 32, 32, c_ui_border)
    # Double border effect
    draw_outline(pixels, 2, 2, 28, 28, c_ui_shadow)

    # Draw a selected frame at (32, 0, 16, 16)
    draw_rect(pixels, 32, 0, 16, 16, "#54BF77")
    draw_rect(pixels, 34, 2, 12, 12, "#00000000") # transparent inside
    draw_outline(pixels, 32, 0, 16, 16, "#318A4F")

    # Standard button state at (0, 32, 32, 16)
    draw_rect(pixels, 0, 32, 32, 16, "#EBD5BB")
    draw_outline(pixels, 0, 32, 32, 16, c_ui_border)
    # Selected/pressed button at (32, 32, 32, 16)
    draw_rect(pixels, 32, 32, 32, 16, "#D4B28C")
    draw_outline(pixels, 32, 32, 32, 16, "#967551")

    write_png("assets/ui.png", 64, 64, pixels)
    print("Generated: assets/ui.png")

# --- Low Level Canvas Utilities ---

def draw_line_horizontal(pixels, x, y, length, color_hex):
    color = hex_to_rgba(color_hex)
    for cx in range(x, x + length):
        if 0 <= y < len(pixels) and 0 <= cx < len(pixels[0]):
            pixels[y][cx] = color

def draw_line_vertical(pixels, x, y, length, color_hex):
    color = hex_to_rgba(color_hex)
    for cy in range(y, y + length):
        if 0 <= cy < len(pixels) and 0 <= x < len(pixels[0]):
            pixels[cy][x] = color

def draw_line_diagonal(pixels, x1, y1, x2, y2, color_hex):
    color = hex_to_rgba(color_hex)
    steps = max(abs(x2 - x1), abs(y2 - y1))
    if steps == 0:
        if 0 <= y1 < len(pixels) and 0 <= x1 < len(pixels[0]):
            pixels[y1][x1] = color
        return
    for i in range(steps + 1):
        cx = int(x1 + (x2 - x1) * i / steps)
        cy = int(y1 + (y2 - y1) * i / steps)
        if 0 <= cy < len(pixels) and 0 <= cx < len(pixels[0]):
            pixels[cy][cx] = color

def draw_circle_filled(pixels, cx, cy, r, color_hex):
    color = hex_to_rgba(color_hex)
    for y in range(max(0, cy - r), min(len(pixels), cy + r + 1)):
        for x in range(max(0, cx - r), min(len(pixels[0]), cx + r + 1)):
            if (x - cx) ** 2 + (y - cy) ** 2 <= r ** 2:
                pixels[y][x] = color

def draw_crop_stages(pixels, ox, oy, colors, crop_name):
    # Stage 0: Seed
    # Tiny dot
    draw_pixel(pixels, ox + 8, oy + 12, colors[0])
    draw_pixel(pixels, ox + 7, oy + 13, colors[0])
    draw_pixel(pixels, ox + 9, oy + 13, colors[0])

    # Stage 1: Sprout
    # Little green line/v
    sox = ox + 16
    draw_line_vertical(pixels, sox + 8, oy + 9, 5, colors[1])
    draw_pixel(pixels, sox + 7, oy + 10, colors[1])
    draw_pixel(pixels, sox + 9, oy + 11, colors[1])

    # Stage 2: Medium
    # Lush cluster
    mox = ox + 32
    draw_rect(pixels, mox + 6, oy + 7, 4, 7, colors[2])
    draw_pixel(pixels, mox + 5, oy + 9, colors[2])
    draw_pixel(pixels, mox + 10, oy + 10, colors[2])
    draw_pixel(pixels, mox + 7, oy + 6, "#8AD44C") # lighter highlights

    # Stage 3: Mature
    # Fruit / grain visible
    tox = ox + 48
    if crop_name == "RICE":
        # Yellow drooping stalks
        draw_rect(pixels, tox + 5, oy + 4, 6, 10, colors[2]) # green base
        draw_line_diagonal(pixels, tox + 5, oy + 6, tox + 2, oy + 11, colors[3]) # rice grains
        draw_line_diagonal(pixels, tox + 10, oy + 6, tox + 13, oy + 11, colors[3])
    elif crop_name == "CARROT":
        # Green leaves above, orange root peaking from ground
        draw_rect(pixels, tox + 6, oy + 2, 4, 8, colors[1]) # leafy top
        draw_rect(pixels, tox + 5, oy + 10, 6, 4, colors[3]) # orange top
        draw_pixel(pixels, tox + 7, oy + 14, colors[3])
    elif crop_name == "RADISH":
        # Green leafy top, large white tuber shoulder
        draw_rect(pixels, tox + 5, oy + 2, 6, 8, colors[1])
        draw_rect(pixels, tox + 4, oy + 9, 8, 5, colors[3]) # white shoulders
        draw_outline(pixels, tox + 4, oy + 9, 8, 5, "#CCCCCC")
    elif crop_name == "TEA":
        # Fully bushy green tea leaves with light tips
        draw_circle_filled(pixels, tox + 8, oy + 8, 6, colors[2])
        draw_pixel(pixels, tox + 4, oy + 4, colors[3])
        draw_pixel(pixels, tox + 12, oy + 5, colors[3])
        draw_pixel(pixels, tox + 8, oy + 3, colors[3])
        draw_pixel(pixels, tox + 9, oy + 9, colors[3])
    elif crop_name == "BAMBOO":
        # Layered point cone
        draw_line_diagonal(pixels, tox + 8, oy + 2, tox + 4, oy + 13, colors[2])
        draw_line_diagonal(pixels, tox + 8, oy + 2, tox + 12, oy + 13, colors[2])
        draw_rect(pixels, tox + 5, oy + 10, 7, 4, colors[3]) # brown layers
        draw_pixel(pixels, tox + 8, oy + 4, colors[2])

def draw_fish(pixels, ox, oy, body_color_hex, detail_color_hex):
    # Oval body
    draw_circle_filled(pixels, ox + 8, oy + 8, 4, body_color_hex)
    draw_line_horizontal(pixels, ox + 4, oy + 8, 8, body_color_hex)
    # Tail fin
    draw_line_vertical(pixels, ox + 2, oy + 6, 5, detail_color_hex)
    draw_pixel(pixels, ox + 3, oy + 8, detail_color_hex)
    # Spots or gills
    draw_pixel(pixels, ox + 7, oy + 7, detail_color_hex)
    draw_pixel(pixels, ox + 9, oy + 9, detail_color_hex)
    # Eye
    draw_pixel(pixels, ox + 11, oy + 7, "#000000")

if __name__ == "__main__":
    generate_tilesheet()
    generate_characters()
    generate_items()
    generate_ui()
    print("All assets generated successfully!")
