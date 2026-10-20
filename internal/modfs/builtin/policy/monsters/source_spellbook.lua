-- Theory of operation: DES spells: text describes a monster's spell slots.
-- The authored text stays on the ECS vault override for saves; this pure
-- reader turns it into the same slot table used by catalog spellbooks.
local spells = require("ids.spells")
local flags = require("constants.monster_spell_flags")
local empty = require("constants.vault_spell_override")
local effects = require("policy.combat.monster_spells")

local source_spellbook = {}

local source_flags = {
    emergency = flags.EMERGENCY,
    natural = flags.NATURAL,
    magical = flags.MAGICAL,
    wizard = flags.WIZARD,
    priest = flags.PRIEST,
    vocal = flags.VOCAL,
    breath = flags.BREATH,
    instant = flags.INSTANT,
    noisy = flags.NOISY,
    ["short range"] = flags.SHORT_RANGE,
    ["long range"] = flags.LONG_RANGE,
}

local type_flags = {
    [flags.NATURAL] = true,
    [flags.MAGICAL] = true,
    [flags.WIZARD] = true,
    [flags.PRIEST] = true,
    [flags.VOCAL] = true,
}

-- DCSS spells: accepts these spell-free tokens. In a mixed book they have
-- zero frequency, so omitting those slots keeps the same weighted draw.
local function empty_slot(text)
    local name = text:match("^%s*(.-)%s*$"):lower():gsub("_", " ")

    return name == empty.EMPTY_BOOK or name == empty.NONE or
        name == empty.NO_SPELL
end

-- Source names use underscores and human spelling, while catalogs own the
-- stable SPELL_* ID. Require a real monster effect before admitting a slot.
local function spell_id(name)
    local key = "SPELL_" .. name:upper():gsub("[^A-Z0-9]+", "_")
    local id = spells[key]
    local effect = effects.effect(id)

    if type(effect.plan) ~= "function" or
        type(effect.resolve) ~= "function" then
        error("monster spell " .. name .. " lacks a plan and resolver")
    end

    return id
end

-- A source slot may specify its frequency and independent casting flags.
-- DCSS defaults a slot without a casting type to magical.
local function slot(text)
    local parts = {}

    for part in (text .. "."):gmatch("(.-)%.") do
        parts[#parts + 1] = part:match("^%s*(.-)%s*$")
    end

    if parts[1] == "" then
        error("monster spell slot has no name")
    end

    local frequency = 30

    if parts[2] then
        frequency = tonumber(parts[2])
    end

    if not frequency or frequency < 1 or frequency % 1 ~= 0 then
        error("invalid monster spell frequency in " .. text)
    end

    local selected_flags = {}
    local has_type = false

    for index = 3, #parts do
        local source = parts[index]:lower():gsub("_", " ")
        local flag = source_flags[source]

        if not flag then
            error("unknown monster spell flag " .. parts[index])
        end

        selected_flags[#selected_flags + 1] = flag
        has_type = has_type or type_flags[flag] or false
    end

    if not has_type then
        selected_flags[#selected_flags + 1] = flags.MAGICAL
    end

    return {
        spell_id = spell_id(parts[1]),
        frequency = frequency,
        flags = selected_flags,
    }
end

-- Semicolons separate slots within one spells: book. A lone dot suppresses
-- the species' normal spellbook, matching the existing DES empty sentinel.
function source_spellbook.parse(text)
    if type(text) ~= "string" or text == "" then
        error("monster spellbook needs source text")
    end

    if empty_slot(text) then
        return nil
    end

    local slots = {}

    for part in (text .. ";"):gmatch("(.-);") do
        if part:match("^%s*$") then
            error("monster spellbook has an empty slot")
        end

        if not empty_slot(part) then
            slots[#slots + 1] = slot(part)
        end
    end

    return #slots > 0 and { slots = slots } or nil
end

return source_spellbook
