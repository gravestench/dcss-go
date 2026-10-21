-- Morgues fill a packed room with undead, choose branch-specific remains,
-- and put matching weapon egos on skeletal warriors. Their corpse records
-- stay typed until the delayed-decay gameplay owner materializes them.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local fill = require("policy.generation.vaults.builder.special_room_fill")

local room = {}

-- Hell branches replace the ordinary weapon suffix on the two armed slots.
local function weapon_suffix(branch)
    if branch == branches.BRANCH_GEHENNA then
        return " ego:flaming ident:type"
    end

    if branch == branches.BRANCH_COCYTUS then
        return " ego:freezing ident:type"
    end

    if branch == branches.BRANCH_DIS then
        return " good_item"
    end

    if branch == branches.BRANCH_TARTARUS then
        return " ego:draining ident:type"
    end

    return ""
end

-- The six common slots are shared; the last two monster groups and corpse
-- alternatives reflect which Hell or deep branch owns the room.
local function roster(branch, depth)
    local suffix = weapon_suffix(branch)
    local monsters = {
        "zombie w:9 / skeleton w:5 / spectral thing w:1",
        "shadow wraith w:3 / soul eater w:4 / vampire mage w:3 / " ..
            "flayed ghost w:4 / death knight w:1",
        "skeletal warrior w:15 ; great mace" .. suffix ..
            " | glaive" .. suffix .. " | battleaxe" .. suffix,
        "vampire knight ; chain mail . great mace" .. suffix ..
            " | glaive" .. suffix .. " | battleaxe" .. suffix,
    }
    local bodies
    local body_chance

    if branch == branches.BRANCH_GEHENNA then
        monsters[5] = "fire giant zombie w:3 / fire giant skeleton w:3 / " ..
            "fire dragon zombie w:2 / fire dragon skeleton w:2"
        monsters[6] = "flayed ghost"
        bodies = "fire giant corpse / fire giant skeleton / " ..
            "fire dragon corpse / fire dragon skeleton"
        body_chance = 40
    elseif branch == branches.BRANCH_COCYTUS then
        monsters[5] = "hydra zombie w:3 / hydra simulacrum w:3 / " ..
            "alligator snapping turtle zombie w:2 / " ..
            "alligator snapping turtle skeleton w:2"
        monsters[6] = "freezing wraith w:7 / bog body w:3"
        bodies = "frost giant corpse / frost giant skeleton / " ..
            "ice dragon corpse / ice dragon skeleton / " ..
            "alligator snapping turtle corpse / " ..
            "alligator snapping turtle skeleton / hydra corpse / " ..
            "hydra skeleton"
        body_chance = 40
    elseif branch == branches.BRANCH_DIS then
        monsters[5] = "iron troll zombie w:2 / iron troll skeleton w:2 / " ..
            "iron dragon zombie w:3 / iron dragon skeleton w:3"
        monsters[6] = "ancient champion w:7 / phantasmal warrior w:3"
        bodies = "iron dragon corpse / iron dragon skeleton / " ..
            "iron troll corpse / iron troll skeleton"
        body_chance = 40
    elseif branch == branches.BRANCH_TARTARUS or
        branch == branches.BRANCH_CRYPT then
        monsters[5] = "eidolon w:6 / jiangshi w:6"
        monsters[6] = "mummy priest w:2 / revenant w:6"
        bodies = "shadow dragon corpse / base draconian corpse / " ..
            "dire elephant corpse"
        body_chance = 33
    else
        monsters[5] = "necromancer w:5 / deep elf death mage w:5"
        monsters[6] = "shadow dragon"
        bodies = "any corpse / any skeleton"
        body_chance = 33
    end

    if depth > 27 then
        monsters[7] = "reaper w:16 / bone dragon w:4"
    end

    return monsters, bodies, body_chance
end

-- The leader becomes an ancient lich lottery beyond the source depth
-- threshold; the chance rises from zero to certain over five levels.
local function leader(api, depth)
    if depth > 24 or api:chance(depth - 20, 5) then
        return "ancient lich / dread lich"
    end

    return "lich"
end

-- Emit corpse substitutions after the ordinary monster recipe, then attach
-- the single delayed-decay intent to the resulting corpse glyphs.
local function fill_morgue(api)
    local branch = api:branch_id()
    local depth = api:absolute_depth()
    local monsters, bodies, chance = roster(branch, depth)

    fill.room(api, table.concat(monsters, " / "), leader(api, depth), true)

    if branch == branches.BRANCH_DEPTHS or
        branch == branches.BRANCH_CRYPT then
        api:emit(directives.KITEM, "2 = randbook disc:necromancy")
    else
        api:emit(directives.NSUBST, "1. = 1:})]>.")
    end

    api:emit(directives.SUBST,
        ". = .:" .. (100 - chance) .. " _:" .. chance)
    api:emit(directives.SUBST,
        "1 = 1:" .. (100 - chance) .. " !:" .. chance)
    api:emit(directives.KMONS,
        "! = " .. table.concat(monsters, " / ", 1, 6))
    api:emit(directives.KFEAT, "_ = .")
    api:record(effects.DELAYED_DECAY, {
        glyph = "!_",
        alternatives = bodies,
    })
end

room.fill = fill_morgue

return room
