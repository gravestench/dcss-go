-- Degeneration visits visible threatening enemies once. Its tier changes
-- the chance of mutation, while the monster's current hit dice resist the
-- effect. Transformable bodies seek a weaker form and then malmutate;
-- other bodies become dazed for a saved tier-dependent duration.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local flags = require("constants.monster_flags")
local malmutation = require("policy.monsters.malmutation")
local monster_stats = require("policy.combat.monster_stats")
local nearby = require("policy.religion.cards.effects.nearby")
local polymorph = require("policy.magic.effects.statuses.polymorph")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")

local degen = {}

degen.uses_tier = true

-- No-threat catalog bodies cannot count as useful Degen targets even when
-- their current allegiance is hostile to the player.
local function threatening(definition)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == flags.NO_THREAT then
            return false
        end
    end

    return true
end

-- Reuse the ordinary daze field instead of inventing a card-only status.
-- Its existing action system and save validator then govern expiry.
local function daze(ctx, monster, definition, tier)
    local duration = (5 + 5 * tier) * 10
    local status = ctx:get(monster, component.MONSTER_ENFEEBLE)
    local existed = status ~= nil

    status = status or {
        weak_aut = 0,
        antimagic_aut = 0,
        blind_aut = 0,
        dazed_aut = 0,
    }
    status.dazed_aut = math.max(status.dazed_aut, duration)

    if existed then
        ctx:set(monster, component.MONSTER_ENFEEBLE, status)
    else
        ctx:add(monster, component.MONSTER_ENFEEBLE, status)
    end

    ctx:emit("religion", "The " .. definition.name ..
        " is dazed by the mutagenic energy.")
end

-- Resolve the source chance against current HD before checking whether
-- the body can polymorph. A successful roll counts as an effect even when
-- the transformation owner finds no legal weaker species.
function degen.apply(ctx, player, request)
    local tier = request.tier

    if type(tier) ~= "number" or tier % 1 ~= 0 or
        tier < 0 or tier > 2 then
        error("Degen requires a source power tier")
    end

    local affected = 0

    for _, candidate in ipairs(nearby.monsters(ctx, player)) do
        local monster = candidate.entity
        local definition = candidate.definition

        if targets.enemy(ctx, player, monster) and
            threatening(definition) then
            local chance = (tier + 1) * 5 +
                ctx:random(streams.CARDS, 5)
            local hd = monster_stats.hit_dice(ctx, monster, definition)

            if chance >= hd or
                ctx:random(streams.CARDS, hd) < chance then
                if polymorph.can_actor(ctx, monster) then
                    polymorph.less(ctx, monster, definition,
                        streams.CARDS)

                    local actor = ctx:get(monster, component.ACTOR)
                    local current = catalog.get(categories.MONSTERS,
                        actor.kind_id)

                    malmutation.apply(ctx, monster, current,
                        streams.CARDS)
                else
                    daze(ctx, monster, definition, tier)
                end

                affected = affected + 1
            end
        end
    end

    if affected == 0 then
        ctx:emit("religion", "Nothing happens.")
    end
end

return degen
