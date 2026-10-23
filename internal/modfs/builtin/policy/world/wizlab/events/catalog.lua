-- Theory of operation: each lab callback family owns its source markers
-- and Akara state in one handler file. This effective-VFS registry finds
-- the owner by marker identity; adding a modded event does not grow a
-- central lab-name switch or depend on file enumeration order.
local effects = require("constants.vault_effects")

local catalog = {}
local entries

-- Reject ambiguous marker ownership during load, before placement can
-- create half of a floor's event entities.
local function load()
    if entries then
        return
    end

    local found = {}
    local ids = {}

    for _, path in ipairs(mod.paths(
        "policy/world/wizlab/events/handlers", ".lua")) do
        local handler = require(path:sub(1, -5):gsub("/", "."))

        if type(handler) ~= "table" or
            type(handler.id) ~= "string" or
            type(handler.is_marker) ~= "function" or
            type(handler.materialize) ~= "function" or
            ids[handler.id] then
            error("invalid Wizard Lab event handler " .. path)
        end

        ids[handler.id] = true
        found[#found + 1] = handler
    end

    table.sort(found, function(left, right)
        return left.id < right.id
    end)

    entries = found
end

-- A marker is claimed by one lab owner or left with an older generic
-- owner. Mod overlays that claim the same identity fail explicitly.
function catalog.owner(record)
    if record.kind ~= effects.MARKER then
        return nil
    end

    load()

    local selected

    for _, handler in ipairs(entries) do
        if handler.is_marker(record) then
            if selected then
                error("two Wizard Lab events own marker " ..
                    tostring(record.identity))
            end

            selected = handler
        end
    end

    return selected
end

return catalog
