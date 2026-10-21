-- The source Shoals branch has one effective DES family for ordinary maps.
-- This test reads the production catalog, so a missing or malformed file
-- cannot be hidden by a second test-only definition list.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local component = require("constants.component")
local harness = require("tests.harness")
local grid = require("policy.generation.grid")
local item_catalog = require("policy.catalog")
local item_ids = require("ids.items")
local item_specs = require("policy.generation.vaults.specs.item")
local placement = require("policy.generation.vaults.placement")
local random_books = require("policy.item_generation.random_books")
local regular = require("policy.generation.vaults.regular")
local resolve = require("policy.generation.vaults.specs.resolve")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- Give each authored map an independent deterministic layout stream so a
-- failed source script names its own vault rather than a previous map's RNG.
local function random_context()
    local state = 71
    local context = {}

    function context:random_u64()
        state = (state * 48271) % 2147483647
        local high = state

        state = (state * 48271) % 2147483647

        return high, state
    end

    return context
end

-- Exercise the production DES operation path for every Shoals definition.
-- This includes emitted Lua directives, keyed actors, shops, and remains.
local function place_all()
    local placed = 0

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = vaults.get(id)

        if definition.family == "shoals" then
            local builder = grid.new(random_context())
            local player = {
                branch_id = branches.BRANCH_SHOALS,
                depth = 2,
                branch_bottom = 4,
                absolute_depth = 16,
            }
            local okay, result = pcall(placement.place, nil, builder,
                definition, player)

            harness.truthy(okay, id .. " placement: " .. tostring(result))
            harness.truthy(result and #result.occupied > 0,
                id .. " placed no source cells")
            placed = placed + 1
        end
    end

    harness.equal(placed, 74, "every ordinary Shoals MAP places")
end

-- The source's named book must retain its title after ordinary random-book
-- generation chooses and saves the two authored spells.
local function authored_book_title()
    local definition = vaults.get("dreamdust_from_the_deep")

    for _, operation in ipairs(definition.operations) do
        if operation.argument and
            operation.argument:find("title:Mad_Ravings", 1, true) then
            local site = {
                path = definition.path,
                vault_id = definition.id,
                line = operation.line,
                directive = operation.kind,
            }
            local selected = item_specs.parse(operation.argument, site)[1][1]
            local request = resolve.item({}, selected, 16, site)
            local random = {}

            function random:random(_, bound)
                harness.truthy(bound > 0, "random book draw bound")

                return 0
            end

            local result = { components = {} }

            random_books.roll(random,
                item_catalog.get("items", item_ids.BOOK_RANDART_THEME), {
                    numspells = request.numspells,
                    included_spells = request.spells,
                    title = request.title,
                }, result)

            harness.equal(result.components[component.ITEM_ARTEFACT].name,
                "Mad Ravings", "DES title survives book generation")

            return
        end
    end

    error("dreamdust_from_the_deep lost its source title")
end

-- Count complete source coverage and prove ordinary Shoals selection can
-- discover the authored family at the correct branch depth.
function test.run()
    vaults.load()

    local count = 0

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        if vaults.get(id).family == "shoals" then
            count = count + 1
        end
    end

    harness.equal(count, 74, "all source ordinary Shoals maps")

    local candidates = regular.candidates({
        branch_id = branches.BRANCH_SHOALS,
        depth = 2,
        branch_bottom = 4,
        absolute_depth = 16,
        branch_vault_family = "shoals",
    })

    harness.truthy(#candidates > 0,
        "ordinary Shoals maps join the weighted live selector")

    place_all()
    authored_book_title()
end

return test
