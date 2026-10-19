local catalog = require("policy.generation.vaults.catalog")

local vaults = {}

-- A saved vault ID must resolve for the floor where its placement was recorded.
local function known(id, level_id)
    local ok = pcall(catalog.get, id)

    if not ok then
        error("level " .. level_id ..
            " references missing vault " .. tostring(id))
    end
end

-- Vault IDs in a save must still resolve against the active catalog.
-- Example: vaults.validate(nil, input) rejects a saved vault ID missing from the scenario catalog.
function vaults.validate(_, input)
    for _, level in ipairs(input.levels or {}) do
        if level.vault_id and level.vault_id ~= "" then
            known(level.vault_id, level.id)
        end

        for _, record in ipairs(level.vault_records or {}) do
            known(record.source_id, level.id)
        end
    end

    return {}
end

register.policy({
    id = "save.validate_vault_ids",
    run = vaults.validate,
})

return vaults
