local component = require("constants.component")
local terrain = require("constants.terrain")
local jobs = require("ids.jobs")
local mutations = require("ids.mutations")
local species = require("ids.species")
local catalog = require("policy.catalog")
local extra_lives = require("policy.character.extra_lives")
local formulas = require("policy.character.formulas")
local records = require("policy.mutations.records")
local harness = require("tests.harness")

local test = {}

local function floor_context(ctx, player)
    local floor = setmetatable({}, { __index = ctx })
    local moved = false

    function floor.player()
        return player
    end

    function floor.level_size()
        return 1, 1
    end

    function floor.random()
        return 0
    end

    function floor.actor_at()
        return player
    end

    function floor.cell()
        return terrain.DNGN_FLOOR
    end

    function floor.move_actor()
        moved = true
    end

    return floor, function()
        return moved
    end
end

local function check_high_experience(ctx)
    local player = ctx:create()
    local felid = catalog.get("species", species.SP_FELID)
    local xp = formulas.experience_needed(28, felid.xp)
    local lost = formulas.experience_needed(27, felid.xp) -
        formulas.experience_needed(26, felid.xp)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_FELID,
        job_id = jobs.JOB_FIGHTER,
        name = "Veteran revival test",
    })
    ctx:add(player, component.PROGRESSION, {
        level = 27,
        total_xp = xp,
    })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 0,
        y = 0,
    })
    ctx:add(player, component.HEALTH, {
        current = 0,
        max = 100,
    })
    ctx:add(player, component.MAGIC, {
        current = 0,
        max = 20,
    })
    ctx:add(player, component.SKILLS, {
        entries = {},
    })
    records.grant_innate(ctx, player, mutations.MUT_MULTILIVED, 1)
    ctx:add(player, component.EXTRA_LIVES, {
        lives = 0,
        deaths = 1,
        max_level = 28,
        last_life_gained = 28,
        pending_revival = true,
    })

    local floor = floor_context(ctx, player)

    harness.truthy(extra_lives.revive(floor, player),
        "veteran Felid revival runs")

    local progress = ctx:get(player, component.PROGRESSION)

    harness.equal(progress.total_xp, xp - lost,
        "XL27 revival subtracts one source XP-level interval")
    harness.equal(progress.level, 27,
        "surplus XP can keep a revived Felid at XL27")
end

function test.run(ctx)
    local player = ctx:create()
    local felid = catalog.get("species", species.SP_FELID)
    local xp = formulas.experience_needed(4, felid.xp)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_FELID,
        job_id = jobs.JOB_FIGHTER,
        name = "Revival test",
    })
    ctx:add(player, component.PROGRESSION, {
        level = 4,
        total_xp = xp,
    })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 0,
        y = 0,
    })
    ctx:add(player, component.HEALTH, {
        current = 0,
        max = 20,
    })
    ctx:add(player, component.MAGIC, {
        current = 0,
        max = 5,
    })
    ctx:add(player, component.SKILLS, {
        entries = {},
    })
    records.grant_innate(ctx, player, mutations.MUT_MULTILIVED, 1)
    ctx:add(player, component.EXTRA_LIVES, {
        lives = 0,
        deaths = 1,
        max_level = 4,
        last_life_gained = 4,
        pending_revival = true,
    })

    local floor, moved = floor_context(ctx, player)

    harness.truthy(extra_lives.revive(floor, player),
        "pending Felid revival runs at the next input boundary")

    local progress = ctx:get(player, component.PROGRESSION)
    local health = ctx:get(player, component.HEALTH)

    harness.equal(progress.level, 3,
        "revival loses one current experience level")
    harness.equal(progress.total_xp, formulas.experience_needed(3, felid.xp),
        "revival preserves source XP progress at the new level")
    harness.equal(health.current, health.max,
        "revival restores the recalculated HP maximum")
    harness.truthy(moved(),
        "revival asks the grid to move the player to safety")
    harness.falsy(extra_lives.state(ctx, player).pending_revival,
        "revival clears the pending save state")

    check_high_experience(ctx)
end

return test
