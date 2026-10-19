-- Source formicid cannot produce a skeleton.

local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local directives = require("constants.vault_directives")
local des = require("policy.generation.vaults.des")
local hooks = require("policy.generation.vaults.hooks")
local harness = require("tests.harness")
local item = require("policy.generation.vaults.specs.item")
local monster = require("policy.generation.vaults.specs.monster")
local resolve = require("policy.generation.vaults.specs.resolve")
local monster_ids = require("ids.monsters")
local item_ids = require("ids.items")
local item_quality = require("constants.vault_item_quality")
local colours = require("constants.vault_colours")

local test = {}

local site = {
    path = "vaults/arrival/nagdon_arrival_zigzag_paths.des",
    vault_id = "nagdon_arrival_zigzag_paths",
    line = 6,
    directive = "ITEM",
    glyph = "d",
}

-- Scripted draws let each resolver assertion control which weighted source option wins.
local function random_context(draws)
    local ctx = {
        draws = draws or {},
        count = 0,
    }

    -- Consume one scripted draw per request and reject a resolver's invalid bound.
    function ctx:random(stream, bound)
        self.count = self.count + 1
        local draw = self.draws[self.count] or 0

        harness.truthy(draw < bound, "random draw exceeds " .. stream)

        return draw
    end

    return ctx
end

-- Named monsters, undead bases, item variants, and quantities must resolve to stable IDs.
local function named_and_variant_identities()
    local ctx = random_context()
    local rat = monster.parse("rat", site)[1][1]
    local skeleton = monster.parse("human skeleton", site)[1][1]
    local stone = item.parse("stone q:4", site)[1][1]
    local corpse = item.parse("orc skeleton", site)[1][1]

    harness.equal(resolve.monster(ctx, rat, 1, site).kind_id,
        monster_ids.MONS_RAT, "named monster")
    harness.equal(resolve.monster(ctx, skeleton, 1, site).kind_id,
        monster_ids.MONS_SKELETON, "undead monster kind")
    harness.equal(resolve.monster(ctx, skeleton, 1, site).base_id,
        monster_ids.MONS_HUMAN, "undead monster base")
    harness.equal(resolve.item(ctx, stone, 1, site).kind_id,
        item_ids.MI_STONE, "named item")
    harness.equal(resolve.item(ctx, stone, 1, site).quantity,
        4, "source item quantity")
    harness.equal(resolve.item(ctx, corpse, 1, site).base_id,
        monster_ids.MONS_ORC, "skeleton item species")
end

-- Random vault requests inherit source depth so placement does not silently
-- draw from an unrelated population tier.
local function random_requests_use_source_depth()
    local ctx = random_context()
    local ordinary = monster.parse("0", site)[1][1]
    local out_of_depth = monster.parse("8", site)[1][1]
    local placed = monster.parse("place:D:1 0", site)[1][1]

    harness.truthy(resolve.monster(ctx, ordinary, 1, site).kind_id,
        "ordinary random monster")
    harness.truthy(resolve.monster(ctx, out_of_depth, 1, site).kind_id,
        "super OOD monster")
    harness.truthy(resolve.monster(ctx, placed, 2, site).kind_id,
        "explicit D:1 monster")

    for _, name in ipairs({ "random_item", "random_gold", "good_item", "superb_item" }) do
        local selected = resolve.item(ctx, item.parse(name, site)[1][1], 1, site)

        harness.truthy(selected.kind_id, name .. " did not resolve")
    end

    for _, name in ipairs({ "%", "$", "*", "|" }) do
        harness.truthy(resolve.item(ctx, item.parse(name, site)[1][1], 1, site).kind_id,
            "implicit item glyph " .. name)
    end

    harness.equal(resolve.item(ctx, item.parse("good_item", site)[1][1], 1, site).quality,
        item_quality.GOOD, "good item quality")
    local starred = resolve.item(ctx, item.parse("*", site)[1][1], 2, site)

    harness.equal(starred.quality, item_quality.STAR,
        "star uses its own source item level")
    harness.equal(starred.generation_depth, 9,
        "star item level uses Dungeon depth")
    harness.equal(resolve.item(ctx, item.parse("superb_item", site)[1][1], 1, site).quality,
        item_quality.SUPERB, "superb item quality")
end

-- Generic corpse expressions must choose a species that can actually leave a corpse.
local function generic_corpse_species()
    local ctx = random_context()

    for _, expression in ipairs({ "corpse", "skeleton", "place:D:1 skeleton" }) do
        local selected = item.parse(expression, site)[1][1]
        local resolved = resolve.item(ctx, selected, 2, site)
        local species = catalog.get(categories.MONSTERS, resolved.base_id)

        harness.truthy(species.leaves_corpse, expression .. " must have a corpse species")
        harness.truthy(resolved.kind_id == item_ids.CORPSE_BODY or
            resolved.kind_id == item_ids.CORPSE_SKELETON,
            expression .. " must resolve as a corpse item")
    end
end

-- The authored Formicid skeleton stays a typed no-spawn rather than an impossible corpse.
local function legacy_source_skeleton_fault()
    local fault_site = {
        path = "vaults/arrival/dreamdust_arrival_sigmund_warning.des",
        vault_id = "dreamdust_arrival_sigmund_warning",
        line = 10,
        directive = "KITEM",
        glyph = "?",
    }
    local selected = item.parse("formicid skeleton", fault_site)[1][1]

    harness.truthy(resolve.item(random_context(), selected, 1, fault_site).no_spawn,
        "source formicid cannot produce a skeleton")
end

-- Resolve col:any once and retain source-site diagnostics for an invalid colour.
local function random_colour_is_selected_once()
    local ctx = random_context()
    local selected = monster.parse("rat col:any", site)[1][1]
    local resolved = resolve.monster(ctx, selected, 1, site)

    harness.equal(resolved.colour, colours.RANDOM[1],
        "random source colour becomes a stable selected value")

    local invalid = monster.parse("rat col:not_a_colour", site)[1][1]
    local ok, reason = pcall(resolve.validate_monster, invalid, site)

    harness.falsy(ok, "invalid source colour was accepted")
    harness.truthy(reason:find(site.path, 1, true),
        "invalid colour error lacks the source site")
end

-- Resolve every authored static arrival name against the same registry used
-- during level generation.
local function every_static_arrival_name_resolves()
    local ctx = random_context()
    local checked = 0

    for _, path in ipairs(mod.paths("vaults/arrival", ".des")) do
        local vault = des.parse(path, mod.read(path))

        for _, operation in ipairs(vault.operations) do
            local parser
            local resolver

            if operation.kind == directives.MONS or operation.kind == directives.KMONS then
                parser = monster
                resolver = resolve.monster
            elseif operation.kind == directives.ITEM or operation.kind == directives.KITEM then
                parser = item
                resolver = resolve.item
            end

            if parser then
                local expression = operation.argument

                if operation.kind == directives.KMONS or operation.kind == directives.KITEM then
                    expression = expression:match("^[^=:]+[=:]%s*(.*)$")
                end

                local source = {
                    path = path,
                    vault_id = vault.id,
                    line = operation.line,
                    directive = operation.kind,
                    glyph = "?",
                }

                for _, slot in ipairs(parser.parse(expression, source)) do
                    for _, term in ipairs(slot) do
                        local selected = resolver(ctx, term, 1, source)

                        harness.truthy(selected.no_spawn or selected.kind_id,
                            path .. ": unresolved " .. term.name)

                        if resolver == resolve.monster and selected.kind_id then
                            local profile_id = selected.base_id or selected.kind_id
                            local definition = catalog.get(categories.MONSTERS, profile_id)

                            harness.truthy(definition.average_hp_10x,
                                path .. ": " .. term.name .. " has no spawn HP")
                        end
                        checked = checked + 1
                    end
                end
            end
        end
    end

    harness.truthy(checked > 100, "static arrival expressions were not visited")
end

-- Run each source hook at both random extremes to cover conditional emissions.
local function hook_api(high)
    local api = {
        emissions = {},
    }

    -- Return the low or high endpoint without relying on a live vault RNG.
    function api:roll(bound)
        return high and bound - 1 or 0
    end

    -- Derive one-in decisions from the same chosen endpoint as roll().
    function api:one_in(bound)
        return self:roll(bound) == 0
    end

    -- Keep boolean hook branches tied to the low or high scripted roll.
    function api:coinflip()
        return self:roll(2) == 0
    end

    -- Choose the first or last value to expose source hook branch differences.
    function api:random_from(values)
        return values[self:roll(#values) + 1]
    end

    -- Use inclusive bounds like the vault hook API under test.
    function api:random_range(first, last)
        return first + self:roll(last - first + 1)
    end

    -- Capture emitted directives for later parser and resolver checks.
    function api:emit(kind, argument)
        self.emissions[#self.emissions + 1] = {
            kind = kind,
            argument = argument,
        }
    end

    -- Ignore marker recording because these assertions cover entity declarations.
    function api:record()
    end

    -- Supply a stable species to hooks that branch on character identity.
    function api:player_species()
        return "SP_HUMAN"
    end

    -- Supply the matching source monster name for player-dependent hooks.
    function api:player_monster()
        return "human"
    end

    -- Keep name-dependent hook text deterministic across runs.
    function api:player_name()
        return "Test Hero"
    end

    -- Exercise pregame hook paths so declarations are available before play.
    function api:game_started()
        return false
    end

    -- Run ordinary declaration hooks rather than validation-only behaviour.
    function api:validating()
        return false
    end

    -- No marker geometry is needed to resolve emitted entity names.
    function api:marker_positions()
        return nil
    end

    -- Permit arrival hooks that require an exit to emit their declarations.
    function api:has_exit()
        return true
    end

    return api
end

-- Parse every hook-emitted entity declaration under both random endpoints.
local function handler_declarations_resolve()
    local ctx = random_context()
    local owners = {}

    for _, path in ipairs(mod.paths("vaults/arrival", ".des")) do
        local vault = des.parse(path, mod.read(path))

        for _, operation in ipairs(vault.operations) do
            if operation.kind == directives.HOOK_RUN or operation.kind == directives.HOOK_VETO then
                owners[vault.id] = true
            end

            if operation.kind == directives.HOOK_RUN then
                for _, high in ipairs({ false, true }) do
                    local api = hook_api(high)

                    hooks.run(vault, operation.argument, api)

                    for _, emitted in ipairs(api.emissions) do
                        local parser
                        local resolver

                        if emitted.kind == directives.MONS or emitted.kind == directives.KMONS then
                            parser = monster
                            resolver = resolve.monster
                        elseif emitted.kind == directives.ITEM or emitted.kind == directives.KITEM then
                            parser = item
                            resolver = resolve.item
                        end

                        if parser then
                            local expression = emitted.argument

                            if emitted.kind == directives.KMONS or emitted.kind == directives.KITEM then
                                expression = expression:match("^[^=:]+[=:]%s*(.*)$")
                            end

                            local source = {
                                path = path,
                                vault_id = vault.id,
                                line = operation.line,
                                directive = emitted.kind,
                                glyph = "?",
                            }

                            for _, slot in ipairs(parser.parse(expression, source)) do
                                for _, term in ipairs(slot) do
                                    resolver(ctx, term, 1, source)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local count = 0

    for _ in pairs(owners) do
        count = count + 1
    end

    harness.equal(count, 36, "source handler owners")
end

-- Empty depth pools should error with source site; duplicate uniques should return no-spawn.
local function missing_pool_and_unique_veto()
    local ctx = random_context()
    local random_term = monster.parse("0", site)[1][1]
    local ok, reason = pcall(resolve.monster, ctx, random_term, 999, site)

    harness.falsy(ok, "empty depth pool accepted")
    harness.truthy(reason:find(site.path, 1, true),
        "empty pool does not identify its source")

    local unique = monster.parse("Sigmund", site)[1][1]
    local first = resolve.monster(ctx, unique, 1, site)

    -- Pretend the first unique already exists when resolving the second declaration.
    function ctx:query()
        return { 1 }
    end

    -- Return that existing unique's kind ID for duplicate detection.
    function ctx:get()
        return { kind_id = first.kind_id }
    end

    harness.truthy(resolve.monster(ctx, unique, 1, site).no_spawn,
        "duplicate source unique was spawned")
end

-- Run static, random, hook, and duplicate resolution cases from one fixture.
function test.run()
    generic_corpse_species()
    legacy_source_skeleton_fault()
    random_colour_is_selected_once()
    named_and_variant_identities()
    random_requests_use_source_depth()
    every_static_arrival_name_resolves()
    handler_declarations_resolve()
    missing_pool_and_unique_veto()
end

return test
