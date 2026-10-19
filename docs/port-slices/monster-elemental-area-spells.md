# Monster elemental area spells

Call Down Lightning and Creeping Frost now resolve from their existing
monster spellbooks. Both use source zap profiles registered as committed Lua
content. The monster resolver remains a separate Lua module, so a mod can
replace one spell without editing a central dispatch switch.

Call Down Lightning needs a visible foe at least three cells away. It starts
the Lightning Bolt contact at that foe, so actors in between are not hit.
The foe still rolls evasion against electrical damage. The source gives this
spell 16 power per monster spell HD instead of Lightning Bolt's ordinary 12.

Creeping Frost needs its selected foe beside a wall that the caster can see.
On resolution it scans every visible actor and strikes each unaligned actor
beside a visible wall. That includes neutral bystanders but spares aligned
monsters. Its Flash Freeze zap hits automatically. Existing frozen players
can take another hit; only a newly struck player gains the frozen condition.
The source does not apply that condition to monsters hit by Creeping Frost.

The Lua rule test checks targeting, profile identity, power scaling,
unaligned bystanders, automatic accuracy, and repeated-hit behavior. The
full Lua-rule package and all-package Go compile checks ran at this slice
boundary.
