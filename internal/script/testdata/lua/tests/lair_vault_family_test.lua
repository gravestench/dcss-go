-- The source Lair family must enter each of its three live selection stages.
-- Read the effective catalog so a sparse mod follows the same registration.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local entry = require("policy.generation.vaults.branch_entry")
local endings = require("policy.generation.vaults.end")
local extra = require("policy.generation.vaults.extra")
local effects = require("constants.vault_effects")
local directives = require("constants.vault_directives")
local features = require("constants.vault_features")
local families = require("constants.vault_families")
local tags = require("constants.vault_tags")
local generated = require("policy.generation.generated")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local placement = require("policy.generation.vaults.placement")
local vaults = require("policy.generation.vaults.catalog")
local rules = require("constants.vault_generation_rules")
local used = require("policy.generation.vaults.used")
local saved_vaults = require("policy.save.vaults")

local test = {}

-- Use one reproducible stream per source map while still going through the
-- production placement owner, including its substitutions and validation.
local function random_context()
    local value = 71
    local context = {}

    function context:random_u64()
        value = (value * 48271) % 2147483647
        local high = value

        value = (value * 48271) % 2147483647

        return high, value
    end

    return context
end

-- All source entries must place exactly one keyed stair intent. A valid
-- catalog alone would miss a broken MONS, SUBST, or Lua hook at runtime.
local function entry_contract()
    local choices = entry.candidates(branches.BRANCH_LAIR)

    harness.equal(#choices, 13, "all source Lair entries are selectable")

    for _, choice in ipairs(choices) do
        local definition = vaults.get(choice.definition.id)
        local builder = grid.new(random_context())
        local player = {
            branch_id = branches.BRANCH_DUNGEON,
            depth = 10,
            branch_bottom = 15,
            absolute_depth = 10,
        }
        local placed = placement.place(nil, builder, definition, player)
        local stairs = 0

        for _, record in ipairs(placed.records) do
            if record.kind == effects.FEATURE and
                record.identity == features.ENTER_LAIR then
                stairs = stairs + 1
            end
        end

        harness.equal(stairs, 1, definition.id .. " keyed Lair stair")
    end
end

-- Compare source-family counts before placement tests can hide a missing MAP
-- behind an unrelated eligible definition from the global vault catalog.
local function family_counts()
    local expected = {
        [families.LAIR_ENTRY] = 13,
        [families.LAIR] = 89,
        [families.LAIR_END] = 14,
    }
    local actual = {
        [families.LAIR_ENTRY] = 0,
        [families.LAIR] = 0,
        [families.LAIR_END] = 0,
    }

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = vaults.get(id)

        if actual[definition.family] then
            actual[definition.family] = actual[definition.family] + 1
        end
    end

    for family, count in pairs(expected) do
        harness.equal(actual[family], count, family .. " source definitions")
    end
end

-- Entry and ending selection must come from the same effective definitions
-- that mods can extend; a source file count alone does not prove wiring.
local function selection_contract()
    local choices = entry.candidates(branches.BRANCH_LAIR)

    harness.truthy(#choices > 0, "weighted Lair entry pool")

    local last_floor = endings.candidates({
        branch_id = branches.BRANCH_LAIR,
        depth = 5,
        branch_bottom = 5,
        absolute_depth = 14,
        end_vault_family = families.LAIR_END,
    })

    harness.equal(#last_floor, 14, "mandatory Lair:5 ending pool")
end

-- Drive every source MAP through substitutions, entity resolution, and its
-- named hooks. Counts alone would miss a malformed source token or a helper
-- that loads but fails when its map is selected on an actual floor.
local function place_all_maps()
    local counts = {
        [families.LAIR] = 0,
        [families.LAIR_END] = 0,
    }

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = vaults.get(id)

        if counts[definition.family] and #definition.rows > 0 then
            local builder = grid.new(random_context())
            local player = {
                branch_id = branches.BRANCH_LAIR,
                depth = definition.family == families.LAIR_END and 5 or 2,
                branch_bottom = 5,
                absolute_depth = definition.family == families.LAIR_END and 14 or 11,
            }
            local okay, placed = pcall(placement.place, nil, builder,
                definition, player)

            harness.truthy(okay, id .. " placement: " .. tostring(placed))
            harness.truthy(placed and #placed.occupied > 0,
                id .. " placed no authored cells")
            counts[definition.family] = counts[definition.family] + 1
        end
    end

    harness.equal(counts[families.LAIR_END], 14,
        "all source Lair endings place")
    harness.truthy(counts[families.LAIR] > 0, "ordinary Lair MAPs place")
end

-- The rare large Beast Lair pack must suppress ambient spawns over only
-- its selected map. A static tag on every small map would change the other
-- twenty-four draws, so verify the emitted map-local rule instead.
local function beast_rule()
    local definition = vaults.get("beast_lair_carwin_large_1")
    local builder = grid.new(random_context())
    local player = {
        branch_id = branches.BRANCH_LAIR,
        depth = 2,
        branch_bottom = 5,
        absolute_depth = 11,
    }
    local placed = placement.place(nil, builder, definition, player)
    local found = false

    for _, record in ipairs(placed.records) do
        if record.kind == effects.GENERATION_RULE and
            record.arguments and
            record.arguments.rule == rules.NO_MONSTER_GEN then
            harness.equal(record.arguments.scope, rules.VAULT,
                "beast rule applies to one placed map")
            found = true
        end
    end

    harness.truthy(found, "large Beast Lair suppresses ambient monsters")

    local excluded = generated.spawn_exclusions(placed, definition)

    harness.equal(#excluded, #placed.occupied,
        "saved Beast Lair rule excludes every occupied map cell")
end

-- Depth-sensitive woods must change their MONS slots without changing
-- source file order or mutating a shared catalog definition.
local function woods_depth()
    local woods = require("policy.generation.vaults.lair.woods")
    local emitted = {}
    local api = {}

    function api:branch_id()
        return branches.BRANCH_LAIR
    end

    function api:absolute_depth()
        return 14
    end

    function api:emit(kind, argument)
        emitted[#emitted + 1] = {
            kind = kind,
            argument = argument,
        }
    end

    woods.populate(api)

    harness.equal(emitted[1].kind, directives.MONS,
        "Wad woods source monster operation")
    harness.equal(emitted[1].argument, "spriggan",
        "Lair woods keep source spriggan slot")
    harness.equal(emitted[2].argument,
        "wolf / black bear w:4 / yak w:2",
        "deep Lair woods use their source beast band")
end

-- Supply a floor of ordinary terrain so the actual end fitter can try all
-- authored orientations without a prior random layout hiding a bad map.
local function plain_floor()
    local ctx = random_context()
    local builder = grid.new(ctx)

    for y = 1, 68 do
        for x = 1, 78 do
            builder:set(x, y, ".")
        end
    end

    return ctx, builder
end

-- Capture the same Lair:5 facts that the live branch generator supplies.
local function ending_context(id)
    local player = {
        branch_id = branches.BRANCH_LAIR,
        depth = 5,
        branch_bottom = 5,
        absolute_depth = 14,
    }

    return {
        branch_id = player.branch_id,
        depth = player.depth,
        branch_bottom = player.branch_bottom,
        absolute_depth = player.absolute_depth,
        end_vault_family = families.LAIR_END,
        end_choice = { id = id },
        protected = {},
        required = {},
        player = player,
        used = used.new({}),
    }
end

-- Every Lair:5 primary must fit through the actual mandatory end stage.
-- Small ones must add exactly one different source partner; ordinary ends
-- remain alone. All selected IDs must enter durable placement history.
local function place_all_endings()
    local count = 0
    local paired = 0

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = vaults.get(id)

        if definition.family == families.LAIR_END then
            local ctx, builder = plain_floor()
            local context = ending_context(id)
            local placed = {}
            local okay, selected = pcall(endings.place, ctx, builder,
                context, placed, extra.place)

            harness.truthy(okay, id .. " end placement: " ..
                tostring(selected))
            harness.equal(selected, id, "ending remains primary")

            if definition.tags[tags.LAIR_END_SMALL] then
                harness.equal(#placed, 2, "small ending has one paired map")
                harness.truthy(placed[2].id ~= id,
                    "a small ending cannot pair with itself")
                harness.equal(vaults.get(placed[2].id).family,
                    families.LAIR_END, "small partner stays in ending family")
                harness.equal(#context.used:ids(), 2,
                    "paired ending IDs enter saved history")
                paired = paired + 1
            else
                harness.equal(#placed, 1,
                    "ordinary ending adds no paired map")
            end

            count = count + 1
        end
    end

    harness.equal(count, 14, "all source Lair:5 endings fit")
    harness.equal(paired, 5, "all source small endings pair")
end

-- Save validation must reject a missing partner even if the selected small
-- ending itself still resolves. This is the source persistence guard's
-- durable equivalent, checked against actual catalog tags on restore.
local function saved_pair_contract()
    local context = {}

    -- The common save pass also checks live Slime seals; this Lair-only
    -- fixture has no such entities.
    function context:query()
        return {}
    end

    local level = {
        id = "Lair:5",
        branch_id = branches.BRANCH_LAIR,
        local_depth = 5,
        vault_id = "wormcave",
        vault_ids = {
            "wormcave",
        },
        vault_records = {},
    }
    local okay = pcall(saved_vaults.validate, context, {
        levels = { level },
    })

    harness.falsy(okay, "small ending without partner cannot restore")

    level.vault_ids[2] = "hangedman_lair_in_review"

    local valid, reason = pcall(saved_vaults.validate, context, {
        levels = { level },
    })

    harness.truthy(valid, "small ending with partner restores: " ..
        tostring(reason))
end

-- If all child shapes conflict, the floor builder must recognize a fit
-- failure and redraw its base layout while retaining the primary choice.
local function paired_fit_failure()
    local api = {}

    function api:place_maps()
        return 0
    end

    local okay, message = pcall(hooks.run, vaults.get("wormcave"),
        "small_end.pair", api)

    harness.falsy(okay, "missing small partner rejects the floor")
    harness.truthy(tostring(message):find(
        "end vault could not fit on base layout:", 1, true),
        "paired fit failure requests a base-layout redraw")
end

-- The child pool must obey the same family and distinct-ID rules as save
-- validation, even if a mod tags an unrelated or duplicate-enabled map.
local function paired_selection_contract()
    local handler = require("policy.generation.vaults.lair_end.small_end")
    local api = {
        controller_id = "wormcave",
    }

    function api:place_maps(tag, count, options)
        harness.equal(tag, tags.LAIR_END_SMALL, "small ending tag")
        harness.equal(count, 1, "exactly one partner")
        harness.equal(options.family, families.LAIR_END, "partner family")
        harness.equal(options.exclude_id, self.controller_id,
            "primary ending excluded")

        return 1
    end

    handler.pair(api)
end

-- Catalog registration precedes source selection in a real game as well.
function test.run()
    vaults.load()
    entry_contract()
    family_counts()
    selection_contract()
    place_all_maps()
    beast_rule()
    woods_depth()
    place_all_endings()
    saved_pair_contract()
    paired_fit_failure()
    paired_selection_contract()
end

return test
