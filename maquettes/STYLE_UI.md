# Styles des menus TFJ

Couleurs communes : noir, rouge (176, 26, 26), blanc.
Menu F4 (arbre de compétences) : l'onglet Classe est en cours de refonte (maquette `classe/maquette_f4_classe.html`), on modifie le skill tree existant. Meme quota de techniques qu'aujourd'hui sur chaque onglet (Natures 10, Styles 5, Classes 3 par arbre) : les 4 ronds des maquettes ne sont qu'indicatifs. Chaque colonne a un degrade tire des couleurs de son illustration ; pour Clans et Kekkei Genkai (sans illustration), couleur moyenne des icones de leurs techniques, calculee en jeu (IMaterial:GetColor).

## Style A : « lecteur de musique » (`references/style_A_lecteur_musique.png`)
Utilisé pour : coffre, registre médical.
- Police : Philosopher Bold (`resource/fonts/philosopher-*.ttf`, envoyée par `sv_tfj_polices.lua`).
- Fenêtres noires avec grain, double liseré fin, angles nets, petits losanges aux coins.
- Petit libellé rouge en majuscules au-dessus d'un grand titre blanc.
- Lignes de liste encadrées, liseré rouge au survol.
- Fonctions partagées : `TFJ_UI.Cadre`, `TFJ_UI.Grain`, `TFJ_UI.Losange`, `TFJ_UI.Bouton`, `TFJ_UI.EnTete`.

## Style B : « entraînement » (`references/style_B_entrainement.png`)
Pour varier les prochains menus.
- Grands titres en capitales, police brute type « Chinese Rocks » (déjà sur les clients : `chinese-rocks.ttf`).
  Petits textes en Poppins.
- Fond noir avec une lueur rouge radiale en haut à gauche.
- Cartes en colonnes, angle supérieur droit coupé, liseré rouge sur la carte active.
- Grand numéro en contour gris (01, 02, 03) en haut à droite de chaque carte.
- Barre de progression fine (blanc sur gris), libellé à gauche et valeur en gras à droite.
- Liste à puces rouges, gros bouton rouge plein en bas de carte avec un sous-titre.
- Colonne de gauche : étapes verticales avec un losange (blanc = fait, rouge = en cours, gris = verrouillé).
- Barre du haut : logo « TFJ » avec un losange rouge, fil d'Ariane, boutons à liseré à droite.
