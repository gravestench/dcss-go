-- Divine Vigour is a player-owned timed percentage bonus. Every max HP/MP
-- formula reads this state, while this owner changes and expires it. That
-- keeps level gains, transformations, training, and save checks aligned.
local component = require("constants.component")
local forms = require("policy.magic.effects.forms.player")
local gods = require("constants.gods")
local power = require("policy.magic.power")
local resources = require("policy.character.resources")
local roll = require("policy.combat.roll")
local skills = require("ids.skills")
local streams = require("constants.rng_streams")

local vigour = {}

-- Only a positive clock contributes the saved source amount to formulas.
function vigour.amount(ctx, player)
    local state = ctx:get(player, component.ELYVILON_VIGOUR)

    return state and state.remaining_aut > 0 and state.amount or 0
end

-- After storing the bonus, refresh HP through the shared form/rage
-- resource path, then scale current MP up with the source ceiling rule.
function vigour.invoke(ctx, player)
    if vigour.amount(ctx, player) > 0 then
        error("Divine Vigour is already active")
    end

    local invocation = power.training(ctx, player,
        skills.SK_INVOCATIONS, 1)
    local amount = 1 + roll.random_divide(ctx, invocation,
        3, streams.RELIGION)
    local duration_skill = power.training(ctx, player,
        skills.SK_INVOCATIONS, 5)
    local turns = 40 + roll.random_divide(ctx, duration_skill,
        2, streams.RELIGION)
    local magic = ctx:get(player, component.MAGIC)
    local old_max = magic.max
    local old_current = magic.current

    ctx:add(player, component.ELYVILON_VIGOUR, {
        amount = amount,
        remaining_aut = turns * 10,
    })
    forms.rescale_health(ctx, player, forms.max_hp(ctx, player))
    resources.refresh_mp(ctx, player)
    magic = ctx:get(player, component.MAGIC)

    if old_max > 0 then
        magic.current = math.min(magic.max,
            math.ceil(magic.max * old_current / old_max))
    end

    ctx:set(player, component.MAGIC, magic)
    ctx:emit("religion", "Elyvilon grants you divine vigour.")
end

-- Clearing the component before recalculation removes the exact saved
-- percentage; the shared resource owners preserve proportional HP and
-- clamp MP if the old current pool exceeds its reduced maximum.
function vigour.clear(ctx, player)
    if not ctx:has(player, component.ELYVILON_VIGOUR) then
        return false
    end

    ctx:remove(player, component.ELYVILON_VIGOUR)
    forms.rescale_health(ctx, player, forms.max_hp(ctx, player))
    resources.refresh_mp(ctx, player)
    ctx:emit("duration", "Your divine vigour fades away.")

    return true
end

-- Active-player aut ages the boon once per committed action, including
-- long actions that pass its final turn in a single step.
function vigour.tick(ctx, player, aut)
    local state = ctx:get(player, component.ELYVILON_VIGOUR)

    if not state or aut <= 0 then
        return
    end

    state.remaining_aut = state.remaining_aut - aut

    if state.remaining_aut <= 0 then
        vigour.clear(ctx, player)
    else
        ctx:set(player, component.ELYVILON_VIGOUR, state)
    end
end

-- Restore rejects orphan or expired boons and boons belonging to a
-- different patron, because formulas would otherwise trust forged maxima.
function vigour.validate(ctx, player)
    for _, entity in ipairs(ctx:query({ component.ELYVILON_VIGOUR })) do
        local state = ctx:get(entity, component.ELYVILON_VIGOUR)
        local worship = ctx:get(entity, component.RELIGION_WORSHIP)

        if entity ~= player or not worship or
            worship.god_id ~= gods.ELYVILON or
            (worship.penance[gods.ELYVILON] or 0) > 0 or
            state.amount < 1 or state.amount > 30 or
            state.remaining_aut < 1 or state.remaining_aut > 4000 then
            error("invalid Elyvilon Divine Vigour state")
        end
    end
end

return vigour
