local component = require("constants.component")
local armour_egos = require("constants.armour_egos")
local item_ids = require("ids.items")
local equipment = require("policy.combat.equipment")
local effects = require("policy.mutations.effects.registry")
local capabilities = require("constants.mutation_capabilities")

local spirit_shield = {}

local armour_slots = {
    body = true,
    shield = true,
    head = true,
    cloak = true,
    gloves = true,
    boots = true,
    amulet = true,
}

function spirit_shield.active(ctx, player)
    if effects.sum(ctx, player, capabilities.SPIRIT_SHIELD) > 0 then
        return true
    end

    local worn = equipment.worn(ctx, player, armour_slots)

    for slot, entry in pairs(worn) do
        if slot == "amulet" and
            entry.item.kind_id == item_ids.AMU_GUARDIAN_SPIRIT then
            return true
        end

        if slot ~= "amulet" and
            entry.item.ego == armour_egos.SPIRIT_SHIELD then
            return true
        end
    end

    return false
end

-- Source: ouch.cc:ouch shares damage between HP and MP, then spends enough
-- MP to avoid a death caused solely by rounding when that is possible.
function spirit_shield.absorb(ctx, player, damage, hp)
    if damage <= 0 or not spirit_shield.active(ctx, player) then
        return damage
    end

    local magic = ctx:get(player, component.MAGIC)

    if not magic then
        error("spirit shield requires player magic")
    end

    if magic.current <= 0 then
        return damage
    end

    local denominator = math.max(hp + magic.current, 1)
    local numerator = damage * magic.current
    local spent = math.floor(numerator / denominator)
    local remainder = numerator % denominator

    if remainder > 0 and ctx:random("mutation", denominator) < remainder then
        spent = spent + 1
    end

    spent = math.max(spent, damage + 1 - hp)
    spent = math.min(spent, magic.current)
    magic.current = magic.current - spent
    ctx:set(player, component.MAGIC, magic)

    return damage - spent
end

return spirit_shield
