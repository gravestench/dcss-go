-- Source: spl-damage.cc:_ignite_poison_monsters, _ignite_poison_clouds,
-- _ignite_poison_bog, and cast_ignite_poison.
local component = require("constants.component")
local catalog = require("policy.catalog")
local damage = require("policy.magic.damage")
local common = require("policy.magic.effects.statuses.common")
local cloud = require("policy.magic.effects.zaps.cloud")
local terrain = require("constants.terrain")
local time = require("constants.time")

local ignite = {}

local function random_divide(ctx, numerator, denominator)
    local quotient = math.floor(numerator / denominator)
    local remainder = numerator % denominator

    if remainder > 0 and ctx:random("spell", denominator) < remainder then
        quotient = quotient + 1
    end

    return quotient
end

local function burn_monster(ctx, monster, definition, power)
    local state = ctx:get(monster, component.PROJECTILE_POISON)

    if not state or state.degree <= 0 then
        return
    end

    local sides = 12 + random_divide(ctx, power * 6, 100)
    local raw = 0

    for _ = 1, state.degree * 2 do
        raw = raw + 1 + ctx:random("spell", sides)
    end

    local amount = damage.monster_elemental(ctx, monster, raw,
        "MR_RES_FIRE")

    if amount <= 0 then
        return
    end

    ctx:emit("spell", "The " .. definition.name ..
        " seems to burn from within!")
    local remaining = damage.apply(ctx, monster, amount)

    if remaining > 0 then
        ctx:remove(monster, component.PROJECTILE_POISON)
    end
end

local function burn_clouds(ctx, origin, power, player)
    for _, entity in ipairs(ctx:query({ component.CLOUD })) do
        local cloud = ctx:get(entity, component.CLOUD)

        if cloud.level_id == origin.level_id and
            (cloud.kind_id == "CLOUD_MEPHITIC" or
                cloud.kind_id == "CLOUD_POISON") and
            common.visible(ctx, origin, cloud) then
            cloud.kind_id = "CLOUD_FIRE"
            cloud.owner = player
            cloud.expires_aut = ctx:aut() + 30 +
                ctx:random("spell", 20 + power)
            ctx:set(entity, component.CLOUD, cloud)
        end
    end
end

local function burn_bogs(ctx, origin, power, player)
    for dy = -common.LOS_RADIUS, common.LOS_RADIUS do
        for dx = -common.LOS_RADIUS, common.LOS_RADIUS do
            local x, y = origin.x + dx, origin.y + dy

            if ctx:cell(origin.level_id, x, y) == terrain.DNGN_TOXIC_BOG and
                ctx:visible(origin.level_id, origin.x, origin.y,
                    common.LOS_RADIUS, x, y) and
                ctx:random("spell", 4) == 0 then
                local bound = math.floor(power / 30)
                local extra = bound > 0 and ctx:random("spell", bound) or 0

                cloud.place(ctx, "CLOUD_FIRE", player, origin.level_id,
                    x, y, (2 + extra) * time.AUT_PER_TURN)
            end
        end
    end
end

function ignite.cast(ctx, player, _, _, power)
    local origin = ctx:get(player, component.POSITION)
    ctx:emit("spell", "You ignite the poison in your surroundings!")
    burn_clouds(ctx, origin, power, player)
    burn_bogs(ctx, origin, power, player)

    for _, monster in ipairs(ctx:query({
        component.ACTOR, component.POSITION, component.HEALTH,
    })) do
        if monster ~= player then
            local position = ctx:get(monster, component.POSITION)
            local health = ctx:get(monster, component.HEALTH)

            if health.current > 0 and
                common.visible(ctx, origin, position) then
                local actor = ctx:get(monster, component.ACTOR)
                burn_monster(ctx, monster,
                    catalog.get("monsters", actor.kind_id), power)
            end
        end
    end
end

return ignite
