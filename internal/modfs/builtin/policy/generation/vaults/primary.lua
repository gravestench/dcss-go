-- Theory of operation: a branch may choose one authored primary vault on
-- particular floors before optional vault passes. Branch data names the
-- family; this policy applies one stable weighted selection to all floors.
local catalog = require("policy.generation.vaults.catalog")
local categories = require("constants.catalog")
local depth = require("policy.generation.vaults.depth")
local effects = require("constants.vault_effects")
local directives = require("constants.vault_directives")
local hooks = require("policy.generation.vaults.hooks")
local controller = require("policy.generation.vaults.controller")
local primary_stairs = require("policy.generation.vaults.primary_stairs")
local weights = require("policy.generation.vaults.weight")

local primary = {}

-- Branch definitions list their authored floor choices in depth order.
-- A list avoids sparse numeric Lua arrays and makes a mod's added floor
-- explicit without assuming the previous branch depth or file order.
function primary.specification(branch, floor_depth)
    local found

    for _, specification in ipairs(branch.primary_vaults or {}) do
        if specification.depth == floor_depth then
            if found then
                error("branch has duplicate primary depth " .. floor_depth)
            end

            found = specification
        end
    end

    return found
end

-- Source PLACE is necessary but not sufficient: the family must match
-- this branch floor, and a previously used unique map is out.
local function eligible(definition, context)
    if definition.family ~= context.primary_vault_family or
        (definition.tags.dummy and not context.primary_allow_dummy) or
        #definition.places == 0 then
        return false
    end

    if context.used and not context.used:allows(definition) then
        return false
    end

    return depth.eligible({ depths = definition.places },
        context.branch_id, context.depth, context.branch_bottom,
        context.absolute_depth)
end

-- Sort by stable NAME before the draw so a file rename or extra overlay
-- cannot change seeds merely by changing the VFS discovery order.
function primary.candidates(context, definitions)
    local source = definitions or {}
    local candidates = {}

    if not definitions then
        for _, id in ipairs(register.ids(categories.VAULTS)) do
            source[#source + 1] = register.get(categories.VAULTS, id)
        end
    end

    for _, definition in ipairs(source) do
        local weight = weights.for_branch(definition, context.branch_id,
            context.depth, context.branch_bottom, context.absolute_depth)

        if weight > 0 and eligible(definition, context) then
            candidates[#candidates + 1] = {
                definition = definition,
                weight = weight,
            }
        end
    end

    table.sort(candidates, function(left, right)
        return left.definition.id < right.definition.id
    end)

    return candidates
end

-- A mandatory floor with no candidate is unavailable; the caller decides
-- whether to advertise a sealed stair or fail a requested generation.
function primary.choose(random, candidates)
    local total = 0

    for _, candidate in ipairs(candidates) do
        total = total + candidate.weight
    end

    if total == 0 then
        return nil
    end

    local draw = random:roll(total)

    for _, candidate in ipairs(candidates) do
        if draw < candidate.weight then
            return candidate.definition
        end

        draw = draw - candidate.weight
    end

    error("primary vault weight selection exceeded the catalog")
end

-- Count source-resolved rune intents, not map glyphs: NSUBST may remove
-- candidate glyphs and a keyed slot may select a non-rune alternative.
local function validate_runes(map, branch)
    -- Lair has a mandatory source ending but no rune. The content loader
    -- represents its absent runes with mod.null, not a Lua array.
    local runes = type(branch.runes) == "table" and branch.runes or {}

    for _, rune_id in ipairs(runes) do
        local count = 0

        for _, record in ipairs(map.records or {}) do
            if record.kind == effects.ITEM and record.arguments and
                record.arguments.kind_id == rune_id and
                not record.arguments.mimic then
                count = count + 1
            end
        end

        if count ~= 1 then
            error("end vault rejected rune selection: " .. rune_id ..
                " count " .. count)
        end
    end
end

-- A source primary may be a mapless controller. It reserves the primary ID,
-- then its post-place hook composes tagged child maps before optional vaults
-- can take their space. Validate the assembled history, including the child
-- that supplied the real rune, before publishing the floor.
local function place_controller(builder, context, placed, fit, vault, branch)
    context.used:add(vault)

    local api = controller.new(builder, context, placed, fit, vault.id)

    for _, operation in ipairs(vault.operations) do
        if operation.kind == directives.HOOK_POST_PLACE then
            hooks.run(vault, operation.argument, api)
        end
    end

    local result = {
        vault_ids = {},
        records = {},
    }

    for _, map in ipairs(placed) do
        result.vault_ids[#result.vault_ids + 1] = map.id

        for _, record in ipairs(map.records or {}) do
            result.records[#result.records + 1] = record
        end
    end

    validate_runes(result, branch)

    for _, operation in ipairs(vault.operations) do
        if operation.kind == directives.HOOK_VALIDATE then
            hooks.run(vault, operation.argument, result)
        end
    end
end

-- A selected primary is published only after its terrain and connector fit.
-- The caller may redraw its base layout after a geometric failure, but it
-- must never continue to ordinary extras without this required map.
function primary.place(ctx, builder, context, placed, fit)
    if not context.primary_vault_family then
        return nil
    end

    local candidates = primary.candidates(context)
    local choice = context.primary_choice
    local selected

    if choice and choice.id then
        for _, candidate in ipairs(candidates) do
            if candidate.definition.id == choice.id then
                selected = candidate.definition
                break
            end
        end

        if not selected then
            error("previously selected primary vault is no longer eligible: " ..
                choice.id)
        end
    else
        selected = primary.choose(builder, candidates)

        if not selected then
            error("primary vault catalog has no eligible map for " ..
                context.primary_vault_family)
        end

        -- Keep this weighted choice across whole-floor redraws. A failed
        -- geometric fit must not change the source map's probability.
        if choice then
            choice.id = selected.id
        end
    end

    local vault = catalog.get(selected.id)
    local branch = register.get(categories.BRANCHES, context.branch_id)

    -- The Elf:1 source dummy spends its weighted choice but leaves the
    -- procedural layout's reciprocal entrance in place.
    if vault.tags.dummy then
        context.used:add(vault)
        return vault.id
    end

    if #vault.rows == 0 then
        place_controller(builder, context, placed, fit, vault, branch)
        return vault.id
    end

    primary_stairs.relocate(builder, vault, context)

    local map, reason = fit(ctx, builder, vault, context)

    if not map then
        error("primary vault could not fit on base layout: " ..
            tostring(reason))
    end

    validate_runes(map, branch)

    placed[#placed + 1] = map
    context.used:add_map(vault, map)

    -- A source end with geometry can also request a paired child after it
    -- fits. Record the primary first so the child appears in the same saved
    -- placement history; the pairing hook excludes this primary by ID.
    for _, operation in ipairs(vault.operations) do
        if operation.kind == directives.HOOK_POST_PLACE then
            local api = controller.new(builder, context, placed, fit,
                vault.id, map)

            hooks.run(vault, operation.argument, api)
        end
    end

    return vault.id
end

return primary
