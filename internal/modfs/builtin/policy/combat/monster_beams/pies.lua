local blueberry = require("policy.combat.pies.blueberry")
local cherry = require("policy.combat.pies.cherry")
local lemon = require("policy.combat.pies.lemon")
local moon = require("policy.combat.pies.moon")
local plum = require("policy.combat.pies.plum")
local raspberry = require("policy.combat.pies.raspberry")
local component = require("constants.component")
local senses = require("policy.character.senses")

local pies = {}
local fillings = {
    plum,
    lemon,
    blueberry,
    raspberry,
    cherry,
    moon,
}

-- Example: pies.choose(ctx, target) with monster target -> weighted eligible filling module
-- Choose only fillings valid for this defender, then use their weights on the monster-spell RNG stream.
function pies.choose(ctx, target)
    local eligible = {}
    local total = 0

    for _, filling in ipairs(fillings) do
        if filling.valid(ctx, target) then
            total = total + filling.weight
            eligible[#eligible + 1] = filling
        end
    end

    if total == 0 then
        error("Throw Pie has no eligible filling")
    end

    local choice = ctx:random("monster_spell", total)

    for _, filling in ipairs(eligible) do
        if choice < filling.weight then
            return filling
        end

        choice = choice - filling.weight
    end

    error("Throw Pie selected outside its weighted fillings")
end

-- A pie effect is applied after contact, leaving misses and blocks without filling effects.
function pies.apply(ctx, caster, defender, outcome)
    if outcome.damage <= 0 then
        return
    end

    local filling = pies.choose(ctx, defender)

    if ctx:has(defender, component.PLAYER) or
        senses.player_sees_actor(ctx, defender) then
        ctx:emit("combat", filling.id .. "!")
    end
    filling.apply(ctx, caster, defender)
end

return pies
