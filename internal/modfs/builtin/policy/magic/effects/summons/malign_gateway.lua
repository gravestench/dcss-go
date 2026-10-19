local spells = require("ids.spells")
local component = require("constants.component")
local terrain_ids = require("constants.terrain")
local registry = require("policy.magic.effects.registry")
local summons = require("policy.magic.effects.summons.common")
local terrain = require("policy.magic.effects.summons.terrain")

local spell_id = spells.SPELL_MALIGN_GATEWAY

-- Source allows only one gateway in the dungeon, regardless of whether a
-- player or monster opened it. A pending portal also counts toward the limit.
local function active_gateway(ctx)
    return #ctx:query({ component.SUMMON_GATEWAY }) > 0
end

-- Source: spl-summoning.cc:can_cast_malign_gateway and
-- find_gateway_location. A failed location check aborts before payment.
local spell_effects = {}

-- Example: A monster gateway blocks the player's cast before placement.
-- Reject any existing gateway or absent placement cell before spending resources.
function spell_effects.prepare(ctx, player)
    if active_gateway(ctx) then
        return "You can only sustain one malign gateway at a time."
    end

    if #terrain.gateway_points(ctx, ctx:get(player, component.POSITION)) == 0 then
        return "There is no space for a malign gateway."
    end
end

-- Save the old feature in a marker so gateway expiry can restore the exact cell after opening the portal.
function spell_effects.resolve(ctx, player, _, _, power)
    local position = ctx:get(player, component.POSITION)
    local points = terrain.gateway_points(ctx, position)
    local point = points[summons.roll(ctx, #points) + 1]

    if not point then
        return
    end

    local marker = ctx:create()

    ctx:add(marker, component.SUMMON_GATEWAY, {
        owner = player,
        level_id = position.level_id,
        x = point.x,
        y = point.y,
        original_feature = ctx:cell(position.level_id, point.x, point.y),
        expires_aut = ctx:aut() + 10 * (1 + summons.roll(ctx, 2)),
        power = power,
        phase = 0,
        tentacle_id = 0,
    })
    ctx:set_cell(position.level_id, point.x, point.y, terrain_ids.DNGN_MALIGN_GATEWAY)
    ctx:emit("spell", "The dungeon shakes as a portal opens!")
end

registry.add(spell_id, {
    prepare = spell_effects.prepare,

    resolve = spell_effects.resolve,
})

return spell_effects
