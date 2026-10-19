-- Call Down Lightning reuses the Lightning Bolt zap's monster damage and
-- accuracy. Its spell policy starts that zap at the selected foe's cell;
-- this profile does not make the electrical strike automatic.
local categories = require("constants.catalog")
local spells = require("ids.spells")

-- Explicitly load the source zap because alphabetical auto-discovery reaches
-- this spell before Lightning Bolt. The module cache prevents a second load.
local base = require("content.monster_beams.lightning_bolt")
local definition = {}

-- Copy the shared zap without mutating its original catalog entry. A mod
-- can still override this spell's metadata independently of Lightning Bolt.
for key, value in pairs(base) do
    definition[key] = value
end

definition.id = spells.SPELL_CALL_DOWN_LIGHTNING
definition.name = base.name
-- mon-cast.cc:mons_power_for_hd gives this spell sixteen power per HD,
-- rather than Lightning Bolt's ordinary twelve.
definition.power_hd_factor = 16

register.definition(categories.MONSTER_BEAMS, definition)

return definition
