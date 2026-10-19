local catalog = require("policy.catalog")
local component = require("constants.component")
local gear = require("policy.population.gear")
local item_ids = require("ids.items")
local items = require("policy.inventory.items")
local monsters = require("ids.monsters")

local spectral_gear = {}

-- An item created for a spectral orc is carried and equipped by the
-- summoned actor. The ordinary summon expiry owner removes it with its
-- carrier, matching the source's mark_summoned(..., true) item lifecycle.
local function attach(ctx, creature, kind_id, plus, ego, slot)
    local definition = catalog.get("items", kind_id)
    local state = {
        kind_id = kind_id,
        quantity = 1,
        plus = plus,
        charges = 0,
        ego = ego,
    }

    items.validate(state, definition)

    local item = ctx:create()

    ctx:add(item, component.ITEM, state)
    ctx:add(item, component.CARRIED_BY, {
        holder = creature,
    })
    ctx:add(item, component.EQUIPPED, {
        slot = slot,
    })
end

-- mon-gear.cc:make_mons_armour gives rank-and-file orcs a weighted light
-- armour chance. Warriors, knights, and warlords choose chain or plate.
local function armour_kind(ctx, base_kind)
    if base_kind == monsters.MONS_ORC then
        if gear.draw(ctx, 5) >= 2 then
            return nil
        end

        return gear.weighted(ctx, {
            {
                id = item_ids.ARM_LEATHER_ARMOUR,
                weight = 4,
            },

            {
                id = item_ids.ARM_RING_MAIL,
                weight = 2,
            },

            {
                id = item_ids.ARM_SCALE_MAIL,
                weight = 1,
            },

            {
                id = item_ids.ARM_CHAIN_MAIL,
                weight = 1,
            },
        })
    end

    if gear.draw(ctx, 2) == 0 then
        return item_ids.ARM_CHAIN_MAIL
    end

    return item_ids.ARM_PLATE_ARMOUR
end

-- Use the original orc profile for gear, never the generic spectral thing.
-- Weapon kind and quality already come from the committed monster gear rule.
function spectral_gear.give(ctx, creature, base_kind, level_id)
    local loadout = gear.loadout(ctx, base_kind, level_id)

    if loadout and loadout.primary then
        local weapon = loadout.primary

        attach(ctx, creature, weapon.kind_id,
            weapon.quality.plus, weapon.quality.ego, "weapon")
    end

    local armour = armour_kind(ctx, base_kind)

    if armour then
        attach(ctx, creature, armour, 0, "", "body")
    end
end

return spectral_gear
