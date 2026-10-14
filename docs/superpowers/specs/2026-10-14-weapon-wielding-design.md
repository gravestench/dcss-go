# Weapon wielding for the playable Dungeon slice

## Purpose and source rules

After dropping and recovering a weapon, the Fighter must be able to wield it
again. The `w` command also chooses bare hands, so weapon choice remains a
reversible part of play. In the pinned source, `cmd-keys.h:56` binds `w` to
`CMD_WIELD_WEAPON`; `item-use.cc:897-1099` validates the choice before a turn,
uses half of ordinary action time to wield and three tenths to unwield, and
changes the weapon slot only on success. `item-prop.cc:1588-1604,2796-2804`
uses the weapon's minimum one-hand size to refuse a shield-incompatible
weapon. The Go Human/Fighter baseline is 10 aut, so these costs are 5 and 3
aut. Selecting the already wielded weapon or bare hands while already bare
spends no time.

This slice accepts carried `OBJ_WEAPONS` with source-backed weapon properties
in the five currently supported primary melee skill families.
The current scenario only supplies a starting weapon, but the command accepts
another valid carried weapon so it does not hard-code the start identity.
Worn armour and non-weapons are rejected without time. The always-equipped
buckler blocks weapons requiring two hands for a medium-sized Human. Curses,
forms, artefact restrictions, wieldable non-weapons, floor wielding, warning
inscriptions, other weapon skill families, and training changes remain later
domains. An unsupported weapon reports that its combat is unavailable
without spending time.

## Ownership and turn flow

The terminal owns a `w` selection screen. It shows carried weapons with the
same inventory letters as inventory and a `-` bare-hands option. It submits
`CommandWield` with an item entity ID, or ID zero for bare hands. `Game`
validates ownership, class, shield compatibility, and current equipment
before committing aut. An ordered Akara system reads `IntentWield` and records
the pending change and text. At the post-update structural barrier, `Game`
removes the old `Equipped{Slot:"weapon"}` relation and adds it to the selected
carried item, if any. Item state stays in existing Akara components; no new
persistent component or package-global state is introduced.

The combat projection already reads the live equipped item, so the next
attack automatically uses the chosen weapon or unarmed rules. The save
validator must allow any legitimate carried weapon in the slot while still
checking that a chosen starting weapon exists among saved items. Current
equipment, actor deadlines, and RNG continuation survive save/restore.

## Verification

Tests cover drop, pickup, and re-wield; switching to bare hands; selecting a
second valid carried weapon; rejecting non-weapons and a shield-incompatible
two-handed weapon without time; already-selected choices; terminal letters
and cancellation; attack projection and save/restore after equipment changes.
Integrated Go tests, vet, build, style checks, and code review run before the
single category commit and fast-forward to local `main`.
