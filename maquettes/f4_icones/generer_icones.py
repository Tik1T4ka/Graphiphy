import math, random
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops
random.seed(7)
OUT="img/"
SS=4
KF="/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc"
W=(255,255,255,255)

def fin(im, size):
    return im.resize((size,size), Image.LANCZOS)

def canvas(n=128):
    im=Image.new("RGBA",(n*SS,n*SS),(0,0,0,0)); return im, ImageDraw.Draw(im), n*SS

def poly_rot(cx,cy,pts,a):
    c,s=math.cos(a),math.sin(a)
    return [(cx+x*c-y*s, cy+x*s+y*c) for x,y in pts]

# ---------- icones d'onglets (blanches, teintees en jeu)
def ico_natures():
    im,d,N=canvas(); c=N/2
    # trois magatama tournants (cycle des elements)
    for k in range(3):
        a=k*2*math.pi/3 - math.pi/2
        hx,hy=c+math.cos(a)*N*0.22, c+math.sin(a)*N*0.22
        r=N*0.13
        d.ellipse([hx-r,hy-r,hx+r,hy+r],fill=W)
        # queue
        pts=[]
        for t in range(0,41):
            u=t/40; ang=a+math.pi/2+u*1.9
            rr=r*(1-u)
            px=c+math.cos(a+u*1.9)*N*0.22*(1+0.35*u)
            py=c+math.sin(a+u*1.9)*N*0.22*(1+0.35*u)
            pts.append((px,py,rr))
        for px,py,rr in pts: d.ellipse([px-rr,py-rr,px+rr,py+rr],fill=W)
    r=N*0.07; d.ellipse([c-r,c-r,c+r,c+r],fill=W)
    return im
def ico_styles():
    im,d,N=canvas(); c=N/2
    # deux katanas croises
    for a in (math.radians(45), math.radians(135)):
        L=N*0.44
        blade=[(-L,-N*0.04),(L*0.6,-N*0.05),(L,0),(L*0.6,N*0.05),(-L*0.25,N*0.05),(-L,N*0.04)]
        d.polygon(poly_rot(c,c,blade,a),fill=W)
        # tsuba
        tx,ty=c+math.cos(a)*-L*0.32, c+math.sin(a)*-L*0.32
        poly=poly_rot(tx,ty,[(-N*0.03,-N*0.11),(N*0.03,-N*0.11),(N*0.03,N*0.11),(-N*0.03,N*0.11)],a)
        d.polygon(poly,fill=W)
    return im
def ico_classes():
    im,d,N=canvas(); c=N/2
    # masque d'anbu stylise
    d.ellipse([N*0.2,N*0.1,N*0.8,N*0.92],fill=W)
    E=(0,0,0,0)
    d.polygon([(N*0.3,N*0.42),(N*0.45,N*0.38),(N*0.46,N*0.48),(N*0.32,N*0.5)],fill=E)
    d.polygon([(N*0.7,N*0.42),(N*0.55,N*0.38),(N*0.54,N*0.48),(N*0.68,N*0.5)],fill=E)
    d.line([(N*0.5,N*0.14),(N*0.5,N*0.3)],fill=E,width=int(N*0.035))
    d.line([(N*0.36,N*0.62),(N*0.42,N*0.78)],fill=E,width=int(N*0.03))
    d.line([(N*0.64,N*0.62),(N*0.58,N*0.78)],fill=E,width=int(N*0.03))
    return im
def ico_clans():
    im,d,N=canvas(); c=N/2
    # eventail (uchiwa) : disque + manche
    d.rounded_rectangle([c-N*0.05,N*0.55,c+N*0.05,N*0.94],radius=N*0.04,fill=W)
    d.ellipse([N*0.16,N*0.06,N*0.84,N*0.66],fill=W)
    E=(0,0,0,0)
    # bande rouge -> creux en bas du disque
    d.chord([N*0.22,N*0.12,N*0.78,N*0.6],0,180,fill=E)
    d.ellipse([N*0.24,N*0.14,N*0.76,N*0.58],outline=E,width=int(N*0.035))
    return im
def ico_kekkei():
    im,d,N=canvas(); c=N/2
    E=(0,0,0,0)
    # oeil en amande + pupille a trois tomoe
    pts=[]
    for t in range(0,181):
        u=math.radians(t*2)
        x=c+math.cos(u)*N*0.46
        y=c+math.sin(u)*N*0.26*(1 if math.sin(u)>0 else 1)
        pts.append((x,y))
    d.polygon(pts,fill=W)
    d.ellipse([c-N*0.2,c-N*0.2,c+N*0.2,c+N*0.2],fill=E)
    d.ellipse([c-N*0.16,c-N*0.16,c+N*0.16,c+N*0.16],fill=W)
    r=N*0.035; d.ellipse([c-r,c-r,c+r,c+r],fill=E)
    for k in range(3):
        a=k*2*math.pi/3-math.pi/2
        x,y=c+math.cos(a)*N*0.1,c+math.sin(a)*N*0.1
        rr=N*0.032; d.ellipse([x-rr,y-rr,x+rr,y+rr],fill=E)
        x2,y2=c+math.cos(a+0.5)*N*0.115,c+math.sin(a+0.5)*N*0.115
        d.line([(x,y),(x2,y2)],fill=E,width=int(N*0.025))
    return im
def shuriken():
    im,d,N=canvas(); c=N/2
    for k in range(4):
        a=k*math.pi/2
        pts=[(0,-N*0.08),(N*0.47,0),(0,N*0.08)]
        p=poly_rot(c,c,[(0,-N*0.1),(N*0.25,-N*0.05),(N*0.48,0),(N*0.2,N*0.08),(0,N*0.1)],a)
        d.polygon(p,fill=W)
    d.ellipse([c-N*0.14,c-N*0.14,c+N*0.14,c+N*0.14],fill=W)
    r=N*0.05; d.ellipse([c-r,c-r,c+r,c+r],fill=(0,0,0,0))
    return im

def brush(im, rough=1.0):
    # bord rugueux facon pinceau / tampon
    a=im.split()[3]
    n=Image.effect_noise(a.size, 60).convert("L")
    n=n.filter(ImageFilter.GaussianBlur(2*rough))
    a2=ImageChops.multiply(a, n.point(lambda v: 255 if v>70 else int(v*3.6)))
    a2=a2.filter(ImageFilter.GaussianBlur(1))
    im.putalpha(a2); return im

def kanji_img(ch, n=512, rough=True):
    im=Image.new("RGBA",(n,n),(0,0,0,0)); d=ImageDraw.Draw(im)
    f=ImageFont.truetype(KF, int(n*0.86))
    d.text((n/2,n/2),ch,font=f,fill=W,anchor="mm")
    a=im.split()[3].filter(ImageFilter.MaxFilter(9))  # traits plus epais facon pinceau
    im.putalpha(a)
    if rough: brush(im,2.0)
    return im

def sceau(ch, n=96):
    N=n*SS
    im=Image.new("RGBA",(N,N),(0,0,0,0)); d=ImageDraw.Draw(im)
    R=(170,24,24,255)
    d.rounded_rectangle([N*0.04,N*0.04,N*0.96,N*0.96],radius=N*0.12,fill=R)
    CR=(242,242,242,255)
    d.rounded_rectangle([N*0.11,N*0.11,N*0.89,N*0.89],radius=N*0.08,outline=CR,width=int(N*0.03))
    f=ImageFont.truetype(KF,int(N*0.6))
    m=Image.new("L",(N,N),0); ImageDraw.Draw(m).text((N/2,N/2+N*0.02),ch,font=f,fill=255,anchor="mm")
    m=m.filter(ImageFilter.MaxFilter(11))
    im.paste(Image.new("RGBA",(N,N),(242,242,242,255)),(0,0),m)
    # grain d'encre du tampon
    n2=Image.effect_noise((N,N),90).convert("L").filter(ImageFilter.GaussianBlur(3)).point(lambda v: 0 if v<62 else 255)
    im.putalpha(ImageChops.multiply(im.split()[3],n2))
    return im.resize((n,n),Image.LANCZOS)

icons={"onglet_natures":ico_natures,"onglet_styles":ico_styles,"onglet_classes":ico_classes,"onglet_clans":ico_clans,"onglet_kekkei":ico_kekkei,"shuriken":shuriken}
for k,f in icons.items(): fin(f(),96).save(OUT+k+".png",optimize=True)
kanji_img("忍",384).resize((256,256),Image.LANCZOS).save(OUT+"filigrane.png",optimize=True)
SC={"suiton":"水","futon":"風","raiton":"雷","doton":"土","katon":"火","taijutsu":"体","kenjutsu":"剣",
    "guerrier":"戦","robustesse":"鋼","mirage":"幻","medicale":"医","clan":"族","kekkei":"血","shinobi":"忍"}
for k,ch in SC.items(): sceau(ch,80).save(OUT+"sceau_"+k+".png",optimize=True)
# grain (texture de fond facon papier sombre)
g=Image.effect_noise((128,128),40).convert("L").point(lambda v: max(0,min(255,(v-128)*2+128)))
Image.merge("RGBA",(g,g,g,Image.new("L",(128,128),255))).save(OUT+"grain.png",optimize=True)
# planche de controle
names=list(icons)+["filigrane"]+["sceau_"+k for k in SC]
sheet=Image.new("RGBA",(110*7,110*3),(30,25,20,255))
for i,nm in enumerate(names):
    im=Image.open(OUT+nm+".png").convert("RGBA").resize((96,96))
    sheet.alpha_composite(im,((i%7)*110+7,(i//7)*110+7))
sheet.save("planche.png")
