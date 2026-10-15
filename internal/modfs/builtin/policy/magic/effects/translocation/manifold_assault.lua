local spells = require("ids.spells")
local component = require("constants.component")
local actions = require("policy.combat.melee_actions")
local common = require("policy.magic.effects.translocation.common")
local registry = require("policy.magic.effects.registry")
local trajectory = require("policy.combat.trajectory")

local function targets(ctx, player)
    local origin = ctx:get(player, component.POSITION)
    local found = {}

    for _, monster in ipairs(common.monsters(ctx, origin.level_id)) do
        local distance = common.distance(origin, monster.position)

        if distance <= 7 and not ctx:has(monster.entity, component.SUMMON) and
            not common.flag(monster.definition, "M_STATIONARY") and
            not common.flag(monster.definition, "M_PROJECTILE") and
            ctx:visible(origin.level_id, origin.x, origin.y, 7,
                monster.position.x, monster.position.y) then
            local ray = trajectory.to_target(ctx, origin.level_id,
                origin.x, origin.y, monster.position.x,
                monster.position.y, distance)

            if not ray.blocked then
                found[#found + 1] = monster.entity
            end
        end
    end

    return found
end

-- Source: spl-transloc.cc:cast_manifold_assault. The existing melee action
-- resolves each projected strike, including weapon and auxiliary attacks.
local spell_effects = {}

function spell_effects.prepare(ctx, player)
    if #targets(ctx, player) == 0 then
        return "You can't see anything to attack."
    end
end

function spell_effects.resolve(ctx, player, _, _, power)
    local found = targets(ctx, player)

    for index = #found, 2, -1 do
        local other = ctx:random("spell", index) + 1
        found[index], found[other] = found[other], found[index]
    end

    local quotient = math.floor(power / 50)
    local remainder = power % 50
    local cap = 2 + quotient +
        (ctx:random("spell", 50) < remainder and 1 or 0)
    ctx:emit("spell", "Space momentarily warps into an impossible shape!")

    for index = 1, math.min(cap, #found) do
        local health = ctx:get(found[index], component.HEALTH)

        if health and health.current > 0 then
            actions.player(ctx, found[index])
        end
    end
end

registry.add(spells.SPELL_MANIFOLD_ASSAULT, {
    prepare = spell_effects.prepare,

    resolve = spell_effects.resolve,
})

return spell_effects
