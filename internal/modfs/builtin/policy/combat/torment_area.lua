-- Torment is an area effect centered on its source, whether a scroll reader
-- or a monster casting Symbol of Torment. Source: spl-goditem.cc:torment.
-- The area is ordinary LOS_NO_TRANS geometry; each victim's own resistance
-- policy decides the HP loss, which cannot kill by itself.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local damage = require("policy.magic.damage")
local monster_torment = require("policy.combat.torment")
local player_health = require("policy.combat.player_health")
local player_resistance = require("policy.combat.player_resistance")
local senses = require("policy.character.senses")
local targets = require("policy.ai.targets")
local spell_range = require("constants.spell_range")

local area = {}
local SIGHT_RADIUS = spell_range.LOS_RADIUS

-- Check source LOS_NO_TRANS before consulting victim resistance. The fixed
-- radius belongs to Torment itself, not to the player's current sight.
local function in_area(ctx, origin, position)
    if position.level_id ~= origin.level_id then
        return false
    end

    local distance = math.max(math.abs(position.x - origin.x),
        math.abs(position.y - origin.y))

    return distance <= SIGHT_RADIUS and
        ctx:visible_no_trans(origin.level_id, origin.x, origin.y,
            SIGHT_RADIUS, position.x, position.y)
end

-- Ask each actor's existing owner for its Torment loss. A monster's kind
-- definition supplies innate resistance, while both actors' live state
-- supplies equipment and other current protections.
local function loss(ctx, entity, health, source)
    if ctx:has(entity, component.PLAYER) then
        return player_resistance.torment_loss(ctx, entity,
            health.current, source), nil
    end

    local actor = ctx:get(entity, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    return monster_torment.monster_loss(ctx, entity, definition,
        health.current),
        definition
end

-- Source _torment_vulnerable checks immunity, not the current HP loss.
-- A one-HP enemy remains a valid prospect even though this nonlethal effect
-- will leave it unharmed on that particular action.
local function vulnerable(ctx, entity)
    if ctx:has(entity, component.PLAYER) then
        return not player_resistance.torment(ctx, entity)
    end

    local actor = ctx:get(entity, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    return monster_torment.susceptible(definition)
end

-- Example: area.worthwhile(ctx, caster) tells Symbol of Torment whether its
-- current radius contains a vulnerable enemy, without rolling or changing
-- anything. An ally declines when the player would be hurt by its symbol.
function area.worthwhile(ctx, caster)
    local origin = ctx:get(caster, component.POSITION)

    if not origin then
        return false
    end

    local enemy = false

    for _, entity in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        local position = ctx:get(entity, component.POSITION)
        local health = ctx:get(entity, component.HEALTH)

        if health.current > 0 and in_area(ctx, origin, position) then
            if vulnerable(ctx, entity) then
                if ctx:has(entity, component.PLAYER) and
                    targets.allied(ctx, caster) then
                    return false
                end

                if targets.enemy(ctx, caster, entity) then
                    enemy = true
                end
            end
        end
    end

    return enemy
end

-- Example: area.apply(ctx, reader, channels.READ) implements a Torment scroll;
-- area.apply(ctx, monster, channels.SPELL) implements Symbol of Torment.
-- Scan live entities once, then use each health owner to apply nonlethal HP
-- loss. Messages name only actors the player can actually perceive.
function area.apply(ctx, caster, channel, death_position, source)
    local origin = death_position or ctx:get(caster, component.POSITION)

    if not origin then
        error("Torment source has no position")
    end

    for _, entity in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        local position = ctx:get(entity, component.POSITION)
        local health = ctx:get(entity, component.HEALTH)

        if health.current > 0 and in_area(ctx, origin, position) then
            local amount, definition = loss(ctx, entity, health,
                source)

            if ctx:has(entity, component.PLAYER) then
                if amount > 0 then
                    ctx:emit(channel, "Your body is wracked with pain!")
                    player_health.damage(ctx, entity, amount, false, caster)
                else
                    ctx:emit(channel, "You feel a surge of unholy energy.")
                end
            elseif amount > 0 then
                -- Perception must be sampled before a lethal hit removes
                -- the actor's location or visibility state.
                local actor_visible = senses.player_sees_actor(ctx, entity)
                local cell_visible = senses.player_sees_cell(ctx, position)

                damage.apply(ctx, entity, amount, caster)

                if actor_visible then
                    ctx:emit(channel, "The " .. definition.name ..
                        " convulses!")
                elseif cell_visible then
                    ctx:emit(channel,
                        "Something is bathed in an unholy light!")
                end
            end
        end
    end
end

return area
