-- Source: crawl-ref/source/acquire.cc:_adjust_brand. A scroll prefers
-- stronger weapon brands after the shared generator has made the item.
local ammunition = require("ids.ammunition")
local brands = require("constants.weapon_brands")
local catalog = require("policy.catalog")
local classes = require("ids.object_classes")
local component = require("constants.component")
local selection = require("policy.scrolls.acquirement.selection")
local skills = require("ids.skills")
local source = require("policy.item_generation.source_roll")
local weapon_brands = require("policy.item_generation.weapon_brands")
local quality = require("constants.vault_item_quality")

local post_roll = {}

local high_quality = {
    [brands.ELECTROCUTION] = 3,
    [brands.DISTORTION] = 3,
    [brands.HOLY_WRATH] = 3,
    [brands.REAPING] = 3,
    [brands.PENETRATION] = 4,
    [brands.CHAOS] = 2,
}

-- Rank brands by source acquirement quality, with ranged Speed receiving a different score.
local function brand_quality(ctx, brand, ranged)
    if brand == "" or brand == brands.NORMAL then
        return 0
    elseif brand == brands.SPEED then
        return ranged and 3 or 5
    elseif brand == brands.PAIN then
        return math.floor(selection.skill(ctx, skills.SK_NECROMANCY) / 2)
    elseif brand == brands.VORPAL then
        return ranged and 5 or 1
    end

    return high_quality[brand] or 1
end

-- Example: A non-artefact weapon with a weak brand can reroll toward a stronger acquirement brand.
-- Leave artefacts untouched; improve ordinary weapon brands only after item generation has rolled them.
function post_roll.adjust(ctx, rolled, depth)
    if rolled.components[component.ITEM_ARTEFACT] then
        return
    end

    local kind = catalog.get("items", rolled.kind_id)

    if kind.class ~= classes.OBJ_WEAPONS then
        return
    end

    local ranged = kind.weapon.ammo_id ~= ammunition.NONE

    for _ = 1, 40 do
        if brand_quality(ctx, rolled.ego, ranged) >=
            source.between(ctx, 0, 5) then
            break
        end

        rolled.ego = weapon_brands.roll(ctx, kind, {
            depth = depth,
            quality = quality.GOOD,
        })
    end
end

return post_roll
