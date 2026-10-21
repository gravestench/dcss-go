-- Source defective weapons are three differently impaired dancing-weapon
-- groups. Each group's equipment is a weighted DES alternative, so the
-- monster's equipment draw happens in the normal spawn path.
local directives = require("constants.vault_directives")

local handler = {}

local chaos_types = {
    ["spear"] = 2,
    ["trident"] = 2,
    ["mace"] = 2,
    ["flail"] = 2,
    ["dire flail"] = 2,
    ["quarterstaff"] = 2,
    ["long sword"] = 2,
    ["scimitar"] = 2,
    ["short sword"] = 2,
    ["dagger"] = 2,
    ["rapier"] = 2,
    ["quick blade"] = 1,
    ["hand axe"] = 2,
    ["war axe"] = 2,
}

local distortion_types = {
    ["halberd"] = 1,
    ["morningstar"] = 1,
    ["great mace"] = 1,
    ["giant club"] = 1,
    ["great sword"] = 1,
    ["battleaxe"] = 1,
}

local venom_types = {
    ["demon trident"] = 1,
    ["bardiche"] = 2,
    ["giant spiked club"] = 2,
    ["lajatang"] = 1,
    ["double sword"] = 1,
    ["triple sword"] = 1,
    ["broad axe"] = 1,
    ["battleaxe"] = 2,
    ["executioner's axe"] = 1,
}

-- Source dgn.random_item_def sorts names and emits weighted alternatives.
-- Building that text once leaves all later equipment selection in the
-- shared monster and item owners, including the weapon's ego and quality.
local function equipment(types, ego, quality)
    local names = {}

    for name in pairs(types) do
        names[#names + 1] = name
    end

    table.sort(names)

    local alternatives = {}

    for _, name in ipairs(names) do
        local request = name

        if quality then
            request = request .. " " .. quality
        end

        alternatives[#alternatives + 1] = request ..
            " ego:" .. ego .. " w:" .. types[name]
    end

    return table.concat(alternatives, " | ")
end

-- Blind chaos weapons are fast, slow distortion weapons are heavy, and
-- corroded venom weapons start from the source's higher-quality types.
local function choose_weapons(api)
    api:emit(directives.KMONS,
        "1 = dancing weapon perm_ench:blind ; " ..
        equipment(chaos_types, "chaos"))
    api:emit(directives.KMONS,
        "2 = dancing weapon perm_ench:slow ; " ..
        equipment(distortion_types, "distortion"))
    api:emit(directives.KMONS,
        "3 = dancing weapon perm_ench:corrosion ; " ..
        equipment(venom_types, "venom", "damaged"))
end

handler.choose_weapons = choose_weapons

return handler
