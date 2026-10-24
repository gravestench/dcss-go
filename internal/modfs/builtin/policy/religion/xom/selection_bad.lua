-- Xom's harmful actions are tried in source priority. Separate named gates
-- keep each reason for eligibility close to its probability and preserve
-- short-circuit RNG behavior when a mod changes one effect.
local chance = require("policy.religion.xom.selection_chance")
local chaos_upgrade = require("policy.religion.xom.effects.monsters.chaos_upgrade")
local clouds = require("policy.clouds.placement")
local branches = require("ids.branches")
local component = require("constants.component")
local events = require("ids.xom_events")
local gods = require("constants.gods")
local exploration = require("policy.religion.xom.exploration")
local movement = require("policy.religion.xom.effects.monsters.movement")
local damage = require("policy.magic.damage")
local player_resistance = require("policy.combat.player_resistance")
local physiology = require("policy.mutations.physiology")
local repel = require("policy.religion.xom.stair_repel")
local selection_mods = require("policy.religion.xom.selection_mods")
local resistance_ids = require("constants.resistance_ids")
local translocation = require("policy.scrolls.translocation")
local xom_state = require("policy.religion.xom.state")

local bad = {}

-- A pseudo-miscast is an early, harmless choice only when the severity
-- cannot turn it into the source's nasty miscast.
local function pseudo_miscast(ctx, player, state, severity, tension, stream)
    local nasty = severity >= 5 and xom_state.feels_nasty(state)

    if not nasty and chance.in_y(ctx, stream, 3, severity) then
        return events.BAD_MISCAST_PSEUDO
    end
end

-- Noise can occur outside a fight, but its first coinflip must precede
-- its severity chance when there is no tension.
local function noise(ctx, player, state, severity, tension, stream)
    if (tension > 0 or ctx:random(stream, 2) == 0) and
        chance.in_y(ctx, stream, 6, severity) then
        return events.BAD_NOISE
    end
end

-- Monster enchantment may spend an action even when its later target draw
-- finds nothing. The source gate checks only tension and chance here.
local function enchant_monster(ctx, player, state, severity, tension, stream)
    if tension > 0 and chance.in_y(ctx, stream, 7, severity) then
        return events.BAD_ENCHANT_MONSTER
    end
end

-- Blinking needs an actual mobile victim after its chance succeeds.
local function blink_monsters(ctx, player, state, severity, tension, stream)
    if tension > 0 and chance.in_y(ctx, stream, 8, severity) and
        #movement.blink_candidates(ctx, player) > 0 then
        return events.BAD_BLINK_MONSTERS
    end
end

-- Confusing the player is pointless without nearby danger; the effect
-- itself handles the player's resistance and status duration.
local function confuse_player(ctx, player, state, severity, tension, stream)
    if tension > 0 and chance.in_y(ctx, stream, 9, severity) then
        return events.BAD_CONFUSION
    end
end

-- Swapping pieces requires a compatible occupied square and player cell.
local function swap_monsters(ctx, player, state, severity, tension, stream)
    if tension > 0 and chance.in_y(ctx, stream, 10, severity) and
        #movement.swap_candidates(ctx, player) > 0 then
        return events.BAD_SWAP_MONSTERS
    end
end

-- Upgrading equipment reuses the effect's restrictions on monster gods,
-- summoned gear, artefacts, and already-chaotic loadouts.
local function upgrade_chaos(ctx, player, state, severity, tension, stream)
    if chance.in_y(ctx, stream, 14, severity) and
        #chaos_upgrade.candidates(ctx, player, stream) > 0 then
        return events.BAD_CHAOS_UPGRADE
    end
end

-- Bad teleport is unattractive to Xom on an explored floor. When he feels
-- nasty, either substantial exploration or high danger vetoes the journey
-- before the usual randomly raised exploration threshold is checked.
local function teleport_player(ctx, player, state,
    severity, tension, stream)
    if not chance.in_y(ctx, stream, 15, severity) then
        return nil
    end

    local position = ctx:get(player, component.POSITION)

    if not position or
        ctx:level_branch(position.level_id) == branches.BRANCH_ABYSS or
        translocation.restriction(ctx, player) then
        return nil
    end

    local explored = exploration.estimate(ctx, position.level_id,
        true, stream)
    local nasty = xom_state.feels_nasty(state)

    if nasty and (explored >= 40 or tension > 10) then
        return nil
    end

    if explored >= 60 + ctx:random(stream, 40) then
        return nil
    end

    return events.BAD_TELEPORT
end

-- The source selects polymorph on chance alone. Its effect later decides
-- whether any nearby mutable body exists, so no target scan is done here.
local function polymorph_monster(ctx, player, state, severity, tension, stream)
    if chance.in_y(ctx, stream, 16, severity) then
        return events.BAD_POLYMORPH
    end
end

-- Stair interference needs danger or the Abyss, a visible stair, and no
-- active repulsion duration. The source then makes climb refusal rarer
-- unless the player is standing on a stair already.
local function repel_stairs(ctx, player, state, severity, tension, stream)
    local position = ctx:get(player, component.POSITION)

    if not position or
        (tension <= 0 and
            ctx:level_branch(position.level_id) ~= branches.BRANCH_ABYSS) or
        not chance.in_y(ctx, stream, 17, severity) then
        return nil
    end

    if #repel.nearby(ctx, player) == 0 then
        return nil
    end

    local active = ctx:get(player, component.XOM_STAIR_REPEL)

    if active and (active.move_aut > 0 or active.climb_aut > 0) then
        return nil
    end

    local underfoot = ctx:travel_feature_at(position.level_id,
        position.x, position.y)

    if ctx:random(stream, 5) == 0 or underfoot then
        return events.BAD_CLIMB_STAIRS
    end

    return events.BAD_MOVING_STAIRS
end

-- Bad mutations are more likely at low tension, but still require the
-- ordinary body-safety rule after the chance has been paid.
local function bad_mutation(ctx, player, state, severity, tension, stream)
    local tension_roll = tension > 0 and
        ctx:random(stream, tension) or 0

    if tension_roll < 11 and
        chance.in_y(ctx, stream, 18, severity) and
        physiology.can_safely_mutate(ctx, player) then
        return events.BAD_MUTATION
    end
end

-- Hostile summoning has no target or tension restriction. Placement may
-- still fail later if the player is fully surrounded, as in the source.
local function summon_hostiles(ctx, player, state, severity, tension, stream)
    if chance.in_y(ctx, stream, 19, severity) then
        return events.BAD_SUMMON_HOSTILES
    end
end

-- The source first tries stat loss, then draining, then torment. Failing
-- resistance checks fall through to later Xom gates instead of forcing a
-- different effect within this one chance roll.
local function misfortune(ctx, player, state, severity, tension, stream)
    if not chance.in_y(ctx, stream, 21, severity) then
        return nil
    end

    if ctx:random(stream, 2) == 0 then
        return events.BAD_STATLOSS
    end

    if ctx:random(stream, 2) == 0 then
        if damage.player_resistance(ctx, player,
            resistance_ids.NEGATIVE_ENERGY) < 3 then
            return events.BAD_DRAINING
        end

        return nil
    end

    if not player_resistance.torment(ctx, player) then
        return events.BAD_TORMENT
    end
end

-- Source cloud placement needs danger, a successful severity roll, and
-- no cloud already occupying the player's square.
local function chaos_cloud(ctx, player, state, severity, tension, stream)
    if tension <= 0 or
        not chance.in_y(ctx, stream, 22, severity) then
        return nil
    end

    local position = ctx:get(player, component.POSITION)

    if position and not clouds.at(ctx, position.level_id,
        position.x, position.y) then
        return events.BAD_CHAOS_CLOUD
    end
end

-- Penance permits banishment outright. Ordinary worship first checks
-- Xom's boredom and the source experience-level protection; a young
-- player can only reach the banishment that Xom immediately retracts.
local function may_banish(ctx, state, level, stream)
    if ((state.penance or {})[gods.XOM] or 0) > 0 then
        return true
    end

    if xom_state.feels_nasty(state) then
        return not chance.in_y(ctx, stream, 5, level)
    end

    if level < 9 then
        return ctx:random(stream, 5) == 0 and
            chance.in_y(ctx, stream, state.piety, 1000)
    end

    return not chance.in_y(ctx, stream, 5, level)
end

-- The source makes a single late one-in-severity attempt outside Abyss.
-- A non-nasty act may turn into pseudo banishment after the allowance roll.
local function banishment(ctx, player, state, severity, tension, stream)
    if not chance.in_y(ctx, stream, 1, severity) then
        return nil
    end

    local position = ctx:get(player, component.POSITION)

    if not position or
        ctx:level_branch(position.level_id) == branches.BRANCH_ABYSS then
        return nil
    end

    local progress = ctx:get(player, component.PROGRESSION)

    if not progress or
        not may_banish(ctx, state, progress.level, stream) then
        return nil
    end

    if not xom_state.feels_nasty(state) and
        (progress.level < 9 or
            chance.in_y(ctx, stream, state.piety, 1000)) then
        return events.BAD_PSEUDO_BANISHMENT
    end

    return events.BAD_BANISHMENT
end

-- Named stages preserve source short-circuit draws while letting mods add
-- events between source gates without an ever-growing event switch.
local gates = {
    [10] = pseudo_miscast,
    [20] = noise,
    [30] = enchant_monster,
    [40] = blink_monsters,
    [50] = confuse_player,
    [60] = swap_monsters,
    [70] = upgrade_chaos,
    [80] = teleport_player,
    [90] = polymorph_monster,
    [100] = repel_stairs,
    [110] = bad_mutation,
    [120] = summon_hostiles,
    [130] = misfortune,
    [140] = chaos_cloud,
    [150] = banishment,
}

-- The effective event catalog contributes custom gates at declared stages.
function bad.choose(ctx, player, state, severity, tension, stream)
    return selection_mods.choose(ctx, player, state, severity,
        tension, stream, "bad", gates)
end

return bad
