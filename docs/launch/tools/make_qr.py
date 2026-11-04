#!/usr/bin/env python3
"""Branded QR code to the App Store page: error correction H so the icon can sit in the middle, then
decoded at 100, 50, 30 and 20 percent scale before the file is written. If any scale fails to decode,
the script refuses to write it.

    python3 make_qr.py ../../../../kismetstudio-site/lantern/icon-512.png ../social/lantern-qr-iphone.png
"""
import sys
import qrcode
from qrcode.constants import ERROR_CORRECT_H
from PIL import Image, ImageDraw

URL = "https://apps.apple.com/us/app/id6830418364"
NIGHT = (20, 27, 43)
PAPER = (242, 244, 247)


def build(icon_path: str) -> Image.Image:
    qr = qrcode.QRCode(error_correction=ERROR_CORRECT_H, box_size=24, border=3)
    qr.add_data(URL)
    qr.make(fit=True)
    img = qr.make_image(fill_color=NIGHT, back_color=PAPER).convert("RGB")
    w, h = img.size
    icon = Image.open(icon_path).convert("RGBA")
    side = int(w * 0.22)
    icon = icon.resize((side, side), Image.LANCZOS)
    # rounded white plate behind the icon so the modules do not touch it
    plate = int(side * 1.18)
    plate_img = Image.new("RGBA", (plate, plate), (0, 0, 0, 0))
    ImageDraw.Draw(plate_img).rounded_rectangle([0, 0, plate - 1, plate - 1], radius=plate // 5, fill=PAPER + (255,))
    mask = Image.new("L", (side, side), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, side - 1, side - 1], radius=int(side * 0.2237), fill=255)
    img.paste(plate_img, ((w - plate) // 2, (h - plate) // 2), plate_img)
    img.paste(icon, ((w - side) // 2, (h - side) // 2), mask)
    return img


def decodes(img: Image.Image) -> bool:
    try:
        from pyzbar.pyzbar import decode  # optional; falls back to OpenCV, then to a warning
        return any(d.data.decode() == URL for d in decode(img))
    except Exception:
        pass
    try:
        import cv2, numpy as np
        det = cv2.QRCodeDetector()
        data, _, _ = det.detectAndDecode(cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR))
        return data == URL
    except Exception:
        return None


if __name__ == "__main__":
    icon, out = sys.argv[1], sys.argv[2]
    img = build(icon)
    results = {}
    for pct in (100, 50, 30, 20):
        w = int(img.width * pct / 100)
        small = img.resize((w, w), Image.LANCZOS)
        results[pct] = decodes(small)
    if any(v is False for v in results.values()):
        print("REFUSED: failed to decode at", [p for p, v in results.items() if v is False])
        sys.exit(1)
    if all(v is None for v in results.values()):
        print("WARNING: no QR decoder installed (pip install opencv-python-headless or pyzbar); written unverified")
    else:
        print("decoded at", [p for p, v in results.items() if v])
    img.save(out)
    print("wrote", out, img.size)
