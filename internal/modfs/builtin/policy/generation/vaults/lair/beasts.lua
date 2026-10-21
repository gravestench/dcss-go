-- Theory of operation: source Beast Lair maps share their random terrain in
-- DES. This handler fills four monster slots. Large packs suppress ordinary
-- random spawns over the placed map, including the rare large roll in a
-- small Beast Lair map. That choice is saved as a typed generation rule.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local rules = require("constants.vault_generation_rules")

local beasts = {}

local shallow_small = {
    "black bear", "water moccasin", "bullfrog", "wolf", "yak",
    "komodo dragon", "cane toad",
}

local deep_small = {
    "yak", "yak", "polar bear", "death yak", "elephant",
    "cane toad", "komodo dragon", "wyvern",
}

local large_packs = {
    {
        "hound / wolf",
        "wolf",
        "wolf / warg w:1",
    },
    {
        "black bear",
        "black bear / polar bear",
        "polar bear",
    },
    {
        "iguana",
        "iguana / basilisk",
        "komodo dragon w:20 / hydra w:2",
    },
    {
        "elephant",
        "elephant",
        "elephant / dire elephant w:1",
    },
    {
        "yak",
        "yak / death yak w:6",
        "death yak / catoblepas w:1",
    },
    {
        "water moccasin",
        "water moccasin / black mamba w:5",
        "black mamba / anaconda w:2",
    },
}

-- Roll one of three source families, shifted to deeper families after Lair:3.
-- The first MONS slot remains a plant so later numbered map glyphs retain
-- their source identity. The placement record controls random spawns later.
local function large(api)
    local pack_index = api:roll(3) + 1

    if api:depth() > 3 then
        pack_index = pack_index + 3
    end

    api:record(effects.GENERATION_RULE, {
        rule = rules.NO_MONSTER_GEN,
        scope = rules.VAULT,
    })
    api:emit(directives.MONS, "plant")

    for _, monster in ipairs(large_packs[pack_index]) do
        api:emit(directives.MONS, monster)
    end
end

-- Small source maps rarely borrow the large pool. The original helper
-- called e.mons(plant) with an unbound Lua name; use the intended plant
-- monster instead of preserving that legacy script fault.
local function small(api)
    if not api:validating() and api:one_in(25) then
        large(api)

        return
    end

    local pool = api:depth() < 4 and shallow_small or deep_small

    api:emit(directives.MONS, "plant")

    for _ = 1, 3 do
        api:emit(directives.MONS, api:random_from(pool))
    end
end

beasts.large = large
beasts.small = small

return beasts
