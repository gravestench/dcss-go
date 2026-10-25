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
    wrath_penance = 30,
    piety_mode = modes.ORDINARY,
    wrath_module = "policy.religion.wrath.kikubaaqudgha",
    evil = true,
    piety_decay_chance = 17,
    conduct_module = "policy.religion.conduct.kikubaaqudgha",
    gift_module = "policy.religion.gifts.kikubaaqudgha",
    rejects_innate_caster = true,
}

register.definition(categories.GODS, definition)

return definition
