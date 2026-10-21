-- Source make_name supplies generated Pan lords, shops, scrolls, and
-- artefacts. This module currently implements its ordinary Pan lord mode;
-- later modes can share the same letter and cluster choices.
local names = {}

local consonants = "bcdfghjklmnpqrstvwxzcdfghlmnrstlmnrst"
local vowels = "aeiouaeiouaeiouy  "
local consonant_letters = "bcdfghjklmnpqrstvwxz"

-- The source uses different consonant clusters at word ends and middles.
-- We retain the complete ordered table so each range keeps its weights.
local clusters = {
    -- Start or middle only.
    "kl", "gr", "cl", "cr", "fr",
    "pr", "tr", "tw", "br", "pl",
    "bl", "str", "shr", "thr",

    -- Start, middle, or end.
    "sm", "sh", "ch", "th", "ph",
    "pn", "kh", "gh", "mn", "ps",
    "st", "sk", "sch",

    -- Middle or end only.
    "ts", "cs", "xt", "nt", "ll",
    "rr", "ss", "wk", "wn", "ng",
    "cw", "mp", "ck", "nk", "dd",
    "tt", "bb", "pp", "nn", "mm",
    "kk", "gg", "ff", "pt", "tz",
    "dgh", "rgh", "rph", "rch",

    -- Middle only.
    "cz", "xk", "zx", "xz", "cv",
    "vv", "nl", "rh", "dw", "nw",
    "khl",
}

-- In Crawl's phonetics, y behaves as a vowel. This determines when the
-- next draw selects from the vowel table rather than the consonant table.
local function is_consonant(letter)
    return consonant_letters:find(letter, 1, true) ~= nil
end

-- Draw one character from the source's deliberately weighted alphabet.
local function letter(ctx, stream, alphabet)
    local index = ctx:random(stream, #alphabet) + 1

    return alphabet:sub(index, index)
end

-- Choose the source cluster range for a word position. A cluster may have
-- three letters, so the target length grows to avoid truncating its ending.
local function cluster(ctx, stream, beginning, ending)
    local first = 1
    local last = #clusters

    if beginning then
        last = 27
    elseif ending then
        first = 15
        last = 56
    end

    local index = first + ctx:random(stream, last - first + 1)

    return clusters[index]
end

-- A capture contains one letter after a space. Keep the space while
-- capitalizing that word's first letter in the finished display name.
local function capitalize_word(character)
    return " " .. character:upper()
end

-- Make one ordinary DCSS name. The source derives a private RNG from one
-- seed; this engine uses its named caller stream for the same ordered draws.
-- The finished name is saved by its owner and never regenerated on restore.
function names.generate(ctx, stream)
    local length = 3 + ctx:random(stream, 5)

    if ctx:random(stream, 5) == 0 then
        length = length + ctx:random(stream, 6)
    else
        length = length + 1
    end

    local name = ""
    local has_space = false

    -- Rejected vowels and spaces still consume draws. The 150-attempt cap
    -- prevents an unlucky stream from getting stuck on unsuitable letters.
    for _ = 1, 150 do
        if #name >= length then
            break
        end

        local previous = name:sub(-1)
        local penultimate = name:sub(-2, -2)
        local next_piece

        if name == "" or previous == " " then
            next_piece = string.char(string.byte("a") +
                ctx:random(stream, 26))
        elseif not has_space and #name > 5 and #name < length - 4 and
            ctx:random(stream, 5) ~= 0 then
            next_piece = " "
        elseif is_consonant(previous) or
            (#name > 1 and not is_consonant(previous) and
                is_consonant(penultimate) and
                ctx:random(stream, 5) <= 1) then
            local vowel = letter(ctx, stream, vowels)
            local invalid_space = vowel == " " and
                (length < 7 or #name <= 2 or #name >= length - 3 or
                    previous == " " or penultimate == " " or
                    (#name > 2 and is_consonant(previous) and
                        is_consonant(penultimate)))
            local repeated_vowel = vowel ~= " " and #name > 1 and
                vowel == previous and
                (vowel == "y" or vowel == "i" or
                    ctx:random(stream, 5) <= 1)

            if not invalid_space and not repeated_vowel then
                next_piece = vowel
            end
        else
            local beginning = name == "" or previous == " "
            local ending = #name >= length - 2

            if (length > 3 or name ~= "") and
                ctx:random(stream, 7) <= 1 and
                (not beginning or not ending) then
                next_piece = cluster(ctx, stream, beginning, ending)
                length = length + #next_piece - 2
            else
                next_piece = letter(ctx, stream, consonants)
            end
        end

        if next_piece then
            name = name .. next_piece

            if name:sub(-1) == " " then
                has_space = true
            end
        end
    end

    local last = name:sub(-1)

    if name ~= "" and last ~= " " and last ~= "y" and
        not is_consonant(last) and
        (#name < length or
            (length < 8 and ctx:random(stream, 3) ~= 0)) then
        name = name .. letter(ctx, stream, consonants)
    end

    name = name:gsub("%s+$", "")

    if #name < 4 then
        name = "plog"
    end

    -- Capitalize each word only after all source letter and space draws.
    name = name:gsub("^%l", string.upper)
    name = name:gsub(" (%l)", capitalize_word)

    return name
end

return names
