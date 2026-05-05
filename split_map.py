"""
Script to split a map image into grid cells.
"""
from PIL import Image
import os
import time
import math

# Disable decompression bomb check for large images
Image.MAX_IMAGE_PIXELS = None

# === CONSTANTS ===
INPUT_IMAGE_PATH = r"D:\Projects\Gridmap_scr\textures\advanced_world_map\custom\gridmap.png"
PIXELS_PER_CELL = 40
CELL_SIZE = 512

# Zero point coordinates on the source image (x, y)
ZERO_POINT_X = 9960
ZERO_POINT_Y = 2573


def is_fully_transparent(image: Image.Image) -> bool:
    """Check if the image contains only transparent pixels."""
    if image.mode != 'RGBA':
        return False
    
    # Get alpha channel
    alpha = image.split()[3]
    # Check if all pixels have alpha = 0
    return alpha.getextrema() == (0, 0)


def split_image():
    """Main function to split the image into grid cells."""
    # Load the source image
    img = Image.open(INPUT_IMAGE_PATH).convert('RGBA')
    width, height = img.size
    
    # Output directory (same as input image)
    output_dir = os.path.dirname(INPUT_IMAGE_PATH)
    
    # Calculate the range of cell indices
    # Zero point is at the BOTTOM-LEFT corner of cell (0, 0)
    # X increases to the right, Y increases upward (in logical coordinates)
    
    # For X: cells to the left of zero point have negative indices
    min_cell_x = -((ZERO_POINT_X) // CELL_SIZE + (1 if ZERO_POINT_X % CELL_SIZE > 0 else 0))
    max_cell_x = (width - ZERO_POINT_X - 1) // CELL_SIZE
    
    # For Y: cells below zero point have negative indices (Y grows upward)
    # In image coordinates, Y grows downward, so we invert
    min_cell_y = -((height - ZERO_POINT_Y) // CELL_SIZE + (1 if (height - ZERO_POINT_Y) % CELL_SIZE > 0 else 0))
    max_cell_y = (ZERO_POINT_Y - 1) // CELL_SIZE if ZERO_POINT_Y > 0 else -1
    
    print(f"Image size: {width}x{height}")
    print(f"Zero point: ({ZERO_POINT_X}, {ZERO_POINT_Y})")
    print(f"Cell size: {CELL_SIZE}x{CELL_SIZE}")
    print(f"Cell range X: {min_cell_x} to {max_cell_x}")
    print(f"Cell range Y: {min_cell_y} to {max_cell_y}")
    
    saved_count = 0
    skipped_count = 0
    
    for cell_y in range(min_cell_y, max_cell_y + 1):
        for cell_x in range(min_cell_x, max_cell_x + 1):
            # Calculate pixel coordinates for this cell
            # X: left edge at zero point for cell_x=0
            left = ZERO_POINT_X + cell_x * CELL_SIZE
            # Y: bottom edge at zero point for cell_y=0 (Y grows upward in logical coords)
            # In image coords: top = ZERO_POINT_Y - (cell_y + 1) * CELL_SIZE
            top = ZERO_POINT_Y - (cell_y + 1) * CELL_SIZE
            right = left + CELL_SIZE
            bottom = top + CELL_SIZE
            
            # Create a new transparent image for the cell
            cell_img = Image.new('RGBA', (CELL_SIZE, CELL_SIZE), (0, 0, 0, 0))
            
            # Calculate the overlap between the cell and the source image
            src_left = max(0, left)
            src_top = max(0, top)
            src_right = min(width, right)
            src_bottom = min(height, bottom)
            
            # Skip if no overlap
            if src_left >= src_right or src_top >= src_bottom:
                skipped_count += 1
                continue
            
            # Calculate where to paste in the cell image
            dst_left = src_left - left
            dst_top = src_top - top
            
            # Crop the region from source image
            region = img.crop((src_left, src_top, src_right, src_bottom))
            
            # Paste the region into the cell image
            cell_img.paste(region, (dst_left, dst_top))
            
            # Skip fully transparent cells
            if is_fully_transparent(cell_img):
                skipped_count += 1
                continue
            
            # Save the cell
            filename = f"({cell_x},{cell_y}).png"
            filepath = os.path.join(output_dir, filename)
            cell_img.save(filepath, 'PNG')
            saved_count += 1
    
    # Create mapInfo.yaml
    # Grid size in cells (one cell = PIXELS_PER_CELL x PIXELS_PER_CELL pixels)
    grid_x_min = -ZERO_POINT_X / PIXELS_PER_CELL
    grid_x_max = (width - ZERO_POINT_X) / PIXELS_PER_CELL - 1
    grid_y_min = -(height - ZERO_POINT_Y) / PIXELS_PER_CELL
    grid_y_max = ZERO_POINT_Y / PIXELS_PER_CELL - 1
    
    yaml_content = f"""version: 3
time: {int(time.time())}
width: {width}
height: {height}
tileSize: {CELL_SIZE}
pixelsPerCell: {PIXELS_PER_CELL}
gridX:
  min: {grid_x_min}
  max: {grid_x_max}
gridY:
  min: {grid_y_min}
  max: {grid_y_max}
bColor: [0.521569, 0.643137, 0.701961]
"""
    
    yaml_path = os.path.join(output_dir, "mapInfo.yaml")
    with open(yaml_path, 'w') as f:
        f.write(yaml_content)
    print(f"Created mapInfo.yaml")
    
    print(f"\nDone! Saved {saved_count} cells, skipped {skipped_count} transparent/empty cells.")


if __name__ == "__main__":
    split_image()
