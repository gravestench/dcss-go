# Unique Pacification Effects Design

## Intent

Complete the source consequences of pacifying Pikel, Kirke, Dowan or
Duvessa, and Vault Warden. Reuse the monster and terrain owners that
already implement the corresponding death transitions. These changes
must survive save/restore and must not award nonlethal XP twice.

## Source behavior

`mon-util.cc:mons_pacify` neutralizes Pikel's band, restores Kirke's
transformed hogs, pacifies the other elven twin, and forces terrain
markers sourced by the now-pacified monster to revert. Pikel's band
members disappear in smoke, matching the current death/banishment Lua
owner. Kirke's death owner already restores her marked band and spelled
hogs across generated levels. Dowan or Duvessa cause the still-hostile
other twin to turn neutral and receive its own once-only pacification XP.
This recognizes original monster class after polymorph. Terrain marker
cleanup applies to any pacified caster, including Vault Warden's door
and stair seals. The source also removes those markers after source death.

## Ownership

Elyvilon's pacification owner separates the successful chance roll from
the once-only conversion operation. The conversion path changes real
attitude, awards XP, releases grips, and runs the unique hooks once.
The Pikel and Kirke hooks call their existing owners; neither receives a
second copy of its band transformation. A focused elven-twin lookup owner
finds the matching live twin by current or original class. The
pacification owner converts that twin without another chance roll or HP
healing. Its once-only marker prevents recursion and duplicate XP.

`policy.world.temporary_terrain` owns forced removal of markers from a
specified actor. Pacification and ordinary monster death call that same
operation. The existing expiry system also uses the owner's restore
operation, preserving intervening map edits.

## Verification

Lua `_test.lua` cases cover Pikel's marked band, Kirke's marked hog,
the elven-twin pair including a second attempt, and temporary seals
returning to their prior feature on pacification and death. The Lua twin
test checks both conversions and the correct XP total. A game save test
checks that multiple pacified actors retain their markers, while the
existing Heal Other game test checks nonlethal XP across restore. All
Lua functions explain why and how, and no
Lua line exceeds 120 columns.
