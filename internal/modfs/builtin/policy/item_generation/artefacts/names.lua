local streams = require("constants.rng_streams")
local names = {}

-- Source: crawl-ref/source/item-name.cc:2400-2469.
local vowels = "aeiouaeiouaeiouy  "
local consonants = "bcdfghjklmnpqrstvwxzcdfghlmnrstlmnrst"
local consonant_pairs = {
    "kl", "gr", "cl", "cr", "fr", "pr", "tr", "tw", "br", "pl",
    "bl", "str", "shr", "thr", "sm", "sh", "ch", "th", "ph",
    "pn", "kh", "gh", "mn", "ps", "st", "sk", "sch", "ts",
    "cs", "xt", "nt", "ll", "rr", "ss", "wk", "wn", "ng",
    "cw", "mp", "ck", "nk", "dd", "tt", "bb", "pp", "nn",
    "mm", "kk", "gg", "ff", "pt", "tz", "dgh", "rgh",
    "rph", "rch", "cz", "xk", "zx", "xz", "cv", "vv",
    "nl", "rh", "dw", "nw", "khl",
}

local consonant_lookup = {}

for char in consonants:gmatch(".") do
    consonant_lookup[char] = true
end

local function seeded_random(seed)
    local state = seed

    return function(bound)
        -- A local stream keeps cosmetic syllable draws from perturbing
        -- later item-generation decisions.
        state = (state * 1664525 + 1013904223) % 4294967296

        return state % bound
    end
end

local function choice(random, letters)
    local index = random(#letters) + 1

    return letters:sub(index, index)
end

local function consonant_pair(random, beginning, ending)
    local first = 1
    local last = 67

    if beginning then
        last = 27
    elseif ending then
        first = 15
        last = 56
    end

    return consonant_pairs[first + random(last - first + 1)]
end

local function next_vowel(random, name, length)
    local vowel = choice(random, vowels)
    local previous = name:sub(-1)
    local penultimate = name:sub(-2, -2)

    if vowel == " " then
        if length < 7 or #name <= 2 or #name >= length - 3 or
            previous == " " or penultimate == " " or
            (consonant_lookup[previous] and
                consonant_lookup[penultimate]) then
            return nil
        end
    elseif vowel == previous and
        (vowel == "y" or vowel == "i" or random(5) <= 1) then
        return nil
    end

    return vowel
end

local function next_consonant(random, name, length)
    local beginning = name == "" or name:sub(-1) == " "
    local ending = #name >= length - 2

    if (length > 3 or name ~= "") and
        random(7) <= 1 and
        (not beginning or not ending) then
        return consonant_pair(random, beginning, ending)
    end

    return choice(random, consonants)
end

local function word(random)
    -- Source: crawl-ref/source/item-name.cc:2224-2396. The source uses
    -- a game-seed subgenerator; this port uses an item-local seed.
    local length = 3 + random(5)

    if random(5) == 0 then
        length = length + random(6)
    else
        length = length + 1
    end

    local name = ""
    local has_space = false

    for _ = 1, 150 do
        if #name >= length then
            break
        end

        local previous = name:sub(-1)
        local penultimate = name:sub(-2, -2)
        local added

        if name == "" or previous == " " then
            added = string.char(string.byte("a") + random(26))
        elseif not has_space and #name > 5 and
            #name < length - 4 and random(5) ~= 0 then
            added = " "
        elseif consonant_lookup[previous] or
            (#name > 1 and not consonant_lookup[previous] and
                consonant_lookup[penultimate] and random(5) <= 1) then
            added = next_vowel(random, name, length)
        else
            added = next_consonant(random, name, length)

            if #added > 2 then
                length = length + #added - 2
            end
        end

        if added then
            name = name .. added
            has_space = has_space or added == " "
        end
    end

    local last = name:sub(-1)

    if last ~= "" and last ~= " " and last ~= "y" and
        not consonant_lookup[last] and
        (#name < length or
            (length < 8 and random(3) ~= 0)) then
        name = name .. choice(random, consonants)
    end

    name = name:gsub("%s+$", "")

    if #name < 4 then
        name = "plog"
    end

    return (name:gsub("(%f[%a]%a)", string.upper))
end

function names.generate(ctx, definition)
    local seed = ctx:random(streams.ITEM_GENERATION, 2147483647)
    local random = seeded_random(seed)
    local title = word(random)
    local full_name

    if random(3) == 0 then
        full_name = definition.name .. " of " .. title
    else
        full_name = definition.name .. " \"" .. title .. "\""
    end

    return full_name, definition.name, seed
end

return names
