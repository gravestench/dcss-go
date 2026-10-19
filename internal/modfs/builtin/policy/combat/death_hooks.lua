local hooks = {}
local handlers = {}

-- Example: hooks.add(id, callback) with duplicate hook ID -> registration error
-- Spell modules register their own source death rules. Sorting by ID keeps
-- simultaneous marks deterministic across loads and saved games.
function hooks.add(id, callback)
    if type(id) ~= "string" or id == "" or
        type(callback) ~= "function" or handlers[id] then
        error("duplicate or invalid monster death hook " .. tostring(id))
    end

    handlers[id] = callback
end

-- Run death hooks in stable ID order and allow one hook to consume the corpse.
function hooks.run(ctx, monster, definition, position, credited)
    local ids = {}
    local consumed_corpse = false

    for id in pairs(handlers) do
        ids[#ids + 1] = id
    end

    table.sort(ids)

    for _, id in ipairs(ids) do
        if handlers[id](ctx, monster, definition, position, credited,
            consumed_corpse) then
            consumed_corpse = true
        end
    end

    return consumed_corpse
end

return hooks
