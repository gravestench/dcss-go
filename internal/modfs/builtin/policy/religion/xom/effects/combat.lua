-- Xom's direct damage shares the player's ordinary resistance and health
-- owners. Event-specific target rules remain here so Torment cannot
-- accidentally become an area spell merely because one exists elsewhere.
local channels = require("constants.message_channels")
local cleaving = require("policy.religion.xom.cleaving")
local component = require("constants.component")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local confusion = require("policy.religion.xom.confusion")
local events = require("ids.xom_events")
local explosive = require("policy.magic.effects.zaps.explosive")
local flags = require("constants.monster_flags")
local groups = require("constants.monster_groups")
local health_owner = require("policy.combat.player_health")
local resistance = require("policy.combat.player_resistance")
local resistance_ids = require("constants.resistance_ids")
local status = require("policy.combat.monster_hexes.status")
local streams = require("constants.rng_streams")
local xom_state = require("policy.religion.xom.state")

local effect = {}

-- The source calls torment_player, affecting only the player. The shared
-- resistance formula includes form, mutation, and negative-energy effects;
-- its nonlethal result is then applied through the normal health owner.
local function torment(ctx, player)
    local health = ctx:get(player, component.HEALTH)

    if not health then
        return nil
    end

    local loss = resistance.torment_loss(ctx, player, health.current)

    if loss > 0 then
        ctx:emit(channels.RELIGION, "Xom torments you!")
        health_owner.damage(ctx, player, loss, false, nil)
    end

    return loss
end

-- Conjurations and tentacle segments are not targets for Xom's fireball
-- theatre, even though they can appear in the ordinary nearby actor query.
local function destruction_target(ctx, monster)
    local actor = ctx:get(monster, component.ACTOR)
    local definition = actor and catalog.get(categories.MONSTERS,
        actor.kind_id)

    if not definition or groups.tentacles[definition.id] then
        return false
    end

    for _, flag in ipairs(definition.flags or {}) do
        if flag == flags.PROJECTILE then
            return false
        end
    end

    return true
end

-- Selection does not spend an event on fake fireballs without any valid
-- body to illuminate, or on real fireballs with only adjacent allies.
function effect.has_destruction_target(ctx, player, real)
    local origin = ctx:get(player, component.POSITION)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local nasty = xom_state.feels_nasty(worship)

    if not origin then
        return false
    end

    for _, monster in ipairs(confusion.nearby(ctx, player)) do
        if destruction_target(ctx, monster) then
            if not real then
                return true
            end

            local position = ctx:get(monster, component.POSITION)
            local distance = math.max(
                math.abs(position.x - origin.x),
                math.abs(position.y - origin.y))

            if distance > 1 and
                (confusion.hostile(ctx, monster) or nasty) then
                return true
            end
        end
    end

    return false
end

-- Fake destruction uses the ordinary saved backlight status. A real act
-- blasts around each eligible nonadjacent foe with the source's 2d(4+s/10)
-- fire dice. Every candidate pays its own one-in-three skip roll first.
local function destruction(ctx, player, severity, stream, real)
    local origin = ctx:get(player, component.POSITION)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local nasty = xom_state.feels_nasty(worship)
    local changed = 0

    if not origin then
        return 0
    end

    for _, monster in ipairs(confusion.nearby(ctx, player)) do
        if destruction_target(ctx, monster) and
            ctx:random(stream, 3) ~= 0 then
            local position = ctx:get(monster, component.POSITION)
            local distance = math.max(
                math.abs(position.x - origin.x),
                math.abs(position.y - origin.y))

            if not real then
                status.corona(ctx, monster, 100)
                changed = changed + 1
            elseif distance > 1 and
                (confusion.hostile(ctx, monster) or nasty) then
                local spec = {
                    name = "fireball",
                    element = resistance_ids.FIRE,
                    uncredited = true,
                    damage = {
                        kind = "fixed",
                        count = 2,
                        sides = 4 + math.floor(severity / 10),
                    },
                }

                explosive.blast(ctx, player, origin.level_id,
                    position.x, position.y, 1, spec, 0, stream)
                changed = changed + 1
            end
        end
    end

    if changed > 0 then
        ctx:emit(channels.RELIGION,
            real and "Xom hurls fireballs at your foes!" or
            "Xom hurls illusory fireballs at your foes!")
    end

    return changed
end

-- The source bolt explodes at the player's square with a deliberate hole
-- there. Other reachable cells take independent 3d30 electric strikes.
local function lightning(ctx, player, stream)
    local position = ctx:get(player, component.POSITION)

    if not position then
        return 0
    end

    local spec = {
        name = "blast of lightning",
        element = resistance_ids.ELECTRICITY,
        uncredited = true,
        damage = {
            kind = "fixed",
            count = 3,
            sides = 30,
        },
    }

    ctx:emit(channels.RELIGION,
        "The area is suffused with divine lightning!")

    return explosive.blast(ctx, player, position.level_id,
        position.x, position.y, 2, spec, 0, stream, true)
end

-- Keep each direct-damage event explicit so a registered Xom ID cannot
-- succeed with only a message and no live combat consequence.
function effect.apply(ctx, player, event_id, severity, request)
    if event_id == events.BAD_TORMENT then
        return torment(ctx, player)
    end

    local stream = request and request.stream or streams.RELIGION

    if event_id == events.GOOD_FAKE_DESTRUCTION then
        return destruction(ctx, player, severity, stream, false)
    end

    if event_id == events.GOOD_DESTRUCTION then
        return destruction(ctx, player, severity, stream, true)
    end

    if event_id == events.GOOD_CLEAVING then
        local state = cleaving.start(ctx, player, severity, stream)

        ctx:emit(channels.RELIGION,
            "Xom makes your attacks cleave through nearby foes!")

        return state
    end

    if event_id == events.GOOD_LIGHTNING then
        return lightning(ctx, player, stream)
    end

    error("combat effect received another Xom event")
end

return effect
