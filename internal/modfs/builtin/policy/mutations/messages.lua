local catalog = require("policy.catalog")

local messages = {}

-- Skip empty catalog messages so transitions do not publish blank mutation events.
local function emit(ctx, message)
    if message and message ~= "" then
        ctx:emit("mutation", message)
    end
end

-- Gain and loss messages are emitted after mutation transition chooses the displayed wording.
-- Example: a new mutation level emits its gain message after the record transition.
-- Emit every newly crossed level in ascending order when a grant adds multiple ranks.
function messages.gained(ctx, mutation_id, old_level, new_level)
    local definition = catalog.get("mutations", mutation_id)

    for level = old_level + 1, new_level do
        emit(ctx, definition.gain[level])
    end
end

-- Index the lost level from the new rank; one deletion emits one source loss message.
function messages.lost(ctx, mutation_id, new_level)
    local definition = catalog.get("mutations", mutation_id)

    emit(ctx, definition.lose[new_level + 1])
end

return messages
