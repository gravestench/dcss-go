-- Example: A D:1 kobold consumes its ammunition roll but receives only early gear.
local gear = require("policy.population.gear")
local registry = require("policy.population.gear.registry")
local items = require("ids.items")
local monsters = require("ids.monsters")
local missile_brands = require("constants.missile_brands")

local handler = {}

local weapons = {
    items.WPN_DAGGER,
    items.WPN_DAGGER,
    items.WPN_SHORT_SWORD,
    items.WPN_SHORT_SWORD,
    items.WPN_CLUB,
    items.WPN_WHIP,
}

-- Consume the early ammunition draw even when D:1 cannot receive the stronger result.
local function ammunition(ctx, depth)
    -- The first draw happens even on D:1, before checking depth.
    if gear.draw(ctx, 10) == 0 and depth > 1 then
        return {
            kind_id = items.MI_DART,
            quantity = 2 + gear.draw(ctx, 7),
            ego = missile_brands.POISONED,
        }
    end

    if gear.draw(ctx, 5) >= 2 then
        return nil
    end

    return {
        kind_id = items.MI_STONE,
        quantity = 1 + gear.draw(ctx, 5),
        ego = "",
    }
end

-- Kobold ammunition is chosen before the depth gate, preserving its D:1 RNG consumption.
function handler.loadout(ctx, depth)
    local kind_id = weapons[gear.draw(ctx, #weapons) + 1]

    return {
        primary = {
            kind_id = kind_id,
            quality = gear.quality(ctx, kind_id, depth),
        },
        ammunition = ammunition(ctx, depth),
    }
end

registry.register(monsters.MONS_KOBOLD, handler.loadout)

return handler
