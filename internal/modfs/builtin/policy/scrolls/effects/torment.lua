-- Source: item-use.cc:SCR_TORMENT and spl-goditem.cc:torment.
-- The scroll supplies an entry point and message channel; the shared area
-- owner now handles both scroll and monster Symbol of Torment victims.
local area = require("policy.combat.torment_area")
local channels = require("constants.message_channels")
local item_ids = require("ids.items")
local scrolls = require("policy.scrolls")

local effect = {}

-- Torment needs no menu because its radius is centered on the reader.
function effect.prepare()
    return nil
end

-- Example: effect.apply(ctx, reader) torments the reader and each visible
-- susceptible monster, using their current resistance and HP components.
function effect.apply(ctx, reader)
    area.apply(ctx, reader, channels.READ)
end

scrolls.register(item_ids.SCR_TORMENT, effect)

return effect
