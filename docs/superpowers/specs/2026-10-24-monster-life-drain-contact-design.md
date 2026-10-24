# Monster Life and Magic Draining Contacts

## Intent

Complete the source monster melee flavours that drain life, speed, stats,
or magic: Drain, Drain Stat, Vampiric, Scarab, Pain, and Antimagic. These
are ordinary effects of a resolved contact, including contacts against
other monsters. The mutable outcomes remain on the existing health, magic,
drain, slow, and antimagic ECS components.

## Source behavior

`AF_DRAIN_STAT` is an abstract catalog flavour. `mons_attack_spec` chooses
Strength, Intelligence, or Dexterity on each contact before the existing
stat-drain chance. `AF_DRAIN` has an outer one-in-two gate; its shared drain
routine has another one-in-two skip for monster victims before it checks
their holiness. Living players and
monsters receive their appropriate temporary drain status and then take
negative-energy adjusted bonus damage. Complete negative-energy resistance
prevents drain.

`AF_VAMPIRIC` can heal an attacker after a damaging contact with a
susceptible natural or plant victim. Unlike a vampiric weapon, the natural
attack has no two-in-five veto. The heal amount is one plus a draw below
physical damage, adjusted by the victim's negative-energy resistance.
The amount draw occurs even when the attacker is already at full health.
`AF_SCARAB` first attempts the existing three-in-five speed drain, then
continues into the same vampiric effect. `AF_PAIN` makes independent
Necromancy skill rolls for activation and negative-energy damage.
`AF_ANTIMAGIC` uses attacker HD times twelve as its magic-drain power,
rather than the weapon brand's damage-times-eight power. A ghost moth
regains the MP it drains from a player.

All these flavours require a confirmed contact with positive physical
damage. A dead defender receives no further flavour. The normal weapon
brand, if present, remains a separate effect of that attack.

## Ownership

The attack sequence resolves abstract Drain Stat per contact. A focused
Lua life-drain policy handles the contact effects and uses the existing
status and damage owners. The main flavour dispatcher maps named source IDs
to those functions. This adds no Go content branch, save field, or Lua
global state.

## Verification

Use production ECS schemas and Lua rule tests for player and monster
victims, resistance, healed HP, magic loss, ghost-moth healing, Scarab
fallthrough, per-contact stat selection, and miss/zero-damage gates. Include
the live melee path for one source monster. Run related script and game
checks at the category boundary, review the diff, commit, and push.
