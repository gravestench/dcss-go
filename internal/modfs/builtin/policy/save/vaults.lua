local catalog = require("policy.generation.vaults.catalog")
local layouts = require("policy.generation.layouts.catalog")
local categories = require("constants.catalog")
local directives = require("constants.vault_directives")
local hooks = require("policy.generation.vaults.hooks")
local depth_rules = require("policy.generation.vaults.depth")
local temple = require("policy.generation.temple.catalog")
local altar = require("policy.generation.altar.catalog")

local vaults = {}

-- A saved vault ID must resolve for the floor where its placement was recorded.
local function known(id, level_id)
    local ok = pcall(catalog.get, id)

    local layout_ok = pcall(layouts.get, id)

    if not ok and not layout_ok and
        not temple.main(id) and not temple.entry(id) and
        not altar.get(id) then
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

        for _, id in ipairs(level.vault_ids or {}) do
            known(id, level.id)
        end

        for _, record in ipairs(level.vault_records or {}) do
            known(record.source_id, level.id)
        end

        local branch = register.get(categories.BRANCHES, level.branch_id)

        if branch.end_layout_required and
            level.local_depth == branch.depth then
            local layout = layouts.get(level.vault_id)
            local validator

            if #layout.places == 0 or
                not depth_rules.eligible({ depths = layout.places },
                    level.branch_id, level.local_depth, branch.depth) then
                error("end floor has no matching explicit PLACE layout")
            end

            for _, operation in ipairs(layout.operations) do
                if operation.kind == directives.HOOK_VALIDATE then
                    validator = operation.argument
                    break
                end
            end

            if not validator then
                error("end layout has no validation hook")
            end

            -- Reuse the generation invariant against saved helper IDs and
            -- source records. Rune pickup changes the entity, not this
            -- historical record, so pre- and post-pickup saves both pass.
            hooks.run(layout, validator, level)
        end
    end

    return {}
end

register.policy({
    id = "save.validate_vault_ids",
    run = vaults.validate,
})

return vaults
