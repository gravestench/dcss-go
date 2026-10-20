-- Arena builder maps are preserved as individual source DES definitions.
-- They stay out of ordinary Dungeon draws until an arena world owner uses
-- their tags, while their scripts must already resolve in the Lua catalog.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local catalog = require("policy.generation.vaults.catalog")
local directives = require("constants.vault_directives")
local eligibility = require("policy.generation.vaults.eligibility")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local item_specs = require("policy.generation.vaults.specs.item")
local item_resolver = require("policy.generation.vaults.specs.resolve")
local item_generation = require("policy.item_generation")
local item_sets = require("policy.item_generation.item_sets")
local item_quality = require("constants.vault_item_quality")
local item_purpose = require("constants.item_generation_purpose")
local object_classes = require("ids.object_classes")
local fixture = require("tests.monster_ally_support_fixture")
local vault_ids = require("ids.vaults")

local test = {}
local EXPECTED_ARENA_COUNT = 22
local EXPECTED_HOOK_COUNT = 2

-- Count registered definitions from the production catalog rather than
-- keeping a second list of source names that could drift from mod content.
local function catalog_contract()
    catalog.load()

    local maps = 0
    local hooks = 0

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        if id:match("^arena_") then
            local vault = catalog.get(id)

            maps = maps + 1
            harness.truthy(#vault.rows > 0,
                id .. " lost its source MAP rows")
            harness.falsy(eligibility.depth(vault, {
                branch_id = branches.BRANCH_DUNGEON,
                depth = 10,
                branch_bottom = 15,
            }), id .. " leaked into Dungeon generation")

            for _, operation in ipairs(vault.operations) do
                if operation.kind == directives.HOOK_RUN then
                    hooks = hooks + 1
                end
            end
        end
    end

    harness.equal(maps, EXPECTED_ARENA_COUNT,
        "source arena builder map count")
    harness.equal(hooks, EXPECTED_HOOK_COUNT,
        "ported arena palette hooks")
end

-- The two colour hooks use the source's four draws and emit typed style
-- directives instead of executing inline Lua from a DES file.
local function palette_contract()
    local vault = catalog.get(vault_ids.arena_items)
    local emitted = {}
    local draws = 0
    local api = {}

    -- Return each list's first value so palette ordering is deterministic.
    function api:random_from(values)
        draws = draws + 1

        return values[1]
    end

    -- Capture the typed directives that the real vault hook API applies.
    function api:emit(kind, argument)
        emitted[#emitted + 1] = {
            kind = kind,
            argument = argument,
        }
    end

    hooks.run(vault, "arena.randomise_colours", api)

    harness.equal(draws, 4, "arena palette source draw count")
    harness.equal(emitted[1].kind, directives.COLOUR,
        "arena rock colour directive")
    harness.equal(emitted[1].argument, "X = blue",
        "arena first rock colour")
    harness.equal(emitted[2].argument, ". = blue",
        "arena first floor colour")
    harness.equal(emitted[3].kind, directives.RTILE,
        "arena rock tile directive")
    harness.equal(emitted[3].argument, "X = wall_normal",
        "arena first rock tile")
    harness.equal(emitted[4].kind, directives.FTILE,
        "arena floor tile directive")
    harness.equal(emitted[4].argument, ". = floor_normal",
        "arena first floor tile")
end

-- Authored ITEM:any class requests must reach the ordinary item picker
-- with a class constraint; a forced potion must never become a wand.
local function item_requests(ctx)
    local player = ctx:create()
    local game = fixture.context(ctx, player)

    item_sets.initialise(game, player)

    local cases = {
        {
            expression = "any",
        },
        {
            expression = "any potion",
            class_id = object_classes.OBJ_POTIONS,
        },
        {
            expression = "any wand",
            class_id = object_classes.OBJ_WANDS,
        },
    }
    local site = {
        path = "vaults/builder/arena_items.des",
        vault_id = vault_ids.arena_items,
        line = 9,
        directive = directives.ITEM,
        glyph = "?",
    }

    for _, case in ipairs(cases) do
        local selected = item_specs.parse(case.expression, site)[1][1]
        local resolved = item_resolver.item(ctx, selected, 10, site)

        harness.equal(resolved.kind_id, object_classes.OBJ_RANDOM,
            case.expression .. " random item request")
        harness.equal(resolved.class_id, case.class_id,
            case.expression .. " class constraint")

        if case.class_id then
            local rolled = item_generation.roll(game, {
                depth = 10,
                class_id = resolved.class_id,
                quality = item_quality.ORDINARY,
                purpose = item_purpose.VAULT,
                site = "arena item request test",
            })
            local definition = register.get(categories.ITEMS,
                rolled.kind_id)

            harness.equal(definition.class, case.class_id,
                case.expression .. " generated item class")
        end
    end
end

-- These contracts cover the complete source family and the one generic
-- item grammar feature its ITEM directives added to the port.
function test.run(ctx)
    catalog_contract()
    palette_contract()
    item_requests(ctx)
end

return test
