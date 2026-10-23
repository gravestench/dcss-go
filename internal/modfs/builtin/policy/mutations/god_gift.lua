-- God-gift mutations bypass ordinary rMut, but Zin can still shield the body.
-- The shared transition owns conflicts, rank changes, and temporary expiry.
local classes = require("constants.mutation_classes")
local channels = require("constants.message_channels")
local component = require("constants.component")
local gods = require("constants.gods")
local piety = require("policy.religion.piety")
local streams = require("constants.rng_streams")
local transition = require("policy.mutations.transition")

local god_gift = {}

-- Source: mutation.cc:mutate checks Zin after skipping intrinsic resistance.
-- Zin's rank-minus-one passive remains active under penance. A zero piety
-- chance spends no roll, and piety at the fifth breakpoint is certain.
local function zin_protects(ctx, owner)
    local worship = ctx:get(owner, component.RELIGION_WORSHIP)

    if not worship or worship.god_id ~= gods.ZIN then
        return false
    end

    local points = worship.piety or 0
    local threshold = piety.breakpoint(5)

    if points <= 0 then
        return false
    end

    if points >= threshold then
        return true
    end

    return ctx:random(streams.MUTATION, threshold) < points
end

-- Preserve the source's protection-before-selection order. Forced transition
-- here means the god-gift conflict rule and intrinsic rMut bypass; the Zin
-- protection above is still checked before unsafe-body and candidate draws.
function god_gift.grant_random(ctx, owner, choice, class)
    if class ~= classes.ACQUIRED and class ~= classes.TEMPORARY then
        error("god-gift mutation requires acquired or temporary class")
    end

    if zin_protects(ctx, owner) then
        ctx:emit(channels.RELIGION,
            "Zin protects your body from mutation!")

        return { kind = "protected" }
    end

    return transition.grant_random(ctx, owner, choice, class, true)
end

return god_gift
