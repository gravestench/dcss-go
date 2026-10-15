local component = require("constants.component")
local zap_ids = require("policy.magic.effects.zaps.ids")
local catalog = require("policy.catalog")
local poison = require("policy.combat.monster_poison")
local resistance = require("policy.combat.player_resistance")
local roll = require("policy.combat.roll")
local monster_stats = require("policy.combat.monster_stats")

local mephitic = {}

local function monster_duration(ctx, target, actor, definition)
    -- mon-ench.cc:ENCH_CONFUSION falls back to its speed/HD duration when
    -- cloud.cc applies BEAM_CONFUSION with enchant power zero.
    local speed = math.max(1, math.min(100, actor.speed))
    local hd = monster_stats.hit_dice(ctx, target, definition)
    local modded = math.max(1, math.floor((hd + 5) * 10 / speed))
    local centiturns = math.max(3, math.floor(100 / modded))
    local raw = centiturns * roll.random_divide(ctx, 100, speed)
    local low = math.floor(60 * raw / 100)
    local high = math.floor(40 * raw / 100)

    return math.max(15, raw + roll.average_two(ctx, "spell",
        low + high + 1) - low)
end

function mephitic.apply(ctx, target)
    if target == ctx:player() then
        if resistance.poison(ctx, target) > 0 or
            resistance.clarity(ctx, target) then
            return
        end

        local progression = ctx:get(target, component.PROGRESSION)

        if 1 + ctx:random("spell", 27) < progression.level then
            return
        end

        local amount = (2 + ctx:random("spell", 2)) * 10
        local state = ctx:get(target, zap_ids.component.PLAYER_CONFUSION)

        if state then
            state.remaining_aut = math.min(400,
                state.remaining_aut + amount)
            ctx:set(target, zap_ids.component.PLAYER_CONFUSION, state)
        else
            ctx:add(target, zap_ids.component.PLAYER_CONFUSION, {
                remaining_aut = amount,
            })
        end

        ctx:emit("spell", "You choke on the stench!")
        return
    end

    local actor = ctx:get(target, component.ACTOR)
    local health = ctx:get(target, component.HEALTH)

    if not actor or not health or health.current <= 0 then
        return
    end

    local definition = catalog.get("monsters", actor.kind_id)

    if poison.resistance(definition) > 0 then
        return
    end

    -- cloud.cc:_mephitic_cloud_roll. High-HD monsters retain a 1/50 chance.
    local hd = monster_stats.hit_dice(ctx, target, definition)
    local affected

    if hd >= 21 then
        affected = ctx:random("spell", 50) == 0
    else
        affected = ctx:random("spell", 21) >= hd
    end

    if not affected then
        return
    end

    local duration = monster_duration(ctx, target, actor, definition)
    local state = ctx:get(target, component.MONSTER_CONFUSION)

    if state then
        state.remaining_aut = state.remaining_aut + duration
        ctx:set(target, component.MONSTER_CONFUSION, state)
    else
        ctx:add(target, component.MONSTER_CONFUSION, {
            remaining_aut = duration,
        })
    end

    ctx:emit("spell", "The " .. definition.name .. " appears confused.")
end

return mephitic
