# Monster forced movement

Roll and Throw Ally now resolve through the ordinary monster spell intent.
Both rules live in Lua and use the existing Akara actor components and world
movement owner.

Roll adds a saved rolling status only when a boulder beetle has a distant foe
and a legal step that closes the gap. While rolling, it cannot choose another
spell. Movement leaves dust; its next natural melee attack uses the source
hit type and doubles base damage. Rolling also lowers movement energy by
five. Contact, blocked movement, incapacity, or
duration expiry removes the status. Save and restore preserve the remaining
duration, and a continuation test checks that the restored actor makes the
same next decision.

Throw Ally chooses an adjacent aligned ally allowed by the thrower's kind:
Robin throws goblins, Polyphemus throws yaks, and the Iron Giant throws
nonconjured allies. The landing is empty, habitable, visible along a solid
line, adjacent to the foe, and at least two cells from the thrower. A legal
cast relocates the ally, deals the source HD-scaled impact after armour,
triggers landing traps, and wakes the ally. The resolver rechecks actor
positions when the saved
spell intent executes, so a stale target cannot redirect a throw.

Wind Blast remains a separate area displacement rule. It will need a
cone-wide actor and cloud pass, size-scaled push distance, alternate paths,
and collision damage; the two spells here do not introduce a partial Wind
Blast implementation.
