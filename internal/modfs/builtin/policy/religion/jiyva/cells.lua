-- Source KPROP no_jiyva protects cells from Jiyva's jelly ecology. The
-- saved vault records already own each transformed source cell, while the
-- Slime Pit seal markers own that map's one-time exception after release.
local effects = require("constants.vault_effects")
local names = require("constants.slime_pit")
local properties = require("constants.vault_properties")
local seals = require("policy.world.slime_seals")

local cells = {}

-- Read the effective KPROP at this live coordinate. A Slime:5 property
-- stops blocking after that vault's own saved fixup; another map's KPROP
-- remains protected even when Slime:5 opens elsewhere on the level.
function cells.allowed(ctx, level_id, x, y)
    for _, record in ipairs(ctx:records_at(level_id, x, y)) do
        if record.kind == effects.PROPERTY and
            record.identity == properties.NO_JIYVA and
            not record.overridden then
            if record.source_id ~= names.MAP_ID or
                not seals.opened(ctx, level_id) then
                return false
            end
        end
    end

    return true
end

return cells
