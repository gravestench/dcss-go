-- Theory of operation: a source-position DES marker is the immutable
-- witness for a Trove gate. Population rolls one price and atomically
-- compare-and-replaces its empty witness while creating an Akara owner.
-- Travel and save validation must match both before changing the gate.
-- Example: a modded Trove entry still uses this owner when its O marker
-- has the shared identity and an empty price field.
local component = require("constants.component")
local effects = require("constants.vault_effects")
local terrain = require("constants.terrain")
local toll = require("policy.world.trove.toll")
local trove = require("constants.trove")
local vaults = require("policy.generation.vaults.catalog")

local portal = {}

-- Only the named marker from a Trove entrance belongs to this owner.
function portal.is_marker(record)
    if not record or record.kind ~= effects.MARKER or
        record.identity ~= trove.MARKER_IDENTITY then
        return false
    end

    local definition = vaults.get(record.source_id)

    return definition and definition.family == trove.ENTRY_FAMILY
end

-- Every selected entrance needs exactly one realized source toll before
-- population draws its price. A sparse mod with a missing or duplicate
-- marker fails during placement instead of producing a broken save later.
function portal.validate_level(ctx, level)
    for _, id in ipairs(level.vault_ids or {}) do
        local definition = vaults.get(id)

        if definition.family == trove.ENTRY_FAMILY then
            local count = 0

            for _, record in ipairs(level.vault_records or {}) do
                if record.source_id == id and
                    not record.pending and not record.overridden and
                    portal.is_marker(record) then
                    count = count + 1

                    if ctx:cell(level.id, record.x, record.y) ~= terrain.DNGN_ENTER_TROVE then
                        error("Trove entrance toll marker has no live arch")
                    end
                end
            end

            if count ~= 1 then
                error("Trove entrance " .. id ..
                    " needs exactly one toll marker")
            end
        end
    end
end

-- Population is the first point with a live character and committed gate
-- location. Reject an altered source marker before consuming a price draw.
function portal.materialize(ctx, level, record)
    local arguments = record.arguments or {}

    if arguments.price ~= "" or arguments.glyph ~= "O" then
        error("Trove entrance has a malformed toll marker")
    end

    local price = toll.roll(ctx, ctx:player())
    local witness = toll.encode(price)
    local gate = ctx:create()

    ctx:replace_record_string(level.id, record.x, record.y,
        record.source_id, record.kind, record.identity,
        "price", "", witness)
    ctx:add(gate, component.WORLD_TROVE_PORTAL, {
        level_id = level.id,
        x = record.x,
        y = record.y,
        vault_id = record.source_id,
        record_index = record.index,
        price_kind = price.kind,
        item_id = price.item_id,
        quantity = price.quantity,
        minimum_plus = price.minimum_plus,
        ego_id = price.ego_id,
        artefact_name = price.artefact_name,
        source_rune_index = price.source_rune_index,
        price_witness = witness,
        spent = false,
        closure_reason = trove.CLOSURE_NONE,
        receipt_kind = "",
        receipt_item_id = "",
        receipt_quantity = 0,
        destination_id = "",
    })

    return {
        level_id = level.id,
        index = record.index,
    }
end

-- A coordinate must identify one and only one gate. The saved marker and
-- ECS owner are compared again before a confirmed payment is committed.
function portal.at(ctx, level_id, x, y)
    local found
    local state

    for _, entity in ipairs(ctx:query({ component.WORLD_TROVE_PORTAL })) do
        local candidate = ctx:get(entity, component.WORLD_TROVE_PORTAL)

        if candidate.level_id == level_id and
            candidate.x == x and candidate.y == y then
            if found then
                error("duplicate Treasure Trove gates at one coordinate")
            end

            found = entity
            state = candidate
        end
    end

    return found, state
end

return portal
