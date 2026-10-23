-- Theory of operation: Trog and Okawaru share the source equipment gate.
-- Trog only asks for weapons; Okawaru can also ask for armour or throwing
-- stacks. This helper owns those common probability and timeout formulas,
-- while each god module names its own class choices and message.
local classes = require("ids.object_classes")
local draws = require("policy.religion.gifts.draws")
local gifts = require("policy.religion.gifts")
local items = require("policy.religion.gifts.items")
local mutation_levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local piety = require("policy.religion.piety")
local selection = require("policy.scrolls.acquirement.selection")
local skills = require("ids.skills")
local streams = require("constants.rng_streams")

local martial = {}

local EQUIPMENT_ROLL_MIN = 120
local EQUIPMENT_CHANCE = 4
local MISSILE_ROLL_MIN = 70
local MISSILE_CHANCE = 8
local THROWING_CHANCE_DENOMINATOR = 12
local MISSILE_TIMEOUT_BASE = 4
local ARMOUR_TIMEOUT_BASE = 30
local EQUIPMENT_TIMEOUT_BASE = 30

-- Reject items that would disappear, or an actor who can neither grasp a
-- weapon nor wear armour. The latter source guard applies to both patrons.
function martial.eligible(ctx, player)
    return items.safe_floor(ctx, player) and
        not (mutation_levels.effective(ctx, player,
            mutations.MUT_NO_GRASPING) > 0 and
            mutation_levels.effective(ctx, player,
                mutations.MUT_NO_ARMOUR) > 0)
end

-- Equipment gifts need high piety, an above-120 roll, and a one-in-four
-- chance. Every check receives fresh draws after the common gift timeout.
function martial.equipment_due(ctx, worship)
    return worship.piety >= piety.breakpoint(5) and
        ctx:random(streams.RELIGION, worship.piety) >
            EQUIPMENT_ROLL_MIN and
        ctx:random(streams.RELIGION, EQUIPMENT_CHANCE) == 0
end

-- Okawaru's alternate throwing route uses the source raw Throwing level
-- as a final 1+skill chance out of twelve.
function martial.missiles_due(ctx, worship)
    if worship.piety < piety.breakpoint(3) or
        ctx:random(streams.RELIGION, worship.piety) <=
            MISSILE_ROLL_MIN or
        ctx:random(streams.RELIGION, MISSILE_CHANCE) ~= 0 then
        return false
    end

    local skill = selection.skill(ctx, skills.SK_THROWING)

    return ctx:random(streams.RELIGION,
        THROWING_CHANCE_DENOMINATOR) < 1 + skill
end

-- A missile gift has a short 2d4 timeout. Oka armour adds its own
-- 30+average(15) before the shared 30+average(19) equipment timeout.
function martial.timeout(ctx, class_id)
    if class_id == classes.OBJ_MISSILES then
        return MISSILE_TIMEOUT_BASE + draws.dice(ctx, 2, 4)
    end

    local total = 0

    if class_id == classes.OBJ_ARMOUR then
        total = ARMOUR_TIMEOUT_BASE + draws.average(ctx, 15)
    end

    return total + EQUIPMENT_TIMEOUT_BASE + draws.average(ctx, 19)
end

-- Only a materialized item counts as a gift; acquisition failure leaves
-- piety and counters available for a later successful check.
function martial.grant(ctx, player, class_id, god_id)
    local entity = items.grant(ctx, player, class_id, god_id)

    if not entity then
        return false
    end

    gifts.record(ctx, player, martial.timeout(ctx, class_id))

    return true
end

return martial
