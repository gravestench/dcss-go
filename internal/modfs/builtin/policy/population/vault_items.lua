-- Example: An invalid DES item reports its source line after vault projection.
local catalog = require("policy.catalog")
local classes = require("ids.object_classes")
local component = require("constants.component")
local generation = require("policy.item_generation")
local origin_component = require("policy.population.origin")
local quality = require("constants.vault_item_quality")
local purpose = require("constants.item_generation_purpose")
local identification = require("policy.items.identification")

local vault_items = {}

-- Keep the authored DES site in resolution errors even after the level record is projected.
local function source_site(resolved, origin)
    local site = resolved.site

    if not site then
        return "vault " .. origin.vault_id ..
            " record " .. origin.record_index
    end

    return string.format("%s:%d: vault %s",
        site.path, site.line, site.vault_id)
end

-- Keep random-item requests unresolved until a live population context supplies the item stream.
local function request_from(resolved, level_id, origin)
    local request = {
        depth = resolved.generation_depth or level_id,
        quality = resolved.quality or quality.ORDINARY,
        allow_uniques = resolved.allow_uniques ~= false,
        purpose = purpose.VAULT,
        quantity = resolved.quantity,
        base_id = resolved.base_id,
        disc = resolved.disc,
        numspells = resolved.numspells,
        site = source_site(resolved, origin),
    }

    if resolved.kind_id ~= classes.OBJ_RANDOM then
        request.kind_id = resolved.kind_id
    end

    return request
end

-- Recheck walkability and corpse suitability at materialization, then attach vault origin to the new item.
function vault_items.create(ctx, resolved, level_id, x, y, origin)
    if not ctx:walkable(level_id, x, y) then
        error("cannot place vault item " .. tostring(resolved.kind_id))
    end

    local rolled = generation.roll(ctx,
        request_from(resolved, level_id, origin))
    local definition = catalog.get("items", rolled.kind_id)

    if definition.class == classes.OBJ_CORPSES and
        not rolled.components[component.CORPSE] then
        error(source_site(resolved, origin) .. " has no corpse species")
    end

    local entity = generation.create(ctx, rolled, {
        position = {
            level_id = level_id,
            x = x,
            y = y,
        },
    })

    -- DES ident:type reveals this specific placed instance; the global
    -- player knowledge map is unchanged until the item is examined or used.
    if resolved.ident then
        local all = resolved.ident == "all"

        identification.reveal_item(ctx, entity, {
            type = true,
            pluses = all,
            properties = all,
        })
    end

    if origin then
        ctx:add(entity, component.VAULT_ORIGIN,
            origin_component.for_entity(origin, rolled.kind_id))
    end

    return entity, rolled.kind_id
end

return vault_items
