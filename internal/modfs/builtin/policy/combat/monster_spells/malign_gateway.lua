local component = require("constants.component")
local streams = require("constants.rng_streams")
local target_kind = require("constants.target_kind")
local targets = require("policy.ai.targets")
local terrain = require("policy.magic.effects.summons.terrain")
local terrain_ids = require("constants.terrain")

local effect = {}

-- The source permits one gateway globally, regardless of its summoner.
-- Preserve the chosen cell in intent; resolution must not roll it again.
function effect.plan(ctx, caster)
    if #ctx:query({ component.SUMMON_GATEWAY }) > 0 then
        return nil
    end

    local position = ctx:get(caster, component.POSITION)
    local points = terrain.gateway_points(ctx, position)
    local visible = {}

    for _, point in ipairs(points) do
        if ctx:visible_no_trans(position.level_id, position.x, position.y,
            7, point.x, point.y) then
            visible[#visible + 1] = point
        end
    end

    if #visible == 0 then
        return nil
    end

    local point = visible[1 + ctx:random(streams.MONSTER_SPELL, #visible)]

    return {
        kind = target_kind.CELL,
        level_id = position.level_id,
        x = point.x,
        y = point.y,
    }
end

-- spl-summoning.cc uses power 200 for monster portals and delays emergence
-- by 10..20 aut. The shared saved gateway marker owns the ensuing tentacle.
function effect.resolve(ctx, caster, _, _, plan)
    if not plan or plan.kind ~= target_kind.CELL then
        error("Malign Gateway requires its planned cell")
    end

    local marker = ctx:create()

    ctx:add(marker, component.SUMMON_GATEWAY, {
        -- C++ stores a non-actor summoner: the portal survives caster death.
        owner = marker,
        level_id = plan.level_id,
        x = plan.x,
        y = plan.y,
        original_feature = ctx:cell(plan.level_id, plan.x, plan.y),
        expires_aut = ctx:aut() + 10 *
            (1 + ctx:random(streams.MONSTER_SPELL, 2)),
        power = 200,
        phase = 0,
        tentacle_id = 0,
        attitude = targets.attitude(ctx, caster),
    })
    ctx:set_cell(plan.level_id, plan.x, plan.y, terrain_ids.DNGN_MALIGN_GATEWAY)
    ctx:emit("spell", "The dungeon shakes as a portal opens!")
end

return effect
