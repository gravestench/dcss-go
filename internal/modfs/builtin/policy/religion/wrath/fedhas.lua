-- Fedhas's three source outcomes require corpse placement, a god avatar,
-- or radius-ring planting before they can resolve faithfully.
local component = require("constants.component")
local gods = require("constants.gods")
local streams = require("constants.rng_streams")

local fedhas = {}

-- Current worship limits Fedhas to spores and nature spells. All three
-- outcomes need generic placement or god-avatar owners, so preserve the
-- source draw and stop at the selected missing mechanic.
function fedhas.apply(ctx, player)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local options = worship.god_id == gods.FEDHAS and 2 or 3
    local choice = ctx:random(streams.CARDS, options)

    if choice == 0 then
        error("unimplemented Fedhas corpse-spore placement wrath")
    elseif choice == 1 then
        error("unimplemented Fedhas nature spell avatar wrath")
    end

    error("unimplemented Fedhas radius-ring plant placement wrath")
end

return fedhas
