-- Source: crawl-ref/source/acquire.cc:_should_acquire_manual and
-- _do_book_acquirement. Scrolls may offer manuals; Sif uses the same book
-- catalog with a no-manual, unknown-spell selector owned below.
local catalog = require("policy.catalog")
local classes = require("ids.object_classes")
local ids = require("ids.items")
local book_weight = require("policy.item_generation.books")
local selection = require("policy.scrolls.acquirement.selection")
local skills = require("ids.skills")
local skill_order = require("data.skill_order")
local source = require("policy.item_generation.source_roll")
local availability = require("policy.character.skill_availability")
local fighter = require("policy.combat.fighter")
local records = require("policy.character.spell_records")
local player_books = require("policy.magic.player_book_catalog")
local schools = require("constants.spell_schools")
local streams = require("constants.rng_streams")

local books = {}
local FIXED_BOOK = "fixed"
local GIFT_THEME_WEIGHT = 30
local GIFT_FIXED_WEIGHT = 10
local GIFT_LEVEL_WEIGHT = 1
local GIFT_TOTAL_WEIGHT = GIFT_THEME_WEIGHT + GIFT_FIXED_WEIGHT +
    GIFT_LEVEL_WEIGHT

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

local school_skill = {
    [schools.AIR] = skills.SK_AIR_MAGIC,
    [schools.CONJURATION] = skills.SK_CONJURATIONS,
    [schools.EARTH] = skills.SK_EARTH_MAGIC,
    [schools.FIRE] = skills.SK_FIRE_MAGIC,
    [schools.HEXES] = skills.SK_HEXES,
    [schools.ICE] = skills.SK_ICE_MAGIC,
    [schools.NECROMANCY] = skills.SK_NECROMANCY,
    [schools.POISON] = skills.SK_POISON_MAGIC,
    [schools.SUMMONING] = skills.SK_SUMMONINGS,
    [schools.TRANSLOCATION] = skills.SK_TRANSLOCATIONS,
    [schools.TRANSMUTATION] = skills.SK_TRANSMUTATIONS,
}

-- Source _skill_rdiv rounds fractional skill at 1/256 precision, drawing
-- only when a remainder exists. Fixed-book weights therefore respond to
-- training progress instead of waiting for a whole level boundary.
local function rounded_skill(ctx, skill_id)
    local scaled = fighter.skill(ctx, skill_id, 256)
    local whole = math.floor(scaled / 256)
    local remainder = scaled % 256

    if remainder > 0 and
        ctx:random(streams.ACQUIREMENT, 256) < remainder then
        whole = whole + 1
    end

    return whole
end

-- Source _book_weight ignores spells already in the player's library.
-- This same set also tells random gift books which spells remain useful.
local function unknown_spells(ctx, player)
    local known = {}

    for _, entry in ipairs(records.list(ctx, player)) do
        if entry.state.in_library or entry.state.known_slot > 0 then
            known[entry.state.spell_id] = true
        end
    end

    return known
end

-- A fixed book is weighted by the sum of its unfamiliar spells, averaging
-- the player's relevant spell-school skills before applying difficulty.
local function fixed_weight(ctx, kind, known)
    local total = 0

    for _, spell_id in ipairs(kind.generation.spells or {}) do
        if not known[spell_id] then
            local spell = catalog.get("spells", spell_id)
            local skills_total = 0
            local count = 0

            for _, school in ipairs(spell.schools or {}) do
                local skill_id = school_skill[school]

                if skill_id then
                    skills_total = skills_total +
                        rounded_skill(ctx, skill_id)
                    count = count + 1
                end
            end

            if count > 0 then
                total = total + math.max(0,
                    math.floor(2 * skills_total / count) +
                        5 - spell.level)
            end
        end
    end

    return total
end

-- Sif cannot give manuals. The source gives themed books weight 30, fixed
-- books weight 10, and level books weight 1; a depleted fixed pool falls
-- back to a theme rather than selecting a useless imported template.
function books.pick_gift(ctx, player)
    local known = unknown_spells(ctx, player)
    local unknown = false

    for _, spell in ipairs(player_books.ordered()) do
        if not known[spell.id] then
            unknown = true
            break
        end
    end

    if not unknown then
        return nil
    end

    local choice = ctx:random(streams.ACQUIREMENT,
        GIFT_TOTAL_WEIGHT)

    if choice < GIFT_THEME_WEIGHT then
        return ids.BOOK_RANDART_THEME, {
            exclude_known = true,
        }
    end

    if choice == GIFT_THEME_WEIGHT + GIFT_FIXED_WEIGHT then
        local level = math.floor((selection.skill(ctx,
            skills.SK_SPELLCASTING) + 2) / 3)

        level = math.max(1, level)

        local available = false

        for _, spell in ipairs(player_books.ordered()) do
            if spell.level == level and not known[spell.id] then
                available = true
                break
            end
        end

        if not available then
            return nil
        end

        return ids.BOOK_RANDART_LEVEL, {
            acquirement_level = level,
            exclude_known = true,
        }
    end

    local rows = {}

    for _, kind in ipairs(catalog.all("items")) do
        if kind.class == classes.OBJ_BOOKS and
            kind.generation and kind.generation.mode == "random" and
            kind.generation.spells and #kind.generation.spells > 0 then
            local weight = fixed_weight(ctx, kind, known)

            if weight > 0 then
                rows[#rows + 1] = {
                    id = kind.id,
                    weight = weight,
                }
            end
        end
    end

    if #rows == 0 then
        return ids.BOOK_RANDART_THEME, {
            exclude_known = true,
        }
    end

    return selection.weighted(ctx, rows)
end

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
