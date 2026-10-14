# Active-floor scheduling implementation

1. Add failing game tests for frozen off-floor deadlines, a return with one
   ordinary monster action, and restore of a saved inactive floor. Keep a
   corruption test for a past deadline on the active floor.
2. Make `TurnScheduler` read `Position` and choose only active-floor actors.
   Remove off-floor no-op actions and reject an off-floor AI invocation.
3. Activate a destination level once after stair travel. Apply existing
   corpse catch-up, then clamp overdue monster deadlines to the current aut.
4. Scope save clock validation to active actors, update the port inventory and
   ownership roadmap, and verify the full category before one commit.
