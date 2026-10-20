-- Demonic and undead serials share source-sized child groups and depth rules.
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

local test = {}

-- Read the production hook request, then count only definitions carrying
-- that returned tag. The test does not keep a second list of child names.
local function controller_children(id, method, expected_tag, expected_count)
    local vault = catalog.get(id)
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

    hooks.run(vault, method, api)

    harness.equal(#vault.rows, 0, "source controller has no MAP cells")
    harness.equal(request.tag, expected_tag, "source family tag")
    harness.equal(request.count, 10, "source maximum child count")

    local children = {}

    for _, child_id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, child_id)

        if definition.tags[request.tag] then
            children[#children + 1] = child_id
        end
    end

    harness.equal(#children, expected_count, "complete child family")

    return children
end

-- Actual placement must keep fog markers and monsters as typed records;
-- parsing a child without applying its depth hook would miss both.
local function place_each_child(children, depth)
    local found = {}

    for _, id in ipairs(children) do
        local builder = grid.new({})

        for y = 1, 68 do
            for x = 1, 78 do
                builder:set(x, y, ".")
            end
        end

        -- Source glyph alternatives carry weight ten each. Retain S on
        -- the six- or seven-way fog substitution, while keeping other
        -- terrain choices open enough for placement.
        function builder:roll(bound)
            return (bound == 60 or bound == 70) and bound - 1 or 0
        end

        local placed = extra.place(nil, builder, catalog.get(id), {
            branch_id = branches.BRANCH_DUNGEON,
            depth = depth,
            branch_bottom = 15,
            protected = {},
            required = {},
            player = {
                branch_id = branches.BRANCH_DUNGEON,
                depth = depth,
                absolute_depth = depth,
                branch_bottom = 15,
            },
        })

        harness.truthy(placed, "themed serial child fits " .. id)

        for _, record in ipairs(placed.records) do
            found[record.kind] = true
        end
    end

    harness.truthy(found[effects.MONSTER], "child monsters remain typed")
    harness.truthy(found[effects.MARKER], "fog machines remain typed")

    return found
end

-- Both families should be live as whole groups and preserve the undead
-- source's custom gravestone feature name in addition to its markers.
function test.run()
    local demonic = controller_children(ids.serial_demonic,
        "place_demonic", tags.SERIAL_DEMONIC, 7)
    local undead = controller_children(ids.serial_undead,
        "place_undead", tags.SERIAL_UNDEAD, 6)
    local undead_effects = place_each_child(undead, 4)

    place_each_child(demonic, 10)

    -- Each authored depth band changes a KMONS choice. Exercise a
    -- representative child at every boundary after checking all maps.
    for _, depth in ipairs({ 2, 7, 10, 13 }) do
        place_each_child({ undead[1] }, depth)
    end

    for _, depth in ipairs({ 4, 13 }) do
        place_each_child({ demonic[1] }, depth)
    end

    harness.truthy(undead_effects[effects.FEATURE_NAME],
        "gravestone source name survives placement")
end

return test
