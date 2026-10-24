-- Theory of operation: both Makhleb servant powers use the same source
-- summoning formula. The tier supplies rank, roster, failure tuple, and
-- costs; this owner handles allegiance, finite abjuration, and gear.
local attitudes = require("constants.attitude")
local allies = require("policy.character.allies")
local categories = require("constants.catalog")
local common = require("policy.magic.effects.summons.common")
local component = require("constants.component")
local costs = require("policy.abilities.god_costs")
local factory = require("policy.population.factory")
local gods = require("constants.gods")
local magic_power = require("policy.magic.power")
local roster = require("policy.religion.makhleb.roster")
local skills = require("ids.skills")
local streams = require("constants.rng_streams")

local servant = {}

-- Source fixup hides both powers from a character whose mutation forbids
-- allies; the same check also keeps a stale command from creating one.
function servant.available(ctx, player, rank)
    return costs.available(ctx, player, gods.MAKHLEB, rank) and
        not allies.forbidden(ctx, player)
end

-- A servant is centered on the player and has no free directional prompt.
-- The fixed HP cost still has to be affordable before time is committed.
function servant.prepare(ctx, player, hp)
    if not costs.enough_health(ctx, player, hp) then
        return "You do not have enough health."
    end

    return nil
end

-- Source random_choose preserves the order of each five-demon tier so a
-- deterministic seed maps to the same demon throughout a mod layer.
function servant.choose(ctx, tier)
    local choices = roster[tier]

    return choices[ctx:random(streams.RELIGION, #choices) + 1]
end

-- summon_demon_type draws abjuration degree from power before placement;
-- a blocked cell still leaves the attempted invocation successful.
function servant.summon(ctx, player, tier, friendly)
    local kind_id = servant.choose(ctx, tier)
    local power = 20 + magic_power.training(ctx, player,
        skills.SK_INVOCATIONS, 3)
    local degree = math.min(2 + math.floor(
        ctx:random(streams.RELIGION, power) / 4), 6)
    local attitude = friendly and attitudes.FRIENDLY or
        attitudes.HOSTILE
    local creature = common.spawn(ctx, player, gods.MAKHLEB,
        kind_id, degree, nil, {
        attitude = attitude,
        source_category = categories.GODS,
        stream = streams.RELIGION,
        silent_failure = true,
        silent_hostility = true,
    })

    if not creature then
        ctx:emit("religion", "Nothing happens.")

        return nil
    end

    local position = ctx:get(player, component.POSITION)

    factory.equip_generated(ctx, creature, kind_id, position.level_id)
    ctx:emit("religion", "A demon appears!")

    if not friendly then
        ctx:emit("religion", "It doesn't seem very happy.")
    end

    return creature
end

-- Hostile failure is a successful source action: even a blocked summon
-- pays HP and piety, unlike an ordinary divine failure that only costs time.
function servant.resolve(ctx, player, tier, hp, base_piety,
    fail_base, fail_scale, fail_divisor)
    local failed = costs.failed(ctx, player,
        fail_base, fail_scale, fail_divisor)

    servant.summon(ctx, player, tier, not failed)
    costs.spend_health(ctx, player, hp)
    costs.spend(ctx, player, 0,
        costs.piety_cost(ctx, base_piety))
end

return servant
