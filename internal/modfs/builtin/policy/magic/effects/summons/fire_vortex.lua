local monsters = require("ids.monsters")
local spells = require("ids.spells")
local component = require("constants.component")
local intent_ids = require("constants.intent")
local death_hooks = require("policy.combat.death_hooks")
local targets = require("policy.ai.targets")
local cloud = require("policy.magic.effects.zaps.cloud")
local summons = require("policy.magic.effects.summons.common")

local vortex = {}

local offsets = {
    { -1, -1 }, { 0, -1 }, { 1, -1 },
    { -1, 0 }, { 1, 0 },
    { -1, 1 }, { 0, 1 }, { 1, 1 },
}

local function random_step(ctx, entity, origin)
    local choices = {}

    for _, offset in ipairs(offsets) do
        local x = origin.x + offset[1]
        local y = origin.y + offset[2]
        local occupant = ctx:actor_at(origin.level_id, x, y)

        if ctx:walkable(origin.level_id, x, y) and
            (not occupant or targets.enemy(ctx, entity, occupant)) then
            choices[#choices + 1] = offset
        end
    end

    if #choices == 0 then
        return { kind = intent_ids.MONSTER_WAIT }
    end

    local step = choices[ctx:random("spell", #choices) + 1]

    return { kind = intent_ids.MONSTER_MOVE, dx = step[1], dy = step[2] }
end

-- Source: mon-data.h:MONS_FIRE_VORTEX has M_CONFUSED; mon-act.cc randomly
-- redirects two in three moves. Contact is resolved by summon_melee.
function vortex.act(ctx, entity, origin)
    local target, distance = targets.nearest(ctx, entity, origin, 7)

    if not target or ctx:random("spell", 3) ~= 0 then
        return random_step(ctx, entity, origin)
    end

    local destination = ctx:get(target, component.POSITION)

    if distance == 1 then
        return {
            kind = intent_ids.MONSTER_MELEE,
            dx = destination.x - origin.x,
            dy = destination.y - origin.y,
        }
    end

    local dx, dy, found = ctx:route_step(origin.level_id,
        origin.x, origin.y, destination.x, destination.y, target)

    if found and ctx:walkable(origin.level_id, origin.x + dx, origin.y + dy) then
        return { kind = intent_ids.MONSTER_MOVE, dx = dx, dy = dy }
    end

    return random_step(ctx, entity, origin)
end

local function fire_cloud(ctx, entity, position)
    local state = ctx:get(entity, component.SUMMON)

    if not state or state.source_id ~= spells.SPELL_FIRE_STORM then
        return
    end

    -- Source: mon-death.cc:1890-1894 leaves a 2+random2(4) turn fire cloud.
    cloud.place(ctx, "CLOUD_FIRE", state.owner, position.level_id,
        position.x, position.y, (2 + ctx:random("spell", 4)) * 10)
end

function vortex.on_death(ctx, entity, definition, position)
    if definition.id == monsters.MONS_FIRE_VORTEX then
        fire_cloud(ctx, entity, position)
    end

    return false
end

function vortex.dissipate(ctx, entity)
    local position = ctx:get(entity, component.POSITION)

    if position then
        fire_cloud(ctx, entity, position)
    end

    summons.expire(ctx, entity)
end

death_hooks.add("magic.summon.fire_vortex", vortex.on_death)

return vortex
