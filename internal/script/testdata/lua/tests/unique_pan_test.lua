-- Pan veto hooks read the same saved player rune and unique ledgers as
-- ordinary pickup and monster creation. Their source chance must not be
-- rerolled after Ignacio's first permanent decision.
local component = require("constants.component")
local connect = require("policy.generation.vaults.connect")
local extra = require("policy.generation.vaults.extra")
local grid = require("policy.generation.grid")
local catalog = require("policy.generation.vaults.catalog")
local decisions = require("constants.pan_unique_decision")
local effects = require("constants.vault_effects")
local harness = require("tests.harness")
local history = require("policy.population.unique_history")
local monsters = require("ids.monsters")
local rune_ids = require("constants.runes")
local runes = require("policy.character.runes")

local test = {}

-- The veto contract requires a player owner, but no map geometry is needed
-- for a one-cell no-exits Pan candidate.
local function world_context(ctx)
    local world = setmetatable({}, { __index = ctx })
    local player = ctx:create()

    ctx:add(player, component.PLAYER_UNIQUE_HISTORY, {
        status = {},
        monsters = {},
        pan_states = {},
    })
    runes.initialise(world, player)

    -- The source hooks read the player from the game context.
    function world:player()
        return player
    end

    return world, player
end

-- Use the real named hook path with a minimal placed map record. A true
-- veto fails before connector work because source Pan maps have no exits.
local function candidate(name, method)
    return {
        id = name,
        family = "unique",
        path = "vaults/unique/" .. name .. ".des",
        tags = {
            no_exits = true,
        },
        exits = {},
        records = {
            {
                kind = effects.VETO,
                method = "pan_unique." .. method,
                line = 1,
            },
        },
    }
end

-- Fail when a hook draws unexpectedly, so the persistent-state assertion
-- also proves that later Pan levels do not reroll Ignacio's coinflip.
local function random(draws)
    local builder = {
        index = 0,
    }

    function builder:roll(bound)
        self.index = self.index + 1
        local value = draws[self.index]

        if value == nil or value < 0 or value >= bound then
            error("unexpected Pan veto draw " .. self.index)
        end

        return value
    end

    return builder
end

-- The fiery lord requires his rune and remains forbidden after his first
-- actor appears, even if that actor is later removed from the level.
local function lord_rune_and_history(world, player)
    local map = candidate("uniq_cerebov", "cerebov")
    local ok = pcall(connect.finish, world, random({}), map, {})

    harness.falsy(ok, "Cerebov appeared before his rune")

    local builder = grid.new(world)

    -- A vetoed extra map restores its cells and returns no placement. It
    -- must not abort the level or retry the same already-vetoed candidate.
    function builder:roll()
        return 0
    end

    local placed = extra.place(world, builder,
        catalog.get("uniq_cerebov"), {
            protected = {},
            required = {},
            player = {},
        })

    harness.falsy(placed, "vetoed Pan map was retained")
    runes.collect(world, player, rune_ids.FIERY)
    harness.equal(connect.finish(world, random({}), map, {}), map,
        "Cerebov stays eligible after the rune")
    history.mark(world, monsters.MONS_CEREBOV)
    harness.falsy(pcall(connect.finish, world, random({}), map, {}),
        "Cerebov appeared twice in one run")
end

-- A failed rune-squared chance makes no state. The first successful gate
-- stores one allow decision, and later levels consume no second draw.
local function ignacio_decision(world, player)
    local map = candidate("uniq_ignacio", "ignacio")

    harness.falsy(pcall(connect.finish, world, random({ 1 }), map, {}),
        "Ignacio passed a failed rune chance")
    harness.falsy(history.pan_state(world, monsters.MONS_IGNACIO),
        "failed chance consumed the permanent decision")

    runes.collect(world, player, rune_ids.DARK)
    runes.collect(world, player, rune_ids.GLOWING)
    runes.collect(world, player, rune_ids.MAGICAL)
    harness.equal(runes.pan_count(world, player), 4,
        "only four Pan runes count for Ignacio")

    connect.finish(world, random({ 0, 1 }), map, {})
    harness.equal(history.pan_state(world, monsters.MONS_IGNACIO),
        decisions.ALLOW, "Ignacio's decision was not saved")
    harness.equal(connect.finish(world, random({}), map, {}), map,
        "Ignacio rerolled a decided encounter")
end

-- Exercise vetoes through the actual connector and saved ECS owners.
function test.run(ctx)
    local world, player = world_context(ctx)

    lord_rune_and_history(world, player)
    ignacio_decision(world, player)
end

return test
