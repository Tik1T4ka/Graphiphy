-- Envoie aux joueurs les icones des emplacements d'equipement de l'inventaire TFJ (modules/inventory/cl_main.lua).
-- Les anciens fonds (fond_objets.png, fond_cosmetiques.png...) ne sont plus utilises ni envoyes.
for _, f in ipairs(file.Find("materials/tfj_inventaire/ico_*.png", "GAME")) do
	resource.AddSingleFile("materials/tfj_inventaire/" .. f)
end
