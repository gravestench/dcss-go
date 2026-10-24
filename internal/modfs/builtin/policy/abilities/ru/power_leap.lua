-- Theory of operation: the player chooses one cell within three squares.
-- Target checks are free; the committed action first struggles against a
-- constrictor, then lands and damages adjacent foes if the cell stays open.
local abilities = require("ids.abilities")
local attitudes = require("constants.attitude")
local barbs = require("policy.combat.barbs")
local catalog = require("policy.catalog")
local component = require("constants.component")
local costs = require("policy.abilities.god_costs")
local exhaustion = require("policy.character.exhaustion")
local fear = require("policy.character.player_fear")
local flags = require("constants.monster_flags")
local forms = require("policy.magic.effects.forms.player")
local gods = require("constants.gods")
local health = require("policy.combat.monster_health")
local mesmerism = require("policy.character.player_mesmerism")
local movement = require("policy.abilities.movement")
local noise = require("policy.world.noise")
local registry = require("policy.abilities.registry")
local roll = require("policy.combat.roll")
local powers = require("constants.ru_powers")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")
local terrain = require("constants.terrain")
local water = require("policy.character.water")
local flight = require("policy.combat.flight")

local leap = {}

-- Check a catalog flag by ID rather than by monster name or roster order.
local function has_flag(definition, wanted)
    for _, id in ipairs(definition.flags or {}) do
        if id == wanted then
            return true
        end
    end

    return false
end

-- The source grants the power at four stars and rejects any exhaustion.
function leap.available(ctx, player)
    return costs.available(ctx, player, gods.RU,
        powers.LEAP_RANK) and
        not exhaustion.active(ctx, player)
end

-- Reject bad cells before an ability intent exists, including open seas
-- and dangerous landings the current body cannot survive.
function leap.prepare(ctx, player, input)
    if not costs.enough_magic(ctx, player,
        powers.LEAP_MAGIC_COST) then
        return "You do not have enough magic."
    end

    if forms.nervous(ctx, player) then
        return "You are too terrified to leap around!"
    end

    local origin = ctx:get(player, component.POSITION)
    local dx = input.dx or 0
    local dy = input.dy or 0

    if dx == 0 and dy == 0 then
        return "Okay, then."
    end

    if math.max(math.abs(dx), math.abs(dy)) >
        powers.LEAP_RANGE then
        return "That's out of range!"
    end

    local x = origin.x + dx
    local y = origin.y + dy
    local destination = {
        level_id = origin.level_id,
        x = x,
        y = y,
    }

    if mesmerism.blocked(ctx, player, origin, destination) then
        return "You cannot leap away from your beholder!"
    end

    if fear.blocked(ctx, player, origin, destination) then
        return "You cannot leap closer to your fearmonger!"
    end

    if not ctx:visible_no_trans(origin.level_id, origin.x,
        origin.y, powers.LEAP_RANGE, x, y) then
        return "Something is in the way."
    end

    if ctx:actor_at(origin.level_id, x, y) then
        return "You can't leap on top of the monster!"
    end

    local feature = ctx:cell(origin.level_id, x, y)

    if feature == terrain.DNGN_OPEN_SEA or
        feature == terrain.DNGN_LAVA_SEA then
        return "You can't leap into the sea!"
    end

    if feature == terrain.DNGN_LAVA and
        not flight.active(ctx, player) then
        return "You cannot leap into lava."
    end

    if feature == terrain.DNGN_DEEP_WATER and
        not flight.active(ctx, player) and
        not water.can_swim(ctx, player) then
        return "You cannot leap into deep water."
    end

    if not ctx:walkable(origin.level_id, x, y) then
        return "You cannot leap there."
    end
end

-- DCSS adjacent_iterator visits center, northwest, west, southwest,
-- south, southeast, east, northeast, then north. Preserve that order so
-- each foe receives the same RNG draw regardless of ECS registration.
local adjacent = {
    { 0, 0 },
    { -1, -1 },
    { -1, 0 },
    { -1, 1 },
    { 0, 1 },
    { 1, 1 },
    { 1, 0 },
    { 1, -1 },
    { 0, -1 },
}

-- Each eligible foe receives its own source damage roll.
local function strike_neighbors(ctx, player, position, piety, level)
    for _, offset in ipairs(adjacent) do
        local x = position.x + offset[1]
        local y = position.y + offset[2]
        local foe = ctx:actor_at(position.level_id, x, y)

        if foe and foe ~= player and
            targets.attitude(ctx, foe) ~= attitudes.FRIENDLY then
            local actor = ctx:get(foe, component.ACTOR)
            local definition = catalog.get("monsters", actor.kind_id)
            local current = ctx:get(foe, component.HEALTH)

            if current and current.current > 0 and
                not has_flag(definition, flags.PROJECTILE) then
                local dice_count = 1 + roll.random_divide(ctx,
                    piety * (54 + level),
                    powers.LEAP_DIE_DIVISOR, streams.RELIGION)
                local damage = roll.dice(ctx, streams.RELIGION,
                    dice_count, powers.LEAP_DIE_SIDES)

                health.damage(ctx, foe, damage, player)
            end
        end
    end
end

-- Failure to escape or a newly blocked landing still spends MP and the
-- exhaustion cost; an invalid aim was rejected earlier without an intent.
function leap.resolve(ctx, player, intent, elapsed_aut)
    local origin = ctx:get(player, component.POSITION)
    local x = origin.x + intent.dx
    local y = origin.y + intent.dy
    local escaped = movement.escape_grasp(ctx, player, 2)

    if escaped then
        if ctx:solid(origin.level_id, x, y) or
            ctx:actor_at(origin.level_id, x, y) then
            ctx:emit("religion",
                "Something unexpectedly blocked your leap!")
        else
            ctx:move_actor(player, origin.level_id, x, y)
            barbs.moved(ctx, player, elapsed_aut)

            local worship = ctx:get(player,
                component.RELIGION_WORSHIP)
            local progress = ctx:get(player, component.PROGRESSION)
            local landing = ctx:get(player, component.POSITION)

            noise.emit(ctx, landing, powers.LEAP_NOISE, player)
            strike_neighbors(ctx, player, landing,
                worship.piety, progress.level)
        end
    end

    costs.spend(ctx, player, powers.LEAP_MAGIC_COST, 0)
    exhaustion.apply(ctx, player,
        powers.LEAP_EXHAUST_TURNS +
        ctx:random(streams.RELIGION,
            powers.LEAP_EXHAUST_SPAN))
end

-- The targeting cursor shows the same fixed range as the preflight rule.
function leap.range()
    return powers.LEAP_RANGE
end

registry.add(abilities.RU_POWER_LEAP, {
    name = "Power Leap",
    range = leap.range,
    available = leap.available,
    prepare = leap.prepare,
    resolve = leap.resolve,
})

return leap
