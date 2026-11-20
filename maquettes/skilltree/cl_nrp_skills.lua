local tMats = {
	["base"] = Material("materials/solve_nrp/nrp_interface/skills/base.png", ""),
	["circle"] = Material("materials/solve_nrp/nrp_interface/skills/rond_jutsu.png", "smooth"),
	["arrow"] = Material("materials/solve_nrp/nrp_interface/skills/arrow.png", "smooth"),
	["suiton_icon"] = Material("materials/solve_nrp/nrp_interface/skills/suiton_icon.png", "smooth"),
	["gradient"] = Material("materials/solve_nrp/nrp_interface/skills/gradient.png", "smooth"),
	["icon_exit"] = Material("materials/solve_nrp/nrp_interface/skills/icon_exit.png", "smooth"),
	["wave_cooldown"] = Material("materials/solve_nrp/nrp_interface/skills/wave_cooldown.png", "smooth"),
}

CreateConVar("nrp_show_learn", "1", FCVAR_ARCHIVE)

local M_Favorites = {}
local function GetFavFilePath()
    local ply = LocalPlayer()
    if not IsValid(ply) then return nil end
    local sid64 = ply:SteamID64() or "unknown"
    local charId = (ply.GetCharacterGlobalId and ply:GetCharacterGlobalId()) or 0
    file.CreateDir("solve_naruto/favorites")
    return string.format("solve_naruto/favorites/%s_%s.json", tostring(sid64), tostring(charId))
end

local function LoadFavorites()
    local path = GetFavFilePath()
    local favs = {}
    if path then
        local raw = file.Read(path, "DATA")
        if isstring(raw) and #raw > 0 then
            local t = util.JSONToTable(raw)
            if istable(t) then
                for _, sID in ipairs(t) do favs[sID] = true end
            end
        end
    end
    M_Favorites = favs
end

local function SaveFavorites()
    local path = GetFavFilePath()
    if not path then return end
    local list = {}
    for sID, b in pairs(M_Favorites) do if b then table.insert(list, sID) end end
    file.Write(path, util.TableToJSON(list, true))
end

local matLoccck, iLockW, iLockH = Solve:GetMaterial("combat_mode_lock")
local matDeck, iDeckW, iDeckH = Solve:GetMaterial("background_set_deck")
local matSetDeck, iSetDeckW, iSetDeckH = Solve:GetMaterial("set_deck")
M_tSkills = M_tSkills or {}
-- TFJ : style du menu B (sombre, transparent, sobre) à la place de la texture Solve skills/base.png
local TFJ_FOND = Color(8, 8, 10, 175)
local TFJ_TRAIT = Color(255, 255, 255, 16)
local TFJ_ROUGE = Color(170, 32, 38)
-- TFJ v2 : fenetre noire a double liseret, fine barre rouge en haut (maquettes/menu_b du depot Graphiphy)
local function TFJ_Cadre(x, y, w, h)
	surface.SetDrawColor(10, 10, 11, 245)
	surface.DrawRect(x, y, w, h)
	surface.SetDrawColor(58, 58, 64, 255)
	surface.DrawOutlinedRect(x, y, w, h, 1)
	surface.SetDrawColor(29, 29, 33, 255)
	surface.DrawOutlinedRect(x + 4, y + 4, w - 8, h - 8, 1)
	surface.SetDrawColor(216, 38, 47, 255)
	surface.DrawRect(x, y, w, 2)
end
local TFJB = {}
local iTFJBPoliceH
function TFJB.Polices()
	if iTFJBPoliceH == ScrH() then return end
	iTFJBPoliceH = ScrH()
	local VH = ScrH() / 100
	-- Bebas Neue : resource/fonts/bebasneue-regular.ttf (sv_tfj_polices.lua)
	surface.CreateFont("TFJB.Onglet", { font = "Bebas Neue", size = math.floor(VH * 3.2), weight = 400, extended = true })
	surface.CreateFont("TFJB.Titre", { font = "Bebas Neue", size = math.floor(VH * 5.6), weight = 400, extended = true })
	surface.CreateFont("TFJB.Groupe", { font = "Bebas Neue", size = math.floor(VH * 2.9), weight = 400, extended = true })
	surface.CreateFont("TFJB.Nom", { font = "Bebas Neue", size = math.floor(VH * 4.3), weight = 400, extended = true })
	surface.CreateFont("TFJB.Num", { font = "Bebas Neue", size = math.floor(VH * 2.3), weight = 400, extended = true })
	surface.CreateFont("TFJB.Kanji", { font = "MS Mincho", size = math.floor(VH * 2.4), weight = 700, extended = true })
end
-- couleur et kanji des groupes de natures (memes couleurs que les colonnes du F4)
local tTFJBNatures = {
	katon = { Color(255, 122, 26), "火" }, raiton = { Color(242, 176, 46), "雷" }, suiton = { Color(47, 155, 232), "水" },
	futon = { Color(123, 224, 90), "風" }, doton = { Color(192, 138, 74), "土" },
}
-- emplacements de la barre : un peu plus petits pour laisser la place au bouton "Enregistrer dans un deck"
local TFJB_SLOT_X, TFJB_SLOT_PAS, TFJB_SLOT_TAILLE, TFJB_SLOT_Y = 38.4, 11.2, 9.6, 53.6
M_tSkills.tSlots = M_tSkills.tSlots or {}
local iDeckSelected
local function fnDrawSpells(vPanel, iDeck)
	if not IsValid(vPanel) then return end
	local pLocal = LocalPlayer()
	for i = 1, 6 do
		if not IsValid(M_tSkills.tSlots[i]) then continue end
		M_tSkills.tSlots[i]:Remove()
	end

	local VH = ScrH() / 100
	local slotName = "nrp_skills" -- .. (iDeck == 3 and "_kenjutsu" or "")
	for i = 1, 6 do
		local iSlotId = i + ((iDeck - 1) * 6)
		local vSlot = vgui.Create("DButton", vPanel)
		vSlot:SetSize(VH * TFJB_SLOT_TAILLE, VH * TFJB_SLOT_TAILLE)
		vSlot:SetPos(VH * (TFJB_SLOT_X + (i - 1) * TFJB_SLOT_PAS), VH * TFJB_SLOT_Y)
		vSlot:Droppable(slotName)
		vSlot:SetText("")
		vSlot.bChange = true
		vSlot.nID = iSlotId
		vSlot:Receiver(slotName, function(self, tPanels, bDrop)
			if not bDrop then return end
			if not IsValid(tPanels[1]) then return end
			if tPanels[1].bChange then
				if tPanels[1].tSkill then
					net.Start("NRP::Battle::SetSkill")
					net.WriteUInt(iSlotId, 8)
					net.WriteString(tPanels[1].tSkill.sID)
					net.SendToServer()
					pLocal:SetNetworkVar("nrp_skill_" .. iSlotId, tPanels[1].tSkill.sID)
				else
					net.Start("NRP::Battle::RemoveSkill")
					net.WriteUInt(iSlotId, 8)
					net.SendToServer()
					pLocal:SetNetworkVar("nrp_skill_" .. iSlotId, false)
				end

				if self.tSkill then
					net.Start("NRP::Battle::SetSkill")
					net.WriteUInt(tPanels[1].nID, 8)
					net.WriteString(self.tSkill.sID)
					net.SendToServer()
					pLocal:SetNetworkVar("nrp_skill_" .. tPanels[1].nID, self.tSkill.sID)
				else
					net.Start("NRP::Battle::RemoveSkill")
					net.WriteUInt(tPanels[1].nID, 8)
					net.SendToServer()
					pLocal:SetNetworkVar("nrp_skill_" .. tPanels[1].nID, false)
				end
				return
			end

			for _, tSkill in pairs(M_tSkills) do
				if tSkill and tSkill.sID == tPanels[1].tSkill.sID then return end
			end

			--tPanels[1].tSkill.sID
			surface.PlaySound("solve_naruto_base/ui/menu_selection_v2.wav")
			net.Start("NRP::Battle::SetSkill")
			net.WriteUInt(iSlotId, 8)
			net.WriteString(tPanels[1].tSkill.sID)
			net.SendToServer()
			pLocal:SetNetworkVar("nrp_skill_" .. iSlotId, tPanels[1].tSkill.sID)
		end)

		vSlot.DoClick = function(self) vSelect = self.tSkill end
		vSlot.DoRightClick = function()
			if pLocal:IsInPVP() then return end
			net.Start("NRP::Battle::RemoveSkill")
			net.WriteUInt(iSlotId, 8)
			net.SendToServer()
			surface.PlaySound("solve_naruto_base/ui/menu_selection_v2.wav")
			pLocal:SetNetworkVar("nrp_skill_" .. iSlotId, false)
		end

		vSlot.Paint = function(self, w, h)
			local bPvp = pLocal:IsInPVP() or pLocal:GetNetworkVar("AyatsuriSpell1:Controlled")
			local iOldAlpha = surface.GetAlphaMultiplier()
			if bPvp then surface.SetAlphaMultiplier(0.05) end
			self.tSkill = M_Fight.tIDs[pLocal:GetNetworkVar("nrp_skill_" .. iSlotId, false)]
			local bClip = DisableClipping(true)
			draw.NoTexture()
			local nMoveX = CurTime() * -100
			draw.Arc(w / 2, h / 2, h / 2 + VH * 0.5, 2, 0 + nMoveX, 90 + nMoveX, 1, ColorAlpha(TFJ_ROUGE, 160))
			draw.Arc(w / 2, h / 2, h / 2 + VH * 0.5, 2, 180 + nMoveX, 270 + nMoveX, 1, ColorAlpha(TFJ_ROUGE, 160))
			DisableClipping(bClip)
			if not self.tSkill then return end
			if not self.tSkill.mImage then return end
			surface.SetDrawColor(255, 255, 255, 255)
			surface.SetMaterial(self.tSkill.mImage)
			surface.DrawTexturedRectRotated(w / 2, h / 2, w / 1.2, h / 1.2, 0)
			surface.SetAlphaMultiplier(iOldAlpha)
			if bPvp then
				surface.SetDrawColor(255, 255, 255, 255)
				surface.SetMaterial(matLoccck)
				surface.DrawTexturedRect(w / 2 - iLockW / 2, h / 2 - iLockH / 2, iLockW, iLockH)
			end
		end

		M_tSkills.tSlots[i] = vSlot
	end
end

local nPage = 1
local fightIcon = Material("solve_naruto_base/select_color_icon_white_v2.png")
hook.Add("PlayerButtonDown", "NRP::Skills::Open", function(pPlayer, nKey, bForce)
	if not IsFirstTimePredicted() and not bForce then return end
	if nKey ~= Solve:GetSetting("jutsu_menu_key") then return end
	local pLocal = pPlayer
	local VH = ScrH() / 100
	if IsValid(vFrame) then
		if vFrame.bClosing then
			vFrame:SetMouseInputEnabled(true)
			vFrame:Stop()
			vFrame:AlphaTo(255, 0.1)
		else
			vFrame:SetMouseInputEnabled(false)
			vFrame:Stop()
			vFrame:AlphaTo(0, 0.1, 0, function() vFrame:Remove() end)
		end

		vFrame.bClosing = not vFrame.bClosing
		return
	end

	LoadFavorites()

	vFrame = vgui.Create("DFrame")
	vFrame:SetSize(ScrW(), ScrH())
	vFrame:Center()
	vFrame:MakePopup()
	vFrame:ShowCloseButton(false)
	vFrame:SetDraggable(false)
	vFrame:SetKeyBoardInputEnabled(false)
	vFrame:SetTitle("")
	vFrame:SetAlpha(0)
	vFrame.Paint = function(self, w, h)
		surface.SetDrawColor(0, 0, 0, 150)
		surface.DrawRect(0, 0, w, h)
		if input.IsKeyDown(KEY_ESCAPE) and not self.bCloseEscape then
			hook.GetTable()["PlayerButtonDown"]["NRP::Skills::Open"](pPlayer, nKey, true)
			self.bCloseEscape = true
		end
	end

	vFrame:AlphaTo(255, 0.1)
	M_vSkillTree = vFrame
	Solve.Naruto.FocusedFrame = vFrame
	local nID
	local vMain = vgui.Create("DPanel", vFrame)
	vMain:SetSize(VH * 119.72, VH * 66.75)
	vMain:Center()
	vMain.Paint = function(self, w, h)
		-- TFJ v2 : barre d'onglets, fenetre principale ; fiche du sort a gauche, liste a droite, barre des 6 sorts en bas
		TFJB.Polices()
		TFJ_Cadre(VH * 1, VH * 0.65, VH * 117.9, VH * 5.65)
		TFJ_Cadre(VH * 1, VH * 7.6, VH * 117.9, VH * 58.5)
		surface.SetDrawColor(42, 42, 46, 255)
		surface.DrawRect(VH * 38, VH * 16.85, VH * 79, 1)
		surface.DrawRect(VH * 37, VH * 50.4, VH * 80.5, 1)
		for i = 1, 6 do
			draw.SimpleText(i, "TFJB.Num", VH * (TFJB_SLOT_X + (i - 1) * TFJB_SLOT_PAS + TFJB_SLOT_TAILLE / 2), VH * (TFJB_SLOT_Y - 0.3), Color(138, 138, 146), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		end
		draw.SimpleText("Cacher les jutsus non appris", "NRP::Poppins::2D::2.5::500", VH * 41.2, VH * 15.05, Color(196, 196, 202), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		if not nID or not M_Fight.tConfig.tSkillsCategories[nID] then return end
		local tCategory = M_Fight.tConfig.tSkillsCategories[nID]
		draw.SimpleText(string.upper(tCategory.sName), "TFJB.Titre", VH * 38, VH * 8.4, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end

	local vClose = vgui.Create("DButton", vMain)
	vClose:SetSize(28, 28)
	vClose:SetPos(vMain:GetWide() - vClose:GetWide() - VH * 3, VH * 2.35)
	vClose:SetText("")
	vClose.Paint = function(self, w, h)
		surface.SetDrawColor(self:IsHovered() and TFJ_ROUGE or Color(255, 255, 255, 150))
		for i = 0, 1 do
			surface.DrawLine(w * 0.25 + i, h * 0.25, w * 0.75 + i, h * 0.75)
			surface.DrawLine(w * 0.75 + i, h * 0.25, w * 0.25 + i, h * 0.75)
		end
	end

	vClose.DoClick = function() hook.GetTable()["PlayerButtonDown"]["NRP::Skills::Open"](pPlayer, nKey, true) end
	local vDeckPanel = vgui.Create("DButton", vFrame)
	vDeckPanel:SetSize(iDeckW, iDeckH)
	vDeckPanel:SetPos(Solve.ScrW / 2 - vMain:GetWide() / 2 - iDeckW + VH * 1 + 1, Solve.ScrH * 0.685)
	vDeckPanel:SetText("")
	vDeckPanel.Paint = function(self, w, h)
		TFJ_Cadre(0, 0, w, h)
		local iDeck = pLocal:GetNetworkVar("iDeckSelected", 1)
		draw.SimpleText("DECK", Solve:Font(0.011, 4), w / 2, h * 0.2, Color(255, 255, 255, 110), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(iDeck, Solve:Font(0.025, 4), w / 2, h * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		surface.SetDrawColor(self:IsHovered() and TFJ_ROUGE or TFJ_TRAIT)
		surface.DrawRect(w * 0.25, h * 0.78, w * 0.5, 2)
		if iDeckSelected ~= iDeck then
			iDeckSelected = iDeck
			fnDrawSpells(vMain, iDeck)
		end
	end

	vDeckPanel.DoClick = function()
		local iNewDeck = pLocal:GetNetworkVar("iDeckSelected", 1) == 1 and 2 or 1
		fnDrawSpells(vMain, iNewDeck)
		pLocal:SetNetworkVar("iDeckSelected", iNewDeck)
		surface.PlaySound("solve_naruto_base/ui/swap_jutsu_deck.wav")
		net.Start("NRP::Battle::Deck")
		net.WriteUInt(1, 3)
		net.SendToServer()
	end

	-- local vKenPanel = vgui.Create("DButton", vFrame)
	-- vKenPanel:SetSize(24, 24)
	-- vKenPanel:SetPos(Solve.ScrW/2 - vMain:GetWide() / 2 - Solve.ScrH * .025, Solve.ScrH*0.78)
	-- vKenPanel:SetText("")
	-- vKenPanel.Paint = function(self, w, h)
	--     surface.SetDrawColor(ColorAlpha(color_white, pLocal:GetNetworkVar("iDeckSelected", 1) == 3 and 255 or 100))
	--     surface.SetMaterial(fightIcon)
	--     surface.DrawTexturedRect(0, 0, w, h)
	-- end
	-- vKenPanel.DoClick = function()
	--     fnDrawSpells(vMain, pLocal:GetNetworkVar("iDeckSelected", 1) != 3 and 3 or 1)
	--     surface.PlaySound("solve_naruto_base/ui/swap_jutsu_deck.wav")
	--     net.Start("NRP::Battle::Deck")
	--         net.WriteUInt(2, 3)
	--     net.SendToServer()
	-- end
	local vSelect
	local vContainer
	local function fCategory(tCategories, sSearch, bLearn)
		if IsValid(vContainer) then vContainer:Remove() end
		if sSearch == "Look for ..." then sSearch = "" end
		vSelect = nil
		vContainer = vgui.Create("DPanel", vMain)
		vContainer:SetSize(VH * 79, VH * 31)
		vContainer:SetPos(VH * 38, VH * 18)
		vContainer.Paint = function() end
		local vScroll = vgui.Create("DScrollPanel", vContainer)
		vScroll:Dock(FILL)
		local sBar = vScroll:GetVBar()
		function sBar:Paint(w, h)
			--draw.RoundedBox(VH * 1, w/2, 0, w/2, h, Color(70, 55, 45, 100))
		end

		function sBar.btnUp:Paint(w, h)
		end

		function sBar.btnDown:Paint(w, h)
		end

		function sBar.btnGrip:Paint(w, h)
			local bClip = DisableClipping(true)
			--draw.RoundedBox(VH * 1, w/2, -w, w/2, h + w * 2, tColors["white05"])
			DisableClipping(bClip)
		end

		-- if sSearch and sSearch ~= "" and not string.find(string.lower(tSkill.sName), string.lower(sSearch)) then
		--     continue
		-- end
		local bSearch = (sSearch and sSearch ~= "") and true or false

		if tCategories.sUniqueId == "favoris" then
			local vLayout = vgui.Create("DIconLayout", vScroll)
			vLayout:SetStretchHeight(true)
			vLayout:Dock(FILL)
			vLayout:SetSpaceY(VH * 0.5)
			vLayout:SetSpaceX(VH * 0.5)

			local tFavoriteIDs = {}
			for sID, b in pairs(M_Favorites) do if b then table.insert(tFavoriteIDs, sID) end end
			table.sort(tFavoriteIDs)
			for _, sID in ipairs(tFavoriteIDs) do
				local tSkill = M_Fight.tIDs[sID]
				if not tSkill then continue end
				if bLearn and not pLocal:HasSkill(tSkill.sID) then continue end
				if bSearch and (not tSkill.sName or not string.find(string.lower(tSkill.sName), string.lower(sSearch))) then continue end
				local vButton = vgui.Create("DButton", vLayout)
				vButton:SetSize(VH * 7, VH * 7)
				vButton:SetText("")
				vButton:Droppable("nrp_skills")
				vButton.tSkill = tSkill
				vButton.Paint = function(self, w, h)
					self.iLerpHover = Lerp(FrameTime() * 10, self.iLerpHover or 0, self:IsHovered() and 1 or 0)
					if not pLocal:HasSkill(tSkill.sID) then surface.SetAlphaMultiplier(0.05) end
					surface.SetDrawColor(255, 255, 255, 255)
					surface.SetMaterial(tMats["circle"])
					surface.DrawTexturedRectRotated(w / 2, h / 2, w + (w * 0.2) * self.iLerpHover, h + (h * 0.2) * self.iLerpHover, 0)
					if not tSkill.mImage then return end
					surface.SetMaterial(tSkill.mImage)
					surface.DrawTexturedRectRotated(w / 2, h / 2, w * 0.85 + (w * 0.15) * self.iLerpHover, h * 0.85 + (h * 0.15) * self.iLerpHover, 0)
				end

				vButton.DoClick = function() vSelect = tSkill end
				vButton.DoRightClick = function()
					if input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT) then
						if pLocal:IsInPVP() then return end
						M_Favorites[tSkill.sID] = nil
						SaveFavorites()
						surface.PlaySound("solve_naruto_base/ui/menu_selection_v2.wav")
						if IsValid(M_vSkillTree) and isfunction(M_vSkillTree.M_RefreshFavorites) then
							M_vSkillTree:M_RefreshFavorites()
						end
						return
					end
					if pLocal:IsInPVP() then return end
					local iAvailableSlot
					for i = 1, 6 do
						i = i + (pLocal:GetNetworkVar("iDeckSelected", 1) - 1) * 6
						if not pLocal:GetNetworkVar("nrp_skill_" .. i, false) then
							iAvailableSlot = i
							break
						end
					end
					if not iAvailableSlot then return end
					pLocal:SetNetworkVar("nrp_skill_" .. iAvailableSlot, tSkill.sID)
					net.Start("NRP::Battle::SetSkill")
					net.WriteUInt(iAvailableSlot, 8)
					net.WriteString(tSkill.sID)
					net.SendToServer()
					surface.PlaySound("solve_naruto_base/ui/menu_selection_v2.wav")
				end
				if not vSelect then vButton:DoClick() end
			end
			return
		end

		if tCategories.bJutsu and not bSearch and not bLearn then
			local vLayout = vgui.Create("DIconLayout", vScroll)
			vLayout:SetStretchHeight(true)
			vLayout:Dock(FILL)
			vLayout:SetSpaceY(VH * 0.5)
			vLayout:SetSpaceX(0)
			for nCategory, tCategory in ipairs(tCategories.tCategories) do
				-- if not M_Fight.tConfig.bDev then
				-- if tCategory.bHide and not tCategory.fCan(pLocal) then continue end
				-- end
				local Jutsu = vgui.Create("DPanel", vLayout)
				Jutsu:SetSize(VH * 75, VH * 15)
				Jutsu:SetPos(VH * 3, VH * 18)
				Jutsu.Paint = function(self, w, h)
					if nCategory ~= #tCategories.tCategories then
						surface.SetDrawColor(TFJ_TRAIT)
						surface.DrawRect(0, h - 8, w, 1)
					end
				end

				local vCategoryHeader = vgui.Create("DPanel", Jutsu)
				vCategoryHeader:Dock(TOP)
				vCategoryHeader:SetTall(VH * 5)
				vCategoryHeader:DockMargin(0, 0, 0, VH * 1)
				vCategoryHeader.cBackgroundColor = tCategory.cGradientColor and tCategory.cGradientColor or Color(0, 140, 255, 5)
				vCategoryHeader.mGradient = Material("vgui/gradient-l")
				vCategoryHeader.Paint = function(self, w, h)
					-- TFJ v2
					local tNat = tTFJBNatures[string.lower(tCategory.sName or "")]
					local c = tNat and tNat[1] or ColorAlpha(self.cBackgroundColor, 255)
					local sNom = string.upper(tCategory.sName or "")
					sNom = (sNom == "FUTON") and "FÛTON" or sNom
					local nW = draw.SimpleText(sNom, "TFJB.Groupe", 0, h / 2, c, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
					if tNat then nW = nW + VH * 0.8 + draw.SimpleText(tNat[2], "TFJB.Kanji", nW + VH * 0.8, h / 2, c, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER) end
					local x0 = nW + VH * 1.2
					for i = 0, 15 do
						surface.SetDrawColor(c.r, c.g, c.b, 150 * (1 - i / 16))
						surface.DrawRect(x0 + (w - x0) * i / 16, h / 2, (w - x0) / 16 + 1, 1)
					end
				end

				local vScroll = vgui.Create("DScrollPanel", Jutsu)
				vScroll:Dock(FILL)
				vScroll:DockMargin(0, 0, 0, 0)
				local sBar = vScroll:GetVBar()
				function sBar:Paint(w, h)
				end

				function sBar.btnUp:Paint(w, h)
				end

				function sBar.btnDown:Paint(w, h)
				end

				function sBar.btnGrip:Paint(w, h)
				end

				local vParent = vgui.Create("DIconLayout", vScroll)
				vParent:SetStretchHeight(true)
				vParent:Dock(FILL)
				vParent:SetSpaceY(VH * 0.5)
				vParent:SetSpaceX(VH * 0.5)
				local sBar = vScroll:GetVBar()
				for nSkill, tSkill in ipairs(tCategory.tSkills) do
					if not tSkill then continue end
					if nSkill >= 11 then continue end
					local tSkill = M_Fight.tIDs[tSkill.sID]
					if not tSkill then continue end
					if tSkill.bHidden then if not pLocal:HasSkill(tSkill.sID) then continue end end
					if bLearn and not pLocal:HasSkill(tSkill.sID) then continue end
					if sSearch and sSearch ~= "" and not string.find(string.lower(tSkill.sName), string.lower(sSearch)) then continue end
					local vButton = vgui.Create("DButton", vParent)
					vButton:SetSize(VH * 7, VH * 7)
					vButton:SetText("")
					local slotName = "nrp_skills" -- .. (tSkill.sID:StartsWith("kenjutsu") and "_kenjutsu" or "")
					vButton:Droppable(slotName)
					vButton.tSkill = tSkill
					vButton.Paint = function(self, w, h)
						self.iLerpHover = Lerp(FrameTime() * 10, self.iLerpHover or 0, self:IsHovered() and 1 or 0)
						if not pLocal:HasSkill(tSkill.sID) then surface.SetAlphaMultiplier(0.05) end
						surface.SetDrawColor(255, 255, 255, 255)
						surface.SetMaterial(tMats["circle"])
						surface.DrawTexturedRectRotated(w / 2, h / 2, w + (w * 0.2) * self.iLerpHover, h + (h * 0.2) * self.iLerpHover, 0)
						if not tSkill.mImage then return end
						surface.SetMaterial(tSkill.mImage)
						surface.DrawTexturedRectRotated(w / 2, h / 2, w * 0.85 + (w * 0.15) * self.iLerpHover, h * 0.85 + (h * 0.15) * self.iLerpHover, 0)
						-- Rank
						local oldClip = DisableClipping(true)
						local tRankLinked = Solve.Naruto.Config["ranks"][tSkill.sMinimumRank or "genin"]
						if tRankLinked then
							local mat, iW, iH = Solve:GetMaterial(tRankLinked.sJutsuMat)
							iW = iW / 6
							iH = iH / 6
							if mat then
								surface.SetDrawColor(255, 255, 255, 255)
								surface.SetMaterial(mat)
								surface.DrawTexturedRectRotated(w * 0.8 + 5 * self.iLerpHover, h * 0.8 + 5 * self.iLerpHover, iW, iH, 0)
							end
						end

						DisableClipping(oldClip)
						surface.SetAlphaMultiplier(1)
					end

					vButton.DoClick = function() vSelect = tSkill end
					vButton.DoRightClick = function()
						if input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT) then
							if pLocal:IsInPVP() then return end
							M_Favorites[tSkill.sID] = true
							SaveFavorites()
							surface.PlaySound("solve_naruto_base/ui/menu_selection_v2.wav")
							if IsValid(M_vSkillTree) and isfunction(M_vSkillTree.M_RefreshFavorites) then
								M_vSkillTree:M_RefreshFavorites()
							end
							return
						end
						if pLocal:IsInPVP() then return end
						local iAvailableSlot
						for i = 1, 6 do
							i = i + (pLocal:GetNetworkVar("iDeckSelected", 1) - 1) * 6
							if not pLocal:GetNetworkVar("nrp_skill_" .. i, false) then
								iAvailableSlot = i
								break
							end
						end

						if not iAvailableSlot then return end
						pLocal:SetNetworkVar("nrp_skill_" .. iAvailableSlot, tSkill.sID)
						net.Start("NRP::Battle::SetSkill")
						net.WriteUInt(iAvailableSlot, 8)
						net.WriteString(tSkill.sID)
						net.SendToServer()
						surface.PlaySound("solve_naruto_base/ui/menu_selection_v2.wav")
					end

					if not vSelect then vButton:DoClick() end
				end
			end
		elseif tCategories.bSpecialJutsu and not bSearch and not bLearn then
			for nCategory, tCategory in ipairs(tCategories.tCategories) do
				-- if not M_Fight.tConfig.bDev then
				-- if tCategory.bHide and not tCategory.fCan(pLocal) then continue end
				-- end
				local Jutsu = vgui.Create("DPanel", vScroll)
				Jutsu:Dock(TOP)
				Jutsu:SetTall(VH * 8.5)
				Jutsu.Paint = function(self, w, h)
					if nCategory ~= #tCategories.tCategories then
						surface.SetDrawColor(TFJ_TRAIT)
						surface.DrawRect(0, h - 8, w, 1)
					end
				end

				local vJustuList = vgui.Create("DPanel", Jutsu)
				vJustuList:Dock(LEFT)
				vJustuList:SetWide(VH * 60)
				vJustuList:SetPaintBackground(false)

				local vScroll = vgui.Create("DScrollPanel", vJustuList)
				vScroll:Dock(FILL)
				local sBar = vScroll:GetVBar()
				function sBar:Paint(w, h)
				end

				function sBar.btnUp:Paint(w, h)
				end

				function sBar.btnDown:Paint(w, h)
				end

				function sBar.btnGrip:Paint(w, h)
				end

				local vParent = vgui.Create("DIconLayout", vScroll)
				vParent:SetStretchHeight(true)
				vParent:Dock(FILL)
				vParent:SetSpaceY(VH * 0.5)
				vParent:SetSpaceX(VH * 0.5)
				local sBar = vScroll:GetVBar()
				local iEmptySlots = 5 - table.Count(tCategory.tSkills)
				for nSkill, tSkill in ipairs(tCategory.tSkills) do
					if not tSkill then continue end
					-- if nSkill >= 11 then
					--     continue
					-- end
					-- print(tSkill.sID)
					local tSkill = M_Fight.tIDs[tSkill.sID]
					if not tSkill then continue end
					if tSkill.bHidden then if not pLocal:HasSkill(tSkill.sID) then continue end end
					if bLearn and not pLocal:HasSkill(tSkill.sID) then continue end
					if sSearch and sSearch ~= "" and not string.find(string.lower(tSkill.sName), string.lower(sSearch)) then continue end
					local vButton = vgui.Create("DButton", vParent)
					vButton:SetSize(VH * 7, VH * 7)
					vButton:SetText("")
					local slotName = "nrp_skills" -- .. (tSkill.sID:StartsWith("kenjutsu") and "_kenjutsu" or "")
					vButton:Droppable(slotName)
					vButton.tSkill = tSkill
					vButton.Paint = function(self, w, h)
						self.iLerpHover = Lerp(FrameTime() * 10, self.iLerpHover or 0, self:IsHovered() and 1 or 0)
						if not pLocal:HasSkill(tSkill.sID) then surface.SetAlphaMultiplier(0.05) end
						surface.SetDrawColor(255, 255, 255, 255)
						surface.SetMaterial(tMats["circle"])
						surface.DrawTexturedRectRotated(w / 2, h / 2, w + (w * 0.2) * self.iLerpHover, h + (h * 0.2) * self.iLerpHover, 0)
						if not tSkill.mImage then return end
						surface.SetMaterial(tSkill.mImage)
						surface.DrawTexturedRectRotated(w / 2, h / 2, w * 0.85 + (w * 0.15) * self.iLerpHover, h * 0.85 + (h * 0.15) * self.iLerpHover, 0)
						-- Rank
						local oldClip = DisableClipping(true)
						local tRankLinked = Solve.Naruto.Config["ranks"][tSkill.sMinimumRank or "genin"]
						if tRankLinked then
							local mat, iW, iH = Solve:GetMaterial(tRankLinked.sJutsuMat)
							iW = iW / 6
							iH = iH / 6
							if mat then
								surface.SetDrawColor(255, 255, 255, 255)
								surface.SetMaterial(mat)
								surface.DrawTexturedRectRotated(w * 0.8 + 5 * self.iLerpHover, h * 0.8 + 5 * self.iLerpHover, iW, iH, 0)
							end
						end

						DisableClipping(oldClip)
						surface.SetAlphaMultiplier(1)
					end

					vButton.DoClick = function() vSelect = tSkill end
					vButton.DoRightClick = function()
						-- Shift + Right Click: always ADD to favorites (outside Favorites tab)
						if input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT) then
							if pLocal:IsInPVP() then return end
							M_Favorites[tSkill.sID] = true
							SaveFavorites()
							surface.PlaySound("solve_naruto_base/ui/menu_selection_v2.wav")
							if IsValid(M_vSkillTree) and isfunction(M_vSkillTree.M_RefreshFavorites) then
								M_vSkillTree:M_RefreshFavorites()
							end
							return
						end
						if pLocal:IsInPVP() then return end
						local iAvailableSlot
						for i = 1, 6 do
							i = i + (pLocal:GetNetworkVar("iDeckSelected", 1) - 1) * 6
							if not pLocal:GetNetworkVar("nrp_skill_" .. i, false) then
								iAvailableSlot = i
								break
							end
						end

						if not iAvailableSlot then return end
						pLocal:SetNetworkVar("nrp_skill_" .. iAvailableSlot, tSkill.sID)
						net.Start("NRP::Battle::SetSkill")
						net.WriteUInt(iAvailableSlot, 8)
						net.WriteString(tSkill.sID)
						net.SendToServer()
						surface.PlaySound("solve_naruto_base/ui/menu_selection_v2.wav")
					end

					if not vSelect then vButton:DoClick() end
				end

				for i = 1, iEmptySlots do
					local vButton = vgui.Create("DButton", vParent)
					vButton:SetSize(VH * 7, VH * 7)
					vButton:SetText("")
					vButton.Paint = function(self, w, h)
						surface.SetAlphaMultiplier(0.05)
						surface.SetDrawColor(255, 255, 255, 255)
						surface.SetMaterial(tMats["circle"])
						surface.DrawTexturedRectRotated(w / 2, h / 2, w * 1.2, h * 1.2, 0)
						draw.SimpleText("SOON", Solve:Font(0.015, 4), w / 2, h / 2, Solve.Naruto.Constants["colors"]["FFFFFF50"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
					end
				end

				local vInfos = vgui.Create("DPanel", Jutsu)
				vInfos:Dock(FILL)
				vInfos.Paint = function(self, w, h)
					surface.SetDrawColor(255, 255, 255, 20)
					surface.SetMaterial(tCategory.mImage)
					surface.DrawTexturedRectRotated(w - VH * 7, h / 2, VH * 13.7, VH * 11.94, 0)
					draw.SimpleText(tCategory.sName, Solve:Font(44, 4, true), w, h, Color(255, 255, 255, 5), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
				end
			end
		elseif tCategories.bOther and not bSearch and not bLearn then
			for nCategory, tCategory in ipairs(tCategories.tCategories) do
				-- if not M_Fight.tConfig.bDev then
				-- if tCategory.bHide and not tCategory.fCan(pLocal) then continue end
				-- end

				local iVisibleJutsus = 0
				for nSkill, tSkill in ipairs(tCategory.tSkills) do
					if not tSkill then continue end
					local tSkill = M_Fight.tIDs[tSkill.sID]
					if not tSkill then continue end
					if tSkill.bHidden then if not pLocal:HasSkill(tSkill.sID) then continue end end
					if bLearn and not pLocal:HasSkill(tSkill.sID) then continue end
					iVisibleJutsus = iVisibleJutsus + 1
				end

				local iEmptySlots = 0
				if table.Count(tCategory.tSkills) < 5 then
					iEmptySlots = 5 - table.Count(tCategory.tSkills)
				end
				local iTotalItems = iVisibleJutsus + iEmptySlots

				local iJutsuListWidth = VH * 60
				local iSkillWidth = VH * 7
				local iSpaceX = VH * 0.5
				local iSkillsPerRow = math.floor(iJutsuListWidth / (iSkillWidth + iSpaceX))
				if iSkillsPerRow < 1 then iSkillsPerRow = 1 end

				local iRowsNeeded = math.max(1, math.ceil(iTotalItems / iSkillsPerRow))

				local iRowHeight = VH * 8

				local iCalculatedHeight = (iRowsNeeded * iRowHeight)

				local nTall = nCategory == 2 and VH * 17 or VH * 8.5
				local iCategoryHeight = math.max(nTall, iCalculatedHeight)

				local Jutsu = vgui.Create("DPanel", vScroll)
				Jutsu:Dock(TOP)
				Jutsu:SetTall(iCategoryHeight)
				Jutsu.Paint = function(self, w, h)
					if nCategory ~= #tCategories.tCategories then
						surface.SetDrawColor(TFJ_TRAIT)
						surface.DrawRect(0, h - 8, w, 1)
					end
				end

				local vJustuList = vgui.Create("DPanel", Jutsu)
				vJustuList:Dock(LEFT)
				vJustuList:SetWide(VH * 60)
				vJustuList:SetPaintBackground(false)

				local vParent = vgui.Create("DIconLayout", vJustuList)
				vParent:Dock(FILL)
				vParent:SetSpaceY(VH * 0.5)
				vParent:SetSpaceX(VH * 0.5)
				for nSkill, tSkill in ipairs(tCategory.tSkills) do
					if not tSkill then continue end
					-- if nSkill >= 11 then
					--     continue
					-- end
					-- print(tSkill.sID)
					local tSkill = M_Fight.tIDs[tSkill.sID]
					if not tSkill then continue end
					if tSkill.bHidden then if not pLocal:HasSkill(tSkill.sID) then continue end end
					if bLearn and not pLocal:HasSkill(tSkill.sID) then continue end
					local vButton = vgui.Create("DButton", vParent)
					vButton:SetSize(VH * 7, VH * 7)
					vButton:SetText("")
					local slotName = "nrp_skills" -- .. (tSkill.sID:StartsWith("kenjutsu") and "_kenjutsu" or "")
					vButton:Droppable(slotName)
					vButton.tSkill = tSkill
					vButton.Paint = function(self, w, h)
						self.iLerpHover = Lerp(FrameTime() * 10, self.iLerpHover or 0, self:IsHovered() and 1 or 0)
						if not pLocal:HasSkill(tSkill.sID) then surface.SetAlphaMultiplier(0.05) end
						-- if tEarlyAccessSkills[tSkill.sID] then
						--     surface.SetAlphaMultiplier(1)
						-- end
						surface.SetDrawColor(255, 255, 255, 255)
						surface.SetMaterial(tMats["circle"])
						surface.DrawTexturedRectRotated(w / 2, h / 2, w + (w * 0.2) * self.iLerpHover, h + (h * 0.2) * self.iLerpHover, 0)
						if not tSkill.mImage then return end
						surface.SetMaterial(tSkill.mImage)
						surface.DrawTexturedRectRotated(w / 2, h / 2, w * 0.85 + (w * 0.15) * self.iLerpHover, h * 0.85 + (h * 0.15) * self.iLerpHover, 0)
						-- Rank
						local oldClip = DisableClipping(true)
						local tRankLinked = Solve.Naruto.Config["ranks"][tSkill.sMinimumRank or "genin"]
						if tRankLinked then
							local mat, iW, iH = Solve:GetMaterial(tRankLinked.sJutsuMat)
							iW = iW / 6
							iH = iH / 6
							if mat then
								surface.SetDrawColor(255, 255, 255, 255)
								surface.SetMaterial(mat)
								surface.DrawTexturedRectRotated(w * 0.8 + 5 * self.iLerpHover, h * 0.8 + 5 * self.iLerpHover, iW, iH, 0)
							end
						end

						DisableClipping(oldClip)
						surface.SetAlphaMultiplier(1)
					end

					vButton.DoClick = function() vSelect = tSkill end
					vButton.DoRightClick = function()
						if input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT) then
							if pLocal:IsInPVP() then return end
							M_Favorites[tSkill.sID] = true
							SaveFavorites()
							surface.PlaySound("solve_naruto_base/ui/menu_selection_v2.wav")
							if IsValid(M_vSkillTree) and isfunction(M_vSkillTree.M_RefreshFavorites) then
								M_vSkillTree:M_RefreshFavorites()
							end
							return
						end
						if pLocal:IsInPVP() then return end
						local iAvailableSlot
						for i = 1, 6 do
							i = i + (pLocal:GetNetworkVar("iDeckSelected", 1) - 1) * 6
							if not pLocal:GetNetworkVar("nrp_skill_" .. i, false) then
								iAvailableSlot = i
								break
							end
						end

						if not iAvailableSlot then return end
						pLocal:SetNetworkVar("nrp_skill_" .. iAvailableSlot, tSkill.sID)
						net.Start("NRP::Battle::SetSkill")
						net.WriteUInt(iAvailableSlot, 8)
						net.WriteString(tSkill.sID)
						net.SendToServer()
						surface.PlaySound("solve_naruto_base/ui/menu_selection_v2.wav")
					end

					if not vSelect then vButton:DoClick() end
				end

				for i = 1, iEmptySlots do
					local vButton = vgui.Create("DButton", vParent)
					vButton:SetSize(VH * 7, VH * 7)
					vButton:SetText("")
					vButton.Paint = function(self, w, h)
						surface.SetAlphaMultiplier(0.05)
						surface.SetDrawColor(255, 255, 255, 255)
						surface.SetMaterial(tMats["circle"])
						surface.DrawTexturedRectRotated(w / 2, h / 2, w * 1.2, h * 1.2, 0)
						draw.SimpleText("SOON", Solve:Font(0.015, 4), w / 2, h / 2, Solve.Naruto.Constants["colors"]["FFFFFF50"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
					end
				end

				local vInfos = vgui.Create("DPanel", Jutsu)
				vInfos:Dock(FILL)
				vInfos.Paint = function(self, w, h)
					surface.SetDrawColor(255, 255, 255, 20)
					surface.SetMaterial(tCategory.mImage)
					surface.DrawTexturedRectRotated(w - VH * 7, h / 2, VH * 13.7, VH * 11.94, 0)
					draw.SimpleText(tCategory.sName, Solve:Font(49, 7, true), w, h, Color(255, 255, 255, 5), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
				end
			end
		else
			local vLayout = vgui.Create("DIconLayout", vScroll)
			vLayout:SetStretchHeight(true)
			vLayout:Dock(FILL)
			vLayout:SetSpaceY(VH * 0.5)
			vLayout:SetSpaceX(0)
			for nCategory, tCategory in ipairs(tCategories.tCategories) do
				-- if not M_Fight.tConfig.bDev then
				-- if tCategory.bHide and not tCategory.fCan(pLocal) then continue end
				-- end
				if not tCategory.tSkills then continue end
				for nSkill, tSkill in ipairs(tCategory.tSkills) do
					local tSkill = M_Fight.tIDs[tSkill.sID]
					if not tSkill then continue end
					if sSearch and sSearch ~= "" and not string.find(string.lower(tSkill.sName), string.lower(sSearch)) then continue end
					if tSkill.bHidden then if not pLocal:HasSkill(tSkill.sID) then continue end end
					if bLearn and not pLocal:HasSkill(tSkill.sID) then continue end
					local vButton = vgui.Create("DButton", vLayout)
					vButton:SetSize(VH * 7, VH * 7)
					vButton:SetText("")
					vButton:Droppable("nrp_skills")
					vButton.tSkill = tSkill
					vButton.Paint = function(self, w, h)
						self.iLerpHover = Lerp(FrameTime() * 10, self.iLerpHover or 0, self:IsHovered() and 1 or 0)
						if not pLocal:HasSkill(tSkill.sID) then surface.SetAlphaMultiplier(0.05) end
						-- do // TODO: Remove this
						-- if tEarlyAccessSkills[tSkill.sID] then
						--     surface.SetAlphaMultiplier(1)
						-- end
						-- end
						surface.SetDrawColor(255, 255, 255, 255)
						surface.SetMaterial(tMats["circle"])
						surface.DrawTexturedRectRotated(w / 2, h / 2, w + (w * 0.2) * self.iLerpHover, h + (h * 0.2) * self.iLerpHover, 0)
						if not tSkill.mImage then return end
						surface.SetMaterial(tSkill.mImage)
						surface.DrawTexturedRectRotated(w / 2, h / 2, w * 0.85 + (w * 0.15) * self.iLerpHover, h * 0.85 + (h * 0.15) * self.iLerpHover, 0)
						-- Rank
						local oldClip = DisableClipping(true)
						local tRankLinked = Solve.Naruto.Config["ranks"][tSkill.sMinimumRank or "genin"]
						if tRankLinked then
							local mat, iW, iH = Solve:GetMaterial(tRankLinked.sJutsuMat)
							iW = iW / 6
							iH = iH / 6
							if mat then
								surface.SetDrawColor(255, 255, 255, 255)
								surface.SetMaterial(mat)
								surface.DrawTexturedRectRotated(w * 0.8 + 5 * self.iLerpHover, h * 0.8 + 5 * self.iLerpHover, iW, iH, 0)
							end
						end

						DisableClipping(oldClip)
						surface.SetAlphaMultiplier(1)
					end

					vButton.DoClick = function() vSelect = tSkill end
					vButton.DoRightClick = function()
						if input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT) then
							if pLocal:IsInPVP() then return end
							M_Favorites[tSkill.sID] = true
							SaveFavorites()
							surface.PlaySound("solve_naruto_base/ui/menu_selection_v2.wav")
							if IsValid(M_vSkillTree) and isfunction(M_vSkillTree.M_RefreshFavorites) then
								M_vSkillTree:M_RefreshFavorites()
							end
							return
						end
						if pLocal:IsInPVP() then return end
						local iAvailableSlot
						for i = 1, 6 do
							i = i + (pLocal:GetNetworkVar("iDeckSelected", 1) - 1) * 6
							if not pLocal:GetNetworkVar("nrp_skill_" .. i, false) then
								iAvailableSlot = i
								break
							end
						end

						if not iAvailableSlot then return end
						pLocal:SetNetworkVar("nrp_skill_" .. iAvailableSlot, tSkill.sID)
						net.Start("NRP::Battle::SetSkill")
						net.WriteUInt(iAvailableSlot, 8)
						net.WriteString(tSkill.sID)
						net.SendToServer()
						surface.PlaySound("solve_naruto_base/ui/menu_selection_v2.wav")
					end

					if not vSelect then vButton:DoClick() end
				end
			end
		end
	end
	local bLearned = true

	-- TFJ v2 : largeurs mesurees d'abord pour repartir les onglets sur toute la barre
	TFJB.Polices()
	surface.SetFont("TFJB.Onglet")
	local tTFJLargeurs, nTFJTotal = {}, 0
	for nCategory, tCategory in ipairs(M_Fight.tConfig.tSkillsCategories) do
		tTFJLargeurs[nCategory] = surface.GetTextSize(string.upper(tCategory.sName)) + VH * 3
		nTFJTotal = nTFJTotal + tTFJLargeurs[nCategory]
	end
	local nTFJEcart = math.max(VH * 1, (VH * 113.9 - nTFJTotal) / math.max(1, #tTFJLargeurs - 1))
	local nPosX = VH * 3
	for nCategory, tCategory in ipairs(M_Fight.tConfig.tSkillsCategories) do
		local nSizeX = tTFJLargeurs[nCategory]
		local sNomOnglet = string.upper(tCategory.sName)
		local vCategory = vgui.Create("DButton", vMain)
		vCategory:SetPos(nPosX, VH * 1.1)
		vCategory:SetSize(nSizeX, VH * 4.8)
		vCategory:SetText("")
		vCategory.Paint = function(self, w, h)
			self.iHoverLerp = Lerp(FrameTime() * 5, self.iHoverLerp or 0, (self:IsHovered() or (nID == nCategory)) and 1 or 0)
			if nID == nCategory then
				-- aplat rouge facon trait de pinceau
				draw.NoTexture()
				surface.SetDrawColor(216, 38, 47, 255)
				surface.DrawPoly({ { x = 0, y = h * 0.14 }, { x = w * 0.06, y = 0 }, { x = w * 0.94, y = h * 0.06 }, { x = w, y = h * 0.3 }, { x = w * 0.97, y = h }, { x = w * 0.03, y = h * 0.92 } })
			end
			local iC = 138 + 117 * self.iHoverLerp
			draw.SimpleText(sNomOnglet, "TFJB.Onglet", w / 2, h / 2 + 1, Color(iC, iC, iC + 8 * (1 - self.iHoverLerp)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		vCategory.DoClick = function()
			nID = nCategory
			nPage = nCategory
			fCategory(tCategory, "", bLearned)
			surface.PlaySound("solve_naruto_base/ui/bruitage_switch_jutsu.wav")
		end

		if not nPage or nPage == nCategory then vCategory:DoClick() end
		nPosX = nPosX + nSizeX + nTFJEcart
	end

	vFrame.M_RefreshFavorites = function(self)
		if not nID then return end
		local tCat = M_Fight.tConfig.tSkillsCategories[nID]
		if not tCat or tCat.sUniqueId ~= "favoris" then return end
		local sSearchText = IsValid(vTextEntry) and vTextEntry:GetText() or ""
		fCategory(tCat, sSearchText, bLearned)
	end

	local sSearch = GetFAIcon("f002")
	local cColor = Color(255, 255, 255, 100)
	local matSearch = Solve:GetMaterial("solve_nrp_combat_search_bar_loupe")
	local vText = vgui.Create("DTextEntry", vMain)
	vText:SetSize(VH * 20, VH * 2.6)
	vText:SetPos(VH * 96.9, VH * 10.5)
	vText.Paint = function(self, w, h)
		NRP:RoundedBox(3, 0, 0, w, h, Color(0, 0, 0, 120))
		if matSearch then
			surface.SetDrawColor(cColor)
			surface.SetMaterial(matSearch)
			surface.DrawTexturedRectRotated(w - VH, h / 2, h * 0.6, h * 0.6, -90)
		end
	end

	local showLearned = GetConVar("nrp_show_learn")
	local vTextEntry = vgui.Create("DTextEntry", vText)
	vTextEntry:SetSize(VH * 20 - VH * 1, VH * 2.6 - VH * 1)
	vTextEntry:SetPos(VH * 0.5, VH * 0.7)
	vTextEntry:SetDrawLanguageID(false)
	vTextEntry:SetFont("NRP::Poppins::2D::3::500")
	vTextEntry:SetText("Recherche...")
	vTextEntry.OnMousePressed = function(self, nCode)
		vFrame:MakePopup()
		if self:GetText() == "Recherche..." then self:SetText("") end
		if nCode == MOUSE_LEFT then self:OnGetFocus() end
	end

	vTextEntry.OnTextChanged = function(self) fCategory(M_Fight.tConfig.tSkillsCategories[nID], self:GetText(), bLearned) end
	vTextEntry.OnLoseFocus = function() vFrame:SetKeyboardInputEnabled(false) end
	vTextEntry.Paint = function(self, w, h) self:DrawTextEntryText(cColor, cColor, cColor) end
	local vCheck = vgui.Create("DButton", vMain)
	vCheck:SetSize(VH * 2.2, VH * 2.2)
	vCheck:SetPos(VH * 38, VH * 13.95)
	vCheck:SetText("")
	vCheck.Paint = function(self, w, h)
		surface.SetDrawColor(18, 18, 20, 255)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(self:IsHovered() and TFJ_ROUGE or Color(102, 102, 108))
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		if bLearned then
			surface.SetDrawColor(216, 38, 47, 255)
			surface.DrawRect(w * 0.25, h * 0.25, w * 0.5, h * 0.5)
		end
	end

	vCheck.DoClick = function()
		bLearned = not bLearned
		showLearned:SetBool(bLearned)

		fCategory(M_Fight.tConfig.tSkillsCategories[nID], vTextEntry:GetText(), bLearned)
		surface.PlaySound("solve_naruto_base/ui/menu_selection_v2.wav")
	end

	if (showLearned:GetBool() != bLearned) then
		vCheck:DoClick()
	end

	vFrame.M_RefreshFavorites = function(self)
		if not IsValid(vMain) then return end
		if not nID then return end
		local tCat = M_Fight.tConfig.tSkillsCategories[nID]
		if not tCat or tCat.sUniqueId ~= "favoris" then return end
		local sSearchText = IsValid(vTextEntry) and vTextEntry:GetText() or ""
		fCategory(tCat, sSearchText, bLearned)
	end

	local vInfo = vgui.Create("DPanel", vMain)
	vInfo:SetSize(VH * 33.5, VH * 55.4)
	vInfo:SetPos(VH * 2.5, VH * 9.2)
	vInfo.Paint = function(self, w, h)
		-- TFJ v2 : fiche du sort selectionne (image dans un rond, nom, description, niveau en losanges, recharge)
		surface.SetDrawColor(17, 17, 19, 255)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(42, 42, 46, 255)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		if not vSelect then return end
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(tMats["circle"])
		surface.DrawTexturedRectRotated(w / 2, VH * 11.2, VH * 17, VH * 17, 0)
		if vSelect.mImage then
			surface.SetMaterial(vSelect.mImage)
			surface.DrawTexturedRectRotated(w / 2, VH * 11.2, VH * 13.8, VH * 13.8, 0)
		end
		draw.SimpleText(string.upper(vSelect.sName or ""), "TFJB.Nom", w / 2, VH * 23.2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		local sDesc = NRP:SplitText(vSelect.sDesc or "", w - VH * 3, "NRP::Poppins::2D::2::500")
		local _, nY = surface.GetTextSize(sDesc)
		draw.DrawText(sDesc, "NRP::Poppins::2D::2::500", w / 2, VH * 26, Color(196, 196, 202), TEXT_ALIGN_CENTER)
		local nTotalLevel = #vSelect.tLevels
		local tAppris = pLocal:HasSkill(vSelect.sID)
		local nActualLevel = tAppris and tAppris.nLevel or 0
		nY = nY + VH * 2 + VH * 26
		-- niveau : un losange par niveau, rouges jusqu'au niveau atteint
		local nL, nPas = VH * 1.5, VH * 2.6
		local x0 = w / 2 - (nTotalLevel - 1) * nPas / 2
		draw.NoTexture()
		for i = 1, nTotalLevel do
			local bOk = i <= nActualLevel
			surface.SetDrawColor(bOk and Color(216, 38, 47) or Color(85, 85, 92))
			surface.DrawTexturedRectRotated(x0 + (i - 1) * nPas, nY + nL, nL, nL, 45)
			if not bOk then
				surface.SetDrawColor(17, 17, 19, 255)
				surface.DrawTexturedRectRotated(x0 + (i - 1) * nPas, nY + nL, nL - 2, nL - 2, 45)
			end
		end
		draw.SimpleText(nActualLevel == 0 and "Non appris" or ("Niveau " .. nActualLevel .. " / " .. nTotalLevel), "NRP::Poppins::2D::2::500", w / 2, nY + VH * 3.4, Color(138, 138, 146), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		local nCoolDown = (vSelect.tLevels[1] or {}).nCoolDown or 0
		draw.SimpleText("RECHARGE  " .. nCoolDown .. " S", "TFJB.Num", w / 2, h - VH * 1.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
	end

	fnDrawSpells(vMain, pLocal:GetNetworkVar("iDeckSelected", 1))
	-- for i = 1, 6 do
	--     local vSlot = vgui.Create("DButton", vMain)
	--     vSlot:SetSize(VH * 11, VH * 11)
	--     vSlot:SetPos(VH * 3.45 + (i - 1) * VH * 13.05, VH * 53)
	--     vSlot:Droppable("nrp_skills")
	--     vSlot:SetText("")
	--     vSlot.bChange = true
	--     vSlot.nID = i
	--     vSlot:Receiver("nrp_skills", function(self, tPanels, bDrop)
	--         if not bDrop then return end
	--         if not IsValid(tPanels[1]) then return end
	--         if tPanels[1].bChange then
	--             if tPanels[1].tSkill then
	--                 net.Start("NRP::Battle::SetSkill")
	--                     net.WriteUInt(i, 8)
	--                     net.WriteString(tPanels[1].tSkill.sID)
	--                 net.SendToServer()
	--             else
	--                 net.Start("NRP::Battle::RemoveSkill")
	--                     net.WriteUInt(i, 8)
	--                 net.SendToServer()
	--             end
	--             if self.tSkill then
	--                 net.Start("NRP::Battle::SetSkill")
	--                     net.WriteUInt(tPanels[1].nID, 8)
	--                     net.WriteString(self.tSkill.sID)
	--                 net.SendToServer()
	--             else
	--                 net.Start("NRP::Battle::RemoveSkill")
	--                     net.WriteUInt(tPanels[1].nID, 8)
	--                 net.SendToServer()
	--             end
	--             return
	--         end
	--         for _, tSkill in pairs(M_tSkills) do
	--             if tSkill and tSkill.sID == tPanels[1].tSkill.sID then
	--                 return
	--             end
	--         end
	--         //tPanels[1].tSkill.sID
	--         net.Start("NRP::Battle::SetSkill")
	--             net.WriteUInt(i, 8)
	--             net.WriteString(tPanels[1].tSkill.sID)
	--         net.SendToServer()
	--     end)
	--     vSlot.DoClick = function(self)
	--         vSelect = self.tSkill
	--     end
	--     vSlot.DoRightClick = function()
	--         net.Start("NRP::Battle::RemoveSkill")
	--             net.WriteUInt(i, 8)
	--         net.SendToServer()
	--     end
	--     vSlot.Paint = function(self, w, h)
	--         self.tSkill = M_Fight.tIDs[pLocal:GetNetworkVar("nrp_skill_" .. i, false)]
	--         local bClip = DisableClipping(true)
	--         draw.NoTexture()
	--         local nMoveX = CurTime() * -100
	--         draw.Arc(w/2, h/2, h/2 + VH * 0.5, 2, 0 + nMoveX, 90 + nMoveX, 1, Color(33, 33, 33, 255))
	--         draw.Arc(w/2, h/2, h/2 + VH * 0.5, 2, 180 + nMoveX, 270 + nMoveX, 1, Color(33, 33, 33, 255))
	--         DisableClipping(bClip)
	--         if not self.tSkill then return end
	--         if not self.tSkill.mImage then return end
	--         surface.SetDrawColor(255, 255, 255, 255)
	--         surface.SetMaterial(self.tSkill.mImage)
	--         surface.DrawTexturedRectRotated(w/2, h/2, w / 1.2, h / 1.2, 0)
	--     end
	-- end
end)

function GetFAIcon(sFAIcon)
	return utf8.char(tonumber("0x" .. sFAIcon))
end

local sCircle = GetFAIcon("f111")
local nPosY = ScrH()
hook.Add("HUDPaint", "NRP::HUDPaint::Skills", function()
	-- pLocal = LocalPlayer()
	-- if not Solve:GetSetting("hud") then return end
	-- if not hook.Run("Solve.Naruto:PreventHUDDraw") then return end
	-- local VH = ScrH() / 100
	-- local nSize, nGap, nCount = VH * 5.4, VH * 2, 6
	-- local nPosX = ScrW() / 2 - (nCount * nSize + (nCount - 1) * nGap) / 2
	-- local nAlpha = surface.GetAlphaMultiplier()
	-- if not IsValid(pLocal:GetActiveWeapon()) or pLocal:GetActiveWeapon():GetClass() ~= "naruto_base_swep" then
	--     surface.SetAlphaMultiplier(0.5)
	--     nPosY = Lerp(15/(1/FrameTime()), nPosY, ScrH() - VH * 2.5)
	-- else
	--     surface.SetAlphaMultiplier(1)
	--     nPosY = Lerp(15/(1/FrameTime()), nPosY, ScrH() - VH * 7)
	-- end
	-- local nY = nPosY
	-- --M_AB:RoundedBox(VH * 1.2, nPosX - nGap, nY - nGap, nCount * nSize + (nCount - 1) * nGap + nGap * 2, nSize + nGap * 2, tColors["black20"])
	-- for i = 1, nCount do
	--     local nX, nY = nPosX + (i - 1) * (nSize + nGap) + nSize / 2 - 1, nY + nSize / 2 - 1
	--     if M_Fight.nSelectSkill == i then
	--         draw.SimpleText(sCircle, "NRP::Font::FA::24", nX, nY, Color(55, 148, 255, 255*(1 or 0.35)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	--     else
	--         draw.SimpleText(sCircle, "NRP::Font::FA::24", nX, nY, Color(19, 20, 19, 255*(1 or 0.35)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	--     end
	--     local tSkill = M_Fight.tIDs[pLocal:GetNetworkVar("nrp_skill_" .. i, false)]
	--     if not tSkill then
	--         draw.SimpleText(i, "NRP::Poppins::2D::3::1000", nX, nY - VH * 3, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	--         continue
	--     end
	--     if pLocal:GetNetworkVar(tSkill.sID, 0) > CurTime() then
	--         surface.SetDrawColor(255, 255, 255, 255)
	--     else
	--         surface.SetDrawColor(255, 255, 255, 255)
	--     end
	--     surface.SetMaterial(tSkill.mImage)
	--     surface.DrawTexturedRectRotated(nX + 1, nY + 1, nSize + 2, nSize, 0)
	--     if pLocal:GetNetworkVar(tSkill.sID, 0) > CurTime() then
	--         NRP:DrawStencil(function()
	--             NRP:DrawCircle(nX, nY, 360, 30, 360, nSize / 2)
	--         end, function()
	--             surface.SetDrawColor(255, 255, 255, 255 * 0.9)
	--             surface.SetMaterial(tMats["wave_cooldown"])
	--             surface.DrawTexturedRect(nX - VH * 15 + math.sin(CurTime() * 1) * VH * 10, nY + nSize / 2 - ((pLocal:GetNetworkVar(tSkill.sID, 0) - CurTime())/tSkill.tLevels[1].nCoolDown) * nSize, VH * 92.59 / 2, VH * 32.31 / 2)
	--         end)
	--     end
	--     if pLocal:GetNetworkVar(tSkill.sID, 0) > CurTime() then
	--         draw.SimpleText(math.floor(pLocal:GetNetworkVar(tSkill.sID, 0) - CurTime()), "NRP::Poppins::2D::5::1000", nX, nY + VH * 0.3, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	--     end
	--     draw.SimpleText(i, "NRP::Poppins::2D::3::1000", nX, nY - VH * 3, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	--     /*if M_AB.tCooldowns[sSkill] and M_AB.tCooldowns[sSkill] > CurTime() then
	--         M_AB:RenderSkill(tSkill, nX, nY, "AB::Font::FA::10", VH * 5, Color(119, 205, 255, 50), 100)
	--         draw.SimpleText(math.ceil(M_AB.tCooldowns[sSkill] - CurTime()), "AB::Font::Bold::4", nX, nY, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	--     else
	--         M_AB:RenderSkill(tSkill, nX, nY, "AB::Font::FA::10", VH * 4, Color(119, 205, 255, 255), 255)
	--     end*/
	-- end
	-- surface.SetAlphaMultiplier(nAlpha)
end)

NRP = NRP or {}
function NRP:SplitText(sText, nWidth, sFont)
	surface.SetFont(sFont)
	local parsingText = string.Explode(" ", string.Replace(sText, "\n", " "))
	local endText = ""
	local lastLine = ""
	local sizeW
	for k, v in ipairs(parsingText) do
		sizeW = surface.GetTextSize(lastLine .. " " .. v)
		if sizeW > nWidth then
			endText = endText .. "\n"
			lastLine = ""
		end

		if lastLine == "" then
			lastLine = lastLine .. v
			endText = endText .. v
		else
			lastLine = lastLine .. " " .. v
			endText = endText .. " " .. v
		end
	end
	return string.Trim(endText)
end

-- Draws an arc on your screen.
-- startang and endang are in degrees,
-- radius is the total radius of the outside edge to the center.
-- cx, cy are the x,y coordinates of the center of the arc.
-- roughness determines how many triangles are drawn. Number between 1-360; 2 or 3 is a good number.
function draw.Arc(cx, cy, radius, thickness, startang, endang, roughness, color)
	surface.SetDrawColor(color)
	surface.DrawArc(surface.PrecacheArc(cx, cy, radius, thickness, startang, endang, roughness))
end

function surface.PrecacheArc(cx, cy, radius, thickness, startang, endang, roughness)
	local triarc = {}
	if not isnumber(radius) or radius <= 0 or not isnumber(thickness) or thickness <= 0 then
		return triarc
	end
	-- local deg2rad = math.pi / 180
	-- Define step
	local step = math.max(tonumber(roughness) or 1, 1)
	-- Correct start/end ang
	local startang, endang = tonumber(startang) or 0, tonumber(endang) or 0
	if startang > endang then step = math.abs(step) * -1 end
	-- Create the inner circle's points.
	local inner = {}
	local r = radius - thickness
	for deg = startang, endang, step do
		local rad = math.rad(deg)
		-- local rad = deg2rad * deg
		local ox, oy = cx + (math.cos(rad) * r), cy + (-math.sin(rad) * r)
		table.insert(inner, {
			x = ox,
			y = oy,
			u = (ox - cx) / radius + .5,
			v = (oy - cy) / radius + .5,
		})
	end

	-- Create the outer circle's points.
	local outer = {}
	for deg = startang, endang, step do
		local rad = math.rad(deg)
		-- local rad = deg2rad * deg
		local ox, oy = cx + (math.cos(rad) * radius), cy + (-math.sin(rad) * radius)
		table.insert(outer, {
			x = ox,
			y = oy,
			u = (ox - cx) / radius + .5,
			v = (oy - cy) / radius + .5,
		})
	end

	-- Triangulize the points.
	-- Each adjacent point pair forms two triangles; do not emit a segment past the final point.
	for tri = 1, math.max(#inner - 1, 0) * 2 do
		local p1, p2, p3
		p1 = outer[math.floor(tri / 2) + 1]
		p3 = inner[math.floor((tri + 1) / 2) + 1]
		if tri % 2 == 0 then --if the number is even use outer.
			p2 = outer[math.floor((tri + 1) / 2)]
		else
			p2 = inner[math.floor((tri + 1) / 2)]
		end

		if p1 and p2 and p3 then
			table.insert(triarc, {p1, p2, p3})
		end
	end
	-- Return a table of triangles to draw.
	return triarc
end

function surface.DrawArc(arc) --Draw a premade arc.
	for k, v in ipairs(arc) do
		if istable(v) and #v >= 3 then
			surface.DrawPoly(v)
		end
	end
end

local cGrey = Color(255, 255, 255, 102)
local vMain

-- TFJ : skill tree au style TFJ. Fond fourni par le fondateur + calques des icônes/noms des arbres (extraits des fonds Solve),
-- cadre dessiné, un seul accent rouge. Si les textures tfj_skilltree manquent, on retombe sur les fonds Solve.
local TFJ_ROUGE_CLAIR = Color(225, 75, 80)
local tTFJCalques = { ["Natures"] = "natures", ["Styles"] = "styles", ["Classes"] = "classes" }
local tTFJMats = {}
local function TFJ_Mat(sFichier)
	if tTFJMats[sFichier] == nil then
		local m = Material("tfj_skilltree/" .. sFichier, "smooth")
		tTFJMats[sFichier] = (m and not m:IsError()) and m or false
	end
	return tTFJMats[sFichier] or nil
end
local function TFJ_CadreArbre(x, y, w, h, cFond)
	draw.RoundedBox(6, x, y, w, h, Color(255, 255, 255, 16))
	draw.RoundedBox(6, x + 1, y + 1, w - 2, h - 2, cFond or Color(8, 8, 10, 150))
end
-- Lettre de rang d'une technique, même découpage que tfj_equilibrage_rang (iPower du grade minimum)
local tTFJOrdreRang = { "D", "C", "B", "A", "S", "X" }
local function TFJ_RangTechnique(tSkill)
	local sRank = tSkill.sMinimumRank or (tSkill.tLevels and tSkill.tLevels[1] and tSkill.tLevels[1].sMinimumRank) or "genin"
	local tRank = Solve.Naruto.Config["ranks"][sRank]
	local iPower = tRank and tRank.iPower or 0
	if iPower <= 5 then return 1 elseif iPower == 6 then return 2 elseif iPower == 7 then return 3
	elseif iPower == 8 then return 4 elseif iPower <= 11 then return 5 end
	return 6
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- TFJ v2 : une colonne par arbre (degrade de couleur + illustration + nom),
-- onglets en capitales avec le logo au centre, points de competence en bas a gauche.
-- Maquettes : maquettes/classe/maquette_f4_*.html (depot Graphiphy).
-- Images attendues dans materials/tfj_skilltree/ (f4_<arbre>.png, f4_logo.png, f4_mascotte.png) :
-- si une image manque, la colonne s'affiche sans elle.
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local TFJ2 = {}
local TFJ2_ROUGE_SOMBRE = Color(90, 15, 18)
-- ordre d'affichage des colonnes (celui des maquettes), sinon ordre de la config
local tTFJ2Ordre = {
	katon = 1, futon = 2, raiton = 3, doton = 4, suiton = 5,
	taijutsu_man = 1, taijutsu = 2, kenjutsu = 3, kenjutsu_expert = 4,
	guerrier = 1, mirage = 2, medicale = 3, robustesse = 4,
}
local tTFJ2Noms = {
	katon = "KATON", futon = "FÛTON", raiton = "RAITON", doton = "DOTON", suiton = "SUITON",
	taijutsu_man = "TAIJUTSU EXPERT", taijutsu = "TAIJUTSU", kenjutsu = "KENJUTSU", kenjutsu_expert = "KENJUTSU EXPERT",
	guerrier = "COMBATTANT", mirage = "MIRAGE", medicale = "MÉDECIN", robustesse = "ROBUSTE",
}
-- degrade de chaque colonne (haut, bas), tire des couleurs de son illustration
local tTFJ2Couleurs = {
	katon = { Color(255, 122, 26), Color(196, 22, 12) }, futon = { Color(123, 224, 90), Color(31, 168, 154) },
	raiton = { Color(242, 176, 46), Color(47, 143, 224) }, doton = { Color(192, 138, 74), Color(26, 160, 168) },
	suiton = { Color(47, 155, 232), Color(27, 63, 181) },
	taijutsu_man = { Color(200, 240, 64), Color(31, 143, 58) }, taijutsu = { Color(124, 200, 80), Color(224, 150, 46) },
	kenjutsu = { Color(111, 143, 208), Color(28, 40, 72) }, kenjutsu_expert = { Color(214, 200, 138), Color(47, 106, 96) },
	guerrier = { Color(95, 191, 74), Color(31, 107, 46) }, mirage = { Color(154, 154, 184), Color(58, 58, 88) },
	medicale = { Color(232, 200, 96), Color(79, 138, 58) }, robustesse = { Color(210, 58, 42), Color(42, 52, 40) },
}

local iTFJ2PoliceH
function TFJ2.Polices()
	if iTFJ2PoliceH == ScrH() then return end
	iTFJ2PoliceH = ScrH()
	local VH = ScrH() / 100
	-- Bebas Neue : resource/fonts/bebasneue-regular.ttf (envoyee par sv_tfj_polices.lua)
	surface.CreateFont("TFJF4.Onglet", { font = "Bebas Neue", size = math.floor(VH * 3.2), weight = 400, extended = true })
	surface.CreateFont("TFJF4.Nom", { font = "Bebas Neue", size = math.floor(VH * 5.9), weight = 400, extended = true })
	surface.CreateFont("TFJF4.NomLong", { font = "Bebas Neue", size = math.floor(VH * 4.3), weight = 400, extended = true })
	surface.CreateFont("TFJF4.Points", { font = "Bebas Neue", size = math.floor(VH * 8.9), weight = 400, extended = true })
	surface.CreateFont("TFJF4.Label", { font = "Bebas Neue", size = math.floor(VH * 2.8), weight = 400, extended = true })
end

-- degrade vertical fait de bandes (independant des textures gui/gradient_*)
function TFJ2.Degrade(x, y, w, h, c1, a1, c2, a2)
	local n = 32
	local hb = h / n
	for i = 0, n - 1 do
		local f = i / (n - 1)
		surface.SetDrawColor(Lerp(f, c1.r, c2.r), Lerp(f, c1.g, c2.g), Lerp(f, c1.b, c2.b), Lerp(f, a1, a2))
		local y0, y1 = math.floor(y + i * hb), math.floor(y + (i + 1) * hb)
		surface.DrawRect(x, y0, w, y1 - y0)
	end
end

-- couleur moyenne (ponderee par la saturation) des icones d'un arbre : sert aux clans et Kekkei Genkai
local tTFJ2CouleursIcones = {}
function TFJ2.CouleurIcones(sTree, tSkills)
	if tTFJ2CouleursIcones[sTree] ~= nil then return tTFJ2CouleursIcones[sTree] end
	local r, g, b, p = 0, 0, 0, 0
	for _, tS in ipairs(tSkills or {}) do
		local tFull = M_Fight.tIDs[tS.sID]
		local m = tFull and tFull.mImage
		if m and not m:IsError() and m.GetColor then
			local iW, iH = m:Width(), m:Height()
			for ix = 1, 9 do
				for iy = 1, 9 do
					local ok, c = pcall(m.GetColor, m, math.floor(iW * ix / 10), math.floor(iH * iy / 10))
					if ok and c and (c.a or 255) > 128 then
						local h, s, v = ColorToHSV(c)
						local f = s * s * v
						r, g, b, p = r + c.r * f, g + c.g * f, b + c.b * f, p + f
					end
				end
			end
		end
	end
	local tRes = false
	if p > 0.5 then
		local h, s = ColorToHSV(Color(r / p, g / p, b / p))
		-- shortcut: une moyenne trop terne (icones grises) retombe sur le rouge TFJ ; ajouter une couleur a la main si besoin
		if s > 0.2 then tRes = { HSVToColor(h, math.min(1, s * 1.2), 0.9), HSVToColor(h, math.min(1, s * 1.1), 0.35) } end
	end
	tTFJ2CouleursIcones[sTree] = tRes
	return tRes
end

-- colonnes a afficher pour une categorie (memes filtres que le jeu : KG et clan du joueur uniquement)
function TFJ2.Colonnes(tCategory, pLocal, sPlayerClan, tClan, VH)
	local tCols = {}
	for iConfig, tConfigTree in ipairs(tCategory.tTrees or {}) do
		if tCategory.bKekkei and tConfigTree.sID ~= pLocal:GetNetworkVar("sKekkei", "") then continue end
		if tCategory.bClan and tConfigTree.sID ~= sPlayerClan then continue end
		local tTree = M_Fight.tConfig.tBranch[tConfigTree.sID]
		if not tTree then continue end
		local sID = tConfigTree.sID
		local tCouleurs = tTFJ2Couleurs[sID] or TFJ2.CouleurIcones(sID, tTree.tSkills) or { TFJ_ROUGE_CLAIR, TFJ2_ROUGE_SOMBRE }
		local sNom = tTFJ2Noms[sID]
		if not sNom then
			if tCategory.bClan then
				sNom = "CLAN " .. string.upper((tClan and tClan.sName) or sID)
			else
				sNom = string.upper(sID)
			end
		end
		table.insert(tCols, { sID = sID, tConfigTree = tConfigTree, tTree = tTree, iOrdre = tTFJ2Ordre[sID] or (100 + iConfig),
			c1 = tCouleurs[1], c2 = tCouleurs[2], sNom = sNom, matIllu = TFJ_Mat("f4_" .. sID .. ".png") })
	end
	table.sort(tCols, function(a, b) return a.iOrdre < b.iOrdre end)
	-- largeur et pas des maquettes (1080p : 290 px / 355 px a 4 colonnes, 270 px / 305 px a 5)
	local n = #tCols
	local nW = (n >= 5) and VH * 25 or VH * 26.9
	local nPas = (n >= 5) and VH * 28.2 or VH * 32.9
	local nCentre = ScrW() / 2 + VH * ((n >= 5) and 14 or 10)
	for i, c in ipairs(tCols) do
		c.x = math.floor(nCentre - (n * nPas - (nPas - nW)) / 2 + (i - 1) * nPas)
		c.y, c.w, c.h = math.floor(VH * 16.2), math.floor(nW), math.floor(VH * 68.4)
		c.cx = c.x + c.w / 2
	end
	return tCols
end

function TFJ2.Fond(w, h, VH)
	surface.SetDrawColor(9, 9, 10, 250)
	surface.DrawRect(0, 0, w, h)
	TFJ2.Degrade(0, h * 0.55, w, h * 0.45, TFJ2_ROUGE_SOMBRE, 0, Color(120, 18, 18), 110)
end

function TFJ2.Colonne(c, bActive, VH)
	TFJ2.Degrade(c.x, c.y, c.w, c.h * 0.45, c.c1, 12, c.c1, 45)
	TFJ2.Degrade(c.x, c.y + c.h * 0.45, c.w, c.h * 0.55, c.c1, 45, c.c2, 95)
	surface.SetDrawColor(c.c1.r, c.c1.g, c.c1.b, bActive and 200 or 55)
	surface.DrawOutlinedRect(c.x, c.y, c.w, c.h, 1)
	if c.matIllu then
		-- illustration en bas de la colonne, proportions conservees
		local iW, iH = c.matIllu:Width(), c.matIllu:Height()
		local bW, bH = c.w + VH * 3, VH * 28.7
		local f = math.min(bW / iW, bH / iH)
		local dW, dH = iW * f, iH * f
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(c.matIllu)
		surface.DrawTexturedRect(c.cx - dW / 2, c.y + c.h - dH, dW, dH)
	end
end

function TFJ2.Nom(c, VH)
	local sFont = (#c.sNom > 10) and "TFJF4.NomLong" or "TFJF4.Nom"
	surface.SetFont(sFont)
	local tW = surface.GetTextSize(c.sNom)
	local y = c.y + c.h + VH * 3.4
	-- trace de pinceau : bande rouge sombre qui s'efface sur les cotes
	local bW, bH = tW + VH * 6, VH * 5.2
	for i = 0, 23 do
		local f = 1 - math.abs(i / 23 * 2 - 1)
		surface.SetDrawColor(TFJ2_ROUGE_SOMBRE.r, TFJ2_ROUGE_SOMBRE.g, TFJ2_ROUGE_SOMBRE.b, 230 * math.min(1, f * 2.2))
		local x0, x1 = math.floor(c.cx - bW / 2 + i * bW / 24), math.floor(c.cx - bW / 2 + (i + 1) * bW / 24)
		surface.DrawRect(x0, y - bH / 2 + VH * 0.4, x1 - x0, bH)
	end
	draw.SimpleText(c.sNom, sFont, c.cx, y, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function TFJ2.BasGauche(w, h, VH, iPoints)
	local matMascotte = TFJ_Mat("f4_mascotte.png")
	if matMascotte then
		local iW, iH = matMascotte:Width(), matMascotte:Height()
		local f = math.min(VH * 31 / iW, VH * 30 / iH)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(matMascotte)
		surface.DrawTexturedRect(VH * 15.5 - iW * f / 2, VH * 89.5 - iH * f, iW * f, iH * f)
	end
	local iNW = draw.SimpleText(iPoints, "TFJF4.Points", VH * 3.7, h - VH * 3, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
	draw.SimpleText("POINTS DE", "TFJF4.Label", VH * 4.7 + iNW, h - VH * 5.9, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
	draw.SimpleText("COMPÉTENCE", "TFJF4.Label", VH * 4.7 + iNW, h - VH * 3.2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
end
--[[local tButtons = {
	{
		sID = "jutsus",
		sText = "Jutsu",
		fFunc = function()
			M_Fight:SkillTree("jutsus")
		end
	},
	{
		sID = "taijutsus",
		sText = "Taijutsu",
		fFunc = function()
			M_Fight:SkillTree("taijutsus")
		end
	},
	{
		sID = "style",
		sText = "Styles de Combat",
		fFunc = function()
			M_Fight:SkillTree("style")
		end
	},
	{
		sID = "clans",
		sText = "Clan Jutsus",
		fFunc = function()
			M_Fight:SkillTree( "clans")
		end
	},
}]]
local function Header(vFrame, nActualID)
	local pLocal = LocalPlayer()
	local VH = ScrH() / 100
	local nGap = VH * 4
	surface.SetFont("NRP::Poppins::2D::4::500")
	vFrame:SetDraggable(false)
	vFrame.Think = function(self)
		if input.IsKeyDown(KEY_ESCAPE) and self:HasHierarchicalFocus() and not self.bClosing then
			vFrame:AlphaTo(0, 0.3, 0, function() vFrame:Remove() end)
			self.bClosing = true
		end
	end

	Solve.Naruto.FocusedFrame = vFrame
	TFJ2.Polices()
	local vButtons = vgui.Create("DPanel", vFrame)
	vButtons:SetSize(1, VH * 12)
	vButtons:CenterHorizontal()
	vButtons:SetY(VH * 2)
	vButtons:SetPaintBackground(false)
	local nEcart = VH * 3.5
	local matLogo = TFJ_Mat("f4_logo.png")
	local tCats = {}
	for i, tCategory in ipairs(M_Fight.tConfig.tCategories) do
		if isfunction(tCategory.fnCheck) then if not tCategory.fnCheck(pLocal) then continue end end
		table.insert(tCats, i)
	end

	local iCumulW = 0
	for i, nID in ipairs(tCats) do
		local tCategory = M_Fight.tConfig.tCategories[nID]
		if not tCategory then continue end
		local tSkillCat = M_Fight.tConfig.tSkillsCategories[nID]
		if not tSkillCat then continue end
		-- TFJ v2 : onglet en capitales, sans icone, souligne en rouge quand il est actif
		local sNomOnglet = string.upper(tCategory.sName)
		surface.SetFont("TFJF4.Onglet")
		local nW, nTH = surface.GetTextSize(sNomOnglet)
		local pButton = vgui.Create("DButton", vButtons)
		pButton:SetWide(nW)
		pButton:Dock(LEFT)
		if i ~= #tCats then pButton:DockMargin(0, 0, nEcart, 0) end
		pButton:SetText("")
		pButton.Paint = function(self, w, h)
			self.iHoverLerp = Lerp(FrameTime() * 5, self.iHoverLerp or 0, (self:IsHovered() or nActualID == nID) and 1 or 0)
			local iC = 138 + 117 * self.iHoverLerp
			draw.SimpleText(sNomOnglet, "TFJF4.Onglet", w / 2, h / 2, Color(iC, iC, iC + 8 * (1 - self.iHoverLerp)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			if nActualID == nID then
				surface.SetDrawColor(TFJ_ROUGE)
				surface.DrawRect(0, h / 2 + nTH / 2 + VH * 0.4, w, 2)
			end
			-- if i != #tCats then
			--     surface.SetDrawColor(255, 255, 255, 100)
			--     surface.DrawRect(w - 2, h/2 - h*0.6/2, 2, h*0.6)
			-- end
		end

		pButton.DoClick = function()
			nActualID = nID
			M_Fight:SkillTree(nID)
			vFrame:Remove()
			surface.PlaySound("solve_naruto_base/ui/bruitage_switch_jutsu.wav")
		end

		iCumulW = iCumulW + nW + ((i ~= #tCats) and nEcart or 0)
		-- logo du serveur entre le 2e et le 3e onglet
		if i == 2 and #tCats > 2 and matLogo then
			local nLogoW = VH * 12 * matLogo:Width() / math.max(1, matLogo:Height())
			local vLogo = vgui.Create("DPanel", vButtons)
			vLogo:SetWide(nLogoW)
			vLogo:Dock(LEFT)
			vLogo:DockMargin(0, 0, nEcart, 0)
			vLogo:SetMouseInputEnabled(false)
			vLogo.Paint = function(self, w, h)
				surface.SetDrawColor(255, 255, 255, 255)
				surface.SetMaterial(matLogo)
				surface.DrawTexturedRect(0, 0, w, h)
			end
			iCumulW = iCumulW + nLogoW + nEcart
		end
	end

	vButtons:SetWide(iCumulW)
	vButtons:CenterHorizontal()
end

local tMats = {
	["base"] = Material("materials/solve_nrp/nrp_interface/tree/base.png", "smooth"),
	["circle"] = Material("materials/solve_nrp/nrp_interface/skills/rond_jutsu.png", "smooth"),
	["white_trait"] = Material("materials/solve_nrp/nrp_interface/tree/white_trait.png", "smooth"),
	["icon_exit"] = Material("materials/solve_nrp/nrp_interface/skills/icon_exit.png", "smooth"),
	["background_nature01"] = Material("materials/solve_nrp/nrp_interface/tree/background_nature01.png", "smooth"),
	["background_nature02"] = Material("materials/solve_nrp/nrp_interface/tree/background_nature02.png", "smooth"),
}

local matBasket = Solve:GetMaterial("chariot_chariot")
local matBaseSecondNatureFriendly = Material("solve_naruto_base/f4menu/f4_base_can_reroll.png", "smooth")
function M_Fight:CreateViewCharacter(vFrame, bPlayIntro)
	SafeRemovePanel(self.vCharacterPanel)
	local pLocal = LocalPlayer()
--[[ ... ]]
	local vecCharacterPos, angCharacterAng = Vector(0, 0, -2), Angle(0, 45, 0)
	local vModelPanelBg = vgui.Create("DPanel", vFrame)
	self.vCharacterPanel = vModelPanelBg
	vModelPanelBg:SetPaintBackground(false)
	local vModelPanel = vgui.Create("DModelPanel", vModelPanelBg)
	vModelPanelBg.ModelPanel = vModelPanel
	vModelPanel:Dock(FILL)
	vModelPanel:SetFOV(30)
	vModelPanel:SetModel(pLocal:GetModel())
	vModelPanel.Entity:SetSkin(pLocal:GetSkin())
	vModelPanel:SetColor(pLocal:GetPlayerColor():ToColor())
	local eHead, fnThink, eMask, fnOnRemove = Solve:BuildPlayerModel(pLocal, vModelPanel.Entity, nil, nil, true)
	vModelPanel.Entity:SetAngles(Angle(0, 45, 0))
	vModelPanel._idleApplied = false

	if bPlayIntro then
		vModelPanel._idleApplied = true
		if Solve and Solve.PlayPoseAnimation then
			Solve:PlayPoseAnimation(vModelPanel, vModelPanel.Entity)
		else
			local ent = vModelPanel.Entity
			if IsValid(ent) then
				local seq = ent:LookupSequence("act_bras_croise_idle")
				if not seq or seq < 0 then
					seq = ent:LookupSequence("nrp_base_idle_loop")
					if not seq or seq < 0 then
						seq = ent:LookupSequence("idle_all")
					end
				end
				if seq and seq >= 0 then
					ent:ResetSequence(seq)
					ent:SetCycle(0)
				end
			end
		end
	end

	vModelPanel.Think = function(self)
		if pLocal:GetModel() ~= self.Entity:GetModel() then
			self:SetModel(pLocal:GetModel())
			self.Entity:SetSkin(pLocal:GetSkin())
			self.Entity:SetAngles(Angle(0, 45, 0))
			self._idleApplied = false

			if fnOnRemove then
				fnOnRemove()
			end

			eHead, fnThink, eMask, fnOnRemove = Solve:BuildPlayerModel(pLocal, self.Entity, nil, nil, true)
		end

		if not self._idleApplied and IsValid(self.Entity) then
			local seq = self.Entity:LookupSequence("act_bras_croise_idle")
			if not seq or seq <= 0 then
				seq = self.Entity:LookupSequence("nrp_base_idle_loop") or self.Entity:LookupSequence("idle_all")
			end
			if seq and seq > 0 then
				self.Entity:ResetSequence(seq)
				self.Entity:SetCycle(0)
				self._idleApplied = true
			end
		end

		if IsValid(self.Entity) then
			local ent = self.Entity
			local mx, my = gui.MousePos()
			local cx, cy = self:LocalToScreen(self:GetWide() / 2, self:GetTall() / 2)
			local dx = math.Clamp((mx - cx) / math.max(self:GetWide() * 0.25, 1), -1, 1)
			local dy = math.Clamp((my - cy) / math.max(self:GetTall() * 0.25, 1), -1, 1)

			ent:SetAngles(Angle(0, 45, 0))

			self._headYaw = Lerp(FrameTime() * 10, self._headYaw or 0, dx * 10)
			self._headPitch = Lerp(FrameTime() * 10, self._headPitch or 0, dy * 6)

			if not self._poseChecked then
				local function lookup(names)
					for _, n in ipairs(names) do
						local idx = ent:LookupPoseParameter(n)
						if idx and idx >= 0 then return n, idx end
					end
				end
				self._ppHeadYawName = (lookup({"head_yaw", "aim_yaw"})) and select(1, lookup({"head_yaw", "aim_yaw"})) or nil
				self._ppHeadPitchName = (lookup({"head_pitch", "aim_pitch"})) and select(1, lookup({"head_pitch", "aim_pitch"})) or nil
				self._poseChecked = true
			end

			local function setParam(name, value)
				if not name then return false end
				local idx = ent:LookupPoseParameter(name)
				if not idx or idx < 0 then return false end
				local min, max = ent:GetPoseParameterRange(idx)
				ent:SetPoseParameter(name, math.Clamp(value, min, max))
				return true
			end

			if self._headBone == nil then
				self._headBone = ent:LookupBone("ValveBiped.Bip01_Head")
			end

			local usedPose = false
			if setParam(self._ppHeadYawName, self._headYaw) then usedPose = true end
			if setParam(self._ppHeadPitchName, self._headPitch) then usedPose = true end

			if usedPose then
				if self._headBone then ent:ManipulateBoneAngles(self._headBone, Angle(0, 0, 0)) end
			else
				if self._headBone then
					ent:ManipulateBoneAngles(self._headBone, Angle(self._headPitch, self._headYaw, 0))
				end
			end

			if self._headBone or usedPose then
				ent:InvalidateBoneCache()
			end
		end

		self:SetCursor("hand")
	end

	vModelPanel.OnRemove = function(self)
		if fnOnRemove then
			fnOnRemove()
		end
		SafeRemoveEntity(self.Entity)
	end

	vModelPanel.PreDrawModel = function(s) if vFrame:GetAlpha() ~= 255 then return false end end
	vModelPanel.PostDrawModel = function(self) if isfunction(fnThink) then fnThink() end end
	vModelPanel.LayoutEntity = function(self, eEntity)
		eEntity:SetPos(vecCharacterPos)
		-- self:SetCursor("blank")
		self:RunAnimation()
	end
	return vModelPanelBg
end

local matBasket = Solve:GetMaterial("chariot_chariot")
local matBaseSecondNatureFriendly = Material("solve_naruto_base/f4menu/f4_base_can_reroll.png", "smooth")
function M_Fight:SkillTree(nID)
	local pLocal = LocalPlayer()
	local VH = ScrH() / 100
	local bReload = false
	if IsValid(vFrame) then
		vFrame:Remove()
		bReload = true
	end

	if not bReload then
		M_Fight._introPlayedKenjutsuThisOpen = false
	end

	if Solve.Naruto.MenuSounds and not bReload then
		Solve.Naruto.MenuSounds:PlaySkillTreeSound()
	end

	nID = nID or 1
	local tIDs = {}
	vFrame = vgui.Create("DFrame")
	vFrame:SetSize(ScrW(), ScrH())
	vFrame:Center()
	vFrame:MakePopup()
	vFrame:ShowCloseButton(false)
	vFrame:SetDraggable(false)
	vFrame:SetTitle("")
	if not bReload then
		vFrame:SetAlpha(0)
		vFrame:AlphaTo(255, 0.3, 0)
	end

	local tCategory = M_Fight.tConfig.tCategories[nID]
	if not tCategory then return end
	local sKekkei = pLocal:GetNetworkVar("sKekkei", "")
	local tKekkei
	if tCategory.bKekkei then
		for _, _tKekkei in ipairs(tCategory.tTrees) do
			if _tKekkei.sID == sKekkei then
				tKekkei = _tKekkei
				break
			end
		end
	end

	local tClan
	local sPlayerClan = pLocal:GetClan()
	if tCategory.bClan then tClan = Solve.Naruto.Clan:GetClan(sPlayerClan) end
	TFJ2.Polices()
	local tTFJCols = TFJ2.Colonnes(tCategory, pLocal, sPlayerClan, tClan, VH)
	local tTFJColParID = {}
	for _, c in ipairs(tTFJCols) do tTFJColParID[c.sID] = c end
	M_vSkillTree = vFrame
	local vFirst, vSecond

	-- Element picker with colored nature cards and icons
	local tNatureColors = {
		["suiton"] = Color(0, 150, 255),
		["futon"] = Color(130, 210, 130),
		["raiton"] = Color(255, 255, 100),
		["doton"] = Color(160, 110, 60),
		["katon"] = Color(255, 100, 0),
	}

	local function fOpenNaturePicker(iSlot)
		local sSlotLabel = iSlot == 1 and "Première nature" or "Deuxième nature"
		local tNatures = M_Fight.tConfig.tNatures
		local iCount = #tNatures

		local iCardW = VH * 16
		local iCardH = VH * 22
		local iSpacing = VH * 2
		local iTotalW = iCount * iCardW + (iCount - 1) * iSpacing + VH * 8
		local iTotalH = iCardH + VH * 18

		local vPickerFrame = vgui.Create("DFrame")
		vPickerFrame:SetSize(iTotalW, iTotalH)
		vPickerFrame:Center()
		vPickerFrame:MakePopup()
		vPickerFrame:ShowCloseButton(false)
		vPickerFrame:SetDraggable(true)
		vPickerFrame:SetTitle("")
		vPickerFrame:SetAlpha(0)
		vPickerFrame.Paint = function(self, w, h)
			NRP:DrawBlur(self, 4)
			NRP:RoundedBox(VH * 1, 0, 0, w, h, Color(15, 15, 25, 240))
			NRP:RoundedBox(VH * 1, 0, 0, w, VH * 7, Color(30, 30, 50, 255))
			draw.SimpleText("Choisissez votre" .. sSlotLabel, "NRP::Poppins::2D::3::1000", w / 2, VH * 3.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		vPickerFrame:AlphaTo(255, 0.3, 0)

		local vClose = vgui.Create("DButton", vPickerFrame)
		vClose:SetSize(VH * 4, VH * 4)
		vClose:SetPos(iTotalW - VH * 5, VH * 1.5)
		vClose:SetText("")
		vClose.Paint = function(self, w, h)
			surface.SetDrawColor(255, 255, 255, self:IsHovered() and 255 or 180)
			surface.SetMaterial(tMats["icon_exit"])
			surface.DrawTexturedRect(0, 0, w, h)
		end
		vClose.DoClick = function() vPickerFrame:AlphaTo(0, 0.3, 0, function() vPickerFrame:Remove() end) end

		local iStartX = VH * 4
		local iStartY = VH * 9
		for i, tNature in ipairs(tNatures) do
			local cNature = tNatureColors[tNature.sID] or Color(200, 200, 200)
			local vCard = vgui.Create("DButton", vPickerFrame)
			vCard:SetPos(iStartX + (i - 1) * (iCardW + iSpacing), iStartY)
			vCard:SetSize(iCardW, iCardH)
			vCard:SetText("")

			vCard.fHoverLerp = 0
			vCard.Paint = function(self, w, h)
				self.fHoverLerp = Lerp(FrameTime() * 10, self.fHoverLerp, self:IsHovered() and 1 or 0)
				local fAlpha = 80 + 120 * self.fHoverLerp
				local cBg = Color(cNature.r * 0.3, cNature.g * 0.3, cNature.b * 0.3, fAlpha)
				NRP:RoundedBox(VH * 1, 0, 0, w, h, cBg)

				-- Border glow on hover
				if self.fHoverLerp > 0.01 then
					local cBorder = Color(cNature.r, cNature.g, cNature.b, 180 * self.fHoverLerp)
					NRP:RoundedBox(VH * 1, 1, 1, w - 2, h - 2, cBorder)
					NRP:RoundedBox(VH * 0.8, 3, 3, w - 6, h - 6, cBg)
				end

				-- Nature icon
				if tNature.mMat then
					local iIconSize = VH * 10
					surface.SetDrawColor(255, 255, 255, 200 + 55 * self.fHoverLerp)
					surface.SetMaterial(tNature.mMat)
					surface.DrawTexturedRect((w - iIconSize) / 2, VH * 2, iIconSize, iIconSize)
				end

				-- Name
				draw.SimpleText(tNature.sName, "NRP::Poppins::2D::3::1000", w / 2, h - VH * 4, cNature, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end

			vCard.DoClick = function()
				net.Start("Solve.Naruto.Nature:Choose")
				net.WriteUInt(iSlot, 2)
				net.WriteString(tNature.sID)
				net.SendToServer()
				surface.PlaySound("solve_naruto_base/ui/menu_selection_v2.wav")
				vPickerFrame:AlphaTo(0, 0.3, 0, function() vPickerFrame:Remove() end)
			end
		end
	end

	-- Button to choose/reroll FIRST nature (Genin+)
	local function fFirstNatureButton()
		if IsValid(vFirst) then return end
		local sFirstNature = pLocal:GetNetworkVar("sFirstNature", "")
		local sSecondNature = pLocal:GetNetworkVar("sSecondNature", "")
		local bHasFirst = (sFirstNature ~= "")
		local bHasBoth = (bHasFirst and sSecondNature ~= "")
		vFirst = vgui.Create("DButton", vFrame)
		vFirst:SetSize(VH * 40, VH * 6)
		-- TFJ v2 : en bas a droite, hors des colonnes
		vFirst:SetPos(ScrW() - VH * 48, VH * 2.5)
		vFirst:SetText("")
		vFirst.Paint = function(self, w, h)
			local sText
			if not bHasFirst then
				sText = "Choisissez votre Première nature !"
			elseif bHasBoth then
				sText = "Relancez votre élément"
			else
				sText = "Acheter et relancer"
			end
			TFJ_CadreArbre(0, 0, w, h, Color(8, 8, 10, self:IsHovered() and 240 or 200))
			surface.SetDrawColor(TFJ_ROUGE)
			surface.DrawRect(w * 0.2, h - 2, w * 0.6, 2)
			draw.SimpleText(sText, "NRP::Poppins::2D::3::1000", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		vFirst.DoClick = function()
			if bHasFirst then
				-- Go to shop reroll page
				Solve.Naruto.Boutique:DrawShop()
				Solve.Naruto.Boutique:SetPage("chests_reroll")
			else
				-- First-time: open element picker
				fOpenNaturePicker(1)
			end
		end
	end

	-- Button to choose/reroll SECOND nature (Confirmed Chunin+)
	local function fSecondNatureButton()
		if IsValid(vSecond) then return end
		local sSecondNature = pLocal:GetNetworkVar("sSecondNature", "")
		local bHasSecond = (sSecondNature ~= "")
		vSecond = vgui.Create("DButton", vFrame)
		vSecond:SetSize(VH * 40, VH * 6)
		vSecond:SetPos(ScrW() - VH * 48, VH * 9)
		vSecond:SetText("")
		vSecond.Paint = function(self, w, h)
			local sText = bHasSecond and "Relancez votre élément" or "Choisissez votre seconde nature !"
			TFJ_CadreArbre(0, 0, w, h, Color(8, 8, 10, self:IsHovered() and 240 or 200))
			surface.SetDrawColor(TFJ_ROUGE)
			surface.DrawRect(w * 0.2, h - 2, w * 0.6, 2)
			draw.SimpleText(sText, "NRP::Poppins::2D::3::1000", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		vSecond.DoClick = function()
			if bHasSecond then
				-- Go to shop reroll page
				Solve.Naruto.Boutique:DrawShop()
				Solve.Naruto.Boutique:SetPage("chests_reroll")
			else
				-- First-time: open element picker
				fOpenNaturePicker(2)
			end
		end
	end

	vFrame.Paint = function(self, w, h)
		surface.SetDrawColor(255, 255, 255, 255)
		local matFondSolve
		if tKekkei then
			matFondSolve = tKekkei.matBackground
		else
			local bShowFirst = pLocal:IsNinjaRank(Solve.Naruto.Config["sMinRankToPickFirstNature"] or "genin") and (nID == 1)
			local bShowSecond = pLocal:IsNinjaRank(Solve.Naruto.Config["sMinRankToPickSecondNature"] or "confirmed_chunin") and (nID == 1)

			if bShowFirst or bShowSecond then
				matFondSolve = matBaseSecondNatureFriendly
				if bShowFirst then fFirstNatureButton() end
				if bShowSecond then fSecondNatureButton() end
			else
				matFondSolve = tCategory.mBackground
				if IsValid(vFirst) then vFirst:Remove() end
				if IsValid(vSecond) then vSecond:Remove() end
			end
		end

		-- TFJ v2 : fond sombre, une colonne par arbre (degrade + illustration). Les liens sont dessines par-dessus.
		-- Retire : calques Solve, logo de clan, textes "Reset points de compétence" / "Achetez une réinitialisation de relance".
		TFJ2.Fond(w, h, VH)
		local nMX, nMY = self:CursorPos()
		for _, c in ipairs(tTFJCols) do
			local bSurvol = nMX >= c.x and nMX <= c.x + c.w and nMY >= c.y and nMY <= c.y + c.h
			TFJ2.Colonne(c, bSurvol or (vSelect and vSelect.sParent == c.sID), VH)
		end

		for _, tConfigTree in pairs(tCategory.tTrees) do
			if tCategory.bKekkei then if tConfigTree.sID ~= pLocal:GetNetworkVar("sKekkei", "") then continue end end
			if tCategory.bClan then if tConfigTree.sID ~= sPlayerClan then continue end end
			local tTree = M_Fight.tConfig.tBranch[tConfigTree.sID]
			if not tTree then continue end
			local nPosX, nPosY = tConfigTree.fPos(VH)
			local bHasNature = true
			if isfunction(tTree.fCheck) then bHasNature = tTree.fCheck(pLocal) end
			local iOldAlpha = surface.GetAlphaMultiplier()
			if not bHasNature then surface.SetAlphaMultiplier(0.4) end
			for _, tSkill in ipairs(M_Fight.tConfig.tBranch[tConfigTree.sID].tSkills) do
				if not tIDs[tSkill.sID] then continue end
				local nPosX, nPosY = tIDs[tSkill.sID]:GetPos()
				local nSizeX, nSizeY = tIDs[tSkill.sID]:GetSize()
				local tSkill = M_Fight.tIDs[tSkill.sID]
				if not tSkill then continue end
				local bUnlockedSkill = pLocal:HasSkill(tSkill.sID)
				-- Un skill sans tParents est une racine de l'arbre, pas une erreur.
				local tLiens = (self.tTFJLiens and self.tTFJLiens[tSkill.sID]) or tSkill.tParents or {}
				for _, sParent in ipairs(tLiens) do
					if not tIDs[sParent] then continue end
					local nParentX, nParentY = tIDs[sParent]:GetPos()
					surface.SetDrawColor(255, 255, 255, (bUnlockedSkill and pLocal:HasSkill(sParent)) and 220 or 70)
					surface.SetMaterial(tMats["white_trait"])
					local iSizeH = Vector(nPosX + nSizeX / 2, nPosY + nSizeY / 2):Distance(Vector(nParentX + nSizeX / 2, nParentY + nSizeY / 2))
					local iAngle = math.atan2(nParentX - nPosX, nParentY - nPosY) * 180 / math.pi
					local iRad = math.rad(iAngle)
					local iXMinus = math.sin(iRad) * iSizeH / 2
					local iYMinus = math.cos(iRad) * iSizeH / 2
					surface.DrawTexturedRectRotated(nPosX + nSizeX / 2 + iXMinus, nPosY + nSizeY / 2 + iYMinus, 7, iSizeH, iAngle)
					-- surface.SetDrawColor(2, 2, 2)
					-- surface.DrawLine(nPosX + nSizeX/2, nPosY + nSizeY/2, nParentX + nSizeX/2, nParentY + nSizeY/2) // TODO : Reactive
				end
			end

			surface.SetAlphaMultiplier(iOldAlpha)
		end

		for _, c in ipairs(tTFJCols) do TFJ2.Nom(c, VH) end
		TFJ2.BasGauche(w, h, VH, pLocal:GetNetworkVar("nSkillPoint", 0))
	end

	local mat = Material("solve_naruto_base/tai_bottom.vmt")
	vFrame.PaintOver = function(s, w, h)
		if IsValid(s._combatStylePanel) then
			s._combatStylePanel:PaintManual()
		end
		if IsValid(s._stancePanel) then
			s._stancePanel:PaintManual()
		end
	end

	vFrame.OnKeyCodePressed = function(self, nKey) if nKey == Solve:GetSetting("skill_tree_key") then
		if Solve.Naruto.MenuSounds then
			Solve.Naruto.MenuSounds:StopAllMenuSounds()
		end
		vFrame:AlphaTo(0, 0.3, 0, function() vFrame:Remove() end)
	end end
	local vClose = vgui.Create("DButton", vFrame)
	vClose:SetSize(28, 28)
	vClose:SetPos(vFrame:GetWide() - vClose:GetWide() - VH * 3, VH * 3)
	vClose:SetText("")
	vClose.Paint = function(self, w, h)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(tMats["icon_exit"])
		surface.DrawTexturedRect(0, 0, w, h)
	end

	vClose.DoClick = function() vFrame:AlphaTo(0, 0.3, 0, function() vFrame:Remove() if Solve.Naruto.MenuSounds then Solve.Naruto.MenuSounds:StopAllMenuSounds() end end) end

	-- Avoid multiple recreations of the fakeplayer during tree iteration
	local bCharacterCreated = false
	for iTreeId, tConfigTree in ipairs(M_Fight.tConfig.tCategories[nID].tTrees) do
		if tCategory.bKekkei then if tConfigTree.sID ~= pLocal:GetNetworkVar("sKekkei", "") then continue end end
		if tCategory.bClan then if tConfigTree.sID ~= sPlayerClan then continue end end

		if tCategory.bShowCharacter and not bCharacterCreated then
			SafeRemovePanel(M_Fight.vCharacterPanel)
			local bPlayIntroNow = (nID == 2) and (not M_Fight._introPlayedKenjutsuThisOpen)
			local mdl = M_Fight:CreateViewCharacter(vFrame, bPlayIntroNow)
			if bPlayIntroNow then
				M_Fight._introPlayedKenjutsuThisOpen = true
			end
			mdl:SetSize(ScrW() * .2625, ScrH() * .85)
			mdl:Center()
			mdl:AlignBottom(-32)
			bCharacterCreated = true
			mdl:SetVisible(false)

			local VH = ScrH() / 100
			local pLocal = LocalPlayer()

			local vCombatStylePanel = vgui.Create("DPanel", vFrame)
			local panelW, panelH = math.floor(mdl:GetWide() * 0.35), math.floor(VH * 3)
			vCombatStylePanel:SetSize(panelW, panelH)
			-- TFJ v2 : selecteurs en bas a droite (le personnage 3D est masque, il couvrait les colonnes)
			vCombatStylePanel:SetPos(ScrW() - VH * 3 - panelW, VH * 88)
			vCombatStylePanel:SetPaintedManually(true)
			local matStanceBorder = select(1, Solve:GetMaterial("stance_border"))
			local matArrowLeft = select(1, Solve:GetMaterial("stance_left_arrow"))
			local matArrowRight = select(1, Solve:GetMaterial("stance_right_arrow"))
			vCombatStylePanel.Paint = function(self, w, h)
				if matStanceBorder then
					surface.SetDrawColor(255, 255, 255, 255)
					surface.SetMaterial(matStanceBorder)
					surface.DrawTexturedRect(0, 0, w, h)
				end
				local old = DisableClipping(true)
				draw.SimpleText("Posture de combat :", "NRP::Poppins::2D::2::500", w / 2, -VH * 2, Color(255, 255, 255, 66), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
				DisableClipping(old)
			end
			vFrame._combatStylePanel = vCombatStylePanel

			local vCombatLeft = vgui.Create("DButton", vCombatStylePanel)
			vCombatLeft:SetText("")
			vCombatLeft:SetSize(VH * 3, panelH - VH)
			vCombatLeft:SetPos(VH * - 0.3, VH *0.5)
			vCombatLeft.Paint = function(self, w, h)
				if matArrowLeft then
					surface.SetDrawColor(255, 255, 255, self:IsHovered() and 255 or 180)
					surface.SetMaterial(matArrowLeft)
					local size = math.min(w, h) * 0.6
					surface.DrawTexturedRect((w - size) / 2, (h - size) / 2, size, size)
				end
			end

			local vCombatRight = vgui.Create("DButton", vCombatStylePanel)
			vCombatRight:SetText("")
			vCombatRight:SetSize(VH * 3, panelH - VH)
			vCombatRight:SetPos(panelW - VH * - 0.3 - vCombatRight:GetWide(), VH *0.5)
			vCombatRight.Paint = function(self, w, h)
				if matArrowRight then
					surface.SetDrawColor(255, 255, 255, self:IsHovered() and 255 or 180)
					surface.SetMaterial(matArrowRight)
					local size = math.min(w, h) * 0.6
					surface.DrawTexturedRect((w - size) / 2, (h - size) / 2, size, size)
				end
			end

			local vCombatLabel = vgui.Create("DLabel", vCombatStylePanel)
			vCombatLabel:SetSize(panelW - (vCombatLeft:GetWide() + vCombatRight:GetWide() - VH * 5), panelH - VH)
			vCombatLabel:SetPos(VH * -2.5 + vCombatLeft:GetWide(), VH * 0.6)
			vCombatLabel:SetFont(Solve:Font(0.018, 4))
			vCombatLabel:SetTextColor(color_white)
			vCombatLabel:SetContentAlignment(5)

			local function getCombatStyleName(iStyleId)
				local tLabels = Solve.Naruto.Combat.Config["tStyleLabels"]
				if not tLabels then return "Style " .. tostring(iStyleId) end
				local tStyle = tLabels[iStyleId]
				if tStyle and tStyle.sName then
					return tStyle.sName
				end
				return "Style " .. tostring(iStyleId)
			end

			local function refreshCombatLabel()
				local iStyleId
				iStyleId = pLocal:GetNWInt("CombatStyleOverride", -1)
				if not iStyleId or iStyleId == -1 then
					local charId = (pLocal.GetCharacterGlobalId and pLocal:GetCharacterGlobalId()) or 0
					if charId and charId ~= 0 then
						local path = ("solve_naruto/combat_style/%s.json"):format(tostring(charId))
						if file.Exists(path, "DATA") then
							local t = util.JSONToTable(file.Read(path, "DATA") or "")
							local saved = tonumber(t and (t.iStyle or t.style))
							if saved and saved >= -1 then iStyleId = saved end
						end
					end
				end
				if not iStyleId then iStyleId = -1 end
				vCombatLabel:SetText(string.upper(getCombatStyleName(iStyleId)))
			end

			local function setCombatStyle(iStyleId)
				local charId = (pLocal.GetCharacterGlobalId and pLocal:GetCharacterGlobalId()) or 0
				if charId and charId ~= 0 then
					file.CreateDir("solve_naruto/combat_style")
					file.Write(("solve_naruto/combat_style/%s.json"):format(tostring(charId)), util.TableToJSON({ iStyle = iStyleId }, false))
				end
				vCombatLabel:SetText(string.upper(getCombatStyleName(iStyleId)))

				net.Start("Solve.Naruto.Combat:SetStyleOverride")
				net.WriteInt(iStyleId, 8)
				net.SendToServer()
				timer.Simple(0.05, refreshCombatLabel)
			end

			vCombatLeft.DoClick = function()
				local tOrder = Solve.Naruto.Combat.Config["tStyleSelectionOrder"]
				if not tOrder then return end

				local iCurrent = pLocal:GetNWInt("CombatStyleOverride", -1)
				local iCurrentIndex = 1

				for i, iStyleId in ipairs(tOrder) do
					if iStyleId == iCurrent then
						iCurrentIndex = i
						break
					end
				end

				iCurrentIndex = iCurrentIndex - 1
				if iCurrentIndex < 1 then iCurrentIndex = #tOrder end

				setCombatStyle(tOrder[iCurrentIndex])
				LocalPlayer():EmitSound("solve/combat/take.mp3")
				surface.PlaySound("solve_naruto_base/ui/bruitage_switch_jutsu.wav")
			end

			vCombatRight.DoClick = function()
				local tOrder = Solve.Naruto.Combat.Config["tStyleSelectionOrder"]
				if not tOrder then return end

				local iCurrent = pLocal:GetNWInt("CombatStyleOverride", -1)
				local iCurrentIndex = 1

				for i, iStyleId in ipairs(tOrder) do
					if iStyleId == iCurrent then
						iCurrentIndex = i
						break
					end
				end

				iCurrentIndex = iCurrentIndex + 1
				if iCurrentIndex > #tOrder then iCurrentIndex = 1 end

				setCombatStyle(tOrder[iCurrentIndex])
				LocalPlayer():EmitSound("solve/combat/take.mp3")
				surface.PlaySound("solve_naruto_base/ui/bruitage_switch_jutsu.wav")
			end

			refreshCombatLabel()

			vCombatStylePanel.Think = function()
				if not IsValid(vCombatStylePanel) then return end
				refreshCombatLabel()
			end

			local function getSword()
				local sword = pLocal:GetSword()
				if not IsValid(sword) then
					local w = pLocal:GetWeapon("naruto_katana_swep")
					if IsValid(w) then sword = w end
				end
				return sword
			end

			local function getStancesSource()
				local sword = getSword()
				if IsValid(sword) and sword.Stances then return sword.Stances end
				local swep = weapons.GetStored and weapons.GetStored("naruto_katana_swep") or nil
				return (swep and swep.Stances) or {}
			end

			local function getStanceName(idx)
				local stances = getStancesSource()
				local t = stances[idx]
				return (t and t.Name) or ("Posture " .. tostring(idx))
			end

			local vStancePanel = vgui.Create("DPanel", vFrame)
			local panelW, panelH = math.floor(mdl:GetWide() * 0.35), math.floor(VH * 3)
			vStancePanel:SetSize(panelW, panelH)
			vStancePanel:SetPos(ScrW() - VH * 3 - panelW, VH * 94)
			vStancePanel:SetPaintedManually(true)
			local matStanceBorder = select(1, Solve:GetMaterial("stance_border"))
			local matArrowLeft = select(1, Solve:GetMaterial("stance_left_arrow"))
			local matArrowRight = select(1, Solve:GetMaterial("stance_right_arrow"))
			vStancePanel.Paint = function(self, w, h)
				if matStanceBorder then
					surface.SetDrawColor(255, 255, 255, 255)
					surface.SetMaterial(matStanceBorder)
					surface.DrawTexturedRect(0, 0, w, h)
				end
				local old = DisableClipping(true)
				draw.SimpleText("Posture de l'épée :", "NRP::Poppins::2D::2::500", w / 2, -VH * 2, Color(255, 255, 255, 66), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
				DisableClipping(old)
			end
			vFrame._stancePanel = vStancePanel

			local vLeft = vgui.Create("DButton", vStancePanel)
			vLeft:SetText("")
			vLeft:SetSize(VH * 3, panelH - VH)
			vLeft:SetPos(VH * - 0.3, VH *0.5)
			vLeft.Paint = function(self, w, h)
				if matArrowLeft then
					surface.SetDrawColor(255, 255, 255, self:IsHovered() and 255 or 180)
					surface.SetMaterial(matArrowLeft)
					local size = math.min(w, h) * 0.6
					surface.DrawTexturedRect((w - size) / 2, (h - size) / 2, size, size)
				end
			end

			local vRight = vgui.Create("DButton", vStancePanel)
			vRight:SetText("")
			vRight:SetSize(VH * 3, panelH - VH)
			vRight:SetPos(panelW - VH * - 0.3 - vRight:GetWide(), VH *0.5)
			vRight.Paint = function(self, w, h)
				if matArrowRight then
					surface.SetDrawColor(255, 255, 255, self:IsHovered() and 255 or 180)
					surface.SetMaterial(matArrowRight)
					local size = math.min(w, h) * 0.6
					surface.DrawTexturedRect((w - size) / 2, (h - size) / 2, size, size)
				end
			end

			local vLabel = vgui.Create("DLabel", vStancePanel)
			vLabel:SetSize(panelW - (vLeft:GetWide() + vRight:GetWide() - VH * 5), panelH - VH)
			vLabel:SetPos(VH * -2.5 + vLeft:GetWide(), VH * 0.6)
			vLabel:SetFont(Solve:Font(0.018, 4))
			vLabel:SetTextColor(color_white)
			vLabel:SetContentAlignment(5)

			local function refreshLabel()
				local idx
				idx = LocalPlayer():GetNetworkVar("iKenStance")
				if not idx then
					local pLocal = LocalPlayer()
					local charId = (pLocal.GetCharacterGlobalId and pLocal:GetCharacterGlobalId()) or 0
					if charId and charId ~= 0 then
						local path = ("solve_naruto/ken_stance/%s.json"):format(tostring(charId))
						if file.Exists(path, "DATA") then
							local t = util.JSONToTable(file.Read(path, "DATA") or "")
							local saved = tonumber(t and (t.iStance or t.stance))
							if saved and saved >= 1 then idx = saved end
						end
					end
				end
				if not idx then
					local sword = getSword()
					idx = (IsValid(sword) and sword.GetFightStyle and sword:GetFightStyle()) or 1
				end
				vLabel:SetText(string.upper(getStanceName(idx)))
			end

			local function setStance(idx)
				local sword = getSword()
				local max = (IsValid(sword) and sword.Stances) and table.Count(sword.Stances) or 0
				local pLocal = LocalPlayer()
				local charId = (pLocal.GetCharacterGlobalId and pLocal:GetCharacterGlobalId()) or 0
				if charId and charId ~= 0 then
					file.CreateDir("solve_naruto/ken_stance")
					file.Write(("solve_naruto/ken_stance/%s.json"):format(tostring(charId)), util.TableToJSON({ iStance = idx }, false))
				end
				vLabel:SetText(string.upper(getStanceName(idx)))

				net.Start("Solve.Naruto:SwordProto")
				net.WriteUInt(2, 3)
				net.WriteUInt(idx, 3)
				net.SendToServer()
				timer.Simple(0.05, refreshLabel)
			end

			vLeft.DoClick = function()
				local sword = getSword()
				local stances = getStancesSource()
				local max = table.Count(stances or {})
				LocalPlayer():EmitSound("solve/combat/take.mp3")
				if max <= 0 then surface.PlaySound("buttons/button10.wav") return end
				local idx = (IsValid(sword) and sword:GetFightStyle()) or LocalPlayer():GetNetworkVar("iKenStance") or 1
				idx = idx - 1
				if idx < 1 then idx = max end
				setStance(idx)
				surface.PlaySound("solve_naruto_base/ui/bruitage_switch_jutsu.wav")
			end

			vRight.DoClick = function()
				local sword = getSword()
				local stances = getStancesSource()
				local max = table.Count(stances or {})
				LocalPlayer():EmitSound("solve/combat/take.mp3")
				if max <= 0 then surface.PlaySound("buttons/button10.wav") return end
				local idx = (IsValid(sword) and sword:GetFightStyle()) or LocalPlayer():GetNetworkVar("iKenStance") or 1
				idx = idx + 1
				if idx > max then idx = 1 end
				setStance(idx)
				surface.PlaySound("solve_naruto_base/ui/bruitage_switch_jutsu.wav")
			end

			refreshLabel()

			vStancePanel.Think = function()
				if not IsValid(vStancePanel) then return end
				refreshLabel()
			end
		end

		local tTree = M_Fight.tConfig.tBranch[tConfigTree.sID]
		if not tTree then continue end
		local nPosX, nPosY = tConfigTree.fPos(VH)
		nPosX = nPosX - VH * 4
		nPosY = nPosY - VH * 4
		local iOldAlpha = surface.GetAlphaMultiplier()
		local bHasNature = true
		if isfunction(tTree.fCheck) then bHasNature = tTree.fCheck(pLocal) end
		local iSkillsCount = #M_Fight.tConfig.tBranch[tConfigTree.sID].tSkills
		-- TFJ v2 : les ronds sont places dans la colonne de leur arbre (TFJ2.Colonnes). Toutes les techniques
		-- de l'arbre restent affichees. Natures : un etage par rang (TFJ_RangTechnique), ronds du meme rang cote a cote.
		-- Autres onglets : une pile verticale, la premiere technique en bas.
		local tTFJPos
		local tCol = tTFJColParID[tConfigTree.sID]
		if tCol then
			tTFJPos = {}
			local nTaille = VH * 5.5
			local tVisibles = {}
			for _, tS in ipairs(M_Fight.tConfig.tBranch[tConfigTree.sID].tSkills) do
				local tFull = M_Fight.tIDs[tS.sID]
				if tFull and not tFull.bHidden then table.insert(tVisibles, tFull) end
			end
			if tCategory.sName == "Natures" and not tConfigTree.bColumn then
				vFrame.tTFJLiens = vFrame.tTFJLiens or {}
				local tEtages, iRangMax = {}, 1
				for _, tFull in ipairs(tVisibles) do
					local iRang = TFJ_RangTechnique(tFull)
					tEtages[iRang] = tEtages[iRang] or {}
					table.insert(tEtages[iRang], tFull.sID)
					iRangMax = math.max(iRangMax, iRang)
				end
				local tEtageDessous
				for iRang = 1, 6 do
					local tEtage = tEtages[iRang]
					if tEtage then
						local nY = tCol.y + VH * 3 + (iRangMax - iRang) * VH * 7
						for k, sID in ipairs(tEtage) do
							tTFJPos[sID] = { tCol.cx - nTaille / 2 + (k - (#tEtage + 1) / 2) * VH * 7, nY }
							vFrame.tTFJLiens[sID] = tEtageDessous or {}
						end
						tEtageDessous = tEtage
					end
				end
			else
				local n = #tVisibles
				local nPas = math.min(VH * 8, VH * 36 / math.max(1, n - 1))
				for k, tFull in ipairs(tVisibles) do
					tTFJPos[tFull.sID] = { tCol.cx - nTaille / 2, tCol.y + VH * 3 + (n - k) * nPas }
				end
			end
		end
		for i, tSkill in ipairs(M_Fight.tConfig.tBranch[tConfigTree.sID].tSkills) do
			local tSkill = M_Fight.tIDs[tSkill.sID]
			if tSkill.bHidden then continue end
			-- tSkill.nX, tSkill.nY
			local bEven = (i + 1) % 2 == 0
			local vButton = vgui.Create("DButton", vFrame)
			vButton:SetSize(VH * 5.5, VH * 5.5)
			if tConfigTree.bColumn then
				vButton:SetPos(nPosX, nPosY + (-VH * 8) * (i - 1))
			else
				if bEven then
					vButton:SetPos(nPosX + VH * 8, nPosY + (-VH * 4) * (i - 1))
				else
					vButton:SetPos(nPosX, nPosY + (-VH * 4) * i)
				end

				if i == 1 then vButton:SetX(vButton:GetX() - VH * 3.8) end

				if i == 10 then vButton:SetX(vButton:GetX() + VH * 3.8) end
			end
			if tTFJPos and tTFJPos[tSkill.sID] then vButton:SetPos(tTFJPos[tSkill.sID][1], tTFJPos[tSkill.sID][2]) end

			vButton:SetText("")
			local bHasSkill = pLocal:HasSkill(tSkill.sID)
			local tLevel1 = tSkill.tLevels[1]
			local sMinimumRank = tLevel1.sMinimumRank or tSkill.sMinimumRank
			local bHasMinimumRank = pLocal:IsNinjaRank(sMinimumRank)
			local bHasPreviousSkill
			local bHasPreviousSkill2
			if M_Fight.tConfig.tBranch[tConfigTree.sID].tSkills[10] then bHasPreviousSkill = pLocal:HasSkill(M_Fight.tConfig.tBranch[tConfigTree.sID].tSkills[10].sID) end
			if M_Fight.tConfig.tBranch[tConfigTree.sID].tSkills[9] then bHasPreviousSkill2 = pLocal:HasSkill(M_Fight.tConfig.tBranch[tConfigTree.sID].tSkills[9].sID) end
			vButton.Paint = function(self, w, h)
				bHasSkill = pLocal:HasSkill(tSkill.sID)
				self.iLerpHover = Lerp(FrameTime() * 10, self.iLerpHover or 0, self:IsHovered() and 1 or 0)
				local bBloque = (i == 11 and (not bHasPreviousSkill and not bHasPreviousSkill2)) or not bHasMinimumRank
				surface.SetAlphaMultiplier((not bHasNature or bBloque) and 0.45 or (bHasSkill and 1 or 0.75))
				local iGris = bHasSkill and 255 or 120
				local bClip = DisableClipping(true)
				surface.SetDrawColor(iGris, iGris, iGris, 255)
				surface.SetMaterial(tMats["circle"])
				surface.DrawTexturedRectRotated(w / 2, h / 2, w + (w * 0.2) * self.iLerpHover, h + (h * 0.2) * self.iLerpHover, 0)
				if tSkill.mImage then
					surface.SetMaterial(tSkill.mImage)
					surface.DrawTexturedRectRotated(w / 2, h / 2, w * 0.85 + (w * 0.15) * self.iLerpHover, h * 0.85 + (h * 0.15) * self.iLerpHover, 0)
				end

				-- Rank
				local tRankLinked = Solve.Naruto.Config["ranks"][tSkill.sMinimumRank or "genin"]
				if tRankLinked then
					local mat, iW, iH = Solve:GetMaterial(tRankLinked.sJutsuMat)
					if mat then
						surface.SetDrawColor(255, 255, 255, 255)
						surface.SetMaterial(mat)
						surface.DrawTexturedRectRotated(w * 0.8 + 5 * self.iLerpHover, h * 0.8 + 5 * self.iLerpHover, iW / 6, iH / 6, 0)
					end
				end

				DisableClipping(bClip)
				surface.SetAlphaMultiplier(1)
			end

			vButton.DoClick = function()
				if not bHasNature then
					surface.PlaySound("solve_naruto_base/ui/nooo_f4.wav")
					if isfunction(tTree.fCustomErrorMessage) then Solve:Notify("info", "Skills Menu", tTree.fCustomErrorMessage()) end
					return
				end

				if (i == 11 and (not bHasPreviousSkill and not bHasPreviousSkill2)) or not bHasMinimumRank then
					surface.PlaySound("solve_naruto_base/ui/nooo_f4.wav")
					return
				end

				vSelect = tSkill
				M_Fight:SkillUpgrade(tSkill)
				surface.PlaySound("solve_naruto_base/ui/bruitage_switch_jutsu.wav")
			end

			tIDs[tSkill.sID] = vButton
		end

	end

	Header(vFrame, nID)
end

net.Receive("NRP::Battle::FirstNature", function() M_Fight:RerollNature(true) end)

net.Receive("Solve.Naruto:RequestClientStance", function()
	local pLocal = LocalPlayer()
	if not IsValid(pLocal) then return end
	local charId = (pLocal.GetCharacterGlobalId and pLocal:GetCharacterGlobalId()) or 0
	if not charId or charId == 0 then return end

	local pathKen = ("solve_naruto/ken_stance/%s.json"):format(tostring(charId))
	if file.Exists(pathKen, "DATA") then
		local s = file.Read(pathKen, "DATA")
		if s and s ~= "" then
			local t = util.JSONToTable(s)
			local idx = tonumber(t and (t.iStance or t.stance))
			if idx and idx >= 1 then
				net.Start("Solve.Naruto:SwordProto")
					net.WriteUInt(2, 3)
					net.WriteUInt(math.max(1, idx), 3)
				net.SendToServer()
			end
		end
	end

	local pathCombat = ("solve_naruto/combat_style/%s.json"):format(tostring(charId))
	if file.Exists(pathCombat, "DATA") then
		local s = file.Read(pathCombat, "DATA")
		if s and s ~= "" then
			local t = util.JSONToTable(s)
			local iStyleId = tonumber(t and (t.iStyle or t.style))
			if iStyleId and iStyleId >= -1 then
				net.Start("Solve.Naruto.Combat:SetStyleOverride")
					net.WriteInt(iStyleId, 8)
				net.SendToServer()
			end
		end
	end
end)

local tMats = {
	["base"] = Material("materials/solve_nrp/nrp_interface/tree/background_reroll.png", "smooth"),
	["basesecondnature"] = Material("materials/geams/ui/2eNature.png", "smooth"),
	["doton"] = Material("materials/solve_nrp/nrp_interface/tree/doton.png", "smooth"),
	["futon"] = Material("materials/solve_nrp/nrp_interface/tree/futon.png", "smooth"),
	["katon"] = Material("materials/solve_nrp/nrp_interface/tree/katon.png", "smooth"),
	["raiton"] = Material("materials/solve_nrp/nrp_interface/tree/raiton.png", "smooth"),
	["suiton"] = Material("materials/solve_nrp/nrp_interface/tree/suiton.png", "smooth"),
	["suiton"] = Material("materials/solve_nrp/nrp_interface/tree/suiton.png", "smooth"),
	["selector_nature_reroll"] = Material("materials/solve_nrp/nrp_interface/tree/selector_nature_reroll.png", "smooth"),
	["icon_exit"] = Material("materials/solve_nrp/nrp_interface/skills/icon_exit.png", "smooth"),
	["background_nature01"] = Material("materials/solve_nrp/nrp_interface/tree/background_nature01.png", "smooth"),
	["background_nature02"] = Material("materials/solve_nrp/nrp_interface/tree/background_nature02.png", "smooth"),
}

local matRound, iRoundW, iRoundH = Solve:GetMaterial("f4_round")
local function IsClanSkillStaffOnly(tSkill)
	if not tSkill or not tSkill.sID then return false end

	for _, tMainCategory in ipairs((M_Fight.tConfig and M_Fight.tConfig.tSkillsCategories) or {}) do
		if tMainCategory.sName == "Clans" or tMainCategory.bClan then
			for _, tClanCategory in ipairs(tMainCategory.tCategories or {}) do
				for _, tEntry in ipairs(tClanCategory.tSkills or {}) do
					if tEntry.sID == tSkill.sID then return true end
				end
			end
		end
	end

	return false
end

function M_Fight:SkillUpgrade(tSkill)
	local pLocal = LocalPlayer()
	local VH = ScrH() / 100
	local cColor = tSkill.cGradient and tSkill.cGradient:Copy() or color_white
	cColor.a = 255
	local vUpgrade
	local vFrame = vgui.Create("DButton")
	vFrame:SetSize(ScrW(), ScrH())
	vFrame:MakePopup()
	vFrame:SetAlpha(0)
	vFrame:SetText("")
	vFrame.Paint = function(self, w, h)
		surface.SetDrawColor(0, 0, 0, 190)
		surface.DrawRect(0, 0, w, h)
		NRP:DrawBlur(self, 4)
		local nActual
		if pLocal:HasSkill(tSkill.sID) then
			nActual = pLocal:HasSkill(tSkill.sID).nLevel
		else
			nActual = 0
		end

		local nY = h / 3.5
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(tSkill.mImage)
		surface.DrawTexturedRectRotated(w / 2, nY, VH * 6, VH * 6, 0)
		local nActualLevel = pLocal:HasSkill(tSkill.sID) and pLocal:HasSkill(tSkill.sID).nLevel or 0
		local tNextLevel = tSkill.tLevels[math.min(nActualLevel + 1, #tSkill.tLevels)] or {}
		draw.SimpleText(tSkill.sName, "NRP::Poppins::2D::3::1000", w / 2, nY + VH * 8, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		local sText = NRP:SplitText(tSkill.sDesc, VH * 50, "NRP::Poppins::2D::2.5::500")
		draw.DrawText(sText, "NRP::Poppins::2D::2.5::500", w / 2, nY + VH * 12, color_white, TEXT_ALIGN_CENTER)
		nY = nY + select(2, surface.GetTextSize(sText))
		local nTypeX = w / 2 - VH * 15
		surface.SetFont("NRP::Poppins::2D::3::1000")
		local nTypeLabelWidth = surface.GetTextSize("Type: ")
		draw.SimpleText("Type:", "NRP::Poppins::2D::3::1000", nTypeX, nY + VH * 15, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText(tSkill.sType or "Attack", "NRP::Poppins::2D::3::1000", nTypeX + nTypeLabelWidth, nY + VH * 15, cColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText("Grade:", "NRP::Poppins::2D::3::1000", w / 2 - VH * 15, nY + VH * 18, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		local s_rank = tSkill.sRang or tSkill.sMinimumRank or "Genin"
		local SRang = Solve.Naruto.Config["ranks"][s_rank] and Solve.Naruto.Config["ranks"][s_rank].sName or ""
		if tNextLevel.sMinimumRank then SRang = Solve.Naruto.Config["ranks"][tNextLevel.sMinimumRank] and Solve.Naruto.Config["ranks"][tNextLevel.sMinimumRank].sName or "" end
		-- TFJ : une technique de rang B affiche toujours Kakunin, sauf si le niveau suivant demande un grade plus haut
		local tAffiche = Solve.Naruto.Config["ranks"][tNextLevel.sMinimumRank or s_rank]
		if TFJ_RangTechnique(tSkill) == 3 and not (tAffiche and (tAffiche.iPower or 0) > 7) then SRang = "Kakunin" end
		local nW = string.len(SRang)
		draw.SimpleText(SRang or "Genin", "NRP::Poppins::2D::3::1000", w / (nW <= 7 and 2 or 1.865), nY + VH * 18, cColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		draw.SimpleText("Required points: " .. (((tSkill.tLevels[nActualLevel + 1] or {}) or {}).nPoint or 0), "NRP::Poppins::2D::2.5::500", w / 2 - VH * 15, nY + VH * 21, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		local nTotalLevel = #tSkill.tLevels
		nY = nY + VH * 17 + VH * 6
		surface.SetDrawColor(255, 255, 255, 10)
		surface.DrawRect(w / 2 - VH * 15.5, nY, VH * 31, 1)
		draw.SimpleText("Upgrades " .. nActualLevel .. "/" .. nTotalLevel, "NRP::Poppins::2D::2.5::500", w / 2, nY + VH * 3.4, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		nY = nY + VH * 6
		local nSize, nGap, nCount = VH * 5.4, VH * 2, nTotalLevel
		local nPosX = ScrW() / 2 - (nCount * nSize + (nCount - 1) * nGap) / 2
		for i = 1, nCount do
			local nX, nY = nPosX + (i - 1) * (nSize + nGap) + nSize / 2 - 1, nY + nSize / 2 - 1
			if nActualLevel >= i then
				-- draw.SimpleText(sCircle, "NRP::Font::FA::20", nX, nY, cColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				-- draw.SimpleText(sCircle, "NRP::Font::FA::18", nX, nY, Color(35, 37, 35, 255*(1 or 0.35)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				surface.SetDrawColor(cColor)
				surface.SetMaterial(matRound)
				surface.DrawTexturedRectRotated(nX, nY, nSize, nSize, 0)
				surface.SetDrawColor(Color(35, 37, 35, 255 * (1 or 0.35)))
				surface.SetMaterial(matRound)
				surface.DrawTexturedRectRotated(nX, nY, nSize - 4, nSize - 4, 0)
			else
				surface.SetDrawColor(Color(35, 37, 35, 255 * (1 or 0.35)))
				surface.SetMaterial(matRound)
				surface.DrawTexturedRectRotated(nX, nY, nSize, nSize, 0)
			end

			draw.SimpleText(i, "NRP::Poppins::2D::4::1000", nX, nY + VH * 0.15, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		if IsValid(vUpgrade) then vUpgrade:SetY(nY + VH * 8) end
	end

	vFrame:AlphaTo(255, 0.3, 0)
	vFrame.Think = function(self)
		if input.IsKeyDown(KEY_ESCAPE) and self:HasHierarchicalFocus() and not self.bClosing then
			vFrame:AlphaTo(0, 0.3, 0, function() vFrame:Remove() end)
			self.bClosing = true
		end

		self:SetCursor("arrow")
	end

	vFrame.DoClick = function() vFrame:AlphaTo(0, 0.3, 0, function() vFrame:Remove() end) end
	local vClose = vgui.Create("DButton", vFrame)
	vClose:SetSize(28, 28)
	vClose:SetPos(vFrame:GetWide() - vClose:GetWide() - VH * 3, VH * 3)
	vClose:SetText("")
	vClose.Paint = function(self, w, h)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(tMats["icon_exit"])
		surface.DrawTexturedRect(0, 0, w, h)
	end

	vClose.DoClick = function() vFrame:AlphaTo(0, 0.3, 0, function() vFrame:Remove() end) end
	vUpgrade = vgui.Create("DButton", vFrame)
	vUpgrade:SetSize(VH * 12, VH * 4)
	vUpgrade:CenterHorizontal()
	vUpgrade:SetText("")
	vUpgrade.Paint = function(self, w, h)
		NRP:RoundedBoxOutlined(VH * 1.5, 0, 0, w, h, color_white, 1)
		if IsClanSkillStaffOnly(tSkill) then
			draw.SimpleText("Staff uniquement", "NRP::Poppins::2D::3::1000", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		elseif not pLocal:HasSkill(tSkill.sID) then
			draw.SimpleText("Unlock", "NRP::Poppins::2D::3::1000", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		else
			draw.SimpleText("Upgrade", "NRP::Poppins::2D::3::1000", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end

	vUpgrade.DoClick = function()
		if IsClanSkillStaffOnly(tSkill) then
			surface.PlaySound("solve_naruto_base/ui/nooo_f4.wav")
			notification.AddLegacy("Cette compétence de clan est attribuée et améliorée uniquement par le staff.", NOTIFY_ERROR, 5)
			return
		end

		if pLocal:GetNetworkVar("nSkillPoint", 0) == 0 then
			surface.PlaySound("solve_naruto_base/ui/nooo_f4.wav")
			return
		end

		if not pLocal:HasSkill(tSkill.sID) then
			surface.PlaySound("solve_naruto_base/ui/unlock_jutsu.wav")
		else
			surface.PlaySound("solve_naruto_base/ui/jutsu_upgrade_skill_tree.wav")
		end

		net.Start("NRP::Battle::BuySkill")
		net.WriteString(tSkill.sID)
		net.SendToServer()
	end
end

function M_Fight:RerollNature(bInit, bRerollAndResetPanelSecondNature, bRerollFirstNature)
	local VH = ScrH() / 100
	local vFrame = vgui.Create("DFrame")
	vFrame:SetSize(ScrW(), ScrH())
	vFrame:Center()
	vFrame:MakePopup()
	vFrame:ShowCloseButton(false)
	vFrame:SetDraggable(false)
	vFrame:SetTitle("")
	vFrame:SetAlpha(0)
	vFrame.Paint = function(self, w, h)
		NRP:DrawBlur(self, 4)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(tMats[bRerollAndResetPanelSecondNature and "basesecondnature" or "base"])
		surface.DrawTexturedRect(0, 0, w, h)
	end

	vFrame:AlphaTo(255, 0.3, 0)
	if not bInit then
		local vClose = vgui.Create("DButton", vFrame)
		vClose:SetSize(28, 28)
		vClose:SetPos(vFrame:GetWide() - vClose:GetWide() - VH * 3, VH * 3)
		vClose:SetText("")
		vClose.Paint = function(self, w, h)
			surface.SetDrawColor(255, 255, 255, 255)
			surface.SetMaterial(tMats["icon_exit"])
			surface.DrawTexturedRect(0, 0, w, h)
		end

		vClose.DoClick = function() vFrame:AlphaTo(0, 0.3, 0, function() vFrame:Remove() end) end
	end

	local tNatures = {
		{
			sID = "suiton",
		},
		{
			sID = "futon",
		},
		{
			sID = "raiton",
		},
		{
			sID = "doton",
		},
		{
			sID = "katon",
		},
	}

	local nID = 3
	local VH = ScrH() / 100
	for i, tNature in ipairs(M_Fight.tConfig.tNatures) do
		local vPanel = vgui.Create("DPanel", vFrame)
		vPanel:SetSize(VH * 18, VH * 15)
		vPanel:SetPos(VH * 42.3 + (i - 1) * VH * 18.8, VH * 36)
		local mMat = tNature.mMat
		vPanel.Paint = function(self, w, h)
			if i == nID then
				surface.SetDrawColor(28, 28, 28, 200)
				surface.DrawRect(0, 0, w, h)
			end

			surface.SetDrawColor(255, 255, 255, 255)
			surface.SetMaterial(mMat)
			local nW, nH = mMat:Width(), mMat:Height()
			local nRatio = nW / nH
			surface.DrawTexturedRectRotated(w / 2, h / 2, h / 1.2 * nRatio, h / 1.2, 0)
		end
	end

	local vStart = vgui.Create("DButton", vFrame)
	vStart:SetSize(VH * 19, VH * 6)
	vStart:SetPos(VH * 79, VH * 62)
	vStart:SetText("")
	vStart.sText = "LANCIER"
	vStart.Paint = function(self, w, h) draw.SimpleText(self.sText, "NRP::Poppins::2D::5::1000", w / 2, h / 1.94, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) end
	vStart.DoClick = function(self)
		if self.bStarted then return end
		net.Receive((bRerollAndResetPanelSecondNature or bRerollFirstNature) and "NRP::Battle::RerollSecondNature" or "NRP::Battle::SendNature", function()
			local nNature = net.ReadUInt(8)
			timer.Create("nrp_skills", 0.2, 7 + nNature, function() nID = nID % 5 + 1 end)
			surface.PlaySound("naruto_reroll_nature.wav")

			local fAnimationDuration = (7 + nNature) * 0.2
			timer.Simple(fAnimationDuration + 0.1, function()
				if IsValid(self) then
					self.sText = "QUITTER"
					self.DoClick = function()
						vFrame:AlphaTo(0, 0.3, 0, function() vFrame:Remove() end)
					end
					self.bStarted = false
				end
			end)

			if bInit then timer.Simple(5, function() vFrame:AlphaTo(0, 0.3, 0, function() vFrame:Remove() end) end) end
			self.sText = "LANCÉ"
		end)

		if not bRerollFirstNature then
			net.Start(bRerollAndResetPanelSecondNature and "Solve.Naruto.Boutique:RerollSecondNature" or "NRP::Battle::FirstNature")
			net.SendToServer()
		else
			net.Start("Solve.Naruto.Boutique:RerollFirstNature")
			net.SendToServer()
		end

		nID = 3
		self.bStarted = true
	end

	if bRerollFirstNature or bRerollAndResetPanelSecondNature then
		timer.Simple(0.1, function()
			if not IsValid(vStart) then return end
			vStart:DoClick()
		end)
	end
end

net.Receive("NRP::Battle::NetworkSkills", function()
	local t = net.ReadTable()
	-- TFJ : pas de pLocal global ; si le joueur n'est pas encore prêt, on réessaie
	local function fnSet()
		local pLocal = LocalPlayer()
		if not IsValid(pLocal) then return false end
		pLocal.NRP_tSkills = t
		return true
	end
	if not fnSet() then
		timer.Create("NRP::Battle::NetworkSkills", 0.5, 20, function()
			if fnSet() then timer.Remove("NRP::Battle::NetworkSkills") end
		end)
	end
end)

net.Receive("Solve.Naruto.Boutique:DrawRerollFirstNature", function() M_Fight:RerollNature(false, false, true) end)
net.Receive("Solve.Naruto.Boutique:DrawRerollSecondNature", function() M_Fight:RerollNature(false, true, false) end)

-- Handle nature roll result from F4 menu — refresh the skill tree
net.Receive("Solve.Naruto.Nature:Result", function()
	local iSlot = net.ReadUInt(2)
	local sNature = net.ReadString()

	timer.Simple(0.3, function()
		if IsValid(M_vSkillTree) then
			M_Fight:SkillTree(1)
		end
	end)

	if Solve and Solve.Notify then
		Solve:Notify(Solve.NOTIFY_INFO, "Nature", "Nouveau caractère :" .. string.upper(sNature) .. "!")
	end
end)

hook.Add("PlayerButtonDown", "NRP::Battle::PlayerButtonDown::Skills", function(pPlayer, nKey)
	if not IsFirstTimePredicted() or nKey ~= Solve:GetSetting("skill_tree_key") then return end
	M_Fight:SkillTree()
end)

function NRP:SecondNature()
	local VH = ScrH() / 100
	local tNatures = M_Fight.tConfig.tNatures
	local iCount = #tNatures

	local tNatureColors = {
		["suiton"] = Color(0, 150, 255),
		["futon"] = Color(130, 210, 130),
		["raiton"] = Color(255, 255, 100),
		["doton"] = Color(160, 110, 60),
		["katon"] = Color(255, 100, 0),
	}

	local iCardW = VH * 16
	local iCardH = VH * 22
	local iSpacing = VH * 2
	local iTotalW = iCount * iCardW + (iCount - 1) * iSpacing + VH * 8
	local iTotalH = iCardH + VH * 18

	local vFrame = vgui.Create("DFrame")
	vFrame:SetSize(iTotalW, iTotalH)
	vFrame:Center()
	vFrame:MakePopup()
	vFrame:ShowCloseButton(false)
	vFrame:SetDraggable(true)
	vFrame:SetTitle("")
	vFrame:SetAlpha(0)
	vFrame.Paint = function(self, w, h)
		NRP:DrawBlur(self, 4)
		NRP:RoundedBox(VH * 1, 0, 0, w, h, Color(15, 15, 25, 240))
		NRP:RoundedBox(VH * 1, 0, 0, w, VH * 7, Color(30, 30, 50, 255))
		draw.SimpleText("Choisissez votre seconde nature", "NRP::Poppins::2D::3::1000", w / 2, VH * 3.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	vFrame:AlphaTo(255, 0.3, 0)

	local vClose = vgui.Create("DButton", vFrame)
	vClose:SetSize(VH * 4, VH * 4)
	vClose:SetPos(iTotalW - VH * 5, VH * 1.5)
	vClose:SetText("")
	vClose.Paint = function(self, w, h)
		surface.SetDrawColor(255, 255, 255, self:IsHovered() and 255 or 180)
		surface.SetMaterial(tMats["icon_exit"])
		surface.DrawTexturedRect(0, 0, w, h)
	end
	vClose.DoClick = function() vFrame:AlphaTo(0, 0.3, 0, function() vFrame:Remove() end) end

	local iStartX = VH * 4
	local iStartY = VH * 9
	for i, tNature in ipairs(tNatures) do
		local cNature = tNatureColors[tNature.sID] or Color(200, 200, 200)
		local vCard = vgui.Create("DButton", vFrame)
		vCard:SetPos(iStartX + (i - 1) * (iCardW + iSpacing), iStartY)
		vCard:SetSize(iCardW, iCardH)
		vCard:SetText("")

		vCard.fHoverLerp = 0
		vCard.Paint = function(self, w, h)
			self.fHoverLerp = Lerp(FrameTime() * 10, self.fHoverLerp, self:IsHovered() and 1 or 0)
			local fAlpha = 80 + 120 * self.fHoverLerp
			local cBg = Color(cNature.r * 0.3, cNature.g * 0.3, cNature.b * 0.3, fAlpha)
			NRP:RoundedBox(VH * 1, 0, 0, w, h, cBg)

			if self.fHoverLerp > 0.01 then
				local cBorder = Color(cNature.r, cNature.g, cNature.b, 180 * self.fHoverLerp)
				NRP:RoundedBox(VH * 1, 1, 1, w - 2, h - 2, cBorder)
				NRP:RoundedBox(VH * 0.8, 3, 3, w - 6, h - 6, cBg)
			end

			if tNature.mMat then
				local iIconSize = VH * 10
				surface.SetDrawColor(255, 255, 255, 200 + 55 * self.fHoverLerp)
				surface.SetMaterial(tNature.mMat)
				surface.DrawTexturedRect((w - iIconSize) / 2, VH * 2, iIconSize, iIconSize)
			end

			draw.SimpleText(tNature.sName, "NRP::Poppins::2D::3::1000", w / 2, h - VH * 4, cNature, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		vCard.DoClick = function()
			net.Start("Solve.Naruto.Nature:Choose")
			net.WriteUInt(2, 2)
			net.WriteString(tNature.sID)
			net.SendToServer()
			surface.PlaySound("solve_naruto_base/ui/menu_selection_v2.wav")
			vFrame:AlphaTo(0, 0.3, 0, function() vFrame:Remove() end)
		end
	end
end

net.Receive("NRP::Battle::NetworkSkills2", function() LocalPlayer().NRP_tSkills = {} end)