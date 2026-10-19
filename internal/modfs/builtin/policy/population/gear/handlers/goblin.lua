-- Example: A goblin sling choice consumes its gear roll before the melee fallback.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local gear = require("policy.population.gear")
local registry = require("policy.population.gear.registry")
local items = require("ids.items")
local monsters = require("ids.monsters")

local handler = {}

-- Read the goblin source gear row before applying special sling and melee handling.
local function primary_spec()
    local definition = catalog.get(categories.MONSTERS, monsters.MONS_GOBLIN)
    local owned = definition.weapon_gear or {}

    return owned.primary
end

-- Preserve source gear draw order while replacing preliminary plusses with final weapon quality.
local function weapon(ctx, depth, melee_only)
    local spec = primary_spec()

    if not spec or spec.plus.odds ~= 0 or spec.good_chance ~= 0 then
        error("unsupported goblin weapon specification")
    end

    local kind_id = gear.weighted(ctx, spec.weapons)

    if kind_id == "" then
        error("goblin weapon table chose no item")
    end

    -- _apply_weapon_spec's preliminary plusses are discarded by
    -- make_mons_weapon, including before a sling override.
    gear.nice_plusses(ctx, depth)

    if not melee_only and gear.draw(ctx, 12) == 0 and depth > 0 then
        kind_id = items.WPN_SLING
    end

    return {
        kind_id = kind_id,
        quality = gear.quality(ctx, kind_id, depth),
    }
end

-- Goblin ranged and melee loadouts share weapon quality draws before the final override is selected.
function handler.loadout(ctx, depth)
    local primary = weapon(ctx, depth, false)
    local loadout = {
        primary = primary,
    }

    if primary.kind_id == items.WPN_SLING then
        loadout.alternate = weapon(ctx, depth, true)
    end

    return loadout
end

registry.register(monsters.MONS_GOBLIN, handler.loadout)

return handler
