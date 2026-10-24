# Ignis wrath design

Ignis tries a shaft first, then anoints a visible monster, then summons
fire elementals. A failed shaft eligibility check or missing champion
target falls through to the next branch. This slice implements all three
branches through their gameplay effects, rather than merely recording a
wrath message.

## Shaft ownership

Lua decides whether the current branch and floor are shaftable and whether
Mountain Boots resist the fall. A successful shaft keeps the source message
and consumes the wrath branch even when the boots prevent travel. Otherwise
Lua records a typed pending shaft request. The Go session transport owner
stages any missing destination floor, asks Lua for a safe landing, and commits
the level transition. The destination depth uses Crawl's one to three
floor rule, bounded by the branch bottom. The action consumes its request
after successful travel. A destination error restores the pre-action card
state, generated floors, and RNG.

## Champion ownership

Lua selects among visible hostile monsters using the source guards and
highest HD with reservoir sampling among ties. Anointment alerts the
chosen monster. Anointed monsters receive a saved ECS marker. While
present, that marker makes their first melee
attack use the Fire flavour, reduces movement energy to two thirds, and
reveals them even when invisible. The effect is permanent and disappears
with the actor. Normal melee, energy, visibility, and save owners read the
marker; Ignis's wrath handler only chooses the target and applies it.

## Verification

Lua scenarios pin branch order, shaft eligibility and boots, champion
selection and tie draws, Fire on first attack, faster movement, elemental
fallback, and failure fallthrough. Game scenarios verify staged Dungeon
travel, save and restore of the champion marker, and rollback of a failed
destination. A checked-in text snapshot shows the resulting D:1–D:3
maps and their stair connections. Run related Lua and Go tests and an
integrated build once, then commit and push the complete category.
