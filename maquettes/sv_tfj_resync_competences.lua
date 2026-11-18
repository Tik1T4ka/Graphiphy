-- TFJ : renvoie les techniques apprises au client quelques secondes apres sa connexion.
-- Si le premier envoi arrive avant que le menu du client soit pret, le F4 et le menu B
-- affichaient "rien d'appris" alors que tout est bien en base.
local function Renvoyer(p)
    if not IsValid(p) or not istable(p.NRP_tSkills) or table.IsEmpty(p.NRP_tSkills) then return end
    net.Start("NRP::Battle::NetworkSkills")
    net.WriteTable(p.NRP_tSkills)
    net.Send(p)
end
hook.Add("PlayerInitialSpawn", "TFJ.ResyncCompetences", function(p)
    for _, d in ipairs({ 15, 45, 90 }) do timer.Simple(d, function() Renvoyer(p) end) end
end)
-- apres un changement de personnage
hook.Add("PlayerSpawn", "TFJ.ResyncCompetences", function(p)
    timer.Simple(5, function() Renvoyer(p) end)
end)
