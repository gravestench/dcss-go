-- Reading Fog uses the shared cloud placement rule. The scroll owns its
-- reading message and spell RNG stream, while Xom may invoke the same
-- smoke behavior without pretending a scroll was consumed.
local cloud_fog = require("policy.clouds.fog")
local item_ids = require("ids.items")
local scrolls = require("policy.scrolls")
local streams = require("constants.rng_streams")

local effect = {}

-- Fog has no target choice; placement and colour wait until execution.
function effect.prepare()
    return nil
end

-- Share source cloud geometry and duration rolls with other Fog producers.
function effect.apply(ctx, player)
    cloud_fog.place(ctx, player, streams.SPELL)
    ctx:emit("read", "The scroll dissolves into smoke.")
end

scrolls.register(item_ids.SCR_FOG, effect)

return effect
