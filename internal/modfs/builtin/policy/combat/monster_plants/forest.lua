-- Theory of operation: an awake caster makes visible tree cells strike
-- nearby enemies on later caster actions. Trees stay in the level grid;
-- the caster's ECS timer is the only mutable forest state. Its destruction
-- therefore ends the effect without a dangling level-wide global.
-- Source: mon-cast.cc:SPELL_AWAKEN_FOREST and spl-damage.cc:forest_damage.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local direct = require("policy.combat.monster_direct")
local fighter = require("policy.combat.fighter")
local monster_defense = require("policy.combat.monster_defense")
local monster_stats = require("policy.combat.monster_stats")
local proportional = require("policy.magic.damage")
local targets = require("policy.ai.targets")
local trees = require("policy.combat.monster_plants.trees")
local streams = require("constants.rng_streams")

local forest = {}
local SIGHT_RADIUS = 7

-- Check the same eight neighboring cells that source forest attacks use.
-- This function never changes terrain or spends RNG during cast planning.
local function reaching_tree(ctx, origin, victim)
    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                local x = victim.x + dx
                local y = victim.y + dy

                if trees.at(ctx, origin.level_id, x, y) and
                    ctx:visible_no_trans(origin.level_id,
                        origin.x, origin.y, SIGHT_RADIUS, x, y) then
                    return true
                end
            end
        end
    end

    return false
end

-- A single active caster owns a level's forest. Querying saved ECS state
-- means level changes and save/restore cannot leave a stale global flag.
function forest.active(ctx, level_id)
    for _, caster in ipairs(ctx:query({
        component.MONSTER_AWAKE_FOREST,
        component.POSITION,
        component.HEALTH,
    })) do
        local state = ctx:get(caster, component.MONSTER_AWAKE_FOREST)
        local position = ctx:get(caster, component.POSITION)
        local health = ctx:get(caster, component.HEALTH)

        if position.level_id == level_id and health.current > 0 and
            state.remaining_aut > 0 then
            return true
        end
    end

    return false
end

-- Return enemies that are both in the caster's nontransparent sight and
-- next to a tree the caster can reach with its forest command.
function forest.victims(ctx, caster)
    local origin = ctx:get(caster, component.POSITION)
    local found = {}

    if not origin then
        return found
    end

    for _, victim in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        if targets.enemy(ctx, caster, victim) then
            local position = ctx:get(victim, component.POSITION)
            local health = ctx:get(victim, component.HEALTH)
            local distance = math.max(math.abs(position.x - origin.x),
                math.abs(position.y - origin.y))

            if health.current > 0 and
                position.level_id == origin.level_id and
                distance <= SIGHT_RADIUS and
                ctx:visible_no_trans(origin.level_id, origin.x,
                    origin.y, SIGHT_RADIUS, position.x, position.y) and
                reaching_tree(ctx, origin, position) then
                found[#found + 1] = victim
            end
        end
    end

    return found
end

-- The source duration is fifty aut plus a roll scaled by caster spell HD.
-- No draw occurs before the cast has passed the forest eligibility check.
function forest.awaken(ctx, caster)
    local position = ctx:get(caster, component.POSITION)

    if not position or forest.active(ctx, position.level_id) or
        #forest.victims(ctx, caster) == 0 then
        return false
    end

    local actor = ctx:get(caster, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)
    local hd = monster_stats.spell_hit_dice(ctx, caster, definition)
    local duration = 50 + ctx:random(streams.MONSTER_SPELL, hd * 20)

    ctx:add(caster, component.MONSTER_AWAKE_FOREST, {
        remaining_aut = duration,
    })
    ctx:emit("spell", "The forest starts to sway and rumble!")

    return true
end

-- Source apply_chunked_AC(1, EV) gives the branch a (80/81)^EV hit chance.
-- Draw one random word, as the common proportional-armour owner does.
local function tree_hits(ctx, evasion)
    local threshold = math.floor((80 / 81) ^ evasion * 4294967296)
    local _, word = ctx:random_u64(streams.MELEE)

    return word < threshold
end

-- One tree can strike each unaligned foe per caster action. Damage goes
-- through the ordinary HP owner after source proportional armour.
local function strike(ctx, caster, victim, hd)
    local player = ctx:has(victim, component.PLAYER)
    local definition
    local evasion

    if player then
        evasion = fighter.defense(ctx).ev
    else
        local actor = ctx:get(victim, component.ACTOR)

        definition = catalog.get(categories.MONSTERS, actor.kind_id)
        evasion = monster_defense.evasion(ctx, victim, definition)
    end

    if not tree_hits(ctx, evasion) then
        return
    end

    local raw = hd + ctx:random(streams.MELEE, hd)
    local amount

    if player then
        amount = proportional.player_proportional_armour(ctx,
            victim, raw, hd * 2 - 1)
    else
        amount = proportional.monster_proportional_armour(ctx,
            victim, raw, hd * 2 - 1)
    end

    if amount > 0 then
        direct.damage(ctx, caster, victim, amount)
        ctx:emit("combat", "A tree reaches out and hits its foe!")
    end
end

-- A caster's action drives both forest attacks and timer decay. A dead
-- caster is removed by the death owner, which also erases its forest state.
function forest.tick(ctx, caster, aut)
    local state = ctx:get(caster, component.MONSTER_AWAKE_FOREST)

    if not state then
        return
    end

    local health = ctx:get(caster, component.HEALTH)

    if not health or health.current <= 0 then
        ctx:remove(caster, component.MONSTER_AWAKE_FOREST)

        return
    end

    local actor = ctx:get(caster, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)
    local hd = monster_stats.hit_dice(ctx, caster, definition)

    for _, victim in ipairs(forest.victims(ctx, caster)) do
        strike(ctx, caster, victim, hd)
    end

    state.remaining_aut = math.max(0, state.remaining_aut - aut)

    if state.remaining_aut == 0 then
        ctx:remove(caster, component.MONSTER_AWAKE_FOREST)
        ctx:emit("spell", "The forest calms down.")
    else
        ctx:set(caster, component.MONSTER_AWAKE_FOREST, state)
    end
end

return forest
