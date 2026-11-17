# Bot de tickets – Suivis TFJ

Le bot poste un bouton **📩 Créer un ticket** dans `#demandes-de-tickets`.
Quand un membre clique dessus :

1. Une fenêtre lui demande la raison du ticket.
2. Un salon privé `ticket-<pseudo>` est créé dans la catégorie *Ticket-suivi*.
   Seuls le membre et le staff (Fondateur, Gérant-serveur, Responsable-MJ et MJ) le voient.
3. Dans le ticket, le staff peut cliquer sur **🙋 Prendre en charge**. Le membre
   ou le staff peut cliquer sur **🔒 Fermer**, ce qui demande une confirmation puis supprime le salon.

Un membre ne peut avoir qu'un seul ticket ouvert à la fois.

Commandes slash :

| Commande | Qui | Effet |
|---|---|---|
| `/panel-tickets` | Admins | Poste le message avec le bouton dans le salon actuel |
| `/fermer` | Auteur du ticket / staff | Ferme le ticket actuel |
| `/ajouter @membre` | Staff | Ajoute quelqu'un au ticket |

## 1. Créer (ou réutiliser) le bot Discord

Tu peux réutiliser ton application **TFJ Bot** ou en créer une nouvelle :

1. Va sur <https://discord.com/developers/applications>, puis ouvre ton application (ou clique sur *New Application*).
2. Dans l'onglet **Bot**, clique sur **Reset Token** et copie le token. Garde-le secret.
   Aucun « Privileged Gateway Intent » n'est nécessaire.
3. Dans l'onglet **OAuth2 → URL Generator** :
   - Scopes : `bot` et `applications.commands`.
   - Permissions : *Gérer les rôles*, *Gérer les salons*, *Voir les salons*,
     *Envoyer des messages*, *Gérer les messages*, *Intégrer des liens*,
     *Joindre des fichiers*, *Voir les anciens messages*.

   Tu peux aussi utiliser directement ce lien, en remplaçant `CLIENT_ID` par l'ID de ton application :

   ```
   https://discord.com/oauth2/authorize?client_id=CLIENT_ID&scope=bot+applications.commands&permissions=268561424
   ```
4. Ouvre ce lien et ajoute le bot au serveur **Suivis - TFJ**.
5. Dans *Paramètres du serveur → Rôles*, place le rôle du bot **au-dessus**
   des rôles membres. Sinon, il ne peut pas régler les permissions des tickets.

## 2. Configurer

```bash
cd ticket-bot
cp .env.example .env
```

Ouvre `.env` et colle le token dans `DISCORD_TOKEN=`. Les IDs du serveur, de la
catégorie et des rôles staff sont déjà remplis. Pour garder un historique des
tickets fermés, mets l'ID d'un salon privé dans `LOG_CHANNEL_ID`. Pour copier un ID :
active le *Mode développeur* de Discord, puis fais un clic droit sur le salon et choisis *Copier l'identifiant*.

## 3. Lancer

Il te faut Python 3.10 ou plus récent.

```bash
python -m venv .venv
source .venv/bin/activate      # Windows : .venv\Scripts\activate
pip install -r requirements.txt
python bot.py
```

Le bot doit afficher `Connecté en tant que ...`.

Ensuite, va dans `#demandes-de-tickets` et tape **`/panel-tickets`**. Le message avec le bouton apparaît.
Il suffit de le faire une seule fois : le bouton continue de marcher après un redémarrage du bot.

## 4. Héberger 24h/24

Le bot ne répond aux clics que pendant qu'il tourne. Quelques options :

- **Ton PC** : bien pour tester, mais le bot s'arrête quand le PC est éteint.
- **Un hébergeur de bots Discord gratuit ou pas cher**, par exemple bot-hosting.net,
  Railway ou un petit VPS (Oracle Cloud Free Tier, etc.) :
  - envoie le dossier `ticket-bot` ;
  - la commande de démarrage est `python bot.py` ;
  - mets les valeurs du `.env` dans les « variables d'environnement » de l'hébergeur.
