local catalog = require("policy.catalog")

local goblin_spec

for _, spec in ipairs(require("data.monster_weapons").primary) do
    if spec.monster_id == "MONS_GOBLIN" then
        goblin_spec = spec

        break
    end
end

local gear = {}

local function draw(ctx, bound)
    return ctx:random("monster_gear", bound)
end

local function weighted(ctx, choices)
    local total = 0

    for _, choice in ipairs(choices) do
        if choice.weight <= 0 or choice.id == "" then
            error("invalid weighted monster gear choice")
        end

        total = total + choice.weight
    end

    local choice = draw(ctx, total)

    for _, row in ipairs(choices) do
        if choice < row.weight then
            return row.id == "NUM_WEAPONS" and "" or row.id
        end

        choice = choice - row.weight
    end

    error("weighted monster gear failed to select")
end

local function nice_plusses(ctx, depth)
    local plus = 0

    -- The source alternates an increment and stop draw up to four times.
    for _ = 1, 4 do
        plus = plus + draw(ctx, 3)

        if draw(ctx, 425) > 35 + depth then
            break
        end
    end

    return plus
end

local function ordinary_brand(ctx, weights)
    local total = 0

    for _, row in ipairs(weights) do
        total = total + row.weight
    end

    if total == 0 then
        return "SPWPN_NORMAL"
    end

    local choice = draw(ctx, total)

    for _, row in ipairs(weights) do
        if choice < row.weight then
            return row.brand_id
        end

        choice = choice - row.weight
    end

    error("ordinary weapon brand table failed to select")
end

local supported_weapon = {
    WPN_DAGGER = true,
    WPN_CLUB = true,
    WPN_SHORT_SWORD = true,
    WPN_WHIP = true,
    WPN_SLING = true,
}

local function quality(ctx, kind_id, depth)
    if not supported_weapon[kind_id] then
        error("unsupported ordinary weapon " .. tostring(kind_id))
    end

    local definition = catalog.get("items", kind_id)

    if definition.class ~= "OBJ_WEAPONS" or not definition.weapon then
        error("missing ordinary weapon properties " .. kind_id)
    end

    local quality_roll = draw(ctx, 200)

    if quality_roll >= 51 + depth or kind_id == "WPN_CLUB" then
        return { plus = 0, ego = "" }
    end

    local brand_roll = draw(ctx, 300)
    local brand = "SPWPN_NORMAL"

    if brand_roll < 101 + depth then
        brand = ordinary_brand(ctx, definition.weapon.brand_weights or {})
    end

    local plus = nice_plusses(ctx, depth)

    if brand == "SPWPN_NORMAL" and plus < 3 then
        plus = 0
    end

    return {
        plus = plus,
        ego = brand == "SPWPN_NORMAL" and "" or brand,
    }
end

local function goblin_weapon(ctx, depth, melee_only)
    if not goblin_spec or goblin_spec.plus.odds ~= 0 or goblin_spec.good_chance ~= 0 then
        error("unsupported goblin weapon specification")
    end

    local kind_id = weighted(ctx, goblin_spec.weapons)

    if kind_id == "" then
        error("goblin weapon table chose no item")
    end

    -- _apply_weapon_spec's preliminary plusses are discarded by
    -- make_mons_weapon, including before a sling override.
    nice_plusses(ctx, depth)

    if not melee_only and draw(ctx, 12) == 0 and depth > 0 then
        kind_id = "WPN_SLING"
    end

    return {
        kind_id = kind_id,
        quality = quality(ctx, kind_id, depth),
    }
end

local kobold_weapons = {
    "WPN_DAGGER",
    "WPN_DAGGER",
    "WPN_SHORT_SWORD",
    "WPN_SHORT_SWORD",
    "WPN_CLUB",
    "WPN_WHIP",
}

local function kobold_ammunition(ctx, depth)
    -- one_chance_in is evaluated before the depth condition, including D:1.
    if draw(ctx, 10) == 0 and depth > 1 then
        return {
            kind_id = "MI_DART",
            quantity = 2 + draw(ctx, 7),
            ego = "poisoned",
        }
    end

    if draw(ctx, 5) >= 2 then
        return nil
    end

    return {
        kind_id = "MI_STONE",
        quantity = 1 + draw(ctx, 5),
        ego = "",
    }
end

function gear.loadout(ctx, monster_id, depth)
    if monster_id == "MONS_GOBLIN" then
        local primary = goblin_weapon(ctx, depth, false)
        local loadout = { primary = primary }

        if primary.kind_id == "WPN_SLING" then
            loadout.alternate = goblin_weapon(ctx, depth, true)
        end

        return loadout
    end

    if monster_id == "MONS_KOBOLD" then
        local kind_id = kobold_weapons[draw(ctx, #kobold_weapons) + 1]

        return {
            primary = {
                kind_id = kind_id,
                quality = quality(ctx, kind_id, depth),
            },
            ammunition = kobold_ammunition(ctx, depth),
        }
    end

    return nil
end

return gear
