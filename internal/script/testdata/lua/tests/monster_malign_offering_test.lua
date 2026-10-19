-- Malign Offering uses the beam's actual victim HP loss, then heals each
-- aligned recipient near that victim rather than near the caster.
local component = require("constants.component")
local effect = require("policy.combat.monster_spells.malign_offering")
local harness = require("tests.harness")
local life = require("policy.combat.life_transfer")
local senses = require("policy.character.senses")
local targets = require("policy.ai.targets")

local test = {}
local caster = 101
local victim = 201
local ally = 102
local nonliving_ally = 103
local distant_ally = 104

-- Keep the hook's lower-level health and geometry services explicit.
local function context()
    local state = {
        victim_hp = 20,
        heals = {},
    }
    local positions = {
        [caster] = { level_id = 1, x = 1, y = 1 },
        [victim] = { level_id = 1, x = 2, y = 2 },
        [ally] = { level_id = 1, x = 3, y = 2 },
        [nonliving_ally] = { level_id = 1, x = 3, y = 3 },
        [distant_ally] = { level_id = 1, x = 10, y = 10 },
    }
    local ctx = {}

    -- No player handle is needed for this unseen monster-to-monster hit.
    function ctx:has()
        return false
    end

    -- A later read of the victim's health exposes actual rather than raw
    -- beam damage to the offering hook.
    function ctx:get(entity, id)
        if id == component.POSITION then
            return positions[entity]
        end

        if id == component.HEALTH then
            return {
                current = entity == victim and state.victim_hp or 10,
                max = 20,
            }
        end
    end

    -- Include every kind of recipient so the policy must filter them.
    function ctx:query()
        return {
            caster,
            victim,
            ally,
            nonliving_ally,
            distant_ally,
        }
    end

    -- Clear-wall LOS is available for each in-radius actor.
    function ctx:visible_no_trans()
        return true
    end

    return ctx, state
end

-- Let the hook choose recipients and healing while replacing independent
-- allegiance, holiness, and perception owners.
local function install_stubs(state)
    local original = {
        aligned = targets.aligned,
        recipient = life.offering_recipient,
        heal = life.heal,
        sees = senses.player_sees_actor,
    }

    targets.aligned = function(_, _, actor)
        return actor ~= victim
    end

    life.offering_recipient = function(_, actor)
        return actor ~= nonliving_ally
    end

    life.heal = function(_, actor, amount)
        state.heals[actor] = amount

        return amount
    end

    senses.player_sees_actor = function()
        return false
    end

    return original
end

-- Restore shared production modules before the next Lua test.
local function restore_stubs(original)
    targets.aligned = original.aligned
    life.offering_recipient = original.recipient
    life.heal = original.heal
    senses.player_sees_actor = original.sees
end

-- Seven real HP lost gives floor(2 * 7 / 3) healing to each eligible
-- recipient, while a zero-damage hit creates no healing field.
function test.run()
    local ctx, state = context()
    local original = install_stubs(state)
    local outcome = {}

    effect.before_damage(ctx, caster, victim, nil, outcome)
    state.victim_hp = 13
    effect.after_hit(ctx, caster, victim, nil, outcome)

    harness.equal(state.heals[caster], 4,
        "caster can receive its own offering")
    harness.equal(state.heals[ally], 4,
        "nearby aligned recipient gets two thirds of dealt HP")
    harness.falsy(state.heals[victim],
        "sacrifice cannot receive its own offering")
    harness.falsy(state.heals[nonliving_ally],
        "nonliving recipient cannot be healed")
    harness.falsy(state.heals[distant_ally],
        "recipient outside victim-centered LOS is excluded")

    state.heals = {}
    effect.before_damage(ctx, caster, victim, nil, outcome)
    effect.after_hit(ctx, caster, victim, nil, outcome)
    harness.falsy(state.heals[caster],
        "a resisted hit cannot create healing")

    restore_stubs(original)
end

return test
