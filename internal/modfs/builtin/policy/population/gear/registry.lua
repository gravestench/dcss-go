-- Example: A duplicate monster gear handler fails at registration.
local registry = {}
local handlers = {}
local catalog = require("policy.catalog")
local categories = require("constants.catalog")

-- One handler per monster ID keeps loadout selection deterministic and rejects accidental duplicate registrations.
function registry.register(monster_id, handler)
    if type(monster_id) ~= "string" or monster_id == "" or
        type(handler) ~= "function" then
        error("monster gear handler requires an ID and function")
    end

    if handlers[monster_id] then
        error("duplicate monster gear handler " .. monster_id)
    end

    local found = pcall(catalog.get, categories.MONSTERS, monster_id)

    if not found then
        error("monster gear handler has unknown monster " .. monster_id)
    end

    handlers[monster_id] = handler
end

-- Use a named monster handler when present; nil leaves factory on ordinary catalog gear.
function registry.loadout(ctx, monster_id, depth)
    local handler = handlers[monster_id]

    if not handler then
        return nil
    end

    return handler(ctx, depth)
end

return registry
