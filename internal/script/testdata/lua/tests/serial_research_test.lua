-- Research serial maps preserve ten spell disciplines and their source maps.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local component = require("constants.component")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local catalog = require("policy.generation.vaults.catalog")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local ids = require("ids.vaults")
local items = require("ids.items")
local generation = require("policy.item_generation")
local placement = require("policy.generation.vaults.placement")
local purpose = require("constants.item_generation_purpose")
local quality = require("constants.vault_item_quality")
local schools = require("constants.spell_schools")
local tags = require("constants.vault_tags")

local test = {}

-- The source controller places four through six research rooms after its
-- chance roll. It has no map cells of its own.
local function controller_contract()
    local vault = catalog.get(ids.serial_hangedman_research)
    local requested
    local api = {}

    function api:roll(bound)
        return bound - 1
    end

    function api:place_maps(tag, count)
        requested = { tag = tag, count = count }
    end

    hooks.run(vault, "place_research", api)

    harness.equal(#vault.rows, 0, "research controller has no cells")
    harness.equal(requested.tag, tags.SERIAL_RESEARCH,
        "research child tag")
    harness.equal(requested.count, 6, "maximum source group size")
end

-- Every research child keeps its source shape and a selectable depth rule.
-- Placing all ten also exercises the shared branch-sensitive setup hook.
local function every_research_map_places()
    local count = 0

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)

        if definition.tags[tags.SERIAL_RESEARCH] then
            count = count + 1
            harness.truthy(#definition.depths > 0,
                "research child has depth rule " .. id)

            local vault = catalog.get(id)
            local builder = grid.new({})

            function builder:roll()
                return 0
            end

            local placed = placement.place(nil, builder, vault, {
                branch_id = branches.BRANCH_ELF,
                depth = 1,
                absolute_depth = 1,
                branch_bottom = 3,
            })

            harness.truthy(placed, "research map places " .. id)
            harness.equal(#vault.rows, 9, "source map height " .. id)

            local books = 0
            local stars = 0

            for _, record in ipairs(placed.records) do
                if record.kind == effects.ITEM and record.source == "D" then
                    if record.arguments.kind_id == items.BOOK_RANDART_THEME then
                        books = books + 1
                        harness.truthy(record.arguments.disc ~= "",
                            "book discipline " .. id)
                        harness.equal(record.arguments.numspells, 5,
                            "book spell count at zero roll " .. id)
                    elseif record.arguments.quality == "star" then
                        stars = stars + 1
                    end
                end
            end

            harness.equal(books, 1, "one themed book at D " .. id)
            harness.equal(stars, 1, "one star item at D " .. id)
        end
    end

    harness.equal(count, 10, "complete source research child count")
end

-- Elf research rooms request elf casters; the other branches use the wider
-- wizard and mage lottery. Keep this branch choice in the shared setup.
local function caster_pool_changes_by_branch()
    local vault = catalog.get(ids.hangedman_research_pyrotechnics)

    for _, branch_id in ipairs({
        branches.BRANCH_ELF,
        branches.BRANCH_DEPTHS,
    }) do
        local emitted = {}
        local api = {}

        function api:branch_id()
            return branch_id
        end

        function api:roll()
            return 0
        end

        function api:emit(kind, argument)
            emitted[#emitted + 1] = { kind = kind, argument = argument }
        end

        hooks.run(vault, "research_setup.fire", api)

        harness.equal(emitted[1].kind, directives.KMONS,
            "caster pool directive is first")
        local expected = branch_id == branches.BRANCH_ELF and
            "deep elf knight" or "ogre mage"

        harness.truthy(emitted[1].argument:find(expected, 1, true),
            "branch caster pool")
    end
end

-- The vault record's school and count must reach the production book
-- generator, because a typed item record without a real spell list is not
-- playable content.
local function authored_book_generates()
    local vault = catalog.get(ids.hangedman_research_pyrotechnics)
    local builder = grid.new({})
    local ctx = {}

    function builder:roll()
        return 0
    end

    function ctx:random(_, bound)
        harness.truthy(bound > 0, "book draw has choices")

        return 0
    end

    local placed = placement.place(nil, builder, vault, {
        branch_id = branches.BRANCH_DEPTHS,
        depth = 1,
        absolute_depth = 22,
        branch_bottom = 4,
    })
    local request
    local star

    for _, record in ipairs(placed.records) do
        if record.kind == effects.ITEM and record.source == "D" then
            if record.arguments.kind_id == items.BOOK_RANDART_THEME then
                request = record.arguments
            else
                star = record.arguments
            end
        end
    end

    harness.truthy(request, "authored book request exists")
    harness.truthy(star, "authored star request exists")
    harness.equal(request.generation_depth, 22,
        "book uses the floor's absolute depth")
    harness.equal(star.generation_depth, 49,
        "star boost uses the floor's absolute depth")

    local rolled = generation.roll(ctx, {
        kind_id = request.kind_id,
        depth = request.generation_depth,
        quality = quality.ORDINARY,
        allow_uniques = true,
        purpose = purpose.VAULT,
        disc = request.disc,
        numspells = request.numspells,
        site = "research book test",
    })
    local book = rolled.components[component.ITEM_RANDOM_BOOK]

    harness.truthy(book, "research item has a generated spellbook")
    harness.truthy(#book.spells > 0, "research book has spells")
    harness.equal(request.disc, schools.FIRE,
        "authored school reaches the item request")
    harness.equal(book.theme, "fire/fire", "authored school survives")
end

-- Cover the family as a unit so its shared item and Lua setup contract
-- cannot silently drift when one map changes.
function test.run()
    controller_contract()
    caster_pool_changes_by_branch()
    every_research_map_places()
    authored_book_generates()
end

return test
