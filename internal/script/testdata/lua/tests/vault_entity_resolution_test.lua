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

local function random_context(draws)
    local ctx = {
        draws = draws or {},
        count = 0,
    }

    function ctx:random(stream, bound)
        self.count = self.count + 1
        local draw = self.draws[self.count] or 0

        harness.truthy(draw < bound, "random draw exceeds " .. stream)

        return draw
    end

    return ctx
end

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

local function hook_api(high)
    local api = {
        emissions = {},
    }

    function api:roll(bound)
        return high and bound - 1 or 0
    end

    function api:one_in(bound)
        return self:roll(bound) == 0
    end

    function api:coinflip()
        return self:roll(2) == 0
    end

    function api:random_from(values)
        return values[self:roll(#values) + 1]
    end

    function api:random_range(first, last)
        return first + self:roll(last - first + 1)
    end

    function api:emit(kind, argument)
        self.emissions[#self.emissions + 1] = {
            kind = kind,
            argument = argument,
        }
    end

    function api:record()
    end

    function api:player_species()
        return "SP_HUMAN"
    end

    function api:player_monster()
        return "human"
    end

    function api:player_name()
        return "Test Hero"
    end

    function api:game_started()
        return false
    end

    function api:validating()
        return false
    end

    function api:marker_positions()
        return nil
    end

    function api:has_exit()
        return true
    end

    return api
end

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

local function missing_pool_and_unique_veto()
    local ctx = random_context()
    local random_term = monster.parse("0", site)[1][1]
    local ok, reason = pcall(resolve.monster, ctx, random_term, 999, site)

    harness.falsy(ok, "empty depth pool accepted")
    harness.truthy(reason:find(site.path, 1, true),
        "empty pool does not identify its source")

    local unique = monster.parse("Sigmund", site)[1][1]
    local first = resolve.monster(ctx, unique, 1, site)

    function ctx:query()
        return { 1 }
    end

    function ctx:get()
        return { kind_id = first.kind_id }
    end

    harness.truthy(resolve.monster(ctx, unique, 1, site).no_spawn,
        "duplicate source unique was spawned")
end

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
