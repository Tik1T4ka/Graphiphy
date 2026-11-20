-- TFJ : fonds, cases et barre de poids au style TFJ, aux mêmes dimensions que les textures Solve (la mise en page ne change pas).
-- Repli sur la texture Solve si le PNG TFJ n'est pas encore téléchargé.
local TFJ_ROUGE = Color(170, 32, 38)
local TFJ_MATS = {
	["inventory_background_objects"] = "tfj_inventaire/fond_objets.png",
	["background_inv_v85"] = "tfj_inventaire/fond_cosmetiques.png",
	["case"] = "tfj_inventaire/case.png",
	["barweight_inv"] = "tfj_inventaire/barre_poids.png",
}
local function GetMat(sName, ...)
	local m, w, h = Solve:GetMaterial(sName, ...)
	local mTFJ = TFJ_MATS[sName] and Material(TFJ_MATS[sName], "smooth")
	if mTFJ and not mTFJ:IsError() then m = mTFJ end
	return m, w, h
end

-- TFJ : trait rouge sous l'onglet actif ou survolé (fA = son iHoverLerp)
local function Souligne(sText, sFont, x, y, iAlign, fA)
	if fA < 0.01 then return end
	surface.SetFont(sFont)
	local tw, th = surface.GetTextSize(sText)
	local x0 = iAlign == TEXT_ALIGN_CENTER and x - tw / 2 or iAlign == TEXT_ALIGN_RIGHT and x - tw or x
	surface.SetDrawColor(TFJ_ROUGE.r, TFJ_ROUGE.g, TFJ_ROUGE.b, 255 * fA)
	surface.DrawRect(x0 + tw * (1 - fA) / 2, y + th / 2 + 2, tw * fA, 2)
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- TFJ v2 : inventaire au style du F4 (maquette maquettes/inventaire/maquette_inventaire.html du depot Graphiphy).
-- Tout est dessine ici (plus de PNG de fond) : fond, titre, barre de poids, cases avec lueur de rarete,
-- cadres et icones des emplacements d'equipement. Positions des panneaux et logique inchangees.
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local TFJInv = {}
local TFJInv_ROUGE_VIF = Color(216, 38, 47)
local TFJInv_ROUGE_TEXTE = Color(224, 72, 72)
local TFJInv_GRIS = Color(138, 138, 146)
local iTFJInvPoliceH
function TFJInv.Polices()
	if iTFJInvPoliceH == ScrH() then return end
	iTFJInvPoliceH = ScrH()
	local VH = ScrH() / 100
	-- Bebas Neue : resource/fonts/bebasneue-regular.ttf (sv_tfj_polices.lua)
	surface.CreateFont("TFJInv.Titre", { font = "Bebas Neue", size = math.floor(VH * 7), weight = 400, extended = true })
	surface.CreateFont("TFJInv.Menu", { font = "Bebas Neue", size = math.floor(VH * 3.7), weight = 400, extended = true })
	surface.CreateFont("TFJInv.Mode", { font = "Bebas Neue", size = math.floor(VH * 3.5), weight = 400, extended = true })
	surface.CreateFont("TFJInv.Barre", { font = "Bebas Neue", size = math.floor(VH * 3.1), weight = 400, extended = true })
	surface.CreateFont("TFJInv.Filtre", { font = "Bebas Neue", size = math.floor(VH * 2.3), weight = 400, extended = true })
	surface.CreateFont("TFJInv.Petit", { font = "Bebas Neue", size = math.floor(VH * 1.6), weight = 400, extended = true })
end
local tTFJInvMats = {}
function TFJInv.Mat(sChemin)
	if tTFJInvMats[sChemin] == nil then
		local m = Material(sChemin, "smooth")
		tTFJInvMats[sChemin] = (m and not m:IsError()) and m or false
	end
	return tTFJInvMats[sChemin] or nil
end
-- degrade vertical en bandes (independant des textures gui/gradient_*)
function TFJInv.Degrade(x, y, w, h, c1, a1, c2, a2)
	local n = 24
	for i = 0, n - 1 do
		local f = i / (n - 1)
		surface.SetDrawColor(Lerp(f, c1.r, c2.r), Lerp(f, c1.g, c2.g), Lerp(f, c1.b, c2.b), Lerp(f, a1, a2))
		local y0, y1 = math.floor(y + i * h / n), math.floor(y + (i + 1) * h / n)
		surface.DrawRect(x, y0, w, y1 - y0)
	end
end
function TFJInv.Fond(w, h)
	surface.SetDrawColor(9, 9, 10, 240)
	surface.DrawRect(0, 0, w, h)
	TFJInv.Degrade(0, h * 0.55, w, h * 0.45, Color(90, 15, 18), 0, Color(120, 18, 18), 110)
end
-- case : fond sombre, et si un objet est pose, lueur de sa rarete qui monte du bas + liseret + trait
function TFJInv.Case(w, h, cRarete)
	surface.SetDrawColor(18, 18, 20, 255)
	surface.DrawRect(0, 0, w, h)
	if cRarete then
		TFJInv.Degrade(0, h * 0.3, w, h * 0.7, cRarete, 0, cRarete, 150)
		surface.SetDrawColor(cRarete.r, cRarete.g, cRarete.b, 180)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		surface.SetDrawColor(cRarete)
		surface.DrawRect(0, h - 3, w, 3)
	else
		surface.SetDrawColor(35, 35, 39, 255)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end
end
-- icone d'emplacement (materials/tfj_inventaire/ico_<emplacement>.png)
local tTFJInvIcones = { ["Boucles d'oreilles"] = "boucles" }
function TFJInv.IconeEmplacement(sEquipement)
	return TFJInv.Mat("tfj_inventaire/ico_" .. (tTFJInvIcones[sEquipement] or sEquipement) .. ".png")
end
function TFJInv.CouleurRarete(tItemData)
	local tRarity = tItemData and Solve.Naruto.Inventory.Config["rarities"][tItemData.sRarity]
	return tRarity and tRarity.cColor or nil
end

local tBackgrounds = {
	["objects"] = GetMat("inventory_background_objects"),
	["objects_stats"] = Solve:GetMaterial("inventory_background_objects_stats"),
	["cosmetics"] = GetMat("background_inv_v85"),
}

local colStatDmgPhys   = Color(255, 182, 255)
local colStatDmgJutsu  = Color(103, 223, 229)
local colStatResiPhys  = Color(234, 211, 158)
local colStatResiJutsu = Color(135, 241, 143)

local tCachedStats = {
	fDmgPhys   = 1,
	fDmgJutsu  = 1,
	fResiPhys  = 1,
	fResiJutsu = 1,
}

net.Receive("Solve.Combat:SendStats", function()
	tCachedStats.fDmgPhys   = net.ReadFloat()
	tCachedStats.fDmgJutsu  = net.ReadFloat()
	tCachedStats.fResiPhys  = net.ReadFloat()
	tCachedStats.fResiJutsu = net.ReadFloat()
end)

local matWeightBar, iBarW, iBarH = GetMat("barweight_inv")
local matCase, iCaseW, iCaseH = GetMat("case")
local matUseButton, iUseButtonW, iUseButtonH = Solve:GetMaterial("use_button")
local matHDVIcon, iHDVIconW, iHDVIconH = Solve:GetMaterial("market_hdv_icon")

local matRefreshIcon, iRefreshIconW, iRefreshIconH = Solve:GetMaterial("refresh_icon_inv")

local CACHE_LIST_BY_RARETY = false
local SHOW_MATERIALS_ONLY = false
local SHOW_EQUIPMENT_ONLY = false
local SHOW_TENUES_ONLY = false
local SHOW_KATANA_ONLY = false
local SHOW_ACCESSORIES_ONLY = false

Solve.Naruto.Inventory = Solve.Naruto.Inventory or {}
Solve.Naruto.Inventory.Items = Solve.Naruto.Inventory.Items or {}
Solve.Naruto.Inventory.tClientOverrides = Solve.Naruto.Inventory.tClientOverrides or {}

function Solve.Naruto.Inventory:SetClientItemOverride(sItemId, sOverrideName, sOverrideDesc)
	if not sItemId then return end
	self.tClientOverrides = self.tClientOverrides or {}

	if sOverrideName == "NULL" then sOverrideName = nil end
	if sOverrideDesc == "NULL" then sOverrideDesc = nil end

	local bHasName = isstring(sOverrideName) and sOverrideName ~= ""
	local bHasDesc = isstring(sOverrideDesc) and sOverrideDesc ~= ""

	if not bHasName and not bHasDesc then
		self.tClientOverrides[sItemId] = nil
		return
	end

	self.tClientOverrides[sItemId] = {
		sOverrideName = bHasName and sOverrideName or nil,
		sOverrideDesc = bHasDesc and sOverrideDesc or nil,
	}
end

function Solve.Naruto.Inventory:ClearClientItemOverrides()
	self.tClientOverrides = {}
end

function Solve.Naruto.Inventory:RecursiveChild(vPanel)

	if not IsValid(vPanel) then return end

	for _, vChild in ipairs(vPanel:GetChildren()) do

		if IsValid(vChild) then

			local fnOldThink = vChild.Think
			vChild.Think = function(self)

				if isfunction(fnOldThink) then fnOldThink(self) end

				-- if Solve:HasMoreThan60FPS() then

				--     self:SetCursor("blank")

				-- end

			end

			self:RecursiveChild(vChild)

		end

	end

end

file.CreateDir("solve_naruto")

/*
	["hud_v3_barrexp"] = Material("solve_naruto_base/hud/v3/hud_v3_barrexp.png", "smooth"),
	["hud_v3_barrexpfond"] = Material("solve_naruto_base/hud/v3/hud_v3_barrexpfond.png", "smooth"),
*/

local matBarreXp, iBarreXpW, iBarreXpH = Solve:GetMaterial("hud_v3_barrexp")
local matBarreXpFond, iBarreXpFondW, iBarreXpFondH = Solve:GetMaterial("hud_v3_barrexpfond")

local iWeightLerp = 0

function Solve.Naruto.Inventory:DrawInventory(sType, bReload, bHotReload, tOverInv, pOverPlayer, bCacheListByRarity)
	if IsValid(self.vInventory) then
		self.vInventory:Remove()
	else
		if bReload then return end
	end

	if not bReload and not pOverPlayer then
		net.Start("Solve.Naruto.Inventory:OpenInventory")
		net.SendToServer()

		net.Start("Solve.Combat:RequestStats")
		net.SendToServer()
	end

	local bInventoryInspection = IsValid(pOverPlayer)

	-- Store inspected player for admin delete functionality
	self.pInspectedPlayer = bInventoryInspection and pOverPlayer or nil

	local pLocal = pOverPlayer or LocalPlayer()
	if not IsValid(pLocal) then return end

	if not pLocal:Alive() then return end

	self.sInventoryType = sType or self.sInventoryType or "objects"
	self.Items[self.sInventoryType] = self.Items[self.sInventoryType] or {}
	self.tEquimentsVGUIS = self.tEquimentsVGUIS or {}

	local iMoney = pLocal:GetMoney()
	local iInvMaxWeight = Solve.Naruto.Inventory.Config["weight"]

	if not Solve.Naruto.Inventory.Sync and not bInventoryInspection then

		local iCharId = LocalPlayer():GetCharacterGlobalId()
		local sFilePath = "solve_naruto/inv_items_" .. iCharId .. ".json"
		local sSlotsJson = file.Read(sFilePath, "DATA")
		local tItemsStored = {}

		if sSlotsJson then
			tItemsStored = util.JSONToTable(sSlotsJson) or {}
		else
			local sOldSlotsJson = file.Read("solve_naruto/inv_items.json", "DATA")
			if sOldSlotsJson then
				tItemsStored = util.JSONToTable(sOldSlotsJson) or {}
				file.Write(sFilePath, sOldSlotsJson)
			end
		end

		Solve.Naruto.Inventory.SavedSlots = tItemsStored
		Solve.Naruto.Inventory.Sync = true

	end

	local tItems = bInventoryInspection and tOverInv or self.Items

	self.vInventory = vgui.Create("EditablePanel")
	self.vInventory:SetSize(Solve.ScrW, Solve.ScrH)
	self.vInventory:MakePopup()
	if not bHotReload then self.vInventory:SetAlpha(0) end
	self.vInventory.Close = function(_self)

		local tItemsToStore = {}

		for sType, tItems in pairs(tItems) do

			for sItemId, tItem in pairs(tItems) do

				if tItem.iSlot then
					tItemsToStore[sItemId] = tItem.iSlot
				end

			end

		end

		local iCharId = LocalPlayer():GetCharacterGlobalId()
		local sFilePath = "solve_naruto/inv_items_" .. iCharId .. ".json"
		file.Write(sFilePath, util.TableToJSON(tItemsToStore))

		_self:AlphaTo(0, 0.15, 0, function(_, self)
			self:Remove()
		end)

	end
	self.vInventory.OnKeyCodePressed = function(self, iCode)
		if iCode == Solve:GetSetting("inv_key") or iCode == KEY_ESCAPE then

			self:Close()

		end

	end
	self.vInventory.Paint = function(_self, w, h)

		local iInvWeight = 0

		tItems["objects"] = tItems["objects"] or {}

		for sItemId, tItem in pairs(tItems["objects"]) do

			tItem = tItem or {}

			local tItemData = self:GetItemData(sItemId)
			if not tItemData then continue end

			iInvWeight = iInvWeight + (tItemData.iWeight or 0)*(tItem.iCount or 1)

		end

		iWeightLerp = iWeightLerp or 0
		iWeightLerp = Lerp(FrameTime()*5, iWeightLerp, iInvWeight/iInvMaxWeight)

		-- TFJ v2 : tout est dessine (plus de PNG de fond Solve / TFJ)
		TFJInv.Polices()
		local VH = h / 100
		TFJInv.Fond(w, h)
		local mLogo = TFJInv.Mat("tfj_skilltree/f4_logo.png")
		if mLogo then
			local lh = VH * 12.5
			local lw = lh * mLogo:Width() / math.max(1, mLogo:Height())
			surface.SetDrawColor(255, 255, 255, 255)
			surface.SetMaterial(mLogo)
			surface.DrawTexturedRect(w / 2 - lw / 2, VH * 3.7, lw, lh)
		end
		local x0, bw = w * 0.116, w * 0.335
		draw.SimpleText("MENU", "TFJInv.Menu", x0, VH * 11.8, TFJInv_GRIS, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText("INVENTAIRE", "TFJInv.Titre", x0 - 2, VH * 14.4, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

		-- poids : barre rouge proportionnelle, texte par-dessus
		local by, bh = VH * 21.8, VH * 4.2
		surface.SetDrawColor(21, 21, 23, 255)
		surface.DrawRect(x0, by, bw, bh)
		surface.SetDrawColor(TFJInv_ROUGE_VIF)
		surface.DrawRect(x0, by, bw * math.Clamp(iWeightLerp, 0, 1), bh)
		draw.SimpleText("LIMITE DE POIDS", "TFJInv.Barre", x0 + VH * 1.6, by + bh / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText(("%s / %s"):format(math.Round(iWeightLerp * iInvMaxWeight, 2), iInvMaxWeight), "TFJInv.Barre", x0 + bw - VH * 1.6, by + bh / 2, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

		-- niveau, XP et argent sous la grille
		local iLevel, iXp, iMaxXp = pLocal:GetLevel(), pLocal:GetXP(), pLocal:GetMaxXP()
		local ny = VH * 83.5
		draw.SimpleText("NIVEAU " .. iLevel, "TFJInv.Barre", x0, ny, TFJInv_ROUGE_TEXTE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText(("%s / %s XP"):format(math.floor(iXp), math.floor(iMaxXp)), "TFJInv.Petit", x0, ny + VH * 3.2, TFJInv_GRIS, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText(Solve:FormatMoney(pLocal:GetMoney()), "TFJInv.Barre", x0 + bw, ny, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
		surface.SetDrawColor(42, 42, 46, 255)
		surface.DrawRect(x0, ny + VH * 5.4, bw, 4)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawRect(x0, ny + VH * 5.4, bw * math.Clamp(iXp / math.max(1, iMaxXp), 0, 1), 4)

	end

	Solve.Naruto.FocusedFrame = self.vInventory

	if not bReload then

		self.vInventory:AlphaTo(255, 0.1, 0)

	end

	local vecCharacterPos, angCharacterAng = Vector(0, 0, -2), Angle(0, 45, 0)

	local matCheck, iCheckW, iCheckH = Solve:GetMaterial("check")
	local bgColor = Color(8, 8, 10, 220)

	// Trier par rareté
	local vRarityPanel = vgui.Create("DPanel", self.vInventory)
	vRarityPanel:SetSize(Solve.ScrW*0.1, Solve.ScrH*0.027)
	vRarityPanel:SetPos(Solve.ScrW*(0.116 + 0.335 - 0.1), Solve.ScrH*0.281)
	vRarityPanel.Paint = function(self, w, h)

		draw.SimpleText("Trier par rareté", Solve:Font(0.013, 2), h*1.4, h/2, Color(196, 196, 202), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

	end

	local vCheckBox = vgui.Create("DCheckBox", vRarityPanel)
	vCheckBox:Dock(LEFT)
	vCheckBox:SetWide(vRarityPanel:GetTall())
	if CACHE_LIST_BY_RARETY then
		vCheckBox:SetChecked(true)
	end
	vCheckBox.Paint = function(self, w, h)

		surface.SetDrawColor(18, 18, 20, 255)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(85, 85, 92, 255)
		surface.DrawOutlinedRect(0, 0, w, h, 1)

		if self:GetChecked() then

			surface.SetDrawColor(Solve.Naruto.Constants["colors"]["FFFFFF"])
			surface.SetMaterial(matCheck)
			surface.DrawTexturedRectRotated(w/2, h/2, w*0.7, h*0.7, 0)

		end

	end
	vCheckBox.DoClick = function(self)

		local bNewChecked = not self:GetChecked()
		self:SetChecked(bNewChecked)
		CACHE_LIST_BY_RARETY = bNewChecked
		Solve.Naruto.Inventory:DrawInventory(nil, true, true, nil, nil, bNewChecked)

	end

	local vFilterPanel = vgui.Create("DPanel", self.vInventory)
	vFilterPanel:SetSize(Solve.ScrW*0.22, Solve.ScrH*0.04)
	vFilterPanel:SetPos(Solve.ScrW*0.116, Solve.ScrH*0.274)
	vFilterPanel:SetPaintBackground(false)
	vFilterPanel:DockPadding(0, 0, 0, 0)

	if self.sInventoryType == "objects" then
		local vMaterialsButton = vgui.Create("DButton", vFilterPanel)
		vMaterialsButton:Dock(LEFT)
		vMaterialsButton:SetWide(vFilterPanel:GetWide()*0.5)
		vMaterialsButton:SetText("")
		vMaterialsButton.Paint = function(_self, w, h)
			_self.iHoverLerp = Lerp(FrameTime()*10, _self.iHoverLerp or 0, (_self:IsHovered() or SHOW_MATERIALS_ONLY) and 1 or 0)

			draw.SimpleText("MATÉRIAUX", "TFJInv.Filtre", w/2, h*0.52, ColorAlpha(Solve.Naruto.Constants["colors"]["FFFFFF"], 255*0.1 + (255*0.9)*_self.iHoverLerp), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			Souligne("MATÉRIAUX", "TFJInv.Filtre", w/2, h*0.52, TEXT_ALIGN_CENTER, _self.iHoverLerp)
		end
		vMaterialsButton.DoClick = function()
			SHOW_MATERIALS_ONLY = not SHOW_MATERIALS_ONLY
			if SHOW_MATERIALS_ONLY then SHOW_EQUIPMENT_ONLY = false end
			self:DrawInventory(self.sInventoryType, nil, true, tOverInv, pOverPlayer)
			surface.PlaySound("solve_naruto_base/ui/bruitage_switch_jutsu.wav")
		end

		local vEquipmentButton = vgui.Create("DButton", vFilterPanel)
		vEquipmentButton:Dock(RIGHT)
		vEquipmentButton:SetWide(vFilterPanel:GetWide()*0.5)
		vEquipmentButton:SetText("")
		vEquipmentButton.Paint = function(_self, w, h)
			_self.iHoverLerp = Lerp(FrameTime()*10, _self.iHoverLerp or 0, (_self:IsHovered() or SHOW_EQUIPMENT_ONLY) and 1 or 0)

			draw.SimpleText("EQUIPEMENT", "TFJInv.Filtre", w/2, h*0.52, ColorAlpha(Solve.Naruto.Constants["colors"]["FFFFFF"], 255*0.1 + (255*0.9)*_self.iHoverLerp), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			Souligne("EQUIPEMENT", "TFJInv.Filtre", w/2, h*0.52, TEXT_ALIGN_CENTER, _self.iHoverLerp)
		end
		vEquipmentButton.DoClick = function()
			SHOW_EQUIPMENT_ONLY = not SHOW_EQUIPMENT_ONLY
			if SHOW_EQUIPMENT_ONLY then SHOW_MATERIALS_ONLY = false end
			self:DrawInventory(self.sInventoryType, nil, true, tOverInv, pOverPlayer)
			surface.PlaySound("solve_naruto_base/ui/bruitage_switch_jutsu.wav")
		end
	elseif self.sInventoryType == "cosmetics" then
		local vTeamsButton = vgui.Create("DButton", vFilterPanel)
		vTeamsButton:Dock(LEFT)
		vTeamsButton:SetWide(vFilterPanel:GetWide()/3)
		vTeamsButton:SetText("")
		vTeamsButton.Paint = function(_self, w, h)
			_self.iHoverLerp = Lerp(FrameTime()*10, _self.iHoverLerp or 0, (_self:IsHovered() or SHOW_TENUES_ONLY) and 1 or 0)

			draw.SimpleText("COSTUMES", "TFJInv.Filtre", w/2, h*0.52, ColorAlpha(Solve.Naruto.Constants["colors"]["FFFFFF"], 255*0.1 + (255*0.9)*_self.iHoverLerp), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			Souligne("COSTUMES", "TFJInv.Filtre", w/2, h*0.52, TEXT_ALIGN_CENTER, _self.iHoverLerp)
		end
		vTeamsButton.DoClick = function()
			SHOW_TENUES_ONLY = not SHOW_TENUES_ONLY
			if SHOW_TENUES_ONLY then
				SHOW_KATANA_ONLY = false
				SHOW_ACCESSORIES_ONLY = false
			end
			self:DrawInventory(self.sInventoryType, nil, true, tOverInv, pOverPlayer)
			surface.PlaySound("solve_naruto_base/ui/bruitage_switch_jutsu.wav")
		end

		local vKatanaButton = vgui.Create("DButton", vFilterPanel)
		vKatanaButton:Dock(FILL)
		vKatanaButton:SetWide(vFilterPanel:GetWide()/3)
		vKatanaButton:SetText("")
		vKatanaButton.Paint = function(_self, w, h)
			_self.iHoverLerp = Lerp(FrameTime()*10, _self.iHoverLerp or 0, (_self:IsHovered() or SHOW_KATANA_ONLY) and 1 or 0)

			draw.SimpleText("KATANA", "TFJInv.Filtre", w/2, h*0.52, ColorAlpha(Solve.Naruto.Constants["colors"]["FFFFFF"], 255*0.1 + (255*0.9)*_self.iHoverLerp), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			Souligne("KATANA", "TFJInv.Filtre", w/2, h*0.52, TEXT_ALIGN_CENTER, _self.iHoverLerp)
		end
		vKatanaButton.DoClick = function()
			SHOW_KATANA_ONLY = not SHOW_KATANA_ONLY
			if SHOW_KATANA_ONLY then
				SHOW_TENUES_ONLY = false
				SHOW_ACCESSORIES_ONLY = false
			end
			self:DrawInventory(self.sInventoryType, nil, true, tOverInv, pOverPlayer)
			surface.PlaySound("solve_naruto_base/ui/bruitage_switch_jutsu.wav")
		end

		local vAccessoriesButton = vgui.Create("DButton", vFilterPanel)
		vAccessoriesButton:Dock(RIGHT)
		vAccessoriesButton:SetWide(vFilterPanel:GetWide()/2.5)
		vAccessoriesButton:SetText("")
		vAccessoriesButton.Paint = function(_self, w, h)
			_self.iHoverLerp = Lerp(FrameTime()*10, _self.iHoverLerp or 0, (_self:IsHovered() or SHOW_ACCESSORIES_ONLY) and 1 or 0)

			draw.SimpleText("ACCESSOIRES", "TFJInv.Filtre", w/1.8, h*0.52, ColorAlpha(Solve.Naruto.Constants["colors"]["FFFFFF"], 255*0.1 + (255*0.9)*_self.iHoverLerp), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			Souligne("ACCESSOIRES", "TFJInv.Filtre", w/1.8, h*0.52, TEXT_ALIGN_CENTER, _self.iHoverLerp)
		end
		vAccessoriesButton.DoClick = function()
			SHOW_ACCESSORIES_ONLY = not SHOW_ACCESSORIES_ONLY
			if SHOW_ACCESSORIES_ONLY then
				SHOW_TENUES_ONLY = false
				SHOW_KATANA_ONLY = false
			end
			self:DrawInventory(self.sInventoryType, nil, true, tOverInv, pOverPlayer)
			surface.PlaySound("solve_naruto_base/ui/bruitage_switch_jutsu.wav")
		end
	end


	// Model Panel
	local vModelPanelBg = vgui.Create("DPanel", self.vInventory)
	vModelPanelBg:SetSize(Solve.ScrW*0.32, Solve.ScrH*0.88)
	vModelPanelBg:SetPos(Solve.ScrW*0.6, Solve.ScrH*0.11)
	vModelPanelBg:SetPaintBackground(false)

	local vModelPanel = vgui.Create("DModelPanel", vModelPanelBg)
	vModelPanel:Dock(FILL)
	vModelPanel:SetFOV(43)

	-- Utilise en priorité le PM modifié du personnage (tenue équipée),
	-- puis retombe sur le modèle réellement porté par le joueur.
	local function GetInventoryPlayerModel()
		local sModel = pLocal:GetModel()
		local iSkin = pLocal:GetSkin()

		if Solve and Solve.Naruto and istable(Solve.Naruto.tCharacters) and pLocal.GetCharacterId then
			local iCharacterId = pLocal:GetCharacterId()
			local tChar = Solve.Naruto.tCharacters[iCharacterId]

			if istable(tChar) then
				if isstring(tChar.sModifiedModel) and tChar.sModifiedModel ~= "" and tChar.sModifiedModel ~= "NULL" then
					sModel = tChar.sModifiedModel
					iSkin = tonumber(tChar.iModifiedSkin) or 0
				elseif isstring(tChar.sModel) and tChar.sModel ~= "" then
					sModel = tChar.sModel
					iSkin = tonumber(tChar.iSkin) or iSkin
				end
			end
		end

		return sModel, iSkin
	end

	local function ApplyInventoryPlayerBodygroups(eEntity)
		if not IsValid(eEntity) or not IsValid(pLocal) then return end

		for _, tBodygroup in ipairs(pLocal:GetBodyGroups() or {}) do
			local iID = tBodygroup.id
			if isnumber(iID) then
				eEntity:SetBodygroup(iID, pLocal:GetBodygroup(iID))
			end
		end
	end

	local sInventoryModel, iInventorySkin = GetInventoryPlayerModel()
	vModelPanel:SetModel(sInventoryModel)
	if IsValid(vModelPanel.Entity) then
		vModelPanel.Entity:SetSkin(iInventorySkin)
		ApplyInventoryPlayerBodygroups(vModelPanel.Entity)
	end

	local eHead, fnThink, eMask, fnOnRemove = Solve:BuildPlayerModel(pLocal, vModelPanel.Entity, nil, nil, true)

	vModelPanel.Entity:SetAngles(Angle(0, 45, 0))
	vModelPanel.OnRemove = function(self)
		if fnOnRemove then
			fnOnRemove()
		end
		SafeRemoveEntity(self.Entity)
	end
	vModelPanel.Think = function(self)
		if not IsValid(self.Entity) then return end

		local sWantedModel, iWantedSkin = GetInventoryPlayerModel()

		if sWantedModel ~= self.Entity:GetModel() then
			self:SetModel(sWantedModel)

			if not IsValid(self.Entity) then return end

			self.Entity:SetSkin(iWantedSkin)
			ApplyInventoryPlayerBodygroups(self.Entity)
			self.Entity:SetAngles(Angle(0, 45, 0))

			if fnOnRemove then
				fnOnRemove()
			end

			eHead, fnThink, eMask, fnOnRemove = Solve:BuildPlayerModel(pLocal, self.Entity, nil, nil, true)
			self.bAnimSet = false
		else
			-- Garde aussi le skin/bodygroups synchronisés avec le joueur.
			if self.Entity:GetSkin() ~= iWantedSkin then
				self.Entity:SetSkin(iWantedSkin)
			end
			ApplyInventoryPlayerBodygroups(self.Entity)
		end

		if input.IsMouseDown(MOUSE_FIRST) and self:IsHovered() then

			local iMouseX = gui.MouseX()

			self.iBaseMouseX = self.iBaseMouseX or iMouseX
			self.iBaseMouseY = self.iBaseMouseY or gui.MouseY()

			local iAngleToAdd = (iMouseX - self.iBaseMouseX)*0.4

			if IsValid(self.Entity) then

				self.Entity:SetAngles(self.Entity:GetAngles() + Angle(0, iAngleToAdd, 0))
				self.iBaseMouseX = iMouseX

				self:SetCursor("blank")

			end

		else

			self:SetCursor("hand")

			self.iBaseMouseX = nil
			self.iBaseMouseY = nil

		end

	end

	vModelPanel.PostDrawModel = function(self)

		if isfunction(fnThink) then

			fnThink()

		end

	end

	vModelPanel.LayoutEntity = function(self, eEntity)

		eEntity:SetPos(vecCharacterPos)

		if not self.bAnimSet then
			local iSeq = eEntity:LookupSequence("nrp_lobby_lobby_shootman_win_loop")
			if iSeq and iSeq > 0 then
				eEntity:ResetSequence(iSeq)
				eEntity:SetCycle(0)
				eEntity:SetPlaybackRate(1)
				self.bAnimSet = true
			end
		end

		self:RunAnimation()

	end

	// HDV Button (removed)

	// Cases
	local vItemsPanel = vgui.Create("DPanel", self.vInventory)
	vItemsPanel:SetSize(Solve.ScrW*0.335, Solve.ScrH*0.475)
	vItemsPanel:SetPos(Solve.ScrW*0.116, Solve.ScrH*0.328)
	vItemsPanel:SetPaintBackground(false)

	local vItemsScroll = vgui.Create("DScrollPanel", vItemsPanel)
	vItemsScroll:Dock(FILL)

	local vSBar = vItemsScroll:GetVBar()
	vSBar:SetWide(0)
	vSBar:SetHideButtons(true)

	local iSpaceX = Solve.ScrW*0.005
	local iSpaceY = Solve.ScrH*0.01

	local iCaseSizeW = (vItemsPanel:GetWide() - iSpaceX*4)/5
	local iCaseSizeH = (vItemsPanel:GetTall() - iSpaceY*3)/4

	local vIconLayoutInv = vgui.Create("DIconLayout", vItemsScroll)
	vIconLayoutInv:Dock(FILL)
	vIconLayoutInv:SetSpaceX(iSpaceX)
	vIconLayoutInv:SetSpaceY(iSpaceY)
	vIconLayoutInv.PaintOver = function(self)

		-- self:SetCursor("blank")

	end

	local tItemsBySlots = {}
	local iFakeSlot = 1

	for sItemId, tItem in pairs(tItems[self.sInventoryType] or {}) do

		local tItemData = self:GetItemData(sItemId)
		if not tItemData then continue end

		if (CACHE_LIST_BY_RARETY or SHOW_MATERIALS_ONLY or SHOW_EQUIPMENT_ONLY or SHOW_TENUES_ONLY or SHOW_KATANA_ONLY or SHOW_ACCESSORIES_ONLY) then
			if tItem.sAccessoryId and (tItem.iCount or 1) <= 1 then continue end
		end

		if self.sInventoryType == "objects" then
			local sCategory = self.Config["tItemCategoriesNoneBoutique"][tItemData.sCategory] or ""
			if SHOW_MATERIALS_ONLY and sCategory ~= "materials" then continue end
			if SHOW_EQUIPMENT_ONLY and sCategory ~= "equipements" then continue end
		elseif self.sInventoryType == "cosmetics" then
			local sCategory = self.Config["tItemCategoriesBoutique"][tItemData.sCategory] or ""
			if SHOW_TENUES_ONLY and sCategory ~= "tenues" then continue end
			if SHOW_KATANA_ONLY and sCategory ~= "katana" then continue end
			if SHOW_ACCESSORIES_ONLY and sCategory ~= "accessories" then continue end
		end

		local tRarityData = self.Config["rarities"][tItemData.sRarity] or {}

		local iSlot = tItem.iSlot or iFakeSlot
		if CACHE_LIST_BY_RARETY or SHOW_MATERIALS_ONLY or SHOW_EQUIPMENT_ONLY or SHOW_TENUES_ONLY or SHOW_KATANA_ONLY or SHOW_ACCESSORIES_ONLY then
			iSlot = iFakeSlot
		end

		tItemsBySlots[iSlot] = {
			["sItemId"] = sItemId,
			["iCount"] = tItem.iCount or 1,
			["iRarityPower"] = tRarityData.iSort or 0,
		}

		iFakeSlot = iFakeSlot + 1

	end

	if CACHE_LIST_BY_RARETY or SHOW_MATERIALS_ONLY or SHOW_EQUIPMENT_ONLY or SHOW_TENUES_ONLY or SHOW_KATANA_ONLY or SHOW_ACCESSORIES_ONLY then
		table.sort(tItemsBySlots, function(a, b)
			return a.iRarityPower > b.iRarityPower
		end)
	end

	local tSlotsPanel = {}
	local iMaxSlot = 0
	for iSlot, _ in pairs(tItemsBySlots) do
		iMaxSlot = math.max(iMaxSlot, iSlot)
	end
	local iSlotsCount = math.max(20, iMaxSlot + 10)

	for i = 1, iSlotsCount do

		local i = iSlotsCount - i + 1

		local iLine = math.floor((i-1)/5)

		local vSlot = vgui.Create("DPanel", vIconLayoutInv)
		vSlot:SetSize(iCaseSizeW, iCaseSizeH)
		vSlot:SetZPos(45)
		vSlot:Receiver("slot", function(_self, tDropped, bIsDropped, iSlotX, iSlotY)

			if not bIsDropped then return end
			if IsValid(_self.vItem) then return end

			local vItem = tDropped[1]
			if not IsValid(vItem) then return end

			if vItem._sModel then
				vItem = vItem:GetParent()
			end

			local sItemId = vItem.sItemId

			local tItem = (tItems[self.sInventoryType] or {})[sItemId]
			if not tItem then return end

			if LocalPlayer():GetNetworkVar("bPVPMode", false) and vItem.sAccessoryId then
				Solve:Notify("error", "Inventory", L("inventory.cannot_remove_accessory_pvp"))
				return
			end

			// If the item's from a equipement
			if vItem.sAccessoryId then

				vItem:Remove()

				if not IsValid(tItem.vItem) then

					local vNewItem = Solve.Naruto.Inventory:DrawItem(_self, sItemId, nil, tOverInv)

					tItem.iSlot = i
					tItem.vItem = vNewItem
					_self.vItem = vNewItem

				end

				net.Start("Solve.Naruto.Inventory:ServerSide")
					net.WriteUInt(2, 3)
					net.WriteString(sItemId)
					net.WriteBool(true)
				net.SendToServer()

				tItem.sAccessoryId= nil

			else

				if IsValid(_self.vItem) then return end

				local vOldParent = vItem:GetParent()

				if IsValid(vOldParent) then

					vOldParent.vItem = nil

				end

				vItem:SetParent(vSlot)
				vItem:Dock(FILL)

				tItem.iSlot = i
				vSlot.vItem = vItem

			end

		end)
		vSlot.Paint = function(_self, w, h)

			local vItem = _self.vItem
			local cRarete
			if IsValid(vItem) then

				if vItem._sModel then

					vItem = vItem:GetParent()

				end

				local sItem = vItem.sItemId
				// remove all after @
				sItem = string.Split(sItem, "@")[1]

				cRarete = TFJInv.CouleurRarete(self.Config["items"][sItem])

			end
			TFJInv.Case(w, h, cRarete)

			-- _self:SetCursor("blank")
		end

		local tItem = tItemsBySlots[i]

		if tItem then
			local tRealItem = (tItems[self.sInventoryType] or {})[tItem.sItemId]
			if tRealItem and ((not tRealItem.sAccessoryId) or ((tRealItem.iCount or 1) > 1)) then

				local vItem = Solve.Naruto.Inventory:DrawItem(vSlot, tItem.sItemId, nil, tOverInv)
				if IsValid(vItem) then
					vSlot.vItem = vItem
					tRealItem.vItem = vItem
				end

			end

		end

		tSlotsPanel[i] = vSlot

	end

	self.tSlotsPanel = tSlotsPanel

	local vNavInvMode = vgui.Create("DPanel", self.vInventory)
	vNavInvMode:SetSize(Solve.ScrW*0.2, Solve.ScrH*0.06)
	vNavInvMode:SetPos(Solve.ScrW*0.27, Solve.ScrH*0.145)
	vNavInvMode:SetPaintBackground(false)

	local vObjectsButton = vgui.Create("DButton", vNavInvMode)
	vObjectsButton:Dock(LEFT)
	vObjectsButton:SetWide(vNavInvMode:GetWide()*0.45)
	vObjectsButton:SetText("")
	vObjectsButton.Paint = function(_self, w, h)

		_self.iHoverLerp = Lerp(FrameTime()*10, _self.iHoverLerp or 0, (_self:IsHovered() or self.sInventoryType == "objects") and 1 or 0)

		surface.SetDrawColor(Solve.Naruto.Constants["colors"]["FFFFFF10"])
		surface.DrawRect(w - 1, h/2 - h*0.38/2, 1, h*0.38)

		draw.SimpleText("OBJETS", "TFJInv.Mode", w - w*0.07, h*0.52, ColorAlpha(Solve.Naruto.Constants["colors"]["FFFFFF"], 255*0.1 + (255*0.9)*_self.iHoverLerp), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		Souligne("OBJETS", "TFJInv.Mode", w - w*0.07, h*0.52, TEXT_ALIGN_RIGHT, _self.iHoverLerp)

	end
	vObjectsButton.DoClick = function()

		self:DrawInventory("objects", nil, true, tOverInv, pOverPlayer)
		surface.PlaySound("solve_naruto_base/ui/bruitage_switch_jutsu.wav")

	end

	local vComosButton = vgui.Create("DButton", vNavInvMode)
	vComosButton:Dock(FILL)
	vComosButton:SetText("")
	vComosButton.Paint = function(_self, w, h)

		_self.iHoverLerp = Lerp(FrameTime()*10, _self.iHoverLerp or 0, (_self:IsHovered() or self.sInventoryType == "cosmetics") and 1 or 0)

		surface.SetDrawColor(Solve.Naruto.Constants["colors"]["FFFFFF10"])
		surface.DrawRect(0, h/2 - h*0.38/2, 2, h*0.38)

		draw.SimpleText("COSMÉTIQUES", "TFJInv.Mode", w*0.07, h*0.52, ColorAlpha(Solve.Naruto.Constants["colors"]["FFFFFF"], 255*0.1 + (255*0.9)*_self.iHoverLerp), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		Souligne("COSMÉTIQUES", "TFJInv.Mode", w*0.07, h*0.52, TEXT_ALIGN_LEFT, _self.iHoverLerp)

	end
	vComosButton.DoClick = function()

		self:DrawInventory("cosmetics", nil, true, tOverInv, pOverPlayer)
		surface.PlaySound("solve_naruto_base/ui/bruitage_switch_jutsu.wav")

	end


	// Player equipement

	for sEquipement, tAccesory in pairs(Solve.Naruto.Inventory.Config["accessories"][self.sInventoryType or ""] or {}) do
		local tData = tAccesory.tClientOffsets or {}

		local vEquipement = vgui.Create("DPanel", self.vInventory)
		vEquipement:SetSize(Solve.ScrH*tData.sizeW, Solve.ScrH*tData.sizeH)
		vEquipement:SetPos(Solve.ScrW*tData.posX, Solve.ScrH*tData.posY)

		vEquipement.sEquipement = sEquipement
		vEquipement.fnDrop = function(_self, tDropped, bIsDropped)

			if not bIsDropped then return end

            -- Block any equip/swap/unequip during PvP, even if fnDrop is called directly
            if LocalPlayer():GetNetworkVar("bPVPMode", false) then
                Solve:Notify("error", "Inventory", L("inventory.cannot_equip_pvp"))
                return
            end

			local vItem = tDropped[1]
			if not IsValid(vItem) then return end

			if vItem._sModel then
				vItem = vItem:GetParent()
			end

			local vEquippedItem = _self.vItem
			local bHasEquippedItem = IsValid(vEquippedItem)
			local sEquippedItemId = nil
			local tEquippedItem = nil

			if bHasEquippedItem then
				if vEquippedItem._sModel then
					vEquippedItem = vEquippedItem:GetParent()
				end
				sEquippedItemId = vEquippedItem.sItemId
				tEquippedItem = (tItems[self.sInventoryType] or {})[sEquippedItemId]
			end

			local tItem = (tItems[self.sInventoryType] or {})[vItem.sItemId]
			if not tItem then return end

			local tItemData = self:GetItemData(vItem.sItemId)
			if not tItemData then return end

			local tCat = self.Config["itemsCategories"][tItemData.sCategory]
			if tCat and tCat.fnCanUse then
				local bCanUse, sReason = tCat.fnCanUse(pLocal, tItemData, vItem.sItemId)
				if bCanUse == false then
					Solve:Notify("error", "Inventaire", sReason)
					return
				end
			end
			if tItemData.sPlayerAccessory != sEquipement then return end

			if (tItem.iCount or 1) > 1 then
				local vNewItem = Solve.Naruto.Inventory:DrawItem(_self, vItem.sItemId, nil, tOverInv)

				if IsValid(vNewItem) then
					if vNewItem._sModel then
						vNewItem = vNewItem:GetParent()
					end

					if bHasEquippedItem then
						local vOriginalSlot = vItem:GetParent()

						if IsValid(vOriginalSlot) then
							vEquippedItem:SetParent(vOriginalSlot)
							vEquippedItem:Dock(FILL)
							vOriginalSlot.vItem = vEquippedItem
							vEquippedItem.sAccessoryId = nil
							if tEquippedItem then
								tEquippedItem.sAccessoryId = nil

								local iSlotIndex = 0
								for i, vSlot in ipairs(Solve.Naruto.Inventory.tSlotsPanel or {}) do
									if vSlot == vOriginalSlot then
										iSlotIndex = i
										break
									end
								end

								if iSlotIndex > 0 then
									tEquippedItem.iSlot = iSlotIndex
								else
									local tUsedSlots = {}
									for _, tOtherItem in pairs(tItems[self.sInventoryType] or {}) do
										if tOtherItem.iSlot then
											tUsedSlots[tOtherItem.iSlot] = true
										end
									end
									for i = 1, 1000 do
										if not tUsedSlots[i] then
											tEquippedItem.iSlot = i
											break
										end
									end
								end
							end
						end
					end

					_self.vItem = vNewItem
					vNewItem.sAccessoryId = sEquipement
					tItem.sAccessoryId = sEquipement

					tItem.iSlot = nil
				end

				net.Start("Solve.Naruto.Inventory:ServerSide")
					net.WriteUInt(2, 3)
					net.WriteString(vItem.sItemId)
					net.WriteBool(false)
					net.WriteBool(bHasEquippedItem)
					if bHasEquippedItem then
						net.WriteString(sEquippedItemId)
					end
				net.SendToServer()

				return
			end

			local vOriginalSlot = vItem:GetParent()
			vOriginalSlot.vItem = nil

			vItem:SetParent(_self)
			vItem:Dock(FILL)
			vItem.sAccessoryId = sEquipement
			tItem.sAccessoryId = sEquipement
			tItem.vItem = nil
			_self.vItem = vItem

			tItem.iSlot = nil

			if bHasEquippedItem then
				vEquippedItem:SetParent(vOriginalSlot)
				vEquippedItem:Dock(FILL)
				vOriginalSlot.vItem = vEquippedItem
				vEquippedItem.sAccessoryId = nil
				if tEquippedItem then
					tEquippedItem.sAccessoryId = nil

					local iSlotIndex = 0
					for i, vSlot in ipairs(Solve.Naruto.Inventory.tSlotsPanel or {}) do
						if vSlot == vOriginalSlot then
							iSlotIndex = i
							break
						end
					end

					if iSlotIndex > 0 then
						tEquippedItem.iSlot = iSlotIndex
					else
						local tUsedSlots = {}
						for _, tOtherItem in pairs(tItems[self.sInventoryType] or {}) do
							if tOtherItem.iSlot then
								tUsedSlots[tOtherItem.iSlot] = true
							end
						end
						for i = 1, 1000 do
							if not tUsedSlots[i] then
								tEquippedItem.iSlot = i
								break
							end
						end
					end
				end
			end

			net.Start("Solve.Naruto.Inventory:ServerSide")
				net.WriteUInt(2, 3)
				net.WriteString(vItem.sItemId)
				net.WriteBool(false)
			net.SendToServer()

		end

		vEquipement.Paint = function(_self, w, h)

			-- TFJ v2 : cadre de l'emplacement (avant : dessine dans le PNG de fond)
			local vEquipe = _self.vItem
			if IsValid(vEquipe) and vEquipe._sModel then vEquipe = vEquipe:GetParent() end
			TFJInv.Case(w, h, IsValid(vEquipe) and TFJInv.CouleurRarete(self:GetItemData(vEquipe.sItemId)) or nil)
			if not IsValid(vEquipe) then
				local mIcone = TFJInv.IconeEmplacement(sEquipement)
				if mIcone then
					surface.SetDrawColor(255, 255, 255, 140)
					surface.SetMaterial(mIcone)
					surface.DrawTexturedRect(w * 0.25, h * 0.25, w * 0.5, h * 0.5)
				end
			end

			// Dragging emplacement image

			local tDraggedItems = dragndrop.GetDroppable("slot") or {}
			local bDraw = false

			for _, vDraggedItem in pairs(tDraggedItems) do

				if IsValid(vDraggedItem) then

					if vDraggedItem._sModel then
						vDraggedItem = vDraggedItem:GetParent()
					end

					local tItemConfig = self:GetItemData(vDraggedItem.sItemId)
					if not tItemConfig then continue end

					if tItemConfig.sPlayerAccessory == sEquipement then

						bDraw = true
						break

					end

				end

			end

			if bDraw then

				surface.SetDrawColor(Solve.Naruto.Constants["colors"]["FFFFFF"])
				surface.SetMaterial(matRefreshIcon)
				surface.DrawTexturedRectRotated(w/2, h/2, iRefreshIconW, iRefreshIconH, 0)

			end

			// Other stuff
			local vItem = _self.vItem

			if IsValid(vItem) then

				if vItem._sModel then

					vItem = vItem:GetParent()

				end

				-- TFJ v2 : la lueur de rarete est dessinee par TFJInv.Case plus haut

			end

		end

		vEquipement:Receiver("slot", function(self, tDropped, bIsDropped)
			if LocalPlayer():GetNetworkVar("bPVPMode", false) then
				Solve:Notify("error", "Inventory", L("inventory.cannot_equip_swap_pvp"))
				return
			end
			self:fnDrop(tDropped, bIsDropped)
		end)

		local sItemId, tAccesoryItem

		for _sItemId, tItem in pairs(tItems[self.sInventoryType] or {}) do

			if tItem.sAccessoryId == sEquipement then

				sItemId = _sItemId
				tAccesoryItem = tItem
				break

			end

		end

		if tAccesoryItem then

			tAccesoryItem.sItemId = sItemId

			local vItem = Solve.Naruto.Inventory:DrawItem(vEquipement, sItemId, nil, tOverInv)
			if IsValid(vItem) then

				if vItem._sModel then
					vItem = vItem:GetParent()
				end

				vItem.sAccessoryId = sEquipement

			end

		end

		self.tEquimentsVGUIS[self.sInventoryType] = self.tEquimentsVGUIS[self.sInventoryType] or {}
		self.tEquimentsVGUIS[self.sInventoryType][sEquipement] = vEquipement
	end

	local vQuit = vgui.Create("DButton", self.vInventory)
	vQuit:SetSize(Solve:SpaceX(130), Solve:SpaceY(35))
	vQuit:SetPos(Solve.ScrW - vQuit:GetWide() - Solve:SpaceX(70), Solve:SpaceY(50))
	vQuit:SetText("")
	vQuit.Paint = nil
	vQuit.DoClick = function()
		self.vInventory:Close()

	end

	if LocalPlayer():IsSuperAdmin() then
		local vAdminButton = vgui.Create("DButton", self.vInventory)
		vAdminButton:SetSize(Solve:SpaceX(160), Solve:SpaceY(40))
		vAdminButton:SetPos(Solve:SpaceX(40), Solve.ScrH - Solve:SpaceY(90))
		vAdminButton:SetText("")
		vAdminButton.Paint = function(_self, w, h)
			draw.RoundedBox(6, 0, 0, w, h, Color(255, 255, 255, 30))
			draw.RoundedBox(5, 1, 1, w - 2, h - 2, Color(8, 8, 10, 230))
			draw.RoundedBox(2, 1, 1, 4, h - 2, TFJ_ROUGE)
			draw.SimpleText("Ouvrir", Solve:Font(0.02, 4), w / 2, h * 0.32, Solve.Naruto.Constants["colors"]["FFFFFF"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText("Remboursement", Solve:Font(0.01, 4), w / 2, h * 0.72, Solve.Naruto.Constants["colors"]["FFFFFF"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		vAdminButton.DoClick = function()
			Solve.Naruto.Inventory:ShowItemsFinder()
			surface.PlaySound("solve_naruto_base/ui/bruitage_switch_jutsu.wav")
		end
	end

	if self.sInventoryType == "objects" or not self.sInventoryType then
		local vImageOverlay = vgui.Create("DPanel", self.vInventory)
		vImageOverlay:SetSize(Solve.ScrW, Solve.ScrH * 0.25)
		vImageOverlay:SetPos(0, Solve.ScrH * 0.75)
		vImageOverlay:SetZPos(1)
		vImageOverlay:SetMouseInputEnabled(false)
		vImageOverlay.Paint = function(s, w, h)
			local matStats = tBackgrounds["objects_stats"]
			if matStats then
				surface.SetDrawColor(Solve.Naruto.Constants["colors"]["FFFFFF"])
				surface.SetMaterial(matStats)
				surface.DrawTexturedRect(0, 0, w, h)
			end
		end

		local tStatsConfig = {
			fPosX     = 0.67,
			fPosY     = 0.899,
			fWidth    = 0.20,
			fHeight   = 0.02,
			fFontSize = 0.013,
			fPadX     = 0.10,
		}

		local vStatsPanel = vgui.Create("DPanel", self.vInventory)
		vStatsPanel:SetSize(Solve.ScrW * tStatsConfig.fWidth, Solve.ScrH * tStatsConfig.fHeight)
		vStatsPanel:SetPos(Solve.ScrW * tStatsConfig.fPosX, Solve.ScrH * tStatsConfig.fPosY)
		vStatsPanel:SetZPos(2)
		vStatsPanel:SetMouseInputEnabled(false)
		vStatsPanel.Paint = function(s, w, h)
			local iDmgPhysPct   = math.Round((tCachedStats.fDmgPhys   - 1) * 100)
			local iDmgJutsuPct  = math.Round((tCachedStats.fDmgJutsu  - 1) * 100)
			local iResiPhysPct  = math.Round((1 - tCachedStats.fResiPhys)  * 100)
			local iResiJutsuPct = math.Round((1 - tCachedStats.fResiJutsu) * 100)

			local tValues = {
				{string.format("%+d%%", iDmgPhysPct),   colStatDmgPhys},
				{string.format("%+d%%", iDmgJutsuPct),  colStatDmgJutsu},
				{string.format("%+d%%", iResiPhysPct),  colStatResiPhys},
				{string.format("%+d%%", iResiJutsuPct), colStatResiJutsu},
			}

			local sFont = Solve:Font(tStatsConfig.fFontSize, 3)
			local iY = h * 0.5

			for i = 1, 4 do
				local sText, col = tValues[i][1], tValues[i][2]
				local sectionW = w * (1 - 2 * tStatsConfig.fPadX) / 4
				local x = w * tStatsConfig.fPadX + sectionW * (i - 0.5)
				draw.SimpleText(sText, sFont, x, iY, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end
	end

	self:RecursiveChild(self.vInventory)

end

local tItemFinderCart = {}

function Solve.Naruto.Inventory:ShowItemsFinder(tItems)

	if IsValid(self.vItemsFinder) then self.vItemsFinder:Remove() end

	self.vItemsFinder = vgui.Create("DFrame")
	self.vItemsFinder:SetSize(Solve.ScrW*0.7, Solve.ScrH*0.7)
	self.vItemsFinder:Center()
	self.vItemsFinder:MakePopup()
	self.vItemsFinder:SetTitle("Bibliothèque d'articles")
	self.vItemsFinder:ShowCloseButton(true)

	local vCart = vgui.Create("DPanel", self.vItemsFinder)
	vCart:Dock(RIGHT)
	vCart:SetWide(Solve.ScrW*0.15)
	vCart.Paint = function(_self, w, h)

		draw.SimpleText("Panier", Solve:Font(0.02, 4), w/2, h*0.05, Solve.Naruto.Constants["colors"]["FFFFFF"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		local iMouseX, iMouseY = _self:LocalCursorPos()
		local iPosY = h*0.1

		for sItemId, iCount in pairs(tItemFinderCart) do

			local tItemData = self.Config["items"][sItemId]
			if not tItemData then continue end

			surface.SetFont(Solve:Font(0.012, 3))
			local iSizeW, iSizeH = surface.GetTextSize(tItemData.sLittleName.." x"..iCount)

			local bIsHoverText = iMouseX > w*0.05 and iMouseX < (w*0.05 + iSizeW) and iMouseY > iPosY and iMouseY < iPosY + iSizeH
			draw.SimpleText(tItemData.sLittleName.." x"..iCount, Solve:Font(0.012, 3), w*0.05, iPosY, Solve.Naruto.Constants["colors"][bIsHoverText and "FE3636" or "FFFFFF"], TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

			if bIsHoverText and input.IsMouseDown(MOUSE_FIRST) then

				_self.iCooldownInput = _self.iCooldownInput or 0
				if _self.iCooldownInput < CurTime() then

					tItemFinderCart[sItemId] = (tItemFinderCart[sItemId] or 0) - 1
					if tItemFinderCart[sItemId] <= 0 then
						tItemFinderCart[sItemId] = nil
					end

					_self.iCooldownInput = CurTime() + 0.1

				end

			end

			iPosY = iPosY + h*0.03

		end


	end

	local vComboBoxChoosePlayer
	local vReasonEntry

	local vPerformButton = vgui.Create("DButton", vCart)
	vPerformButton:Dock(BOTTOM)
	vPerformButton:SetTall(Solve.ScrH*0.05)
	vPerformButton:SetText("Effectuer")
	vPerformButton.DoClick = function()

		local _, pPlayer = vComboBoxChoosePlayer:GetSelected()
		local sReason = vReasonEntry:GetValue()

		if not sReason or string.Trim(sReason) == "" then
			return
		end

		net.Start("Solve.Naruto.Inventory:ItemBrowser")
			net.WriteUInt(1, 3)
			net.WriteEntity(pPlayer)
			net.WriteString(sReason)
			net.WriteUInt(table.Count(tItemFinderCart), 32)
			for sItemId, iCount in pairs(tItemFinderCart) do
				net.WriteString(sItemId)
				net.WriteUInt(iCount, 32)
			end
		net.SendToServer()

		tItemFinderCart = {}

	end

	vReasonEntry = vgui.Create("DTextEntry", vCart)
	vReasonEntry:Dock(BOTTOM)
	vReasonEntry:SetTall(Solve.ScrH*0.03)
	vReasonEntry:SetPlaceholderText("Raison")
	vReasonEntry:SetValue("")

	vComboBoxChoosePlayer = vgui.Create("DComboBox", vCart)
	vComboBoxChoosePlayer:Dock(BOTTOM)
	vComboBoxChoosePlayer:SetTall(Solve.ScrH*0.03)
	vComboBoxChoosePlayer:SetValue("Choisir le joueur")

	for _, pPlayer in player.Iterator() do

		vComboBoxChoosePlayer:AddChoice(pPlayer:Nick(), pPlayer)

	end

	local vSearchBar = vgui.Create("DTextEntry", self.vItemsFinder)
	vSearchBar:Dock(TOP)
	vSearchBar:SetTall(Solve.ScrH*0.05)
	vSearchBar:SetPlaceholderText("Cherche un item")
	vSearchBar.OnEnter = function(_self)

		local sText = _self:GetText()
		if sText == "" then return end

		local tItems = {}

		for sItemId, tItem in pairs(self.Config["items"]) do

			if
				string.find(sItemId:lower(), sText:lower()) or
				string.find(tItem.sName:lower(), sText:lower())
			then

				tItems[sItemId] = true

			end

		end

		self:ShowItemsFinder(tItems)

	end

	local vItemsList = vgui.Create("DScrollPanel", self.vItemsFinder)
	vItemsList:Dock(FILL)

	local bCanSeeRefundSuits = LocalPlayer():IsSuperAdmin() or self.Config["canRefundBoutiqueSuits"][LocalPlayer():SteamID64()]
	local iMaxResults = 300
	local tQueuedItems = {}

	for sItemId, _ in pairs(tItems or self.Config["items"]) do
		if #tQueuedItems >= iMaxResults then break end

		local tData = self.Config["items"][sItemId]
		if not tData then continue end

		local bBoutiqueSuit = tData.bCantDrop
		if not bCanSeeRefundSuits then
			if bBoutiqueSuit then continue end
		end

		local tCategory = self.Config["itemsCategories"][tData.sCategory]
		if not tCategory then continue end

		tQueuedItems[#tQueuedItems + 1] = sItemId
	end

	local iIndex = 1
	local iPerTick = 20
	local sTimerName = "Solve.Naruto.Inventory:ShowItemsFinder:" .. tostring(vItemsList)

	timer.Create(sTimerName, 0.02, 0, function()
		if (not IsValid(self.vItemsFinder)) or (not IsValid(vItemsList)) then
			timer.Remove(sTimerName)
			return
		end

		local iEnd = math.min(iIndex + iPerTick - 1, #tQueuedItems)
		for i = iIndex, iEnd do
			local sItemId = tQueuedItems[i]
			local tData = self.Config["items"][sItemId]
			if not tData then continue end

			local bBoutiqueSuit = tData.bCantDrop
			if not bCanSeeRefundSuits then
				if bBoutiqueSuit then continue end
			end

			local tCategory = self.Config["itemsCategories"][tData.sCategory]
			if not tCategory then continue end

			local vItem = vgui.Create("DPanel", vItemsList)
			vItem:Dock(TOP)
			vItem:SetTall(Solve.ScrH*0.1)
			vItem:DockMargin(0, 0, 0, Solve.ScrH*0.01)
			vItem.Paint = function(_self, w, h)
				local iSizeW = draw.SimpleText(tData.sLittleName.." - ("..sItemId..")", Solve:Font(0.02, 4), h*1.1, h/2, Solve.Naruto.Constants["colors"]["FFFFFF"], TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				if bBoutiqueSuit then
				end
				if tData.sImgurId and not tData.sModel then
					local matImgur = Solve:GetMaterial(tData.sImgurId, nil, true)
					if matImgur then
						local fScale = tonumber(tData.fImgurScale) or 1
						local iSize = h * fScale
						surface.SetDrawColor(Solve.Naruto.Constants["colors"]["FFFFFF"])
						surface.SetMaterial(matImgur)
						surface.DrawTexturedRect(0, 0, iSize, iSize)
					end
				end
			end

			local tModelPanelOffset = tCategory.tModelPanelOffset or {}
			if tData.sModel then
				local vModelPanel = vgui.Create("DModelPanel", vItem)
				vModelPanel:Dock(LEFT)
				vModelPanel:SetWide(vItem:GetTall())
				vModelPanel:SetModel(tData.sModel)
				vModelPanel:SetColor(tData.cColor or Color(255, 255, 255))
				vModelPanel:SetFOV(43)
				vModelPanel.LayoutEntity = function(self, eEntity)
					eEntity:SetPos(tModelPanelOffset.vecOffset or Vector(0, 0, 0))
					eEntity:SetAngles(tModelPanelOffset.angOffset or Angle(0, 0, 0))
					self:SetFOV(tModelPanelOffset.iFOV or 43)
				end
			end

			local vAddToCart = vgui.Create("DButton", vItem)
			vAddToCart:Dock(RIGHT)
			vAddToCart:SetWide(Solve.ScrW*0.1)
			vAddToCart:SetText("Mettre dans le panier")
			vAddToCart.DoClick = function()
				tItemFinderCart[sItemId] = (tItemFinderCart[sItemId] or 0) + 1
			end
		end

		iIndex = iEnd + 1
		if iIndex > #tQueuedItems then
			timer.Remove(sTimerName)
		end
	end)

end


local function NetReadOptionalString()
	if net.ReadBool() then
		return net.ReadString()
	end
	return nil
end
local function FindFreeSlot(tItems)
	local tUsedSlots = {}
	for _, tItem in pairs(tItems or {}) do
		if tItem.iSlot then
			tUsedSlots[tItem.iSlot] = true
		end
	end

	for i = 1, 1000 do
		if not tUsedSlots[i] then
			return i
		end
	end
	return 1
end

local function IsSlotFree(tItems, iSlot, sExcludeItemId)
	for sId, tItem in pairs(tItems or {}) do
		if sId ~= sExcludeItemId and tItem.iSlot == iSlot then
			return false
		end
	end
	return true
end

local function DetermineItemSlot(sItemId, sAccessoryId, tItemsOfType)
	if sAccessoryId ~= "" and sAccessoryId ~= "NULL" then
		return nil
	end

	local tSavedSlots = Solve.Naruto.Inventory.SavedSlots or {}
	local iSavedSlot = tSavedSlots[sItemId]

	if iSavedSlot and IsSlotFree(tItemsOfType, iSavedSlot, sItemId) then
		return iSavedSlot
	end

	return FindFreeSlot(tItemsOfType)
end

net.Receive("Solve.Naruto.Inventory:ClientSide", function()
	local iNetId = net.ReadUInt(3)

	if iNetId == 1 then
		local iCount = net.ReadUInt(32)

		Solve.Naruto.Inventory.Items = {}

		for i = 1, iCount do
			local sItemId = net.ReadString()
			local iItemCount = net.ReadUInt(32)
			local sAccessoryId = net.ReadString()

			local sOverrideName = NetReadOptionalString()
			local sOverrideDesc = NetReadOptionalString()
			Solve.Naruto.Inventory:SetClientItemOverride(sItemId, sOverrideName, sOverrideDesc)

			local tItemData = Solve.Naruto.Inventory:GetItemData(sItemId)
			if not tItemData then continue end

			Solve.Naruto.Inventory.Items[tItemData.sType] = Solve.Naruto.Inventory.Items[tItemData.sType] or {}
			local tItemsOfType = Solve.Naruto.Inventory.Items[tItemData.sType]

			tItemsOfType[sItemId] = tItemsOfType[sItemId] or {}
			local tItem = tItemsOfType[sItemId]

			tItem.iCount = iItemCount
			tItem.iSlot = DetermineItemSlot(sItemId, sAccessoryId, tItemsOfType)
			tItem.sAccessoryId = (sAccessoryId ~= "" and sAccessoryId ~= "NULL") and sAccessoryId or nil
		end

		if IsValid(Solve.Naruto.Inventory.vInventory) then
			Solve.Naruto.Inventory:DrawInventory(nil, nil, true)
		end

	elseif iNetId == 2 then
		local sItemId = net.ReadString()
		local tItemData = Solve.Naruto.Inventory:GetItemData(sItemId)
		if not tItemData then return end

		local tItemEntry = (Solve.Naruto.Inventory.Items[tItemData.sType] or {})[sItemId]
		if tItemEntry and IsValid(tItemEntry.vItem) then
			tItemEntry.vItem:Remove()
		end

		local tEquipVGUIs = Solve.Naruto.Inventory.tEquimentsVGUIS or {}
		local vEquipVGUI = (tEquipVGUIs[tItemData.sType] or {})[tItemData.sPlayerAccessory]
		if IsValid(vEquipVGUI) and IsValid(vEquipVGUI.vItem) then
			vEquipVGUI.vItem:Remove()
		end

		Solve.Naruto.Inventory.Items[tItemData.sType][sItemId] = nil
		Solve.Naruto.Inventory:SetClientItemOverride(sItemId, nil, nil)

	elseif iNetId == 3 then
		Solve.Naruto.Inventory.Items = {}
		Solve.Naruto.Inventory:ClearClientItemOverrides()

	elseif iNetId == 4 then
		local sItemId = net.ReadString()
		local tItemData = Solve.Naruto.Inventory:GetItemData(sItemId)
		if not tItemData then return end

		local tItem = (Solve.Naruto.Inventory.Items[tItemData.sType or ""] or {})[sItemId]
		if not tItem then return end

		tItem.sAccessoryId = nil
		Solve.Naruto.Inventory:DrawInventory(nil, nil, true)
	end
end)

hook.Add("PlayerButtonDown", "Solve.Naruto.Inventory:DrawInventory", function(_, iKey)

	if not IsFirstTimePredicted() then return end
	local xKey = Solve:GetSetting("inv_key")

	if iKey == xKey then

		Solve.Naruto.Inventory:DrawInventory()

	end

end)

local eCurrentEntity
local iCooldownRefresh = 0

local tItemsToDraw = {
	["solve_naruto_inventory_item"] = true,
	["solve_naruto_apparts_chest"] = true,
	["solve_naruto_blacksmith_forge"] = true,
	["solve_naruto_charette"] = true,
	["solve_naruto_charette_big"] = true,
}

hook.Add("HUDPaint", "Solve.Naruto.Inventory:HUDPaint", function()

	local pLocal = LocalPlayer()
	if not IsValid(pLocal) then return end

	local iCurTime = CurTime()

	if iCurTime > iCooldownRefresh then

		local iLastDist = 120
		eCurrentEntity = nil

		for _, eEntity in ipairs(ents.FindInSphere(pLocal:GetPos(), 120)) do

			if not tItemsToDraw[eEntity:GetClass()] then continue end
			local iDist = eEntity:GetPos():Distance(pLocal:GetPos())
			if iDist < iLastDist then
				iLastDist = iDist
				eCurrentEntity = eEntity
			end

		end

		iCooldownRefresh = iCurTime + 0.3

	end

	if not IsValid(eCurrentEntity) then return end

	// Prenvent item draw
	if hook.Run("Solve.Naruto.Inventory:DrawItem", eCurrentEntity) == true then return end

	local tItemData
	local sItemId = eCurrentEntity.GetItemId and eCurrentEntity:GetItemId() or false

	if sItemId == "money" then

		tItemData = {
			sLittleName = "Ryos",
		}

	else

		tItemData = Solve.Naruto.Inventory.Config["items"][sItemId]

	end


	local tRarity = Solve.Naruto.Inventory.Config["rarities"][(tItemData or {}).sRarity or ""]

	local vecEntityPos = eCurrentEntity:GetPos() + Vector(0, 0, math.sin(CurTime()*2)*4 + 25)
	local tEntityPosToScreen = vecEntityPos:ToScreen()

	local vecPos = vecEntityPos + Vector(0, 0, 20)
	local tPos = vecPos:ToScreen()

	tPos.x = math.Clamp(tPos.x, 0, Solve.ScrW)
	tPos.y = math.Clamp(tPos.y, 0, Solve.ScrH)

	surface.DrawLine(tPos.x + 20, tPos.y + 20, tEntityPosToScreen.x, tEntityPosToScreen.y)

	if matUseButton then

		local matW = iUseButtonW/1.5
		local matH = iUseButtonH/1.5

		surface.SetDrawColor(Solve.Naruto.Constants["colors"]["FFFFFF"])
		surface.SetMaterial(matUseButton)
		surface.DrawTexturedRect(tPos.x + 20 - matW/2, tPos.y - Solve.ScrH*0.075, matW, matH)

	end

	draw.SimpleText(tItemData and tItemData.sLittleName or "Use", Solve:Font(0.018, 4), tPos.x + 20, tPos.y - Solve.ScrH*0.021, Solve.Naruto.Constants["colors"]["FFFFFF"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	if tRarity then

		draw.SimpleText(tRarity.sLittleName, Solve:Font(0.015, 2), tPos.x + 20, tPos.y, tRarity.cColor  or Solve.Naruto.Constants["colors"]["FFFFFF"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	end

end)

hook.Add("PlayerBindPress", "Solve.Naruto.Inventory:UseItem", function(_, sBind, bPressed)

	if not bPressed then return end

	if sBind == "+use" and IsValid(eCurrentEntity) and eCurrentEntity:GetClass() == "solve_naruto_inventory_item" then

		net.Start("Solve.Naruto.Inventory:ServerSide")
			net.WriteUInt(4, 3)
			net.WriteEntity(eCurrentEntity)
		net.SendToServer()

	end

end)

net.Receive("Solve.Naruto.Inventory:AskPlayerMaskMode", function()

	Solve:Popup("Masque", "Voulez-vous apparaître masqué(e) ?", function()

		net.Start("Solve.Naruto.Inventory:AskPlayerMaskMode")
			net.WriteBool(true)
		net.SendToServer()

	end, function()

		net.Start("Solve.Naruto.Inventory:AskPlayerMaskMode")
			net.WriteBool(false)
		net.SendToServer()

	end)

end)

net.Receive("Solve.Naruto.Inventory:LookUpInventory", function()

	local tOverInv = {}
	local pInvOwner = net.ReadPlayer()

	local iCount = net.ReadUInt(3)

	for i = 1, iCount do

		local sKind = net.ReadString()
		local iItemsCount = net.ReadUInt(16)

		tOverInv[sKind] = tOverInv[sKind] or {}

		for i = 1, iItemsCount do

			local sItemId = net.ReadString()
			-- local iId = net.ReadUInt(32)
			local iCount = net.ReadUInt(16)
			local bAccessory = net.ReadBool()
			local sAccessoryId = bAccessory and net.ReadString() or nil

			tOverInv[sKind][sItemId] = {
				-- ["id"] = iId,
				["iCount"] = iCount,
				["sAccessoryId"] = sAccessoryId,
			}

		end

	end

	-- Auto-select the first tab that has items
	local sInitialTab = "objects"
	if not tOverInv["objects"] or not next(tOverInv["objects"]) then
		if tOverInv["cosmetics"] and next(tOverInv["cosmetics"]) then
			sInitialTab = "cosmetics"
		end
	end

	Solve.Naruto.Inventory:DrawInventory(sInitialTab, nil, nil, tOverInv, pInvOwner)

end)

// Lookup all the items in circulation
function Solve.Naruto.Inventory:LookUpAllItems()

	if IsValid(self.vLookUpAllItems) then self.vLookUpAllItems:Remove() end

	self.vLookUpAllItems = vgui.Create("DFrame")
	self.vLookUpAllItems:SetSize(Solve.ScrW*0.5, Solve.ScrH*0.5)
	self.vLookUpAllItems:Center()
	self.vLookUpAllItems:MakePopup()
	self.vLookUpAllItems:SetTitle("Items in Circulation <3")
	self.vLookUpAllItems:ShowCloseButton(true)
	self.vLookUpAllItems:SetBackgroundBlur(true)
	self.vLookUpAllItems:SetSizable(true)
	self.vLookUpAllItems.Paint = function(self, w, h)
		draw.RoundedBox(8, 0, 0, w, h, Color(50, 50, 50, 200))
	end

	local vItemsList = vgui.Create("DScrollPanel", self.vLookUpAllItems)
	for _, item in ipairs(items) do

		local tData = Solve.Naruto.Inventory:GetItemData(item.sItemId)
		if not tData then continue end

		local vItem = vgui.Create("DPanel", vItemsList)
		vItem:Dock(TOP)
		vItem:SetTall(Solve.ScrH*0.1)
		vItem:DockMargin(0, 0, 0, Solve.ScrH*0.01)
		vItem.Paint = function(_self, w, h)
			draw.SimpleText(tData.sLittleName.." - ("..item.sItemId..")", Solve:Font(0.02, 4), h*1.1, h/2, Solve.Naruto.Constants["colors"]["FFFFFF"], TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end

	end

end

net.Receive("Solve.Naruto.Inventory:LookupAllItems", function()



end)

net.Receive("Solve.Naruto.Inventory:ShowMapImage", function()

	local sImgurId = net.ReadString()

	if not sImgurId or sImgurId == "" then return end

	local iImageWidth = ScrW() * 0.7
	local iImageHeight = ScrH() * 0.7

	local vFrame = vgui.Create("DPanel")
	vFrame:SetSize(iImageWidth, iImageHeight)
	vFrame:Center()
	vFrame:MakePopup()
	vFrame.Paint = function(self, w, h)
		local mImage = Solve:GetImgurImage(sImgurId)
		if mImage then
			surface.SetDrawColor(255, 255, 255, 255)
			surface.SetMaterial(mImage)
			surface.DrawTexturedRect(0, 0, w, h)
		end
	end

	local iCloseSize = 40
	local vCloseButton = vgui.Create("DButton", vFrame)
	vCloseButton:SetSize(iCloseSize, iCloseSize)
	vCloseButton:SetPos(iImageWidth - iCloseSize - 100, 10)
	vCloseButton:SetText("")
	vCloseButton.Paint = function(self, w, h)
		local col = self:IsHovered() and Color(150, 150, 150, 255) or Color(100, 100, 100, 255)
		draw.RoundedBox(4, 0, 0, w, h, col)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawLine(10, 10, w - 10, h - 10)
		surface.DrawLine(w - 10, 10, 10, h - 10)
	end
	vCloseButton.DoClick = function()
		vFrame:Remove()
	end

end)