local component = require("constants.component")
local spells = require("ids.spells")
local monsters = require("ids.monsters")
local catalog = require("policy.catalog")
local habitat = require("policy.combat.monster_habitat")
local net = require("policy.combat.net")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")
local trajectory = require("policy.combat.trajectory")
local will = require("policy.magic.effects.zaps.will")

local teleport = {}

local function has_flag(definition, wanted)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

local function no_tele(actor, definition)
    -- monster.cc:monster::no_tele excludes stationary and projectile actors,
    -- tentacle segments, stasis, and anchored monsters.
    return has_flag(definition, "M_STATIONARY") or
        has_flag(definition, "M_PROJECTILE") or
        has_flag(definition, "M_STASIS") or
        actor.kind_id == monsters.MONS_TENTACLE or
        actor.kind_id == monsters.MONS_TENTACLE_SEGMENT or
        actor.kind_id == monsters.MONS_ELDRITCH_TENTACLE or
        actor.kind_id == monsters.MONS_ELDRITCH_TENTACLE_SEGMENT
end

local function destination(ctx, target, position)
    local width, height = ctx:level_size(position.level_id)

    -- teleport.cc:_monster_random_space samples the whole level at most
    -- 1000 times, with occupancy and habitat filtering.
    for _ = 1, 1000 do
        local x = ctx:random("spell", width)
        local y = ctx:random("spell", height)

        if not ctx:actor_at(position.level_id, x, y) and
            habitat.at(ctx, target, position.level_id, x, y) then
            return x, y
        end
    end

    return nil, nil
end

teleport.no_tele = no_tele
teleport.random_destination = destination

function teleport.tick(ctx, target)
    local state = ctx:get(target, component.TELEPORT)

    if not state then
        return
    end

    state.remaining_aut = state.remaining_aut - 10

    if state.remaining_aut > 0 then
        ctx:set(target, component.TELEPORT, state)
        return
    end

    ctx:remove(target, component.TELEPORT)
    local position = ctx:get(target, component.POSITION)
    local actor = ctx:get(target, component.ACTOR)

    if not position or not actor then
        return
    end

    local definition = catalog.get("monsters", actor.kind_id)

    if no_tele(actor, definition) then
        return
    end

    local x, y = destination(ctx, target, position)

    if not x then
        ctx:emit("spell", "The " .. definition.name ..
            " flickers for a moment.")
        return
    end

    net.release(ctx, target)
    ctx:move_actor(target, position.level_id, x, y)
    ctx:emit("spell", "The " .. definition.name .. " disappears!")
end

function teleport.resolve(ctx, player, intent, spell, power)
    local origin = ctx:get(player, component.POSITION)
    local ray = trajectory.trace(ctx, origin.level_id, origin.x, origin.y,
        origin.x + intent.dx, origin.y + intent.dy,
        range.for_spell(ctx, player, spell))
    local contact = ray.contacts[1]

    if not contact then
        return
    end

    local target = contact.actor
    local actor = ctx:get(target, component.ACTOR)
    local health = ctx:get(target, component.HEALTH)

    if not actor or not health then
        error("Teleport Other struck an actor without health")
    end

    local definition = catalog.get("monsters", actor.kind_id)

    if health.current <= 0 or no_tele(actor, definition) then
        return
    end

    -- zap-data.h:ZAP_TELEPORT_OTHER has player enchant power 3*power/2.
    if will.resists(ctx, definition,
        math.floor(math.min(power, 100) * 3 / 2)) then
        ctx:emit("spell", "The " .. definition.name ..
            " resists teleportation.")
        return
    end

    if ctx:has(target, component.TELEPORT) then
        ctx:remove(target, component.TELEPORT)
        ctx:emit("spell", "The " .. definition.name ..
            " seems more stable.")
        return
    end

    ctx:add(target, component.TELEPORT, {
        remaining_aut = 20 + ctx:random("spell", 11),
    })
    ctx:emit("spell", "The " .. definition.name ..
        " looks slightly unstable.")
end

function teleport.update(ctx, entity)
    if ctx:has(entity, component.AI) then
        teleport.tick(ctx, entity)
    end
end

registry.add(spells.SPELL_TELEPORT_OTHER, teleport)

register.system({
    id = "zap.teleport.tick",
    scope = "active",
    query = {},
    before = { "monster.decision" },
    update = teleport.update,
})

return teleport
