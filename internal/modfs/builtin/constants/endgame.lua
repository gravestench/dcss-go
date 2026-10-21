-- The saved player chapter uses stable names instead of numbered C++ enum
-- values. Other Lua rules import these names when deciding whether the
-- Orb run has started or a Dungeon exit has ended play.
return {
    EXPLORING = "exploring",
    ESCAPING = "escaping",
    WON = "won",
    LEFT = "left",
}
