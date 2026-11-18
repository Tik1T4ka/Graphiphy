-- TFJ : nouveau theme de l'arbre de competences (F4), d'apres la maquette Figma
--   https://www.figma.com/design/Hy8SdspeEFGD57xZanxw0K
-- Ce fichier ne change PAS la logique du menu (cl_nrp_skills.lua) : il habille le F4 une fois cree
-- (ronds des techniques avec leurs vraies icones, liens, cartes des arbres, onglets, points, fiche de technique).
-- Pour revenir a l'ancien affichage : tfj_f4_classique 1 dans la console (puis rouvrir le F4).
-- Fichier : garrysmod/lua/autorun/client/cl_tfj_f4_theme.lua
TFJ_F4 = TFJ_F4 or {}
local F = TFJ_F4

local cvClassique = CreateClientConVar("tfj_f4_classique", "0", true, false, "TFJ : 1 = ancien affichage du F4")

-- palette : noir, rouge, blanc
local OR = Color(236, 233, 228)          -- (blanc) techniques apprises, accents clairs
local ROUGE = Color(176, 26, 26)
local ROUGE_FONCE = Color(104, 14, 14)
local ENCRE = Color(8, 8, 8)
local GRIS = Color(74, 74, 74)
local PAPIER = Color(244, 244, 244)
local TEXTE2 = Color(150, 150, 150)
local PANNEAU = Color(11, 11, 11, 242)
local BORD = Color(60, 60, 60)
local BORD_INT = Color(26, 26, 26)
local VERT = Color(95, 168, 102)
local MAT_GLOW = Material("sprites/light_glow02_add")
local MAT_DEGRADE = Material("vgui/gradient-d")

local function VH() return ScrH() / 100 end
-- la police Philosopher est telechargee a la connexion ; si elle manque encore, on garde Poppins
local function PoliceDispo(sNom)
    surface.CreateFont("TFJF4::TestA", { font = sNom, size = 40, extended = true })
    surface.CreateFont("TFJF4::TestB", { font = "TFJ_police_inexistante", size = 40, extended = true })
    surface.SetFont("TFJF4::TestA") local a = surface.GetTextSize("Favoris Combat Tristesse")
    surface.SetFont("TFJF4::TestB") local b = surface.GetTextSize("Favoris Combat Tristesse")
    return a ~= b
end
local function Polices()
    local v = VH()
    local sP = PoliceDispo("Philosopher") and "Philosopher" or "Poppins"
    F.sPolice = sP
    surface.CreateFont("TFJUI::Titre", { font = sP, size = math.Round(v * 3.4), weight = 700, extended = true })
    surface.CreateFont("TFJUI::Sous", { font = sP, size = math.Round(v * 2.0), weight = 700, extended = true })
    surface.CreateFont("TFJUI::Texte", { font = sP, size = math.Round(v * 1.6), weight = 700, extended = true })
    surface.CreateFont("TFJUI::Petit", { font = sP, size = math.Round(v * 1.25), weight = 700, extended = true })
    surface.CreateFont("TFJF4::Gros", { font = sP, size = math.Round(v * 4.2), weight = 800, extended = true })
    surface.CreateFont("TFJF4::Titre", { font = sP, size = math.Round(v * 2.1), weight = 700, extended = true })
    surface.CreateFont("TFJF4::Texte", { font = sP, size = math.Round(v * 1.45), weight = 500, extended = true })
    surface.CreateFont("TFJF4::Gras", { font = sP, size = math.Round(v * 1.45), weight = 700, extended = true })
    surface.CreateFont("TFJF4::Petit", { font = sP, size = math.Round(v * 1.15), weight = 500, extended = true })
    surface.CreateFont("TFJF4::Mini", { font = sP, size = math.Round(v * 1.0), weight = 700, extended = true })
end
Polices()
hook.Add("OnScreenSizeChanged", "TFJ.F4.Polices", Polices)
hook.Add("InitPostEntity", "TFJ.F4.Polices", function() timer.Simple(3, Polices) end)

-- ------------------------------------------------------------------ outils de dessin
local tCercles = {}
local function Cercle(x, y, r, col)
    local n = 40
    local cle = n
    local base = tCercles[cle]
    if not base then
        base = {}
        for i = 0, n - 1 do local a = i / n * math.pi * 2 base[#base + 1] = { math.cos(a), math.sin(a) } end
        tCercles[cle] = base
    end
    local pts = {}
    for i, p in ipairs(base) do pts[i] = { x = x + p[1] * r, y = y + p[2] * r } end
    draw.NoTexture()
    surface.SetDrawColor(col)
    surface.DrawPoly(pts)
end
local function Ligne(x1, y1, x2, y2, ep, col)
    local dx, dy = x2 - x1, y2 - y1
    local l = math.sqrt(dx * dx + dy * dy)
    if l < 1 then return end
    draw.NoTexture()
    surface.SetDrawColor(col)
    surface.DrawTexturedRectRotated((x1 + x2) / 2, (y1 + y2) / 2, l, ep, -math.deg(math.atan2(dy, dx)))
end
local function Grain(x, y, w, h, a)
    local m = TFJ_F4.Img and TFJ_F4.Img.grain
    if not m then return end
    surface.SetMaterial(m)
    surface.SetDrawColor(255, 255, 255, a or 10)
    surface.DrawTexturedRectUV(x, y, w, h, 0, 0, w / 128, h / 128)
end
local function Carte(x, y, w, h, colBord)
    surface.SetDrawColor(PANNEAU) surface.DrawRect(x, y, w, h)
    Grain(x, y, w, h, 9)
    surface.SetDrawColor(colBord or BORD) surface.DrawOutlinedRect(x, y, w, h, 1)
    surface.SetDrawColor(BORD_INT) surface.DrawOutlinedRect(x + 3, y + 3, w - 6, h - 6, 1)
end
-- petit losange (facon curseurs de la capture)
local function Losange(x, y, r, col, colBord)
    draw.NoTexture()
    if colBord then
        surface.SetDrawColor(colBord)
        surface.DrawPoly({ { x = x, y = y - r - 2 }, { x = x + r + 2, y = y }, { x = x, y = y + r + 2 }, { x = x - r - 2, y = y } })
    end
    surface.SetDrawColor(col)
    surface.DrawPoly({ { x = x, y = y - r }, { x = x + r, y = y }, { x = x, y = y + r }, { x = x - r, y = y } })
end
local function Cadenas(x, y, s, col)
    surface.SetDrawColor(col)
    draw.NoTexture()
    surface.DrawRect(x - s * 0.5, y - s * 0.05, s, s * 0.6)
    surface.DrawRect(x - s * 0.36, y - s * 0.45, s * 0.14, s * 0.42)
    surface.DrawRect(x + s * 0.22, y - s * 0.45, s * 0.14, s * 0.42)
    surface.DrawRect(x - s * 0.36, y - s * 0.55, s * 0.72, s * 0.14)
end
F.Cercle, F.Ligne, F.Carte, F.Grain, F.Losange = Cercle, Ligne, Carte, Grain, Losange

-- ------------------------------------------------------------------ style ninja
local function Img(s) return TFJ_F4.Img and TFJ_F4.Img[s] end
local function DessinerImg(s, x, y, w, h, col, ang)
    local m = Img(s)
    if not m then return false end
    surface.SetMaterial(m)
    surface.SetDrawColor(col or color_white)
    if ang then surface.DrawTexturedRectRotated(x, y, w, h, ang) else surface.DrawTexturedRect(x, y, w, h) end
    return true
end
-- cadre d'un arbre : fond noir granuleux, double liseret, trait rouge en haut, losanges aux angles
local function Parchemin(x, y, w, h)
    local v = VH()
    Carte(x, y, w, h)
    surface.SetDrawColor(ROUGE) surface.DrawRect(x + 1, y + 1, w - 2, 2)
    surface.SetMaterial(MAT_DEGRADE)
    surface.SetDrawColor(0, 0, 0, 120)
    surface.DrawTexturedRect(x + 1, y + h * 0.6, w - 2, h * 0.4 - 1)
    local r = math.max(3, v * 0.45)
    Losange(x, y, r, ROUGE, ENCRE) Losange(x + w, y, r, ROUGE, ENCRE)
    Losange(x, y + h, r, BORD, ENCRE) Losange(x + w, y + h, r, BORD, ENCRE)
end
F.Parchemin = Parchemin
-- sceau rouge de chaque arbre
local tSceaux = { suiton = 1, futon = 1, raiton = 1, doton = 1, katon = 1, guerrier = 1, robustesse = 1, mirage = 1, medicale = 1 }
local function Sceau(sB)
    sB = tostring(sB or "")
    if tSceaux[sB] then return "sceau_" .. sB end
    if sB:StartWith("taijutsu") then return "sceau_taijutsu" end
    if sB:StartWith("kenjutsu") then return "sceau_kenjutsu" end
    local tClans = Solve and Solve.Naruto and Solve.Naruto.Clan and Solve.Naruto.Clan.Config and Solve.Naruto.Clan.Config.clans
    if tClans and tClans[sB] then return "sceau_clan" end
    for _, c in ipairs((M_Fight.tConfig and M_Fight.tConfig.tCategories) or {}) do
        if c.bKekkei then for _, t in ipairs(c.tTrees or {}) do if t.sID == sB then return "sceau_kekkei" end end end
        if c.bClan then for _, t in ipairs(c.tTrees or {}) do if t.sID == sB then return "sceau_clan" end end end
    end
    return "sceau_shinobi"
end
F.Sceau = Sceau
local tIconesOnglets = { ["Natures"] = "onglet_natures", ["Styles"] = "onglet_styles", ["Classes"] = "onglet_classes", ["Clans"] = "onglet_clans", ["Kekkei Genkai"] = "onglet_kekkei" }
-- trait en pointilles (liens verrouilles)
local function Pointilles(x1, y1, x2, y2, ep, col)
    local dx, dy = x2 - x1, y2 - y1
    local l = math.sqrt(dx * dx + dy * dy)
    if l < 1 then return end
    local pas = VH() * 1.2
    local n = math.floor(l / pas)
    for i = 0, n - 1, 2 do
        local a, b = i / n, math.min((i + 1) / n, 1)
        Ligne(x1 + dx * a, y1 + dy * a, x1 + dx * b, y1 + dy * b, ep, col)
    end
end

-- lit une variable capturee par une fonction du menu (sans modifier le menu)
local function Upval(fn, sNom)
    if not isfunction(fn) or not debug.getupvalue then return end
    for i = 1, 80 do
        local n, v = debug.getupvalue(fn, i)
        if not n then return end
        if n == sNom then return v end
    end
end

-- ------------------------------------------------------------------ etat d'une technique
local function Niveau(p, tSkill)
    local t = p.HasSkill and p:HasSkill(tSkill.sID)
    if istable(t) then return t.nLevel or 1 end
    return t and 1 or 0
end
local function RangOk(p, tSkill)
    local tL1 = tSkill.tLevels and tSkill.tLevels[1] or {}
    local s = tL1.sMinimumRank or tSkill.sMinimumRank
    return not s or not p.IsNinjaRank or p:IsNinjaRank(s)
end
local function ParentsOk(p, tSkill)
    for _, s in ipairs(tSkill.tParents or {}) do
        if not (p.HasSkill and p:HasSkill(s)) then return false end
    end
    return true
end
-- "appris", "dispo" ou "verrou"
function F.Etat(p, tSkill, bHasNature)
    local iNiv = Niveau(p, tSkill)
    local iMax = tSkill.tLevels and #tSkill.tLevels or 1
    if iNiv > 0 then return "appris", iNiv, iMax end
    if bHasNature == false or not RangOk(p, tSkill) or not ParentsOk(p, tSkill) then return "verrou", iNiv, iMax end
    return "dispo", iNiv, iMax
end
local function CouleurEtat(s) return s == "appris" and OR or (s == "dispo" and ROUGE or GRIS) end

-- ------------------------------------------------------------------ style partage avec les autres menus TFJ
TFJ_UI = TFJ_UI or {}
TFJ_UI.Couleurs = { ROUGE = ROUGE, ROUGE_FONCE = ROUGE_FONCE, NOIR = ENCRE, BLANC = PAPIER, GRIS = GRIS, TEXTE2 = TEXTE2, PANNEAU = PANNEAU, BORD = BORD, BORD_INT = BORD_INT }
TFJ_UI.Cadre, TFJ_UI.Grain, TFJ_UI.Losange, TFJ_UI.Ligne = Carte, Grain, Losange, Ligne
function TFJ_UI.Police() return F.sPolice or "Poppins" end
-- bouton du style : fond noir ou rouge, liseret, texte blanc
function TFJ_UI.Bouton(w, h, bSurvol, bRouge, sTexte, sFont)
    surface.SetDrawColor(bRouge and (bSurvol and ROUGE or ROUGE_FONCE) or (bSurvol and Color(28, 28, 28) or Color(14, 14, 14))) surface.DrawRect(0, 0, w, h)
    Grain(0, 0, w, h, 12)
    surface.SetDrawColor((bRouge or bSurvol) and ROUGE or BORD) surface.DrawOutlinedRect(0, 0, w, h, 1)
    if sTexte then draw.SimpleText(sTexte, sFont or "TFJUI::Texte", w / 2, h / 2, PAPIER, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) end
end
-- en-tete facon "CATEGORIE / Favoris"
function TFJ_UI.EnTete(x, y, sPetit, sGrand)
    draw.SimpleText(string.upper(sPetit or ""), "TFJUI::Petit", x, y, ROUGE)
    draw.SimpleText(sGrand or "", "TFJUI::Titre", x, y + VH() * 1.6, PAPIER)
end

-- ------------------------------------------------------------------ rond d'une technique
local function PeindreNoeud(btn, tSkill, bHasNature)
    btn.Paint = function(self, w, h)
        local p = LocalPlayer()
        local sEtat, iNiv, iMax = F.Etat(p, tSkill, bHasNature)
        local col = CouleurEtat(sEtat)
        self.fH = Lerp(FrameTime() * 10, self.fH or 0, self:IsHovered() and 1 or 0)
        local cx, cy = w / 2, h / 2
        local r = w / 2 * (1 + 0.1 * self.fH)
        local bClip = DisableClipping(true)
        if sEtat == "dispo" then -- shuriken qui tourne doucement
            DessinerImg("shuriken", cx, cy, r * 2.9, r * 2.9, Color(ROUGE.r, ROUGE.g, ROUGE.b, 70 + 60 * self.fH), (CurTime() * 25) % 360)
        end
        if sEtat ~= "verrou" then -- halo
            surface.SetMaterial(MAT_GLOW)
            local fPulse = sEtat == "dispo" and (0.75 + 0.25 * math.sin(CurTime() * 3)) or 1
            surface.SetDrawColor(col.r, col.g, col.b, (60 + 70 * self.fH) * fPulse)
            surface.DrawTexturedRectRotated(cx, cy, r * 3.4, r * 3.4, 0)
        end
        if sEtat == "appris" then -- quatre pointes facon shuriken
            for k = 0, 3 do
                local a = k * math.pi / 2 + math.pi / 4
                local px, py = cx + math.cos(a) * r * 1.08, cy + math.sin(a) * r * 1.08
                draw.NoTexture()
                surface.SetDrawColor(col)
                surface.DrawPoly({
                    { x = px + math.cos(a) * r * 0.28, y = py + math.sin(a) * r * 0.28 },
                    { x = px + math.cos(a + math.pi / 2) * r * 0.14, y = py + math.sin(a + math.pi / 2) * r * 0.14 },
                    { x = px - math.cos(a) * r * 0.1, y = py - math.sin(a) * r * 0.1 },
                    { x = px + math.cos(a - math.pi / 2) * r * 0.14, y = py + math.sin(a - math.pi / 2) * r * 0.14 },
                })
            end
        end
        Cercle(cx, cy, r, col)                         -- anneau
        Cercle(cx, cy, r - math.max(2, w * 0.05), ENCRE)
        if tSkill.mImage then                            -- vraie icone de la technique
            surface.SetMaterial(tSkill.mImage)
            surface.SetDrawColor(255, 255, 255, sEtat == "verrou" and 90 or 255)
            surface.DrawTexturedRectRotated(cx, cy, r * 1.62, r * 1.62, 0)
        end
        if sEtat == "verrou" then
            Cercle(cx, cy, r * 0.8, Color(20, 17, 14, 150))
            Cadenas(cx, cy + r * 0.05, r * 0.5, Color(185, 178, 166, 230))
        end
        -- pastille de niveau
        local s = iNiv .. "/" .. iMax
        surface.SetFont("TFJF4::Mini")
        local tw, th = surface.GetTextSize(s)
        local pw, ph = tw + VH() * 1, th + 2
        draw.RoundedBox(ph / 2, cx - pw / 2, cy + r - ph * 0.45, pw, ph, col)
        draw.SimpleText(s, "TFJF4::Mini", cx, cy + r - ph * 0.45 + ph / 2, sEtat == "dispo" and PAPIER or ENCRE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        DisableClipping(bClip)
    end
end

-- ------------------------------------------------------------------ noms des arbres
local function NomArbre(sBranche)
    for _, t in ipairs((M_Fight.tConfig and M_Fight.tConfig.tNatures) or {}) do
        if t.sID == sBranche then return t.sName, t.mMat end
    end
    local tClan = Solve and Solve.Naruto and Solve.Naruto.Clan and Solve.Naruto.Clan.Config and Solve.Naruto.Clan.Config.clans and Solve.Naruto.Clan.Config.clans[sBranche]
    if tClan and tClan.sName then return "Clan " .. tClan.sName end
    local s = tostring(sBranche):gsub("_", " ")
    return s:sub(1, 1):upper() .. s:sub(2)
end

-- ------------------------------------------------------------------ habillage du F4
function F.Habiller(vFrame, nID)
    if cvClassique:GetBool() or not IsValid(vFrame) then return end
    local p = LocalPlayer()
    local v = VH()

    -- 1) ronds des techniques
    local tNoeuds = {} -- { btn, tSkill, bHasNature }
    for _, c in ipairs(vFrame:GetChildren()) do
        local tSkill = Upval(c.DoClick, "tSkill")
        if istable(tSkill) and tSkill.sID and c.ClassName == "DButton" then
            local bHasNature = Upval(c.DoClick, "bHasNature")
            PeindreNoeud(c, tSkill, bHasNature)
            tNoeuds[#tNoeuds + 1] = { btn = c, tSkill = tSkill, bHasNature = bHasNature }
        end
    end
    vFrame.tTFJNoeuds = tNoeuds

    -- 1b) recentrage : les arbres sont places au centre de la zone libre (sous les onglets, au-dessus des boutons du bas)
    if not vFrame.TFJCentre and #tNoeuds > 0 then
        vFrame.TFJCentre = true
        local W, H = vFrame:GetWide(), vFrame:GetTall()
        local x1, y1, x2, y2 = math.huge, math.huge, -math.huge, -math.huge
        for _, n in ipairs(tNoeuds) do
            local x, y = n.btn:GetPos()
            local bw, bh = n.btn:GetSize()
            x1, y1 = math.min(x1, x), math.min(y1, y)
            x2, y2 = math.max(x2, x + bw), math.max(y2, y + bh)
        end
        -- marges des cartes dessinees autour des ronds
        local cx1, cy1, cx2, cy2 = x1 - v * 3.2, y1 - v * 7.5, x2 + v * 3.2, y2 + v * 3
        local zHaut = v * 13.5
        local zBas = (nID == 1) and v * 80 or (H - v * 5)
        local dy = (zHaut + zBas) / 2 - (cy1 + cy2) / 2
        if cy1 + dy < zHaut then dy = zHaut - cy1 end
        local dx = (nID == 2) and 0 or (W / 2 - (cx1 + cx2) / 2)
        if math.abs(dx) > 1 or math.abs(dy) > 1 then
            for _, n in ipairs(tNoeuds) do
                local x, y = n.btn:GetPos()
                n.btn:SetPos(math.Round(x + dx), math.Round(y + dy))
            end
        end
    end

    -- 2) fond, cartes des arbres, liens, points (le dessin d'origine est garde pour ses effets mais rendu invisible)
    local fnOrig = vFrame.Paint
    vFrame.Paint = function(self, w, h)
        local fA = surface.GetAlphaMultiplier()
        surface.SetAlphaMultiplier(0)
        local ok = pcall(fnOrig, self, w, h) -- cree les boutons de nature / reroll comme avant
        surface.SetAlphaMultiplier(fA)

        -- voile : le jeu reste visible
        surface.SetDrawColor(6, 6, 6, 215)
        surface.DrawRect(0, 0, w, h)
        surface.SetMaterial(MAT_DEGRADE)
        surface.SetDrawColor(0, 0, 0, 160)
        surface.DrawTexturedRect(0, h * 0.5, w, h * 0.5)
        DessinerImg("filigrane", w / 2, h * 0.55, h * 0.85, h * 0.85, Color(ROUGE.r, ROUGE.g, ROUGE.b, 18), 0)
        -- bandeau du haut : trait de pinceau rouge + shuriken
        local yB = v * 10.4
        Ligne(v * 3, yB, w / 2 - v * 3, yB, 2, Color(ROUGE.r, ROUGE.g, ROUGE.b, 150))
        Ligne(w / 2 + v * 3, yB, w - v * 3, yB, 2, Color(ROUGE.r, ROUGE.g, ROUGE.b, 150))
        DessinerImg("shuriken", w / 2, yB, v * 3.2, v * 3.2, Color(OR.r, OR.g, OR.b, 200), (CurTime() * 12) % 360)

        -- cartes des arbres (regroupe les ronds par arbre)
        local tArbres = {}
        for _, n in ipairs(self.tTFJNoeuds or {}) do
            if IsValid(n.btn) and n.btn:IsVisible() then
                local sB = n.tSkill.sParent or "?"
                local t = tArbres[sB] or { x1 = math.huge, y1 = math.huge, x2 = -math.huge, y2 = -math.huge, n = 0, appris = 0, nature = n.bHasNature }
                local x, y = n.btn:GetPos()
                local bw, bh = n.btn:GetSize()
                t.x1, t.y1 = math.min(t.x1, x), math.min(t.y1, y)
                t.x2, t.y2 = math.max(t.x2, x + bw), math.max(t.y2, y + bh)
                t.n = t.n + 1
                if Niveau(p, n.tSkill) > 0 then t.appris = t.appris + 1 end
                tArbres[sB] = t
            end
        end
        for sB, t in pairs(tArbres) do
            if t.n >= 2 then
                local x, y = t.x1 - v * 3.2, t.y1 - v * 7.5
                local cw, ch = (t.x2 - t.x1) + v * 6.4, (t.y2 - t.y1) + v * 10.5
                cw = math.max(cw, v * 18)
                x = (t.x1 + t.x2) / 2 - cw / 2
                Parchemin(x, y, cw, ch)
                local sNom = NomArbre(sB)
                local tx = x + v * 1.5
                if DessinerImg(Sceau(sB), tx, y + v * 1.3, v * 3.4, v * 3.4, Color(255, 255, 255, t.nature == false and 110 or 255)) then
                    tx = tx + v * 4
                end
                draw.SimpleText(string.upper(sNom), "TFJF4::Titre", tx, y + v * 1.1, t.nature == false and TEXTE2 or OR)
                draw.SimpleText(t.appris .. " / " .. t.n .. " techniques" .. (t.nature == false and "  ·  nature non ma\195\174tris\195\169e" or ""), "TFJF4::Petit", tx, y + v * 3.4, TEXTE2)
                local bx, by, bw = x + v * 1.5, y + v * 5.4, cw - v * 3
                surface.SetDrawColor(BORD) surface.DrawRect(bx, by, bw, 2)
                if t.appris > 0 then surface.SetDrawColor(ROUGE) surface.DrawRect(bx, by, bw * t.appris / t.n, 2) end
            end
        end

        -- liens entre techniques
        local tPos = {}
        for _, n in ipairs(self.tTFJNoeuds or {}) do
            if IsValid(n.btn) then
                local x, y = n.btn:GetPos()
                local bw, bh = n.btn:GetSize()
                tPos[n.tSkill.sID] = { x + bw / 2, y + bh / 2, n }
            end
        end
        for sID, a in pairs(tPos) do
            local n = a[3]
            local tLiens = (self.tTFJLiens and self.tTFJLiens[sID]) or n.tSkill.tParents or {}
            local sEtat = F.Etat(p, n.tSkill, n.bHasNature)
            for _, sP in ipairs(tLiens) do
                local b = tPos[sP]
                if b then
                    local bParentAppris = Niveau(p, b[3].tSkill) > 0
                    local col = (sEtat == "appris" and bParentAppris) and Color(OR.r, OR.g, OR.b, 235)
                        or (sEtat == "dispo" and Color(ROUGE.r, ROUGE.g, ROUGE.b, 210) or Color(GRIS.r, GRIS.g, GRIS.b, 150))
                    if sEtat == "verrou" then Pointilles(a[1], a[2], b[1], b[2], 3, col)
                    else Ligne(a[1], a[2], b[1], b[2], sEtat == "appris" and 4 or 3, col) end
                end
            end
        end

        -- points de competence (haut gauche)
        local sPts = tostring(p:GetNetworkVar("nSkillPoint", 0))
        surface.SetFont("TFJF4::Gros")
        local pw = surface.GetTextSize(sPts)
        Carte(v * 3, v * 3, pw + v * 23.5, v * 5.6)
        DessinerImg("sceau_shinobi", v * 3.7, v * 3.7, v * 4.2, v * 4.2)
        draw.SimpleText(sPts, "TFJF4::Gros", v * 8.9, v * 5.8, OR, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("POINTS DE COMP\195\137TENCE", "TFJF4::Gras", v * 10.1 + pw, v * 4.9, PAPIER, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("disponibles", "TFJF4::Petit", v * 10.1 + pw, v * 6.8, TEXTE2, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        -- reinitialisation (le bouton d'origine reste cliquable, on dessine la carte autour)
        local b = self.vButtonBuySecondReroll
        if IsValid(b) then
            local sTxt = "\226\134\186  R\195\169initialiser les points"
            surface.SetFont("TFJF4::Gras")
            local tw2, th2 = surface.GetTextSize(sTxt)
            local bw2, bh2 = tw2 + v * 3, th2 + v * 1.8
            bh2 = v * 4.6
            local bx2, by2 = w - v * 9.4 - bw2, v * 3.5
            b:SetPos(bx2, by2) b:SetSize(bw2, bh2)
            local bSurvol = b:IsHovered()
            Carte(bx2, by2, bw2, bh2, bSurvol and ROUGE or BORD)
            draw.SimpleText(sTxt, "TFJF4::Gras", bx2 + bw2 / 2, by2 + bh2 / 2, PAPIER, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        -- legende (bas)
        local lx, ly = v * 3, h - v * 2.6
        for _, t in ipairs({ { "Appris", OR }, { "Disponible", ROUGE }, { "Verrouill\195\169", GRIS } }) do
            if not DessinerImg("shuriken", lx + v * 0.6, ly, v * 1.6, v * 1.6, t[2], 0) then Cercle(lx + v * 0.6, ly, v * 0.6, t[2]) end
            local tw = draw.SimpleText(t[1], "TFJF4::Petit", lx + v * 1.6, ly, TEXTE2, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            lx = lx + v * 1.6 + tw + v * 2.4
        end
        draw.SimpleText("Clic : d\195\169tails   \194\183   \195\137chap : fermer", "TFJF4::Petit", w - v * 3, ly, TEXTE2, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    -- 3) boutons et onglets
    F.HabillerEnfants(vFrame)
    vFrame.TFJProchainScan = 0
    local fnThink = vFrame.Think
    vFrame.Think = function(self, ...)
        if fnThink then fnThink(self, ...) end
        if CurTime() > (self.TFJProchainScan or 0) then -- boutons crees plus tard (choix de nature...)
            self.TFJProchainScan = CurTime() + 0.5
            F.HabillerEnfants(self)
        end
    end
end

function F.HabillerEnfants(vFrame)
    local v = VH()
    for _, c in ipairs(vFrame:GetChildren()) do
        if not c.TFJHabille then
            -- bouton fermer (petit carre en haut a droite)
            if c.ClassName == "DButton" and c:GetWide() == 28 and c:GetTall() == 28 then
                c.TFJHabille = true
                c:SetSize(v * 4.6, v * 4.6)
                c:SetPos(vFrame:GetWide() - v * 7.6, v * 3.5)
                c.Paint = function(self, w, h)
                    Carte(0, 0, w, h, self:IsHovered() and ROUGE or BORD)
                    Ligne(w * 0.33, h * 0.33, w * 0.67, h * 0.67, 3, PAPIER)
                    Ligne(w * 0.67, h * 0.33, w * 0.33, h * 0.67, 3, PAPIER)
                end
            -- boutons de choix / relance de nature
            elseif c.ClassName == "DButton" and (Upval(c.Paint, "bHasFirst") ~= nil or Upval(c.Paint, "bHasSecond") ~= nil) then
                c.TFJHabille = true
                local bPremier = Upval(c.Paint, "bHasFirst") ~= nil
                c.Paint = function(self, w, h)
                    local sText
                    if bPremier then
                        local bA, bB = Upval(self.DoClick, "bHasFirst"), nil
                        local s1, s2 = LocalPlayer():GetNetworkVar("sFirstNature", ""), LocalPlayer():GetNetworkVar("sSecondNature", "")
                        sText = (s1 == "") and "Choisissez votre premi\195\168re nature !" or ((s2 ~= "") and "Relancer votre \195\169l\195\169ment" or "Acheter et relancer")
                    else
                        local s2 = LocalPlayer():GetNetworkVar("sSecondNature", "")
                        sText = (s2 ~= "") and "Relancer votre \195\169l\195\169ment" or "Choisissez votre seconde nature !"
                    end
                    local bS = self:IsHovered()
                    surface.SetDrawColor(bS and ROUGE or ROUGE_FONCE) surface.DrawRect(0, 0, w, h)
                    Grain(0, 0, w, h, 12)
                    surface.SetDrawColor(ROUGE) surface.DrawOutlinedRect(0, 0, w, h, 1)
                    Losange(0, h / 2, h * 0.12, ROUGE, ENCRE) Losange(w, h / 2, h * 0.12, ROUGE, ENCRE)
                    draw.SimpleText(sText, "TFJF4::Gras", w / 2, h / 2, PAPIER, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            -- barre d'onglets (DPanel contenant les boutons des categories)
            elseif c.ClassName == "DPanel" then
                local tOnglets = {}
                for _, b in ipairs(c:GetChildren()) do
                    if Upval(b.Paint, "tCategory") and Upval(b.Paint, "nID") then tOnglets[#tOnglets + 1] = b end
                end
                if #tOnglets > 0 then
                    c.TFJHabille = true
                    c:SetTall(v * 5.6)
                    c:SetY(v * 3)
                    c:SetX(math.Round(vFrame:GetWide() / 2 - c:GetWide() / 2))
                    c.Paint = function(self, w, h)
                        local bClipO = DisableClipping(true)
                        Carte(-v * 0.8, 0, w + v * 1.6, h)
                        DisableClipping(bClipO)
                    end
                    for _, b in ipairs(tOnglets) do
                        local tCat = Upval(b.Paint, "tCategory")
                        local nMon = Upval(b.Paint, "nID")
                        local sIcone = tCat and tIconesOnglets[tCat.sName]
                        local mIconeOrig = Upval(b.Paint, "matIcon")
                        local fnActif = function() return Upval(b.Paint, "nActualID") == nMon end
                        local fnOrig = b.Paint
                        b.TFJHabille = true
                        b.Paint = function(self, w, h)
                            local bActif = Upval(fnOrig, "nActualID") == nMon
                            self.fH = Lerp(FrameTime() * 10, self.fH or 0, self:IsHovered() and 1 or 0)
                            local hh = h - v * 1
                            if bActif then
                                surface.SetDrawColor(ROUGE_FONCE) surface.DrawRect(0, v * 0.5, w, hh)
                                surface.SetDrawColor(ROUGE) surface.DrawOutlinedRect(0, v * 0.5, w, hh, 1)
                                Grain(0, v * 0.5, w, hh, 12)
                            elseif self.fH > 0.01 then surface.SetDrawColor(255, 255, 255, 14 * self.fH) surface.DrawRect(0, v * 0.5, w, hh) end
                            if not (sIcone and DessinerImg(sIcone, v * 0.8, h / 2 - v * 1.2, v * 2.4, v * 2.4, bActif and PAPIER or Color(OR.r, OR.g, OR.b, 200))) and mIconeOrig then
                                surface.SetMaterial(mIconeOrig)
                                surface.SetDrawColor(255, 255, 255, bActif and 255 or 170)
                                surface.DrawTexturedRect(v * 0.9, h / 2 - v * 1.1, v * 2.2, v * 2.2)
                            end
                            draw.SimpleText(tCat.sName, "TFJF4::Gras", v * 3.5, h / 2, bActif and PAPIER or TEXTE2, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                        end
                    end
                end
            end
        end
    end
end

-- ------------------------------------------------------------------ fiche d'une technique (remplace la fenetre "Upgrade")
local function EstClanStaff(tSkill)
    for _, tMain in ipairs((M_Fight.tConfig and M_Fight.tConfig.tSkillsCategories) or {}) do
        if tMain.sName == "Clans" or tMain.bClan then
            for _, tC in ipairs(tMain.tCategories or {}) do
                for _, e in ipairs(tC.tSkills or {}) do if e.sID == tSkill.sID then return true end end
            end
        end
    end
    return false
end

local function Decouper(s, iLarg, sFont)
    surface.SetFont(sFont)
    local tLignes, sL = {}, ""
    for mot in tostring(s or ""):gmatch("%S+") do
        local essai = sL == "" and mot or (sL .. " " .. mot)
        if surface.GetTextSize(essai) > iLarg and sL ~= "" then tLignes[#tLignes + 1] = sL sL = mot else sL = essai end
    end
    if sL ~= "" then tLignes[#tLignes + 1] = sL end
    return tLignes
end

function F.Fiche(self, tSkill)
    if cvClassique:GetBool() and F.OrigUpgrade then return F.OrigUpgrade(self, tSkill) end
    local p = LocalPlayer()
    local v = VH()
    if IsValid(F.vFiche) then F.vFiche:Remove() end
    local vFond = vgui.Create("DButton")
    F.vFiche = vFond
    vFond:SetSize(ScrW(), ScrH())
    vFond:SetText("")
    vFond:MakePopup()
    vFond:SetAlpha(0)
    vFond:AlphaTo(255, 0.2, 0)
    vFond.Paint = function(s, w, h)
        surface.SetDrawColor(8, 7, 6, 200)
        surface.DrawRect(0, 0, w, h)
    end
    vFond.DoClick = function(s) s:AlphaTo(0, 0.15, 0, function() s:Remove() end) end
    vFond.Think = function(s)
        if input.IsKeyDown(KEY_ESCAPE) and not s.bFerme then s.bFerme = true s:AlphaTo(0, 0.15, 0, function() s:Remove() end) end
    end

    local W = v * 56
    local carte = vgui.Create("DPanel", vFond)
    carte:SetSize(W, v * 70)
    carte:Center()
    carte.OnMousePressed = function() end -- un clic dans la carte ne la ferme pas

    local bouton = vgui.Create("DButton", carte)
    bouton:SetText("")
    local fermer = vgui.Create("DButton", carte)
    fermer:SetText("")
    fermer:SetSize(v * 3.6, v * 3.6)
    fermer:SetPos(W - v * 5.2, v * 1.6)
    fermer.Paint = function(s, w, h)
        surface.SetDrawColor(s:IsHovered() and ROUGE or Color(255, 255, 255, 10)) surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(BORD) surface.DrawOutlinedRect(0, 0, w, h, 1)
        Ligne(w * 0.33, h * 0.33, w * 0.67, h * 0.67, 2, PAPIER)
        Ligne(w * 0.67, h * 0.33, w * 0.33, h * 0.67, 2, PAPIER)
    end
    fermer.DoClick = function() vFond:DoClick() end

    carte.Paint = function(s, w, h)
        local iNiv = Niveau(p, tSkill)
        local iMax = tSkill.tLevels and #tSkill.tLevels or 1
        local iProchain = math.min(iNiv + 1, iMax)
        local tL = (tSkill.tLevels and tSkill.tLevels[iProchain]) or {}
        local bMax = iNiv >= iMax
        local sEtat = F.Etat(p, tSkill)
        local col = CouleurEtat(sEtat)
        local pad = v * 2.6
        local y = pad

        local bClip = DisableClipping(true)
        Parchemin(0, 0, w, h)
        DisableClipping(bClip)
        DessinerImg(Sceau(tSkill.sParent), w - v * 11, v * 2.2, v * 4.6, v * 4.6)
        -- en-tete : icone dans son anneau, nom, infos
        local r = v * 3.6
        surface.SetMaterial(MAT_GLOW)
        surface.SetDrawColor(col.r, col.g, col.b, 90)
        surface.DrawTexturedRectRotated(pad + r, y + r, r * 3.4, r * 3.4, 0)
        Cercle(pad + r, y + r, r, col)
        Cercle(pad + r, y + r, r - 3, ENCRE)
        if tSkill.mImage then
            surface.SetMaterial(tSkill.mImage)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRectRotated(pad + r, y + r, r * 1.62, r * 1.62, 0)
        end
        local tx = pad + r * 2 + v * 1.6
        draw.SimpleText(tSkill.sName or tSkill.sID, "TFJF4::Titre", tx, y + v * 1.2, PAPIER)
        local sRang = tSkill.sMinimumRank or (tSkill.tLevels and tSkill.tLevels[1] and tSkill.tLevels[1].sMinimumRank)
        local tRang = sRang and Solve.Naruto.Config["ranks"][sRang]
        local sInfo = (tSkill.sType or "Technique") .. (tRang and tRang.sName and ("  \194\183  " .. tRang.sName) or "") .. "  \194\183  " .. NomArbre(tSkill.sParent or "")
        draw.SimpleText(sInfo, "TFJF4::Petit", tx, y + v * 4.2, TEXTE2)
        y = y + r * 2 + v * 2

        -- niveaux
        local nb = math.max(iMax, 1)
        local gap = v * 0.8
        local lw = (w - pad * 2 - gap * (nb - 1)) / nb
        for i = 1, nb do
            local bx = pad + (i - 1) * (lw + gap)
            local bFait, bSuiv = i <= iNiv, i == iNiv + 1
            draw.RoundedBox(v * 0.7, bx, y, lw, v * 3.4, bFait and OR or (bSuiv and ROUGE or Color(255, 255, 255, 14)))
            local tLi = tSkill.tLevels and tSkill.tLevels[i] or {}
            draw.SimpleText(tLi.sName or ("Niveau " .. i), "TFJF4::Gras", bx + lw / 2, y + v * 1.7, bFait and ENCRE or (bSuiv and PAPIER or TEXTE2), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        y = y + v * 5

        -- description
        for _, l in ipairs(Decouper(tSkill.sDesc, w - pad * 2, "TFJF4::Texte")) do
            draw.SimpleText(l, "TFJF4::Texte", pad, y, Color(216, 205, 182))
            y = y + v * 2.1
        end
        y = y + v * 1.2

        -- statistiques du niveau suivant (ou du dernier)
        local tInfos = tL.tInfos or {}
        if #tInfos > 0 then
            draw.SimpleText(bMax and "Statistiques" or ("Statistiques  \194\183  niveau " .. iProchain), "TFJF4::Gras", pad, y, OR)
            y = y + v * 2.6
            local hh = v * 2.8
            draw.RoundedBox(v, pad, y, w - pad * 2, hh * #tInfos, Color(0, 0, 0, 110))
            for i, inf in ipairs(tInfos) do
                local sN = isfunction(inf.sName) and inf.sName() or tostring(inf.sName or "")
                draw.SimpleText(sN, "TFJF4::Texte", pad + v * 1.4, y + hh / 2, TEXTE2, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(tostring(inf.nValue or ""), "TFJF4::Gras", w - pad - v * 1.4, y + hh / 2, PAPIER, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                y = y + hh
            end
            y = y + v * 1.6
        end

        -- conditions
        if not bMax then
            draw.SimpleText("Conditions", "TFJF4::Gras", pad, y, OR)
            y = y + v * 2.6
            for _, req in ipairs(tL.tRequirements or {}) do
                local sN = isfunction(req.sName) and req.sName() or tostring(req.sName or "")
                local okC, bOk = pcall(req.fCheck or function() return true end, p)
                bOk = okC and bOk
                draw.SimpleText(bOk and "\226\156\147" or "\226\156\149", "TFJF4::Gras", pad, y, bOk and VERT or ROUGE)
                draw.SimpleText(sN, "TFJF4::Texte", pad + v * 2.2, y, bOk and PAPIER or TEXTE2)
                y = y + v * 2.3
            end
            y = y + v * 1
        end

        -- bouton
        local bh = v * 5.2
        bouton:SetPos(pad, y)
        bouton:SetSize(w - pad * 2, bh)
        local hFinal = y + bh + pad
        if math.abs(h - hFinal) > 1 then s:SetTall(hFinal) s:Center() end
    end

    bouton.Paint = function(s, w, h)
        local iNiv = Niveau(p, tSkill)
        local iMax = tSkill.tLevels and #tSkill.tLevels or 1
        local tL = tSkill.tLevels and tSkill.tLevels[math.min(iNiv + 1, iMax)] or {}
        local sTxt, bActif
        if EstClanStaff(tSkill) then sTxt, bActif = "Attribu\195\169e par le staff", false
        elseif iNiv >= iMax then sTxt, bActif = "Niveau maximum", false
        else
            local n = tL.nPoint or 0
            sTxt = (iNiv == 0 and "Apprendre" or "Am\195\169liorer") .. "  \194\183  " .. n .. " point" .. (n > 1 and "s" or "")
            bActif = p:GetNetworkVar("nSkillPoint", 0) > 0
        end
        local c1 = bActif and (s:IsHovered() and Color(214, 70, 52) or ROUGE) or Color(70, 64, 58)
        surface.SetDrawColor(bActif and (s:IsHovered() and ROUGE or ROUGE_FONCE) or Color(30, 30, 30)) surface.DrawRect(0, 0, w, h)
        Grain(0, 0, w, h, 12)
        surface.SetDrawColor(bActif and ROUGE or BORD) surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText(sTxt, "TFJF4::Titre", w / 2, h / 2, bActif and PAPIER or TEXTE2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    -- meme action que la fenetre d'origine
    bouton.DoClick = function()
        if EstClanStaff(tSkill) then
            surface.PlaySound("solve_naruto_base/ui/nooo_f4.wav")
            notification.AddLegacy("Cette comp\195\169tence de clan est attribu\195\169e et am\195\169lior\195\169e uniquement par le staff.", NOTIFY_ERROR, 5)
            return
        end
        if p:GetNetworkVar("nSkillPoint", 0) == 0 then surface.PlaySound("solve_naruto_base/ui/nooo_f4.wav") return end
        if not p:HasSkill(tSkill.sID) then surface.PlaySound("solve_naruto_base/ui/unlock_jutsu.wav")
        else surface.PlaySound("solve_naruto_base/ui/jutsu_upgrade_skill_tree.wav") end
        net.Start("NRP::Battle::BuySkill")
        net.WriteString(tSkill.sID)
        net.SendToServer()
    end
end

-- ------------------------------------------------------------------ installation (se remet en place si le menu est recharge)
function F.Installer()
    if not (M_Fight and M_Fight.SkillTree) then return end
    if M_Fight.SkillTree ~= F.fnTree then
        local fnOrig = M_Fight.SkillTree
        F.fnTree = function(self, nID, ...)
            local r = fnOrig(self, nID, ...)
            if IsValid(M_vSkillTree) then
                local ok, err = pcall(F.Habiller, M_vSkillTree, nID)
                if not ok then ErrorNoHalt("[TFJ F4] habillage : " .. tostring(err) .. "\n") end
            end
            return r
        end
        M_Fight.SkillTree = F.fnTree
    end
    if M_Fight.SkillUpgrade and M_Fight.SkillUpgrade ~= F.Fiche then
        F.OrigUpgrade = M_Fight.SkillUpgrade
        M_Fight.SkillUpgrade = F.Fiche
    end
end
F.Installer()
hook.Add("InitPostEntity", "TFJ.F4", F.Installer)
timer.Create("TFJ.F4", 5, 0, F.Installer)
