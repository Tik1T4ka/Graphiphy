--[[---------------------------------------------------------------------------
	COFFRES À CODE (TFJ) - CLIENT : pavé numérique et fenêtre du coffre
	Emplacement : garrysmod/addons/tfj_coffre/lua/autorun/client/cl_tfj_coffre.lua
---------------------------------------------------------------------------]]--

-- Actions (doivent correspondre à sv_tfj_coffre.lua)
local A_KEYPAD, A_CODE, A_OPEN, A_DEPOSIT, A_WITHDRAW, A_CLOSE, A_NEWCODE = 1, 2, 3, 4, 5, 6, 7

-- style TFJ : noir, rouge, blanc (meme style que le F4)
local BOIS = Color(60, 60, 60)          -- liserets
local BOIS_FONCE = Color(10, 10, 10)    -- fond des fenetres
local PAPIER = Color(244, 244, 244)     -- texte clair
local CASE = Color(18, 18, 18)
local CASE_H = Color(32, 32, 32)
local ENCRE = Color(232, 232, 232)      -- texte
local GRIS = Color(140, 140, 140)
local ROUGE = Color(176, 26, 26)
local ROUGE_FONCE = Color(104, 14, 14)
local VERT = ROUGE
local function Grain(x, y, w, h, a) if TFJ_UI and TFJ_UI.Grain then TFJ_UI.Grain(x, y, w, h, a) end end
local function Cadre(x, y, w, h, colBord, colFond)
	surface.SetDrawColor(colFond or BOIS_FONCE) surface.DrawRect(x, y, w, h)
	Grain(x, y, w, h, 9)
	surface.SetDrawColor(colBord or BOIS) surface.DrawOutlinedRect(x, y, w, h, 1)
	surface.SetDrawColor(26, 26, 26) surface.DrawOutlinedRect(x + 3, y + 3, w - 6, h - 6, 1)
end

local function S(x) return math.Round(x * math.min(ScrH() / 1080, 1.4)) end

local function Polices()
	local sP = TFJ_UI and TFJ_UI.Police and TFJ_UI.Police() or "Poppins"
	surface.CreateFont("TFJ_Coffre_Titre", { font = sP, size = S(30), weight = 700, extended = true })
	surface.CreateFont("TFJ_Coffre_Texte", { font = sP, size = S(20), weight = 700, extended = true })
	surface.CreateFont("TFJ_Coffre_Petit", { font = sP, size = S(16), weight = 700, extended = true })
	surface.CreateFont("TFJ_Coffre_Code", { font = sP, size = S(50), weight = 700, extended = true })
end
Polices()
hook.Add("OnScreenSizeChanged", "TFJ_Coffre_Polices", Polices)
hook.Add("InitPostEntity", "TFJ_Coffre_Polices", function() timer.Simple(5, Polices) end)

local function Send(iAct, ent, fnExtra)
	net.Start("TFJ_Coffre")
	net.WriteUInt(iAct, 4)
	net.WriteEntity(ent)
	if fnExtra then fnExtra() end
	net.SendToServer()
end

-- Fenêtre en bois avec un parchemin à l'intérieur
local function Fenetre(sTitre, w, h)
	local f = vgui.Create("DFrame")
	f:SetSize(w, h)
	f:Center()
	f:SetTitle("")
	f:ShowCloseButton(false)
	f:MakePopup()
	function f:Paint(pw, ph)
		Cadre(0, 0, pw, ph)
		surface.SetDrawColor(ROUGE) surface.DrawRect(1, 1, pw - 2, 2)
		Cadre(S(14), S(56), pw - S(28), ph - S(70), Color(44, 44, 44), Color(14, 14, 14))
		draw.SimpleText(sTitre, "TFJ_Coffre_Titre", S(22), S(30), PAPIER, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		if TFJ_UI and TFJ_UI.Losange then
			TFJ_UI.Losange(0, 0, S(5), ROUGE, Color(0, 0, 0)) TFJ_UI.Losange(pw, 0, S(5), ROUGE, Color(0, 0, 0))
		end
	end
	local x = vgui.Create("DButton", f)
	x:SetText("")
	x:SetSize(S(34), S(34))
	x:SetPos(w - S(46), S(14))
	function x:Paint(pw, ph)
		Cadre(0, 0, pw, ph, self:IsHovered() and ROUGE or BOIS, self:IsHovered() and ROUGE_FONCE or BOIS_FONCE)
		draw.SimpleText("✕", "TFJ_Coffre_Texte", pw / 2, ph / 2, PAPIER, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	function x:DoClick() f:Close() end
	return f
end

local function Bouton(parent, sTexte, x, y, w, h, bRouge)
	local b = vgui.Create("DButton", parent)
	b:SetText("")
	b:SetPos(x, y)
	b:SetSize(w, h)
	function b:Paint(pw, ph)
		local bOn = self:IsEnabled()
		local fond = bRouge and (self:IsHovered() and ROUGE or ROUGE_FONCE) or (self:IsHovered() and CASE_H or CASE)
		if not bOn then fond = Color(24, 24, 24) end
		surface.SetDrawColor(fond) surface.DrawRect(0, 0, pw, ph)
		Grain(0, 0, pw, ph, 12)
		surface.SetDrawColor((bRouge or self:IsHovered()) and ROUGE or BOIS) surface.DrawOutlinedRect(0, 0, pw, ph, 1)
		draw.SimpleText(sTexte, "TFJ_Coffre_Texte", pw / 2, ph / 2, bRouge and PAPIER or (bOn and ENCRE or GRIS), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	return b
end

local function NomObjet(sItemId)
	local inv = Solve and Solve.Naruto and Solve.Naruto.Inventory
	local t = inv and inv.GetItemData and inv:GetItemData(sItemId)
	return t and (t.sLittleName or t.sName) or sItemId
end

--[[---------------------------------------------------------------------------
	PAVÉ NUMÉRIQUE
---------------------------------------------------------------------------]]--

local pad, boardChest

local function OuvrirPave(ent, iMode)
	if IsValid(pad) then pad:Remove() end
	local W, H = S(330), S(520)
	pad = Fenetre(iMode == 1 and "CHOISIS LE CODE" or "CODE DU COFFRE", W, H)
	pad.Ent, pad.Code, pad.Erreur = ent, "", 0

	function pad:OnClose()
		if not IsValid(boardChest) then Send(A_CLOSE, self.Ent) end
	end

	local ecran = vgui.Create("DPanel", pad)
	ecran:SetPos(S(30), S(72))
	ecran:SetSize(W - S(60), S(84))
	function ecran:Paint(pw, ph)
		Cadre(0, 0, pw, ph, BOIS, Color(4, 4, 4))
		local s = ""
		for i = 1, 4 do s = s .. (pad.Code:sub(i, i) ~= "" and pad.Code:sub(i, i) or "_") .. (i < 4 and " " or "") end
		local bErr = pad.Erreur > CurTime()
		draw.SimpleText(s, "TFJ_Coffre_Code", pw / 2, ph / 2, bErr and Color(230, 80, 70) or PAPIER, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	local info = vgui.Create("DLabel", pad)
	info:SetPos(S(24), S(160))
	info:SetSize(W - S(48), S(24))
	info:SetFont("TFJ_Coffre_Petit")
	info:SetContentAlignment(5)
	info:SetTextColor(GRIS)
	info:SetText(iMode == 1 and "4 chiffres. Ne l'oublie pas !" or "Tape le code à 4 chiffres.")
	function info:Think()
		if pad.Erreur > CurTime() then
			self:SetTextColor(ROUGE)
			self:SetText("Mauvais code.")
		elseif self:GetText() == "Mauvais code." then
			self:SetTextColor(GRIS)
			self:SetText("Tape le code à 4 chiffres.")
		end
	end

	local function Valider()
		if #pad.Code ~= 4 then return end
		local sCode = pad.Code
		Send(A_CODE, pad.Ent, function() net.WriteString(sCode) end)
	end
	local function Touche(c)
		if c == "C" then
			pad.Code = ""
		elseif c == "OK" then
			Valider()
		elseif #pad.Code < 4 then
			pad.Code = pad.Code .. c
		end
		surface.PlaySound("buttons/button15.wav")
	end

	local touches = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "OK" }
	local bw, bh, gap = S(80), S(64), S(12)
	local x0 = (W - (3 * bw + 2 * gap)) / 2
	for i, c in ipairs(touches) do
		local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
		local b = Bouton(pad, c, x0 + col * (bw + gap), S(196) + row * (bh + gap), bw, bh, c == "OK")
		function b:DoClick() Touche(c) end
	end

	-- clavier : chiffres, Entrée, Retour arrière
	function pad:OnKeyCodePressed(k)
		if k >= KEY_0 and k <= KEY_9 then Touche(tostring(k - KEY_0))
		elseif k >= KEY_PAD_0 and k <= KEY_PAD_9 then Touche(tostring(k - KEY_PAD_0))
		elseif k == KEY_ENTER or k == KEY_PAD_ENTER then Valider()
		elseif k == KEY_BACKSPACE then self.Code = self.Code:sub(1, -2)
		elseif k == KEY_ESCAPE then self:Close() end
	end
end

--[[---------------------------------------------------------------------------
	FENÊTRE DU COFFRE
---------------------------------------------------------------------------]]--

local etat = { coffre = {}, inv = {}, proprio = false }

-- Infos d'affichage d'un objet (nom, icone, modele, rarete) tirees de l'inventaire Solve
local function InfosObjet(sItemId)
	local inv = Solve and Solve.Naruto and Solve.Naruto.Inventory
	local t = inv and inv.GetItemData and inv:GetItemData(sItemId)
	if not t then return { nom = sItemId } end
	local tInfos = { nom = t.sLittleName or t.sName or sItemId, desc = t.sDesc, modele = t.sModel, skin = t.iSkin }
	if t.sImgurId and Solve.GetMaterial then
		local ok, mat, w, h = pcall(Solve.GetMaterial, Solve, t.sImgurId, nil, true)
		if ok and mat then
			local f = tonumber(t.fImgurScale) or 1
			tInfos.mat, tInfos.w, tInfos.h = mat, (w or 64) * f, (h or 64) * f
		end
	end
	local tRar = inv.Config and inv.Config["rarities"] and inv.Config["rarities"][t.sRarity]
	if tRar and tRar.sMat and Solve.GetMaterial then
		local ok, mat = pcall(Solve.GetMaterial, Solve, tRar.sMat)
		if ok and mat then tInfos.matRarete = mat end
	end
	return tInfos
end

local DND = "tfj_coffre_objet"

local function Transferer(sDe, sItemId, n)
	if not IsValid(boardChest) or n < 1 then return end
	Send(sDe == "inv" and A_DEPOSIT or A_WITHDRAW, boardChest.Ent, function()
		net.WriteString(sItemId)
		net.WriteUInt(math.min(n, 65535), 16)
	end)
	surface.PlaySound("physics/wood/wood_box_impact_soft" .. math.random(1, 3) .. ".wav")
end

-- Petite fenetre pour choisir une quantite
local function DemanderQuantite(sDe, sItemId, iMax)
	if iMax <= 1 then Transferer(sDe, sItemId, 1) return end
	if IsValid(boardChest.Quantite) then boardChest.Quantite:Remove() end
	local W, H = S(360), S(230)
	local q = Fenetre("QUANTITÉ", W, H)
	boardChest.Quantite = q
	local n = iMax
	local lbl = vgui.Create("DLabel", q)
	lbl:SetPos(S(24), S(70)) lbl:SetSize(W - S(48), S(26))
	lbl:SetFont("TFJ_Coffre_Texte") lbl:SetTextColor(ENCRE) lbl:SetContentAlignment(5)
	local function MAJ() lbl:SetText(InfosObjet(sItemId).nom .. " : " .. n .. " / " .. iMax) end
	MAJ()
	local sl = vgui.Create("DNumSlider", q)
	sl:SetPos(S(-110), S(104)) sl:SetSize(W - S(10), S(32))
	sl:SetMin(1) sl:SetMax(iMax) sl:SetDecimals(0) sl:SetValue(iMax) sl:SetText("")
	function sl:OnValueChanged(v) n = math.Clamp(math.Round(v), 1, iMax) MAJ() end
	local bw = (W - S(48) - S(24)) / 3
	local tChoix = { { "1", function() return 1 end }, { "Moitié", function() return math.max(1, math.floor(iMax / 2)) end }, { "Tout", function() return iMax end } }
	for i, c in ipairs(tChoix) do
		local b = Bouton(q, c[1], S(24) + (i - 1) * (bw + S(12)), S(140), bw, S(30))
		function b:DoClick() n = c[2]() sl:SetValue(n) MAJ() end
	end
	local ok = Bouton(q, sDe == "inv" and "Ranger" or "Prendre", S(24), H - S(58), W - S(48), S(38), true)
	function ok:DoClick() Transferer(sDe, sItemId, n) q:Close() end
	function q:OnKeyCodePressed(k)
		if k == KEY_ENTER or k == KEY_PAD_ENTER then ok:DoClick() elseif k == KEY_ESCAPE then self:Close() end
	end
end

-- Une case de la grille
local function Case(grille, sDe, it, iTaille)
	local c = grille:Add("DButton")
	c:SetSize(iTaille, iTaille)
	c:SetText("")
	c.sItemId, c.iCount, c.sDe = it.id, it.n, sDe
	local tInfos = InfosObjet(it.id)
	local sBulle = tInfos.nom .. "  (x" .. it.n .. ")"
	if it.equipe then sBulle = sBulle .. "\nÉquipé : à déséquiper avant de le ranger."
	else sBulle = sBulle .. "\nGlisse vers l'autre côté pour " .. (sDe == "inv" and "le ranger." or "le prendre.") .. "\nShift en lâchant ou clic droit : choisir la quantité." end
	c:SetTooltip(sBulle)
	if not it.equipe then c:Droppable(DND) end

	if tInfos.modele and not tInfos.mat then
		local mp = vgui.Create("DModelPanel", c)
		mp:SetPos(S(6), S(6)) mp:SetSize(iTaille - S(12), iTaille - S(12))
		mp:SetModel(tInfos.modele)
		mp:SetMouseInputEnabled(false)
		if IsValid(mp.Entity) then
			if tInfos.skin then mp.Entity:SetSkin(tInfos.skin) end
			local mn, mx = mp.Entity:GetRenderBounds()
			local fR = math.max(mx:Distance(mn), 1)
			mp:SetFOV(40)
			mp:SetCamPos(Vector(fR, fR, fR * 0.6))
			mp:SetLookAt((mn + mx) / 2)
		end
		function mp:LayoutEntity(e) e:SetAngles(Angle(0, 30, 0)) end
	end

	function c:Paint(w, h)
		local bSurvol = self:IsHovered() and not dragndrop.IsDragging()
		surface.SetDrawColor(bSurvol and CASE_H or CASE) surface.DrawRect(0, 0, w, h)
		Grain(0, 0, w, h, 8)
		surface.SetDrawColor(bSurvol and ROUGE or BOIS) surface.DrawOutlinedRect(0, 0, w, h, 1)
		if tInfos.matRarete then
			surface.SetDrawColor(255, 255, 255, 140)
			surface.SetMaterial(tInfos.matRarete)
			surface.DrawTexturedRect(S(2), S(2), w - S(4), h - S(4))
		end
		if tInfos.mat then
			local iw = math.min(tInfos.w or w, w * 0.7)
			local ih = math.min(tInfos.h or h, h * 0.7)
			surface.SetDrawColor(255, 255, 255, it.equipe and 110 or 255)
			surface.SetMaterial(tInfos.mat)
			surface.DrawTexturedRect(w / 2 - iw / 2, h / 2 - ih / 2, iw, ih)
		elseif not tInfos.modele then
			draw.DrawText(tInfos.nom, "TFJ_Coffre_Petit", w / 2, h * 0.3, ENCRE, TEXT_ALIGN_CENTER)
		end
	end
	function c:PaintOver(w, h)
		draw.SimpleTextOutlined(it.equipe and "équipé" or ("x" .. it.n), "TFJ_Coffre_Petit", w - S(6), h - S(4), PAPIER, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, 1, BOIS_FONCE)
	end
	if it.equipe then return c end
	function c:DoDoubleClick() Transferer(sDe, it.id, it.n) end
	function c:DoRightClick()
		local m = DermaMenu()
		local sVerbe = sDe == "inv" and "Ranger" or "Prendre"
		m:AddOption(sVerbe .. " 1", function() Transferer(sDe, it.id, 1) end)
		if it.n >= 10 then m:AddOption(sVerbe .. " 10", function() Transferer(sDe, it.id, 10) end) end
		if it.n > 1 then
			m:AddOption(sVerbe .. " la moitié", function() Transferer(sDe, it.id, math.max(1, math.floor(it.n / 2))) end)
			m:AddOption(sVerbe .. " tout (" .. it.n .. ")", function() Transferer(sDe, it.id, it.n) end)
			m:AddOption("Choisir la quantité...", function() DemanderQuantite(sDe, it.id, it.n) end)
		end
		m:Open()
	end
	return c
end

-- Une colonne : titre + zone qui recoit les objets venant de l'autre cote
local function Zone(parent, x, y, w, h, sTitre, sCote)
	local lbl = vgui.Create("DLabel", parent)
	lbl:SetPos(x, y) lbl:SetSize(w, S(26))
	lbl:SetFont("TFJ_Coffre_Texte") lbl:SetTextColor(ROUGE) lbl:SetText(string.upper(sTitre))

	local sp = vgui.Create("DScrollPanel", parent)
	sp:SetPos(x, y + S(30)) sp:SetSize(w, h - S(30))
	function sp:Paint(pw, ph)
		local bCible = false
		if dragndrop.IsDragging() then
			local t = dragndrop.GetDroppable(DND)
			bCible = t and t[1] and IsValid(t[1]) and t[1].sDe ~= sCote
		end
		surface.SetDrawColor(bCible and Color(30, 8, 8) or Color(8, 8, 8)) surface.DrawRect(0, 0, pw, ph)
		surface.SetDrawColor(bCible and ROUGE or Color(44, 44, 44))
		surface.DrawOutlinedRect(0, 0, pw, ph, bCible and S(2) or 1)
	end
	-- meme reception sur toute la zone (fond, grille et cases) : on peut lacher n'importe ou dedans
	local function Recevoir(_, tPanneaux, bLache)
		if not bLache then return end
		local c = tPanneaux[1]
		if not IsValid(c) or c.sDe == sCote then return end
		if input.IsShiftDown() then DemanderQuantite(c.sDe, c.sItemId, c.iCount)
		else Transferer(c.sDe, c.sItemId, c.iCount) end
	end
	sp.Recevoir = Recevoir
	sp:Receiver(DND, Recevoir)
	sp:GetCanvas():Receiver(DND, Recevoir)

	local grille = vgui.Create("DIconLayout", sp)
	grille:Dock(TOP)
	grille:DockMargin(S(8), S(8), S(8), S(8))
	grille:SetSpaceX(S(8)) grille:SetSpaceY(S(8))
	grille:Receiver(DND, Recevoir)
	sp.Grille = grille
	return sp
end

local function Remplir()
	if not IsValid(boardChest) then return end
	local function Trier(t)
		table.sort(t, function(a, b)
			if (a.equipe and 1 or 0) ~= (b.equipe and 1 or 0) then return not a.equipe end
			return InfosObjet(a.id).nom < InfosObjet(b.id).nom
		end)
		return t
	end
	local iTaille = boardChest.TailleCase
	for _, z in ipairs({ { boardChest.ZoneInv, etat.inv, "inv" }, { boardChest.ZoneCoffre, etat.coffre, "coffre" } }) do
		local g = z[1].Grille
		g:Clear()
		for _, it in ipairs(Trier(z[2])) do
			local c = Case(g, z[3], it, iTaille)
			c:Receiver(DND, z[1].Recevoir)
		end
		g:InvalidateLayout(true)
	end
	if IsValid(boardChest.Code) then boardChest.Code:SetVisible(etat.proprio) end
	if IsValid(boardChest.Quantite) then boardChest.Quantite:Remove() end
end

local function OuvrirCoffre(ent)
	if IsValid(pad) then pad.Ent = nil pad:Remove() end
	if IsValid(boardChest) then boardChest:Remove() end
	local W, H = S(1000), S(660)
	boardChest = Fenetre("COFFRE", W, H)
	boardChest.Ent = ent
	function boardChest:OnClose()
		if IsValid(self.Quantite) then self.Quantite:Remove() end
		Send(A_CLOSE, self.Ent)
	end
	function boardChest:Think()
		if not IsValid(self.Ent) or LocalPlayer():GetPos():DistToSqr(self.Ent:GetPos()) > 160 * 160 then self:Close() end
	end
	function boardChest:OnKeyCodePressed(k) if k == KEY_ESCAPE then self:Close() end end

	local colW = math.floor((W - S(28) - S(36)) / 2)
	local iParLigne = 5
	boardChest.TailleCase = math.floor((colW - S(16) - S(14) - (iParLigne - 1) * S(8)) / iParLigne)
	boardChest.ZoneInv = Zone(boardChest, S(26), S(70), colW, H - S(150), "Ton inventaire", "inv")
	boardChest.ZoneCoffre = Zone(boardChest, S(26) + colW + S(12), S(70), colW, H - S(150), "Dans le coffre", "coffre")

	local aide = vgui.Create("DLabel", boardChest)
	aide:SetPos(S(260), H - S(64)) aide:SetSize(W - S(290), S(36))
	aide:SetFont("TFJ_Coffre_Petit") aide:SetTextColor(GRIS) aide:SetContentAlignment(6)
	aide:SetText("Glisse un objet d'un côté à l'autre  •  Shift en lâchant ou clic droit : quantité  •  Double-clic : tout")

	boardChest.Code = Bouton(boardChest, "Changer le code", S(26), H - S(68), S(220), S(44))
	function boardChest.Code:DoClick() Send(A_NEWCODE, boardChest.Ent) end

	surface.PlaySound("doors/door_wood_open1.wav")
	Remplir()
end

--[[---------------------------------------------------------------------------
	RÉSEAU
---------------------------------------------------------------------------]]--

net.Receive("TFJ_Coffre", function()
	local iAct = net.ReadUInt(4)
	local ent = net.ReadEntity()

	if iAct == A_KEYPAD then
		local iMode, bWrong = net.ReadUInt(2), net.ReadBool()
		if bWrong and IsValid(pad) and pad.Ent == ent then
			pad.Code = ""
			pad.Erreur = CurTime() + 1.5
			surface.PlaySound("buttons/button10.wav")
			return
		end
		OuvrirPave(ent, iMode)

	elseif iAct == A_OPEN then
		local bOpen, bProprio = net.ReadBool(), net.ReadBool()
		etat = { coffre = {}, inv = {}, proprio = bProprio }
		for i = 1, net.ReadUInt(8) do
			etat.coffre[i] = { id = net.ReadString(), n = net.ReadUInt(16) }
		end
		for i = 1, net.ReadUInt(8) do
			etat.inv[i] = { id = net.ReadString(), n = net.ReadUInt(16), equipe = net.ReadBool() }
		end
		if bOpen then
			OuvrirCoffre(ent)
		elseif IsValid(boardChest) and boardChest.Ent == ent then
			Remplir()
		end
	end
end)
