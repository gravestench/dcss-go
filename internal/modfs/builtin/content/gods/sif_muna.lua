-- Sif Muna governs learned magic; the innate-caster mutation prevents worship.
-- Its file registers one stable ID; the resolved catalog can replace this
-- definition from a later mod layer without changing the engine.
local categories = require("constants.catalog")
local gods = require("constants.gods")
local modes = require("constants.god_piety_modes")

local definition = {
    id = gods.SIF_MUNA,
    name = "Sif Muna",
    temple_eligible = true,
    starting_piety = 15,
    wrath_penance = 30,
    piety_mode = modes.ORDINARY,
    piety_decay_chance = 17,
    conduct_module = "policy.religion.conduct.sif_muna",
    gift_module = "policy.religion.gifts.sif_muna",
    behavior_module = "policy.religion.gods.sif_muna",
    rejects_innate_caster = true,
}

register.definition(categories.GODS, definition)

return definition
