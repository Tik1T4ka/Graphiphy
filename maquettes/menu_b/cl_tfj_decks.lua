-- Decks de sorts nommés : enregistrés depuis le menu des sorts (B), équipés en combat avec H.
-- Un deck = les 6 sorts de la barre. Le serveur (server/sv_tfj_decks.lua) vérifie que le joueur possède
-- chaque sort et sauvegarde la barre.
local OPEN_KEY = KEY_H

local tDecks = {}
local vDeckMenu

local function DeckFile()
    return "tfj_decks_" .. LocalPlayer():GetCharacterGlobalId() .. ".json"
end

local function LoadDecks()
    tDecks = util.JSONToTable(file.Read(DeckFile(), "DATA") or "") or {}
end

local function SaveDecks()
    file.Write(DeckFile(), util.TableToJSON(tDecks))
end

local function BarSlot(i)
    return i + (LocalPlayer():GetNetworkVar("iDeckSelected", 1) - 1) * 6
end

local function SaveCurrentBar(sName)
    local pLocal = LocalPlayer()
    local tSkills = {}
    for i = 1, 6 do tSkills[i] = pLocal:GetNetworkVar("nrp_skill_" .. BarSlot(i), false) or false end
    LoadDecks()
    table.insert(tDecks, { sName = sName, tSkills = tSkills })
    SaveDecks()
end

-- Les 6 sorts partent dans un seul message (sv_tfj_decks.lua) : ils apparaissent tous en même temps
local function ApplyDeck(tDeck)
    net.Start("TFJ::Decks::Apply")
    for i = 1, 6 do
        local sSkill = tDeck.tSkills[i]
        net.WriteString(M_Fight.tIDs[sSkill] and sSkill or "")
    end
    net.SendToServer()
    surface.PlaySound("solve_naruto_base/ui/swap_jutsu_deck.wav")
end

local function Font(fSize)
    return Solve:Font(math.Round(ScrH() * fSize), 8, true)
end

-- Menu H : liste des decks, clic = équiper, clic droit = supprimer
local function OpenDeckMenu()
    if IsValid(vDeckMenu) then vDeckMenu:Remove() return end
    LoadDecks()

    local VH = ScrH() / 100
    local iRowH, iPad = VH * 7, VH * 1
    vDeckMenu = vgui.Create("DPanel")
    vDeckMenu:SetSize(VH * 60, iPad * 2 + VH * 5 + math.max(#tDecks, 1) * (iRowH + iPad))
    vDeckMenu:Center()
    vDeckMenu:MakePopup()
    vDeckMenu:SetKeyboardInputEnabled(false) -- on peut continuer à se déplacer pendant le choix
    vDeckMenu.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(10, 10, 10, 220))
        draw.SimpleText("DECKS", Font(0.03), w / 2, iPad, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        if #tDecks == 0 then
            draw.SimpleText("Aucun deck : crée-en un dans le menu des sorts (B)", Font(0.018), w / 2, iPad + VH * 9,
                Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    for iDeck, tDeck in ipairs(tDecks) do
        local vRow = vgui.Create("DButton", vDeckMenu)
        vRow:SetText("")
        vRow:SetPos(iPad, iPad + VH * 5 + (iDeck - 1) * (iRowH + iPad))
        vRow:SetSize(vDeckMenu:GetWide() - iPad * 2, iRowH)
        vRow.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and Color(214, 170, 72, 120) or Color(255, 255, 255, 20))
            draw.SimpleText(tDeck.sName, Font(0.02), VH, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            local iIcon = h - VH
            for i = 1, 6 do
                local tSkill = M_Fight.tIDs[tDeck.tSkills[i]]
                local x = w - (7 - i) * (iIcon + VH * 0.5)
                draw.RoundedBox(iIcon / 2, x, VH / 2, iIcon, iIcon, Color(0, 0, 0, 150))
                if tSkill and tSkill.mImage then
                    surface.SetDrawColor(255, 255, 255)
                    surface.SetMaterial(tSkill.mImage)
                    surface.DrawTexturedRect(x, VH / 2, iIcon, iIcon)
                end
            end
        end
        vRow.DoClick = function()
            ApplyDeck(tDeck)
            vDeckMenu:Remove()
        end
        vRow.DoRightClick = function()
            Derma_Query("Supprimer le deck « " .. tDeck.sName .. " » ?", "Decks", "Supprimer", function()
                LoadDecks()
                table.remove(tDecks, iDeck)
                SaveDecks()
                if IsValid(vDeckMenu) then vDeckMenu:Remove() end
                OpenDeckMenu()
            end, "Annuler")
        end
    end
end

hook.Add("PlayerButtonDown", "TFJ.Decks.Open", function(pPlayer, iKey)
    if iKey ~= OPEN_KEY or not IsFirstTimePredicted() or pPlayer ~= LocalPlayer() then return end
    if IsValid(M_vSkillTree) and not M_vSkillTree.bClosing then return end -- pas par-dessus le menu des sorts
    OpenDeckMenu()
end)

-- Une seule barre de sorts : la touche N (cl_views.lua) et le bouton 1/2 du menu changent iDeckSelected côté client
-- sans attendre le serveur, qui reste maintenant sur la barre 1 (jutsus_fix sv_skill_handlers.lua) : on recale.
hook.Add("Think", "TFJ.Decks.SingleBar", function()
    local pLocal = LocalPlayer()
    if IsValid(pLocal) and pLocal:GetNetworkVar("iDeckSelected", 1) ~= 1 then pLocal:SetNetworkVar("iDeckSelected", 1) end
end)

-- Menu B (cl_nrp_skills.lua, cadre global M_vSkillTree) : bouton sous le menu pour enregistrer la barre
hook.Add("Think", "TFJ.Decks.SkillMenuButton", function()
    local vFrame = M_vSkillTree
    if not IsValid(vFrame) or vFrame.bTFJDeckButton then return end
    vFrame.bTFJDeckButton = true

    -- Bouton 1/2 du menu (vDeckPanel, même taille que son image) : invisible et non cliquable.
    -- Son Paint est gardé car c'est lui qui crée les emplacements de la barre dans le menu (fnDrawSpells).
    local _, iDeckW, iDeckH = Solve:GetMaterial("background_set_deck")
    for _, vChild in ipairs(vFrame:GetChildren()) do
        if vChild.DoClick and math.abs(vChild:GetWide() - iDeckW) <= 1 and math.abs(vChild:GetTall() - iDeckH) <= 1 then
            local fnPaint = vChild.Paint
            vChild.Paint = function(self, w, h)
                local fAlpha = surface.GetAlphaMultiplier()
                surface.SetAlphaMultiplier(0)
                fnPaint(self, w, h)
                surface.SetAlphaMultiplier(fAlpha)
            end
            vChild:SetMouseInputEnabled(false)
        end
    end

    -- Le F4 (M_Fight:SkillTree) remplit aussi M_vSkillTree mais garde le clavier : pas de bouton deck là-bas
    if vFrame:IsKeyboardInputEnabled() then return end

    -- TFJ v2 : a droite des 6 emplacements de la barre, dans la fenetre du menu B (vMain : VH*119.72 x VH*66.75, centre)
    local VH = ScrH() / 100
    local x0, y0 = (ScrW() - VH * 119.72) / 2, (ScrH() - VH * 66.75) / 2
    local vButton = vgui.Create("DButton", vFrame)
    vButton:SetText("")
    vButton:SetSize(VH * 12.8, VH * 11.6)
    vButton:SetPos(x0 + VH * 105.1, y0 + VH * 52.2)
    vButton.Paint = function(self, w, h)
        if not TFJ_DeckPolice2 then
            TFJ_DeckPolice2 = true
            surface.CreateFont("TFJD.Grand", { font = "Bebas Neue", size = math.floor(VH * 3.1), weight = 400, extended = true })
            surface.CreateFont("TFJD.Petit", { font = "Bebas Neue", size = math.floor(VH * 1.5), weight = 400, extended = true })
            surface.CreateFont("TFJD.Bouton", { font = "Bebas Neue", size = math.floor(VH * 2.5), weight = 400, extended = true })
        end
        local bSurvol = self:IsHovered()
        draw.SimpleText("ENREGISTRER", "TFJD.Grand", w / 2, h * 0.02, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText("D A N S   U N   D E C K", "TFJD.Petit", w / 2, h * 0.32, Color(138, 138, 146), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        -- aplat rouge facon trait de pinceau
        local by, bh = h * 0.55, h * 0.36
        draw.NoTexture()
        surface.SetDrawColor(bSurvol and Color(240, 60, 68) or Color(216, 38, 47))
        surface.DrawPoly({ { x = 0, y = by + bh * 0.12 }, { x = w * 0.08, y = by }, { x = w * 0.92, y = by + bh * 0.08 }, { x = w, y = by + bh * 0.35 }, { x = w * 0.96, y = by + bh }, { x = w * 0.04, y = by + bh * 0.9 } })
        draw.SimpleText("+ NOUVEAU DECK", "TFJD.Bouton", w / 2, by + bh / 2 + 1, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    vButton.DoClick = function()
        Derma_StringRequest("Nouveau deck", "Nom du deck (la barre de sorts actuelle sera enregistrée) :", "", function(sName)
            sName = string.Trim(sName)
            if sName == "" then return end
            SaveCurrentBar(string.sub(sName, 1, 32))
            surface.PlaySound("solve_naruto_base/ui/menu_selection_v2.wav")
            chat.AddText(Color(214, 170, 72), "[Decks] ", color_white, "Deck « " .. sName .. " » enregistré. Touche H pour l'équiper.")
        end)
    end
end)

