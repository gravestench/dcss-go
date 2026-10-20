-- The source river and bayou serial families share water terrain, but
-- retain separate chance controllers and tagged child pools.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local effects = require("constants.vault_effects")
local catalog = require("policy.generation.vaults.catalog")
local extra = require("policy.generation.vaults.extra")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local ids = require("ids.vaults")

local test = {}

-- Read a controller's requested tag from its real Lua hook so this test
-- does not repeat the source tag string in another handwritten catalog.
local function controller_request(id, method)
    local requested_tag
    local requested_count
    local api = {}

    -- One draw makes the source count formula observable for either family.
    function api:roll()
        return 1
    end

    -- Capture the production hook's request without a geometric mutation.
    function api:place_maps(tag, count)
        requested_tag = tag
        requested_count = count
    end

    local definition = catalog.get(id)

    harness.equal(#definition.rows, 0,
        "water controller has no MAP cells: " .. id)
    hooks.run(definition, method, api)

    return requested_tag, requested_count
end

-- The registered child count must match every source NAME in each family,
-- while unrelated serial maps remain outside its selection pool.
local function children_for(tag)
    local children = {}

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)

        if definition.tags[tag] then
            children[#children + 1] = id
        end
    end

    return children
end

-- Apply each child through the production geometric and typed-effect
-- path; a parsed but unplaceable map would be dead content for modders.
local function each_child_places(tag, names)
    local seen_effects = {}

    for _, id in ipairs(names) do
        local builder = grid.new({})

        for y = 1, 68 do
            for x = 1, 78 do
                builder:set(x, y, ".")
            end
        end

        -- Keep substitutions and the origin repeatable across each map.
        function builder:roll()
            return 0
        end

        local placed = extra.place(nil, builder, catalog.get(id), {
            branch_id = branches.BRANCH_DUNGEON,
            depth = 4,
            branch_bottom = 15,
            protected = {},
            required = {},
            player = {
                branch_id = branches.BRANCH_DUNGEON,
                depth = 4,
                branch_bottom = 15,
                map_tag = tag,
            },
        })

        harness.truthy(placed, "water serial child fits " .. id)

        for _, record in ipairs(placed.records) do
            seen_effects[record.kind] = true
        end
    end

    return seen_effects
end

-- River and bayou controllers both request five children for draw one,
-- but their different child tags must never share a pool.
function test.run()
    local river_tag, river_count = controller_request(ids.serial_rivers,
        "place_serial_rivers")
    local bayou_tag, bayou_count = controller_request(ids.serial_bayou,
        "place_serial_bayou")
    local rivers = children_for(river_tag)
    local bayous = children_for(bayou_tag)

    harness.equal(river_count, 5, "source river count")
    harness.equal(bayou_count, 5, "source bayou count")
    harness.equal(#rivers, 13, "complete river child family")
    harness.equal(#bayous, 12, "complete bayou child family")

    local river_effects = each_child_places(river_tag, rivers)
    local bayou_effects = each_child_places(bayou_tag, bayous)

    harness.truthy(river_effects[effects.MASK],
        "river water retains its no-monster mask")
    harness.truthy(bayou_effects[effects.MONSTER],
        "bayou plants remain typed monster intent")
end

return test
