local choice = require("policy.combat.monster_summons.choice")
local branches = require("policy.combat.monster_summons.branches")
local demons = require("policy.combat.monster_summons.demons")
local drakes = require("policy.combat.monster_summons.drakes")
local eyeballs = require("policy.combat.monster_summons.eyeballs")
local harness = require("tests.harness")
local holiness = require("policy.combat.monster_summons.holies")
local monsters = require("ids.monsters")
local branch_ids = require("ids.branches")
local spells = require("ids.spells")
local strength = require("policy.combat.monster_summons.strength")
local undead = require("policy.combat.monster_summons.undead")
local vermin = require("policy.combat.monster_summons.vermin")
local component = require("constants.component")

local test = {}

-- Source weighted pickers use one monster-spell draw. Supplying a boundary
-- draw shows which ID owns each part of the committed source table.
local function draw_at(ctx, value)
    local game = setmetatable({}, { __index = ctx })

    function game.random(_, stream, bound)
        harness.equal(stream, "monster_spell",
            "monster summon choice uses the saved monster stream")
        harness.truthy(value >= 0 and value < bound,
            "test draw lies inside the source choice bound")

        return value
    end

    return game
end

-- Aura of Brilliance adds spell HD before the source spell-specific power
-- factor; Dragon and Menagerie intentionally differ from default spells.
local function spell_strength(ctx)
    local caster = ctx:create()

    ctx:add(caster, component.ACTOR, {
        kind_id = monsters.MONS_ORC_SORCERER,
        speed = 10,
    })

    local base = strength.spell_hd(ctx, caster)

    harness.equal(strength.power(ctx, caster,
        spells.SPELL_SUMMON_DRAGON), base * 5,
        "monster Dragon uses its source five-times-HD factor")
    harness.equal(strength.power(ctx, caster,
        spells.SPELL_MONSTROUS_MENAGERIE), base * 6,
        "Menagerie uses its source six-times-HD factor")
    harness.equal(strength.power(ctx, caster,
        spells.SPELL_SUMMON_VERMIN), base * 12,
        "ordinary summons use the source default factor")

    ctx:add(caster, component.MONSTER_EMPOWERED_SPELLS, {
        remaining_aut = 30,
    })

    harness.equal(strength.spell_hd(ctx, caster), base + 5,
        "Brilliance raises effective spell HD without changing base HD")
end

-- The first and last weighted entries make accidental array reordering or
-- weight drift visible without testing a copied implementation table.
local function source_pools(ctx)
    harness.equal(demons.tier(draw_at(ctx, 0), 5),
        monsters.MONS_CRIMSON_IMP,
        "lesser demon first entry matches source")
    harness.equal(demons.tier(draw_at(ctx, 5), 5),
        monsters.MONS_SHADOW_IMP,
        "lesser demon last entry matches source")
    harness.equal(undead.pick(draw_at(ctx, 15)),
        monsters.MONS_SHADOW,
        "undead source pool keeps all sixteen entries")
    harness.equal(vermin.pick(draw_at(ctx, 19)),
        monsters.MONS_DEMONIC_CRAWLER,
        "vermin source weights end with demonic crawler")
    harness.equal(drakes.pick(draw_at(ctx, 29)),
        monsters.MONS_LINDWURM,
        "drake source weights end with lindwurm")
    harness.equal(holiness.pick(draw_at(ctx, 230)),
        monsters.MONS_OPHAN,
        "rare Ophan occupies the final holy draw")
    harness.equal(eyeballs.pick(draw_at(ctx, 229)),
        monsters.MONS_EYE_OF_DEVASTATION,
        "rare Eye of Devastation occupies the final eye draw")
end

-- Reject zero and negative weights so a modded pool cannot silently skew
-- monster selection or consume an invalid RNG bound.
local function invalid_weights(ctx)
    local ok = pcall(choice.weighted, draw_at(ctx, 0), {
        {
            id = monsters.MONS_RAT,
            weight = 0,
        },
    })

    harness.falsy(ok, "a zero-weight entry is rejected")
end

-- Invitation persists its selected source branch; Planerend chooses a
-- source branch anew on each cast. Their pools keep source weights.
local function branch_pools(ctx)
    local invitation_kind = branches.invitation(draw_at(ctx, 0),
        branch_ids.BRANCH_SNAKE)

    harness.equal(invitation_kind, monsters.MONS_BLACK_MAMBA,
        "Snake pool begins with black mamba")

    local planer_kind = branches.planerend(draw_at(ctx, 219),
        branch_ids.BRANCH_ZOT)

    harness.equal(planer_kind, monsters.MONS_MOTH_OF_WRATH,
        "Zot source pool ends with moth of wrath")
end

-- Pools import live monster IDs; no copied monster schema is needed here.
function test.run(ctx)
    spell_strength(ctx)
    source_pools(ctx)
    invalid_weights(ctx)
    branch_pools(ctx)
end

return test
