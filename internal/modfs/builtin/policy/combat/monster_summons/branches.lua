local choice = require("policy.combat.monster_summons.choice")
local branch_ids = require("ids.branches")
local monsters = require("ids.monsters")

local branches = {}

-- mon-cast.cc:_invitation_summons gives each branch three distinct
-- monsters. Forceful Invitation saves the chosen branch ID on its caster.
local invitation = {
    [branch_ids.BRANCH_SNAKE] = {
        {
            id = monsters.MONS_BLACK_MAMBA,
            weight = 80,
        },

        {
            id = monsters.MONS_NAGA_WARRIOR,
            weight = 40,
        },

        {
            id = monsters.MONS_MANA_VIPER,
            weight = 20,
        },
    },

    [branch_ids.BRANCH_SPIDER] = {
        {
            id = monsters.MONS_TARANTELLA,
            weight = 60,
        },

        {
            id = monsters.MONS_WOLF_SPIDER,
            weight = 80,
        },

        {
            id = monsters.MONS_ORB_SPIDER,
            weight = 20,
        },
    },

    [branch_ids.BRANCH_SWAMP] = {
        {
            id = monsters.MONS_BOG_BODY,
            weight = 80,
        },

        {
            id = monsters.MONS_SWAMP_DRAKE,
            weight = 60,
        },

        {
            id = monsters.MONS_GOLIATH_FROG,
            weight = 40,
        },
    },

    [branch_ids.BRANCH_SHOALS] = {
        {
            id = monsters.MONS_SNAPPING_TURTLE,
            weight = 60,
        },

        {
            id = monsters.MONS_MANTICORE,
            weight = 40,
        },

        {
            id = monsters.MONS_MERFOLK_AQUAMANCER,
            weight = 20,
        },
    },

    [branch_ids.BRANCH_ELF] = {
        {
            id = monsters.MONS_DEEP_ELF_AIR_MAGE,
            weight = 50,
        },

        {
            id = monsters.MONS_DEEP_ELF_FIRE_MAGE,
            weight = 50,
        },

        {
            id = monsters.MONS_DEEP_ELF_KNIGHT,
            weight = 40,
        },
    },

    [branch_ids.BRANCH_VAULTS] = {
        {
            id = monsters.MONS_VERY_UGLY_THING,
            weight = 60,
        },

        {
            id = monsters.MONS_IRONBOUND_THUNDERHULK,
            weight = 40,
        },

        {
            id = monsters.MONS_VAULT_SENTINEL,
            weight = 20,
        },
    },

    [branch_ids.BRANCH_CRYPT] = {
        {
            id = monsters.MONS_FREEZING_WRAITH,
            weight = 80,
        },

        {
            id = monsters.MONS_SKELETAL_WARRIOR,
            weight = 40,
        },

        {
            id = monsters.MONS_NECROMANCER,
            weight = 40,
        },
    },
}

-- Planerend draws a fresh branch for each cast and uses stronger source
-- populations. Slime creatures receive their size after actor creation.
local planerend = {
    [branch_ids.BRANCH_SLIME] = {
        {
            id = monsters.MONS_SLIME_CREATURE,
            weight = 80,
        },

        {
            id = monsters.MONS_ROCKSLIME,
            weight = 100,
        },

        {
            id = monsters.MONS_ACID_BLOB,
            weight = 100,
        },
    },

    [branch_ids.BRANCH_ELF] = {
        {
            id = monsters.MONS_DEEP_ELF_SORCERER,
            weight = 100,
        },

        {
            id = monsters.MONS_DEEP_ELF_HIGH_PRIEST,
            weight = 100,
        },

        {
            id = monsters.MONS_DEEP_ELF_BLADEMASTER,
            weight = 60,
        },
    },

    [branch_ids.BRANCH_VAULTS] = {
        {
            id = monsters.MONS_VAULT_SENTINEL,
            weight = 80,
        },

        {
            id = monsters.MONS_IRONBOUND_CONVOKER,
            weight = 40,
        },

        {
            id = monsters.MONS_WAR_GARGOYLE,
            weight = 100,
        },
    },

    [branch_ids.BRANCH_CRYPT] = {
        {
            id = monsters.MONS_VAMPIRE_KNIGHT,
            weight = 100,
        },

        {
            id = monsters.MONS_FLAYED_GHOST,
            weight = 100,
        },

        {
            id = monsters.MONS_REVENANT,
            weight = 80,
        },
    },

    [branch_ids.BRANCH_TOMB] = {
        {
            id = monsters.MONS_ANCIENT_CHAMPION,
            weight = 60,
        },

        {
            id = monsters.MONS_SPHINX,
            weight = 100,
        },

        {
            id = monsters.MONS_MUMMY_PRIEST,
            weight = 100,
        },
    },

    [branch_ids.BRANCH_ABYSS] = {
        {
            id = monsters.MONS_APOCALYPSE_CRAB,
            weight = 80,
        },

        {
            id = monsters.MONS_STARCURSED_MASS,
            weight = 100,
        },

        {
            id = monsters.MONS_TENTACLED_STARSPAWN,
            weight = 40,
        },
    },

    [branch_ids.BRANCH_ZOT] = {
        {
            id = monsters.MONS_DRACONIAN_STORMCALLER,
            weight = 40,
        },

        {
            id = monsters.MONS_GOLDEN_DRAGON,
            weight = 100,
        },

        {
            id = monsters.MONS_MOTH_OF_WRATH,
            weight = 80,
        },
    },
}

-- Stable branch-ID order removes file-load order from the random choice.
-- The source gives each branch one equal slot in its own array.
local function branch_ids_for(pools)
    local ids = {}

    for id in pairs(pools) do
        ids[#ids + 1] = id
    end

    table.sort(ids)

    return ids
end

-- Invitation draws its branch once; the caller saves this ID on the caster.
function branches.choose_invitation(ctx)
    return choice.uniform(ctx, branch_ids_for(invitation))
end

-- Planerend deliberately redraws its branch on each cast.
function branches.choose_planerend(ctx)
    return choice.uniform(ctx, branch_ids_for(planerend))
end

-- Look up one monster from the saved Invitation branch's source weights.
function branches.invitation(ctx, branch_id)
    local pool = invitation[branch_id]

    if not pool then
        error("unsupported Invitation branch " .. tostring(branch_id))
    end

    return choice.weighted(ctx, pool)
end

-- Restore validation checks the same source pool used by the cast. A
-- branch removed by a mod cannot silently redirect a saved Invitation.
function branches.valid_invitation(branch_id)
    return invitation[branch_id] ~= nil
end

-- Look up one monster from the freshly drawn Planerend branch.
function branches.planerend(ctx, branch_id)
    local pool = planerend[branch_id]

    if not pool then
        error("unsupported Planerend branch " .. tostring(branch_id))
    end

    return choice.weighted(ctx, pool)
end

return branches
