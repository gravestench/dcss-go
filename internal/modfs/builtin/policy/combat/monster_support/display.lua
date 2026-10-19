local catalog = require("policy.catalog")
local component = require("constants.component")

local display = {}

-- Resolve a live actor's catalog name at the message boundary. Spell rules
-- keep entity handles as state and never duplicate monster names in strings.
function display.name(ctx, monster)
    local actor = ctx:get(monster, component.ACTOR)

    if not actor then
        error("monster support message has no actor")
    end

    local definition = catalog.get("monsters", actor.kind_id)

    return definition.name
end

return display
