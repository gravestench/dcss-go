-- Source: item-use.cc:SCR_TORMENT and spl-goditem.cc:torment.
-- The scroll supplies an entry point and message channel; the shared area
-- owner now handles both scroll and monster Symbol of Torment victims.
local area = require("policy.combat.torment_area")
local channels = require("constants.message_channels")
local item_ids = require("ids.items")
local scrolls = require("policy.scrolls")
local conduct = require("policy.religion.conduct")
local kinds = require("constants.religion_conduct")

local effect = {}

-- Torment needs no menu because its radius is centered on the reader.
function effect.prepare()
    return nil
end

-- Example: effect.apply(ctx, reader) torments the reader and each visible
-- susceptible monster, using their current resistance and HP components.
function effect.apply(ctx, reader, request)
    area.apply(ctx, reader, channels.READ)

    -- Source conduct follows the Torment effect, using knowledge from
    -- before the scroll identified itself through reading.
    conduct.record(ctx, {
        id = kinds.EVIL,
        level = 10,
        known = request and request.known == true,
    })
end

scrolls.register(item_ids.SCR_TORMENT, effect)

return effect
