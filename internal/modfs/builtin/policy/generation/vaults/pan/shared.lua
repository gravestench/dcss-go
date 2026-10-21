-- Theory of operation: Pandemonium maps retain their source DES geometry.
-- These methods replace the shared inline Lua in pan.des. A DES hook invokes
-- one method at the same declaration position, so its emitted operations
-- participate in the ordinary vault pipeline and its seeded random stream.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local messages = require("constants.pan_messages")
local names = require("constants.vault_feature_names")
local rules = require("constants.vault_generation_rules")
local runes = require("constants.runes")
local tags = require("constants.vault_tags")

local shared = {}

local lure_tags = {
    [tags.PAN_FIXED_LURE_BOXES] = true,
    [tags.PAN_FIXED_LURE_DISCO] = true,
    [tags.PAN_FIXED_LURE_FROZEN] = true,
    [tags.PAN_FIXED_LURE_HELLIONS] = true,
    [tags.PAN_FIXED_LURE_PAIN] = true,
}

local lord_profiles = {
    mnoleg = {
        monsters = "large abomination w:200 / neqoxec w:200 / " ..
            "chaos spawn w:200 / cacodemon w:300 / tormentor / " ..
            "tentacled monstrosity w:5 / floating eye / golden eye band / " ..
            "eye of devastation / shining eye / very ugly thing band / " ..
            "demonspawn corrupter",
        floor_colour = "lightred",
        rock_colour = "yellow",
        floor_tile = "floor_nerves",
        rock_tile = "wall_zot_yellow",
        rune = "glowing rune of Zot",
    },
    lom_lobon = {
        monsters = "hellwing w:300 / sixfirhy w:100 / " ..
            "smoke demon w:300 / blizzard demon w:100 / green death w:200 / " ..
            "glowing orange brain / rakshasa / wizard / " ..
            "draconian annihilator / deep elf annihilator / titan w:5 / " ..
            "lich w:5 / demonspawn blood saint",
        floor_colour = "lightgrey",
        rock_colour = "white",
        floor_tile = "floor_rough_lightgray",
        rock_tile = "wall_hall_white",
        rune = "magical rune of Zot",
    },
    cerebov = {
        monsters = "efreet / orange demon / sun demon / ynoxinul / " ..
            "balrug / brimstone fiend w:1 / demonspawn warmonger w:1",
        floor_colour = "red",
        rock_colour = "red",
        floor_tile = "floor_volcanic",
        rock_tile = "wall_zot_red",
        rune = "fiery rune of Zot",
    },
    gloorx_vloq = {
        monsters = "skeleton w:400 / soul eater w:200 / " ..
            "lorocyproca w:100 / executioner w:300 / demonic crawler / " ..
            "shadow wraith / unseen horror / demonspawn black sun",
        floor_colour = "blue",
        rock_colour = "blue",
        floor_tile = "floor_grey_dirt",
        rock_tile = "wall_hall_darkgray",
        rune = "dark rune of Zot",
    },
}

-- A rune vault's marked cell usually becomes ordinary floor; the O and N
-- outcomes deliberately remain rare. Some maps also place a Pan lord on
-- whichever of those cells survives the substitution.
local function demonic_rune(api, glyph, place_lord)
    local ordinary = place_lord and glyph or "."

    api:emit(directives.SUBST, glyph .. " = " .. ordinary .. ":6 O:1 N:2")
    api:emit(directives.KITEM, "O = demonic rune of Zot")
    api:emit(directives.KFEAT, "N = exit_pandemonium")

    if place_lord then
        api:emit(directives.KMONS, glyph .. "ON = pandemonium lord")
    end
end

-- This variant has a P rune cell and may place its guarding lord.
function shared.rune_p_lord(api)
    demonic_rune(api, "P", true)
end

-- This variant has a P rune cell but no guaranteed guarding lord.
function shared.rune_p(api)
    demonic_rune(api, "P", false)
end

-- This variant uses an e rune cell in the source map.
function shared.rune_e(api)
    demonic_rune(api, "e", false)
end

-- This variant uses a g rune cell in the source map.
function shared.rune_g(api)
    demonic_rune(api, "g", false)
end

-- Shared lesser-lord vault content keys three monster request tiers and
-- a source return stair. The glyph group may include the < stair cell.
local function lord_vault_contents(api, anyglyph, commonglyph, greaterglyph)
    api:emit(directives.KMONS, anyglyph ..
        " = any demon w:76 / demonspawn black sun w:1 / " ..
        "demonspawn blood saint w:1 / demonspawn corrupter w:1 / " ..
        "demonspawn warmonger w:1")
    api:emit(directives.KMONS, commonglyph .. " = common demon")
    api:emit(directives.KMONS, greaterglyph ..
        " = greater demon w:36 / demonspawn black sun w:1 / " ..
        "demonspawn blood saint w:1 / demonspawn corrupter w:1 / " ..
        "demonspawn warmonger w:1")
    api:emit(directives.KFEAT, "< = {")
end

-- Ordinary A/B/C monster cells are shared by most lesser-lord maps.
function shared.lord_abc(api)
    lord_vault_contents(api, "A", "B", "C")
end

-- A greater demon can also stand on the source map's return stair.
function shared.lord_abc_stair(api)
    lord_vault_contents(api, "A", "B", "C<")
end

-- A common demon can also stand on the source map's return stair.
function shared.lord_ab_stair_c(api)
    lord_vault_contents(api, "A", "B<", "C")
end

-- Each named lord changes the surrounding region's ambient monsters and
-- palette as well as placing the matching rune on O. These rules belong to
-- the selected level, not to the individual monster entity.
local function lord_setup(api, profile)
    api:record(effects.GENERATION_RULE, {
        rule = rules.RANDOM_MONSTER_LIST,
        expression = profile.monsters,
    })
    api:emit(directives.LFLOORCOL, profile.floor_colour)
    api:emit(directives.LROCKCOL, profile.rock_colour)
    api:emit(directives.LFLOORTILE, profile.floor_tile)
    api:emit(directives.LROCKTILE, profile.rock_tile)
    api:emit(directives.KITEM, "O = " .. profile.rune)
end

-- Mnoleg's region has the glowing rune and its mutation themed population.
function shared.mnoleg(api)
    lord_setup(api, lord_profiles.mnoleg)
end

-- Lom Lobon's region has the magical rune and its cold caster population.
function shared.lom_lobon(api)
    lord_setup(api, lord_profiles.lom_lobon)
end

-- Cerebov's region has the fiery rune and its fire themed population.
function shared.cerebov(api)
    lord_setup(api, lord_profiles.cerebov)
end

-- Gloorx Vloq's region has the dark rune and its death themed population.
function shared.gloorx_vloq(api)
    lord_setup(api, lord_profiles.gloorx_vloq)
end

-- All five serial sets share an iron grate keyed by m. Their distinguishing
-- tags remain in DES, where the catalog can see them before map selection.
function shared.serial_grate(api)
    api:emit(directives.KFEAT, "m = iron_grate")
end

-- The direct portal becomes more likely as the player takes Pan runes.
-- The alternative is literal floor, so a failed exit roll does not leave
-- a fake interactive feature on the generated level.
function shared.exit_portal(api)
    local exit_chance = 5 + 3 * api:pan_rune_count()
    local floor_chance = 100 - exit_chance

    api:emit(directives.KFEAT,
        "O = exit_pandemonium w:" .. exit_chance ..
        " / floor w:" .. floor_chance)
end

-- The Abyss route starts at a larger chance than the direct return and
-- also grows with saved Pan runes, matching the source weighted feature.
function shared.abyss_portal(api)
    local exit_chance = 25 + 10 * api:pan_rune_count()
    local floor_chance = 100 - exit_chance

    api:emit(directives.KFEAT,
        "O = exit_through_abyss w:" .. exit_chance ..
        " / floor w:" .. floor_chance)
end

-- The source controller requests each fixed site by its rune or lure tag.
-- A lure has the same geometry and monsters but cannot award a second real
-- rune; an untagged request follows source map-parameter fallback to real.
function shared.fixed_rune_or_lure(api)
    local item = "demonic rune of zot"

    if lure_tags[api:map_tag()] then
        item = "superb_item / demonic rune of zot mimic"
    end

    api:emit(directives.KITEM, "O = " .. item)
end

-- The source fixed-site epilogue warns only while the real demonic rune is
-- still missing. The placement tag may have selected a lure; source gives
-- the same warning there to keep the decoy convincing.
function shared.fixed_rune_epilogue(api)
    if not api:has_rune(runes.DEMONIC) then
        api:record(effects.ENTRY_MESSAGE, {
            text = messages.DEMONIC_RUNE_WARNING,
        })
    end
end

-- The source disco hall uses a granite statue as the ball's terrain kind.
-- Preserve its special inspection name without changing that terrain.
function shared.disco_ball_name(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.STRANGELY_GLOWING_BALL,
    })
end

-- Source epilogues run when entering a named lord's realm. A typed level
-- record keeps the message, note, and milestone together until the travel
-- path can present them without running generation again after a restore.
local function lord_epilogue(api, lord)
    local note = "Entered the realm of " .. lord.name .. "."
    local text = lord.warning .. "\n" ..
        "The mighty Pandemonium lord " .. lord.name .. " resides here.\n" ..
        "They guard the " .. lord.rune .. " rune of Zot."

    api:record(effects.ENTRY_MESSAGE, {
        text = text,
        note = note,
        milestone = "entered the realm of " .. lord.name .. ".",
    })
end

-- Mnoleg's glowing realm announces its lord and rune on first entry.
function shared.mnoleg_epilogue(api)
    lord_epilogue(api, messages.LORDS.MNOLEG)
end

-- Lom Lobon's magical realm announces its lord and rune on first entry.
function shared.lom_lobon_epilogue(api)
    lord_epilogue(api, messages.LORDS.LOM_LOBON)
end

-- Cerebov's fiery realm announces its lord and rune on first entry.
function shared.cerebov_epilogue(api)
    lord_epilogue(api, messages.LORDS.CEREBOV)
end

-- Gloorx Vloq's dark realm announces its lord and rune on first entry.
function shared.gloorx_vloq_epilogue(api)
    lord_epilogue(api, messages.LORDS.GLOORX_VLOQ)
end

return shared
