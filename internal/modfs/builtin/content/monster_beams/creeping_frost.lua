-- Creeping Frost uses Flash Freeze's ice zap at every eligible foe beside
-- a visible wall. The spell's policy supplies its automatic-hit adjustment
-- and does not grant Flash Freeze's repeated-hit immunity.
local accuracy = require("constants.beam_accuracy")
local categories = require("constants.catalog")
local spells = require("ids.spells")

-- Explicitly load the shared zap so content file discovery order cannot
-- change this spell's definition or registration behavior.
local base = require("content.monster_beams.flash_freeze")
local definition = {}

-- Copy before adjusting the spell-specific hit rule; mods can replace
-- either profile without changing the other's contact behavior.
for key, value in pairs(base) do
    definition[key] = value
end

definition.id = spells.SPELL_CREEPING_FROST
definition.name = "frost"
definition.monster_tohit = {
    kind = "tohit",
    args = {
        accuracy.AUTOMATIC_HIT,
    },
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
