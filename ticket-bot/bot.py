"""Bot de tickets pour le serveur Discord « Suivis - TFJ ».

Fonctionnement :
  1. Un admin tape /panel-tickets dans #demandes-de-tickets : le bot y poste
     un message avec un bouton « 📩 Créer un ticket ».
  2. Un membre clique, indique la raison, et le bot crée un salon privé
     visible uniquement par lui et par le staff.
  3. Dans le ticket, le staff peut « Prendre en charge », et tout le monde
     peut « Fermer » (avec confirmation). À la fermeture, une transcription
     est envoyée dans le salon de logs (si configuré) puis le salon est supprimé.

Les boutons sont « persistants » : ils continuent de marcher après un
redémarrage du bot.
"""

from __future__ import annotations

import asyncio
import io
import logging
import os
import re

import discord
from discord import app_commands
from discord.ext import commands

try:  # Le fichier .env est optionnel (pratique en local).
    from dotenv import load_dotenv

    load_dotenv()
except ImportError:  # pragma: no cover
    pass

log = logging.getLogger("ticket-bot")


# --------------------------------------------------------------------------
# Configuration (variables d'environnement)
# --------------------------------------------------------------------------
def _env_int(name: str, default: int | None = None) -> int | None:
    value = os.getenv(name, "").strip()
    return int(value) if value else default


def _env_int_list(name: str) -> list[int]:
    raw = os.getenv(name, "")
    return [int(x) for x in re.split(r"[,\s]+", raw) if x.strip()]


TOKEN = os.getenv("DISCORD_TOKEN", "").strip()
GUILD_ID = _env_int("GUILD_ID")
TICKET_CATEGORY_ID = _env_int("TICKET_CATEGORY_ID")
STAFF_ROLE_IDS = _env_int_list("STAFF_ROLE_IDS")
LOG_CHANNEL_ID = _env_int("LOG_CHANNEL_ID")
PING_STAFF = os.getenv("PING_STAFF", "true").lower() in {"1", "true", "yes", "oui"}

EMBED_COLOR = discord.Color.from_rgb(88, 101, 242)
OWNER_TAG = "ticket-owner:"  # Stocké dans le sujet du salon pour retrouver l'auteur.


# --------------------------------------------------------------------------
# Utilitaires
# --------------------------------------------------------------------------
def staff_roles(guild: discord.Guild) -> list[discord.Role]:
    return [r for rid in STAFF_ROLE_IDS if (r := guild.get_role(rid)) is not None]


def is_staff(member: discord.Member) -> bool:
    if member.guild_permissions.administrator:
        return True
    return any(r.id in STAFF_ROLE_IDS for r in member.roles)


def ticket_owner_id(channel: discord.abc.GuildChannel) -> int | None:
    topic = getattr(channel, "topic", None) or ""
    match = re.search(rf"{OWNER_TAG}(\d+)", topic)
    return int(match.group(1)) if match else None


def find_open_ticket(guild: discord.Guild, user_id: int) -> discord.TextChannel | None:
    for channel in guild.text_channels:
        if ticket_owner_id(channel) == user_id:
            return channel
    return None


def channel_slug(name: str) -> str:
    slug = re.sub(r"[^a-z0-9-]", "", name.lower().replace(" ", "-"))
    return slug[:80] or "membre"


async def build_transcript(channel: discord.TextChannel) -> discord.File:
    lines = [f"Transcription de #{channel.name}", "=" * 40]
    async for msg in channel.history(limit=None, oldest_first=True):
        when = msg.created_at.strftime("%d/%m/%Y %H:%M")
        content = msg.clean_content
        for embed in msg.embeds:
            content += f" [embed: {embed.title or ''} {embed.description or ''}]"
        for att in msg.attachments:
            content += f" [fichier: {att.url}]"
        lines.append(f"[{when}] {msg.author.display_name}: {content}")
    data = io.BytesIO("\n".join(lines).encode("utf-8"))
    return discord.File(data, filename=f"{channel.name}.txt")


# --------------------------------------------------------------------------
# Création d'un ticket
# --------------------------------------------------------------------------
async def create_ticket(interaction: discord.Interaction, reason: str) -> None:
    guild = interaction.guild
    member = interaction.user
    assert guild is not None and isinstance(member, discord.Member)

    existing = find_open_ticket(guild, member.id)
    if existing:
        await interaction.response.send_message(
            f"Tu as déjà un ticket ouvert : {existing.mention}", ephemeral=True
        )
        return

    await interaction.response.defer(ephemeral=True, thinking=True)

    category = guild.get_channel(TICKET_CATEGORY_ID) if TICKET_CATEGORY_ID else None
    if category is not None and not isinstance(category, discord.CategoryChannel):
        category = None

    overwrites: dict[discord.abc.Snowflake, discord.PermissionOverwrite] = {
        guild.default_role: discord.PermissionOverwrite(view_channel=False),
        member: discord.PermissionOverwrite(
            view_channel=True,
            send_messages=True,
            read_message_history=True,
            attach_files=True,
            embed_links=True,
        ),
        guild.me: discord.PermissionOverwrite(
            view_channel=True,
            send_messages=True,
            read_message_history=True,
            manage_channels=True,
            manage_messages=True,
            embed_links=True,
            attach_files=True,
        ),
    }
    for role in staff_roles(guild):
        overwrites[role] = discord.PermissionOverwrite(
            view_channel=True,
            send_messages=True,
            read_message_history=True,
            attach_files=True,
            embed_links=True,
            manage_messages=True,
        )

    try:
        channel = await guild.create_text_channel(
            name=f"ticket-{channel_slug(member.name)}",
            category=category,
            overwrites=overwrites,
            topic=f"Ticket de {member} | {OWNER_TAG}{member.id}",
            reason=f"Ticket ouvert par {member}",
        )
    except discord.Forbidden:
        await interaction.followup.send(
            "Je n'ai pas la permission de créer le salon. Un admin doit me donner "
            "la permission « Gérer les salons ».",
            ephemeral=True,
        )
        return

    embed = discord.Embed(
        title="🎫 Nouveau ticket",
        description=(
            f"Bonjour {member.mention}, merci d'avoir ouvert un ticket !\n"
            "Un membre du staff va te répondre dès que possible.\n\n"
            f"**Raison :**\n{reason}"
        ),
        color=EMBED_COLOR,
    )
    embed.set_footer(text="Clique sur 🔒 Fermer quand ta demande est réglée.")

    pings = [member.mention]
    if PING_STAFF:
        pings += [r.mention for r in staff_roles(guild)]

    await channel.send(
        content=" ".join(pings),
        embed=embed,
        view=TicketControlsView(),
        allowed_mentions=discord.AllowedMentions(users=True, roles=True),
    )
    await interaction.followup.send(f"Ton ticket a été créé : {channel.mention}", ephemeral=True)
    log.info("Ticket %s créé pour %s", channel.name, member)


# --------------------------------------------------------------------------
# Vues (boutons) et formulaire
# --------------------------------------------------------------------------
class TicketReasonModal(discord.ui.Modal, title="Créer un ticket"):
    reason = discord.ui.TextInput(
        label="Pourquoi ouvres-tu ce ticket ?",
        style=discord.TextStyle.paragraph,
        placeholder="Explique ta demande en quelques mots…",
        max_length=1000,
    )

    async def on_submit(self, interaction: discord.Interaction) -> None:
        await create_ticket(interaction, str(self.reason.value))


class TicketPanelView(discord.ui.View):
    """Message permanent dans #demandes-de-tickets."""

    def __init__(self) -> None:
        super().__init__(timeout=None)

    @discord.ui.button(
        label="Créer un ticket",
        emoji="📩",
        style=discord.ButtonStyle.primary,
        custom_id="tfj:ticket:open",
    )
    async def open_ticket(self, interaction: discord.Interaction, _: discord.ui.Button) -> None:
        assert interaction.guild is not None
        existing = find_open_ticket(interaction.guild, interaction.user.id)
        if existing:
            await interaction.response.send_message(
                f"Tu as déjà un ticket ouvert : {existing.mention}", ephemeral=True
            )
            return
        await interaction.response.send_modal(TicketReasonModal())


class TicketControlsView(discord.ui.View):
    """Boutons affichés dans chaque ticket."""

    def __init__(self) -> None:
        super().__init__(timeout=None)

    @discord.ui.button(
        label="Prendre en charge",
        emoji="🙋",
        style=discord.ButtonStyle.success,
        custom_id="tfj:ticket:claim",
    )
    async def claim(self, interaction: discord.Interaction, button: discord.ui.Button) -> None:
        assert isinstance(interaction.user, discord.Member)
        if not is_staff(interaction.user):
            await interaction.response.send_message(
                "Seul le staff peut prendre un ticket en charge.", ephemeral=True
            )
            return
        # Nouvelle instance : la vue persistante enregistrée est partagée par tous les tickets.
        view = TicketControlsView()
        view.claim.disabled = True
        view.claim.label = f"Pris en charge par {interaction.user.display_name}"[:80]
        await interaction.response.edit_message(view=view)
        await interaction.followup.send(
            f"🙋 {interaction.user.mention} s'occupe de ce ticket."
        )

    @discord.ui.button(
        label="Fermer",
        emoji="🔒",
        style=discord.ButtonStyle.danger,
        custom_id="tfj:ticket:close",
    )
    async def close(self, interaction: discord.Interaction, _: discord.ui.Button) -> None:
        assert isinstance(interaction.user, discord.Member)
        channel = interaction.channel
        owner_id = ticket_owner_id(channel) if channel else None
        if not (is_staff(interaction.user) or interaction.user.id == owner_id):
            await interaction.response.send_message(
                "Tu ne peux pas fermer ce ticket.", ephemeral=True
            )
            return
        await interaction.response.send_message(
            "Fermer ce ticket ? Le salon sera supprimé.",
            view=ConfirmCloseView(),
            ephemeral=True,
        )


class ConfirmCloseView(discord.ui.View):
    def __init__(self) -> None:
        super().__init__(timeout=60)

    @discord.ui.button(label="Oui, fermer", style=discord.ButtonStyle.danger)
    async def confirm(self, interaction: discord.Interaction, _: discord.ui.Button) -> None:
        channel = interaction.channel
        assert isinstance(channel, discord.TextChannel)
        await interaction.response.edit_message(content="Fermeture du ticket…", view=None)
        await channel.send(f"🔒 Ticket fermé par {interaction.user.mention}. Suppression dans 5 secondes.")

        if LOG_CHANNEL_ID and interaction.guild:
            log_channel = interaction.guild.get_channel(LOG_CHANNEL_ID)
            if isinstance(log_channel, discord.TextChannel):
                owner_id = ticket_owner_id(channel)
                try:
                    await log_channel.send(
                        f"📁 Ticket **#{channel.name}** (auteur : <@{owner_id}>) "
                        f"fermé par {interaction.user.mention}.",
                        file=await build_transcript(channel),
                        allowed_mentions=discord.AllowedMentions.none(),
                    )
                except discord.HTTPException:
                    log.exception("Impossible d'envoyer la transcription")

        await asyncio.sleep(5)
        await channel.delete(reason=f"Ticket fermé par {interaction.user}")

    @discord.ui.button(label="Annuler", style=discord.ButtonStyle.secondary)
    async def cancel(self, interaction: discord.Interaction, _: discord.ui.Button) -> None:
        await interaction.response.edit_message(content="Fermeture annulée.", view=None)


# --------------------------------------------------------------------------
# Bot et commandes
# --------------------------------------------------------------------------
class TicketBot(commands.Bot):
    def __init__(self) -> None:
        intents = discord.Intents.default()  # Pas besoin d'intents privilégiés.
        super().__init__(command_prefix=commands.when_mentioned, intents=intents)

    async def setup_hook(self) -> None:
        # Rend les boutons persistants après redémarrage.
        self.add_view(TicketPanelView())
        self.add_view(TicketControlsView())

        if GUILD_ID:
            guild = discord.Object(id=GUILD_ID)
            self.tree.copy_global_to(guild=guild)
            synced = await self.tree.sync(guild=guild)
        else:
            synced = await self.tree.sync()
        log.info("%d commande(s) slash synchronisée(s)", len(synced))

    async def on_ready(self) -> None:
        log.info("Connecté en tant que %s (id %s)", self.user, self.user.id if self.user else "?")


bot = TicketBot()


@bot.tree.command(name="panel-tickets", description="Poste le bouton « Créer un ticket » dans ce salon.")
@app_commands.default_permissions(administrator=True)
@app_commands.guild_only()
async def panel_tickets(interaction: discord.Interaction) -> None:
    embed = discord.Embed(
        title="🎫 Besoin d'aide ?",
        description=(
            "Clique sur le bouton ci-dessous pour ouvrir un ticket.\n"
            "Un salon privé sera créé entre toi et le staff."
        ),
        color=EMBED_COLOR,
    )
    assert isinstance(interaction.channel, discord.abc.Messageable)
    await interaction.channel.send(embed=embed, view=TicketPanelView())
    await interaction.response.send_message("Panneau de tickets posté ✅", ephemeral=True)


@bot.tree.command(name="fermer", description="Ferme le ticket actuel.")
@app_commands.guild_only()
async def fermer(interaction: discord.Interaction) -> None:
    channel = interaction.channel
    if channel is None or ticket_owner_id(channel) is None:
        await interaction.response.send_message("Ce salon n'est pas un ticket.", ephemeral=True)
        return
    assert isinstance(interaction.user, discord.Member)
    if not (is_staff(interaction.user) or interaction.user.id == ticket_owner_id(channel)):
        await interaction.response.send_message("Tu ne peux pas fermer ce ticket.", ephemeral=True)
        return
    await interaction.response.send_message(
        "Fermer ce ticket ? Le salon sera supprimé.", view=ConfirmCloseView(), ephemeral=True
    )


@bot.tree.command(name="ajouter", description="Ajoute un membre au ticket actuel.")
@app_commands.describe(membre="Le membre à ajouter")
@app_commands.guild_only()
async def ajouter(interaction: discord.Interaction, membre: discord.Member) -> None:
    channel = interaction.channel
    assert isinstance(interaction.user, discord.Member)
    if not isinstance(channel, discord.TextChannel) or ticket_owner_id(channel) is None:
        await interaction.response.send_message("Ce salon n'est pas un ticket.", ephemeral=True)
        return
    if not is_staff(interaction.user):
        await interaction.response.send_message("Réservé au staff.", ephemeral=True)
        return
    await channel.set_permissions(
        membre, view_channel=True, send_messages=True, read_message_history=True
    )
    await interaction.response.send_message(f"{membre.mention} a été ajouté au ticket.")


def main() -> None:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
    if not TOKEN:
        raise SystemExit("DISCORD_TOKEN manquant : copie .env.example en .env et mets le token du bot.")
    bot.run(TOKEN, log_handler=None)


if __name__ == "__main__":
    main()
