"""Printable A4 "Check in here" poster with a QR code to the check-in site.

Run:  python3 make_checkin_poster.py
Output: seren-checkin-poster.pdf
"""
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib.utils import ImageReader
from reportlab.pdfgen import canvas
import qrcode
from qrcode.constants import ERROR_CORRECT_M

from make_review_cards import ACCENT, INK, MUTED, PAPER, white  # fonts are registered on import

CHECKIN_URL = "https://checkin.serensaigon.com"


def main():
    qr = qrcode.QRCode(error_correction=ERROR_CORRECT_M, box_size=20, border=2)
    qr.add_data(CHECKIN_URL)
    qr.make(fit=True)
    image = ImageReader(qr.make_image(fill_color="#3B2F28", back_color="white").convert("RGB"))

    w, h = A4
    c = canvas.Canvas("seren-checkin-poster.pdf", pagesize=A4)
    c.setTitle("Seren – Check-in poster")
    m = 14 * mm
    c.setFillColor(PAPER)
    c.roundRect(m, m, w - 2 * m, h - 2 * m, 9 * mm, stroke=0, fill=1)
    cx = w / 2

    c.setFillColor(ACCENT)
    c.setFont("Serif", 46)
    c.drawCentredString(cx, h - 50 * mm, "S E R E N")
    c.setStrokeColor(ACCENT)
    c.line(cx - 22 * mm, h - 57 * mm, cx + 22 * mm, h - 57 * mm)

    c.setFillColor(INK)
    c.setFont("Serif", 34)
    c.drawCentredString(cx, h - 78 * mm, "Check-in tại đây")
    c.setFillColor(MUTED)
    c.setFont("Serif-Italic", 26)
    c.drawCentredString(cx, h - 90 * mm, "Check in here")

    size = 112 * mm
    qy = h - 102 * mm - size
    c.setFillColor(white)
    c.roundRect(cx - size / 2 - 6 * mm, qy - 6 * mm, size + 12 * mm, size + 12 * mm, 6 * mm, stroke=0, fill=1)
    c.drawImage(image, cx - size / 2, qy, size, size)

    c.setFillColor(INK)
    c.setFont("Sans-Bold", 17)
    c.drawCentredString(cx, qy - 20 * mm, "Quét mã bằng camera điện thoại để điền phiếu thông tin")
    c.setFillColor(MUTED)
    c.setFont("Sans-Italic", 16)
    c.drawCentredString(cx, qy - 29 * mm, "Scan with your phone camera to fill in your details")
    c.setFont("Sans", 13)
    c.drawCentredString(cx, qy - 40 * mm, "Brows & Lashes · Massage · Nails · Head Spa")
    c.drawCentredString(cx, qy - 48 * mm, "checkin.serensaigon.com")
    c.showPage()
    c.save()
    print("Wrote seren-checkin-poster.pdf")


if __name__ == "__main__":
    main()
