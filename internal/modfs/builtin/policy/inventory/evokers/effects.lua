-- Each XP evoker effect registers from its own discoverable Lua file.
-- The command owner never switches on a subtype name, so mods can add an
-- item and resolver without editing this module.
local effects = {}
local registered = {}

-- Register one effect for an item kind. A duplicate means two mod files
-- claim the same effect and should fail at load rather than depend on order.
function effects.add(kind_id, effect)
    if type(kind_id) ~= "string" or kind_id == "" or
        registered[kind_id] or type(effect) ~= "table" or
        type(effect.resolve) ~= "function" then
        error("invalid or duplicate XP evoker effect " .. tostring(kind_id))
    end

    registered[kind_id] = effect
end

-- Look up the effective resolver after all mod files have registered.
function effects.get(kind_id)
    return registered[kind_id]
end

return effects
