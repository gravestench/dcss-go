-- Parghit always wears gold dragon scales. A one-in-100 winning roll
-- makes them the Dragon King; otherwise source forces a +6–9 enchantment.
local artefacts = require("ids.artefacts")
local gear = require("policy.population.gear")
local item_ids = require("ids.items")
local monsters = require("ids.monsters")
local registry = require("policy.population.gear.registry")

local handler = {}

-- This armour choice is independent of any ordinary weapon loadout and
-- uses the monster body inventory slot in both branches.
function handler.loadout(ctx, depth)
    local loadout = gear.ordinary_loadout(ctx,
        monsters.MONS_PARGHIT, depth) or {}

    if gear.chance_unique(ctx, artefacts.UNRAND_DRAGON_KING, 100) then
        loadout.body = {
            unique_id = artefacts.UNRAND_DRAGON_KING,
        }
    else
        loadout.body = {
            kind_id = item_ids.ARM_GOLD_DRAGON_ARMOUR,
            quality = {
                plus = 6 + gear.draw(ctx, 4),
            },
        }
    end

    return loadout
end

registry.register(monsters.MONS_PARGHIT, handler.loadout)

return handler
