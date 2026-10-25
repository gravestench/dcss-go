-- Spell conduct uses real source spell metadata and the production worship
-- component. It should not duplicate school or flag declarations in tests.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local species = require("ids.species")
local spells = require("ids.spells")
local conduct = require("policy.religion.conduct.spells")

local test = {}

-- Conduct can start the source XP-fed wrath clock, so each spell test uses
-- the player's real identity and progression schemas as well as worship.
local function new_player(ctx)
    local entity = ctx:create()

    ctx:add(entity, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })
    ctx:add(entity, component.PROGRESSION, {
        level = 1,
    })

    return entity
end

-- Trog's successful spell punishment uses one five-sided source draw to
-- choose severity, then applies loss hysteresis and penance separately.
local function trog_cast(ctx)
    local player = new_player(ctx)
    local observed = setmetatable({}, { __index = ctx })
    local draws = 0

    function observed:player()
        return player
    end

    function observed:random(stream, bound)
        harness.equal(stream, "religion")
        if bound == 5 then
            draws = draws + 1
        else
            harness.equal(bound, 200)
        end

        return 0
    end

    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.TROG,
        piety = 50,
    })

    conduct.on_success(observed, player,
        catalog.get(categories.SPELLS, spells.SPELL_MAGIC_DART))

    local state = ctx:get(player, component.RELIGION_WORSHIP)

    harness.equal(state.piety, 50)
    harness.equal(state.piety_hysteresis, 1)
    harness.equal(state.penance[gods.TROG], 5)
    harness.equal(draws, 1)
end

-- Starting a real memorisation delay is a casting conduct in the source,
-- with severity two through six. Merely inspecting a book is not an act.
local function trog_memorise(ctx)
    local player = new_player(ctx)
    local observed = setmetatable({}, { __index = ctx })

    function observed:player()
        return player
    end

    function observed:random(stream, bound)
        harness.equal(stream, "religion")
        harness.truthy(bound == 5 or bound == 200)

        return 0
    end

    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.TROG,
        piety = 50,
    })

    conduct.on_memorise(observed)

    local state = ctx:get(player, component.RELIGION_WORSHIP)

    harness.equal(state.piety_hysteresis, 1)
    harness.equal(state.piety, 49)
    harness.equal(state.penance[gods.TROG], 10)
end

-- Necromancy without the source's not_evil flag offends Zin by ten plus
-- spell level, before the ordinary successful-cast event is considered.
local function zin_necromancy(ctx)
    local player = new_player(ctx)
    local observed = setmetatable({}, { __index = ctx })

    function observed:player()
        return player
    end

    function observed:random(stream, bound)
        harness.equal(stream, "religion")
        harness.truthy(bound == 5 or bound == 200)

        return 0
    end

    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.ZIN,
        piety = 50,
    })

    conduct.on_success(observed, player,
        catalog.get(categories.SPELLS, spells.SPELL_ANIMATE_DEAD))

    local state = ctx:get(player, component.RELIGION_WORSHIP)

    harness.equal(state.piety, 37)
    harness.equal(state.penance[gods.ZIN], 14)
end

-- Run independent actors so one god's penance cannot mask another's
-- response, and the exact source severity stays visible in assertions.
function test.run(ctx)
    trog_cast(ctx)
    trog_memorise(ctx)
    zin_necromancy(ctx)
end

return test
