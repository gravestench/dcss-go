local armour = require("policy.magic.armour")
local catalog = require("policy.catalog")
local power = require("policy.magic.power")
local mutation_effects = require("policy.mutations.effects.registry")
local mutation_capabilities = require("constants.mutation_capabilities")
local player_attributes = require("policy.character.attributes")
local forms = require("policy.magic.effects.forms.player")
local statuses = require("policy.magic.effects.statuses.player")
local jewellery_effects = require("policy.inventory.jewellery_effects")
local jewellery_capabilities = require("constants.jewellery_capabilities")

local failure = {}

local difficulty = {
    [0] = 0,
    3,
    15,
    35,
    70,
    100,
    150,
    200,
    260,
    340,
}

local function divide(numerator, denominator)
    -- C++ integer division truncates toward zero. Lua's floor does not.
    local quotient = numerator / denominator

    if quotient < 0 then
        return math.ceil(quotient)
    end

    return math.floor(quotient)
end

local function tetrahedral(n)
    return divide(n * (n + 1) * (n + 2), 6)
end

-- Source: spl-cast.cc:raw_spell_fail. Power has already been computed at
-- scale six without intelligence or the spellpower cap.
function failure.raw(input)
    local level = input.spell_level
    local spell_difficulty = difficulty[level]

    if not spell_difficulty then
        error("invalid spell difficulty " .. tostring(level))
    end

    local chance = 60 - input.power6 - 2 * input.intelligence +
        input.armour_penalty + spell_difficulty

    chance = math.min(chance, 210)

    local numerator = (((chance + 426) * chance + 82670) * chance + 7245398)
    local raw = math.max(0, divide(numerator, 262144))

    raw = raw + (input.form_penalty or 0)
    raw = raw + (input.mutation_adjustment or 0)

    if input.vertigo then
        raw = raw + 7
    end

    local fail_reduce = 100

    if input.vehumet then
        fail_reduce = divide(fail_reduce * 2, 3)
    end

    local wizardry = input.wizardry or 0

    if wizardry > 0 then
        fail_reduce = divide(fail_reduce * 6, 7 + wizardry)
    end

    raw = divide(raw * math.max(50, fail_reduce), 100)

    return math.min(100, math.max(0, raw))
end

-- Source: spl-cast.cc:_get_true_fail_rate and failure_rate_to_int.
-- The display percentage is the probability that three averaged draws
-- fall strictly below the raw threshold; it is not the raw threshold.
function failure.percent(raw)
    if raw <= 0 then
        return 0
    end

    if raw >= 100 then
        return divide(raw + 100, 2)
    end

    local outcomes = 101 * 101 * 100
    local target = raw * 3
    local failures

    if target <= 100 then
        failures = tetrahedral(target)
    elseif target <= 200 then
        failures = tetrahedral(target) -
            2 * tetrahedral(target - 101) -
            tetrahedral(target - 100)
    else
        failures = outcomes - tetrahedral(300 - target)
    end

    return math.max(1, divide(100 * failures, outcomes))
end

-- Source: random2avg(100, 3) used by spl-cast.cc:your_spells.
-- random2avg draws 0..99 first, then two 0..100 values. Keep that order
-- even though the displayed probability is invariant under permutation.
function failure.roll(ctx, raw)
    local sum = ctx:random("spell", 100) +
        ctx:random("spell", 101) +
        ctx:random("spell", 101)

    return divide(sum, 3) < raw
end

function failure.profile(ctx, player, spell)
    local character = ctx:get(player, "core.player")
    local attributes = player_attributes.current(ctx, player)

    if not character or not attributes then
        error("player lacks spell failure state")
    end

    local raw = failure.raw({
        power6 = power.failure(ctx, player, spell),
        intelligence = attributes.intelligence,
        armour_penalty = armour.spell_penalty(ctx, player),
        form_penalty = forms.modifiers(ctx, player).spell_penalty,
        spell_level = spell.level,
        mutation_adjustment = mutation_effects.sum(ctx, player,
            mutation_capabilities.SPELL_FAILURE_ADJUSTMENT),
        wizardry = jewellery_effects.sum(ctx, player,
            jewellery_capabilities.WIZARDRY),
        vertigo = statuses.vertigo_active(ctx, player),
    })

    return {
        raw = raw,
        percent = failure.percent(raw),
    }
end

function failure.run_formula(_, input)
    local raw = failure.raw(input)

    return {
        raw = raw,
        percent = failure.percent(raw),
    }
end

register.policy({
    id = "magic.failure_formula",
    run = failure.run_formula,
})

function failure.run_spell(ctx, input)
    local spell = catalog.get("spells", input.spell_id)

    return failure.profile(ctx, ctx:player(), spell)
end

register.policy({
    id = "magic.spell_failure",
    run = failure.run_spell,
})

return failure
