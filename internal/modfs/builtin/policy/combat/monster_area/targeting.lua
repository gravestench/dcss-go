-- Direct explosions select a visible cell and assess the whole footprint.
-- Actors or clear walls between caster and target do not stop the blast.
-- Source: mon-cast.cc:_fire_direct_explosion and mons_should_fire.
-- Example: a Fire Storm may be acceptable despite one weak allied victim
-- when the blast reaches several much stronger enemies.
local actors = require("policy.combat.monster_area.actors")
local component = require("constants.component")
local decision = require("policy.combat.monster_area.decision")
local power = require("policy.combat.monster_beams.power")
local target_kind = require("constants.target_kind")

local targeting = {}

-- Reject an out-of-range, wall-hidden, or collateral-heavy target before
-- the spell consumes an action. The returned cell remains fixed in intent.
function targeting.plan(ctx, caster, foe, profile,
    radius, foe_ratio, impact)
    local source = ctx:get(caster, component.POSITION)
    local destination = foe and
        ctx:get(foe, component.POSITION)

    if not source or not destination or
        source.level_id ~= destination.level_id then
        return nil
    end

    local reach = power.spell_range(ctx, caster, profile)
    local distance = math.max(
        math.abs(destination.x - source.x),
        math.abs(destination.y - source.y))

    if reach < 0 or distance > reach or
        not ctx:visible(source.level_id,
            source.x, source.y, reach,
            destination.x, destination.y) then
        return nil
    end

    local victims = actors.blast(ctx, source.level_id,
        destination.x, destination.y, radius)

    if not decision.accept(ctx, caster, victims,
        foe_ratio, impact) then
        return nil
    end

    return {
        kind = target_kind.CELL,
        level_id = source.level_id,
        x = destination.x,
        y = destination.y,
        dx = destination.x - source.x,
        dy = destination.y - source.y,
    }
end

return targeting
