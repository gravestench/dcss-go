local streams = require("constants.rng_streams")
local catalog = require("policy.catalog")
local component = require("constants.component")
local ids = require("ids.items")
local skills = require("ids.skills")
local source = require("policy.item_generation.source_roll")
local shapes = require("constants.book_rarity_shape")
local random_books = require("policy.item_generation.random_books")

local books = {}

-- Source: crawl-ref/source/skill-type.h and skills.cc:is_removed_skill.
local mundane_skills = {
    skills.SK_FIGHTING,
    skills.SK_SHORT_BLADES,
    skills.SK_LONG_BLADES,
    skills.SK_AXES,
    skills.SK_MACES_FLAILS,
    skills.SK_POLEARMS,
    skills.SK_STAVES,
    skills.SK_RANGED_WEAPONS,
    skills.SK_THROWING,
    skills.SK_ARMOUR,
    skills.SK_DODGING,
    skills.SK_STEALTH,
    skills.SK_SHIELDS,
    skills.SK_UNARMED_COMBAT,
}

local magic_skills = {
    skills.SK_SPELLCASTING,
    skills.SK_CONJURATIONS,
    skills.SK_HEXES,
    skills.SK_SUMMONINGS,
    skills.SK_NECROMANCY,
    skills.SK_TRANSLOCATIONS,
    skills.SK_TRANSMUTATIONS,
    skills.SK_FIRE_MAGIC,
    skills.SK_ICE_MAGIC,
    skills.SK_AIR_MAGIC,
    skills.SK_EARTH_MAGIC,
    skills.SK_POISON_MAGIC,
    skills.SK_INVOCATIONS,
    skills.SK_EVOCATIONS,
}

-- Source: crawl-ref/source/spl-book.cc:1137-1161.
local level_ranges = {
    {
        first = 0,
        last = 35,
        rarity = 100,
        shape = shapes.FLAT,
        level = 1,
    },
    {
        first = 0,
        last = 35,
        rarity = 100,
        shape = shapes.FLAT,
        level = 2,
    },
    {
        first = 0,
        last = 35,
        rarity = 100,
        shape = shapes.FLAT,
        level = 3,
    },
    {
        first = 4,
        last = 8,
        rarity = 100,
        shape = shapes.RISE,
        level = 4,
    },
    {
        first = 9,
        last = 35,
        rarity = 100,
        shape = shapes.FLAT,
        level = 4,
    },
    {
        first = 6,
        last = 10,
        rarity = 100,
        shape = shapes.RISE,
        level = 5,
    },
    {
        first = 11,
        last = 35,
        rarity = 80,
        shape = shapes.FLAT,
        level = 5,
    },
    {
        first = 10,
        last = 14,
        rarity = 100,
        shape = shapes.RISE,
        level = 6,
    },
    {
        first = 15,
        last = 35,
        rarity = 100,
        shape = shapes.FLAT,
        level = 6,
    },
    {
        first = 14,
        last = 22,
        rarity = 100,
        shape = shapes.RISE,
        level = 7,
    },
    {
        first = 23,
        last = 35,
        rarity = 100,
        shape = shapes.FLAT,
        level = 7,
    },
    {
        first = 18,
        last = 26,
        rarity = 100,
        shape = shapes.RISE,
        level = 8,
    },
    {
        first = 27,
        last = 35,
        rarity = 100,
        shape = shapes.FLAT,
        level = 8,
    },
    {
        first = 22,
        last = 30,
        rarity = 100,
        shape = shapes.RISE,
        level = 9,
    },
    {
        first = 31,
        last = 35,
        rarity = 100,
        shape = shapes.FLAT,
        level = 9,
    },
}

local function spell_weight(level, depth)
    local total = 0
    local selected = 0

    for _, range in ipairs(level_ranges) do
        if depth >= range.first and depth <= range.last then
            local rarity = range.rarity * 2520

            if range.shape == shapes.RISE then
                rarity = math.floor(rarity * (depth - range.first + 1) /
                    (range.last - range.first + 1))
            end

            total = total + rarity

            if range.level == level then
                selected = rarity
            end
        end
    end

    if total == 0 then
        return 0
    end

    return math.floor(selected * 1000 / total)
end

function books.weight(definition, depth)
    local spells = definition.generation.spells or {}

    if #spells == 0 then
        return 0
    end

    local total = 0

    for _, spell_id in ipairs(spells) do
        local spell = catalog.get("spells", spell_id)

        total = total + spell_weight(spell.level, math.min(depth, 35)) + 50
    end

    return math.floor(total / #spells)
end

function books.roll(ctx, definition, request, result)
    if definition.id ~= ids.BOOK_MANUAL then
        random_books.roll(ctx, definition, request, result)
        return
    end

    -- Source: crawl-ref/source/makeitem.cc:1400-1440. Removed skill IDs
    -- are omitted, yielding the same final distribution as source rerolls.
    local skill_id = request.manual_skill_id

    if not skill_id then
        local candidates = mundane_skills

        if source.chance(ctx, 1, 4) then
            candidates = magic_skills
        end

        local index = ctx:random(streams.ITEM_GENERATION, #candidates) + 1

        skill_id = candidates[index]
    end

    result.components[component.ITEM_MANUAL] = {
        skill_id = skill_id,
        points = source.between(ctx, 2000, 3000),
    }
    result.components[component.ITEM_IDENTIFICATION] = {
        known_type = true,
        known_pluses = true,
        known_properties = true,
    }
end

return books
