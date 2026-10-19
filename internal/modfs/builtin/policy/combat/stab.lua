-- Source: fight.cc:find_stab_type and attack.cc:player_stab.
-- The player attack owner asks for a stab after contact rolls but before
-- applying damage; all condition and bonus rules stay here.
local capabilities = require("constants.mutation_capabilities")
local catalog = require("policy.catalog")
local component = require("constants.component")
local flags = require("constants.monster_flags")
local mutations = require("ids.mutations")
local confusion = require("policy.magic.player_confusion")
local effects = require("policy.mutations.effects.registry")
local roll = require("policy.combat.roll")
local senses = require("policy.character.senses")

local stab = {}

-- Absent monster flags do not imply an immunity or special stab state.
local function has_flag(definition, wanted)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- Only perceived visible targets get a stab opening; line of sight alone is insufficient.
local function visible(ctx, player, target)
    local origin = ctx:get(player, component.POSITION)
    local position = ctx:get(target, component.POSITION)

    if not origin or not position or
        origin.level_id ~= position.level_id then
        return false
    end

    local line_of_sight = ctx:visible(origin.level_id, origin.x, origin.y,
        7, position.x, position.y)

    return senses.perceive(ctx, player, target, line_of_sight) == "visible"
end

-- Prioritize helpless states before weaker fleeing, confused, or distracted openings.
local function condition(ctx, player, target, definition)
    if has_flag(definition, flags.STATIONARY) and
        has_flag(definition, flags.NO_EXP_GAIN) then
        return nil
    end

    if not visible(ctx, player, target) then
        return nil
    end

    local stasis = ctx:get(target, component.MONSTER_STASIS)
    local paralysis = ctx:get(target, component.PARALYSIS)
    local fear = ctx:get(target, component.MONSTER_MASS_ENCHANT)
    local confused = ctx:get(target, component.MONSTER_CONFUSION)

    if stasis and stasis.hibernating then
        return "sleeping", 1
    end

    if paralysis and (paralysis.remaining_aut or 0) > 0 then
        return "paralysed", 1
    end

    if stasis and (stasis.petrified_aut or 0) > 0 then
        return "petrified", 1
    end

    if stasis and (stasis.petrifying_aut or 0) > 0 then
        return "petrifying", 4
    end

    if fear and (fear.fear_aut or 0) > 0 then
        return "fleeing", 4
    end

    if confused and (confused.remaining_aut or 0) > 0 then
        return "confused", 4
    end

    local ai = ctx:get(target, component.AI)

    if ai and ai.behavior == "wander" and
        not has_flag(definition, flags.BATTY) then
        return "distracted", 4
    end

    return nil
end

-- The denominator is one for helpless monsters and four for other openings.
-- Source chance for a non-helpless stab is rounded weapon/stealth skill halves
-- plus Dexterity and one, tested against 100.
function stab.prepare(ctx, player, target, input)
    if confusion.active(ctx, player) then
        return { bonus = 0 }
    end

    local actor = ctx:get(target, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    local kind, bonus = condition(ctx, player, target, definition)

    if not kind then
        return { bonus = 0 }
    end

    if bonus > 1 then
        local chance = roll.random_divide(ctx,
            input.weapon100 or (input.weapon50 or 0) * 2, 200)
        chance = chance + roll.random_divide(ctx,
            input.stealth100 or (input.stealth50 or 0) * 2, 200)
        chance = chance + input.dexterity + 1

        if roll.melee(ctx, 100) >= chance then
            return { bonus = 0 }
        end
    end

    return {
        bonus = bonus,
        kind = kind,
    }
end

-- Short Blades and the mutation capability use the stronger stab damage formula.
local function good_stab(ctx, player, input)
    return input.weapon_skill == "SK_SHORT_BLADES" or
        effects.sum(ctx, player, capabilities.GOOD_STAB) > 0
end

-- Logarithmic stepdown caps large Dexterity flat bonuses without changing small values.
local function stepdown_bonus(value)
    if value < 10 then
        return value
    end

    return math.min(30, math.floor(10 * math.log(1 + value / 10, 2)))
end

-- Apply the helplessness divisor after the good-stab bonus, then add the final extra roll.
function stab.damage(ctx, player, input, plan, damage)
    if not plan or plan.bonus == 0 then
        return damage
    end

    local skill = (input.weapon50 or 0) + (input.stealth50 or 0)
    damage = math.max(1, damage)

    if good_stab(ctx, player, input) then
        local divisor = input.weapon_id == "WPN_DAGGER" and 500 or 1000
        local flat = math.floor(input.dexterity * (skill + 100) / divisor)

        damage = damage + stepdown_bonus(flat)
        damage = math.floor(damage * (10 +
            roll.random_divide(ctx, skill, 100 * plan.bonus)) / 10)
    end

    damage = math.floor(damage * (12 +
        roll.random_divide(ctx, skill, 100 * plan.bonus)) / 12)
    local extra = roll.random_divide(ctx, skill, 200 * plan.bonus)

    return damage + roll.melee(ctx, extra)
end

-- Example: stab.message(ctx, player, plan, name) with no stab bonus -> nil message
-- Paws can replace the normal helpless message with a pounce on one melee draw.
function stab.message(ctx, player, plan, name)
    if not plan or plan.bonus == 0 then
        return nil
    end

    local paws = effects.sum(ctx, player, capabilities.GOOD_STAB) > 0

    if plan.bonus == 1 then
        if paws and roll.melee(ctx, 2) == 0 then
            return "You pounce on the unaware " .. name .. "!"
        end

        return "The " .. name .. " fails to defend itself."
    end

    if roll.melee(ctx, 3) ~= 0 then
        return "You catch the " .. name .. " completely off-guard!"
    end

    local verb = paws and "pounce on" or "strike"

    return "You " .. verb .. " the " .. name .. " from behind!"
end

effects.add(mutations.MUT_PAWS, {
    -- Any effective Paw level enables the stronger stab formula without scaling it again.
    [capabilities.GOOD_STAB] = function(level)
        return level > 0 and 1 or 0
    end,
})

return stab
