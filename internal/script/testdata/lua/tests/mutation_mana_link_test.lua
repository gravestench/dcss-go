
local component = require("constants.component")
local jobs = require("ids.jobs")
local mutations = require("ids.mutations")
local species = require("ids.species")
local records = require("policy.mutations.records")
local status_system = require("systems.player_status")
local harness = require("tests.harness")

local test = {}

-- Bind mana link player lookup to this owner while preserving live ECS component reads.
local function player_context(ctx, player)
    local proxy = setmetatable({}, { __index = ctx })

    -- Bind policy ownership to mana link fixture actor so player-only branches execute on that entity.
    function proxy.player()
        return player
    end

    return proxy
end

-- Seed HP and MP so Mana Link can redirect a recovery pip.
local function player_with_regeneration(ctx, mp)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Mana Link test",
    })
    ctx:add(player, component.HEALTH, {
        current = 20,
        max = 30,
    })
    ctx:add(player, component.MAGIC, {
        current = mp,
        max = 10,
    })
    ctx:add(player, component.REGENERATION, {
        hp_progress = 99,
        mp_progress = 0,
    })

    return player
end

-- Diverted HP regeneration restores MP.
function test.run(ctx)
    local linked = player_with_regeneration(ctx, 0)

    records.grant_acquired(ctx, linked, mutations.MUT_MANA_LINK, 1)
    status_system.regeneration(player_context(ctx, linked), linked, 10)

    harness.equal(ctx:get(linked, component.HEALTH).current, 20,
        "Mana Link diverts a low-MP HP regeneration pip")
    harness.equal(ctx:get(linked, component.MAGIC).current, 1,
        "diverted HP regeneration restores MP")

    local full_magic = player_with_regeneration(ctx, 10)

    records.grant_acquired(ctx, full_magic,
        mutations.MUT_MANA_LINK, 1)
    status_system.regeneration(player_context(ctx, full_magic),
        full_magic, 10)

    harness.equal(ctx:get(full_magic, component.HEALTH).current, 21,
        "Mana Link heals HP normally at full MP")

    local ordinary = player_with_regeneration(ctx, 0)

    status_system.regeneration(player_context(ctx, ordinary),
        ordinary, 10)

    harness.equal(ctx:get(ordinary, component.HEALTH).current, 21,
        "ordinary HP regeneration still heals HP")
end

return test
