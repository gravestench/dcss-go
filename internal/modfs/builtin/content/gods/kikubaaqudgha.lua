-- Kikubaaqudgha grants necromantic worship, which an innate caster cannot adopt.
-- Its file registers one stable ID; the resolved catalog can replace this
-- definition from a later mod layer without changing the engine.
local categories = require("constants.catalog")
local gods = require("constants.gods")
local modes = require("constants.god_piety_modes")

local definition = {
    id = gods.KIKUBAAQUDGHA,
    name = "Kikubaaqudgha",
    temple_eligible = true,
    starting_piety = 15,
    piety_mode = modes.ORDINARY,
    rejects_innate_caster = true,
}

register.definition(categories.GODS, definition)

return definition
