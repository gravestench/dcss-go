-- Source: spl-selfench.cc:cast_corpse_rot, mon-death.cc:_corpse_rot,
-- and cloud.cc:CLOUD_MIASMA.
local time = require("constants.time")
local component = require("constants.component")
local death_hooks = require("policy.combat.death_hooks")
local miasma = require("policy.magic.effects.statuses.miasma_cloud")
local common = require("policy.magic.effects.statuses.common")

local rot = {}

local function random_divide(ctx, numerator, denominator)
    local quotient = math.floor(numerator / denominator)
    local remainder = numerator % denominator

    if remainder > 0 and ctx:random("spell", denominator) < remainder then
        quotient = quotient + 1
    end

    return quotient
end

function rot.cast(ctx, player, _, _, power)
    local state = ctx:get(player, component.AREA_STATUS) or {
        corpse_rot_aut = 0,
        corpse_rot_power = 0,
        toxic_radiance_aut = 0,
        toxic_radiance_power = 0,
        noxious_bog_aut = 0,
    }
    local bound = 1 + random_divide(ctx, power * 3, 5)
    local added = 10 + ctx:random("spell", bound)

    state.corpse_rot_aut = math.min(500,
        state.corpse_rot_aut + added * time.AUT_PER_TURN)
    state.corpse_rot_power = power

    if ctx:has(player, component.AREA_STATUS) then
        ctx:set(player, component.AREA_STATUS, state)
    else
        ctx:add(player, component.AREA_STATUS, state)
    end

    ctx:emit("spell", "You radiate decay.")
end

local function place(ctx, origin, x, y)
    if not miasma.available(ctx, origin.level_id, x, y) then
        return false
    end

    local duration = 2 + math.floor((ctx:random("spell", 8) +
        ctx:random("spell", 9)) / 2)

    return miasma.place(ctx, origin.level_id, x, y,
        duration * time.AUT_PER_TURN) ~= nil
end

-- Called by actor.death after the victim has left the map.
function rot.on_death(ctx, monster, definition, position)
    local player = ctx:player()
    local state = ctx:get(player, component.AREA_STATUS)

    if not state or state.corpse_rot_aut <= 0 or
        not definition.leaves_corpse or
        ctx:has(monster, component.SUMMON) then
        return false
    end

    local origin = ctx:get(player, component.POSITION)

    if not common.visible(ctx, origin, position) then
        return false
    end

    local limit = 1 + ctx:random("spell", 1 +
        random_divide(ctx, state.corpse_rot_power, 25))

    for radius = 1, 2 do
        for dy = -radius, radius do
            for dx = -radius, radius do
                if math.max(math.abs(dx), math.abs(dy)) == radius and
                    place(ctx, origin, origin.x + dx, origin.y + dy) then
                    limit = limit - 1

                    if limit == 0 then
                        return false
                    end
                end
            end
        end
    end

    ctx:emit("spell", "You smell decay.")
    return false
end

death_hooks.add("magic.status.corpse_rot", rot.on_death)

return rot
