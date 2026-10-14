# Ball python constriction on the playable Dungeon floors

## Goal

Admit the source's D:1–2 ball python to generated Dungeon population with
its bite, second grab attack, sustained constriction, escape, XP, corpse,
and save behavior. Existing monsters and the fixed population scenario keep
their current roster and combat results. Human, Hill Orc, Deep Elf, and
Minotaur Fighters can all encounter and escape the same source mechanic.

## Source and scope

Pinned C++ revision: `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.

- `mon-pick-data.h:67` gives ball pythons flat weight 1000 on D:1–4.
- `mon-data.h:4383-4395` gives HD 1, average HP 3.5, EV 11, speed 12,
  XP modifier 13, a plain 3-damage bite, and a 1-damage `AT_CONSTRICT` /
  `AF_CRUSH` second attack. It has no spells or equipment and leaves a corpse.
- `melee-attack.cc:177-188,2838-2854,3586-3591` skips a grab when the
  target is already constricted or cannot be held. A successful grab starts
  constriction; the grab attack itself has zero immediate damage.
- `actor.cc:557-580,683-692,715-825`, `mon-act.cc:2162-2169` require
  adjacency and apply a constrictor's damage after its action, including the
  grab action. Damage uses the source AC and speed scaling, and releases
  automatically when the constrictor dies or adjacency ends.
- `player.cc:6124-6136,7520-7558`, `movement.cc:1109` apply a 3 EV
  penalty while constricted. A movement command attempts escape with
  accumulating attempts; failure spends the action without moving. A
  success releases the grip, slows the constrictor by five energy points,
  and continues movement.
- `status.cc:409-424` calls the damaging status `Constr`.

The current game has one player defender and no monster-on-monster combat.
Only ball pythons can establish direct constriction in this slice. The
map is floor and wall terrain; amphibious swimming behavior has no special
tile to act on yet.

## Ownership

The committed catalog owns the ball python's immutable definition and
Dungeon weight. A single optional Akara `Constricted` component on the
player owns the constrictor entity and escape-attempt count. The live
constrictor's kind, speed, position, and health remain in its existing ECS
components; no duplicate link is stored on the monster. Combat creates the
grip after an eligible landed second attack. A focused constriction system
handles post-monster-action damage and release. The player movement path
calls a pure escape rule before it moves. The player defense projection
reads the component for the live EV penalty. The read model exposes the
status; the terminal renders it. Save and restore persist the link and
counter and reject impossible or dangling links.

The ordinary natural-melee resolver must share hit, shield, and dodge phases
between bite and grab without making the grab consume bite damage or AC
rolls. No parallel combat implementation or compatibility wrapper is added.

## Turn and release rules

A python attempts its normal bite first, then attempts a grab if the player
is alive, adjacent, and not already constricted. A landed grab emits the
source grab message and attaches the component. The post-action
constriction phase applies its ongoing damage on that same monster action.
Subsequent python actions apply damage while the live actors remain adjacent.
The player can attack, wait, use supported items, or try to move while held.
Only movement rolls for escape; a failed roll spends its normal action.
Successful escape clears the component before movement and removes five
constrictor energy points, reducing its next-action readiness. A dead
python, a dead player, or separation clears the component at the action
boundary. Source-shaped messages and
`Constr` status reflect attachment and release.

## Verification

Source-backed catalog and population tests cover ball-python HP, speed,
attack order, XP, and generated D:1 eligibility. Scripted attack rolls prove
that bite and grab use the expected phases, grab damage starts only in the
post-action phase, and an already held player cannot be grabbed again.
Tests cover held EV, two-sided escape outcomes, increasing escape attempts,
post-action damage, release on death/separation, save continuation, malformed
save rejection, and visible terminal status. Run the full suite, vet, build,
style gate, and diff check once for the category before its single commit.
