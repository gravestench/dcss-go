local choice = require("policy.combat.monster_summons.choice")
local catalog = require("policy.catalog")
local flags = require("constants.monster_flags")
local holiness = require("constants.monster_holiness")
local monsters = require("ids.monsters")
local pool = require("policy.population.pool")
local roster = require("policy.population.roster")
local scenarios = require("constants.scenarios")
local streams = require("constants.rng_streams")
local branches = require("ids.branches")

local undead = {}

-- mon-cast.cc:_pick_undead_summon uses uniform random choice, including
-- base forms whose final appearance is resolved by the spawn owner.
local kinds = {
    monsters.MONS_NECROPHAGE,
    monsters.MONS_JIANGSHI,
    monsters.MONS_FLAYED_GHOST,
    monsters.MONS_ZOMBIE,
    monsters.MONS_SKELETON,
    monsters.MONS_SIMULACRUM,
    monsters.MONS_SPECTRAL_THING,
    monsters.MONS_FLYING_SKULL,
    monsters.MONS_MUMMY,
    monsters.MONS_VAMPIRE,
    monsters.MONS_WIGHT,
    monsters.MONS_WRAITH,
    monsters.MONS_SHADOW_WRAITH,
    monsters.MONS_FREEZING_WRAITH,
    monsters.MONS_PHANTASMAL_WARRIOR,
    monsters.MONS_SHADOW,
}

-- One source draw chooses one monster; a spell decides how many to try.
function undead.pick(ctx)
    return choice.uniform(ctx, kinds)
end

-- Generic zombies, skeletons, simulacra, and spectral things have no
-- standalone body. Select an eligible base from the current Dungeon roster
-- before deriving their HP and attacks, like source zombie_picker does.
function undead.base(ctx, position, kind_id)
    local scenario = scenarios.GENERATED_DUNGEON_BASIC
    local allowed = roster.allowed(scenario, branches.BRANCH_DUNGEON)

    for id in pairs(allowed) do
        local definition = catalog.get("monsters", id)
        local natural = false
        local excluded = false

        for _, value in ipairs(definition.holiness or {}) do
            natural = natural or value == holiness.NATURAL
        end

        for _, value in ipairs(definition.flags or {}) do
            excluded = excluded or value == flags.NO_GEN_DERIVED or
                value == flags.NO_ZOMBIE or
                (kind_id == monsters.MONS_SKELETON and
                    value == flags.NO_SKELETON)
        end

        if not natural or not definition.leaves_corpse or excluded or
            not definition.hd or not definition.average_hp_10x then
            allowed[id] = nil
        end
    end

    local choices, total = pool.at_depth(branches.BRANCH_DUNGEON,
        position.level_id,
        allowed, scenario)
    local base_id = pool.pick(ctx, choices, total,
        streams.MONSTER_SPELL)

    return catalog.get("monsters", base_id)
end

-- Source derived_undead_avg_hp uses a different tenth-HP multiplier for
-- each body. The ordinary monster HP roll still owns the final variation.
function undead.average_hp(kind_id, base_hd)
    local per_hd = {
        [monsters.MONS_ZOMBIE] = 85,
        [monsters.MONS_SKELETON] = 70,
        [monsters.MONS_SIMULACRUM] = 30,
        [monsters.MONS_SPECTRAL_THING] = 60,
    }

    return math.floor(per_hd[kind_id] * base_hd / 10)
end

-- Only these four entries in the source pool require a derived base body.
function undead.derived(kind_id)
    return kind_id == monsters.MONS_ZOMBIE or
        kind_id == monsters.MONS_SKELETON or
        kind_id == monsters.MONS_SIMULACRUM or
        kind_id == monsters.MONS_SPECTRAL_THING
end

return undead
