-- A monster's threat band is relative to the player's current experience
-- threshold. Okawaru, Uskayaw, and Cowardice must agree on this source rule.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local death = require("policy.death")
local experience_limit = require("policy.character.experience_limit")
local bands = require("constants.monster_threat")
local monsters = require("ids.monsters")

local threat = {}

-- Convert source monster XP to the four public threat bands. Band two is
-- MTHRT_TOUGH, the minimum opponent Okawaru accepts for a Duel.
function threat.band(ctx, player, experience)
    local progress = ctx:get(player, component.PROGRESSION)
    local identity = ctx:get(player, component.PLAYER)

    if not progress or not identity then
        error("monster threat requires player level and species")
    end

    local needed = experience_limit.needed(ctx, player,
        progress.level)
    local tension = math.floor(experience /
        (1 + math.sqrt(needed / 30)))

    if tension <= 0 then
        return bands.TRIVIAL
    elseif tension <= bands.EASY_TENSION_MAX then
        return bands.EASY
    elseif tension <= bands.TOUGH_TENSION_MAX then
        return bands.TOUGH
    end

    return bands.NASTY
end

-- Source mons_threat_level calls exper_value with real=false. Ordinary
-- monsters therefore use their species' maximum HP rather than a lucky
-- or unlucky individual roll. Ghosts and player illusions are exceptions.
function threat.monster(ctx, player, monster, definition)
    local health = ctx:get(monster, component.HEALTH)

    if not health then
        error("monster threat requires live health")
    end

    -- Source mons_threat_level treats sacrificial wretches as trivial even
    -- when their underlying species would normally reward a dangerous kill.
    if ctx:has(monster, component.RELIGION_KIKU_WRETCH) then
        return bands.TRIVIAL
    end

    local max_hp = math.floor(definition.average_hp_10x * 133 / 1000)

    if definition.id == monsters.MONS_PLAYER_GHOST or
        definition.id == monsters.MONS_PLAYER_ILLUSION then
        max_hp = health.max
    end

    return threat.band(ctx, player,
        death.experience(definition, max_hp, true))
end

return threat
