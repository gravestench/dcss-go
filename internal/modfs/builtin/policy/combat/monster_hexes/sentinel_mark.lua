local component = require("constants.component")
local mark_policy = require("policy.traps.mark")
local streams = require("constants.rng_streams")

local mark = {}

-- Source: beam.cc:ench_flavour_affects_monster excludes monster targets.
function mark.viable(ctx, _, defender)
    return ctx:has(defender, component.PLAYER)
end

-- Example: mark.apply(ctx, nil, defender) with player defender -> mark status from monster-spell stream
-- Mark the contacted defender so nearby monsters can track its position after the beam resolves.
function mark.apply(ctx, _, defender)
    mark_policy.apply(ctx, defender, streams.MONSTER_SPELL)
end

return mark
