-- Restore must reject a saved ancestry entity that belongs to another
-- actor; the one-player game cannot silently ignore hidden foreign plans.
local component = require("constants.component")
local demonspawn = require("policy.character.demonspawn")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local levels = require("policy.mutations.levels")
local species = require("ids.species")

local test = {}

-- Create a real schedule, then add one foreign record before validation.
function test.run(ctx)
    local player = ctx:create()
    local game = setmetatable({}, { __index = ctx })
    local draw = 47

    function game:random(_, bound)
        draw = (draw * 48271) % 2147483647

        return draw % bound
    end

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_DEMONSPAWN,
        job_id = jobs.JOB_FIGHTER,
        name = "Save validation test",
    })
    demonspawn.start(game, player)
    demonspawn.validate(ctx, player, species.SP_DEMONSPAWN, 1)

    local foreign = ctx:create()
    local rogue = ctx:create()
    local first_entry = demonspawn.list(ctx, player)[1]
    local first = first_entry.state

    ctx:add(rogue, component.DEMONSPAWN_TRAIT, {
        owner = foreign,
        facet_id = first.facet_id,
        rank_index = first.rank_index,
        mutation_id = first.mutation_id,
        level = first.level,
    })

    local valid = pcall(demonspawn.validate, ctx, player,
        species.SP_DEMONSPAWN, 1)

    harness.falsy(valid, "foreign ancestry passed save validation")

    -- Losing XL must not let a saved flag claim that its still-present
    -- innate rank has yet to be granted.
    ctx:remove(rogue, component.DEMONSPAWN_TRAIT)
    demonspawn.grant_level(game, player, 2)
    harness.equal(levels.base(ctx, player, first.mutation_id), 1)

    local gained = ctx:get(first_entry.entity,
        component.DEMONSPAWN_TRAIT)

    gained.granted = false
    ctx:set(first_entry.entity, component.DEMONSPAWN_TRAIT, gained)
    local accepted, reason = pcall(demonspawn.validate, ctx, player,
        species.SP_DEMONSPAWN, 1)

    harness.falsy(accepted,
        "forgotten grant passed validation after level loss")
    harness.truthy(string.find(tostring(reason), "grant flag", 1, true),
        "save failed for another reason: " .. tostring(reason))
end

return test
