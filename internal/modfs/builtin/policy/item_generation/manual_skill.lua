-- DES and shop stock can request a manual by its displayed skill name.
-- Resolve that name in one place so both sources make the same item.
local skills = require("ids.skills")

local manual_skill = {}

-- Map source prose to the registered skill ID and reject unknown skills
-- at the authored site instead of generating an untrainable manual.
function manual_skill.from_name(name, site)
    local normalized = name:upper():gsub("&", "")
    local key = "SK_" .. normalized:gsub("[^%w]+", "_")
    local id = skills[key]

    if id then
        return id
    end

    error(string.format("%s:%d: vault %s: unknown manual skill %s",
        site.path, site.line or 0, site.vault_id, name))
end

return manual_skill
