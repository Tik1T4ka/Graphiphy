--[[ TFJ Medical - Dossiers medicaux : interface du livre ]]--
local D = TFJDossier
local A_OUVRIR, A_FERMER, A_SAUVER, A_DON, A_TRANSFU = 1, 2, 3, 4, 5

-- style TFJ : noir, rouge, blanc (meme style que le F4)
local CUIR = Color(60, 60, 60)          -- liserets
local CUIR_FONCE = Color(10, 10, 10)    -- fond
local PAPIER = Color(244, 244, 244)     -- texte clair
local PAPIER_2 = Color(18, 18, 18)      -- cases
local LIGNE = Color(52, 52, 52)
local ENCRE = Color(236, 236, 236)      -- texte
local GRIS = Color(145, 145, 145)
local ROUGE = Color(176, 26, 26)
local ROUGE_FONCE = Color(104, 14, 14)
local VERT = Color(236, 236, 236)       -- "compatible" en blanc (palette noir / rouge / blanc)
local function Grain(x, y, w, h, a) if TFJ_UI and TFJ_UI.Grain then TFJ_UI.Grain(x, y, w, h, a) end end
local function Cadre(x, y, w, h, colBord, colFond)
    surface.SetDrawColor(colFond or CUIR_FONCE) surface.DrawRect(x, y, w, h)
    Grain(x, y, w, h, 9)
    surface.SetDrawColor(colBord or CUIR) surface.DrawOutlinedRect(x, y, w, h, 1)
    surface.SetDrawColor(26, 26, 26) surface.DrawOutlinedRect(x + 3, y + 3, w - 6, h - 6, 1)
end

local function S(x) return math.Round(x * math.min(ScrH() / 1080, 1.4)) end
local function Polices()
    local sP = TFJ_UI and TFJ_UI.Police and TFJ_UI.Police() or "Poppins"
    surface.CreateFont("TFJD_Titre", { font = sP, size = S(32), weight = 700, extended = true })
    surface.CreateFont("TFJD_Grand", { font = sP, size = S(30), weight = 700, extended = true })
    surface.CreateFont("TFJD_Texte", { font = sP, size = S(19), weight = 700, extended = true })
    surface.CreateFont("TFJD_Petit", { font = sP, size = S(15), weight = 700, extended = true })
    surface.CreateFont("TFJD_Sang", { font = sP, size = S(42), weight = 700, extended = true })
end
Polices()
hook.Add("OnScreenSizeChanged", "TFJD_Polices", Polices)
hook.Add("InitPostEntity", "TFJD_Polices", function() timer.Simple(5, Polices) end)

local vLivre
local tDonnees = { joueurs = {}, poches = {} }
local iSelection -- EntIndex du joueur affiche

local function Envoyer(iAct, iEnt, fnExtra)
    net.Start(D.NET)
    net.WriteUInt(iAct, 3)
    if iEnt then net.WriteUInt(iEnt, 16) end
    if fnExtra then fnExtra() end
    net.SendToServer()
end

local function Bouton(parent, sTexte, bRouge)
    local b = vgui.Create("DButton", parent)
    b:SetText("")
    b.sTexte = sTexte
    function b:Paint(w, h)
        local bOn = self:IsEnabled()
        local fond = bRouge and (self:IsHovered() and ROUGE or ROUGE_FONCE) or (self:IsHovered() and Color(32, 32, 32) or PAPIER_2)
        if not bOn then fond = Color(22, 22, 22) end
        surface.SetDrawColor(fond) surface.DrawRect(0, 0, w, h)
        Grain(0, 0, w, h, 12)
        surface.SetDrawColor((bRouge or (bOn and self:IsHovered())) and ROUGE or CUIR) surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText(self.sTexte, "TFJD_Texte", w / 2, h / 2, bRouge and PAPIER or (bOn and ENCRE or GRIS), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    return b
end

local function Entree(parent, bMulti)
    local e = vgui.Create("DTextEntry", parent)
    e:SetFont("TFJD_Texte")
    e:SetMultiline(bMulti == true)
    e:SetUpdateOnType(false)
    e:SetDrawLanguageID(false)
    function e:Paint(w, h)
        surface.SetDrawColor(self:HasFocus() and Color(20, 20, 20) or Color(12, 12, 12)) surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(self:HasFocus() and ROUGE or LIGNE)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        if self:GetValue() == "" and self.GetPlaceholderText and self:GetPlaceholderText() then
            draw.SimpleText(self:GetPlaceholderText(), "TFJD_Texte", S(8), S(6), GRIS)
        end
        self:DrawTextEntryText(ENCRE, ROUGE, ENCRE)
    end
    return e
end

local function JoueurParEnt(iEnt)
    for _, j in ipairs(tDonnees.joueurs) do if j.e == iEnt then return j end end
end

local AfficherFiche -- defini plus bas

local function RemplirListe()
    if not IsValid(vLivre) then return end
    local sp = vLivre.Liste
    sp:Clear()
    local sFiltre = string.lower(vLivre.Recherche:GetValue() or "")
    local t = table.Copy(tDonnees.joueurs)
    table.sort(t, function(a, b) return string.lower(a.nom) < string.lower(b.nom) end)
    for _, j in ipairs(t) do
        if sFiltre == "" or string.find(string.lower(j.nom), sFiltre, 1, true) then
            local b = sp:Add("DButton")
            b:Dock(TOP)
            b:DockMargin(0, 0, 0, S(4))
            b:SetTall(S(40))
            b:SetText("")
            function b:Paint(w, h)
                local bSel = iSelection == j.e
                surface.SetDrawColor(bSel and Color(34, 10, 10) or (self:IsHovered() and Color(26, 26, 26) or PAPIER_2)) surface.DrawRect(0, 0, w, h)
                surface.SetDrawColor((bSel or self:IsHovered()) and ROUGE or LIGNE) surface.DrawOutlinedRect(0, 0, w, h, 1)
                draw.SimpleText(j.nom, "TFJD_Texte", S(10), h / 2, ENCRE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                surface.SetDrawColor(ROUGE_FONCE) surface.DrawRect(w - S(50), S(8), S(42), h - S(16))
                surface.SetDrawColor(ROUGE) surface.DrawOutlinedRect(w - S(50), S(8), S(42), h - S(16), 1)
                draw.SimpleText(j.sang, "TFJD_Petit", w - S(29), h / 2, PAPIER, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            function b:DoClick()
                iSelection = j.e
                surface.PlaySound("physics/cardboard/cardboard_box_impact_soft" .. math.random(1, 4) .. ".wav")
                AfficherFiche()
            end
        end
    end
end

AfficherFiche = function()
    if not IsValid(vLivre) then return end
    local pg = vLivre.Page
    pg:Clear()
    local j = iSelection and JoueurParEnt(iSelection)
    if not j then
        local l = vgui.Create("DLabel", pg)
        l:Dock(FILL)
        l:SetFont("TFJD_Texte") l:SetTextColor(GRIS) l:SetContentAlignment(5)
        l:SetText("Choisis un joueur dans la liste.")
        return
    end
    local pJoueur = Entity(j.e)
    local W = pg:GetWide()

    -- en-tete : nom + groupe sanguin (non modifiable)
    local tete = vgui.Create("DPanel", pg)
    tete:Dock(TOP) tete:SetTall(S(84)) tete:DockMargin(0, 0, 0, S(8))
    local sDonneurs = table.concat(D.COMPATIBLE[j.sang] or {}, ", ")
    function tete:Paint(w, h)
        draw.SimpleText(j.nom, "TFJD_Grand", 0, S(4), ENCRE)
        draw.SimpleText("Peut recevoir : " .. sDonneurs, "TFJD_Petit", 0, S(38), GRIS)
        if j.majPar and j.majPar ~= "" then
            draw.SimpleText("Derni\195\168re mise \195\160 jour : " .. j.majPar .. " (" .. os.date("%d/%m %H:%M", j.maj) .. ")", "TFJD_Petit", 0, S(58), GRIS)
        end
        surface.SetDrawColor(ROUGE_FONCE) surface.DrawRect(w - S(150), 0, S(150), h)
        Grain(w - S(150), 0, S(150), h, 14)
        surface.SetDrawColor(ROUGE) surface.DrawOutlinedRect(w - S(150), 0, S(150), h, 1)
        draw.SimpleText(j.sang, "TFJD_Sang", w - S(75), S(30), PAPIER, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("groupe sanguin", "TFJD_Petit", w - S(75), S(62), Color(230, 180, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- champs modifiables
    local sp = vgui.Create("DScrollPanel", pg)
    sp:Dock(FILL)
    local tEntrees = {}
    local grille = vgui.Create("DIconLayout", sp)
    grille:Dock(TOP) grille:SetSpaceX(S(12)) grille:SetSpaceY(S(8))
    local iColW = math.floor((W - S(12) - S(20)) / 2)
    for _, c in ipairs(D.CHAMPS) do
        local bloc = grille:Add("DPanel")
        bloc:SetSize(c.multi and (iColW * 2 + S(12)) or iColW, c.multi and S(92) or S(58))
        bloc.Paint = nil
        local l = vgui.Create("DLabel", bloc)
        l:Dock(TOP) l:SetTall(S(20)) l:SetFont("TFJD_Petit") l:SetTextColor(ROUGE) l:SetText((string.upper(c.nom):gsub("\195\169", "\195\137"):gsub("\195\168", "\195\136"):gsub("\195\160", "\195\128")))
        local e = Entree(bloc, c.multi)
        e:Dock(FILL)
        e:SetValue(j.champs[c.id] or "")
        e.iMax = c.max
        function e:AllowInput() return #self:GetValue() >= self.iMax end
        tEntrees[c.id] = e
    end

    -- barre du bas : enregistrer, prelever, transfuser
    local bas = vgui.Create("DPanel", pg)
    bas:Dock(BOTTOM) bas:SetTall(S(96)) bas:DockMargin(0, S(8), 0, 0)
    bas.Paint = function(_, w, h) surface.SetDrawColor(LIGNE) surface.DrawLine(0, 0, w, 0) end

    local bSauver = Bouton(bas, "Enregistrer la fiche", true)
    bSauver:SetPos(0, S(12)) bSauver:SetSize(S(230), S(40))
    function bSauver:DoClick()
        local t = {}
        for id, e in pairs(tEntrees) do t[id] = e:GetValue() end
        local s = util.TableToJSON(t) or "{}"
        Envoyer(A_SAUVER, j.e, function() net.WriteUInt(#s, 16) net.WriteData(s, #s) end)
        surface.PlaySound("physics/cardboard/cardboard_box_impact_soft2.wav")
    end

    local bDon = Bouton(bas, "Pr\195\169lever une poche de sang")
    bDon:SetPos(S(244), S(12)) bDon:SetSize(S(290), S(40))
    function bDon:DoClick() Envoyer(A_DON, j.e) end

    local cb = vgui.Create("DComboBox", bas)
    cb:SetPos(S(548), S(12)) cb:SetSize(S(200), S(40))
    cb:SetFont("TFJD_Texte")
    cb:SetValue("Poche \195\160 transfuser")
    local bAucune = true
    for _, g in ipairs(D.GROUPES) do
        local n = tDonnees.poches[g.id]
        if n then cb:AddChoice(g.id .. "  (x" .. n .. ")", g.id) bAucune = false end
    end
    if bAucune then cb:SetValue("Aucune poche") cb:SetEnabled(false) end

    local bTransfu = Bouton(bas, "Transfuser")
    bTransfu:SetPos(S(756), S(12)) bTransfu:SetSize(S(150), S(40))
    bTransfu:SetEnabled(false)
    local sChoix
    function cb:OnSelect(_, _, sGroupe) sChoix = sGroupe bTransfu:SetEnabled(true) end
    function bTransfu:DoClick() if sChoix then Envoyer(A_TRANSFU, j.e, function() net.WriteString(sChoix) end) end end

    local info = vgui.Create("DLabel", bas)
    info:SetPos(0, S(60)) info:SetSize(W, S(28))
    info:SetFont("TFJD_Petit")
    function info:Think()
        local s, col = "Don et transfusion : le patient doit \195\170tre allong\195\169 sur un lit, \195\160 moins de 3 m de toi.", GRIS
        if IsValid(pJoueur) and TFJMed and TFJMed.IsLying and TFJMed.IsLying(pJoueur)
            and LocalPlayer():GetPos():DistToSqr(pJoueur:GetPos()) <= D.DISTANCE * D.DISTANCE then
            s, col = "Patient allong\195\169 \195\160 port\195\169e.", VERT
        end
        if sChoix then
            if D.Compatible(j.sang, sChoix) then
                s, col = s .. "   Poche " .. sChoix .. " : compatible.", VERT
            else
                s, col = s .. "   Poche " .. sChoix .. " : INCOMPATIBLE avec " .. j.sang .. " !", ROUGE
            end
        end
        if self:GetText() ~= s then self:SetText(s) end
        self:SetTextColor(col)
    end
    grille:InvalidateLayout(true)
end

local function OuvrirLivre()
    if IsValid(vLivre) then vLivre:Remove() end
    local W, H = math.min(S(1180), ScrW() - 40), math.min(S(760), ScrH() - 40)
    local f = vgui.Create("DFrame")
    vLivre = f
    f:SetSize(W, H) f:Center() f:SetTitle("") f:ShowCloseButton(false) f:MakePopup()
    local iListeW = S(300)
    function f:Paint(w, h)
        Cadre(0, 0, w, h)
        surface.SetDrawColor(ROUGE) surface.DrawRect(1, 1, w - 2, 2)
        Cadre(S(18), S(60), iListeW, h - S(78), Color(44, 44, 44), Color(8, 8, 8))
        Cadre(S(18) + iListeW + S(10), S(60), w - iListeW - S(46), h - S(78), Color(44, 44, 44), Color(13, 13, 13))
        draw.SimpleText("M\195\137DICAL", "TFJD_Petit", S(24), S(14), ROUGE)
        draw.SimpleText("Registre des patients", "TFJD_Titre", S(22), S(36), PAPIER, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        if TFJ_UI and TFJ_UI.Losange then
            TFJ_UI.Losange(0, 0, S(5), ROUGE, Color(0, 0, 0)) TFJ_UI.Losange(w, 0, S(5), ROUGE, Color(0, 0, 0))
        end
    end
    function f:OnClose() Envoyer(A_FERMER) end
    function f:OnKeyCodePressed(k) if k == KEY_ESCAPE then self:Close() end end

    local x = vgui.Create("DButton", f)
    x:SetText("") x:SetSize(S(34), S(34)) x:SetPos(W - S(48), S(14))
    function x:Paint(w, h)
        Cadre(0, 0, w, h, self:IsHovered() and ROUGE or CUIR, self:IsHovered() and ROUGE_FONCE or CUIR_FONCE)
        draw.SimpleText("\226\156\149", "TFJD_Texte", w / 2, h / 2, PAPIER, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    function x:DoClick() f:Close() end

    f.Recherche = Entree(f, false)
    f.Recherche:SetPos(S(26), S(70)) f.Recherche:SetSize(iListeW - S(16), S(34))
    f.Recherche:SetPlaceholderText("Rechercher un joueur...")
    f.Recherche:SetUpdateOnType(true)
    function f.Recherche:OnValueChange() RemplirListe() end

    f.Liste = vgui.Create("DScrollPanel", f)
    f.Liste:SetPos(S(26), S(112)) f.Liste:SetSize(iListeW - S(16), H - S(140))

    f.Page = vgui.Create("DPanel", f)
    f.Page:SetPos(S(18) + iListeW + S(26), S(74)) f.Page:SetSize(W - iListeW - S(78), H - S(104))
    f.Page.Paint = nil

    surface.PlaySound("physics/cardboard/cardboard_box_impact_soft1.wav")
    RemplirListe()
    AfficherFiche()
end

net.Receive(D.NET, function()
    local iAct = net.ReadUInt(3)
    if iAct ~= A_OUVRIR then return end
    local bOuvrir = net.ReadBool()
    local iLen = net.ReadUInt(32)
    local t = util.JSONToTable(util.Decompress(net.ReadData(iLen)) or "") or {}
    tDonnees = { joueurs = t.joueurs or {}, poches = t.poches or {} }
    if bOuvrir then
        if not iSelection or not JoueurParEnt(iSelection) then iSelection = LocalPlayer():EntIndex() end
        OuvrirLivre()
    elseif IsValid(vLivre) then
        RemplirListe()
        AfficherFiche()
    end
end)
