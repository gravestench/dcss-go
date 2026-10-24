-- The Royal Jelly's death is permanent player history. Source Jiyva only
-- vanishes after the player leaves his worship and pays off his penance;
-- an opened Slime seal alone does not prove this, since six-star worship
-- can open the same walls while the Royal Jelly remains alive.
local component = require("constants.component")
local death_hooks = require("policy.combat.death_hooks")
local gods = require("constants.gods")
local monsters = require("ids.monsters")

local life = {}

-- Current worship and unpaid penance keep Jiyva available after the
-- Royal Jelly dies. This one predicate serves altar eligibility and the
-- Nemelex Wrath card's redraw rule.
function life.dead(worship)
    if not worship or not worship.royal_jelly_dead then
        return false
    end

    if worship.god_id == gods.JIYVA then
        return false
    end

    return ((worship.penance or {})[gods.JIYVA] or 0) == 0
end

-- The source marks only an unsummoned Royal Jelly that dies in its
-- actual form. The authored Slime:5 seal has a separate death hook so
-- neither event is inferred from the other.
function life.on_death(ctx, monster)
    local actor = ctx:get(monster, component.ACTOR)

    if not actor or actor.kind_id ~= monsters.MONS_ROYAL_JELLY or
        ctx:has(monster, component.SUMMON) then
        return false
    end

    local player = ctx:player()
    local worship = player and ctx:get(player,
        component.RELIGION_WORSHIP)

    if worship and not worship.royal_jelly_dead then
        worship.royal_jelly_dead = true
        ctx:set(player, component.RELIGION_WORSHIP, worship)
    end

    return false
end

death_hooks.add("jiyva.royal_jelly", life.on_death)

return life
