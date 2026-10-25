# Implement ordinary timed divine wrath

1. Add a Lua test under `internal/script/testdata/lua/tests` for the XP
   threshold, active-god roster, god-time draw order, no-penance clearing,
   finite queue, Nemelex punishment, conversion timeout, and a zero-penance
   Wrath card. Watch the new cases fail before adding each rule.
2. Add `wrath_xp_remaining` and `wrath_count` to the existing worship schema
   and validate both on restore. Implement the focused Lua timer and expose
   active-god selection from the existing retribution module. Call it from
   credited XP and from god-time before ordinary piety maintenance. Route
   Nemelex to the existing Punishment catalog and start newly active good
   wrath after a patron conversion.
3. Add a game save/restore test for a queued event. Compare the resumed
   game with an uninterrupted game after the next god-time firing.
4. Run the new Lua test and game scenario, relevant religion tests, builds,
   formatting/style checks, then commit and push this one domain category.

The large complete test suite currently exceeds Go's default 10-minute
per-package timeout in several packages. Use scoped integrated tests for
this category, and report any remaining broad-suite limit honestly.
