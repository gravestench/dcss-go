local abilities = require("ids.abilities")
local component = require("constants.component")
local catalog = require("policy.catalog")
local effects = require("policy.magic.effects.registry")
local failure = require("policy.abilities.failure")
local mutations = require("ids.mutations")
local registry = require("policy.abilities.registry")
local spells = require("ids.spells")

local damnation = {}

function damnation.hp_cost(maximum)
    return math.floor((150 * maximum + 500) / 1000)
end

function damnation.prepare(ctx, player, input)
    local health = ctx:get(player, component.HEALTH)
    local position = ctx:get(player, component.POSITION)
    local dx = input.dx or 0
    local dy = input.dy or 0

    if dx == 0 and dy == 0 then
        return "Okay, then."
    end

    if math.max(math.abs(dx), math.abs(dy)) > 6 or
        not ctx:visible(position.level_id, position.x, position.y,
            6, position.x + dx, position.y + dy) then
        return "That is beyond your range."
    end

    if health.current <= damnation.hp_cost(health.max) then
        return "You do not have enough health."
    end

    return nil
end

function damnation.resolve(ctx, player, intent)
    if failure.roll(ctx, player) then
        ctx:emit("mutation", "You fail to hurl damnation.")
        return
    end

    local spell = catalog.get("spells", spells.SPELL_HURL_DAMNATION)
    local effect = effects.get(spell.id)
    local progression = ctx:get(player, component.PROGRESSION)
    local power = 40 + progression.level * 6

    effect.resolve(ctx, player, intent, spell, power)

    local health = ctx:get(player, component.HEALTH)
    health.current = math.max(0,
        health.current - damnation.hp_cost(health.max))
    ctx:set(player, component.HEALTH, health)
end

registry.add(abilities.HURL_DAMNATION, {
    mutation_id = mutations.MUT_HURL_DAMNATION,
    name = "Hurl Damnation",
    range = function()
        return 6
    end,
    prepare = damnation.prepare,
    resolve = damnation.resolve,
})

return damnation
