-- Okawaru sends level-scaled warriors. The source roster's depth curves are
-- shared with ambient populations, and each hostile body remains saveable.
local component = require("constants.component")
local curves = require("constants.population_curves")
local gods = require("constants.gods")
local monsters = require("ids.monsters")
local pool = require("policy.population.pool")
local streams = require("constants.rng_streams")
local summons = require("policy.religion.wrath.summons")
local requests = require("constants.vault_monster_requests")

local okawaru = {}

-- Keep each source row's fields in one call so the long 24-row roster stays
-- readable while the shared population owner receives normal row records.
local function servant(first, last, rarity, curve, kind)
    return {
        min_depth = first,
        max_depth = last,
        rarity = rarity,
        curve = curve,
        monster_id = kind,
    }
end

-- god-wrath.cc:_okawaru_servants. Source order breaks equal-weight draws;
-- the population curve owner computes each row's exact depth weight.
local rows = {
    servant(1, 3, 3, curves.FALL, monsters.MONS_ORC),
    servant(1, 3, 3, curves.FALL, monsters.MONS_GNOLL),
    servant(2, 6, 3, curves.PEAK, monsters.MONS_OGRE),
    servant(2, 6, 2, curves.PEAK, monsters.MONS_GNOLL_SERGEANT),
    servant(3, 7, 1, curves.FLAT, monsters.MONS_TWO_HEADED_OGRE),
    servant(3, 13, 3, curves.PEAK, monsters.MONS_ORC_WARRIOR),
    servant(5, 15, 3, curves.PEAK, monsters.MONS_ORC_KNIGHT),
    servant(5, 15, 2, curves.PEAK, monsters.MONS_CYCLOPS),
    servant(7, 21, 2, curves.PEAK, monsters.MONS_CENTAUR_WARRIOR),
    servant(7, 21, 2, curves.PEAK, monsters.MONS_NAGA_WARRIOR),
    servant(7, 21, 2, curves.PEAK, monsters.MONS_TENGU_WARRIOR),
    servant(7, 21, 1, curves.FLAT, monsters.MONS_MERFOLK_IMPALER),
    servant(7, 21, 1, curves.FLAT, monsters.MONS_MERFOLK_JAVELINEER),
    servant(7, 21, 1, curves.FLAT, monsters.MONS_MINOTAUR),
    servant(9, 27, 2, curves.FLAT, monsters.MONS_STONE_GIANT),
    servant(9, 27, 1, curves.FLAT, monsters.MONS_DEEP_ELF_KNIGHT),
    servant(9, 27, 1, curves.FLAT, monsters.MONS_DEEP_ELF_ARCHER),
    servant(11, 21, 1, curves.FLAT, monsters.MONS_ORC_WARLORD),
    servant(11, 27, 2, curves.FLAT, monsters.MONS_FIRE_GIANT),
    servant(11, 27, 2, curves.FLAT, monsters.MONS_FROST_GIANT),
    servant(13, 27, 1, curves.FLAT, monsters.MONS_DEEP_ELF_BLADEMASTER),
    servant(13, 27, 1, curves.FLAT, monsters.MONS_DEEP_ELF_MASTER_ARCHER),
    servant(13, 27, 1, curves.FLAT, requests.BASE_DRACONIAN),
    servant(15, 27, 2, curves.FLAT, monsters.MONS_TITAN),
}

-- RANDOM_BASE_DRACONIAN resolves to one of eight active base colours. The
-- generic draconian profile would erase this source roster distinction.
local base_draconians = {
    monsters.MONS_BLACK_DRACONIAN,
    monsters.MONS_GREEN_DRACONIAN,
    monsters.MONS_GREY_DRACONIAN,
    monsters.MONS_PALE_DRACONIAN,
    monsters.MONS_PURPLE_DRACONIAN,
    monsters.MONS_RED_DRACONIAN,
    monsters.MONS_WHITE_DRACONIAN,
    monsters.MONS_YELLOW_DRACONIAN,
}

local function concrete_kind(ctx, kind)
    if kind ~= requests.BASE_DRACONIAN then
        return kind
    end

    return base_draconians[ctx:random(streams.CARDS,
        #base_draconians) + 1]
end

-- The source attempts one plus level/5 warriors, even when placement fails.
-- Successful bodies retain the god ID, hostile attitude, and no timeout.
function okawaru.apply(ctx, player)
    local progression = ctx:get(player, component.PROGRESSION)
    local level = math.max(1, progression.level)
    local choices, total = pool.at_rows(rows, level)
    local created = 0

    for _ = 1, 1 + math.floor(level / 5) do
        local kind = concrete_kind(ctx,
            pool.pick(ctx, choices, total, streams.CARDS))

        if summons.hostile(ctx, player, gods.OKAWARU, kind) then
            created = created + 1
        end
    end

    ctx:emit("religion", created > 0 and
        "Okawaru sends forces against you!" or
        "Okawaru's forces are busy with other wars.")

    return true
end

return okawaru
