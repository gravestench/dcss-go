-- The four Elf:2 Hall of Blades maps share one source monster roster.
-- Two distinct high-quality weapons with distinct egos make the central
-- encounter vary without duplicating the policy in each DES map.
local directives = require("constants.vault_directives")

local shared = {}

local weapon_bases = {
    "quick blade",
    "double sword",
    "executioner's axe",
    "eveningstar",
    "bardiche",
    "lajatang",
}

local weapon_egos = {
    "flaming",
    "freezing",
    "electrocution",
    "venom",
    "holy_wrath",
    "pain",
    "vampirism",
    "draining",
    "antimagic",
    "distortion",
}

-- Source util.random_from retries until a second value differs from the
-- first. Preserve that draw sequence rather than sampling without replacement.
local function distinct_pair(api, values)
    local first = values[api:roll(#values) + 1]
    local second = first

    while second == first do
        second = values[api:roll(#values) + 1]
    end

    return first, second
end

-- The source first chooses double or triple sword, then makes that one
-- blade a member of the six-way type pool for this placement only.
local function weapon_pair(api)
    local blades = {}

    for _, name in ipairs(weapon_bases) do
        blades[#blades + 1] = name
    end

    blades[2] = api:one_in(2) and "double sword" or "triple sword"

    return distinct_pair(api, blades)
end

-- Emit the seven source monster slots in their original order. The last
-- two entries carry separately rolled weapon and ego requests.
local function hall_of_blades_monsters(api)
    api:emit(directives.MONS,
        "deep elf pyromancer / deep elf zephyrmancer")
    api:emit(directives.MONS,
        "deep elf knight w:22 / deep elf pyromancer w:1 / " ..
        "deep elf zephyrmancer w:1")
    api:emit(directives.MONS, "deep elf blademaster")
    api:emit(directives.MONS, "dancing weapon")

    local first, second = weapon_pair(api)
    local first_ego, second_ego = distinct_pair(api, weapon_egos)

    api:emit(directives.MONS,
        "dancing weapon; good_item " .. first .. " ego:" .. first_ego)
    api:emit(directives.MONS,
        "dancing weapon; good_item " .. second .. " ego:" .. second_ego)
end

shared.hall_of_blades_monsters = hall_of_blades_monsters

return shared
