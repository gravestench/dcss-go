-- Jiyva's wrath first chooses a body effect, then may revoke a slime gift.
-- The source's short-circuit draws are kept separate from effect-owner draws.
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local choices = require("constants.mutation_choices")
local component = require("constants.component")
local gods = require("constants.gods")
local streams = require("constants.rng_streams")
local uses = require("constants.mutation_uses")

local monsters = require("ids.monsters")

local catalog = require("policy.catalog")
local contamination = require("policy.magic.contamination")
local physiology = require("policy.mutations.physiology")
local records = require("policy.mutations.records")
local summons = require("policy.religion.wrath.summons")
local transition = require("policy.mutations.transition")

local jiyva = {}

-- C++ random2 returns zero for an empty bound; keep zero-penance
-- contamination from asking the host RNG for an invalid range.
local function roll(ctx, bound)
    if bound <= 1 then
        return 0
    end

    return ctx:random(streams.CARDS, bound)
end

local slimes = {
    monsters.MONS_FLOATING_EYE,
    monsters.MONS_EYE_OF_DEVASTATION,
    monsters.MONS_GREAT_ORB_OF_EYES,
    monsters.MONS_SHINING_EYE,
    monsters.MONS_GLOWING_ORANGE_BRAIN,
    monsters.MONS_ROCKSLIME,
    monsters.MONS_QUICKSILVER_OOZE,
    monsters.MONS_ACID_BLOB,
    monsters.MONS_AZURE_JELLY,
    monsters.MONS_SLIME_CREATURE,
}

-- The source chooses one creature before every placement attempt, even
-- when a blocked cell prevents it from arriving. The summon owner saves
-- each successful monster as permanent, hostile, and sourced to Jiyva.
local function summon_slimes(ctx, player)
    local level = ctx:get(player, component.PROGRESSION).level
    local attempts = 1 + math.floor(level / 10) +
        ctx:random(streams.CARDS, 3)
    local created = false

    for _ = 1, attempts do
        local kind = slimes[ctx:random(streams.CARDS, #slimes) + 1]

        if summons.hostile(ctx, player, gods.JIYVA, kind) then
            created = true
        end
    end

    ctx:emit(channels.RELIGION, created and
        "Jiyva says: Some slimes ooze up out of the ground!" or
        "Jiyva says: The ground quivers slightly.")
end

-- Source tests every active mutation rank before announcing revocation;
-- it may announce a gift even when no acquired rank can be removed.
local function has_slime_mutation(ctx, player)
    for _, entry in ipairs(records.list(ctx, player)) do
        if entry.state.innate + entry.state.acquired +
            entry.state.temporary > 0 then
            local definition = catalog.get(categories.MUTATIONS,
                entry.state.mutation_id)

            for _, use in ipairs(definition.uses or {}) do
                if use == uses.JIYVA then
                    return true
                end
            end
        end
    end

    return false
end

-- The source's god_gift flag bypasses ordinary deletion resistance, but
-- its force_mutation flag is false and still checks mutation safety.
local function revoke_slime(ctx, player)
    if not has_slime_mutation(ctx, player) then
        return
    end

    ctx:emit(channels.RELIGION, "Jiyva's gift of slime is revoked.")

    -- Source god_gift skips deletion resistance, but does not skip the
    -- unsafe-body check. The shared deletion owner uses forced only after
    -- that explicit check so it still removes one acquired rank.
    if physiology.can_safely_mutate(ctx, player) then
        transition.remove_random(ctx, player, choices.JIYVA, true)
    end
end

-- Keep all three short-circuit one_chance_in draws in source order. The
-- mutation and five-form paths need god-gift and Fungus Form mechanics;
-- explicit errors preserve the selected punishment until those exist.
function jiyva.apply(ctx, player)
    if physiology.can_safely_mutate(ctx, player) and
        ctx:random(streams.CARDS, 7) == 0 then
        error("unimplemented Jiyva god-gift bad mutation wrath")
    elseif ctx:random(streams.CARDS, 3) == 0 and
        not (ctx:get(player, component.PLAYER_FORM) or {}).uncancellable then
        error("unimplemented Jiyva five-form transformation wrath")
    elseif ctx:random(streams.CARDS, 3) ~= 0 or
        ctx:get(player, component.RELIGION_WORSHIP).god_id == gods.JIYVA then
        ctx:emit(channels.RELIGION,
            "Jiyva says: Mutagenic energy floods into your body!")

        local penance = ctx:get(player,
            component.RELIGION_WORSHIP).penance[gods.JIYVA] or 0
        local amount = roll(ctx, penance * 500)

        contamination.change(ctx, player, amount, false)
    else
        summon_slimes(ctx, player)
    end

    if ctx:random(streams.CARDS, 2) == 0 then
        revoke_slime(ctx, player)
    end

    return true
end

return jiyva
