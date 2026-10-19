-- Monster life theft keeps an adjacent saved foe, uses live resistance,
-- and heals only from HP actually removed. The fixture imports production
-- IDs and policies instead of rebuilding their component definitions.
local channels = require("constants.message_channels")
local component = require("constants.component")
local effect = require("policy.combat.monster_spells.vampiric_draining")
local harness = require("tests.harness")
local life = require("policy.combat.life_transfer")
local monster_stats = require("policy.combat.monster_stats")
local monsters = require("ids.monsters")
local species_ids = require("ids.species")
local senses = require("policy.character.senses")
local streams = require("constants.rng_streams")
local target_kind = require("constants.target_kind")

local test = {}
local caster = 101
local foe = 202

-- Keep only mutable position, health, and saved RNG behavior in this
-- fixture. The spell itself still supplies target and damage policy.
local function context()
    local state = {
        foe_x = 2,
        caster_hp = 20,
        foe_hp = 100,
        draws = 0,
        messages = {},
    }
    local ctx = {}

    -- Distinguish a monster source from the player victim.
    function ctx:has(entity, id)
        return entity == foe and id == component.PLAYER
    end

    -- Return source and selected foe at their current positions.
    function ctx:get(entity, id)
        if id == component.POSITION then
            return {
                level_id = 1,
                x = entity == caster and 1 or state.foe_x,
                y = 1,
            }
        end

        if id == component.ACTOR and entity == caster then
            return { kind_id = monsters.MONS_RAT }
        end

        if id == component.HEALTH then
            return {
                current = entity == caster and state.caster_hp or
                    state.foe_hp,
                max = 100,
            }
        end

        return nil
    end

    -- The two source dice consume this named monster spell stream.
    function ctx:random(stream, bound)
        harness.equal(stream, streams.MONSTER_SPELL,
            "life theft uses the monster spell stream")
        harness.truthy(bound > 0, "damage dice need positive sides")
        state.draws = state.draws + 1

        return 0
    end

    -- Keep player-facing cast messages distinct from damage math.
    function ctx:emit(channel, message)
        state.messages[#state.messages + 1] = {
            channel = channel,
            text = message,
        }
    end

    return ctx, state
end

-- Substitute only neighboring policies whose formulas have their own
-- tests, so this test isolates the cast's target and HP-transfer contract.
local function install_stubs(state)
    local original = {
        susceptible = life.susceptible,
        resistance = life.resistance,
        hurt = life.hurt,
        heal = life.heal,
        hd = monster_stats.spell_hit_dice,
        sees = senses.player_sees_actor,
    }

    -- A living adjacent player with no rN is a legal selected foe.
    life.susceptible = function()
        return true
    end

    -- Toggle this result below to prove immunity prevents planning.
    life.resistance = function()
        return state.resistance or 0
    end

    -- Count actual HP loss independently of raw damage.
    life.hurt = function(_, _, _, raw)
        harness.equal(raw, 2, "two minimum source dice were rolled")
        state.foe_hp = state.foe_hp - 2

        return 2
    end

    -- Monster caster gains floor(2 * dealt / 3) HP.
    life.heal = function(_, _, amount)
        state.caster_hp = state.caster_hp + amount

        return amount
    end

    -- A fixed HD makes the die side count deterministic in this fixture.
    monster_stats.spell_hit_dice = function()
        return 5
    end

    -- The player victim is always visible in this focused cast test.
    senses.player_sees_actor = function()
        return true
    end

    return original
end

-- Restore cached production modules before another Lua test runs.
local function restore_stubs(original)
    life.susceptible = original.susceptible
    life.resistance = original.resistance
    life.hurt = original.hurt
    life.heal = original.heal
    monster_stats.spell_hit_dice = original.hd
    senses.player_sees_actor = original.sees
end

-- Verify a successful transfer, stale target rejection, and resistance
-- rejection through the public monster effect methods.
function test.run()
    local ctx, state = context()
    local original = install_stubs(state)
    local plan = effect.plan(ctx, caster, foe)

    harness.equal(plan.kind, target_kind.ENTITY,
        "the selected foe is an entity target")
    harness.equal(plan.entity, foe,
        "the plan retains the chosen foe")
    harness.equal(effect.resolve(ctx, caster, foe, nil, plan), 2,
        "the resolver returns dealt HP")
    harness.equal(state.caster_hp, 21,
        "monster healing uses two thirds of dealt HP")
    harness.equal(state.draws, 2,
        "damage rolls exactly two dice")
    harness.equal(state.messages[1].channel, channels.SPELL,
        "cast message uses the spell channel")

    state.foe_x = 3
    harness.falsy(effect.plan(ctx, caster, foe),
        "a nonadjacent foe cannot be selected")
    harness.falsy(pcall(effect.resolve, ctx, caster, foe, nil, plan),
        "the target cannot move away after selection")

    state.foe_x = 2
    state.resistance = 3
    harness.falsy(effect.plan(ctx, caster, foe),
        "full negative-energy resistance blocks planning")

    restore_stubs(original)
    harness.equal(life.resisted(20, 3), 0, "rN3 grants immunity")
    harness.equal(life.resisted(20, 2), 5, "rN2 quarters damage")
    harness.equal(life.resisted(20, 1), 10, "rN1 halves damage")
    harness.equal(life.resisted(20, -1), 30,
        "negative rN increases damage")
    harness.equal(life.resisted(20, 2, true), 4,
        "monster rN2 uses the source monster divisor")

    -- Malign Offering excludes only nonliving bodies. Undead recipients
    -- may receive its healing even though they cannot supply drained life.
    local species_id = species_ids.SP_HUMAN
    local recipient_ctx = {}

    -- This actor starts as a player so live species and form rules apply.
    function recipient_ctx:has(_, id)
        return id == component.PLAYER
    end

    -- Each species is a real registered content definition, not a copied
    -- fixture schema or hand-written holiness table.
    function recipient_ctx:get(_, id)
        if id == component.PLAYER then
            return { species_id = species_id }
        end
    end

    harness.truthy(life.living(recipient_ctx, foe),
        "Human can supply life")
    harness.truthy(life.offering_recipient(recipient_ctx, foe),
        "Human can receive an offering")

    species_id = species_ids.SP_GARGOYLE
    harness.falsy(life.living(recipient_ctx, foe),
        "Gargoyle is nonliving")
    harness.falsy(life.offering_recipient(recipient_ctx, foe),
        "Gargoyle cannot receive an offering")

    species_id = species_ids.SP_MUMMY
    harness.falsy(life.living(recipient_ctx, foe),
        "Mummy cannot supply life")
    harness.truthy(life.offering_recipient(recipient_ctx, foe),
        "Mummy can receive an offering")

    -- Source monster holiness makes an undead Wight another valid
    -- offering recipient, without making it a vampiric victim.
    function recipient_ctx:has()
        return false
    end

    function recipient_ctx:get(_, id)
        if id == component.ACTOR then
            return { kind_id = monsters.MONS_WIGHT }
        end
    end

    harness.falsy(life.living(recipient_ctx, foe),
        "Wight cannot supply life")
    harness.truthy(life.offering_recipient(recipient_ctx, foe),
        "Wight can receive an offering")
end

return test
