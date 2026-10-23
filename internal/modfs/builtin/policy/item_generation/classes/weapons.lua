local streams = require("constants.rng_streams")
local catalog = require("policy.item_generation.catalog")
local classes = require("ids.object_classes")
local ids = require("ids.items")
local pool = require("policy.item_generation.pool")
local quality = require("constants.vault_item_quality")
local source = require("policy.item_generation.source_roll")
local weapon_brands = require("policy.item_generation.weapon_brands")

local policy = {}

-- Source: crawl-ref/source/makeitem.cc. These are the source's
-- special, middle, and early weapon lists, in source order.
local special = {
    ids.WPN_LAJATANG,
    ids.WPN_HAND_CROSSBOW,
    ids.WPN_TRIPLE_CROSSBOW,
    ids.WPN_DEMON_WHIP,
    ids.WPN_DEMON_BLADE,
    ids.WPN_DEMON_TRIDENT,
    ids.WPN_DOUBLE_SWORD,
    ids.WPN_EVENINGSTAR,
    ids.WPN_EXECUTIONERS_AXE,
    ids.WPN_QUICK_BLADE,
    ids.WPN_TRIPLE_SWORD,
}

local middle = {
    ids.WPN_QUARTERSTAFF,
    ids.WPN_FALCHION,
    ids.WPN_LONG_SWORD,
    ids.WPN_WAR_AXE,
    ids.WPN_TRIDENT,
    ids.WPN_FLAIL,
    ids.WPN_RAPIER,
}

local early = {
    ids.WPN_SLING,
    ids.WPN_SPEAR,
    ids.WPN_HAND_AXE,
    ids.WPN_MACE,
    ids.WPN_DAGGER,
    ids.WPN_DAGGER,
    ids.WPN_CLUB,
    ids.WPN_WHIP,
    ids.WPN_SHORT_SWORD,
}

-- Example: policy.eligible(nil, sword_kind, request) requires a random sword to have positive weight.
-- Let explicit weapon requests bypass commonness while random stock needs positive subtype weight.
function policy.eligible(_, definition, request)
    if definition.class ~= classes.OBJ_WEAPONS then
        return false
    end

    if request.kind_id == definition.id then
        return definition.generation.mode ~= "none"
    end

    return definition.generation.mode == "random" and
        policy.weight(nil, definition) > 0
end

-- Prefer source commonness over generic weight for ordinary weapon draws.
function policy.weight(_, definition)
    return definition.generation.commonness or
        definition.generation.weight or 0
end

-- Depth gates special weapon chances before the ordinary weighted pool.
function policy.pick(ctx, request)
    local depth = request.depth

    if source.chance(ctx, 1, 30) and
        source.chance(ctx, depth + 3, 100) then
        return source.one_of(ctx, special)
    end

    if source.chance(ctx, depth + 1, 27) then
        return pool.select(ctx, classes.OBJ_WEAPONS, request, policy)
    end

    if source.chance(ctx, depth + 1, depth + 11) then
        return source.one_of(ctx, middle)
    end

    return source.one_of(ctx, early)
end

-- Good quality grants enchantment even when no brand rolls; ordinary unbranded weapons can stay plain.
function policy.roll(ctx, definition, request, result)
    -- Source: crawl-ref/source/makeitem.cc.
    local forced_good = request.quality == quality.GIFT or
        request.quality == quality.GOOD or
        request.quality == quality.SUPERB
    local brand = weapon_brands.roll(ctx, definition, request)

    result.ego = brand

    if not forced_good and brand == "" then
        return
    end

    if forced_good and brand == "" then
        result.plus = 2 + ctx:random(streams.ITEM_GENERATION, 3)
    end

    local chance = forced_good and 200 or request.depth

    for _ = 1, 4 do
        result.plus = result.plus + ctx:random(streams.ITEM_GENERATION, 3)

        if ctx:random(streams.ITEM_GENERATION, 425) > 35 + chance then
            break
        end
    end

    if not forced_good and brand == "" and result.plus < 3 then
        result.plus = 0
    end
end

catalog.register(classes.OBJ_WEAPONS, policy)

return policy
