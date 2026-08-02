#!/bin/bash

set -e

INPUT="$1"
EXT="${INPUT##*.}"
BASENAME=$(basename "$INPUT" ."$EXT")
INPUT_DIR=$(dirname "$(realpath "$INPUT")")
TMPDIR=$(mktemp -d)

# Step 0: Convert .odp or .pptx to PDF using LibreOffice
if [[ "$EXT" == "odp" || "$EXT" == "pptx" ]]; then
    echo "🔄 Converting $INPUT to PDF..."
    soffice --headless --convert-to pdf "$INPUT" --outdir "$TMPDIR"
    PDF="$TMPDIR/$BASENAME.pdf"
elif [[ "$EXT" == "pdf" ]]; then
    PDF="$INPUT"
else
    echo "❌ Unsupported file type: $EXT"
    exit 1
fi

# Step 1: Convert PDF slides to high-quality PNGs
echo "🖼️  Converting PDF pages to PNGs..."
pdftoppm -png -r 300 "$PDF" "$TMPDIR/slide"

# Step 2: Generate output path
OUTPUT_PATH="$INPUT_DIR/${BASENAME}.pngconv.pptx"

# Step 3: Call Python to assemble PPTX
echo "📦 Assembling PNGs into PPTX..."
uv run --with python-pptx - "$TMPDIR" "$OUTPUT_PATH" <<'EOF'
import sys
import os
from pptx import Presentation
from pptx.util import Inches
from PIL import Image

img_dir = sys.argv[1]
out_pptx = sys.argv[2]

prs = Presentation()
blank_slide_layout = prs.slide_layouts[6]

img_files = sorted(f for f in os.listdir(img_dir) if f.endswith('.png'))

# Set slide size to image size
first_img = Image.open(os.path.join(img_dir, img_files[0]))
prs.slide_width = first_img.width * 9525
prs.slide_height = first_img.height * 9525

for fname in img_files:
    path = os.path.join(img_dir, fname)
    slide = prs.slides.add_slide(blank_slide_layout)
    slide.shapes.add_picture(path, 0, 0, width=prs.slide_width, height=prs.slide_height)

prs.save(out_pptx)
EOF

echo "✅ Created: $OUTPUT_PATH"
