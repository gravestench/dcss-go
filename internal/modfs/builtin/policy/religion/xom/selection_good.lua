-- Xom's helpful action gates follow source priority. Each gate keeps its
-- eligibility beside the draw that pays for it; later gates run only when
-- earlier ones fail.
local allies = require("policy.character.allies")
local animation = require("policy.religion.xom.effects.animate_weapon")
local branches = require("ids.branches")
local chance = require("policy.religion.xom.selection_chance")
local combat = require("policy.religion.xom.effects.combat")
local clouds = require("policy.clouds.placement")
local component = require("constants.component")
local confusion = require("policy.religion.xom.confusion")
local enchantment = require("policy.religion.xom.effects.monsters.enchantment")
local events = require("ids.xom_events")
local explosion = require("policy.combat.explosion")
local exploration = require("policy.religion.xom.exploration")
local physiology = require("policy.mutations.physiology")
local polymorph = require("policy.religion.xom.effects.monsters.polymorph")
local cleaving = require("policy.religion.xom.cleaving")
local mutation_records = require("policy.mutations.records")
local scenery = require("policy.religion.xom.effects.scenery")
local selection_mods = require("policy.religion.xom.selection_mods")
local snakes = require("policy.religion.xom.effects.monsters.snakes")
local spell = require("policy.religion.xom.effects.spell")
local target_policy = require("policy.ai.targets")
local tension_policy = require("policy.combat.monster_seal_tension")
local translocation = require("policy.scrolls.translocation")

local good = {}

local divinations = {
    events.GOOD_MAGIC_MAPPING,
    events.GOOD_DETECT_CREATURES,
    events.GOOD_DETECT_ITEMS,
}

-- Potions are the first combat aid. The tension roll is paid before the
-- severity chance, even when no potion effect would later be useful.
local function potion(ctx, player, state, severity, tension, stream)
    if tension > ctx:random(stream, 3) and
        chance.in_y(ctx, stream, 2, severity) then
        return events.GOOD_POTION
    end
end

-- Detecting creatures is useful on an explored floor; mapping and items
-- need enough unknown terrain unless Xom's exploration roll permits them.
local function divination(ctx, player, state, severity, tension, stream)
    if not chance.in_y(ctx, stream, 3, severity) then
        return nil
    end

    local chosen = divinations[ctx:random(stream, #divinations) + 1]

    if chosen == events.GOOD_DETECT_CREATURES then
        return chosen
    end

    local position = ctx:get(player, component.POSITION)

    if not position then
        return nil
    end

    local explored = exploration.estimate(ctx, position.level_id,
        false, stream)

    if explored <= 80 or chance.in_y(ctx, stream, explored, 100) then
        return chosen
    end
end

-- The source probes a severity prefix of its spell list here and draws
-- again when the effect fires. A failed spell probe leaves later gates.
local function forced_spell(ctx, player, state, severity, tension, stream)
    if chance.in_y(ctx, stream, 4, severity) and tension > 0 and
        spell.choose(ctx, player, severity, stream) then
        return events.GOOD_SPELL
    end
end

-- A second cloud trail cannot stack with the saved active trail.
local function cloud_trail(ctx, player, state, severity, tension, stream)
    if tension <= 0 and chance.in_y(ctx, stream, 5, severity) and
        not ctx:has(player, component.XOM_CLOUD_TRAIL) then
        return events.GOOD_CLOUD_TRAIL
    end
end

-- Confusion needs a nearby hostile in no-trans sight, after the chance
-- succeeds. Actual confusion immunity remains with the effect owner.
local function confuse_monsters(ctx, player, state, severity, tension, stream)
    if tension <= 0 or
        not chance.in_y(ctx, stream, 5, severity) then
        return nil
    end

    for _, monster in ipairs(confusion.nearby(ctx, player)) do
        if confusion.hostile(ctx, monster) then
            return events.GOOD_CONFUSION
        end
    end
end

-- Divine enchantment chooses only a hostile with finite willpower. The
-- selector checks the same target pool the live effect will draw from.
local function enchant_monster(ctx, player, state, severity, tension, stream)
    if tension > 0 and chance.in_y(ctx, stream, 6, severity) and
        #enchantment.enchant_candidates(ctx, player) > 0 then
        return events.GOOD_ENCHANT_MONSTER
    end
end

-- Xom never offers a friendly demon to a player whose No Love mutation
-- forbids allies, even if the severity and tension draws would succeed.
local function single_ally(ctx, player, state, severity, tension, stream)
    if tension > ctx:random(stream, 5) and
        chance.in_y(ctx, stream, 7, severity) and
        not allies.forbidden(ctx, player) then
        return events.GOOD_SINGLE_ALLY
    end
end

-- The source permits a rare scenery action without a visible feature.
-- Keep the fallback one-in-eight roll after the ordinary low-tension path.
local function change_scenery(ctx, player, state, severity, tension, stream)
    if tension < ctx:random(stream, 5) and
        chance.in_y(ctx, stream, 8, severity) and
        #scenery.candidates(ctx, player) > 0 then
        return events.GOOD_SCENERY
    end

    if ctx:random(stream, 8) == 0 then
        return events.GOOD_SCENERY
    end
end

-- The source checks a no-trans visible hostile snake after spending this
-- gate's chance. Reuse the live effect's genus pool so adding a snake kind
-- does not require changing the selector.
local function snakes_to_sticks(ctx, player, state, severity, tension, stream)
    if chance.in_y(ctx, stream, 9, severity) and
        #snakes.candidates(ctx, player) > 0 then
        return events.GOOD_SNAKES
    end
end

-- A larger ally group costs a separate danger draw and cannot be offered
-- to a player whose current mutation forbids allies.
local function allied_group(ctx, player, state, severity, tension, stream)
    if tension > ctx:random(stream, 10) and
        chance.in_y(ctx, stream, 10, severity) and
        not allies.forbidden(ctx, player) then
        return events.GOOD_ALLIES
    end
end

-- An armed hostile offers a real item to animate. The effect and selector
-- share one source-shaped candidate pool, including summoned, ranged,
-- distortion, and unique-item exclusions.
local function animate_weapon(ctx, player, state, severity, tension, stream)
    if tension > ctx:random(stream, 8) and
        chance.in_y(ctx, stream, 11, severity) and
        #animation.candidates(ctx, player) > 0 and
        not allies.forbidden(ctx, player) then
        return events.GOOD_ANIMATE_MON_WPN
    end
end

-- The source tests the chance before asking for a nearby mutable body.
-- Reusing the actual effect's target rule keeps firewood and immutable
-- monsters out of both selection and execution.
local function polymorph_monster(ctx, player, state, severity, tension, stream)
    if chance.in_y(ctx, stream, 12, severity) and
        polymorph.polymorph_target(ctx, player) then
        return events.GOOD_POLYMORPH
    end
end

-- The fake draw precedes the nearby target scan. Real fireballs need a
-- nonadjacent hostile unless Xom feels nasty; fake ones need any ordinary
-- nearby monster that can be illuminated.
local function destruction(ctx, player, state, severity, tension, stream)
    if tension <= 0 or
        not chance.in_y(ctx, stream, 13, severity) then
        return nil
    end

    local fake = ctx:random(stream, 3) == 0

    if combat.has_destruction_target(ctx, player, not fake) then
        return fake and events.GOOD_FAKE_DESTRUCTION or
            events.GOOD_DESTRUCTION
    end
end

-- A fighting player can gain Cleaving even without a nearby target. The
-- duration is saved by the effect and changes subsequent melee contacts.
local function cleaving_gift(ctx, player, state, severity, tension, stream)
    if tension > ctx:random(stream, 5) and
        chance.in_y(ctx, stream, 14, severity) then
        return events.GOOD_CLEAVING
    end
end

-- Fog cannot start on an occupied cloud square. Other cloud events use
-- the same placement owner, so the gate sees their saved occupancy.
local function fog(ctx, player, state, severity, tension, stream)
    if tension <= 0 or
        not chance.in_y(ctx, stream, 15, severity) then
        return nil
    end

    local position = ctx:get(player, component.POSITION)

    if position and not clouds.at(ctx, position.level_id,
        position.x, position.y) then
        return events.GOOD_FOG
    end
end

-- The source first tests low tension, then the action chance, then a
-- severity-based chance for acquirement versus an ordinary random item.
local function item_gift(ctx, player, state, severity, tension, stream)
    if ctx:random(stream, math.max(1, tension)) < 15 and
        chance.in_y(ctx, stream, 16, severity) then
        if chance.in_y(ctx, stream, severity, 201) then
            return events.GOOD_ACQUIREMENT
        end

        return events.GOOD_RANDOM_ITEM
    end
end

-- A good teleport avoids Abyss and the player's current stasis. A mostly
-- cleared floor can still receive the journey on its source rare roll.
local function teleport_player(ctx, player, state, severity, tension, stream)
    local position = ctx:get(player, component.POSITION)

    if not position or
        ctx:level_branch(position.level_id) == branches.BRANCH_ABYSS or
        not chance.in_y(ctx, stream, 17, severity) or
        translocation.restriction(ctx, player, false) then
        return nil
    end

    local explored = exploration.estimate(ctx, position.level_id,
        true, stream)

    if explored < 80 or
        not chance.in_y(ctx, stream, explored, 120) then
        return events.GOOD_TELEPORT
    end
end

-- Source how_mutated counts distinct noninnate mutations, not summed
-- ranks. Keeping the count here avoids another mutable player cache.
local function mutation_count(ctx, player)
    local count = 0

    for _, entry in ipairs(mutation_records.list(ctx, player)) do
        local state = entry.state

        if state.acquired + state.temporary > 0 then
            count = count + 1
        end
    end

    return count
end

-- The mutation saturation chance becomes impossible only after enough
-- distinct mutations have accumulated; unsafe undead forms veto it later.
local function mutation_gift(ctx, player, state, severity, tension, stream)
    if ctx:random(stream, math.max(1, tension)) < 5 and
        chance.in_y(ctx, stream, 19, severity) and
        chance.in_y(ctx, stream, 16,
            mutation_count(ctx, player)) and
        physiology.can_safely_mutate(ctx, player) then
        return events.GOOD_MUTATION
    end
end

-- Lightning needs a live hostile in the same radius-two footprint as the
-- eventual blast. Local danger must still be present when this gate runs.
local function lightning(ctx, player, state, severity, tension, stream)
    if tension <= 0 or
        not chance.in_y(ctx, stream, 20, severity) or
        tension_policy.current(ctx, player) <= 0 then
        return nil
    end

    local position = ctx:get(player, component.POSITION)

    if not position then
        return nil
    end

    for _, cell in ipairs(explosion.cells(ctx, position.level_id,
        position.x, position.y, 2)) do
        local monster = ctx:actor_at(position.level_id,
            cell.x, cell.y)
        local health = monster and ctx:get(monster, component.HEALTH)

        if monster and monster ~= player and health and
            health.current > 0 and
            target_policy.enemy(ctx, player, monster) then
            return events.GOOD_LIGHTNING
        end
    end
end

-- One named gate owns each source stage. Custom events can take positions
-- between these stages without copying this selector or changing its draws.
local gates = {
    [10] = potion,
    [20] = divination,
    [30] = forced_spell,
    [40] = cloud_trail,
    [50] = confuse_monsters,
    [60] = enchant_monster,
    [70] = single_ally,
    [80] = change_scenery,
    [90] = snakes_to_sticks,
    [100] = allied_group,
    [110] = animate_weapon,
    [120] = polymorph_monster,
    [130] = destruction,
    [140] = cleaving_gift,
    [150] = fog,
    [160] = item_gift,
    [170] = teleport_player,
    [180] = mutation_gift,
    [190] = lightning,
}

-- Run the effective catalog beside the original priority sequence.
function good.choose(ctx, player, severity, tension, stream)
    return selection_mods.choose(ctx, player, nil, severity,
        tension, stream, "good", gates)
end

return good
