local implicit = {}

implicit.items = {
    ["$"] = "random_gold",
    ["%"] = "random_item",
    ["*"] = "good_item",
    ["|"] = "superb_item",
    d = "item_array_1",
    e = "item_array_2",
    f = "item_array_3",
    g = "item_array_4",
    h = "item_array_5",
    i = "item_array_6",
    j = "item_array_7",
    k = "item_array_8",
}

implicit.monsters = {
    ["0"] = "random_monster",
    ["1"] = "monster_array_1",
    ["2"] = "monster_array_2",
    ["3"] = "monster_array_3",
    ["4"] = "monster_array_4",
    ["5"] = "monster_array_5",
    ["6"] = "monster_array_6",
    ["7"] = "monster_array_7",
    ["8"] = "super_out_of_depth_monster",
    ["9"] = "moderate_out_of_depth_monster",
}

return implicit
