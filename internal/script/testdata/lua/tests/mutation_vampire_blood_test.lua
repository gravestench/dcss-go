
local catalog = require("policy.catalog")
local component = require("constants.component")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local vampire = require("policy.character.vampire")

local test = {}

-- Bloodless Vampires cannot feed on nonliving monsters.
function test.run(ctx)
    local player = ctx:create()
    local target = ctx:create()

    ctx:add(player, component.HEALTH, {
        current = 5,
        max = 20,
    })
    ctx:add(player, component.PROGRESSION, {
        level = 3,
        total_xp = 0,
    })
    records.grant_acquired(ctx, player, mutations.MUT_VAMPIRISM, 1)
    vampire.start(ctx, player)

    local adder = catalog.get("monsters", monsters.MONS_ADDER)

    harness.falsy(vampire.draw_blood(ctx, player, target, adder, 3),
        "living Vampires do not draw blood")

    local state = ctx:get(player, component.VAMPIRE)

    state.alive = false
    ctx:set(player, component.VAMPIRE, state)

    local elemental = catalog.get("monsters",
        monsters.MONS_AIR_ELEMENTAL)

    harness.falsy(vampire.draw_blood(ctx, player, target, elemental, 3),
        "bloodless Vampires cannot feed on nonliving monsters")
    harness.truthy(vampire.draw_blood(ctx, player, target, adder, 3),
        "bloodless Vampires draw blood from natural creatures")

    local health = ctx:get(player, component.HEALTH)

    harness.truthy(health.current >= 7 and health.current <= 8,
        "blood healing uses two damage rolls capped at XL")
end

return test
