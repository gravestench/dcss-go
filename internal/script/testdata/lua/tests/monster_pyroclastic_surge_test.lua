-- Pyroclastic Surge uses the production spell and zap profile. This grid
-- fixture checks the source lava predicate and records final hits at the
-- shared damage owner without recreating its armour or resistance rules.
local calculators = require("policy.combat.monster_beams.calculators")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local effect = require("policy.combat.monster_spells.pyroclastic_surge")
local harness = require("tests.harness")
local accuracy = require("constants.beam_accuracy")
local contact = require("policy.combat.monster_beams.contact")
local power = require("policy.combat.monster_beams.power")
local spells = require("ids.spells")
local targets = require("policy.ai.targets")
local terrain = require("constants.terrain")
local zaps = require("constants.zap_ids")

local test = {}
local caster = 11
local foe = 22
local other_foe = 33
local ally = 44

-- Both foes and an ally stand beside one lava cell. Only enemies can be
-- struck, and hiding that lava from the caster prevents a cast entirely.
local function context()
    local positions = {
        [caster] = {
            level_id = 1,
            x = 0,
            y = 0,
        },

        [foe] = {
            level_id = 1,
            x = 2,
            y = 2,
        },

        [other_foe] = {
            level_id = 1,
            x = 3,
            y = 2,
        },

        [ally] = {
            level_id = 1,
            x = 1,
            y = 2,
        },
    }
    local ctx = {
        lava_visible = true,
    }

    -- Every actor has live position and health; no damage owner is faked.
    function ctx:get(entity, id)
        if id == component.POSITION then
            return positions[entity]
        end

        if id == component.HEALTH then
            return { current = 30 }
        end

        return nil
    end

    -- Production area discovery gets all living bodies, including allies.
    function ctx:query()
        return {
            caster,
            foe,
            other_foe,
            ally,
        }
    end

    -- Source requires sight to both victim and the nearby lava cell.
    function ctx:visible_no_trans(_, _, _, _, x, y)
        if x == 2 and y == 1 then
            return self.lava_visible
        end

        return true
    end

    -- Lava Sea is a source lava feature too; both must trigger the spell.
    function ctx:cell(_, x, y)
        if x == 2 and y == 1 then
            return terrain.DNGN_LAVA_SEA
        end

        return terrain.DNGN_FLOOR
    end

    -- Minimum dice rolls make each qualifying strike easy to count.
    function ctx:random()
        return 0
    end

    return ctx, positions
end

-- Confirm refusal, multiple independent hits, and source zap identity.
function test.run()
    local old = {
        enemy = targets.enemy,
        hit = contact.resolve,
        caster_power = power.caster_power,
    }
    local hits = {}

    targets.enemy = function(_, _, victim)
        return victim == foe or victim == other_foe
    end

    contact.resolve = function(_, _, victim, _, _, to_hit)
        hits[#hits + 1] = {
            victim = victim,
            to_hit = to_hit,
        }
    end

    power.caster_power = function()
        return 100
    end

    local profile = catalog.get(categories.MONSTER_BEAMS,
        spells.SPELL_PYROCLASTIC_SURGE)
    local dice = calculators.damage_dice({
        random = function()
            return 0
        end,
    }, profile, 100)

    harness.equal(profile.zap_id, zaps.ZAP_BOLT_OF_FIRE,
        "surge uses the source Bolt of Fire zap")
    harness.equal(dice.count, 3,
        "each struck actor gets three source fire dice")

    local ctx, positions = context()

    ctx.lava_visible = false
    harness.falsy(effect.plan(ctx, caster, foe),
        "invisible nearby lava does not offer the spell")

    ctx.lava_visible = true

    local plan = effect.plan(ctx, caster, foe)

    harness.truthy(plan,
        "visible lava beside the selected foe offers the spell")
    effect.resolve(ctx, caster, foe, nil, plan)
    harness.equal(#hits, 2,
        "the two enemies are hit but the equally near ally is spared")
    harness.equal(hits[1].to_hit, accuracy.AUTOMATIC_HIT,
        "the first actor receives an automatic contact")
    harness.equal(hits[2].to_hit, accuracy.AUTOMATIC_HIT,
        "the second actor receives an independent automatic contact")

    positions[other_foe].x = 4
    hits = {}

    effect.resolve(ctx, caster, foe, nil, plan)
    harness.equal(#hits, 1,
        "resolution rechecks live lava adjacency instead of stale victims")

    targets.enemy = old.enemy
    contact.resolve = old.hit
    power.caster_power = old.caster_power
end

return test
