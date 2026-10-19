-- Source: crawl-ref/source/acquire.cc:_should_acquire_manual and
-- _do_book_acquirement. Spell-library exclusions can be added when the
-- spell-library domain is ported; current books use the effective catalog.
local catalog = require("policy.catalog")
local classes = require("ids.object_classes")
local ids = require("ids.items")
local book_weight = require("policy.item_generation.books")
local selection = require("policy.scrolls.acquirement.selection")
local skills = require("ids.skills")
local skill_order = require("data.skill_order")
local source = require("policy.item_generation.source_roll")
local availability = require("policy.character.skill_availability")

local books = {}
local FIXED_BOOK = "fixed"

local magic = {
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
}

-- Compare trained magic and nonmagic skills before deciding whether a manual roll is plausible.
local function manual(ctx)
    local magic_weight = 0
    local other_weight = 0
    local magic_ids = {}

    for _, id in ipairs(magic) do
        magic_ids[id] = true
    end

    for _, id in ipairs(skill_order.all()) do
        local level = selection.skill(ctx, id)

        if magic_ids[id] then
            magic_weight = magic_weight + level
        else
            other_weight = other_weight + level
        end
    end

    if other_weight == 0 or magic_weight * 3 >= other_weight then
        return false
    end

    return source.chance(ctx, other_weight,
        other_weight + 2 * magic_weight)
end

-- Exclude capped, forbidden, or disallowed skills before a manual names its training target.
local function manual_skill(ctx, player)
    local rows = {}
    local species = selection.species(ctx, player)

    for _, id in ipairs(skill_order.all()) do
        local level = selection.skill(ctx, id)
        local aptitude = species.aptitudes[id]

        if level < 27 and aptitude and aptitude.allowed and
            not availability.forbidden_skill(ctx, player, id) then
            local weight = level < 12 and level + 3 or
                math.max(0, 25 - level)

            if weight > 0 then
                rows[#rows + 1] = {
                    id = id,
                    weight = weight,
                }
            end
        end
    end

    if #rows == 0 then
        return nil
    end

    return selection.weighted(ctx, rows)
end

-- Example: Heavy nonmagic training can turn a book offer into a manual for a trainable skill.
-- If manual selection fails, weight themed, level, and fixed books before depth-specific fixed stock.
function books.pick(ctx, player, depth)
    if manual(ctx) then
        local skill_id = manual_skill(ctx, player)

        if skill_id then
            return ids.BOOK_MANUAL, {
                manual_skill_id = skill_id,
            }
        end
    end

    local choice = source.weighted_id(ctx, {
        {
            id = ids.BOOK_RANDART_THEME,
            weight = 30,
        },
        {
            id = ids.BOOK_RANDART_LEVEL,
            weight = 1,
        },
        {
            id = FIXED_BOOK,
            weight = 40,
        },
    })

    if choice == ids.BOOK_RANDART_LEVEL then
        local level = math.floor((selection.skill(ctx,
            skills.SK_SPELLCASTING) + 2) / 3)

        return choice, {
            acquirement_level = math.max(1, level),
        }
    end

    if choice ~= FIXED_BOOK then
        return choice
    end

    local rows = {}

    for _, kind in ipairs(catalog.all("items")) do
        if kind.class == classes.OBJ_BOOKS and
            kind.generation.mode == "random" and
            kind.generation.spells and #kind.generation.spells > 0 then
            local weight = book_weight.weight(kind, depth)

            if weight > 0 then
                rows[#rows + 1] = {
                    id = kind.id,
                    weight = weight,
                }
            end
        end
    end

    if #rows == 0 then
        return ids.BOOK_RANDART_THEME
    end

    return selection.weighted(ctx, rows)
end

return books
