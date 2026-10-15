local catalog = require("policy.catalog")

local messages = {}

local function emit(ctx, message)
    if message and message ~= "" then
        ctx:emit("mutation", message)
    end
end

function messages.gained(ctx, mutation_id, old_level, new_level)
    local definition = catalog.get("mutations", mutation_id)

    for level = old_level + 1, new_level do
        emit(ctx, definition.gain[level])
    end
end

function messages.lost(ctx, mutation_id, new_level)
    local definition = catalog.get("mutations", mutation_id)

    emit(ctx, definition.lose[new_level + 1])
end

return messages
