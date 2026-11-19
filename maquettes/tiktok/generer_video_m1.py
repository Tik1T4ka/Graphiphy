#!/usr/bin/env python3
# Video TikTok "Les M1 de chaque clan" a partir du clip Medal (1920x1080 60 fps)
import math, os, subprocess, wave, random
import numpy as np
from PIL import Image, ImageDraw
import generer_video as V   # reutilise le style (fond, polices, slams, coups de sabre...)

ICI = os.path.dirname(os.path.abspath(__file__)) + "/"
CLIP = ICI + "../medal/clip.mp4"
W, H, FPS = V.W, V.H, V.FPS

# (clan, effet en plus, [(debut, fin)...] dans le clip, centre x du personnage)
CLANS = [
    ("SENJU",    "Régénère sa vie à chaque coup",      [(41.3, 45.3)], 950),
    ("UCHIHA",   "Flammes + brûlure sur la durée",      [(54.4, 57.9)], 950),
    ("HYUGA",    "Vole du chakra à chaque coup",       [(68.7, 72.1)], 960),
    ("ABURAME",  "Nuée d'insectes sur la cible",        [(88.3, 91.8)], 950),
    ("ENSHO",    "Futon amélioré : tornade de vent",   [(104.6, 106.2), (107.9, 109.0)], 950),
    ("MUGEN",    "Explosion d'ombre à 70 dégâts",       [(124.5, 126.3), (128.5, 129.7)], 960),
    ("AYATSURI", "Marionnette et fils de chakra",       [(137.25, 140.75)], 900),
    ("JISHAKU",  "Sable doré magnétique",               [(157.2, 160.9)], 950),
]
T_INTRO = 2.5
FIN = 4.0
# durees
for c in CLANS:
    pass
DUR_CLANS = [sum(b - a for a, b in c[2]) for c in CLANS]
DEBUTS = []
t = T_INTRO
for d in DUR_CLANS:
    DEBUTS.append(t); t += d
T_FIN = t
DUREE = T_FIN + FIN

# ------------------------------------------------------------------ extraction des images du clip (recadrees en 9:16)
CW = 556  # largeur recadree dans la source (556x988, sans la barre de raccourcis du jeu)
def extraire():
    os.makedirs(ICI + "m1_frames", exist_ok=True)
    k = 0
    for ci, (nom, _, morceaux, cx) in enumerate(CLANS):
        for (a, b) in morceaux:
            x = max(0, min(1920 - CW, cx - CW // 2))
            d = ICI + f"m1_frames/{ci}_{a:.2f}"
            os.makedirs(d, exist_ok=True)
            if not os.listdir(d):
                subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-ss", str(a), "-to", str(b), "-i", CLIP,
                                "-vf", f"fps={FPS},crop={CW}:988:{x}:0,scale={W}:{H}:flags=lanczos,eq=contrast=1.06:saturation=1.15",
                                "-q:v", "3", d + "/%04d.jpg"], check=True)
def extraire_barre():
    d = ICI + "m1_barre"
    os.makedirs(d, exist_ok=True)
    if not os.listdir(d):
        a, b = CLANS[0][2][0]
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-ss", str(a), "-to", str(b), "-i", CLIP,
                        "-vf", f"fps={FPS},crop=240:32:162:963,scale=900:120:flags=lanczos", "-q:v", "2", d + "/%04d.jpg"], check=True)
    return [d + "/" + f for f in sorted(os.listdir(d))]
BARRE = []

def images_clan(ci):
    out = []
    for (a, b) in CLANS[ci][2]:
        d = ICI + f"m1_frames/{ci}_{a:.2f}"
        out += [d + "/" + f for f in sorted(os.listdir(d))]
    return out

# ------------------------------------------------------------------ habillage
NOMS = {}
SOUS = {}
def prerendus():
    for i, (nom, eff, _, _) in enumerate(CLANS):
        NOMS[i] = V.calque_texte(nom, V.ANTON(150), V.BLANC, glow=V.ROUGE)
C_TITRE1 = V.calque_texte("LES M1", V.ANTON(230), V.BLANC, glow=V.ROUGE)
C_TITRE2 = V.calque_texte("DE CHAQUE CLAN", V.ANTON(120), V.ROUGE, glow=V.ROUGE)

def degrade_haut_bas(base):
    # assombrit le haut et le bas pour lire le texte
    a = np.zeros((H, 1), np.float32)
    y = np.arange(H)
    a[:, 0] = np.clip((640 - y) / 300, 0, 1) * 0.97 + np.clip((y - (H - 520)) / 520, 0, 1) * 0.9
    ov = Image.fromarray((np.repeat(a, W, 1) * 255).astype(np.uint8))
    base.paste((0, 0, 0), (0, 0), ov)

def habillage(base, i, t0, t):
    k = t - t0
    degrade_haut_bas(base)
    dr = ImageDraw.Draw(base)
    V.entete(base, t)
    # numero + nom du clan
    V.texte(base, (80, 300), "CLAN %02d / %02d" % (i + 1, len(CLANS)), V.BOLD(38), V.ROUGE, anchor="lm")
    sc, al = V.slam(t, t0, 2.2)
    if al > 0:
        n = NOMS[i]
        im = n.resize((max(1, int(n.width * sc)), max(1, int(n.height * sc))))
        if al < 1: im.putalpha(im.split()[3].point(lambda v: int(v * al)))
        base.alpha_composite(im, (int(80 - 40), int(400 - im.height / 2)))
    dr.rectangle([80, 490, 80 + 380 * V.ease(k * 5), 496], fill=V.ROUGE + (255,))
    # bandeau du bas : l'effet en plus
    a = V.ease((k - 0.3) * 5)
    if a > 0:
        y = H - 330
        bw = 920
        x = (W - bw) / 2 + (1 - a) * 200
        dr.polygon([(x, y), (x + bw - 40, y), (x + bw, y + 40), (x + bw, y + 150), (x, y + 150)], fill=(10, 10, 12, int(230 * a)))
        dr.line([(x, y), (x + bw - 40, y), (x + bw, y + 40), (x + bw, y + 150), (x, y + 150), (x, y)], fill=V.ROUGE + (int(255 * a),), width=4)
        V.texte(base, (x + 40, y + 45), "EN PLUS", V.BOLD(32), V.GRIS, anchor="lm", alpha=int(255 * a))
        V.losange(dr, x + 52, y + 102, 11, V.ROUGE + (int(255 * a),))
        V.texte(base, (x + 80, y + 102), CLANS[i][1], V.BOLD(46), V.BLANC, anchor="lm", alpha=int(255 * a))
    # Senju : zoom sur la barre de vie qui remonte
    if i == 0 and BARRE:
        a2 = V.ease((k - 0.2) * 5)
        n = min(int(k * FPS), len(BARRE) - 1)
        bar = Image.open(BARRE[n]).convert("RGBA")
        x, y = 90 + (1 - a2) * -300, 620
        dr.rectangle([x - 14, y - 70, x + 900 + 14, y + 120 + 14], fill=(10, 10, 12, int(225 * a2)), outline=V.ROUGE + (int(255 * a2),), width=4)
        V.texte(base, (x + 6, y - 36), "BARRE DE VIE", V.BOLD(34), V.GRIS, anchor="lm", alpha=int(255 * a2))
        pulse = 0.5 + 0.5 * math.sin(t * 2 * math.pi * 2)
        V.texte(base, (x + 900, y - 36), "+ PV À CHAQUE COUP", V.ANTON(44), (90, 220, 110), anchor="rm", alpha=int(255 * a2 * (0.6 + 0.4 * pulse)))
        if a2 > 0.02:
            if a2 < 1: bar.putalpha(int(255 * a2))
            base.alpha_composite(bar, (int(x), int(y)))
    # points de progression
    for j in range(len(CLANS)):
        V.losange(dr, W / 2 + (j - 3.5) * 46, H - 110, 10 if j == i else 7, (V.ROUGE if j <= i else (80, 80, 85)) + (255,))

# ------------------------------------------------------------------ rendu
COUPES = [T_INTRO] + DEBUTS[1:] + [T_FIN]
V.COUPES = COUPES
V.IMPACTS = [0.0, 0.6] + DEBUTS + [T_FIN, T_FIN + 0.5]

def frame(fi, cache):
    t = fi / FPS
    if t < T_INTRO:
        base = V.fond_frame(t, 0)
        V.coller(base, V.FILI, W / 2, H * 0.52, 1.0, 0.12)
        V.braises(ImageDraw.Draw(base, "RGBA"), t)
        V.lignes_vitesse(base, t, 0.7)
        sc, al = V.slam(t, 0.0, 2.6); V.coller(base, C_TITRE1, W / 2, 800, sc, al)
        sc, al = V.slam(t, 0.6, 2.2); V.coller(base, C_TITRE2, W / 2, 1010, sc, al)
        sc, al = V.slam(t, 1.2, 1.8); V.coller(base, V.calque_texte("TFJ · NARUTO RP", V.BOLD(46), V.GRIS), W / 2, 1150, sc, al)
    elif t < T_FIN:
        i = max(j for j in range(len(CLANS)) if DEBUTS[j] <= t)
        imgs = cache.setdefault(i, images_clan(i))
        n = int((t - DEBUTS[i]) * FPS)
        base = Image.open(imgs[min(n, len(imgs) - 1)]).convert("RGBA")
        habillage(base, i, DEBUTS[i], t)
    else:
        # ecran final (reprend celui de la video des nouveautes)
        tt = V.T_FIN + (t - T_FIN)
        base = V.fond_frame(t, 0)
        V.coller(base, V.FILI, W / 2, H * 0.52, 1.0, 0.16)
        V.braises(ImageDraw.Draw(base, "RGBA"), t)
        V.lignes_vitesse(base, t, 0.35)
        V.entete(base, t)
        sc, al = V.slam(t, T_FIN, 2.6); V.coller(base, V.C_REJ, W / 2, 640, sc, al)
        V.texte(base, (W / 2, 790), "Choisis ton clan et rejoins le village", V.MED(42), V.GRIS, alpha=int(255 * V.ease((t - T_FIN - 0.2) * 4)))
        p = 1 + 0.04 * math.sin(t * 2 * math.pi / V.BEAT)
        bt = Image.new("RGBA", (900, 260), (0, 0, 0, 0))
        dbt = ImageDraw.Draw(bt)
        dbt.rectangle([0, 0, 899, 259], fill=V.ROUGE + (255,))
        V.texte(bt, (450, 85), "REJOINDRE LE DISCORD", V.ANTON(70), V.BLANC)
        bt.alpha_composite(V.C_LIEN, (450 - V.C_LIEN.width // 2, 175 - V.C_LIEN.height // 2))
        sc, al = V.slam(t, T_FIN + 0.5, 1.8); V.coller(base, bt, W / 2, 1060, sc * p, al)
        V.texte(base, (W / 2, 1290), "Lien aussi en bio", V.BOLD(44), V.BLANC, alpha=int(255 * V.ease((t - T_FIN - 0.8) * 4)))
        V.texte(base, (W / 2, 1360), "8 clans jouables · Naruto RP · Garry's Mod", V.BOLD(40), V.ROUGE, alpha=int(255 * V.ease((t - T_FIN - 1.0) * 4)))
    V.coup_de_sabre(base, t)
    return V.post(base.convert("RGB"), t)

def audio(path):
    # musique ninja calme (generateur de video.py) + sons du jeu de chaque passage
    V.DUREE = DUREE; V.T_TITRE = T_INTRO; V.COUPES = COUPES; V.HOOK = [0.0, 0.6, 1.2]
    V.audio(ICI + "m1_musique.wav")
    sr = 44100
    with wave.open(ICI + "m1_musique.wav") as w:
        mus = np.frombuffer(w.readframes(w.getnframes()), np.int16).astype(np.float32) / 32767
    jeu = np.zeros_like(mus)
    t = T_INTRO
    for (nom, _, morceaux, _) in CLANS:
        for (a, b) in morceaux:
            raw = subprocess.run(["ffmpeg", "-loglevel", "error", "-ss", str(a), "-to", str(b), "-i", CLIP, "-map", "0:a:0",
                                  "-ac", "1", "-ar", str(sr), "-f", "s16le", "-"], capture_output=True, check=True).stdout
            x = np.frombuffer(raw, np.int16).astype(np.float32) / 32767
            i0 = int(t * sr); j = min(len(jeu), i0 + len(x))
            fade = np.minimum(1, np.minimum(np.arange(j - i0), (j - i0) - np.arange(j - i0)) / (0.04 * sr))
            jeu[i0:j] += x[: j - i0] * fade
            t += b - a
    jeu = jeu / max(1e-6, np.abs(jeu).max()) * 0.9
    s = mus * 0.55 + jeu * 0.75
    s = np.tanh(s / max(1e-6, np.abs(s).max()) * 1.2) * 0.9
    with wave.open(path, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr); w.writeframes((s * 32767).astype(np.int16).tobytes())

if __name__ == "__main__":
    import sys
    extraire(); prerendus(); BARRE.extend(extraire_barre())
    cache = {}
    if len(sys.argv) > 1 and sys.argv[1] == "apercu":
        ts = [1.0] + [d + 0.8 for d in DEBUTS] + [T_FIN + 2.0]
        ims = [frame(int(x * FPS), cache).resize((360, 640)) for x in ts]
        pl = Image.new("RGB", (360 * 5, 640 * 2))
        for k, im in enumerate(ims): pl.paste(im, ((k % 5) * 360, (k // 5) * 640))
        pl.save(ICI + "m1_apercu.jpg", quality=85); print("duree", DUREE); sys.exit()
    audio(ICI + "m1_son.wav")
    out = ICI + "TFJ_M1_clans_brut.mp4"
    p = subprocess.Popen(["ffmpeg", "-y", "-loglevel", "error", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-",
                          "-i", ICI + "m1_son.wav", "-c:v", "libx264", "-preset", "medium", "-crf", "22", "-pix_fmt", "yuv420p",
                          "-c:a", "aac", "-b:a", "160k", "-shortest", "-movflags", "+faststart", out], stdin=subprocess.PIPE)
    for fi in range(int(DUREE * FPS)):
        p.stdin.write(frame(fi, cache).tobytes())
    p.stdin.close(); p.wait()
    print("ok", DUREE)
