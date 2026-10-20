-- Theory of operation: after ordinary secondary maps, DCSS repeatedly
-- offers a named unique map. A one-in-A continuation draw is followed by
-- an available-map count gate against five; a weighted dummy ends the
-- attempt without placing an actor. Successful maps use the same protected
-- geometry and source-record owner as other secondary vaults.
local categories = require("constants.catalog")
local directives = require("constants.vault_directives")
local catalog = require("policy.generation.vaults.catalog")
local monster_specs = require("policy.generation.vaults.specs.monster")
local resolve = require("policy.generation.vaults.specs.resolve")
local selection = require("policy.generation.vaults.selection")
local history = require("policy.population.unique_history")
local placement = {}

-- The first MONS request is the leader for every authored unique map.
-- Dummy maps deliberately have no MONS and count in the source draw.
local function leader(vault)
    for _, operation in ipairs(vault.operations) do
        if operation.kind == directives.MONS then
            local site = {
                path = vault.path,
                vault_id = vault.id,
                line = operation.line,
                directive = operation.kind,
                glyph = "1",
            }
            local selected = monster_specs.parse(operation.argument, site)[1][1]
            local resolved = resolve.monster({}, selected, 1, site)

            return resolved.kind_id
        end
    end

    return nil
end

-- Exclude a claimed monster even when its earlier source map had a
-- different ID. Remember successful maps on this floor before population
-- has created the actor and written the durable player ledger.
local function exclusions(ctx, pending, prior)
    local excluded = {}

    for id, value in pairs(prior or {}) do
        excluded[id] = value
    end

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)

        if definition.tags.place_unique then
            local kind_id = leader(catalog.get(id))

            if kind_id and (pending[kind_id] or
                history.seen(ctx, kind_id)) then
                excluded[id] = true
            end
        end
    end

    return excluded
end

-- Preserve the common eligibility owner while adding unique-history
-- exclusions for this stage only. Other selectors keep their own scope.
local function request(context, excluded)
    local result = {}

    for key, value in pairs(context) do
        result[key] = value
    end

    result.excluded = excluded

    return result
end

-- Run the source A=2, B=5 loop after ordinary vaults but before monster
-- population. D:1 never places a unique and has no player actor yet.
function placement.place(ctx, builder, context, placed, place)
    if context.depth == 1 or not ctx then
        return 0
    end

    local denominator = 2
    local count = 0
    local pending = {}

    while builder:roll(denominator) == 0 do
        local eligible = request(context,
            exclusions(ctx, pending, context.excluded))
        local candidates = selection.candidates_for_tag(
            builder, "place_unique", eligible)

        if #candidates == 0 or
            (#candidates < 5 and builder:roll(5) >= #candidates) then
            break
        end

        local selected = selection.choose_tag(builder,
            "place_unique", eligible)

        if selected.tags.dummy then
            break
        end

        local vault = catalog.get(selected.id)
        local map = place(ctx, builder, vault, context)

        if map then
            placed[#placed + 1] = map
            context.used:add(vault)

            local kind_id = leader(vault)

            if kind_id then
                pending[kind_id] = true
            end

            count = count + 1

            if count >= 3 then
                denominator = denominator + 1
            end
        end
    end

    return count
end

return placement
