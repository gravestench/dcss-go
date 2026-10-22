-- A feeding slime with the source M_SPLITS trait can turn one live actor
-- into two independently scheduled actors. The new body has no copied
-- vault-origin claim: it was born from the parent, not placed by that map.
local attitudes = require("constants.attitude")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local factory = require("policy.population.factory")
local flags = require("constants.monster_flags")
local growth = require("policy.religion.jiyva.growth")
local habitat = require("policy.combat.monster_habitat")
local senses = require("policy.character.senses")
local silence = require("policy.world.silence")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")

local splitting = {}

-- Source M_SPLITS belongs to the catalog species. A modded species can
-- carry it without a new Jiyva-specific case in the engine.
local function can_split(definition)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == flags.SPLITS then
            return true
        end
    end

    return false
end

-- One reservoir draw per legal adjacent cell gives every location equal
-- probability without constructing a temporary list of map coordinates.
local function child_site(ctx, parent, position)
    local count = 0
    local chosen

    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                local x = position.x + dx
                local y = position.y + dy

                if not ctx:actor_at(position.level_id, x, y) and
                    habitat.at(ctx, parent, position.level_id, x, y) then
                    count = count + 1

                    if ctx:random(streams.RELIGION, count) == 0 then
                        chosen = {
                            x = x,
                            y = y,
                        }
                    end
                end
            end
        end
    end

    return chosen
end

-- Name a visible split; otherwise the source allows a sound only when
-- neither the player nor the split location lies inside a silence field.
local function announce(ctx, parent, position, child_site, definition)
    if senses.player_sees_actor(ctx, parent) then
        ctx:emit(channels.MONSTER,
            "The " .. definition.name .. " splits in two!")

        return
    end

    local player = ctx:player()
    local player_pos = ctx:get(player, component.POSITION)

    local parent_heard = not silence.at(ctx, position.level_id,
        position.x, position.y)
    local child_heard = not silence.at(ctx, position.level_id,
        child_site.x, child_site.y)

    if player_pos and player_pos.level_id == position.level_id and
        not silence.at(ctx, player_pos.level_id,
            player_pos.x, player_pos.y) and
        (parent_heard or child_heard) then
        ctx:emit(channels.SOUND, "You hear a squelching noise.")
    end
end

-- Source division halves maximum HP, clamps current HP, then copies that
-- resulting body. Its child starts at 70–74 energy points so it cannot
-- immediately take an unrelated full action on the same player turn.
function splitting.try(ctx, parent, definition)
    local health = ctx:get(parent, component.HEALTH)
    local threshold = math.max((definition.hd or 0) * 8, 50)

    if not can_split(definition) or not health or
        health.current < threshold then
        return false
    end

    local position = ctx:get(parent, component.POSITION)
    local site = position and child_site(ctx, parent, position)

    if not site then
        return false
    end

    health.max = math.floor(health.max / 2)
    health.current = math.min(health.current, health.max)
    ctx:set(parent, component.HEALTH, health)

    local actor = ctx:get(parent, component.ACTOR)
    local source = ctx:get(parent, component.VAULT_ACTOR_OVERRIDES)
    local child = factory.spawn(ctx, actor.kind_id, position.level_id,
        site.x, site.y, {
            hp = health.current,
            attitude = targets.real_attitude(ctx, parent) or
                attitudes.HOSTILE,
            god_id = source and source.god_id or "",
        })
    local energy = ctx:get(child, component.MONSTER_ENERGY)

    energy.points = 70 + ctx:random(streams.RELIGION, 5)
    ctx:set(child, component.MONSTER_ENERGY, energy)

    local lineage = ctx:get(parent, component.JIYVA_SLIME)

    if lineage then
        ctx:add(child, component.JIYVA_SLIME, lineage)
    end

    growth.split(ctx, parent, child)

    announce(ctx, parent, position, site, definition)

    return true
end

return splitting
