local brands = require("policy.combat.brands")
local catalog = require("policy.catalog")
local component = require("constants.component")
local flavours = require("constants.beam_flavours")
local monster_poison = require("policy.combat.monster_poison")
local player_resistance = require("policy.combat.player_resistance")
local roll = require("policy.combat.roll")

local poison = {}

local function player_amount(ctx, dice)
    local maximum = dice.count * dice.sides
    local base = roll.random_divide(ctx, maximum, 3, "monster_spell")
    local low = math.floor(base * 2 / 3)
    local high = math.floor(base * 4 / 3)

    return 3 + low + ctx:random("monster_spell", high - low + 1)
end

local function poison_player(ctx, caster, defender, profile, outcome)
    local resistance = player_resistance.poison(ctx, defender)

    if resistance >= 3 then
        return
    end

    if profile.flavour == flavours.BEAM_POISON and
        resistance > 0 and ctx:random("monster_spell", 3) ~= 0 then
        return
    end

    local amount = player_amount(ctx, outcome.dice)

    if profile.flavour == flavours.BEAM_POISON_ARROW and
        resistance > 0 then
        amount = math.floor(amount / 2)
    elseif resistance < 0 then
        amount = amount * 2
    end

    brands.poison(ctx, amount, ctx:id(caster))
end

local function poison_monster(ctx, caster, defender, profile, outcome)
    local actor = ctx:get(defender, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    if profile.flavour == flavours.BEAM_POISON then
        if ctx:random("monster_spell", 3) ~= 0 then
            monster_poison.apply(ctx, defender, definition, 1, caster)
        end

        return
    end

    local stacks = 4

    if outcome.damage < outcome.after_armour then
        stacks = roll.random_divide(ctx, stacks, 2, "monster_spell")
    end

    monster_poison.apply(ctx, defender, definition, stacks, caster, true)
end

-- Source: beam.cc:mons_adjust_flavoured and ouch.cc:check_your_resists.
function poison.before_damage(ctx, caster, defender, profile, outcome)
    if profile.flavour ~= flavours.BEAM_POISON and
        profile.flavour ~= flavours.BEAM_POISON_ARROW then
        error("poison beam hook received " .. tostring(profile.flavour))
    end

    if ctx:has(defender, component.PLAYER) then
        poison_player(ctx, caster, defender, profile, outcome)
    else
        poison_monster(ctx, caster, defender, profile, outcome)
    end
end

return poison
