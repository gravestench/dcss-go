-- Source: player-reacts.cc:_current_horror_level and _update_cowardice.
local catalog = require("policy.catalog")
local component = require("constants.component")
local death = require("policy.death")
local flags = require("constants.monster_flags")
local formulas = require("policy.character.formulas")
local horror = require("policy.character.horror")
local levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local monsters = require("ids.monsters")
local monster_groups = require("constants.monster_groups")
local targets = require("policy.ai.targets")
local vision = require("policy.character.vision")

local threat_policy = {}

local function has_flag(definition, wanted)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

local function threat(ctx, player, monster, origin, sight, factor)
    if not targets.enemy(ctx, player, monster) then
        return 0
    end

    local position = ctx:get(monster, component.POSITION)
    local health = ctx:get(monster, component.HEALTH)
    local actor = ctx:get(monster, component.ACTOR)
    local distance = math.max(math.abs(position.x - origin.x),
        math.abs(position.y - origin.y))

    if health.current <= 0 or position.level_id ~= origin.level_id or
        distance > sight or not ctx:visible(origin.level_id,
            origin.x, origin.y, sight, position.x, position.y) then
        return 0
    end

    local definition = catalog.get("monsters", actor.kind_id)

    if has_flag(definition, flags.NO_THREAT) or
        monster_groups.tentacles[actor.kind_id] then
        return 0
    end

    local experience = death.experience(definition, health.max, true)
    local tension = math.floor(experience / (1 + factor))

    if tension > 32 then
        return 3
    end

    return tension > 5 and 1 or 0
end

function threat_policy.current(ctx, player)
    local origin = ctx:get(player, component.POSITION)
    local progress = ctx:get(player, component.PROGRESSION)
    local character = ctx:get(player, component.PLAYER)

    if not origin or not progress or not character then
        error("Cowardice requires player position and progression")
    end

    local species = catalog.get("species", character.species_id)
    local needed = formulas.experience_needed(progress.level, species.xp)
    local factor = math.sqrt(needed / 30)
    local sight = vision.radius(ctx, player)
    local total = 0

    for _, monster in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        total = total + threat(ctx, player, monster,
            origin, sight, factor)
    end

    return math.max(0, total - 1)
end

function threat_policy.update(ctx, player)
    local old = horror.penalty(ctx, player)
    local current = 0

    if levels.effective(ctx, player, mutations.MUT_COWARDICE) > 0 then
        current = threat_policy.current(ctx, player)
    end

    if current == 0 then
        if old > 0 then
            ctx:remove(player, component.HORROR)
        end

        return
    end

    local state = { penalty = current }

    if old > 0 then
        ctx:set(player, component.HORROR, state)
    else
        ctx:add(player, component.HORROR, state)
    end

    if current <= old then
        return
    end

    if current >= 5 then
        ctx:emit("status",
            "Monsters! Monsters everywhere! You have to get out of here!")
    elseif current >= 3 then
        ctx:emit("status", "You reel with horror at the sight of these foes!")
    else
        ctx:emit("status", "You feel a twist of horror at the sight of this foe.")
    end
end

return threat_policy
