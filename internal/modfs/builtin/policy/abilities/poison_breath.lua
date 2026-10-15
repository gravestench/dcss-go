-- Source: ability.cc:ABIL_SPIT_POISON and ABIL_BREATHE_POISON; zap-data.h
-- supplies their distinct bolt dice, hit bonuses, and penetration rules.
local abilities = require("ids.abilities")
local catalog = require("policy.catalog")
local component = require("constants.component")
local failure = require("policy.abilities.failure")
local mutations = require("ids.mutations")
local poison = require("policy.combat.monster_poison")
local projectile = require("policy.magic.effects.zaps.projectile")
local registry = require("policy.abilities.registry")
local resistances = require("constants.resistance_ids")
local spells = require("ids.spells")

local breath = {}

local spit_spec = {
    name = "splash of poison",
    cap = 50,
    range = 5,
    damage = {
        kind = "dicedef",
        count = 1,
        base = 4,
        numerator = 1,
        denominator = 2,
    },
    hit = {
        base = 5,
        numerator = 1,
        denominator = 6,
    },
    ac_rule = "normal",
    element = resistances.POISON,
}

local gas_spec = {
    name = "poison gas",
    cap = 50,
    range = 6,
    damage = {
        kind = "dicedef",
        count = 3,
        base = 2,
        numerator = 1,
        denominator = 6,
    },
    hit = {
        base = 6,
        numerator = 1,
        denominator = 6,
    },
    ac_rule = "normal",
    element = resistances.POISON,
    beam = true,
}

function breath.poison_after_hit(ctx, player, target, definition, damage)
    if damage <= 0 or poison.resistance(definition) >= 3 or
        ctx:random("spell", 3) == 0 then
        return
    end

    poison.apply(ctx, target, definition, 1, player)
end

spit_spec.after_hit = breath.poison_after_hit
gas_spec.after_hit = breath.poison_after_hit

local function prepare(ctx, player, input, range)
    local state = ctx:get(player, component.BREATH_COOLDOWN)

    if state and state.remaining_aut > 0 then
        return "You cannot use your breath weapon yet."
    end

    local dx = input.dx or 0
    local dy = input.dy or 0

    if dx == 0 and dy == 0 then
        return "Okay, then."
    end

    local position = ctx:get(player, component.POSITION)

    if math.max(math.abs(dx), math.abs(dy)) > range or
        not ctx:visible(position.level_id, position.x, position.y,
            range, position.x + dx, position.y + dy) then
        return "That is beyond your range."
    end

    return nil
end

function breath.prepare_spit(ctx, player, input)
    return prepare(ctx, player, input, spit_spec.range)
end

function breath.prepare_gas(ctx, player, input)
    return prepare(ctx, player, input, gas_spec.range)
end

local function start_cooldown(ctx, player, turns)
    local state = {
        remaining_aut = turns * 10,
    }

    if ctx:has(player, component.BREATH_COOLDOWN) then
        ctx:set(player, component.BREATH_COOLDOWN, state)
    else
        ctx:add(player, component.BREATH_COOLDOWN, state)
    end
end

function breath.resolve_spit(ctx, player, intent)
    if failure.roll(ctx, player, 20) then
        ctx:emit("mutation", "You fail to spit poison.")
        return
    end

    local progression = ctx:get(player, component.PROGRESSION)
    local spell = catalog.get("spells", spells.SPELL_SPIT_POISON)

    ctx:emit("mutation", "You spit a splash of poison.")
    projectile.fire(ctx, player, intent, spell, spit_spec,
        10 + progression.level)
    start_cooldown(ctx, player, 3 + ctx:random("mutation", 5))
end

function breath.resolve_gas(ctx, player, intent)
    if failure.roll(ctx, player, 30) then
        ctx:emit("mutation", "You fail to breathe poison gas.")
        return
    end

    local progression = ctx:get(player, component.PROGRESSION)
    local spell = catalog.get("spells", spells.SPELL_SPIT_POISON)

    ctx:emit("mutation", "You exhale a blast of poison gas.")
    projectile.fire(ctx, player, intent, spell, gas_spec,
        progression.level)

    local cooldown = 3 + ctx:random("mutation", 10) +
        ctx:random("mutation", math.max(1, 30 - progression.level))

    start_cooldown(ctx, player, cooldown)
end

registry.add(abilities.SPIT_POISON, {
    mutation_id = mutations.MUT_SPIT_POISON,
    name = "Spit Poison",
    min_level = 1,
    max_level = 1,
    range = function()
        return spit_spec.range
    end,
    prepare = breath.prepare_spit,
    resolve = breath.resolve_spit,
})

registry.add(abilities.BREATHE_POISON, {
    mutation_id = mutations.MUT_SPIT_POISON,
    name = "Breathe Poison Gas",
    min_level = 2,
    range = function()
        return gas_spec.range
    end,
    prepare = breath.prepare_gas,
    resolve = breath.resolve_gas,
})

return breath
