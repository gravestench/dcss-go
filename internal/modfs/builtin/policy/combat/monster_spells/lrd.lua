-- Monster Lee's Rapid Deconstruction chooses the fragmentable cell whose
-- blast gives the highest weighted foe impact. The chosen cell is saved;
-- resolution shares the player's material, dice, and explosion rule.
-- Source: mon-cast.cc:_mons_fragment_target and spl-damage.cc.
-- Example: a rock wall beside the foe can beat an exposed ally as a target.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local decision = require("policy.combat.monster_area.decision")
local explosion = require("policy.combat.explosion")
local fragmentation = require("policy.combat.monster_area.fragmentation")
local materials = require("constants.fragment_material")
local monster_stats = require("policy.combat.monster_stats")
local range = require("policy.magic.range")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")
local target_kind = require("constants.target_kind")

local effect = {}
local spell = catalog.get(categories.SPELLS, spells.SPELL_LRD)
local POWER_PER_HD = 6
local MIN_FOE_RATIO = 80

-- Source monster power uses spell HD, including temporary brilliance, and
-- the LRD spell logic's six power per HD.
local function spell_power(ctx, caster)
    local state = ctx:get(caster, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, state.kind_id)

    return POWER_PER_HD *
        monster_stats.spell_hit_dice(ctx, caster, definition)
end

-- The source tracer counts direct shattering and every reachable splash
-- victim. A solid center propagates fragments but is not itself hit.
local function victims(ctx, level_id, x, y, direct_hit, target, hit_center,
    material)
    local found = {}
    local radius = material == materials.CRYSTAL and 2 or 1

    if direct_hit and target then
        found[#found + 1] = target
    end

    for _, cell in ipairs(explosion.cells(ctx, level_id,
        x, y, radius, not ctx:walkable(level_id, x, y))) do
        if hit_center or cell.x ~= x or cell.y ~= y then
            local victim = ctx:actor_at(level_id, cell.x, cell.y)

            if victim then
                found[#found + 1] = victim
            end
        end
    end

    return found
end

-- Rank visible material targets by source foe power while rejecting a
-- collateral-heavy explosion. Ties keep stable coordinate order, never
-- file discovery order.
function effect.plan(ctx, caster)
    local source = ctx:get(caster, component.POSITION)

    if not source then
        return nil
    end

    local reach = range.for_power(spell, spell_power(ctx, caster))
    local best
    local best_foes = 0

    for _, cell in ipairs(ctx:visible_cells(source.level_id,
        source.x, source.y, reach)) do
        local distance = math.max(math.abs(cell.x - source.x),
            math.abs(cell.y - source.y))

        if distance > 0 and distance <= reach and
            ctx:visible(source.level_id, source.x, source.y,
                reach, cell.x, cell.y) then
            local material, direct_hit, target, hit_center =
                fragmentation.profile(ctx, source.level_id,
                    cell.x, cell.y)

            if material then
                local affected = victims(ctx, source.level_id,
                    cell.x, cell.y, direct_hit, target,
                    hit_center, material)
                local foes, friends = decision.weights(ctx, caster, affected)

                if foes > best_foes and
                    foes * 100 >= MIN_FOE_RATIO * (foes + friends) then
                    best_foes = foes
                    best = cell
                end
            end
        end
    end

    if not best then
        return nil
    end

    return {
        kind = target_kind.CELL,
        level_id = source.level_id,
        x = best.x,
        y = best.y,
        dx = best.x - source.x,
        dy = best.y - source.y,
    }
end

-- The intent fixes the cell. Rechecking its material prevents an unrelated
-- target from being substituted after a terrain or actor change.
function effect.resolve(ctx, caster, _, _, plan)
    local source = ctx:get(caster, component.POSITION)

    if not plan or plan.kind ~= target_kind.CELL or
        not source or source.level_id ~= plan.level_id or
        not fragmentation.profile(ctx, plan.level_id,
            plan.x, plan.y) then
        error("Lee's Rapid Deconstruction lost its planned target")
    end

    fragmentation.resolve(ctx, caster, plan.level_id,
        plan.x, plan.y, spell_power(ctx, caster),
        streams.MONSTER_SPELL)
end

return effect
