-- Pyroclastic Surge uses Bolt of Fire's zap damage at each eligible body.
-- Its source makes the strike automatic and starts each beam at its
-- victim's own cell, so the spell policy selects bodies beside lava.
-- Source: mon-cast.cc:_setup_pyroclastic_surge and spl-zap.cc.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local base = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_BOLT_OF_FIRE)
local definition = {}

-- Copy the source zap formula from its one catalog owner. A mod that
-- changes Bolt of Fire's zap will affect this shared zap as well.
for key, value in pairs(base) do
    definition[key] = value
end

definition.id = spells.SPELL_PYROCLASTIC_SURGE
definition.name = "flame surge"
definition.monster_tohit = {
    kind = "tohit",
    args = {
        "AUTOMATIC_HIT",
    },
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
