# Divine kill recovery design

## Intent

Complete the kill-triggered HP and MP passives for Makhleb, Vehumet, and
The Shining One in the Lua game rules. A modded god or monster definition
should be able to change the relevant traits without Go dispatch.

## Source behavior

The pinned `mon-death.cc` grants recovery only for a credited, XP-giving,
non-object kill. Kill conduct happens first, so a newly gained piety point
may satisfy the recovery threshold. A worshipper under penance cannot get
divine recovery. Otherwise a draw in `[0, piety)` must reach the first-star
threshold of 30. Makhleb restores HP based on the victim's original HD;
Vehumet restores MP. The Shining One restores both only when the victim is
evil. A formerly neutral victim grants no XP or recovery unless frenzy
overrides that exclusion. Existing mutation reactions also follow kill
conduct in source, and Devour and divine HP gains share one message.

## Design

The existing actor-death system retains credit, XP, and corpse ownership.
After its conduct events are recorded, a Lua kill aftermath owner runs the
existing mutation effects followed by one focused divine recovery policy.
The policy reads worship and live monster traits. It does not store a
recovery flag or duplicate monster facts on the player. Dynamic victim HD
comes from the existing monster stats owner without temporary drain.

Each god definition names a focused `kill_recovery_module` with an
`amounts(ctx, victim, definition)` method. The shared owner contains no
god-specific formula or ID dispatch; a mod can add or replace a formula
through its effective god definition and Lua policy file.

The shared conduct classifier determines evil identity for both TSO sight
conduct and this death reaction. Conjured actors and the source's named
object kinds cannot trigger divine healing even if a custom definition
awards them XP. Death's Door blocks HP but does not block MP recovery.
Messages appear only when the corresponding pool actually increases.

## Verification

Focused Lua tests pin Makhleb, Vehumet, TSO, piety threshold, penance,
evil classification, object exclusion, cap behavior, and Death's Door.
The actor-death integration test verifies that conduct runs before the
threshold draw, former neutral XP is suppressed, frenzy restores XP, and
combined healing announces once. Tests run once at the category boundary
with the build.
