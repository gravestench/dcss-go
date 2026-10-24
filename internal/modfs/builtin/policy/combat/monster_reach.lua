-- Natural reaching attacks are read from the actor's current melee profile.
-- AI and combat share this check so a projected facet cannot offer an
-- attack that the later intent resolver treats as an ordinary move.
local catalog = require("policy.catalog")
local component = require("constants.component")
local flavours = require("constants.attack_flavours")
local terrain = require("constants.terrain")
local profile = require("policy.combat.monster_profile")

local reach = {}

local reaching_flavours = {
    [flavours.REACH] = true,
    [flavours.REACH_STING] = true,
}

-- A distant melee round still visits every source slot, but only a
-- reaching contact can land at distance two. This keeps the first plain
-- hit of a Sting beast from striking across the intervening cell.
function reach.contact(attack)
    return attack.damage > 0 and
        reaching_flavours[attack.flavour_id] == true
end

-- A natural contact grants reach if it has real damage. Reading the
-- projected profile includes saved mutant beast facets and generated forms.
local function has_natural_reach(ctx, actor)
    local body = ctx:get(actor, component.ACTOR)

    if not body then
        return false
    end

    local definition = profile.definition(ctx, actor,
        catalog.get("monsters", body.kind_id))

    for _, attack in ipairs(definition.attacks or {}) do
        if reach.contact(attack) then
            return true
        end
    end

    return false
end

-- Source reach checks both possible middle cells. On diagonals, either
-- open route is enough; on a straight line they are the same cell. The
-- grid owns solidity and opacity, while this Lua rule owns the attack.
local function open_middle(ctx, level_id, x, y)
    return ctx:cell(level_id, x, y) ~= nil and
        not ctx:solid(level_id, x, y) and
        not ctx:opaque(level_id, x, y) and
        ctx:cell(level_id, x, y) ~= terrain.DNGN_GRATE
end

-- A reaching monster needs a current foe exactly two cells away on the
-- same level, with at least one clear middle path.
function reach.can(ctx, actor, origin, target)
    if not origin or not target or
        origin.level_id ~= target.level_id or
        not has_natural_reach(ctx, actor) then
        return false
    end

    local dx = target.x - origin.x
    local dy = target.y - origin.y

    if math.max(math.abs(dx), math.abs(dy)) ~= 2 then
        return false
    end

    local half_x = math.floor(math.abs(dx) / 2) *
        (dx < 0 and -1 or 1)
    local half_y = math.floor(math.abs(dy) / 2) *
        (dy < 0 and -1 or 1)
    local level_id = origin.level_id

    return open_middle(ctx, level_id,
        origin.x + half_x, origin.y + half_y) or
        open_middle(ctx, level_id,
            target.x - half_x, target.y - half_y)
end

return reach
