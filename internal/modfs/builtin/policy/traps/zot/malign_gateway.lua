-- Source: traps.cc:zot_effects[9], find_gateway_location.
local categories = require("constants.catalog")
local component = require("constants.component")
local ids = require("ids.traps")
local streams = require("constants.rng_streams")
local terrain_ids = require("constants.terrain")
local terrain = require("policy.magic.effects.summons.terrain")

local effect = {}

-- Open a portal only at a legal gateway cell and save a marker for later expiry.
-- Example: effect.apply(ctx, player) opens a gateway and stores its summoning marker.
function effect.apply(ctx, player)
    local position = ctx:get(player, component.POSITION)
    local points = terrain.gateway_points(ctx, position)

    if #points == 0 then
        return
    end

    local point = points[ctx:random(streams.TRAPS, #points) + 1]
    local marker = ctx:create()

    ctx:add(marker, component.SUMMON_GATEWAY, {
        owner = player,
        level_id = position.level_id,
        x = point.x,
        y = point.y,
        original_feature = ctx:cell(position.level_id, point.x, point.y),
        expires_aut = ctx:aut() + 10,
        power = 150,
        phase = 0,
        tentacle_id = 0,
        source_category = categories.TRAPS,
        source_id = ids.TRAP_ZOT,
        hostile = true,
    })
    ctx:set_cell(position.level_id, point.x, point.y,
        terrain_ids.DNGN_MALIGN_GATEWAY)
    ctx:emit("trap", "The dungeon shakes as a portal opens!")
end

return effect
