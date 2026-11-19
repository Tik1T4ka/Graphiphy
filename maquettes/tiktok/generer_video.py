#!/usr/bin/env python3
# Video TikTok TFJ - Naruto RP (1080x1920, 30 fps) : style rouge / noir des menus TFJ
import math, random, subprocess, wave, os
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

W, H, FPS = 1080, 1920, 30
DUREE = 30.0
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
    ("CLAN KIOKI", "Nouveau clan · 5 techniques", ["Ailes de l'Envol : vole au combat", "Prison du temps : fige tes ennemis"], KIO + "kioki_ailes_ascension.png"),
    ("DASH CHAKRA", "Combat plus nerveux", ["Esquive + saut de chakra", "Contrôle total dans les airs"], ICO + "shuriken.png"),
    ("SYSTÈME MÉDICAL", "Le RP médecin prend vie", ["Groupes sanguins par personnage", "Dons de sang et transfusions"], ICO + "sceau_medicale.png"),
    ("EXÉCUTIONS", "Mises à mort cinématiques", ["Décapitations au ralenti", "Animation du bourreau au sabre"], ICO + "sceau_kenjutsu.png"),
    ("COFFRES À CODE", "Protège ton butin", ["Inventaire en glisser-déposer", "Code secret à 4 chiffres"], ICO + "sceau_shinobi.png"),
    ("ARBRE DE TECHNIQUES", "Nouvelle interface F4", ["Style ninja, sceaux et parchemins", "Rinnegan désormais disponible"], ICO + "onglet_kekkei.png"),
    ("XP x6", "Monte en rang à toute vitesse", ["Gain d'expérience multiplié par 6", "Grades VIP 1 et VIP 2 disponibles"], ICO + "sceau_kekkei.png"),
]
T_INTRO, T_TITRE = 0.0, 3.0
T_CARTES = 6.0
D_CARTE = 2.5
T_FIN = T_CARTES + D_CARTE * len(NOUVEAUTES)   # 23.5
COUPES = [T_TITRE, T_CARTES] + [T_CARTES + i * D_CARTE for i in range(1, len(NOUVEAUTES))] + [T_FIN]

# pre-rendus
C_HOOK1 = calque_texte("TON VILLAGE", ANTON(150), BLANC, glow=ROUGE)
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
    ic = img(n[3], 300)
    if "shuriken" in n[3] or "onglet" in n[3]: ic = teinte(ic, ROUGE)
    ICONES.append(ic)
SHUR = teinte(img(ICO + "shuriken.png", 220), ROUGE)
C_REJ = calque_texte("REJOINS-NOUS", ANTON(150), BLANC, glow=ROUGE)
C_LIEN = calque_texte(LIEN, BOLD(66), BLANC)
C_GMOD = calque_texte("SERVEUR GARRY'S MOD · NARUTO RP", BOLD(40), GRIS)

def carte(base, i, t0, t):
    """Carte facon menu 'entrainement' : coin coupe, numero en contour, puces rouges, gros bouton."""
    k = (t - t0) / D_CARTE
    e = ease(k * 3.2)
    sortie = ease((k - 0.88) * 8.5)
    x0 = 80 + (1 - e) * 900 - sortie * 1100
    y0, cw, ch = 470, 920, 1020
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
    cal.alpha_composite(TITRES[i], (int(x0 + 20), int(y0 + 105)))
    texte(cal, (x0 + 60, y0 + 270), sous, BOLD(40), ROUGE, anchor="la")
    # barre de progression
    dr.rectangle([x0 + 60, y0 + 345, x0 + cw - 60, y0 + 351], fill=(60, 60, 64, 255))
    dr.rectangle([x0 + 60, y0 + 345, x0 + 60 + (cw - 120) * ((i + 1) / len(NOUVEAUTES)), y0 + 351], fill=BLANC + (255,))
    # icone
    pop = back((k - 0.08) * 4)
    coller(cal, ICONES[i], x0 + cw / 2, y0 + 560, 0.95 * pop, 1.0, rot=(t * 40 % 360) if "shuriken" in NOUVEAUTES[i][3] else 0)
    # puces
    for j, p in enumerate(puces):
        a = ease((k - 0.18 - j * 0.1) * 5)
        yb = y0 + 760 + j * 70
        losange(dr, x0 + 75, yb, 11, ROUGE + (int(255 * a),))
        texte(cal, (x0 + 105 + (1 - a) * 40, yb), p, MED(40), BLANC, anchor="lm", alpha=int(255 * a))
    # bouton
    bx, by = x0 + 60, y0 + ch - 130
    dr.rectangle([bx, by, x0 + cw - 60, by + 92], fill=ROUGE + (255,))
    texte(cal, ((bx + x0 + cw - 60) / 2, by + 46), "À DÉCOUVRIR EN JEU", ANTON(52), BLANC)
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
        k = t / T_TITRE
        coller(base, C_HOOK1, W / 2, 820, back(k * 3) * 1.0, ease(k * 4))
        coller(base, C_HOOK2, W / 2, 1010, back((k - 0.25) * 3), ease((k - 0.25) * 4), rot=-3)
        coller(base, SHUR, W / 2, 1320, ease((k - 0.45) * 3) * 0.8, ease((k - 0.45) * 3), rot=t * 300)
    elif t < T_CARTES:
        k = (t - T_TITRE) / (T_CARTES - T_TITRE)
        entete(base, t)
        coller(base, C_TFJ, W / 2, 700, back(k * 3.5), ease(k * 4))
        coller(base, C_NRP, W / 2, 920, back((k - 0.15) * 3.5), ease((k - 0.15) * 4))
        dr = ImageDraw.Draw(base)
        lw = 520 * ease((k - 0.3) * 3)
        dr.rectangle([W / 2 - lw, 1040, W / 2 + lw, 1046], fill=ROUGE + (255,))
        coller(base, C_NOUV, W / 2, 1180, back((k - 0.4) * 3.5), ease((k - 0.4) * 4))
        coller(base, C_SEM, W / 2, 1320, back((k - 0.5) * 3.5), ease((k - 0.5) * 4))
    elif t < T_FIN:
        entete(base, t)
        i = min(int((t - T_CARTES) / D_CARTE), len(NOUVEAUTES) - 1)
        carte(base, i, T_CARTES + i * D_CARTE, t)
        # points de progression
        dr = ImageDraw.Draw(base)
        for j in range(len(NOUVEAUTES)):
            losange(dr, W / 2 + (j - 3) * 46, 1580, 10 if j == i else 7, (ROUGE if j <= i else (80, 80, 85)) + (255,))
    else:
        k = (t - T_FIN) / (DUREE - T_FIN)
        entete(base, t)
        coller(base, C_REJ, W / 2, 640, back(k * 5), ease(k * 6))
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
        coller(base, bt, W / 2, 1060, back((k - 0.15) * 4) * p, a)
        texte(base, (W / 2, 1290), "Lien aussi en bio", BOLD(44), BLANC, alpha=int(255 * ease((k - 0.3) * 5)))
        texte(base, (W / 2, 1360), "XP x6 · Clan Kioki · VIP", BOLD(40), ROUGE, alpha=int(255 * ease((k - 0.4) * 5)))
        coller(base, C_GMOD, W / 2, 1450, 1, ease((k - 0.5) * 5))
    # vignette
    return base.convert("RGB")

# ------------------------------------------------------------------ son : rythme 120 BPM + impacts aux transitions
def audio(path):
    sr = 44100
    n = int(DUREE * sr)
    s = np.zeros(n, np.float32)
    rng = np.random.default_rng(1)
    def ajout(t, sig):
        i = int(t * sr)
        j = min(n, i + len(sig))
        if i < n: s[i:j] += sig[: j - i]
    tt = np.arange(int(0.45 * sr)) / sr
    kick = np.sin(2 * np.pi * (45 + 110 * np.exp(-tt * 28)) * tt) * np.exp(-tt * 7) * 0.9
    th = np.arange(int(0.05 * sr)) / sr
    hat = rng.normal(0, 1, len(th)) * np.exp(-th * 90) * 0.12
    hat = np.diff(np.concatenate([[0], hat])).astype(np.float32)
    tc = np.arange(int(0.25 * sr)) / sr
    clap = rng.normal(0, 1, len(tc)) * np.exp(-tc * 22) * 0.25
    tk = np.arange(int(1.2 * sr)) / sr
    taiko = (np.sin(2 * np.pi * (70 + 40 * np.exp(-tk * 10)) * tk) * np.exp(-tk * 3.5) * 1.1
             + rng.normal(0, 1, len(tk)) * np.exp(-tk * 30) * 0.3)
    b = 0.0
    while b < DUREE - 0.2:
        beat_i = int(round(b / BEAT))
        if b >= T_TITRE - 0.01 and b < DUREE - 1.5:
            ajout(b, kick)
            if beat_i % 2 == 1: ajout(b, clap)
        ajout(b + BEAT / 2, hat)
        b += BEAT
    for c in [0.0] + COUPES:
        ajout(c, taiko)
        tw = np.arange(int(0.35 * sr)) / sr
        wh = rng.normal(0, 1, len(tw)) * np.sin(np.pi * tw / tw[-1]) * 0.18
        ajout(max(0, c - 0.3), wh)
    # nappe grave (re mineur) + petite melodie de flute pentatonique
    t_all = np.arange(n) / sr
    for f in (73.42, 110.0, 146.83):
        s += (np.sin(2 * np.pi * f * t_all) * 0.05 * (0.6 + 0.4 * np.sin(2 * np.pi * t_all / 8))).astype(np.float32)
    notes = [587.33, 698.46, 783.99, 880.0, 1046.5, 880.0, 783.99, 698.46]
    tn = np.arange(int(0.45 * sr)) / sr
    env = np.minimum(1, tn * 30) * np.exp(-tn * 4)
    for k in range(int(DUREE / BEAT)):
        if k % 2 == 0 and T_TITRE <= k * BEAT < DUREE - 1:
            f = notes[(k // 2) % len(notes)]
            fl = (np.sin(2 * np.pi * f * tn) + 0.3 * np.sin(4 * np.pi * f * tn)) * env * 0.08
            ajout(k * BEAT, fl.astype(np.float32))
    # fondu de fin
    fo = int(1.5 * sr)
    s[-fo:] *= np.linspace(1, 0, fo)
    s = np.tanh(s * 1.4) * 0.85
    pcm = (s * 32767).astype(np.int16)
    with wave.open(path, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr); w.writeframes(pcm.tobytes())

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == "apercu":
        for t in [5.5, 12.0, 17.0, 20.0, 22.0, 29.0]:
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
