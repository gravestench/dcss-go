-- Theory of operation: DCSS monster specs can name one mutant beast tier
-- and several hyphen-separated facets before "mutant beast". The catalog
-- ID stays MONS_MUTANT_BEAST; the authored form is separate per-actor
-- data for its hit dice, attacks, movement, and eventual corpse identity.
local choice = require("policy.generation.vaults.specs.choice")
local facet_ids = require("policy.monsters.mutant_beast.facets")
local streams = require("constants.rng_streams")
local component = require("constants.component")
local monsters = require("ids.monsters")

local form = {}

local tiers = {
    larval = 3,
    juvenile = 9,
    mature = 15,
    elder = 21,
    primal = 27,
}

local tier_order = {
    "larval",
    "juvenile",
    "mature",
    "elder",
    "primal",
}

local facets = {
    [facet_ids.STING] = true,
    [facet_ids.BAT] = true,
    [facet_ids.FIRE] = true,
    [facet_ids.WEIRD] = true,
    [facet_ids.SHOCK] = true,
    [facet_ids.OX] = true,
}

-- Source maps a base HD to the first tier whose threshold contains it.
-- This also gives natural catalog beasts their saved mature tier.
function form.for_hit_dice(hd)
    if not hd or hd < 1 or hd % 1 ~= 0 then
        error("invalid mutant beast HD " .. tostring(hd))
    end

    for rank, tier in ipairs(tier_order) do
        if hd <= tiers[tier] then
            return tier, rank
        end
    end

    error("mutant beast HD exceeds source tiers " .. tostring(hd))
end

-- Combat uses the source tier ordinal, not HD divided by a guessed step.
function form.rank(tier)
    for rank, name in ipairs(tier_order) do
        if name == tier then
            return rank
        end
    end

    error("unknown mutant beast tier " .. tostring(tier))
end

-- An unauthored beast shuffles the six source facets and saves two
-- distinct choices once. Future turns read the saved form, not this RNG.
local function roll_facets(ctx)
    local available = {}

    for _, facet in ipairs(facet_ids.ALL) do
        available[#available + 1] = facet
    end

    local chosen = {}

    for _ = 1, 2 do
        local index = ctx:random(streams.MONSTER_TRAITS,
            #available) + 1

        chosen[#chosen + 1] = table.remove(available, index)
    end

    return chosen
end

-- Source accepts a tier-only DES spelling. Fill its unspecified facets
-- exactly once at spawn while retaining the authored HD.
function form.complete(ctx, authored)
    if #authored.facets > 0 then
        return authored
    end

    return {
        tier = authored.tier,
        hit_dice = authored.hit_dice,
        facets = roll_facets(ctx),
    }
end

-- A wholly unauthored beast gets its catalog tier and two saved facets.
function form.roll(ctx, hd)
    local tier = form.for_hit_dice(hd)

    return {
        tier = tier,
        hit_dice = hd,
        facets = roll_facets(ctx),
    }
end

-- An explicit DES HD overrides the spelling's default tier. Source
-- initialization passes the resolved HD to the beast, so a facet-only
-- expression with hd:27 must be primal in combat as well as in HP.
function form.with_hit_dice(authored, hd)
    if not authored or not hd or authored.hit_dice == hd then
        return authored
    end

    return {
        tier = form.for_hit_dice(hd),
        hit_dice = hd,
        facets = authored.facets,
    }
end

-- All beast origins, including summons and ambient roster spawns, must
-- keep a well-formed saved body. The vault validator separately compares
-- authored facets with their source DES expression.
function form.validate_actor(ctx, entity, actor)
    local beast = ctx:get(entity, component.MONSTER_MUTANT_BEAST)
    local beast_kind = actor.kind_id == monsters.MONS_MUTANT_BEAST

    if beast_kind ~= (beast ~= nil) then
        error("monster " .. ctx:id(entity) ..
            " has inconsistent mutant beast body")
    end

    if not beast then
        return
    end

    local expected = form.for_hit_dice(beast.hit_dice)

    if beast.tier ~= expected or #beast.facets == 0 then
        error("monster " .. ctx:id(entity) ..
            " has invalid mutant beast form")
    end

    for _, facet in ipairs(beast.facets) do
        if not facets[facet] then
            error("monster " .. ctx:id(entity) ..
                " has unknown mutant beast facet")
        end
    end
end

-- Save validation permits only source facet IDs in a rolled pair. An
-- authored list can be longer or repeat a facet, matching DES syntax.
function form.valid_rolled_facets(chosen)
    return #chosen == 2 and chosen[1] ~= chosen[2] and
        facets[chosen[1]] and facets[chosen[2]]
end

-- Decode the source spelling once during spec parsing. A typo must fail
-- at its DES line rather than becoming a new monster catalog lookup.
function form.parse(name, site, expression)
    local prefix = name:match("^(.-) mutant beast$")

    if not prefix then
        return nil
    end

    local tier, facet_text = prefix:match("^(%S+)%s+(%S+)$")

    if not tier then
        if tiers[prefix] then
            tier = prefix
        else
            tier = "mature"
            facet_text = prefix
        end
    end

    if not tiers[tier] then
        choice.fail(site, expression, "invalid mutant beast tier")
    end

    local chosen = {}

    if facet_text then
        for facet in facet_text:gmatch("[^-]+") do
            if not facets[facet] then
                choice.fail(site, expression,
                    "invalid mutant beast facet " .. facet)
            end

            chosen[#chosen + 1] = facet
        end

        if #chosen == 0 then
            choice.fail(site, expression,
                "missing mutant beast facet")
        end
    end

    return {
        tier = tier,
        hit_dice = tiers[tier],
        facets = chosen,
    }
end

return form
