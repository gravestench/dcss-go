# Monster-target weapon brands

## Intent

Any melee attacker that hits a monster must resolve its weapon brand through
the same Lua effect file. This includes the player, ordinary monsters,
special summoned bodies, and a player illusion carrying its saved ghost
brand. The defender's dynamic monster profile remains authoritative for
resistance and holiness. The design keeps one effect file per brand and a
small dispatcher; it does not add another content-ID switch.

## Ownership

Rename `policy.combat.player_brands` to
`policy.combat.monster_target_brands`. Its modules already own effects on
monster defenders and remain the single brand implementation for that
target class. `policy.combat.brands` continues to own effects on the player.
The attacking melee owner supplies an envelope with attacker, defender,
defender definition, weapon identity, actual base damage, current health,
visible names, and player kill credit. The brand policy applies effects;
the melee owner orders them after the ordinary strike.

The target-specific dispatcher loads `monster_target_brands/<brand>.lua`
by brand ID. Unknown brands fail at content validation or the attack
boundary. Normal, Speed, Protection, and Spectral retain their explicit
no-contact-effect files. The Spectral follow-up remains a player-weapon
after-attack rule; monster melee does not invoke it.

## Source rules and integration

Follow the pinned `attack.cc::apply_damage_brand` ordering: first the
physical strike, then the brand effect; brand-specific gates decide whether
zero damage or a newly dead defender can still be affected. Elemental
bonuses use the defender's live resistance, and life/negative-energy
effects use the same dynamic profile as player melee. Monster-target
messages name the actual attacker instead of claiming the player's weapon
struck. Pain derives Necromancy skill from the attacking player or monster
as appropriate. The shared damage helper sends player kill credit only
when the attacker's side is credited.

Ordinary `melee_actions.monster_target` invokes the brand once after a hit.
`summon_melee.attack` invokes it for each successful strike, including a
saved player illusion with no carried weapon. A blocked or missed strike
never applies a brand. Relocation effects leave later contact logic to
the owning effect file. The player path continues to call the same modules.

## Verification

Lua rule tests cover fire/cold/electric resistance, venom, pain, draining,
vampirism, zero-damage and lethal gates, player kill credit, ordinary
monster attack dispatch, summoned attack dispatch, and the saved illusion
brand. Existing player brand tests must remain green. A live game test
covers a branded monster attacking another monster and save/restore if the
effect stores state. Run the category's tests, build, style check, and diff
check before one commit, then merge and push `main`.
