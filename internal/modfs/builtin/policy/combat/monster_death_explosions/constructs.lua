-- Ball Lightning and Fulminant Prism share saved charge state. Their
-- ordinary actions and lethal deaths must call the same blast policies.
local component = require("constants.component")
local death_hooks = require("policy.combat.death_hooks")
local lightning = require("policy.magic.effects.summons.ball_lightning")
local monsters = require("ids.monsters")
local prism = require("policy.magic.effects.summons.fulminant_prism")

local constructs = {}

-- Inner Flame replaces an innate explosion in source Crawl. A dead
-- construct is already off the grid, so its final position is explicit.
function constructs.on_death(ctx, actor, definition, position)
    if definition.id ~= monsters.MONS_BALL_LIGHTNING and
        definition.id ~= monsters.MONS_FULMINANT_PRISM then
        return false
    end

    if ctx:has(actor, component.INNER_FLAME) then
        return true
    end

    if definition.id == monsters.MONS_BALL_LIGHTNING then
        lightning.explode(ctx, actor, position)
    else
        prism.explode(ctx, actor, position)
    end

    -- Even a zero-charge prism is a conjured construct, not a corpse.
    return true
end

death_hooks.add("monster.construct_explosion", constructs.on_death)

return constructs
