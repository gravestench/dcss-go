local spells = require("ids.spells")
local monsters = require("ids.monsters")
local component = require("constants.component")
local catalog = require("policy.catalog")
local equipment = require("policy.combat.equipment")
local registry = require("policy.magic.effects.registry")
local summons = require("policy.magic.effects.summons.common")

local armour = {}

local function body_armour(ctx, player)
    return equipment.worn(ctx, player, { body = true }).body
end

function armour.attack_damage(ctx, creature)
    for _, item in ipairs(ctx:query({ component.ITEM, component.CARRIED_BY })) do
        local carrier = ctx:get(item, component.CARRIED_BY)

        if carrier.holder == creature then
            local state = ctx:get(item, component.ITEM)
            local definition = catalog.get("items", state.kind_id)
            local ac = definition.armour and definition.armour.ac

            if not ac then
                error("animated armour lost its defining armour")
            end

            return ac + math.floor(ac * ac / 2)
        end
    end

    error("animated armour has no defining item")
end

-- Source: spl-summoning.cc:cast_summon_armour_spirit and
-- mon-util.cc:monster::attack: AC + AC^2 / 2 for each of two hits.
function armour.prepare(ctx, player)
    if not body_armour(ctx, player) then
        return "You aren't wearing any armour!"
    end
end

function armour.resolve(ctx, player, _, _, power)
    local worn = body_armour(ctx, player)

    if not worn then
        return
    end

    local creature = summons.spawn(ctx, player,
        spells.SPELL_ANIMATE_ARMOUR, monsters.MONS_ANIMATED_ARMOUR, 2, 1, {
            hd = 15 + summons.divide(ctx, power, 10),
        })

    if not creature then
        return
    end

    local item = worn.item
    local copy = ctx:create()
    ctx:add(copy, component.ITEM, {
        kind_id = item.kind_id,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    })
    ctx:add(copy, component.CARRIED_BY, { holder = creature })
    ctx:emit("spell", "Your armour rises to your defence.")
end

registry.add(spells.SPELL_ANIMATE_ARMOUR, {
    prepare = armour.prepare,
    resolve = armour.resolve,
})

return armour
