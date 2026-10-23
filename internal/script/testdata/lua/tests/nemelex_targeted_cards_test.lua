-- Exercise all three targeted card tiers through the effective catalog,
-- while observing the existing combat owners at their public interfaces.
local agony = require("policy.magic.effects.zaps.agony")
local area = require("policy.combat.torment_area")
local cards = require("ids.cards")
local component = require("constants.component")
local effects = require("policy.religion.cards.effects.dispatch")
local enchant = require("policy.combat.monster_enchant")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local iood = require("policy.magic.effects.zaps.iood")
local orb_effect = require("policy.religion.cards.effects.orb")
local monsters = require("ids.monsters")
local projectile = require("policy.magic.effects.zaps.projectile")
local selection_kinds = require("constants.selection_kinds")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")

local test = {}

-- Record calls without replacing card policy or ECS schemas. The test
-- restores owners even if an assertion fails inside a sampled scenario.
local function observe(owner, key, replacement, run)
    local original = owner[key]
    owner[key] = replacement
    local ok, result = pcall(run)
    owner[key] = original

    if not ok then
        error(result)
    end

    return result
end

-- A pending high-tier Vitriol wave runs before aim and exactly once. The
-- lower tier keeps the source 5d acid glob profile, then bolts take over.
local function vitriol(ctx, player, owner)
    local waves = 0
    local shots = {}

    function owner:random(stream, bound)
        harness.equal(stream, streams.CARDS)
        harness.equal(bound, 2)

        return 0
    end

    observe(projectile, "fire", function(_, _, intent, _, spec, power)
        shots[#shots + 1] = {
            dx = intent.dx,
            spec = spec,
            power = power,
        }
    end, function()
        observe(enchant, "corrode_equipment", function(_, target)
            harness.truthy(target)
            waves = waves + 1
        end, function()
            local first = effects.apply(owner, player, cards.VITRIOL, {
                tier = 2,
                power = 360,
            })

            harness.equal(first.selection.kind, selection_kinds.CELL)
            harness.equal(waves, 1)

            effects.apply(owner, player, cards.VITRIOL, {
                tier = 2,
                power = 360,
                target_phase = true,
                dx = 1,
                dy = 0,
            })

            harness.equal(waves, 1)
            harness.equal(shots[1].spec.name, "bolt of acid")
            harness.equal(shots[1].power, 60)

            effects.apply(owner, player, cards.VITRIOL, {
                tier = 0,
                power = 180,
                dx = 1,
                dy = 0,
            })

            harness.equal(shots[2].spec.name, "glob of acid")
            harness.equal(shots[2].spec.damage.count, 5)
            harness.equal(shots[2].power, 30)

            effects.apply(owner, player, cards.VITRIOL, {
                tier = 1,
                power = 240,
                dx = 1,
                dy = 0,
            })

            harness.equal(shots[3].spec.name, "bolt of acid")
            harness.equal(waves, 1)
        end)
    end)
end

-- High Pain torments before aim, including a discarded draw. Agony and
-- draining use distinct source zaps and one sixth of card power.
local function pain(ctx, player, owner)
    local torment_count = 0
    local agony_count = 0
    local shot = nil

    observe(area, "apply", function()
        torment_count = torment_count + 1
    end, function()
        observe(agony, "resolve", function(_, _, intent, spell, power)
            agony_count = agony_count + 1
            harness.equal(intent.dx, 1)
            harness.equal(spell.id, spells.SPELL_AGONY)
            harness.equal(power, 30)
        end, function()
            observe(projectile, "fire", function(_, _, intent, _, spec, power)
                shot = { intent = intent, spec = spec, power = power }
            end, function()
                local first = effects.apply(owner, player, cards.PAIN, {
                    tier = 2,
                    power = 360,
                })

                harness.equal(first.selection.kind, selection_kinds.CELL)
                harness.equal(torment_count, 1)

                effects.apply(owner, player, cards.PAIN, {
                    tier = 2,
                    power = 360,
                    target_phase = true,
                    dx = 1,
                    dy = 0,
                })

                harness.equal(torment_count, 1)
                harness.equal(shot.spec.name,
                    "bolt of negative energy")
                harness.equal(shot.spec.element, "MR_RES_NEG")
                harness.equal(shot.power, 60)

                effects.apply(owner, player, cards.PAIN, {
                    tier = 0,
                    power = 180,
                    dx = 1,
                    dy = 0,
                })

                harness.equal(agony_count, 1)

                effects.apply(owner, player, cards.PAIN, {
                    tier = 1,
                    power = 240,
                    dx = 1,
                    dy = 0,
                })

                harness.equal(shot.power, 40)
                harness.equal(torment_count, 1)
            end)
        end)
    end)
end

-- Only the middle Orb tier launches one aimed orb; the other tiers use
-- the burst owner after the same postcommit target prompt.
local function orb(player, owner)
    local single = 0
    local bursts = 0

    observe(iood, "launch", function(_, _, dx, dy, power, _, stream)
        single = single + 1
        harness.equal(dx, 1)
        harness.equal(dy, 0)
        harness.equal(power, 60)
        harness.equal(stream, streams.CARDS)
    end, function()
        observe(orb_effect, "burst", function(_, _, dx, dy, power, stream)
            bursts = bursts + 1
            harness.equal(dx, 1)
            harness.equal(dy, 0)
            harness.equal(power, 60)
            harness.equal(stream, streams.CARDS)
        end, function()
            for tier = 0, 2 do
                local prompt = effects.apply(owner, player, cards.ORB, {
                    tier = tier,
                    power = 360,
                })

                harness.equal(prompt.selection.kind, selection_kinds.CELL)

                effects.apply(owner, player, cards.ORB, {
                    tier = tier,
                    power = 360,
                    target_phase = true,
                    dx = 1,
                    dy = 0,
                })
            end
        end)
    end)

    harness.equal(single, 1)
    harness.equal(bursts, 2)
end

-- A real positioned player and hostile rat make sight and entropy queries
-- use the same components as a production card action.
function test.run(ctx)
    local player = ctx:create()
    local owner = fixture.context(ctx, player)

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })

    fixture.actor(ctx, monsters.MONS_RAT, 8, 7)

    vitriol(ctx, player, owner)
    pain(ctx, player, owner)
    orb(player, owner)
end

return test
