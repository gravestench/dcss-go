-- Theory of operation: monster death inspects source-shaped catalog facts
-- and the dying actor's live ECS state before removal. It emits conduct
-- categories in mon-death.cc order; the current god decides which matter.
-- This module never decides piety or stores a second monster profile.
local attitudes = require("constants.attitude")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local death = require("policy.death")
local flags = require("constants.monster_flags")
local gods = require("constants.gods")
local holiness = require("constants.monster_holiness")
local kinds = require("constants.religion_conduct")
local books = require("ids.monster_spellbooks")
local spell_flags = require("constants.monster_spell_flags")
local slime = require("policy.religion.jiyva.identity")
local traits = require("policy.religion.conduct.monster_traits")
local targets = require("policy.ai.targets")
local senses = require("policy.character.senses")
local movement = require("policy.character.movement")

local facts = {}

-- Source catalog arrays are lists, not keyed sets. A mod can replace one
-- profile without adding a new branch to the death system.
local function contains(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Priest and wizard status comes from spell-slot flags, not the monster's
-- English name. One spellbook can mark a class as both when the source does.
local function has_spell_flag(definition, wanted)
    if not definition.spellbook_id or
        definition.spellbook_id == books.MST_NO_SPELLS then
        return false
    end

    local book = catalog.get(categories.MONSTER_SPELLBOOKS,
        definition.spellbook_id)

    for _, slot in ipairs(book.slots or {}) do
        if contains(slot.flags, wanted) then
            return true
        end
    end

    return false
end

-- TSO's kill recovery and first-sight conduct must agree about whether
-- a living priest or spellcaster is evil. Keep the spell-slot lookup here.
function facts.evil(ctx, monster, definition)
    return traits.evil(ctx, monster, definition,
        has_spell_flag(definition, spell_flags.PRIEST))
end

-- A source event captures live victim facts while its entity still exists.
-- Piety-gain eligibility is a separate flag because a prohibited kill can
-- still make a god angry even when it awards no XP.
local function event(ctx, id, monster, definition, credit, side)
    return {
        id = id,
        level = definition.hd,
        known = true,
        victim = monster,
        credit = credit,
        friend_hated = side ~= attitudes.HOSTILE,
        was_neutral = side == attitudes.NEUTRAL or
            side == attitudes.GOOD_NEUTRAL or
            ctx:has(monster, component.RELIGION_WAS_NEUTRAL),
        no_reward = contains(definition.flags, flags.NO_EXP_GAIN),
        genus_id = definition.genus_id,
        plant = contains(definition.holiness, holiness.PLANT),
        leaves_corpse = definition.leaves_corpse == true,
        slime = slime.slime(definition),
        shapeshifter = traits.shapeshifter(definition),
    }
end

-- Attack conduct is decided before hit resolution. Source conduct counts
-- an attempted strike against a friend or neutral even when it misses.
-- Holy attacks also carry the victim's level for the good gods' peeves.
function facts.attack(ctx, monster, definition)
    local side = targets.attitude(ctx, monster)
    local events = {}

    local function add(id, level)
        local observed = event(ctx, id, monster, definition, false, side)

        observed.level = level
        observed.known = senses.player_sees_actor(ctx, monster)
        events[#events + 1] = observed
    end

    if side == attitudes.FRIENDLY or side == attitudes.FELLOW_SLIME then
        add(kinds.ATTACK_FRIEND, 5)
    elseif side == attitudes.NEUTRAL or
        side == attitudes.GOOD_NEUTRAL then
        add(kinds.ATTACK_NEUTRAL, 5)
    end

    if contains(definition.holiness, holiness.HOLY) then
        add(kinds.ATTACK_HOLY, definition.hd)
    end

    return events
end

-- Source seen_monster offers this conduct only for a first encounter with
-- an XP-bearing creature. The sight owner preserves first-seen state; this
-- classifier supplies evil identity for The Shining One's own response.
function facts.sight(ctx, monster, definition)
    local side = targets.attitude(ctx, monster)

    if side ~= attitudes.HOSTILE or
        ctx:has(monster, component.SUMMON) or
        contains(definition.flags, flags.NO_EXP_GAIN) then
        return nil
    end

    local observed = event(ctx, kinds.SEE_MONSTER, monster, definition,
        true, side)

    observed.evil = facts.evil(ctx, monster, definition)

    return observed
end

-- Source monster::hurt reports direct player damage only for hostile,
-- XP-bearing creatures. Delayed poison and clouds are filtered by the
-- damage owner before this classifier receives them.
function facts.hurt(ctx, monster, definition, dealt, max_health)
    if dealt <= 0 or max_health <= 0 or
        targets.attitude(ctx, monster) ~= attitudes.HOSTILE or
        contains(definition.flags, flags.NO_EXP_GAIN) then
        return nil
    end

    local observed = event(ctx, kinds.HURT_FOE, monster, definition,
        true, attitudes.HOSTILE)

    observed.level = 0
    observed.damage = dealt
    observed.max_health = max_health
    observed.experience = death.experience(definition, max_health)

    return observed
end

-- Banishment is a separate source conduct, not a kill. It uses the target's
-- experience level and only credits a player's action against an ordinary
-- hostile, rewardable monster. Moving a monster to the Abyss never creates
-- a delayed death event for this conduct.
function facts.banish(ctx, monster, definition, attacker)
    local side = targets.attitude(ctx, monster)
    local credited = attacker == ctx:player() and
        side == attitudes.HOSTILE and
        not ctx:has(monster, component.SUMMON) and
        not contains(definition.flags, flags.NO_EXP_GAIN)
    local observed = event(ctx, kinds.BANISH, monster, definition,
        credited, side)

    return observed
end

-- The source sends the base holiness class first, then trait conducts.
-- Reusing this ordered list for every god keeps the same RNG sequence when
-- a creature satisfies more than one special preference.
function facts.death(ctx, monster, definition)
    local side = targets.attitude(ctx, monster)
    local health = ctx:get(monster, component.HEALTH)

    if not health then
        error("death conduct requires victim health")
    end

    local experience = death.experience(definition, health.max)
    local credited = side == attitudes.HOSTILE and
        not ctx:has(monster, component.SUMMON) and
        death.former_neutral_rewardable(ctx, monster) and
        not contains(definition.flags, flags.NO_EXP_GAIN)
    local events = {}

    local function add(id)
        local observed = event(ctx, id, monster, definition, credited, side)

        observed.experience = experience
        events[#events + 1] = observed
    end

    if contains(definition.holiness, holiness.DEMONIC) then
        add(kinds.KILL_DEMON)
    elseif contains(definition.holiness, holiness.NATURAL) or
        contains(definition.holiness, holiness.PLANT) then
        add(kinds.KILL_LIVING)

        if facts.evil(ctx, monster, definition) then
            add(kinds.KILL_NATURAL_EVIL)
        end
    elseif contains(definition.holiness, holiness.UNDEAD) then
        add(kinds.KILL_UNDEAD)
    elseif contains(definition.holiness, holiness.NONLIVING) then
        add(kinds.KILL_NONLIVING)
    end

    if traits.unclean(definition,
        has_spell_flag(definition, spell_flags.WIZARD)) then
        add(kinds.KILL_UNCLEAN)
    elseif traits.chaotic(definition) then
        add(kinds.KILL_CHAOTIC)
    end

    if has_spell_flag(definition, spell_flags.WIZARD) then
        add(kinds.KILL_WIZARD)
    end

    if has_spell_flag(definition, spell_flags.PRIEST) then
        add(kinds.KILL_PRIEST)
    end

    if slime.slime(definition) then
        add(kinds.KILL_SLIME)
    end

    if contains(definition.holiness, holiness.HOLY) then
        add(kinds.KILL_HOLY)
    end

    if contains(definition.holiness, holiness.PLANT) then
        add(kinds.KILL_PLANT)
    end

    -- Relative speed is only needed for Cheibriados's live response.
    -- Slow is ignored by source policy, while haste still affects speed.
    local player = ctx:player()
    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    if worship and worship.god_id == gods.CHEIBRIADOS then
        -- Timing imports projectiles, which import this classifier. Resolve
        -- it after module registration so the shared combat path has loaded.
        local timing = require("policy.command_timing")
        local move_delay = movement.base(ctx, player)
        local action_delay = timing.player_speed(ctx, player, true)
        local player_speed = math.floor(1000 /
            (move_delay * action_delay))
        local delta = definition.speed - player_speed

        if delta > 0 then
            local observed = event(ctx, kinds.KILL_FAST, monster, definition,
                credited, side)

            observed.speed_delta = delta
            events[#events + 1] = observed
        end
    end

    return events
end

return facts
