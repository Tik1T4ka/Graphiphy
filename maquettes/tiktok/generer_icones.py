#!/usr/bin/env python3
# Icones "capacites" TFJ pour la video : medaillon + symbole, dessines a 4x puis reduits
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops

S = 4
N = 512 * S
C = N / 2
OUT = __import__("os").path.dirname(__file__) + "/ico_"

ROUGE = (210, 28, 36)
ROUGE_F = (90, 6, 12)
BLANC = (250, 248, 245)

def radial(c1, c2, cx=0.5, cy=0.4, r=0.6):
    yy, xx = np.mgrid[0:N, 0:N] / N
    d = np.clip(np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) / r, 0, 1)[..., None]
    a = np.array(c1) * (1 - d) + np.array(c2) * d
    return Image.fromarray(a.astype(np.uint8)).convert("RGBA")

def lineaire(c1, c2, angle=90):
    yy, xx = np.mgrid[0:N, 0:N] / N
    a = math.radians(angle)
    t = np.clip((xx - 0.5) * math.cos(a) + (yy - 0.5) * math.sin(a) + 0.5, 0, 1)[..., None]
    g = np.array(c1) * (1 - t) + np.array(c2) * t
    return Image.fromarray(g.astype(np.uint8)).convert("RGBA")

def masque(fn):
    m = Image.new("L", (N, N), 0)
    fn(ImageDraw.Draw(m))
    return m

def peindre(base, m, src):
    base.paste(src, (0, 0), m)

def medaillon():
    im = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    r_ext, r_int = N * 0.47, N * 0.40
    # ombre portee
    om = masque(lambda d: d.ellipse([C - r_ext, C - r_ext + N * 0.02, C + r_ext, C + r_ext + N * 0.02], fill=200))
    om = om.filter(ImageFilter.GaussianBlur(N * 0.02))
    im.paste((0, 0, 0, 255), (0, 0), om)
    # anneau rouge metallique
    peindre(im, masque(lambda d: d.ellipse([C - r_ext, C - r_ext, C + r_ext, C + r_ext], fill=255)), lineaire((255, 90, 90), (110, 8, 14), 70))
    peindre(im, masque(lambda d: d.ellipse([C - r_ext * 0.965, C - r_ext * 0.965, C + r_ext * 0.965, C + r_ext * 0.965], fill=255)), lineaire((150, 14, 22), (230, 40, 48), 70))
    # fond interieur sombre avec lueur
    peindre(im, masque(lambda d: d.ellipse([C - r_int, C - r_int, C + r_int, C + r_int], fill=255)), radial((70, 10, 16), (10, 8, 10), 0.5, 0.42, 0.42))
    # liseret interieur
    d = ImageDraw.Draw(im)
    d.ellipse([C - r_int, C - r_int, C + r_int, C + r_int], outline=(255, 120, 120, 120), width=int(N * 0.006))
    # 4 rivets en losange
    for k in range(4):
        a = k * math.pi / 2 + math.pi / 4
        x, y = C + math.cos(a) * (r_ext + r_int) / 2, C + math.sin(a) * (r_ext + r_int) / 2
        r = N * 0.016
        d.polygon([(x, y - r), (x + r, y), (x, y + r), (x - r, y)], fill=(255, 230, 230, 255))
    return im

def poser_symbole(im, sym_mask, couleur_haut=BLANC, couleur_bas=(200, 196, 192), lueur=ROUGE):
    # lueur rouge derriere
    gl = sym_mask.filter(ImageFilter.GaussianBlur(N * 0.03))
    im.paste(lueur + (255,), (0, 0), gl.point(lambda v: int(v * 0.9)))
    # ombre portee
    sh = ImageChops.offset(sym_mask, int(N * 0.012), int(N * 0.018)).filter(ImageFilter.GaussianBlur(N * 0.006))
    im.paste((0, 0, 0, 255), (0, 0), sh.point(lambda v: int(v * 0.8)))
    # corps en degrade
    peindre(im, sym_mask, lineaire(couleur_haut, couleur_bas, 90))
    # reflet en haut
    hl = ImageChops.multiply(sym_mask, lineaire((255, 255, 255), (0, 0, 0), 90).convert("L").point(lambda v: 255 if v > 175 else 0))
    im.paste((255, 255, 255, 255), (0, 0), hl.point(lambda v: int(v * 0.35)))

def finir(im, nom):
    # clip au cercle exterieur
    m = masque(lambda d: d.ellipse([C - N * 0.48, C - N * 0.48, C + N * 0.48, C + N * 0.50], fill=255))
    a = ImageChops.multiply(im.split()[3], m)
    im.putalpha(a)
    im.resize((512, 512), Image.LANCZOS).save(OUT + nom + ".png")

def rot(pts, a, cx=C, cy=C):
    c, s = math.cos(a), math.sin(a)
    return [(cx + (x - cx) * c - (y - cy) * s, cy + (x - cx) * s + (y - cy) * c) for x, y in pts]

# ---------------------------------------------------------------- 1. DASH : kunai lance + trainees de chakra
def ico_dash():
    im = medaillon()
    d = ImageDraw.Draw(im)
    # trainees de vitesse rouges
    for k, (y, l, ep) in enumerate([(-0.10, 0.30, 0.022), (0.0, 0.40, 0.03), (0.10, 0.28, 0.02), (0.18, 0.18, 0.014), (-0.18, 0.2, 0.014)]):
        x2 = C - N * 0.02
        pts = [(x2 - N * l, C + N * y), (x2, C + N * y - N * ep / 2), (x2, C + N * y + N * ep / 2)]
        d.polygon(rot(pts, -0.45), fill=(255, 70 + k * 20, 70, 220))
    def kunai(dr):
        L = N * 0.36
        pts = [(C + L * 0.95, C), (C + L * 0.25, C - N * 0.10), (C - L * 0.05, C), (C + L * 0.25, C + N * 0.10)]  # lame
        dr.polygon(rot(pts, -0.45), fill=255)
        poignee = [(C - L * 0.05, C - N * 0.03), (C - L * 0.75, C - N * 0.03), (C - L * 0.75, C + N * 0.03), (C - L * 0.05, C + N * 0.03)]
        dr.polygon(rot(poignee, -0.45), fill=255)
        cx, cy = rot([(C - L * 0.9, C)], -0.45)[0]
        r = N * 0.065
        dr.ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
        dr.ellipse([cx - r * 0.55, cy - r * 0.55, cx + r * 0.55, cy + r * 0.55], fill=0)
    m = masque(kunai)
    # bandes sur la poignee
    def bandes(dr):
        L = N * 0.36
        for k in range(5):
            x = C - L * 0.12 - k * L * 0.13
            dr.polygon(rot([(x, C - N * 0.03), (x - L * 0.05, C - N * 0.04), (x - L * 0.05, C + N * 0.04), (x, C + N * 0.04)], -0.45), fill=255)
    poser_symbole(im, m)
    bm = ImageChops.multiply(masque(bandes), m)
    im.paste((150, 18, 26, 255), (0, 0), bm)
    # arete centrale de la lame
    L = N * 0.36
    ImageDraw.Draw(im).line(rot([(C + L * 0.9, C), (C + L * 0.0, C)], -0.45), fill=(150, 150, 155, 255), width=int(N * 0.006))
    finir(im, "dash")

# ---------------------------------------------------------------- 2. MEDICAL : goutte de sang + croix + battement
def ico_medical():
    im = medaillon()
    def goutte(dr):
        r = N * 0.17
        cy = C + N * 0.06
        dr.ellipse([C - r, cy - r, C + r, cy + r], fill=255)
        dr.polygon([(C, C - N * 0.27), (C - r * 0.93, cy - r * 0.35), (C + r * 0.93, cy - r * 0.35)], fill=255)
    m = masque(goutte)
    poser_symbole(im, m, (255, 80, 85), (150, 8, 16), lueur=(255, 40, 40))
    # croix blanche
    def croix(dr):
        cy = C + N * 0.06; a, b = N * 0.035, N * 0.10
        dr.rectangle([C - a, cy - b, C + a, cy + b], fill=255)
        dr.rectangle([C - b, cy - a, C + b, cy + a], fill=255)
    cm = masque(croix)
    sh = ImageChops.offset(cm, int(N * 0.006), int(N * 0.008)).filter(ImageFilter.GaussianBlur(N * 0.004))
    im.paste((60, 0, 0, 255), (0, 0), sh)
    im.paste(BLANC + (255,), (0, 0), cm)
    # reflet sur la goutte
    d = ImageDraw.Draw(im)
    d.ellipse([C - N * 0.12, C - N * 0.03, C - N * 0.08, C + N * 0.05], fill=(255, 220, 220, 150))
    # ligne de battement de coeur
    pts = [(C - N * 0.27, C + N * 0.28), (C - N * 0.18, C + N * 0.28), (C - N * 0.13, C + N * 0.22), (C - N * 0.08, C + N * 0.33),
           (C - N * 0.03, C + N * 0.19), (C + N * 0.02, C + N * 0.28), (C + N * 0.27, C + N * 0.28)]
    d.line(pts, fill=(255, 255, 255, 230), width=int(N * 0.012), joint="curve")
    finir(im, "medical")

# ---------------------------------------------------------------- 3. EXECUTIONS : katana en diagonale + entaille sanglante
def ico_execution():
    im = medaillon()
    d = ImageDraw.Draw(im)
    # entaille rouge (croissant)
    sl = masque(lambda dr: dr.ellipse([C - N * 0.36, C - N * 0.30, C + N * 0.30, C + N * 0.36], fill=255))
    sl2 = masque(lambda dr: dr.ellipse([C - N * 0.31, C - N * 0.36, C + N * 0.36, C + N * 0.28], fill=255))
    cres = ImageChops.subtract(sl, sl2).filter(ImageFilter.GaussianBlur(N * 0.004))
    im.paste((255, 40, 50, 255), (0, 0), cres)
    a = -math.pi / 4
    def katana(dr):
        # lame legerement courbe
        pts = []
        for i in range(40):
            u = i / 39
            x = C - N * 0.05 + u * N * 0.38
            y = C - N * 0.03 * math.sin(u * math.pi * 0.9)
            pts.append((x, y - N * 0.04 * (1 - u * 0.6)))
        pts.append((C + N * 0.36, C - N * 0.045))
        for i in range(39, -1, -1):
            u = i / 39
            x = C - N * 0.05 + u * N * 0.38
            y = C - N * 0.03 * math.sin(u * math.pi * 0.9)
            pts.append((x, y + N * 0.026 * (1 - u * 0.8)))
        dr.polygon(rot(pts, a), fill=255)
        # tsuba
        tx, ty = rot([(C - N * 0.065, C)], a)[0]
        dr.ellipse([tx - N * 0.065, ty - N * 0.065, tx + N * 0.065, ty + N * 0.065], fill=255)
        # poignee
        dr.polygon(rot([(C - N * 0.08, C - N * 0.034), (C - N * 0.30, C - N * 0.03), (C - N * 0.30, C + N * 0.03), (C - N * 0.08, C + N * 0.034)], a), fill=255)
    m = masque(katana)
    poser_symbole(im, m, (255, 255, 255), (175, 178, 185))
    # tressage rouge de la poignee + tsuba sombre
    def tresse(dr):
        for k in range(6):
            x = C - N * 0.10 - k * N * 0.032
            dr.polygon(rot([(x, C - N * 0.032), (x - N * 0.016, C), (x, C + N * 0.032), (x + N * 0.016, C)], a), fill=255)
    im.paste((170, 16, 26, 255), (0, 0), masque(tresse))
    tx, ty = rot([(C - N * 0.065, C)], a)[0]
    ImageDraw.Draw(im).ellipse([tx - N * 0.052, ty - N * 0.052, tx + N * 0.052, ty + N * 0.052], fill=(40, 36, 36, 255))
    ImageDraw.Draw(im).ellipse([tx - N * 0.014, ty - N * 0.014, tx + N * 0.014, ty + N * 0.014], fill=(200, 160, 60, 255))
    # gouttes de sang qui tombent de la lame
    for x, y, r in [(0.17, 0.10, 0.022), (0.22, 0.18, 0.016), (0.12, 0.20, 0.012)]:
        cx, cy = C + N * x, C + N * y
        rr = N * r
        d = ImageDraw.Draw(im)
        d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=(220, 20, 30, 255))
        d.polygon([(cx, cy - rr * 2.2), (cx - rr * 0.9, cy - rr * 0.3), (cx + rr * 0.9, cy - rr * 0.3)], fill=(220, 20, 30, 255))
    finir(im, "execution")

# ---------------------------------------------------------------- 4. COFFRES : coffre ferre + cadenas a code
def ico_coffre():
    im = medaillon()
    x1, x2, y1, y2 = C - N * 0.27, C + N * 0.27, C - N * 0.18, C + N * 0.22
    def corps(dr):
        dr.rounded_rectangle([x1, y1 + N * 0.10, x2, y2], radius=N * 0.03, fill=255)
        dr.pieslice([x1, y1 - N * 0.02, x2, y1 + N * 0.22], 180, 360, fill=255)
        dr.rectangle([x1, y1 + N * 0.09, x2, y1 + N * 0.11], fill=255)
    m = masque(corps)
    poser_symbole(im, m, (215, 52, 56), (120, 16, 22), lueur=ROUGE)
    d = ImageDraw.Draw(im)
    # ferrures blanches
    fer = (235, 232, 228, 255)
    w = int(N * 0.018)
    d.line([(x1, y1 + N * 0.10), (x2, y1 + N * 0.10)], fill=fer, width=w)
    for x in (x1 + N * 0.07, x2 - N * 0.07):
        d.line([(x, y1 + N * 0.005), (x, y2)], fill=fer, width=w)
    d.rounded_rectangle([x1, y1 + N * 0.10, x2, y2], radius=N * 0.03, outline=fer, width=w)
    d.arc([x1, y1 - N * 0.02, x2, y1 + N * 0.22], 180, 360, fill=fer, width=w)
    # cadenas a code
    lx, ly = C, y1 + N * 0.16
    d.arc([lx - N * 0.06, ly - N * 0.12, lx + N * 0.06, ly + N * 0.0], 180, 360, fill=fer, width=int(N * 0.02))
    d.line([(lx - N * 0.06, ly - N * 0.06), (lx - N * 0.06, ly - N * 0.01)], fill=fer, width=int(N * 0.02))
    d.line([(lx + N * 0.06, ly - N * 0.06), (lx + N * 0.06, ly - N * 0.01)], fill=fer, width=int(N * 0.02))
    d.rounded_rectangle([lx - N * 0.09, ly - N * 0.02, lx + N * 0.09, ly + N * 0.12], radius=N * 0.02, fill=(250, 248, 245, 255))
    for i in range(3):
        for j in range(2):
            cx, cy = lx - N * 0.05 + i * N * 0.05, ly + N * 0.025 + j * N * 0.045
            d.ellipse([cx - N * 0.013, cy - N * 0.013, cx + N * 0.013, cy + N * 0.013], fill=(200, 24, 32, 255))
    # reflets dores
    d.ellipse([x1 + N * 0.05, y1 + N * 0.02, x1 + N * 0.09, y1 + N * 0.05], fill=(255, 255, 255, 90))
    finir(im, "coffre")

# ---------------------------------------------------------------- 5. ARBRE : parchemin deroule + arbre de techniques
def ico_arbre():
    im = medaillon()
    def parch(dr):
        dr.rectangle([C - N * 0.22, C - N * 0.24, C + N * 0.22, C + N * 0.24], fill=255)
    m = masque(parch)
    poser_symbole(im, m, (245, 236, 220), (205, 190, 165), lueur=ROUGE)
    d = ImageDraw.Draw(im)
    # rouleaux
    for y in (C - N * 0.25, C + N * 0.25):
        d.rounded_rectangle([C - N * 0.27, y - N * 0.035, C + N * 0.27, y + N * 0.035], radius=N * 0.03, fill=(150, 18, 26, 255))
        d.rounded_rectangle([C - N * 0.27, y - N * 0.035, C + N * 0.27, y - N * 0.012], radius=N * 0.02, fill=(220, 60, 66, 255))
        for x in (C - N * 0.29, C + N * 0.29):
            d.ellipse([x - N * 0.03, y - N * 0.03, x + N * 0.03, y + N * 0.03], fill=(40, 30, 30, 255))
    # arbre de techniques : noeuds + liens
    nodes = [(0, -0.14), (-0.11, -0.03), (0.11, -0.03), (-0.11, 0.09), (0, 0.09), (0.11, 0.09)]
    links = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 4), (2, 5)]
    for a, b in links:
        d.line([(C + N * nodes[a][0], C + N * nodes[a][1]), (C + N * nodes[b][0], C + N * nodes[b][1])], fill=(60, 40, 36, 255), width=int(N * 0.012))
    for k, (x, y) in enumerate(nodes):
        cx, cy, r = C + N * x, C + N * y, N * 0.038
        appris = k in (0, 1, 4)
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(200, 24, 32, 255) if appris else (60, 40, 36, 255))
        d.ellipse([cx - r * 0.55, cy - r * 0.55, cx + r * 0.55, cy + r * 0.55], fill=(255, 245, 235, 255) if appris else (150, 130, 115, 255))
    finir(im, "arbre")

# ---------------------------------------------------------------- 6. SUIVIS : cible d'entrainement + kunai plante + rangs
def ico_suivi():
    im = medaillon()
    d = ImageDraw.Draw(im)
    cy = C + N * 0.02
    for k, (r, col) in enumerate([(0.25, (245, 240, 235)), (0.195, (200, 24, 32)), (0.14, (245, 240, 235)), (0.085, (200, 24, 32)), (0.035, (245, 240, 235))]):
        d.ellipse([C - N * r, cy - N * r, C + N * r, cy + N * r], fill=col + (255,))
    # ombre/relief de la cible
    sh = masque(lambda dr: dr.ellipse([C - N * 0.25, cy - N * 0.25, C + N * 0.25, cy + N * 0.25], fill=255))
    grad = lineaire((255, 255, 255), (0, 0, 0), 120).convert("L").point(lambda v: int((255 - v) * 0.35))
    im.paste((0, 0, 0, 255), (0, 0), ImageChops.multiply(sh, grad))
    # kunai plante en diagonale (pointe au centre)
    a = -2.3
    def kunai(dr):
        L = N * 0.30
        tip = (C, cy)
        pts = [(C, cy), (C + L * 0.55, cy - N * 0.07), (C + L * 0.8, cy), (C + L * 0.55, cy + N * 0.07)]
        dr.polygon(rot(pts, a, C, cy), fill=255)
        dr.polygon(rot([(C + L * 0.8, cy - N * 0.022), (C + L * 1.35, cy - N * 0.022), (C + L * 1.35, cy + N * 0.022), (C + L * 0.8, cy + N * 0.022)], a, C, cy), fill=255)
        ex, ey = rot([(C + L * 1.45, cy)], a, C, cy)[0]
        r = N * 0.045
        dr.ellipse([ex - r, ey - r, ex + r, ey + r], fill=255)
        dr.ellipse([ex - r * 0.5, ey - r * 0.5, ex + r * 0.5, ey + r * 0.5], fill=0)
    m = masque(kunai)
    poser_symbole(im, m, (70, 70, 76), (25, 25, 30), lueur=(0, 0, 0))
    # 3 chevrons de rang en bas
    for k in range(3):
        y = C + N * 0.33 - k * N * 0.0
        x = C + (k - 1) * N * 0.07
        d = ImageDraw.Draw(im)
        col = (255, 255, 255, 255) if k < 2 else (120, 40, 44, 255)
        d.polygon([(x - N * 0.025, y - N * 0.025), (x, y), (x + N * 0.025, y - N * 0.025), (x + N * 0.025, y - N * 0.005), (x, y + N * 0.02), (x - N * 0.025, y - N * 0.005)], fill=col)
    finir(im, "suivi")

for f in (ico_suivi, ico_dash, ico_medical, ico_execution, ico_coffre, ico_arbre):
    f()
# planche de controle
pl = Image.new("RGB", (6 * 260, 260), (12, 10, 12))
for i, n in enumerate(["suivi", "dash", "medical", "execution", "coffre", "arbre"]):
    pl.paste(Image.open(OUT + n + ".png").resize((250, 250), Image.LANCZOS), (i * 260 + 5, 5), Image.open(OUT + n + ".png").resize((250, 250)).split()[3])
pl.save(OUT + "planche.png")
print("ok")
