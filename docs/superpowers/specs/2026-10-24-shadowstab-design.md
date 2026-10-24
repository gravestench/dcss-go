# Shadowstab contact design

## Source behavior

The Shadow's `AF_SHADOWSTAB` attack checks whether its defender can see it
before hit resolution. An unseen attacker bypasses evasion, but shields still
block. Monster damage receives a 5/2 multiplier before armour when the
defender is asleep, or when a Shadowstab attacker is unseen. A successful
Shadowstab removes the attacker's temporary invisibility even when armour
absorbs the physical damage. The ordinary contact message remains for
visible attacks; an unseen attack announces the strike from darkness.

## Ownership

`policy.combat.monster_shadowstab` owns visibility, sleeping-defender checks,
the raw damage multiplier, and ending temporary invisibility. The melee
policy calls it at contact and pre-armour damage phases. The attack-flavour
dispatcher calls it only after a confirmed surviving-defender contact.
The same helper works against player and monster targets, reading live ECS
components and catalog flags. No new saved component or Go handler is needed.

## Verification

Lua tests use the production catalog, actor components, and melee entry
points. They cover unseen forced contact, visible evasion, player and monster
sleep, pre-armour damage, shield priority, invisibility expiry, and zero-
damage contact. Focused Go Lua-rule tests then exercise the full script
runtime. The import and save formats stay unchanged.
