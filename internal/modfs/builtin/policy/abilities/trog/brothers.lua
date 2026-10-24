-- Theory of operation: Brothers in Arms chooses one source power band,
-- creates a real friendly Trog-sourced monster, then lets the monster's
-- action-based Berserk timer govern its short life.
local abilities = require("ids.abilities")
local attitudes = require("constants.attitude")
local allegiance = require("policy.magic.effects.statuses.monster_allegiance")
local allies = require("policy.character.allies")
local categories = require("constants.catalog")
local common = require("policy.magic.effects.summons.common")
local component = require("constants.component")
local costs = require("policy.abilities.god_costs")
local factory = require("policy.population.factory")
local gods = require("constants.gods")
local roster = require("policy.religion.trog.brothers_roster")
local registry = require("policy.abilities.registry")
local streams = require("constants.rng_streams")

local brothers = {}

-- Trog's fourth star is useless to a character forbidden from having
-- allies; source fixup hides the power in that state.
function brothers.available(ctx, player)
    return costs.available(ctx, player, gods.TROG, 4) and
        not allies.forbidden(ctx, player)
end

-- Placement is centered on the player and has no separate target prompt.
function brothers.prepare()
    return nil
end

-- The same source roster is imported by save validation, so a selected
-- actor cannot become an unrecognized god gift after restore.
brothers.kind = roster.pick

-- Source draws a nominal abjuration duration before selecting a kind,
-- then replaces that timer with the monster's extended berserk lifetime.
function brothers.summon(ctx, player)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local quarter = math.floor(worship.piety / 4)
    local power = worship.piety +
        ctx:random(streams.RELIGION, quarter) -
        ctx:random(streams.RELIGION, quarter)

    ctx:random(streams.RELIGION, power)

    local kind_id = brothers.kind(ctx, power)
    local creature = common.spawn(ctx, player, gods.TROG, kind_id, 0,
        nil, {
        source_category = categories.GODS,
        stream = streams.RELIGION,
        silent_failure = true,
    })

    if not creature then
        ctx:emit("religion", "Nothing happens.")

        return nil
    end

    local position = ctx:get(player, component.POSITION)

    factory.equip_generated(ctx, creature, kind_id, position.level_id)
    allegiance.start_berserk(ctx, creature, streams.RELIGION)

    local state = ctx:get(creature, component.MONSTER_ALLEGIANCE)
    local summon = ctx:get(creature, component.SUMMON)

    state.frenzy_aut = math.floor(state.frenzy_aut * 3 / 2)
    -- Zero marks the source-specific monster-action clock, not a permanent
    -- gift. The summon expiry system dismisses this actor as frenzy ends.
    summon.expires_aut = 0
    ctx:set(creature, component.MONSTER_ALLEGIANCE, state)
    ctx:set(creature, component.SUMMON, summon)

    return creature
end

-- Only temporary player-owned Trog summons vanish on loss of favor;
-- permanent god-origin monsters and unrelated summons keep their owner.
function brothers.dismiss(ctx, player)
    for _, creature in ipairs(ctx:query({ component.SUMMON })) do
        local summon = ctx:get(creature, component.SUMMON)

        if summon.owner == player and
            summon.source_category == categories.GODS and
            summon.source_id == gods.TROG and
            summon.attitude == attitudes.FRIENDLY then
            common.expire(ctx, creature)
        end
    end
end

-- A failed invocation spends time only. A successful, blocked summon
-- still pays Trog's source five-point generic piety cost.
function brothers.resolve(ctx, player)
    if costs.failed(ctx, player, 160, 0, 1) then
        ctx:emit("religion", "You fail to use your ability.")

        return
    end

    brothers.summon(ctx, player)
    costs.spend(ctx, player, 0, costs.piety_cost(ctx, 5))
end

registry.add(abilities.TROG_BROTHERS_IN_ARMS, {
    name = "Brothers in Arms",
    available = brothers.available,
    prepare = brothers.prepare,
    resolve = brothers.resolve,
})

return brothers
