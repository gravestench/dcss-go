-- Named DES marker calls and saved link fields are shared by generation,
-- travel, restore validation, and modded transporter maps.
local transporter = {
    SOURCE_CALL = "lua:transp_loc",
    DESTINATION_CALL = "lua:transp_dest_loc",
    DESTINATION_X = "transporter_destination_x",
    DESTINATION_Y = "transporter_destination_y",
}

return transporter
