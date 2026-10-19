-- Example: Only letters with enough stock for a five-item shop enter the candidate set.
local content = require("policy.generation.vaults.shop.alphabet_content")
local directives = require("constants.vault_directives")

local handler = {}

-- Only letters with enough stock for a five-item shop enter the candidate set.
local function available_letters()
    local letters = {}

    for byte = string.byte("A"), string.byte("Z") do
        local letter = string.char(byte)

        -- The source counts one generic item in addition to the list.
        if #content.items[letter] + 1 >= 5 then
            letters[#letters + 1] = letter
        end
    end

    return letters
end

local letters = available_letters()

-- A rare N draw uses Nicolae; other initials transform a generated owner name.
local function owner_name(api, letter)
    if letter == "N" and api:one_in(20) then
        return "Nicolae"
    end

    local random_name = api:random_name():lower():gsub("%s+", "")

    return letter .. random_name:sub(2)
end

-- Pick one eligible initial, reserve its unique tag, then draw stock from that letter's catalog.
local function configure_alphabet_shop(api)
    if api:validating() then
        return
    end

    local letter = api:random_from(letters)
    local item_list = content.items[letter]
    local maximum = math.min(15, #item_list)
    local extra = maximum > 4 and api:roll(maximum - 4) or 0
    local count = math.min(#item_list, 5 + extra)
    local inventory = api:subset(item_list, count)
    local owner = owner_name(api, letter)

    api:emit(directives.TAGS, "uniq_alphashops_" .. letter)
    api:emit(directives.KFEAT,
        "s = general shop name:" .. owner .. " " ..
        content.names[letter] .. " count:" .. count ..
        " use_all ; " .. table.concat(inventory, " | "))
end

handler.configure_alphabet_shop = configure_alphabet_shop

return handler
