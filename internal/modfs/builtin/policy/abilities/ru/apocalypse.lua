-- Theory of operation: one paid invocation visits every visible nonfriendly
-- monster in source radius order. Each target receives one source effect roll,
-- damage, then a continuing enchantment only if it survives the damage.
local abilities = require("ids.abilities")
local attitudes = require("constants.attitude")
local catalog = require("policy.catalog")
local component = require("constants.component")
local costs = require("policy.abilities.god_costs")
local drain = require("policy.combat.player_drain")
local enfeeble = require("policy.magic.effects.statuses.enfeeble")
local exhaustion = require("policy.character.exhaustion")
local flags = require("constants.monster_flags")
local gods = require("constants.gods")
local health = require("policy.combat.monster_health")
local noise = require("policy.world.noise")
local paralysis = require("policy.magic.effects.zaps.paralysis")
local powers = require("constants.ru_powers")
local registry = require("policy.abilities.registry")
local radius_order = require("policy.world.radius_order")
local roll = require("policy.combat.roll")
local slow = require("policy.combat.monster_slow")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")
local vision = require("policy.character.vision")

local apocalypse = {}

-- Keep source projectile and firewood traits with monster definitions.
local function has_flag(definition, wanted)
    for _, id in ipairs(definition.flags or {}) do
        if id == wanted then
            return true
        end
    end

    return false
end

-- The source's firewood test suppresses status effects on inert bodies.
local function firewood(definition)
    return has_flag(definition, flags.STATIONARY) and
        has_flag(definition, flags.NO_THREAT)
end

-- Only visible, live, nonfriendly, nonprojectile monsters take part.
function apocalypse.targets(ctx, player)
    local origin = ctx:get(player, component.POSITION)
    local sight = vision.radius(ctx, player)
    local result = {}

    for _, monster in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        if monster ~= player and
            targets.attitude(ctx, monster) ~= attitudes.FRIENDLY then
            local position = ctx:get(monster, component.POSITION)
            local current = ctx:get(monster, component.HEALTH)
            local actor = ctx:get(monster, component.ACTOR)
            local definition = catalog.get("monsters", actor.kind_id)
            local distance = math.max(
                math.abs(position.x - origin.x),
                math.abs(position.y - origin.y))

            if current.current > 0 and
                position.level_id == origin.level_id and
                distance <= sight and
                not has_flag(definition, flags.PROJECTILE) and
                ctx:visible_no_trans(origin.level_id,
                    origin.x, origin.y, sight,
                    position.x, position.y) then
                result[#result + 1] = {
                    entity = monster,
                    x = position.x,
                    y = position.y,
                    id = ctx:id(monster),
                    definition = definition,
                }
            end
        end
    end

    table.sort(result, function(left, right)
        return radius_order.before(origin, left, right)
    end)

    return result
end

-- Rank five and a clear exhaustion status make the power available.
function apocalypse.available(ctx, player)
    return costs.available(ctx, player, gods.RU,
        powers.APOCALYPSE_RANK) and
        not exhaustion.active(ctx, player)
end

-- The source warns before an empty cast. Declining that question is free.
function apocalypse.prepare(ctx, player, input)
    if not costs.enough_magic(ctx, player,
        powers.APOCALYPSE_MAGIC_COST) then
        return "You do not have enough magic."
    end

    if #apocalypse.targets(ctx, player) == 0 and
        not input.forced then
        return {
            confirmation = "There are no visible enemies. " ..
                "Unleash your apocalypse anyway?",
            confirmation_id = abilities.RU_APOCALYPSE,
        }
    end
end

-- Apply the previously selected source effect only to a living target.
local function enchant(ctx, target, definition, effect, duration_aut)
    if effect == powers.APOCALYPSE_ANTIMAGIC then
        enfeeble.apply_fixed_antimagic(ctx, target,
            duration_aut)
    elseif effect == powers.APOCALYPSE_PARALYSIS then
        paralysis.apply_fixed(ctx, target, duration_aut)
    elseif effect == powers.APOCALYPSE_SLOW then
        slow.apply(ctx, target, definition,
            duration_aut, streams.RELIGION)
    end
end

-- The effect roll precedes damage, while its duration draw occurs only for
-- a usable enchantment. Firewood always takes the damage-only branch.
local function strike(ctx, player, target, piety, level)
    local monster = target.entity
    local definition = target.definition
    local effect = ctx:random(streams.RELIGION,
        powers.APOCALYPSE_EFFECTS)
    local duration_aut = 0
    local dice_count = powers.APOCALYPSE_DAMAGE_DICE

    if firewood(definition) then
        effect = powers.APOCALYPSE_DAMAGE_ONLY
    elseif effect == powers.APOCALYPSE_ANTIMAGIC then
        if enfeeble.antimagic_susceptible(ctx, monster) then
            duration_aut = powers.APOCALYPSE_ANTIMAGIC_BASE_AUT +
                ctx:random(streams.RELIGION,
                    powers.APOCALYPSE_ANTIMAGIC_SPAN_AUT)
            dice_count = powers.APOCALYPSE_ANTIMAGIC_DICE
        else
            effect = powers.APOCALYPSE_PARALYSIS
        end
    end

    if effect == powers.APOCALYPSE_PARALYSIS then
        duration_aut = powers.APOCALYPSE_PARALYSIS_BASE_AUT +
            ctx:random(streams.RELIGION,
                powers.APOCALYPSE_PARALYSIS_SPAN_AUT)
        dice_count = powers.APOCALYPSE_PARALYSIS_DICE
    elseif effect == powers.APOCALYPSE_SLOW then
        duration_aut = powers.APOCALYPSE_SLOW_BASE_AUT +
            ctx:random(streams.RELIGION,
                powers.APOCALYPSE_SLOW_SPAN_AUT)
        dice_count = powers.APOCALYPSE_SLOW_DICE
    end

    local sides = 1 + roll.random_divide(ctx,
        piety * (54 + level),
        powers.APOCALYPSE_DIE_DIVISOR,
        streams.RELIGION)
    local amount = powers.APOCALYPSE_BASE_DAMAGE +
        roll.dice(ctx, streams.RELIGION,
            dice_count, sides)

    health.damage(ctx, monster, amount, player)

    local remaining = ctx:get(monster, component.HEALTH)

    if remaining and remaining.current > 0 and
        effect ~= powers.APOCALYPSE_DAMAGE_ONLY then
        enchant(ctx, monster, definition, effect, duration_aut)
    end
end

-- One noisy reveal damages every current visible target, then pays the
-- drain, MP, and 30–49 turn exhaustion once for the whole invocation.
function apocalypse.resolve(ctx, player)
    local origin = ctx:get(player, component.POSITION)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local progress = ctx:get(player, component.PROGRESSION)

    ctx:emit("religion",
        "You reveal the great annihilating truth to your foes!")
    noise.emit(ctx, origin, powers.APOCALYPSE_NOISE, player)

    for _, target in ipairs(apocalypse.targets(ctx, player)) do
        strike(ctx, player, target, worship.piety, progress.level)
    end

    drain.apply(ctx, player,
        powers.APOCALYPSE_DRAIN_POWER, streams.RELIGION)
    costs.spend(ctx, player,
        powers.APOCALYPSE_MAGIC_COST, 0)
    exhaustion.apply(ctx, player,
        powers.APOCALYPSE_EXHAUST_TURNS +
        ctx:random(streams.RELIGION,
            powers.APOCALYPSE_EXHAUST_SPAN))
end

-- The ability menu previews the same live sight radius as the area effect.
function apocalypse.range(_, ctx, player)
    return vision.radius(ctx, player)
end

registry.add(abilities.RU_APOCALYPSE, {
    name = "Apocalypse",
    range = apocalypse.range,
    available = apocalypse.available,
    prepare = apocalypse.prepare,
    resolve = apocalypse.resolve,
})

return apocalypse
