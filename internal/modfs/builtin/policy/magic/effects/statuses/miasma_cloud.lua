-- Corpse rot and mutation retaliation use the same world-cloud placement.
local placement = require("policy.clouds.placement")
local ids = require("ids.clouds")

local miasma = {}

-- Example: A cell with any cloud returns occupied, so miasma will not replace it.
-- Ask the shared cloud grid before placement so rot cannot overwrite a cloud from another source.
function miasma.occupied(ctx, level_id, x, y)
    return placement.at(ctx, level_id, x, y) ~= nil
end

-- Avoid replacing an existing cloud or placing miasma on impassable terrain.
function miasma.available(ctx, level_id, x, y)
    return ctx:walkable(level_id, x, y) and
        not miasma.occupied(ctx, level_id, x, y)
end

-- Reject zero-life clouds and preserve the caster as source for later attribution.
function miasma.place(ctx, level_id, x, y, duration_aut, source)
    if duration_aut <= 0 or
        not miasma.available(ctx, level_id, x, y) then
        return nil
    end

    return placement.place(ctx, ids.CLOUD_MIASMA,
        source or ctx:player(), level_id, x, y, duration_aut)
end

return miasma
