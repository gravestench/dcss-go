-- Theory of operation: a successful player cast reports source spell
-- transgressions from immutable catalog metadata before Trog's ordinary
-- casting conduct. Preparation and failure do not reach this owner.
local conduct = require("policy.religion.conduct")
local flags = require("constants.spell_flags")
local kinds = require("constants.religion_conduct")
local schools = require("constants.spell_schools")
local spell_ids = require("ids.spells")
local streams = require("constants.rng_streams")

local spells = {}

-- Source spell definitions hold lists, so one helper checks both flags and
-- schools without copying their strings into the action owner.
local function contains(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Every special offense uses ten plus the spell's source difficulty.
-- Separate records preserve source order when one spell has two tags.
local function report(ctx, id, level)
    conduct.record(ctx, {
        id = id,
        level = level,
        known = true,
    })
end

-- The pinned source exempts a necromantic spell marked not_evil, while an
-- unholy flag is evil regardless of school. Only Swiftness itself reports
-- haste here because other haste effects have their own action owners.
function spells.on_success(ctx, player, spell)
    if not spell or type(spell.level) ~= "number" then
        error("spell conduct requires a resolved spell definition")
    end

    local severity = 10 + spell.level
    local evil = contains(spell.flags, flags.UNHOLY) or
        (contains(spell.schools, schools.NECROMANCY) and
            not contains(spell.flags, flags.NOT_EVIL))

    if evil then
        report(ctx, kinds.EVIL, severity)
    end

    if contains(spell.flags, flags.UNCLEAN) then
        report(ctx, kinds.UNCLEAN, severity)
    end

    if contains(spell.flags, flags.CHAOTIC) then
        report(ctx, kinds.CHAOS, severity)
    end

    if spell.id == spell_ids.SPELL_SWIFTNESS then
        report(ctx, kinds.HASTY, severity)
    end

    -- Source casts choose one through five severity after success. Keeping
    -- the draw here means the source chance is shared by every god, even
    -- though only Trog currently responds to SPELL_CASTING.
    report(ctx, kinds.SPELL_CASTING,
        1 + ctx:random(streams.RELIGION, 5))
end

-- Source spl-book.cc reports a casting act when a valid memorisation delay
-- starts. It chooses two through six severity once, not on every study turn
-- or when the spell finally becomes known.
function spells.on_memorise(ctx)
    report(ctx, kinds.SPELL_CASTING,
        2 + ctx:random(streams.RELIGION, 5))
end

return spells
