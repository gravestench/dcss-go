-- Source ranged-attack.cc gives chaos ammunition a fresh post-hit ego.
-- The ordered weighted bands are combat rules, not content load order;
-- every shot draws again so the saved item stays branded Chaos.
local catalog = require("policy.catalog")
local component = require("constants.component")
local fiery = require("policy.monsters.fiery")
local holiness = require("constants.monster_holiness")
local missile_egos = require("constants.missile_egos")
local monster_ids = require("ids.monsters")
local streams = require("constants.rng_streams")

local chaos = {}

local choices = {
    { id = missile_egos.FLAME, weight = 10 },
    { id = missile_egos.FROST, weight = 10 },
    { id = missile_egos.POISONED, weight = 10 },
    { id = missile_egos.CHAOS, weight = 10 },
    { id = missile_egos.BLINDING, weight = 10 },
    { id = missile_egos.FRENZY, weight = 5 },
    { id = missile_egos.CURARE, weight = 2 },
    { id = missile_egos.DISPERSAL, weight = 2 },
}

local icy = {
    [monster_ids.MONS_ICE_BEAST] = true,
    [monster_ids.MONS_SIMULACRUM] = true,
    [monster_ids.MONS_ICE_STATUE] = true,
    [monster_ids.MONS_BLOCK_OF_ICE] = true,
    [monster_ids.MONS_NARGUN] = true,
}

-- Some source immunities are species traits, while others are saved
-- statuses. An absent defender is useful to inspect the pure source bands.
local function susceptible(ctx, defender, id)
    if not defender then
        return true
    end

    if ctx:has(defender, component.PLAYER) then
        if id == missile_egos.FRENZY then
            local rage = require("policy.character.rage")

            return rage.can_begin(ctx, defender)
        end

        return true
    end

    local actor = ctx:get(defender, component.ACTOR)
    local definition = actor and catalog.get("monsters", actor.kind_id)

    if not definition then
        return true
    end

    if id == missile_egos.FLAME then
        return not fiery.is(definition.id)
    end

    if id == missile_egos.FROST then
        return not icy[definition.id]
    end

    if id == missile_egos.POISONED or id == missile_egos.FRENZY then
        for _, kind in ipairs(definition.holiness or {}) do
            if kind == holiness.UNDEAD or
                id == missile_egos.FRENZY and
                    kind == holiness.NONLIVING then
                return false
            end
        end
    end

    if id == missile_egos.FRENZY then
        local allegiance = require(
            "policy.magic.effects.statuses.monster_allegiance")

        return not allegiance.frenzied(ctx, defender)
    end

    if id == missile_egos.DISPERSAL then
        local status = require("policy.combat.monster_hexes.status")

        return not status.anchored(ctx, defender)
    end

    return true
end

-- The source may reroll a clashing ego, but a one-in-three check permits
-- it anyway. This prevents a resistant target from consuming an unbounded
-- loop while keeping its ordinary chaos distribution.
function chaos.choose(ctx, defender)
    for _ = 1, 100 do
        local draw = ctx:random(streams.MELEE, 59)
        local chosen

        for _, choice in ipairs(choices) do
            draw = draw - choice.weight

            if draw < 0 then
                chosen = choice.id
                break
            end
        end

        if ctx:random(streams.MELEE, 3) == 0 or
            susceptible(ctx, defender, chosen) then
            return chosen
        end
    end

    return missile_egos.CHAOS
end

return chaos
