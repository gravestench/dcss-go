-- The early-Dungeon gnoll camp consists of one controller and twelve pieces.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local catalog = require("policy.generation.vaults.catalog")
local effects = require("constants.vault_effects")
local extra = require("policy.generation.vaults.extra")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local ids = require("ids.vaults")
local tags = require("constants.vault_tags")
local used = require("policy.generation.vaults.used")

local test = {}

-- The source controller rolls a high chance only on open D:5-10 layouts,
-- then requests four to six tagged pieces rather than a fixed lineup.
local function controller_contract()
    local vault = catalog.get(ids.serial_gnoll_camp)
    local requested
    local api = {}

    function api:roll(bound)
        return bound - 1
    end

    function api:place_maps(tag, count)
        requested = {
            tag = tag,
            count = count,
        }
    end

    hooks.run(vault, "place_gnoll_camp", api)

    harness.equal(#vault.rows, 0, "controller has no MAP cells")
    harness.equal(requested.tag, tags.SERIAL_GNOLL_CAMP,
        "source child tag")
    harness.equal(requested.count, 6, "source maximum group size")

    return requested.tag
end

-- Every child must fit and retain its typed monster instructions. Source
-- default-depth is reset after the controller, so these tagged helpers
-- must not enter the ordinary weighted Dungeon minivault draw.
local function every_piece_places(tag)
    local count = 0
    local saw_shop = false

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)

        if definition.tags[tag] then
            count = count + 1
            harness.equal(#definition.depths, 0,
                "gnoll child is tag-only: " .. id)

            local builder = grid.new({})

            for y = 1, 68 do
                for x = 1, 78 do
                    builder:set(x, y, ".")
                end
            end

            function builder:roll()
                return 0
            end

            local placed = extra.place(nil, builder, catalog.get(id), {
                branch_id = branches.BRANCH_DUNGEON,
                depth = 6,
                branch_bottom = 15,
                layout_family = "open",
                protected = {},
                required = {},
                player = {
                    branch_id = branches.BRANCH_DUNGEON,
                    depth = 6,
                    branch_bottom = 15,
                },
            })

            harness.truthy(placed, "gnoll camp piece fits " .. id)

            local monsters = 0

            for _, record in ipairs(placed.records) do
                if record.kind == effects.MONSTER then
                    monsters = monsters + 1
                elseif record.kind == effects.FEATURE and
                    record.identity == "any shop" then
                    saw_shop = true
                end
            end

            harness.truthy(monsters > 0,
                "gnoll camp retains monsters " .. id)
        end
    end

    harness.equal(count, 12, "complete source child family")
    harness.truthy(saw_shop, "mini shop keeps its feature intent")
end

-- The two larger hut maps share a source uniq_* tag; using one on a run
-- excludes the other even though they have distinct NAME values.
local function hut_uniqueness()
    local history = used.new({})
    local basic = catalog.get(ids.gnoll_camp_huts_basic)
    local moat = catalog.get(ids.gnoll_camp_huts_moat)

    history:add(basic)

    harness.falsy(history:allows(moat),
        "shared hut uniqueness survives a different map name")
end

-- Cover selection, full child placement, and shared name use together.
function test.run()
    every_piece_places(controller_contract())
    hut_uniqueness()
end

return test
