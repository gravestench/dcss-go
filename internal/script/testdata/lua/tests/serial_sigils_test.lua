-- Sigils are fourteen source shapes selected by one rare branch controller.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local directives = require("constants.vault_directives")
local catalog = require("policy.generation.vaults.catalog")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local ids = require("ids.vaults")
local placement = require("policy.generation.vaults.placement")
local tags = require("constants.vault_tags")

local test = {}

-- The source controller requests four through six weighted shapes after
-- its branch-specific chance; it does not author terrain itself.
local function controller_contract()
    local vault = catalog.get(ids.serial_sigils)
    local request
    local api = {}

    function api:roll(bound)
        return bound - 1
    end

    function api:place_maps(tag, count)
        request = {
            tag = tag,
            count = count,
        }
    end

    hooks.run(vault, "place_sigils", api)

    harness.equal(#vault.rows, 0, "sigils controller has no MAP cells")
    harness.equal(request.tag, tags.SERIAL_SIGILS,
        "source sigils child tag")
    harness.equal(request.count, 6, "source maximum sigils count")
end

-- The four heavy, five medium, and five light shapes keep their source
-- weights while each map retains the shared floor and wall decoration.
local function every_shape_places()
    local counts = {
        [5] = 0,
        [4] = 0,
        [3] = 0,
    }

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)

        if definition.tags[tags.SERIAL_SIGILS] then
            local vault = catalog.get(id)
            local builder = grid.new({})

            function builder:roll()
                return 0
            end

            local placed = placement.place(nil, builder, vault, {
                branch_id = branches.BRANCH_DEPTHS,
                depth = 2,
                branch_bottom = 5,
                layout_family = "open",
            })

            harness.truthy(placed, "sigil shape places " .. id)
            harness.truthy(#vault.rows > 0, "sigil MAP rows " .. id)
            harness.truthy(definition.tags.extra, "shared extra tag " .. id)
            harness.truthy(definition.tags.decor, "shared decor tag " .. id)
            harness.truthy(definition.tags.transparent,
                "shared transparent tag " .. id)
            local tiles = 0

            for _, operation in ipairs(vault.operations) do
                if operation.kind == directives.TILE or
                    operation.kind == directives.FTILE then
                    tiles = tiles + 1
                end
            end

            harness.equal(tiles, 3, "shared sigil surface rules " .. id)
            counts[definition.weight] = counts[definition.weight] + 1
        end
    end

    harness.equal(counts[5], 4, "heavy source sigils")
    harness.equal(counts[4], 5, "medium source sigils")
    harness.equal(counts[3], 5, "light source sigils")
end

-- Cover family selection and every authored shape as one content slice.
function test.run()
    controller_contract()
    every_shape_places()
end

return test
