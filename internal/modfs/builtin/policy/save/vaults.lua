local catalog = require("policy.generation.vaults.catalog")
local layouts = require("policy.generation.layouts.catalog")
local categories = require("constants.catalog")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local hooks = require("policy.generation.vaults.hooks")
local depth_rules = require("policy.generation.vaults.depth")
local temple = require("policy.generation.temple.catalog")
local altar = require("policy.generation.altar.catalog")
local slime_seal = require("policy.save.slime_seal")
local primary = require("policy.generation.vaults.primary")
local tags = require("constants.vault_tags")

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

-- A source SUBVAULT can own the rune inside its parent finale. Require the
-- helper to be both present in placement history and selected by a tag the
-- parent actually declared; an unrelated known rune map is not enough.
local function rune_owner_selected(selected, selected_ids, source_id)
    if source_id == selected.id then
        return true
    end

    if not selected_ids[source_id] then
        return false
    end

    local helper = catalog.get(source_id)

    for _, operation in ipairs(selected.operations) do
        if operation.kind == directives.SUBVAULT then
            local choices = operation.argument:match("^%s*%S+%s*:%s*(.-)%s*$")

            for choice in ((choices or "") .. "/"):gmatch("(.-)/") do
                local tag = choice:match("^%s*([%w_]+)")

                if tag and helper.tags[tag] then
                    return true
                end
            end
        end
    end

    return false
end

-- A primary's SUBVAULT regions are actual placements, not just decorative
-- text. Match each requested region to one saved helper occurrence. The
-- matching also handles alternative tags without depending on file order.
local function validate_subvault_history(level, selected, label)
    local requests = {}

    for _, operation in ipairs(selected.operations) do
        if operation.kind == directives.SUBVAULT then
            local choices = operation.argument:match(
                "^%s*%S+%s*:%s*(.-)%s*$")
            local allowed = {}

            for choice in ((choices or "") .. "/"):gmatch("(.-)/") do
                local tag = choice:match("^%s*([%w_]+)")

                if tag then
                    allowed[tag] = true
                end
            end

            requests[#requests + 1] = allowed
        end
    end

    local helpers = {}

    for _, id in ipairs(level.vault_ids or {}) do
        if id ~= selected.id then
            helpers[#helpers + 1] = catalog.get(id)
        end
    end

    local assigned = {}

    -- Reassign an earlier match when a later region has fewer valid helpers.
    local function match(request_index, seen)
        for index, helper in ipairs(helpers) do
            if not seen[index] then
                for tag in pairs(requests[request_index]) do
                    if helper.tags[tag] then
                        seen[index] = true

                        if not assigned[index] or
                            match(assigned[index], seen) then
                            assigned[index] = request_index
                            return true
                        end
                    end
                end
            end
        end

        return false
    end

    for index in ipairs(requests) do
        if not match(index, {}) then
            error(label .. " needs its selected SUBVAULT helpers")
        end
    end
end

-- The selected floor-primary vault and its historical rune intent must agree.
-- A collected rune may no longer have a floor entity, so validation reads
-- the saved source record rather than requiring the item to remain present.
local function validate_primary_vault(level, branch, specification)
    local okay, selected = pcall(catalog.get, level.vault_id)
    local label = branch.abbreviation .. ":" .. level.local_depth ..
        " primary"

    if level.local_depth == branch.depth then
        label = branch.abbreviation .. " end"
    end

    if not okay or selected.family ~= specification.family or
        #selected.places == 0 or
        not depth_rules.eligible({ depths = selected.places },
            level.branch_id, level.local_depth, branch.depth) then
        error(label .. " needs a matching vault")
    end

    local selected_ids = {}

    for _, id in ipairs(level.vault_ids or {}) do
        selected_ids[id] = true
    end

    if not selected_ids[selected.id] then
        error(label .. " needs its selected vault in history")
    end

    if selected.tags.dummy then
        if not specification.allow_dummy then
            error(label .. " does not permit a dummy")
        end

        return
    end

    if #selected.rows == 0 then
        local validator

        for _, operation in ipairs(selected.operations) do
            if operation.kind == directives.HOOK_VALIDATE then
                validator = operation.argument
                break
            end
        end

        if not validator then
            error(label .. " controller needs a validation hook")
        end

        hooks.run(selected, validator, level)
        return
    end

    validate_subvault_history(level, selected, label)

    -- A required finale can be rune-free, as on Lair:5. mod.null is the
    -- catalog's absent-runes value and is not a Lua sequence.
    local runes = type(branch.runes) == "table" and branch.runes or {}

    for _, rune_id in ipairs(runes) do
        local count = 0
        local source_id

        for _, record in ipairs(level.vault_records or {}) do
            if record.kind == effects.ITEM and record.arguments and
                record.arguments.kind_id == rune_id then
                count = count + 1
                source_id = record.source_id
            end
        end

        -- Count every real rune, even if its source map is absent from
        -- history. The sole rune must come from the selected ending or a
        -- helper explicitly selected by that ending's SUBVAULT directive.
        if count ~= 1 or
            not rune_owner_selected(selected, selected_ids, source_id) then
            error(label .. " needs exactly one " .. rune_id ..
                " source record from " .. selected.id)
        end
    end

    -- The source small Lair ending builds one other small ending. The
    -- selected map cannot stand in for its own partner, and a forged extra
    -- ID must not turn an ordinary Lair map into that partner.
    if selected.tags[tags.LAIR_END_SMALL] then
        local partners = 0

        for _, id in ipairs(level.vault_ids or {}) do
            if id ~= selected.id then
                local definition = catalog.get(id)

                if definition.family == specification.family and
                    definition.tags[tags.LAIR_END_SMALL] then
                    partners = partners + 1
                end
            end
        end

        if partners ~= 1 then
            error(label .. " needs exactly one paired small ending")
        end
    end

    -- A mapful source controller may have composed children after its own
    -- placement. Its named validator checks that saved composition too.
    for _, operation in ipairs(selected.operations) do
        if operation.kind == directives.HOOK_VALIDATE then
            hooks.run(selected, operation.argument, level)
        end
    end
end

-- Vault IDs in a save must still resolve against the active catalog.
-- Example: vaults.validate(ctx, input) rejects a saved vault ID missing
-- from the scenario catalog and an authored seal missing from ECS state.
function vaults.validate(ctx, input)
    -- Earlier Pan regions have been retired, but their successful map IDs
    -- still constrain unique-lord and once-per-run draws. Validate those
    -- names against the effective layered catalog during save restore.
    for _, id in ipairs(input.pan_vault_ids or {}) do
        known(id, "Pan history")
    end

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

        local primary_spec = primary.specification(branch,
            level.local_depth)

        if primary_spec then
            validate_primary_vault(level, branch, primary_spec)
        end

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

    -- The source map owns both immutable rune history and the mutable
    -- clear-stone seal cells; check those cells in this same vault pass.
    slime_seal.validate(ctx, input)

    return {}
end

register.policy({
    id = "save.validate_vault_ids",
    run = vaults.validate,
})

return vaults
