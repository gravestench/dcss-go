-- Duel selects one worthy visible enemy before it spends a turn. The
-- opponent's live ECS identity, not the map glyph, is the challenge target.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local flags = require("constants.monster_flags")
local groups = require("constants.monster_groups")
local habitats = require("constants.monster_habitats")
local threat = require("policy.combat.monster_threat")
local threat_bands = require("constants.monster_threat")
local targets = require("policy.ai.targets")
local vision = require("policy.character.vision")

local eligibility = {}

-- Catalog flags are lists so a mod can extend a species without changing
-- a fixed flag bitset in the engine.
local function has_flag(definition, wanted)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- The source excludes stationary no-threat species, except tentacles and
-- test bodies. Tentacles are excluded separately from Duel itself.
local function firewood(definition)
    return has_flag(definition, flags.STATIONARY) and
        has_flag(definition, flags.NO_THREAT) and
        not groups.tentacles[definition.id] and
        not groups.test_monsters[definition.id]
end

-- Resolve a target through the current player's line of sight. All free
-- rejections happen before the generic ability command creates an intent.
function eligibility.target(ctx, player, dx, dy)
    local origin = ctx:get(player, component.POSITION)

    if not origin then
        error("Duel requires a positioned player")
    end

    local radius = vision.radius(ctx, player)
    local x = origin.x + dx
    local y = origin.y + dy
    local distance = math.max(math.abs(dx), math.abs(dy))

    if distance == 0 or distance > radius or
        not ctx:visible(origin.level_id, origin.x, origin.y,
            radius, x, y) then
        return nil, "You can see no monster there to duel!"
    end

    local monster = ctx:actor_at(origin.level_id, x, y)
    local actor = monster and ctx:get(monster, component.ACTOR)
    local health = monster and ctx:get(monster, component.HEALTH)

    if not actor or not health or health.current <= 0 then
        return nil, "You can see no monster there to duel!"
    end

    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    if firewood(definition) or
        has_flag(definition, flags.CONJURED) or
        groups.tentacles[actor.kind_id] or
        definition.habitat_id == habitats.LAVA or
        definition.habitat_id == habitats.WATER or
        not targets.enemy(ctx, player, monster) then
        return nil, "You cannot duel that!"
    end

    if threat.monster(ctx, player, monster, definition) <
        threat_bands.TOUGH then
        return nil, "The " .. definition.name ..
            " is not worthy to be dueled!"
    end

    -- A mirror is deliberately checked before ordinary summon rejection.
    -- Identifying an otherwise eligible illusion costs the player a turn.
    if ctx:has(monster, component.SUMMON_MIRROR) or
        ctx:has(monster, component.PLAYER_ILLUSION) then
        return monster, nil, true
    end

    if ctx:has(monster, component.SUMMON) then
        return nil, "You cannot duel that!"
    end

    return monster, nil, false
end

return eligibility
