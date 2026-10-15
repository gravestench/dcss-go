local items = require("ids.items")
local potions = require("policy.potions")
local common = require("policy.potions.common")
local component = require("constants.component")
local catalog = require("policy.catalog")
local traits = require("policy.character.species_traits")

local effect = {}

function effect.can_quaff(ctx, player)
    local identity = ctx:get(player, component.PLAYER)
    local species = catalog.get("species", identity.species_id)

    local forms = require("policy.magic.effects.forms.player")

    if traits.stasis(species) or forms.stasis(ctx, player) then
        return "Your stasis prevents you from being hasted."
    end
end

local function rounded_two_thirds(ctx, value)
    local numerator = value * 2
    local whole = math.floor(numerator / 3)
    local remainder = numerator % 3

    if remainder > 0 and ctx:random("potion", 3) < remainder then
        return whole + 1
    end

    return whole
end

-- Source: potion.cc:PotionHaste::effect and spl-other.cc:haste_player.
function effect.apply(ctx, player)
    local durations = common.required(ctx, player, component.DURATIONS)
    local previous = durations.haste_aut
    local power_roll = ctx:random("potion", 40)
    local turns = rounded_two_thirds(ctx, 40 + power_roll)

    durations.haste_aut = math.min(400, previous + turns * 10)

    ctx:set(player, component.DURATIONS, durations)

    if previous > 0 then
        return "You feel as though your hastened speed will last longer."
    end

    return "You feel yourself speed up."
end

potions.register(items.POT_HASTE, effect)

return effect
