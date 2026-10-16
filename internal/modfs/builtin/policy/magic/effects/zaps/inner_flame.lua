local component = require("constants.component")
local zap_ids = require("policy.magic.effects.zaps.ids")
local spells = require("ids.spells")
local catalog = require("policy.catalog")
local cloud = require("policy.magic.effects.zaps.cloud")
local death_hooks = require("policy.combat.death_hooks")
local explosion = require("policy.combat.explosion")
local explosive = require("policy.magic.effects.zaps.explosive")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")
local will = require("policy.magic.effects.zaps.will")

local flame = {}

function flame.mark(ctx, source, target)
    if ctx:has(target, component.INNER_FLAME) then
        return false
    end

    ctx:add(target, component.INNER_FLAME, {
        source = source,
        remaining_aut = (25 + ctx:random("spell", 11)) * 10,
    })

    return true
end

local function profile(definition)
    -- mon-explode.cc:_setup_inner_flame_explosion.
    if definition.size_id == "SIZE_GIANT" then
        return 2, 25
    elseif definition.size_id == "SIZE_TINY" then
        return 1, 15
    end

    return 1, 20
end

function flame.resolve(ctx, player, intent, spell, power)
    local origin = ctx:get(player, component.POSITION)
    local x = origin.x + intent.dx
    local y = origin.y + intent.dy
    local reach = range.for_spell(ctx, player, spell)
    local distance = math.max(math.abs(intent.dx), math.abs(intent.dy))

    if distance > reach or not ctx:visible(origin.level_id,
        origin.x, origin.y, reach, x, y) then
        return
    end

    local target = ctx:actor_at(origin.level_id, x, y)

    if not target or target == player then
        return
    end

    local actor = ctx:get(target, component.ACTOR)
    local health = ctx:get(target, component.HEALTH)

    if not actor or not health then
        error("Inner Flame struck an actor without health")
    end

    local definition = catalog.get("monsters", actor.kind_id)

    if health.current <= 0 or ctx:has(target, component.INNER_FLAME) or
        will.resists(ctx, definition, math.min(power, 100) * 3,
            target) then
        return
    end

    -- mon-ench.cc:ENCH_INNER_FLAME lasts random_range(25,35) turns.
    flame.mark(ctx, player, target)
    ctx:emit("spell", "The " .. definition.name ..
        " is filled with an inner flame.")
end

function flame.tick(ctx, target)
    local state = ctx:get(target, component.INNER_FLAME)

    if not state then
        return
    end

    state.remaining_aut = state.remaining_aut - 10

    if state.remaining_aut <= 0 then
        ctx:remove(target, component.INNER_FLAME)
        return
    end

    ctx:set(target, component.INNER_FLAME, state)
end

function flame.on_death(ctx, monster, definition, position)
    local mark = ctx:get(monster, component.INNER_FLAME)

    if not mark then
        return false
    end

    -- fineff.cc:fire places fire clouds before the explosion. Adjacent
    -- squares with an existing cloud or solid terrain are skipped.
    for dy = -1, 1 do
        for dx = -1, 1 do
            if (dx ~= 0 or dy ~= 0) and
                ctx:random("spell", 5) ~= 0 then
                cloud.place(ctx, zap_ids.cloud.FIRE, mark.source,
                    position.level_id, position.x + dx, position.y + dy,
                    10 + ctx:random("spell", 10))
            end
        end
    end

    local radius, sides = profile(definition)
    local spec = {
        name = "fiery explosion",
        element = "MR_RES_FIRE",
        damage = {
            kind = "fixed",
            count = 3,
            sides = sides,
        },
    }

    ctx:emit("spell", "The " .. definition.name .. " explodes!")

    for _, cell in ipairs(explosion.cells(ctx, position.level_id,
        position.x, position.y, radius)) do
        local victim = ctx:actor_at(position.level_id, cell.x, cell.y)

        if victim then
            explosive.hurt(ctx, mark.source, victim, spec, 0)
        end
    end

    return true
end

function flame.update(ctx, entity)
    if ctx:has(entity, component.AI) then
        flame.tick(ctx, entity)
    end
end

death_hooks.add(component.INNER_FLAME, flame.on_death)
registry.add(spells.SPELL_INNER_FLAME, flame)

register.system({
    id = "zap.inner_flame.tick",
    scope = "active",
    query = {},
    before = { "monster.decision" },
    update = flame.update,
})

return flame
