-- Theory of operation: the character trainer reports skill-point gains
-- after spending a whole XP batch. Source skills.cc totals gained magic
-- points and sends one SPELL_PRACTISE conduct with rounded tenths.
local conduct = require("policy.religion.conduct")
local kinds = require("constants.religion_conduct")
local spells = require("policy.character.wanderer_spells")
local streams = require("constants.rng_streams")

local training = {}

-- Snapshot only source magic skills. Combat and Invocations points do not
-- count even when a weighted training pass changes them in the same turn.
function training.before(entries)
    local points = {}

    for _, entry in ipairs(entries) do
        if spells.is_magic_skill(entry.id) then
            points[entry.id] = entry.points
        end
    end

    return points
end

-- Fractional tenths use a draw only for a remainder. The trainer calls
-- once after all skill allocations so shuffled batch order cannot change
-- the number or severity of conduct events.
function training.report(ctx, player, before, entries)
    local gained = 0

    for _, entry in ipairs(entries) do
        if spells.is_magic_skill(entry.id) then
            gained = gained + math.max(0,
                entry.points - (before[entry.id] or 0))
        end
    end

    if gained == 0 then
        return 0
    end

    local severity = math.floor(gained / 10)
    local remainder = gained % 10

    if remainder > 0 and
        ctx:random(streams.RELIGION, 10) < remainder then
        severity = severity + 1
    end

    conduct.record(ctx, {
        id = kinds.SPELL_PRACTISE,
        level = severity,
        known = true,
    })

    return severity
end

return training
