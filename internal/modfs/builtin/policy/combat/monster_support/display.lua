local catalog = require("policy.catalog")
local component = require("constants.component")
local slime_blob = require("policy.monsters.slime_blob")

local display = {}

-- Resolve a live actor's catalog name at the message boundary. Spell rules
-- keep entity handles as state and never duplicate monster names in strings.
function display.name(ctx, monster)
    local actor = ctx:get(monster, component.ACTOR)

    if not actor then
        error("monster support message has no actor")
    end

    local definition = catalog.get("monsters", actor.kind_id)
    local generated = ctx:get(monster, component.PANDEMONIUM_LORD)
    local actor_name = generated and generated.name ~= "" and
        generated.name or definition.name
    local base_name = slime_blob.name(ctx, monster, actor_name)
    local authored = ctx:get(monster, component.VAULT_ACTOR_OVERRIDES)

    if authored and authored.custom_name ~= "" then
        if authored.name_adjective then
            return authored.custom_name .. " " .. base_name
        end

        return authored.custom_name
    end

    return base_name
end

return display
