-- Theory of operation: final surviving HP loss may cause Ru to punish its
-- living monster source. Piety determines the chance, and damage minus
-- current monster HD determines which saved enchantment the monster gains.
local catalog = require("policy.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local gods = require("constants.gods")
local order = require("constants.damage_reaction_order")
local piety = require("policy.religion.piety")
local powers = require("constants.ru_powers")
local reactions = require("policy.combat.player_damage_reactions")
local roll = require("policy.combat.roll")
local streams = require("constants.rng_streams")
local stats = require("policy.combat.monster_stats")
local enfeeble = require("policy.magic.effects.statuses.enfeeble")
local enchant = require("policy.combat.monster_enchant")
local hex_status = require("policy.combat.monster_hexes.status")
local paralysis = require("policy.magic.effects.zaps.paralysis")
local slow = require("policy.combat.monster_slow")

local retaliation = {}

-- The source's Ru passives require live worship, no Ru penance, and the
-- two-star rank. Read all three at hit time so no stale passive is saved.
local function active(ctx, player)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    return worship and worship.god_id == gods.RU and
        (worship.penance[gods.RU] or 0) == 0 and
        piety.rank(gods.RU, worship.piety) >=
            powers.RETALIATION_RANK and worship or nil
end

-- An exact division consumes no rounding draw. Otherwise source
-- div_rand_round draws once before the one-in-N chance test.
local function chance(ctx, worship)
    local denominator = roll.random_divide(ctx,
        powers.RETALIATION_CHANCE_NUMERATOR,
        worship.piety, streams.RELIGION)

    return roll.draw(ctx, streams.RELIGION,
        denominator) == 0
end

-- Current HD includes draining and other live modifiers. This roll is
-- made only after Ru's chance succeeds and a valid monster remains.
local function strength(ctx, worship, monster, definition, damage)
    local bound = roll.random_divide(ctx,
        worship.piety * powers.RETALIATION_POWER_MULTIPLIER,
        powers.RETALIATION_POWER_DIVISOR, streams.RELIGION)
    local random_power = roll.draw(ctx, streams.RELIGION, bound)
    local hd = stats.hit_dice(ctx, monster, definition)

    return math.max(0, random_power + damage -
        powers.RETALIATION_HD_PENALTY * hd)
end

-- Keep each branch's duration draw in the source order. Unsusceptible
-- monsters continue to the next lower effect without drawing a duration.
local function punish(ctx, monster, definition, power)
    if power > powers.RETALIATION_ANTIMAGIC_THRESHOLD and
        enfeeble.antimagic_susceptible(ctx, monster) then
        local duration = power + roll.draw(ctx, streams.RELIGION,
            powers.RETALIATION_ANTIMAGIC_SPAN_AUT)

        enfeeble.apply_fixed_antimagic(ctx, monster, duration)
        ctx:emit(channels.RELIGION, "You focus your inner power and drain the " ..
            definition.name .. "'s magic in retribution!")

        return
    end

    if power > powers.RETALIATION_PARALYSIS_THRESHOLD then
        local duration = power + roll.draw(ctx, streams.RELIGION,
            powers.RETALIATION_PARALYSIS_SPAN_AUT)

        paralysis.apply_fixed(ctx, monster, duration)
        ctx:emit(channels.RELIGION, "You focus your inner power and paralyse the " ..
            definition.name .. " in retribution!")

        return
    end

    if power > powers.RETALIATION_SLOW_THRESHOLD then
        local duration = power + roll.draw(ctx, streams.RELIGION,
            powers.RETALIATION_SLOW_SPAN_AUT)

        slow.apply(ctx, monster, definition,
            duration, streams.RELIGION)
        ctx:emit(channels.RELIGION, "You focus your inner power and slow the " ..
            definition.name .. " in retribution!")

        return
    end

    if power > powers.RETALIATION_BLIND_THRESHOLD and
        enchant.can_blind(definition) then
        local duration = power + roll.draw(ctx, streams.RELIGION,
            powers.RETALIATION_BLIND_SPAN_AUT)

        if enchant.apply_fixed_blind(ctx, monster,
            definition, duration) then
            ctx:emit(channels.RELIGION, "You focus your inner power and blind the " ..
                definition.name .. " in retribution!")

            return
        end
    end

    if power > 0 then
        local duration = power + roll.draw(ctx, streams.RELIGION,
            powers.RETALIATION_CORONA_SPAN_AUT)

        hex_status.corona(ctx, monster, duration)
        ctx:emit(channels.RELIGION, "You focus your inner power and illuminate the " ..
            definition.name .. " in retribution!")
    end
end

-- Source ouch.cc tests Ru's chance before resolving the saved monster ID.
-- A missing or dead source consumes that chance but gains no enchantment.
function retaliation.on_damage(ctx, player, damage, _, monster)
    local worship = active(ctx, player)

    if not worship or damage <= 0 or not chance(ctx, worship) then
        return
    end

    local health = monster and ctx:get(monster, component.HEALTH)
    local actor = monster and ctx:get(monster, component.ACTOR)

    if monster == player or not health or health.current <= 0 or
        not actor then
        return
    end

    local definition = catalog.get("monsters", actor.kind_id)
    local power = strength(ctx, worship, monster,
        definition, damage)

    punish(ctx, monster, definition, power)
end

-- Register by stable reaction ID so Lua load order cannot move this
-- between deterioration and the source's summon/fog consequences.
function retaliation.register()
    reactions.add("religion.ru.retaliation",
        order.RU_RETALIATION, retaliation.on_damage)
end

return retaliation
