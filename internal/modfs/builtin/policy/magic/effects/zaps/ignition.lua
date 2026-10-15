local component = require("constants.component")
local spells = require("ids.spells")
local catalog = require("policy.catalog")
local explosive = require("policy.magic.effects.zaps.explosive")
local registry = require("policy.magic.effects.registry")
local targets = require("policy.ai.targets")

local ignition = {}

local spec = {
    name = "ignition",
    cap = 200,
    element = "MR_RES_FIRE",
    damage = {
        count = 3,
        base = 10,
        numerator = 1,
        denominator = 3,
    },
}

local function has_flag(definition, wanted)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

local function friendly(ctx, actor, player)
    return not targets.enemy(ctx, player, actor)
end

local function blast_sources(ctx, player, origin)
    local sources = {}

    -- spl-damage.cc:get_ignition_blast_sources snapshots hostile actors in
    -- LOS_NO_TRANS before explosions can kill or move them.
    for _, target in ipairs(ctx:query({
        component.ACTOR, component.POSITION, component.HEALTH,
    })) do
        if not friendly(ctx, target, player) then
            local position = ctx:get(target, component.POSITION)
            local health = ctx:get(target, component.HEALTH)
            local actor = ctx:get(target, component.ACTOR)
            local definition = catalog.get("monsters", actor.kind_id)
            local firewood = has_flag(definition, "M_STATIONARY") and
                has_flag(definition, "M_NO_THREAT")
            local distance = math.max(math.abs(position.x - origin.x),
                math.abs(position.y - origin.y))

            if health.current > 0 and not firewood and
                position.level_id == origin.level_id and distance <= 7 and
                ctx:visible(origin.level_id, origin.x, origin.y, 7,
                    position.x, position.y) then
                sources[#sources + 1] = {
                    x = position.x,
                    y = position.y,
                }
            end
        end
    end

    return sources
end

function ignition.resolve(ctx, player, _, _, power)
    local origin = ctx:get(player, component.POSITION)
    local sources = blast_sources(ctx, player, origin)

    if #sources == 0 then
        ctx:emit("spell", "Nothing happens.")
        return
    end

    local adjacent = {}

    for _, source in ipairs(sources) do
        for dy = -1, 1 do
            for dx = -1, 1 do
                if dx ~= 0 or dy ~= 0 then
                    local x = source.x + dx
                    local y = source.y + dy
                    local actor = ctx:actor_at(origin.level_id, x, y)

                    if ctx:walkable(origin.level_id, x, y) and
                        (not actor or not friendly(ctx, actor, player)) then
                        -- Deliberately retain duplicates: overlapping
                        -- Ignition blasts strike the square more than once.
                        adjacent[#adjacent + 1] = {
                            x = x,
                            y = y,
                        }
                    end
                end
            end
        end
    end

    ctx:emit("spell", "The air bursts into flame!")

    for _, source in ipairs(sources) do
        local target = ctx:actor_at(origin.level_id, source.x, source.y)

        if target then
            explosive.hurt(ctx, player, target, spec, power)
        end
    end

    for _, cell in ipairs(adjacent) do
        local target = ctx:actor_at(origin.level_id, cell.x, cell.y)

        if target then
            explosive.hurt(ctx, player, target, spec, power)
        end
    end
end

registry.add(spells.SPELL_IGNITION, ignition)

return ignition
