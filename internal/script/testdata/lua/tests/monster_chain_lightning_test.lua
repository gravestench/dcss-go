-- Chain Lightning uses the production jump geometry and source zap. A
-- two-actor fixture makes the return arc and its one-sixth dice visible
-- without replacing the target search or ray trace.
local accuracy = require("constants.beam_accuracy")
local area = require("policy.combat.monster_area.chain_lightning")
local beam_damage = require("policy.combat.monster_beams.damage")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local contact = require("policy.combat.monster_beams.contact")
local effect = require("policy.combat.monster_spells.chain_lightning")
local flavours = require("constants.beam_flavours")
local harness = require("tests.harness")
local magic_damage = require("policy.magic.damage")
local monsters = require("ids.monsters")
local power = require("policy.combat.monster_beams.power")
local senses = require("policy.character.senses")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")
local zaps = require("constants.zap_ids")

local test = {}
local caster = 11
local foe = 22

-- Clear floor and one foe two cells away allow the ray to return to the
-- caster after its first hit, using the same saved monster-spell stream.
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
            y = 0,
        },
    }
    local ctx = {}

    -- Candidate discovery reads the current body and position components.
    function ctx:get(entity, id)
        if id == component.POSITION then
            return positions[entity]
        end

        if id == component.HEALTH then
            return { current = 30 }
        end

        if id == component.ACTOR then
            return { kind_id = monsters.MONS_RAT }
        end

        return nil
    end

    -- Both bodies are monsters for this source dice test.
    function ctx:has()
        return false
    end

    -- ECS query order is stable and does not depend on Lua file order.
    function ctx:query()
        return {
            caster,
            foe,
        }
    end

    -- This small grid has no wall between either arc endpoint.
    function ctx:visible()
        return true
    end

    -- Neither target is hidden by a clear wall from the caster.
    function ctx:visible_no_trans()
        return true
    end

    -- A ray may traverse the middle floor cell before its target.
    function ctx:walkable()
        return true
    end

    -- The ray's actual contacts come from the production trajectory.
    function ctx:actor_at(_, x, y)
        if x == 0 and y == 0 then
            return caster
        end

        if x == 2 and y == 0 then
            return foe
        end

        return nil
    end

    -- There are no equal-distance targets; minimum draws suffice.
    function ctx:random()
        return 0
    end

    return ctx
end

-- Check profile semantics, target planning, and the two actual arc rays.
function test.run()
    local old = {
        hit = contact.resolve,
        enemy = targets.enemy,
        allied = targets.allied,
        sees = senses.player_sees_actor,
        caster_power = power.caster_power,
        elemental = magic_damage.monster_elemental,
    }
    local contacts = {}

    contact.resolve = function(_, _, victim, profile, _, to_hit)
        contacts[#contacts + 1] = {
            victim = victim,
            sides = profile.monster_damage.args[2],
            flavour = profile.flavour,
            stream = profile.rng_stream,
            to_hit = to_hit,
        }
    end

    targets.enemy = function(_, _, victim)
        return victim == foe
    end

    targets.allied = function()
        return false
    end

    senses.player_sees_actor = function()
        return false
    end

    power.caster_power = function()
        return 100
    end

    local profile = catalog.get(categories.MONSTER_BEAMS,
        spells.SPELL_CHAIN_LIGHTNING)
    local ctx = context()

    harness.equal(profile.zap_id, zaps.ZAP_CHAIN_LIGHTNING,
        "the monster cast uses the source chain zap")
    harness.equal(profile.flavour, flavours.BEAM_THUNDER,
        "thunder is half electrical and half sonic")

    local plan = effect.plan(ctx, caster, foe)

    harness.truthy(plan,
        "a nearby hostile makes the source AI offer the spell")
    area.resolve(ctx, caster, 100, profile,
        streams.MONSTER_SPELL)
    harness.equal(#contacts, 2,
        "the first ray hits the foe and the next returns to caster")
    harness.equal(contacts[1].victim, foe,
        "the first ray reaches the nearest body")
    harness.equal(contacts[1].sides, 29,
        "range-two attenuation applies to the 35-side monster zap")
    harness.equal(contacts[2].victim, caster,
        "the next ray may return to the original caster")
    harness.equal(contacts[2].sides, 2,
        "the return arc reduces post-wave sides to one sixth")
    harness.equal(contacts[2].to_hit, accuracy.AUTOMATIC_HIT,
        "the source rays are automatic hits")
    harness.equal(contacts[2].stream, streams.MONSTER_SPELL,
        "monster rays keep their saved spell stream")

    magic_damage.monster_elemental = function()
        return 0
    end

    local after_ac = beam_damage.armour(ctx, 10, 10, profile)
    local resisted = beam_damage.resisted(ctx, foe,
        after_ac, profile)

    harness.equal(after_ac, 10,
        "minimum AC roll removes no thunder damage")
    harness.equal(resisted, 5,
        "complete rElec still leaves thunder's sonic half")

    contact.resolve = old.hit
    targets.enemy = old.enemy
    targets.allied = old.allied
    senses.player_sees_actor = old.sees
    power.caster_power = old.caster_power
    magic_damage.monster_elemental = old.elemental
end

return test
