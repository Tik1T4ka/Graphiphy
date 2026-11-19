#!/usr/bin/env python3
# Video TikTok TFJ - Naruto RP (1080x1920, 30 fps) : style rouge / noir des menus TFJ
import math, random, subprocess, wave, os
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

W, H, FPS = 1080, 1920, 30
DUREE = 20.0
BPM = 120
BEAT = 60 / BPM
ICO = "/home/user/Graphiphy/maquettes/f4_icones/"
KIO = "/home/user/Graphiphy/kioki_icones/"
GF = "/tmp/claude-0/-home-user-Graphiphy/1cad09a0-0525-5516-bfca-9bee1be4520e/scratchpad/police/gf/ofl/"
OUT = os.path.dirname(os.path.abspath(__file__)) + "/"
LIEN = "discord.gg/EDaVQZGvrD"

ROUGE = (200, 24, 32)
ROUGE_F = (120, 10, 16)
BLANC = (245, 245, 245)
GRIS = (150, 150, 150)

def F(nom, t): return ImageFont.truetype(GF + nom, t)
ANTON = lambda t: F("anton/Anton-Regular.ttf", t)
BOLD = lambda t: F("poppins/Poppins-Bold.ttf", t)
MED = lambda t: F("poppins/Poppins-Medium.ttf", t)
BLACK = lambda t: F("poppins/Poppins-Black.ttf", t)

def img(p, taille=None):
    im = Image.open(p).convert("RGBA")
    return im.resize((taille, taille), Image.LANCZOS) if taille else im

def teinte(im, col):
    a = im.split()[3]
    out = Image.new("RGBA", im.size, col + (255,))
    out.putalpha(a)
    return out

# ------------------------------------------------------------------ fond fixe
yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
fond = np.zeros((H, W, 3), np.float32)
fond[:] = (8, 8, 10)
d = np.sqrt((xx - W * 0.15) ** 2 + (yy - H * 0.12) ** 2)
lueur1 = np.clip(1 - d / 1100, 0, 1) ** 2
d2 = np.sqrt((xx - W * 0.85) ** 2 + (yy - H * 0.88) ** 2)
lueur2 = np.clip(1 - d2 / 900, 0, 1) ** 2
GRAINS = [np.random.default_rng(i).normal(0, 9, (H // 2, W // 2)).astype(np.float32) for i in range(6)]
FILI = teinte(img(ICO + "filigrane.png", 1300), ROUGE)

def fond_frame(t, flash):
    p = 0.55 + 0.45 * (0.5 + 0.5 * math.cos(2 * math.pi * (t % BEAT) / BEAT)) * math.exp(-(t % BEAT) * 3)
    a = fond.copy()
    a[..., 0] += lueur1 * (150 * p + 60) + lueur2 * 70
    a[..., 1] += lueur1 * 10
    a[..., 2] += lueur1 * 14
    g = GRAINS[int(t * FPS) % len(GRAINS)]
    g = np.repeat(np.repeat(g, 2, 0), 2, 1)
    a += g[..., None]
    a += flash * 90
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)).convert("RGBA")

# braises qui montent
random.seed(3)
BRAISES = [(random.uniform(0, W), random.uniform(0, H), random.uniform(40, 140), random.uniform(2, 6), random.uniform(0, 6.28)) for _ in range(70)]
def braises(dr, t):
    for x, y, v, r, ph in BRAISES:
        yy_ = (y - t * v) % (H + 100) - 50
        xx_ = x + 25 * math.sin(t * 1.3 + ph)
        al = int(120 + 100 * math.sin(t * 3 + ph))
        dr.ellipse([xx_ - r, yy_ - r, xx_ + r, yy_ + r], fill=(255, 70 + int(60 * math.sin(ph)), 40, max(0, al)))

# ------------------------------------------------------------------ outils d'animation
def ease(x): x = max(0.0, min(1.0, x)); return 1 - (1 - x) ** 3
def back(x):
    x = max(0.0, min(1.0, x)); c = 1.7
    return 1 + (c + 1) * (x - 1) ** 3 + c * (x - 1) ** 2

def texte(cal, xy, s, font, col, anchor="mm", alpha=255, contour=0):
    dr = ImageDraw.Draw(cal)
    if contour:
        dr.text(xy, s, font=font, fill=(0, 0, 0, alpha), anchor=anchor, stroke_width=contour, stroke_fill=(0, 0, 0, alpha))
    dr.text(xy, s, font=font, fill=col + (alpha,), anchor=anchor)

def coller(base, im, cx, cy, echelle=1.0, alpha=1.0, rot=0):
    if echelle <= 0.01 or alpha <= 0.01: return
    w, h = im.size
    im2 = im.resize((max(1, int(w * echelle)), max(1, int(h * echelle))), Image.LANCZOS)
    if rot: im2 = im2.rotate(rot, resample=Image.BICUBIC, expand=True)
    if alpha < 1:
        a = im2.split()[3].point(lambda v: int(v * alpha)); im2.putalpha(a)
    base.alpha_composite(im2, (int(cx - im2.width / 2), int(cy - im2.height / 2)))

def calque_texte(s, font, col, contour=0, glow=None):
    dr0 = ImageDraw.Draw(Image.new("RGBA", (1, 1)))
    bb = dr0.textbbox((0, 0), s, font=font, stroke_width=contour)
    w, h = bb[2] - bb[0] + 80, bb[3] - bb[1] + 80
    c = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    dr = ImageDraw.Draw(c)
    if glow:
        g = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        ImageDraw.Draw(g).text((40 - bb[0], 40 - bb[1]), s, font=font, fill=glow + (255,))
        g = g.filter(ImageFilter.GaussianBlur(18))
        c.alpha_composite(g)
    dr.text((40 - bb[0], 40 - bb[1]), s, font=font, fill=col + (255,), stroke_width=contour, stroke_fill=(0, 0, 0, 255))
    return c

def contour_texte(s, font, col, ep=3):
    dr0 = ImageDraw.Draw(Image.new("RGBA", (1, 1)))
    bb = dr0.textbbox((0, 0), s, font=font)
    w, h = bb[2] - bb[0] + 40, bb[3] - bb[1] + 40
    c = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(c).text((20 - bb[0], 20 - bb[1]), s, font=font, fill=(0, 0, 0, 0), stroke_width=ep, stroke_fill=col + (255,))
    return c

def losange(dr, x, y, r, col):
    dr.polygon([(x, y - r), (x + r, y), (x, y + r), (x - r, y)], fill=col)

# ------------------------------------------------------------------ contenu
NOUVEAUTES = [
    ("DASH CHAKRA", "Combat plus nerveux", ["Esquive + saut de chakra", "Contrôle total dans les airs"], OUT + "ico_dash.png"),
    ("SYSTÈME MÉDICAL", "Le RP médecin prend vie", ["Groupes sanguins par personnage", "Dons de sang et transfusions"], OUT + "ico_medical.png"),
    ("EXÉCUTIONS", "Mises à mort cinématiques", ["Décapitations au ralenti", "Animation du bourreau au sabre"], OUT + "ico_execution.png"),
    ("COFFRES À CODE", "Protège ton butin", ["Inventaire en glisser-déposer", "Code secret à 4 chiffres"], OUT + "ico_coffre.png"),
    ("ARBRE DE TECHNIQUES", "Nouvelle interface F4", ["Style ninja, sceaux et parchemins", "Rinnegan désormais disponible"], OUT + "ico_arbre.png"),
]
T_INTRO, T_TITRE = 0.0, 2.0
T_CARTES = 4.0
D_CARTE = 2.0
T_FIN = T_CARTES + D_CARTE * len(NOUVEAUTES)   # 23.5
COUPES = [T_TITRE, T_CARTES] + [T_CARTES + i * D_CARTE for i in range(1, len(NOUVEAUTES))] + [T_FIN]
HOOK = [0.0, 0.5, 1.0]
IMPACTS = HOOK + [1.5, T_TITRE, T_TITRE + 0.5, T_TITRE + 1.0, T_TITRE + 1.5] \
    + [T_CARTES + i * D_CARTE + d for i in range(len(NOUVEAUTES)) for d in (0.0, 0.5)] + [T_FIN, T_FIN + 0.5]
def impact(t):
    v = 0.0
    for c in IMPACTS:
        if t >= c: v = max(v, math.exp(-(t - c) * 9))
    return v
def slam(t, t0, s0=2.4):
    """echelle d'un mot qui 'claque' : grand -> taille normale en 0,15 s"""
    if t < t0: return 0.0, 0.0
    k = min(1.0, (t - t0) / 0.15)
    return 1 + (s0 - 1) * (1 - k) ** 2, min(1.0, (t - t0) / 0.06)

# pre-rendus
C_HOOK1 = calque_texte("TON", ANTON(200), BLANC, glow=ROUGE)
C_HOOK1B = calque_texte("VILLAGE", ANTON(200), BLANC, glow=ROUGE)
C_HOOK2 = calque_texte("T'ATTEND.", ANTON(190), ROUGE, glow=ROUGE)
C_TFJ = calque_texte("TFJ", ANTON(330), BLANC, glow=ROUGE)
C_NRP = calque_texte("NARUTO RP", ANTON(120), ROUGE, glow=ROUGE)
C_NOUV = calque_texte("NOUVEAUTÉS", ANTON(140), BLANC, glow=ROUGE)
C_SEM = calque_texte("DE LA SEMAINE", ANTON(90), ROUGE)
NUMS = [contour_texte("%02d" % (i + 1), ANTON(260), (90, 90, 95), 4) for i in range(len(NOUVEAUTES))]
def titre_ajuste(s):
    t = 118
    while t > 60:
        bb = ImageDraw.Draw(Image.new("RGBA", (1, 1))).textbbox((0, 0), s, font=ANTON(t))
        if bb[2] - bb[0] <= 560: break
        t -= 4
    return calque_texte(s, ANTON(t), BLANC, glow=ROUGE_F)
TITRES = [titre_ajuste(n[0]) for n in NOUVEAUTES]
ICONES = []
for n in NOUVEAUTES:
    ic = img(n[3], 360)
    if "shuriken" in n[3] or "onglet" in n[3]: ic = teinte(ic, ROUGE)
    ICONES.append(ic)
SHUR = teinte(img(ICO + "shuriken.png", 220), ROUGE)
C_REJ = calque_texte("REJOINS-NOUS", ANTON(150), BLANC, glow=ROUGE)
C_LIEN = calque_texte(LIEN, BOLD(66), BLANC)
C_GMOD = calque_texte("SERVEUR GARRY'S MOD · NARUTO RP", BOLD(40), GRIS)

def carte(base, i, t0, t):
    """Carte facon menu 'entrainement' : coin coupe, numero en contour, puces rouges, gros bouton."""
    k = (t - t0) / D_CARTE
    e = ease(k * 7)
    sens = [1, -1, 1, -1, 1][i % 5]
    x0 = 80 + (1 - e) * 1000 * sens
    y0, cw, ch = 470, 920, 1020
    if i % 2 == 0: y0 += (1 - e) * 0
    cal = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    dr = ImageDraw.Draw(cal)
    cc = 70
    pts = [(x0, y0), (x0 + cw - cc, y0), (x0 + cw, y0 + cc), (x0 + cw, y0 + ch), (x0, y0 + ch)]
    dr.polygon(pts, fill=(14, 14, 17, 236))
    dr.line(pts + [pts[0]], fill=ROUGE + (255,), width=4)
    # lueur rouge au centre
    g = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(g).ellipse([x0 + cw / 2 - 260, y0 + 380 - 200, x0 + cw / 2 + 260, y0 + 380 + 200], fill=ROUGE + (120,))
    g = g.filter(ImageFilter.GaussianBlur(90))
    cal.alpha_composite(g)
    dr = ImageDraw.Draw(cal)
    nom, sous, puces, _ = NOUVEAUTES[i]
    texte(cal, (x0 + 60, y0 + 70), "NOUVEAUTÉ", BOLD(34), GRIS, anchor="la")
    coller(cal, NUMS[i], x0 + cw - 190, y0 + 165)
    cal.alpha_composite(TITRES[i], (int(x0 + 20), int(y0 + 245 - (TITRES[i].height - 40))))
    texte(cal, (x0 + 60, y0 + 270), sous, BOLD(40), ROUGE, anchor="la")
    # barre de progression
    dr.rectangle([x0 + 60, y0 + 345, x0 + cw - 60, y0 + 351], fill=(60, 60, 64, 255))
    dr.rectangle([x0 + 60, y0 + 345, x0 + 60 + (cw - 120) * ((i + 1) / len(NOUVEAUTES)), y0 + 351], fill=BLANC + (255,))
    # icone
    sc, al = slam(t, t0 + 0.5, 2.0)
    coller(cal, ICONES[i], x0 + cw / 2, y0 + 560 + 8 * math.sin(t * 4), sc * (1 + 0.04 * math.exp(-((t - t0) % BEAT) * 8)), al, rot=4 * math.sin(t * 2.3))
    # puces
    for j, p in enumerate(puces):
        a = ease((k - 0.45 - j * 0.12) * 9)
        yb = y0 + 760 + j * 70
        losange(dr, x0 + 75, yb, 11, ROUGE + (int(255 * a),))
        texte(cal, (x0 + 105 + (1 - a) * 40, yb), p, MED(40), BLANC, anchor="lm", alpha=int(255 * a))
    # bouton
    bx, by = x0 + 60, y0 + ch - 130
    dr.rectangle([bx, by, x0 + cw - 60, by + 92], fill=ROUGE + (255,))
    texte(cal, ((bx + x0 + cw - 60) / 2, by + 46), "À DÉCOUVRIR EN JEU", ANTON(52), BLANC)
    # entree : carte inclinee qui se redresse ; sortie : zoom + fondu
    rot_e = (1 - e) * 8 * sens
    sortie = ease((k - 0.9) * 10)
    if rot_e > 0.05 or rot_e < -0.05:
        cal = cal.rotate(rot_e, resample=Image.BICUBIC, center=(W / 2, H / 2))
    if sortie > 0:
        z = 1 + 0.25 * sortie
        cal = cal.resize((int(W * z), int(H * z)), Image.BILINEAR).crop((int((W * z - W) / 2), int((H * z - H) / 2), int((W * z - W) / 2) + W, int((H * z - H) / 2) + H))
        cal.putalpha(cal.split()[3].point(lambda v: int(v * (1 - sortie))))
    base.alpha_composite(cal)

def entete(base, t):
    dr = ImageDraw.Draw(base)
    losange(dr, 95, 150, 16, ROUGE + (255,))
    texte(base, (125, 150), "TFJ", ANTON(64), BLANC, anchor="lm")
    texte(base, (230, 152), "Naruto RP · Garry's Mod", MED(34), GRIS, anchor="lm")

def frame(t):
    flash = 0.0
    for c in COUPES:
        if 0 <= t - c < 0.12: flash = 1 - (t - c) / 0.12
    base = fond_frame(t, flash * 0.25)
    # filigrane 忍
    s = 1.0 + 0.03 * math.sin(t * 2)
    fa = 0.10 if t < T_FIN else 0.16
    coller(base, FILI, W / 2, H * 0.52, s, fa)
    braises(ImageDraw.Draw(base, "RGBA"), t)

    if t < T_TITRE:
        lignes_vitesse(base, t, 0.8)
        for cal_, y_, t0_, r_ in ((C_HOOK1, 540, 0.0, 0), (C_HOOK1B, 800, 0.5, 0), (C_HOOK2, 1070, 1.0, -4)):
            sc, al = slam(t, t0_)
            coller(base, cal_, W / 2, y_, sc, al, rot=r_)
        sc, al = slam(t, 1.5, 3.0)
        coller(base, SHUR, W / 2, 1360, sc * 0.9, al, rot=t * 500)
    elif t < T_CARTES:
        lignes_vitesse(base, t, 0.5)
        entete(base, t)
        sc, al = slam(t, T_TITRE, 2.8); coller(base, C_TFJ, W / 2, 700, sc, al)
        sc, al = slam(t, T_TITRE + 0.5); coller(base, C_NRP, W / 2, 920, sc, al)
        dr = ImageDraw.Draw(base)
        lw = 520 * ease((t - T_TITRE - 0.5) * 6)
        dr.rectangle([W / 2 - lw, 1040, W / 2 + lw, 1046], fill=ROUGE + (255,))
        sc, al = slam(t, T_TITRE + 1.0); coller(base, C_NOUV, W / 2, 1180, sc, al)
        sc, al = slam(t, T_TITRE + 1.5); coller(base, C_SEM, W / 2, 1320, sc, al)
    elif t < T_FIN:
        entete(base, t)
        i = min(int((t - T_CARTES) / D_CARTE), len(NOUVEAUTES) - 1)
        carte(base, i, T_CARTES + i * D_CARTE, t)
        # points de progression
        dr = ImageDraw.Draw(base)
        for j in range(len(NOUVEAUTES)):
            losange(dr, W / 2 + (j - (len(NOUVEAUTES) - 1) / 2) * 46, 1580, 10 if j == i else 7, (ROUGE if j <= i else (80, 80, 85)) + (255,))
    else:
        k = (t - T_FIN) / (DUREE - T_FIN)
        entete(base, t)
        lignes_vitesse(base, t, 0.35)
        sc, al = slam(t, T_FIN, 2.6); coller(base, C_REJ, W / 2, 640, sc, al)
        texte(base, (W / 2, 790), "Le village a besoin de nouveaux ninjas", MED(42), GRIS, alpha=int(255 * ease((k - 0.1) * 5)))
        # bouton lien
        p = 1 + 0.04 * math.sin(t * 2 * math.pi / BEAT)
        a = ease((k - 0.15) * 5)
        bt = Image.new("RGBA", (900, 260), (0, 0, 0, 0))
        dbt = ImageDraw.Draw(bt)
        dbt.rectangle([0, 0, 899, 259], fill=ROUGE + (255,))
        dbt.line([(0, 0), (899, 0), (899, 259), (0, 259), (0, 0)], fill=(255, 90, 90, 255), width=3)
        texte(bt, (450, 85), "REJOINDRE LE DISCORD", ANTON(70), BLANC)
        bt.alpha_composite(C_LIEN, (450 - C_LIEN.width // 2, 175 - C_LIEN.height // 2))
        sc, al = slam(t, T_FIN + 0.5, 1.8)
        coller(base, bt, W / 2, 1060, sc * p, al)
        texte(base, (W / 2, 1290), "Lien aussi en bio", BOLD(44), BLANC, alpha=int(255 * ease((k - 0.3) * 5)))
        texte(base, (W / 2, 1360), "Dash · Médical · Coffres · Exécutions", BOLD(40), ROUGE, alpha=int(255 * ease((k - 0.4) * 5)))
        coller(base, C_GMOD, W / 2, 1450, 1, ease((k - 0.5) * 5))
    coup_de_sabre(base, t)
    return post(base.convert("RGB"), t)

def lignes_vitesse(base, t, force):
    dr = ImageDraw.Draw(base, "RGBA")
    rng = random.Random(int(t * FPS))
    for _ in range(26):
        a = rng.uniform(0, 2 * math.pi)
        r1 = rng.uniform(380, 700); r2 = r1 + rng.uniform(250, 700)
        cx, cy = W / 2, H * 0.45
        w = rng.choice([2, 3, 4, 6])
        dr.line([(cx + math.cos(a) * r1, cy + math.sin(a) * r1), (cx + math.cos(a) * r2, cy + math.sin(a) * r2)],
                fill=(255, 255, 255, int(rng.uniform(40, 110) * force)), width=w)

def coup_de_sabre(base, t):
    for c in COUPES:
        u = (t - c + 0.10) / 0.22          # balaye de -0,10 s a +0,12 s autour de la coupe
        if 0 <= u <= 1:
            dr = ImageDraw.Draw(base, "RGBA")
            x = -600 + u * (W + 1200)
            ep = 140 * math.sin(math.pi * u)
            pts = [(x - 500, H + 200), (x + 500, -200), (x + 500 + ep, -200), (x - 500 + ep, H + 200)]
            dr.polygon(pts, fill=ROUGE + (230,))
            dr.line([(x - 500 + ep / 2, H + 200), (x + 500 + ep / 2, -200)], fill=(255, 255, 255, 255), width=max(2, int(ep / 10)))

def post(im, t):
    imp = impact(t)
    battement = math.exp(-((t % BEAT)) * 10) * 0.015
    z = 1 + 0.07 * imp + battement
    rng = random.Random(int(t * FPS) * 7 + 1)
    dx = rng.uniform(-1, 1) * 26 * imp
    dy = rng.uniform(-1, 1) * 26 * imp
    if z > 1.001 or abs(dx) > 0.5:
        ww, hh = int(W * z), int(H * z)
        big = im.resize((ww, hh), Image.BILINEAR)
        ox = int((ww - W) / 2 + dx); oy = int((hh - H) / 2 + dy)
        ox = max(0, min(ww - W, ox)); oy = max(0, min(hh - H, oy))
        im = big.crop((ox, oy, ox + W, oy + H))
    if imp > 0.15:
        a = np.asarray(im).copy()
        d = int(14 * imp)
        a[:, d:, 0] = a[:, :-d, 0]
        a[:, :-d, 2] = a[:, d:, 2]
        im = Image.fromarray(a)
    return im

# ------------------------------------------------------------------ son : ambiance japonaise (taiko, shakuhachi, koto, sabre)
def audio(path):
    sr = 44100
    n = int(DUREE * sr)
    s = np.zeros(n, np.float32)
    rng = np.random.default_rng(7)
    def ajout(t, sig, g=1.0):
        i = int(t * sr)
        if i >= n or i < 0: return
        j = min(n, i + len(sig))
        s[i:j] += (sig[: j - i] * g).astype(np.float32)
    def env(d, a=0.005, r=4.0):
        t = np.arange(int(d * sr)) / sr
        return t, np.minimum(1, t / a) * np.exp(-t * r)
    # taiko grave (don), taiko aigu (ka = bord du tambour)
    t, e = env(1.0, 0.002, 4.5)
    don = (np.sin(2 * np.pi * (62 + 45 * np.exp(-t * 14)) * t) * 1.0 + np.sin(2 * np.pi * 124 * t) * 0.15 * np.exp(-t * 9)) * e \
        + rng.normal(0, 1, len(t)) * np.exp(-t * 45) * 0.25
    t, e = env(0.12, 0.001, 38)
    ka = (np.sin(2 * np.pi * 820 * t) * 0.5 + rng.normal(0, 1, len(t)) * 0.4) * e * 0.35
    t, e = env(1.6, 0.002, 2.2)
    odaiko = np.sin(2 * np.pi * (44 + 30 * np.exp(-t * 10)) * t) * e * 1.3 + rng.normal(0, 1, len(t)) * np.exp(-t * 25) * 0.35
    # koto : corde pincee (Karplus-Strong)
    def koto(f, d=1.6, g=0.22):
        N = int(sr / f); buf = rng.uniform(-1, 1, N).astype(np.float32)
        out = np.zeros(int(d * sr), np.float32)
        for k in range(len(out)):
            out[k] = buf[k % N]
            buf[k % N] = 0.996 * 0.5 * (buf[k % N] + buf[(k + 1) % N])
        return out * g
    # shakuhachi : souffle + vibrato + attaque bruitee
    def shaku(f, d, g=0.13):
        t = np.arange(int(d * sr)) / sr
        vib = 1 + 0.012 * np.sin(2 * np.pi * 5.2 * t) * np.minimum(1, t / 0.5)
        ph = 2 * np.pi * np.cumsum(f * vib) / sr
        en = np.minimum(1, t / 0.12) * np.minimum(1, (d - t) / 0.25)
        souffle = rng.normal(0, 1, len(t)) * 0.35
        souffle = np.convolve(souffle, np.ones(6) / 6, mode="same")
        sig = (np.sin(ph) + 0.25 * np.sin(2 * ph) + 0.08 * np.sin(3 * ph)) * en + souffle * en * 0.5
        att = rng.normal(0, 1, len(t)) * np.exp(-t * 25) * 0.6
        return (sig + att) * g
    # gamme japonaise "in" sur re : re mib sol la sib
    IN = [293.66, 311.13, 392.0, 440.0, 466.16, 587.33, 622.25, 783.99]
    # bruit de sabre (shing metallique) pour les transitions
    def sabre():
        t = np.arange(int(1.1 * sr)) / sr
        sig = sum(np.sin(2 * np.pi * f * t) * np.exp(-t * dcy) for f, dcy in [(3150, 4.5), (4720, 6), (6230, 8), (2380, 5)])
        sw = rng.normal(0, 1, len(t)) * np.exp(-((t - 0.05) / 0.06) ** 2) * 0.5
        return (sig * 0.07 + sw * 0.25) * np.minimum(1, t / 0.01)
    SAB = sabre()
    # rythme : don . ka don | don ka ka . (sur 2 temps de 0,5 s)
    pas = BEAT / 2
    motif = ["D", "K", "K", "D", "D", "K", "D", "K"]
    k = 0; tt = T_TITRE
    while tt < DUREE - 2.0:
        m = motif[k % len(motif)]
        if m == "D": ajout(tt, don, 0.8)
        elif m == "K": ajout(tt, ka)
        k += 1; tt += pas
    # intro : 3 coups d'odaiko espaces + shakuhachi seul
    for c in HOOK + [1.5]: ajout(c, odaiko, 0.9)
    ajout(0.15, shaku(IN[0] * 2, 2.8, 0.16))
    for c in COUPES:
        ajout(c, odaiko, 0.8)
        ajout(c - 0.05, SAB)
    # koto : arpege toutes les mesures
    arp = [0, 2, 3, 5, 3, 2]
    b = T_TITRE; m = 0
    while b < DUREE - 2.5:
        racine = [0, 0, 2, 1][m % 4]
        for q, idx in enumerate(arp):
            ajout(b + q * pas / 1.5, koto(IN[(idx + racine) % len(IN)] / 2))
        b += BEAT * 4; m += 1
    # melodie de shakuhachi par phrases
    phrase = [(5, 1.0), (6, 0.5), (5, 0.5), (3, 1.5), (4, 0.5), (3, 1.0), (2, 1.0), (0, 2.0)]
    b = T_TITRE + 1.0
    while b < DUREE - 3:
        for idx, dd in phrase:
            if b + dd > DUREE - 2: break
            ajout(b, shaku(IN[idx], dd * 1.05))
            b += dd
        b += 1.0
    # bourdon grave
    ta = np.arange(n) / sr
    s += (np.sin(2 * np.pi * 73.42 * ta) * 0.05 + np.sin(2 * np.pi * 110 * ta) * 0.025).astype(np.float32)
    # final : gros coup + gong
    ajout(DUREE - 2.2, odaiko, 1.0)
    tg = np.arange(int(2.0 * sr)) / sr
    gong = sum(np.sin(2 * np.pi * f * tg) * np.exp(-tg * 1.4) for f in (196, 293.66, 415.3)) * 0.07
    ajout(DUREE - 2.2, gong)
    fo = int(1.2 * sr)
    s[-fo:] *= np.linspace(1, 0, fo)
    s = np.tanh(s * 1.3) * 0.88
    with wave.open(path, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr); w.writeframes((s * 32767).astype(np.int16).tobytes())

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == "apercu":
        for t in [0.55, 2.6, 4.05, 4.7, 9.0, 15.0]:
            frame(t).resize((540, 960)).save(OUT + "apercu_%04.1f.png" % t)
        sys.exit()
    audio(OUT + "son.wav")
    p = subprocess.Popen(["ffmpeg", "-y", "-loglevel", "error", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-",
                          "-i", OUT + "son.wav", "-c:v", "libx264", "-preset", "medium", "-crf", "20", "-pix_fmt", "yuv420p",
                          "-c:a", "aac", "-b:a", "160k", "-shortest", "-movflags", "+faststart", OUT + "TFJ_tiktok.mp4"], stdin=subprocess.PIPE)
    for f in range(int(DUREE * FPS)):
        p.stdin.write(frame(f / FPS).tobytes())
    p.stdin.close(); p.wait()
    print("ok")
