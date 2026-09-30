"""Printable bilingual Google review QR cards for Seren.

Run:  python3 make_review_cards.py
Needs: pip install qrcode reportlab pillow
Output: seren-google-review-cards.pdf (A4) and seren-google-review-qr.png
"""
import qrcode
from qrcode.constants import ERROR_CORRECT_M
from reportlab.lib.colors import HexColor, white
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas

REVIEW_URL = "https://g.page/r/CTpMl46hoXZSEBM/review"
BUSINESS = "SEREN"

INK = HexColor("#3B2F28")
ACCENT = HexColor("#8B6B4A")
MUTED = HexColor("#8A7F76")
PAPER = HexColor("#F7F4EE")
STAR = HexColor("#F4A62A")

FONTS = "/usr/share/fonts/truetype/liberation/"
pdfmetrics.registerFont(TTFont("Serif", FONTS + "LiberationSerif-Regular.ttf"))
pdfmetrics.registerFont(TTFont("Serif-Italic", FONTS + "LiberationSerif-Italic.ttf"))
pdfmetrics.registerFont(TTFont("Sans", FONTS + "LiberationSans-Regular.ttf"))
pdfmetrics.registerFont(TTFont("Sans-Bold", FONTS + "LiberationSans-Bold.ttf"))
pdfmetrics.registerFont(TTFont("Sans-Italic", FONTS + "LiberationSans-Italic.ttf"))


def qr_image():
    qr = qrcode.QRCode(error_correction=ERROR_CORRECT_M, box_size=20, border=2)
    qr.add_data(REVIEW_URL)
    qr.make(fit=True)
    return qr.make_image(fill_color="#3B2F28", back_color="white").convert("RGB")


def star(c, cx, cy, r):
    """Five-pointed star centred at (cx, cy)."""
    import math
    path = c.beginPath()
    for i in range(10):
        radius = r if i % 2 == 0 else r * 0.42
        angle = math.pi / 2 + i * math.pi / 5
        x, y = cx + radius * math.cos(angle), cy + radius * math.sin(angle)
        path.moveTo(x, y) if i == 0 else path.lineTo(x, y)
    path.close()
    c.setFillColor(STAR)
    c.drawPath(path, stroke=0, fill=1)


def card(c, x, y, w, h, qr, scale=1.0):
    """One card with its bottom-left corner at (x, y)."""
    s = scale
    c.setFillColor(PAPER)
    c.roundRect(x, y, w, h, 6 * mm * s, stroke=0, fill=1)
    cx = x + w / 2
    top = y + h

    c.setFillColor(ACCENT)
    c.setFont("Serif", 30 * s)
    c.drawCentredString(cx, top - 22 * mm * s, " ".join(BUSINESS))
    c.setStrokeColor(ACCENT)
    c.setLineWidth(0.6 * s)
    c.line(cx - 14 * mm * s, top - 27 * mm * s, cx + 14 * mm * s, top - 27 * mm * s)

    c.setFillColor(INK)
    c.setFont("Serif", 19 * s)
    c.drawCentredString(cx, top - 40 * mm * s, "Bạn hài lòng với dịch vụ?")
    c.setFillColor(MUTED)
    c.setFont("Serif-Italic", 15 * s)
    c.drawCentredString(cx, top - 48 * mm * s, "Loved your visit?")

    size = min(w * 0.58, h * 0.42)
    qy = top - 54 * mm * s - size
    c.setFillColor(white)
    c.roundRect(cx - size / 2 - 4 * mm * s, qy - 4 * mm * s, size + 8 * mm * s, size + 8 * mm * s,
                4 * mm * s, stroke=0, fill=1)
    c.drawImage(qr, cx - size / 2, qy, size, size)

    for i in range(5):
        star(c, cx + (i - 2) * 8 * mm * s, qy - 13 * mm * s, 3.2 * mm * s)

    c.setFillColor(INK)
    c.setFont("Sans-Bold", 12.5 * s)
    c.drawCentredString(cx, qy - 25 * mm * s, "Quét mã để đánh giá chúng tôi trên Google")
    c.setFillColor(MUTED)
    c.setFont("Sans-Italic", 11.5 * s)
    c.drawCentredString(cx, qy - 31.5 * mm * s, "Scan with your phone camera to review us on Google")
    c.setFont("Sans", 9.5 * s)
    c.drawCentredString(cx, qy - 39 * mm * s, "Chỉ mất 30 giây · It only takes 30 seconds · Cảm ơn bạn! Thank you!")


def main():
    qr = ImageReader(qr_image())
    page_w, page_h = A4
    c = canvas.Canvas("seren-google-review-cards.pdf", pagesize=A4)
    c.setTitle("Seren – Google review cards")

    # Page 1: one large sign for reception (A4).
    margin = 14 * mm
    card(c, margin, margin, page_w - 2 * margin, page_h - 2 * margin, qr, scale=1.55)
    c.showPage()

    # Page 2: four A6 cards (105 x 148 mm) with cut lines, for stations and mirrors.
    cw, ch = page_w / 2, page_h / 2
    pad = 5 * mm
    for col in range(2):
        for row in range(2):
            card(c, col * cw + pad, row * ch + pad, cw - 2 * pad, ch - 2 * pad, qr, scale=0.72)
    c.setStrokeColor(HexColor("#CCCCCC"))
    c.setDash(3, 3)
    c.setLineWidth(0.5)
    c.line(cw, 0, cw, page_h)
    c.line(0, ch, page_w, ch)
    c.setFont("Sans", 7)
    c.setFillColor(MUTED)
    c.drawString(4 * mm, ch + 1.5 * mm, "Cắt theo đường kẻ / cut along the lines")
    c.showPage()
    c.save()

    qr_image().save("seren-google-review-qr.png")
    print("Wrote seren-google-review-cards.pdf and seren-google-review-qr.png")


if __name__ == "__main__":
    main()
