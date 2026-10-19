-- Mara draws an enemy player's current combat identity into a separate,
-- saved ghost-like monster. Source: mon-cast.cc:SPELL_SUMMON_ILLUSION.
local channels = require("constants.message_channels")
local component = require("constants.component")
local illusion = require("policy.combat.monster_summons.player_illusion")
local mirror = require("policy.combat.monster_summons.mirror")
local invisibility = require("policy.potions.invisibility")
local target = require("policy.combat.monster_spell_target")
local target_kind = require("constants.target_kind")
local targets = require("policy.ai.targets")
local spells = require("ids.spells")

local effect = {}
local SIGHT_RADIUS = 7

-- Direct sight and the one-copy rule are tested before the scheduler spends
-- a spell action. A hidden or absent player cannot be cloned by stale AI.
local function eligible(ctx, caster, foe)
    if not foe or not targets.enemy(ctx, caster, foe) or
        not invisibility.visible_to(ctx, foe, caster) then
        return false
    end

    local origin = ctx:get(caster, component.POSITION)
    local destination = ctx:get(foe, component.POSITION)

    if not origin or not destination or
        origin.level_id ~= destination.level_id then
        return false
    end

    local choice = ctx:get(foe, component.PLAYER)

    if choice then
        if illusion.exists(ctx, choice.name) then
            return false
        end
    elseif not mirror.eligible_illusion(ctx, foe) then
        return false
    end

    local distance = math.max(math.abs(origin.x - destination.x),
        math.abs(origin.y - destination.y))

    return distance <= SIGHT_RADIUS and
        ctx:visible_no_trans(origin.level_id, origin.x, origin.y,
            SIGHT_RADIUS, destination.x, destination.y)
end

-- The player handle crosses the intent boundary; the later resolver must
-- still clone that actor, not another target in the same cell.
function effect.plan(ctx, caster, foe)
    if not eligible(ctx, caster, foe) then
        return nil
    end

    return {
        kind = target_kind.ENTITY,
        entity = foe,
    }
end

-- Recheck the live target and cap because movement, death, or another cast
-- may have changed the world after the AI planned this spell.
function effect.resolve(ctx, caster, foe, _, plan)
    target.require_entity(plan, foe)

    if not eligible(ctx, caster, foe) then
        return
    end

    if ctx:has(foe, component.PLAYER) and
        illusion.spawn(ctx, caster, foe) then
        ctx:emit(channels.SPELL,
            "There is a horrible, sudden wrenching feeling in your soul!")
    elseif not ctx:has(foe, component.PLAYER) then
        -- Source monster illusion is a full-life copy beside the foe.
        -- It does not untangle or swap the original as Phantom Mirror does.
        mirror.spawn(ctx, caster, foe,
            spells.SPELL_SUMMON_ILLUSION, 100, nil, {
                duration = 6,
                swap = false,
                untangle = false,
                discard_charm = true,
            })
    end
end

return effect
