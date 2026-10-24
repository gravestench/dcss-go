-- Jiyva's two powers must be discoverable from production ability files.
-- Later assertions exercise their terrain and melee owners through the
-- same registered schemas used by normal play.
local abilities = require("ids.abilities")
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local piety = require("policy.religion.piety")
local registry = require("policy.abilities.registry")
local jiyva = require("policy.religion.gods.jiyva")
local species = require("ids.species")

local test = {}

-- Registration is the public ability contract for menus and commands.
function test.run(ctx)
    local ooze = registry.get(abilities.JIYVA_OOZEMANCY)
    local slimify = registry.get(abilities.JIYVA_SLIMIFY)

    harness.truthy(ooze)
    harness.truthy(slimify)

    local player = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Jiyva tester",
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.JIYVA,
        piety = piety.breakpoint(2),
        penance = {},
    })

    harness.truthy(ooze.available(ctx, player))
    harness.falsy(slimify.available(ctx, player))

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    worship.piety = piety.breakpoint(4)
    ctx:set(player, component.RELIGION_WORSHIP, worship)
    harness.truthy(slimify.available(ctx, player))

    ctx:add(player, component.JIYVA_POWERS, {
        slimify_aut = 100,
    })
    jiyva.on_penance(ctx, player)
    harness.falsy(ctx:has(player, component.JIYVA_POWERS))

    ctx:add(player, component.JIYVA_POWERS, {
        slimify_aut = 100,
    })
    jiyva.leave(ctx, player)
    harness.falsy(ctx:has(player, component.JIYVA_POWERS))
end

return test
