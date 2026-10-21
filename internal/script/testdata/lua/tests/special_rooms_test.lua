-- Source special rooms are variable-size parent maps filled by one of eight
-- mapless monster recipes. Check their shared production placement path so
-- registering the recipes alone cannot make this test pass.
local branches = require("ids.branches")
local catalog = require("policy.generation.vaults.catalog")
local extra = require("policy.generation.vaults.extra")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local item_specs = require("policy.generation.vaults.specs.item")
local monster_specs = require("policy.generation.vaults.specs.monster")
local operations = require("policy.generation.vaults.operations")
local resolve = require("policy.generation.vaults.specs.resolve")

local test = {}

local recipes = {
    "special_room_kobold",
    "special_room_orc",
    "special_room_bee",
    "special_room_morgue",
    "special_room_jelly",
    "special_room_mythical_zoo",
    "special_room_magic_class",
    "special_room_demon_pit",
}

local contexts = {
    {
        id = "special_room_kobold",
        branch = branches.BRANCH_DUNGEON,
        depth = 9,
        absolute = 9,
    },

    {
        id = "special_room_orc",
        branch = branches.BRANCH_DUNGEON,
        depth = 10,
        absolute = 10,
    },

    {
        id = "special_room_bee",
        branch = branches.BRANCH_DUNGEON,
        depth = 9,
        absolute = 9,
    },

    {
        id = "special_room_morgue",
        branch = branches.BRANCH_DEPTHS,
        depth = 1,
        absolute = 16,
    },

    {
        id = "special_room_jelly",
        branch = branches.BRANCH_LAIR,
        depth = 5,
        absolute = 15,
    },

    {
        id = "special_room_mythical_zoo",
        branch = branches.BRANCH_DUNGEON,
        depth = 14,
        absolute = 14,
    },

    {
        id = "special_room_magic_class",
        branch = branches.BRANCH_DEPTHS,
        depth = 1,
        absolute = 16,
    },

    {
        id = "special_room_demon_pit",
        branch = branches.BRANCH_PANDEMONIUM,
        depth = 1,
        absolute = 27,
    },

    {
        id = "special_room_kobold",
        branch = branches.BRANCH_ORC,
        depth = 1,
        absolute = 12,
    },

    {
        id = "special_room_orc",
        branch = branches.BRANCH_ORC,
        depth = 1,
        absolute = 14,
    },

    {
        id = "special_room_orc",
        branch = branches.BRANCH_ELF,
        depth = 1,
        absolute = 21,
    },

    {
        id = "special_room_bee",
        branch = branches.BRANCH_LAIR,
        depth = 3,
        absolute = 12,
    },

    {
        id = "special_room_morgue",
        branch = branches.BRANCH_CRYPT,
        depth = 1,
        absolute = 24,
    },

    {
        id = "special_room_morgue",
        branch = branches.BRANCH_DIS,
        depth = 1,
        absolute = 29,
    },

    {
        id = "special_room_morgue",
        branch = branches.BRANCH_GEHENNA,
        depth = 1,
        absolute = 29,
    },

    {
        id = "special_room_morgue",
        branch = branches.BRANCH_COCYTUS,
        depth = 1,
        absolute = 29,
    },

    {
        id = "special_room_morgue",
        branch = branches.BRANCH_TARTARUS,
        depth = 1,
        absolute = 29,
    },

    {
        id = "special_room_jelly",
        branch = branches.BRANCH_SLIME,
        depth = 2,
        absolute = 19,
    },

    {
        id = "special_room_jelly",
        branch = branches.BRANCH_DEPTHS,
        depth = 2,
        absolute = 17,
    },

    {
        id = "special_room_mythical_zoo",
        branch = branches.BRANCH_LAIR,
        depth = 3,
        absolute = 14,
    },

    {
        id = "special_room_mythical_zoo",
        branch = branches.BRANCH_ELF,
        depth = 2,
        absolute = 21,
    },

    {
        id = "special_room_magic_class",
        branch = branches.BRANCH_DEPTHS,
        depth = 4,
        absolute = 27,
    },

    {
        id = "special_room_demon_pit",
        branch = branches.BRANCH_PANDEMONIUM,
        depth = 1,
        absolute = 27,
        runes = 5,
    },
}

-- Give every recipe the same local rectangle a parent SUBVAULT provides.
-- This exercises the source hook and entity resolver for all eight recipes,
-- including rooms that the two deterministic parent draws do not select.
local function place_recipe(context)
    local cells = {}

    for y = 1, 3 do
        cells[y] = {}

        for x = 1, 4 do
            cells[y][x] = " "
        end
    end

    local builder = grid.new({})

    -- Pick the first source alternative so each recipe stays reproducible.
    function builder:roll(_)
        return 0
    end

    local records = operations.apply(catalog.get(context.id), cells,
        builder, 0, {
            branch_id = context.branch,
            depth = context.depth,
            absolute_depth = context.absolute,
            branch_bottom = 15,
            pan_rune_count = context.runes or 0,
        })
    local monster = false
    local source = catalog.get(context.id)
    local site = {
        path = source.path,
        vault_id = source.id,
        line = 1,
    }
    local random = {}

    -- Resolve each emitted choice through production parsers without making
    -- this test depend on an unrelated random stream.
    function random:random(_stream, _bound)
        return 0
    end

    for _, record in ipairs(records) do
        monster = monster or record.kind == "monster"

        if record.kind == "monster" then
            for _, slot in ipairs(monster_specs.parse(record.identity, site)) do
                for _, selected in ipairs(slot) do
                    resolve.monster(random, selected, context.absolute, site)
                end
            end
        elseif record.kind == "item" then
            for _, slot in ipairs(item_specs.parse(record.identity, site)) do
                for _, selected in ipairs(slot) do
                    resolve.item(random, selected, context.absolute, site)
                end
            end
        end
    end

    harness.truthy(monster, context.id .. " emits its monster recipe")
end

-- The room parent must build its own dimensions before its tagged helper
-- paints occupants; neither parent nor child has a static source MAP.
local function place_room(id, branch_id, depth, absolute_depth)
    local builder = grid.new({})

    for y = 1, 68 do
        for x = 1, 78 do
            builder:set(x, y, ".")
        end
    end

    -- Standalone placement uses a fixed layout draw; integrated Go tests
    -- will exercise the saved RNG stream through normal floor generation.
    function builder:roll(_)
        return 0
    end

    local player = {
        branch_id = branch_id,
        depth = depth,
        absolute_depth = absolute_depth,
        branch_bottom = 15,
        pan_rune_count = 0,
    }
    local placed = extra.place(nil, builder, catalog.get(id), {
        branch_id = branch_id,
        depth = depth,
        branch_bottom = 15,
        protected = {},
        required = {},
        player = player,
    })

    harness.truthy(placed, "special room fits " .. id)
    harness.truthy(placed.bounds.width >= 6 and
        placed.bounds.width <= 8, "source room width")
    harness.truthy(placed.bounds.height >= 5 and
        placed.bounds.height <= 9, "source room height")
    harness.equal(#placed.vault_ids, 1, "one tagged room recipe is selected")

    local monster = false

    for _, record in ipairs(placed.records) do
        monster = monster or record.kind == "monster"
    end

    harness.truthy(monster, "room recipe produces monster placement records")
end

-- Each recipe must be discoverable by the same catalog used by SUBVAULT.
-- The normal and Vaults parents use that pool at their source CHANCE.
function test.run()
    for _, id in ipairs(recipes) do
        local recipe = catalog.get(id)

        harness.truthy(recipe.tags.special_room, id .. " keeps its source tag")
        harness.equal(#recipe.rows, 0, id .. " remains a mapless recipe")
    end

    for _, context in ipairs(contexts) do
        place_recipe(context)
    end

    -- Bee-room loot uses a source corpse modifier that must survive both
    -- production parsing and item resolution before ECS creation.
    local site = {
        path = "vaults/builder/special_room_bee.des",
        vault_id = "special_room_bee",
        line = 6,
    }
    local selected = item_specs.parse("never_decay yak corpse", site)[1][1]
    local corpse = resolve.item(nil, selected, 9, site)

    harness.truthy(corpse.never_decay,
        "source bee corpse keeps the never_decay item modifier")

    place_room("special_room", branches.BRANCH_DUNGEON, 10, 10)
    place_room("special_room_vaults", branches.BRANCH_VAULTS, 1, 18)
end

return test
