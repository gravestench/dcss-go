local catalog = require("policy.catalog")
local component = require("constants.component")
local items = require("policy.inventory.items")
local item_ids = require("ids.items")
local classes = require("ids.object_classes")
local quality = require("constants.vault_item_quality")
local origin_component = require("policy.population.origin")

local vault_items = {}

-- A random vault item is selected before its source quality is applied.
-- Artefact properties need their own component; until then, superb gear
-- retains its guaranteed enchantment in the ordinary item fields.
local function generated_properties(ctx, definition, resolved)
    local properties = {
        plus = resolved.plus or 0,
        charges = resolved.charges or 0,
        ego = resolved.ego or "",
    }

    if not resolved.request then
        return properties
    end

    local level = resolved.quality or quality.ORDINARY
    local class = definition.class

    if class == classes.OBJ_WANDS then
        properties.charges = 1 + ctx:random("vault_items", 4)

        if level == quality.GOOD then
            properties.charges = properties.charges + 3
        elseif level == quality.SUPERB then
            properties.charges = properties.charges + 6
        end
    elseif class == classes.OBJ_WEAPONS or class == classes.OBJ_ARMOUR then
        if level == quality.GOOD then
            properties.plus = 2 + ctx:random("vault_items", 3)
        elseif level == quality.SUPERB then
            properties.plus = 5 + ctx:random("vault_items", 3)
        else
            local denominator = class == classes.OBJ_WEAPONS and 200 or 250
            local chance = math.min(denominator, 51 +
                (resolved.generation_depth or 1))

            if ctx:random("vault_items", denominator) < chance then
                properties.plus = ctx:random("vault_items", 3)
            end
        end
    elseif class == classes.OBJ_JEWELLERY and definition.jewellery and
        definition.jewellery.pluses then
        if level == quality.GOOD then
            properties.plus = 2 + ctx:random("vault_items", 3)
        elseif level == quality.SUPERB then
            properties.plus = 4 + ctx:random("vault_items", 3)
        end
    end

    return properties
end

-- Source: crawl-ref/source/makeitem.cc:1901-1911.
local function random_gold_quantity(ctx, resolved)
    if resolved.kind_id ~= item_ids.OBJ_GOLD or not resolved.request then
        return resolved.quantity or 1
    end

    if resolved.quantity then
        return resolved.quantity
    end

    if resolved.quality == quality.GOOD or resolved.quality == quality.SUPERB then
        return 100 + ctx:random("vault_items", 400)
    end

    local first = ctx:random("vault_items", 19)
    local second = ctx:random("vault_items", 19)
    local depth = math.max(1, resolved.generation_depth or 1)

    return 1 + math.floor((first + second) / 2) +
        ctx:random("vault_items", depth)
end

local function corpse_source(ctx, entity, resolved)
    if resolved.kind_id ~= item_ids.CORPSE_BODY and
        resolved.kind_id ~= item_ids.CORPSE_SKELETON then
        return
    end

    if not resolved.base_id or resolved.base_id == "" then
        error("vault corpse has no monster species")
    end

    local source = catalog.get("monsters", resolved.base_id)

    if source.status ~= "defined" then
        error("vault corpse has inactive species " .. resolved.base_id)
    end

    ctx:add(entity, "core.corpse", {
        monster_id = resolved.base_id,
        freshness = 110,
        appearance = ctx:random("corpse", 255) + 1,
    })
end

function vault_items.create(ctx, resolved, level_id, x, y, origin)
    if not ctx:walkable(level_id, x, y) then
        error("cannot place vault item " .. tostring(resolved.kind_id))
    end

    local definition = catalog.get("items", resolved.kind_id)
    local properties = generated_properties(ctx, definition, resolved)
    local item = {
        kind_id = resolved.kind_id,
        quantity = random_gold_quantity(ctx, resolved),
        plus = properties.plus,
        charges = properties.charges,
        ego = properties.ego,
    }

    items.validate(item, definition)

    if (resolved.kind_id == item_ids.CORPSE_BODY or
        resolved.kind_id == item_ids.CORPSE_SKELETON) and
        not resolved.base_id then
        error("vault corpse has no monster species")
    end

    local entity = ctx:create()

    ctx:add(entity, component.ITEM, item)
    corpse_source(ctx, entity, resolved)
    ctx:add(entity, component.POSITION, {
        level_id = level_id,
        x = x,
        y = y,
    })

    if origin then
        ctx:add(entity, component.VAULT_ORIGIN,
            origin_component.for_entity(origin, resolved.kind_id))
    end

    return entity
end

return vault_items
