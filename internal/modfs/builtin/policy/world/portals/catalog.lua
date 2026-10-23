-- Theory of operation: temporary portals register one feature owner and one
-- source-marker owner per domain. The layered VFS discovers handler files,
-- so another portal adds one Lua file instead of another command or vault
-- population branch. Selection is by feature or marker, never file order.
-- Example: handlers.owner(terrain.DNGN_ENTER_SEWER) returns "sewer".
local effects = require("constants.vault_effects")

local catalog = {}
local entries
local by_feature

-- Validate the effective files once. Duplicate features are errors because
-- a single stair cannot safely offer two different travel transactions.
local function load()
    if entries then
        return
    end

    local discovered = {}
    local features = {}
    local ids = {}

    for _, path in ipairs(mod.paths("policy/world/portals/handlers", ".lua")) do
        local name = path:sub(1, -5):gsub("/", ".")
        local handler = require(name)

        if type(handler) ~= "table" or type(handler.id) ~= "string" or
            handler.id == "" or type(handler.features) ~= "table" or
            type(handler.prepare) ~= "function" or
            type(handler.is_marker) ~= "function" or
            type(handler.materialize) ~= "function" then
            error("invalid temporary portal handler " .. path)
        end

        if ids[handler.id] then
            error("duplicate temporary portal handler " .. handler.id)
        end

        ids[handler.id] = true

        for _, feature in ipairs(handler.features) do
            if type(feature) ~= "string" or feature == "" or
                features[feature] then
                error("duplicate or invalid temporary portal feature " ..
                    tostring(feature))
            end

            features[feature] = handler
        end

        discovered[#discovered + 1] = handler
    end

    table.sort(discovered, function(left, right)
        return left.id < right.id
    end)

    entries = discovered
    by_feature = features
end

-- Expose the owner ID for rule tests and mod diagnostics.
function catalog.owner(feature)
    load()

    local handler = by_feature[feature]

    return handler and handler.id or nil
end

-- The feature picks one handler before it sees the command details.
function catalog.dispatch(ctx, request)
    load()

    local position = request.position
    local feature = ctx:cell(position.level_id, position.x, position.y)
    local handler = by_feature[feature]

    return handler and handler.prepare(ctx, request) or nil
end

-- Resolve a source marker without creating a gate. Population checks its
-- earlier nonportal owners first, then invokes this handler in record order.
-- Overlap among temporary portals remains an error rather than load order.
function catalog.for_marker(record)
    if record.kind ~= effects.MARKER then
        return nil
    end

    load()

    local match

    for _, handler in ipairs(entries) do
        if handler.is_marker(record) then
            if match then
                error("two temporary portals own source marker " ..
                    tostring(record.identity))
            end

            match = handler
        end
    end

    return match
end

-- Domain validators check required source markers before population draws.
function catalog.validate_level(ctx, level)
    load()

    for _, handler in ipairs(entries) do
        if handler.validate_level then
            handler.validate_level(ctx, level)
        end
    end
end

return catalog
