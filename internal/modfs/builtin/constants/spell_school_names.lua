-- DCSS random-book database keys use these displayed school names. Keep
-- spelling separate from the saved lowercase spell-school IDs.
local schools = require("constants.spell_schools")

local names = {
    [schools.AIR] = "Air",
    [schools.CONJURATION] = "Conjuration",
    [schools.EARTH] = "Earth",
    [schools.FIRE] = "Fire",
    [schools.HEXES] = "Hexes",
    [schools.ICE] = "Ice",
    [schools.NECROMANCY] = "Necromancy",
    [schools.POISON] = "Poison",
    [schools.SUMMONING] = "Summoning",
    [schools.TRANSLOCATION] = "Translocation",
    [schools.TRANSMUTATION] = "Transmutation",
}

return names
