-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- TFJ : tableau des joueurs (touche TAB), Style A (noir, rouge, blanc).
-- Maquette Figma : "TFJ – Kit UI Style A" > Ecran – Tableau des ninjas.
-- Remplace le tableau FAdmin. Clic droit pendant que TAB est enfonce :
-- la souris apparait (clic droit sur un joueur = profil, SteamID...).
-- Les admins gardent l'ancien tableau FAdmin via le bouton "Menu admin".
-- Ancien tableau pour tout le monde : tfj_tableau 0
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
TFJ_Tableau = TFJ_Tableau or {}
local T = TFJ_Tableau
local cvActif = CreateClientConVar("tfj_tableau", "1", true, false, "1 = nouveau tableau des joueurs")

-- palette Style A (memes valeurs que le coffre / registre medical)
local C = {
    fond      = Color(10, 10, 10, 245),   -- fenetre
    cadre     = Color(14, 14, 14, 235),   -- cadre interne
    case      = Color(18, 18, 18),        -- ligne
    caseH     = Color(32, 32, 32),        -- ligne survolee
    selection = Color(30, 8, 8),          -- joueur local
    bord      = Color(60, 60, 60),        -- liseret exterieur
    bordInt   = Color(26, 26, 26),        -- double liseret interieur
    texte     = Color(232, 232, 232),
    blanc     = Color(244, 244, 244),
    gris      = Color(140, 140, 140),
    rouge     = Color(176, 26, 26),       -- liserets, barres, boutons
    rougeF    = Color(104, 14, 14),
    rougeT    = Color(224, 72, 72),       -- petits textes rouges (lisibles sur le noir)
}

local function Polices()
    local H = ScrH()
    local sP = TFJ_UI and TFJ_UI.Police and TFJ_UI.Police() or "Philosopher"
    if T.iH == H and T.sPolice == sP then return end
    T.iH, T.sPolice = H, sP
    surface.CreateFont("TFJTab.Titre",   { font = sP, size = math.floor(H * 0.034), weight = 700, extended = true })
    surface.CreateFont("TFJTab.Village", { font = sP, size = math.floor(H * 0.019), weight = 700, extended = true })
    surface.CreateFont("TFJTab.Nom",     { font = sP, size = math.floor(H * 0.0185), weight = 700, extended = true })
    surface.CreateFont("TFJTab.Sous",    { font = sP, size = math.floor(H * 0.0145), weight = 700, extended = true })
    surface.CreateFont("TFJTab.Petit",   { font = sP, size = math.floor(H * 0.0125), weight = 700, extended = true })
end

local function Grain(x, y, w, h, a) if TFJ_UI and TFJ_UI.Grain then TFJ_UI.Grain(x, y, w, h, a) end end
local function Cadre(x, y, w, h, cFond, cBord)
    surface.SetDrawColor(cFond) surface.DrawRect(x, y, w, h)
    surface.SetDrawColor(cBord) surface.DrawOutlinedRect(x, y, w, h, 1)
end
-- cadre a double liseret (fenetres Style A)
local function CadreDouble(x, y, w, h, cFond)
    surface.SetDrawColor(cFond) surface.DrawRect(x, y, w, h)
    Grain(x, y, w, h, 9)
    surface.SetDrawColor(C.bord) surface.DrawOutlinedRect(x, y, w, h, 1)
    surface.SetDrawColor(C.bordInt) surface.DrawOutlinedRect(x + 3, y + 3, w - 6, h - 6, 1)
end
local function Losange(x, y, s, cExt, cInt)
    draw.NoTexture()
    surface.SetDrawColor(cExt) surface.DrawTexturedRectRotated(x, y, s, s, 45)
    if cInt then
        surface.SetDrawColor(cInt) surface.DrawTexturedRectRotated(x, y, s * 0.45, s * 0.45, 45)
    end
end

local function EstAdmin()
    local lp = LocalPlayer()
    return IsValid(lp) and lp:IsAdmin()
end

-- commandes staff (SAM) : goto / bring / retour
local function PeutSAM(sCmd)
    local lp = LocalPlayer()
    if not IsValid(lp) then return false end
    if lp.HasPermission then
        local ok, b = pcall(lp.HasPermission, lp, sCmd)
        if ok and b ~= nil then return b end
    end
    return lp:IsAdmin()
end
local function CommandeSAM(sCmd, pl)
    if not IsValid(pl) then return end
    RunConsoleCommand("sam", sCmd, "#" .. pl:UserID())
end

local function OuvrirFAdmin()
    if FAdmin and FAdmin.ScoreBoard and FAdmin.ScoreBoard.ShowScoreBoard then
        T.Cacher()
        T.bFAdmin = true
        FAdmin.ScoreBoard.ShowScoreBoard()
        gui.EnableScreenClicker(true)
    end
end

-- factions, dans l'ordre d'affichage (palette noir / rouge / blanc)
local tFactions = {
    { id = "konoha",  nom = "Konoha",  c = C.blanc, cTrait = C.bord },
    { id = "suna",    nom = "Suna",    c = C.blanc, cTrait = C.bord },
    { id = "nukenin", nom = "Nukenin", c = C.rougeT, cLos = C.rouge, cTrait = C.rougeF },
}
local tAutre = { id = "autre", nom = "Sans village", c = C.gris, cLos = C.bord, cTrait = C.bordInt }

local function Village(pl)
    local s = pl.GetNetworkVar and pl:GetNetworkVar("sVillage") or nil
    return isstring(s) and string.lower(s) or nil
end

-- joueurs ranges par faction puis par nom
local function Groupes()
    local tPar = {}
    for _, pl in ipairs(player.GetAll()) do
        local s = Village(pl)
        local tF = tAutre
        for _, f in ipairs(tFactions) do if f.id == s then tF = f break end end
        tPar[tF] = tPar[tF] or {}
        table.insert(tPar[tF], pl)
    end
    local tOut = {}
    for _, f in ipairs(tFactions) do tOut[#tOut + 1] = { f = f, t = tPar[f] or {} } end
    if tPar[tAutre] then tOut[#tOut + 1] = { f = tAutre, t = tPar[tAutre] } end
    for _, g in ipairs(tOut) do
        table.sort(g.t, function(a, b) return string.lower(a:Nick()) < string.lower(b:Nick()) end)
    end
    return tOut
end
T.Village = Village

-- ping : blanc = bon, gris = moyen, rouge = mauvais
local function CouleurPing(i)
    if i < 80 then return C.blanc end
    if i < 150 then return C.gris end
    return C.rougeT
end

function T.Construire()
    Polices()
    if IsValid(T.vPanel) then T.vPanel:Remove() end
    local H = math.floor(ScrH() * 0.74)
    local W = math.floor(math.min(ScrW() * 0.6, H * 1.2))
    local p = math.floor(H * 0.025)
    local hEnt = math.floor(H * 0.12)
    local mCadre = math.floor(H * 0.0175) -- marge du cadre interne

    local v = vgui.Create("EditablePanel")
    T.vPanel = v
    v:SetSize(W, H)
    v:Center()
    v:SetAlpha(0)
    v:AlphaTo(255, 0.1)
    v.Paint = function(self, w, h)
        -- fenetre : fond a grain, liseret, barre rouge, losanges aux coins
        surface.SetDrawColor(C.fond) surface.DrawRect(0, 0, w, h)
        Grain(0, 0, w, h, 10)
        surface.SetDrawColor(C.bord) surface.DrawOutlinedRect(0, 0, w, h, 1)
        surface.SetDrawColor(C.rouge) surface.DrawRect(1, 1, w - 2, 2)
        CadreDouble(mCadre, hEnt, w - mCadre * 2, h - hEnt - mCadre, C.cadre)
        local k = math.max(8, math.floor(H * 0.013))
        Losange(0, 0, k, C.rouge, Color(0, 0, 0)) Losange(w, 0, k, C.rouge, Color(0, 0, 0))
        Losange(0, h, k, C.rouge, Color(0, 0, 0)) Losange(w, h, k, C.rouge, Color(0, 0, 0))
        -- en-tete : petit libelle rouge + grand titre blanc
        draw.SimpleText("TABLEAU DES NINJAS", "TFJTab.Petit", p, p, C.rougeT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(GetHostName(), "TFJTab.Titre", p, p + H * 0.022, C.blanc, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(player.GetCount() .. " / " .. game.MaxPlayers() .. " joueurs", "TFJTab.Nom", w - p, p + H * 0.008, C.blanc, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        if not self.bSouris then
            draw.SimpleText("Clic droit : souris", "TFJTab.Sous", w - p, p + H * 0.042, C.gris, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        end
        -- colonnes
        local y = hEnt + H * 0.03
        draw.SimpleText("NINJA", "TFJTab.Petit", p * 1.6 + H * 0.075, y, C.gris, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("PING", "TFJTab.Petit", w - p * 2.4, y, C.gris, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(C.bord)
        surface.DrawRect(p * 1.6, y + H * 0.018, w - p * 3.2, 1)
    end

    if EstAdmin() and FAdmin and FAdmin.ScoreBoard then
        local b = vgui.Create("DButton", v)
        b:SetText("")
        b:SetSize(H * 0.17, H * 0.055)
        b:SetPos(W - p - H * 0.17 - H * 0.2, p + H * 0.004)
        b.Paint = function(self, w, h)
            local bH = self:IsHovered()
            surface.SetDrawColor(bH and C.caseH or C.case) surface.DrawRect(0, 0, w, h)
            Grain(0, 0, w, h, 12)
            surface.SetDrawColor(bH and C.rouge or C.bord) surface.DrawOutlinedRect(0, 0, w, h, 1)
            draw.SimpleText("Menu admin", "TFJTab.Nom", w / 2, h / 2, C.texte, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        b.DoClick = OuvrirFAdmin
    end

    local vListe = vgui.Create("DScrollPanel", v)
    local xL, yL = math.floor(p * 1.6), math.floor(hEnt + H * 0.06)
    vListe:SetPos(xL, yL)
    vListe:SetSize(W - xL * 2, H - yL - mCadre - p * 0.6)
    local vb = vListe:GetVBar()
    vb:SetWide(math.max(4, ScrH() * 0.004))
    vb:SetHideButtons(true)
    vb.Paint = function(_, w, h) surface.SetDrawColor(C.bordInt) surface.DrawRect(0, 0, w, h) end
    vb.btnGrip.Paint = function(_, w, h) surface.SetDrawColor(C.rougeF) surface.DrawRect(0, 0, w, h) end
    T.vListe = vListe

    local hr = math.floor(H * 0.07)
    local function EnTete(f, n)
        local e = vListe:Add("DPanel")
        e:Dock(TOP)
        e:DockMargin(0, math.floor(H * 0.018), p * 0.4, math.floor(H * 0.008))
        e:SetTall(math.floor(H * 0.04))
        e.Paint = function(_, w, h)
            local s = h * 0.42
            Losange(s * 0.75, h / 2, s, f.cLos or f.c, nil)
            local sNom = string.upper(f.nom)
            draw.SimpleText(sNom, "TFJTab.Village", s * 1.9, h / 2, f.c, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            surface.SetFont("TFJTab.Village")
            local iL = surface.GetTextSize(sNom)
            local sNb = n .. (n > 1 and " ninjas" or " ninja")
            draw.SimpleText(sNb, "TFJTab.Sous", s * 1.9 + iL + h * 0.3, h / 2, C.gris, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            surface.SetFont("TFJTab.Sous")
            local iL2 = surface.GetTextSize(sNb)
            local xT = s * 1.9 + iL + h * 0.3 + iL2 + h * 0.35
            surface.SetDrawColor(f.cTrait or C.bord)
            surface.DrawRect(xT, h / 2, w - xT, 1)
        end
    end

    local function Remplir()
        vListe:Clear()
        T.iNombre = player.GetCount()
        T.sSignature = ""
        for _, pl in ipairs(player.GetAll()) do T.sSignature = T.sSignature .. tostring(Village(pl)) end
        for _, g in ipairs(Groupes()) do
            EnTete(g.f, #g.t)
            if #g.t == 0 then
                local e = vListe:Add("DPanel")
                e:Dock(TOP)
                e:DockMargin(0, 0, p * 0.4, math.floor(H * 0.006))
                e:SetTall(math.floor(H * 0.03))
                e.Paint = function(_, w, h)
                    draw.SimpleText("Personne pour le moment", "TFJTab.Sous", 0, h / 2, C.gris, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
            end
            for _, pl in ipairs(g.t) do
                local r = vListe:Add("DButton")
                r:Dock(TOP)
                r:DockMargin(0, 0, p * 0.4, math.floor(H * 0.008))
                r:SetTall(hr)
                r:SetText("")
                r.Paint = function(self, w, h)
                    if not IsValid(pl) then return end
                    local bMoi = pl == LocalPlayer()
                    local bH = self:IsHovered()
                    local cFond = bMoi and C.selection or (bH and C.caseH or C.case)
                    surface.SetDrawColor(cFond) surface.DrawRect(0, 0, w, h)
                    Grain(0, 0, w, h, 8)
                    surface.SetDrawColor((bMoi or bH) and C.rouge or C.bord) surface.DrawOutlinedRect(0, 0, w, h, 1)
                    if bMoi then surface.SetDrawColor(C.rouge) surface.DrawRect(0, 0, 3, h) end
                    -- cadre de l'avatar
                    surface.SetDrawColor(C.bordInt) surface.DrawOutlinedRect(7, 5, h - 10, h - 10, 1)
                    local xT = h + p * 0.4
                    draw.SimpleText(pl:Nick(), "TFJTab.Nom", xT, h * 0.4, C.blanc, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    local sGroupe = pl:GetUserGroup()
                    if sGroupe and sGroupe ~= "user" then
                        draw.SimpleText(string.upper(sGroupe), "TFJTab.Petit", xT, h * 0.72, C.rougeT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    end
                    local iPing = pl:Ping()
                    draw.SimpleText(iPing, "TFJTab.Nom", w - p, h / 2, CouleurPing(iPing), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                    if pl:IsMuted() then
                        draw.SimpleText("MUET", "TFJTab.Petit", w - p * 3.4, h / 2, C.gris, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                    end
                end
                local av = vgui.Create("AvatarImage", r)
                av:SetSize(hr - 12, hr - 12)
                av:SetPos(8, 6)
                av:SetPlayer(pl, 64)
                av:SetMouseInputEnabled(false)
                r.DoRightClick = function()
                    if not IsValid(pl) then return end
                    local m = DermaMenu()
                    m:AddOption("Voir le profil Steam", function() if IsValid(pl) then pl:ShowProfile() end end)
                    m:AddOption("Copier le SteamID", function() if IsValid(pl) then SetClipboardText(pl:SteamID()) end end)
                    if pl ~= LocalPlayer() then
                        m:AddOption(pl:IsMuted() and "Réactiver la voix" or "Couper la voix", function() if IsValid(pl) then pl:SetMuted(not pl:IsMuted()) end end)
                    end
                    if pl ~= LocalPlayer() and (PeutSAM("goto") or PeutSAM("bring")) then
                        m:AddSpacer()
                        if PeutSAM("goto") then m:AddOption("Goto (aller vers lui)", function() CommandeSAM("goto", pl) T.Cacher() end):SetIcon("icon16/arrow_right.png") end
                        if PeutSAM("bring") then m:AddOption("Bring (l'amener ici)", function() CommandeSAM("bring", pl) end):SetIcon("icon16/arrow_left.png") end
                        if PeutSAM("return") then m:AddOption("Retour (le renvoyer)", function() CommandeSAM("return", pl) end):SetIcon("icon16/arrow_undo.png") end
                    end
                    if EstAdmin() and FAdmin and FAdmin.ScoreBoard then
                        m:AddSpacer()
                        m:AddOption("Menu admin", OuvrirFAdmin)
                    end
                    m:Open()
                end
                r.DoClick = r.DoRightClick
            end
        end
    end
    Remplir()
    v.Think = function(self)
        local sSig = ""
        for _, pl in ipairs(player.GetAll()) do sSig = sSig .. tostring(Village(pl)) end
        if T.iNombre ~= player.GetCount() or T.sSignature ~= sSig then Remplir() end
        if not self.bSouris and input.IsMouseDown(MOUSE_RIGHT) then
            self.bSouris = true
            self:MakePopup()
            self:SetKeyboardInputEnabled(false)
        end
    end
end

function T.Montrer()
    if not cvActif:GetBool() then return end
    T.Construire()
    return true
end
function T.Cacher()
    if IsValid(T.vPanel) then
        local v = T.vPanel
        v:SetMouseInputEnabled(false)
        v:AlphaTo(0, 0.08, 0, function() if IsValid(v) then v:Remove() end end)
        T.vPanel = nil
        CloseDermaMenus()
        return true
    end
end

-- on prend la place du tableau FAdmin
local function Brancher()
    if not cvActif:GetBool() then return end
    hook.Remove("ScoreboardShow", "FAdmin_scoreboard")
    hook.Remove("ScoreboardHide", "FAdmin_scoreboard")
end
hook.Add("ScoreboardShow", "TFJ.Tableau", function()
    Brancher()
    return T.Montrer()
end)
hook.Add("ScoreboardHide", "TFJ.Tableau", function()
    if T.bFAdmin and FAdmin and FAdmin.ScoreBoard and FAdmin.ScoreBoard.HideScoreBoard then
        T.bFAdmin = false
        FAdmin.ScoreBoard.HideScoreBoard()
        gui.EnableScreenClicker(false)
        return true
    end
    if not cvActif:GetBool() then return end
    return T.Cacher()
end)
hook.Add("InitPostEntity", "TFJ.Tableau", function() timer.Simple(2, Brancher) end)
timer.Simple(2, Brancher)
