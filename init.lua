--  /$$$$$$$$                                           /$$    /$$                          /$$
-- | $$_____/                                          | $$   | $$                         | $$
-- | $$    /$$$$$$  /$$$$$$$   /$$$$$$$ /$$   /$$      | $$   | $$ /$$$$$$  /$$$$$$$   /$$$$$$$
-- | $$$$$|____  $$| $$__  $$ /$$_____/| $$  | $$      |  $$ / $$//$$__  $$| $$__  $$ /$$__  $$
-- | $$__/ /$$$$$$$| $$  \ $$| $$      | $$  | $$       \  $$ $$/| $$$$$$$$| $$  \ $$| $$  | $$
-- | $$   /$$__  $$| $$  | $$| $$      | $$  | $$        \  $$$/ | $$_____/| $$  | $$| $$  | $$
-- | $$  |  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$$         \  $/  |  $$$$$$$| $$  | $$|  $$$$$$$
-- |__/   \_______/|__/  |__/ \_______/ \____  $$          \_/    \_______/|__/  |__/ \_______/
--                                      /$$  | $$
--                                     |  $$$$$$/
--                                      \______/
--
-- A full-featured, fully-integrated vendor mod for Minetest


local display_node = (minetest.setting_get("fancy_vend_display_node") or "default:obsidian_glass")
local max_logs = (tonumber(minetest.setting_get("fancy_vend_log_max")) or 40)
local autorotate_speed = (tonumber(minetest.setting_get("fancy_vend_autorotate_speed")) or 1)

local drop_vendor = "fancy_vend:player_vendor"

-- Register a copy of the display node with no drops to make players separating the obsidian glass with something like a piston a non-issue.
local display_node_def = table.copy(minetest.registered_nodes[display_node])
display_node_def.drop = ""
display_node_def.groups.not_in_creative_inventory = 1
minetest.register_node("fancy_vend:display_node", display_node_def)
minetest.register_craftitem("fancy_vend:inactive",{inventory_image = "inactive.png",})

minetest.register_privilege("admin_vendor", "Enables the user to set regular vendors to admin vendors.")

local function bts(bool)
    if bool == false then
        return "false"
    elseif bool == true then
        return "true"
    else
        return bool
    end
end

local function stb(str)
    if str == "false" then
        return false
    elseif str == "true" then
        return true
    else
        return str
    end
end

table.length = function(table)
    local length
    for i in pairs(table) do
        length = length + 1
    end
    return length
end

local function send_message(pos, channel, msg)
    if channel and channel ~= "" then
        digilines.receptor_send(pos, digilines.rules.default, channel, msg)
    end
end

-- Awards
if minetest.get_modpath("awards") then
    awards.register_achievement("fancy_vend_getting_fancy",{
        title = "Getting Fancy",
        description = "Craft a fancy vendor.",
        trigger = {
            type = "craft",
            item = drop_vendor,
            target = 1,
        },
        icon = "player_vend_front.png^awards_level1.png",
    })

    awards.register_achievement("fancy_vend_wizard",{
        title = "You're a Wizard",
        description = "Craft a copy tool.",
        trigger = {
            type = "craft",
            item = "fancy_vend:copy_tool",
            target = 1,
        },
        icon = "copier.png",
    })


    awards.register_achievement("fancy_vend_trader",{
        title = "Trader",
        description = "Configure a depositor.",
        icon = "player_depo_front.png",
    })
    awards.register_achievement("fancy_vend_seller",{
        title = "Seller",
        description = "Configure a vendor.",
        icon = "player_vend_front.png^awards_level2.png",
    })
    awards.register_achievement("fancy_vend_shop_keeper",{
        title = "Shop Keeper",
        description = "Configure 10 vendors or depositors.",
        icon = "player_vend_front.png^awards_level3.png",
    })
    awards.register_achievement("fancy_vend_merchant",{
        title = "Merchant",
        description = "Configure 25 vendors or depositors.",
        icon = "player_vend_front.png^awards_level4.png",
    })
    awards.register_achievement("fancy_vend_super_merchant",{
        title = "Super Merchant",
        description = "Configure 100 vendors or depositors. How do you even have this much stuff to sell?",
        icon = "player_vend_front.png^awards_level5.png",
    })
    awards.register_achievement("fancy_vend_god_merchant",{
        title = "God Merchant",
        description = "Configure 9001 vendors or depositors. Ok wot.",
        icon = "player_vend_front.png^awards_level6.png",
        secret = true, -- Oi. Cheater.
    })
end

local tmp = {}

minetest.register_entity("fancy_vend:display_item",{
    hp_max = 1,
    visual = "wielditem",
    visual_size = {x = 0.33, y = 0.33},
    collisionbox = {0, 0, 0, 0, 0, 0},
    physical = false,
    textures = {"air"},
    on_activate = function(self, staticdata)
        if tmp.nodename ~= nil and tmp.texture ~= nil then
            self.nodename = tmp.nodename
            tmp.nodename = nil
            self.texture = tmp.texture
            tmp.texture = nil
        else
            if staticdata ~= nil and staticdata ~= "" then
                local data = staticdata:split(';')
                if data and data[1] and data[2] then
                    self.nodename = data[1]
                    self.texture = data[2]
                end
            end
        end
        if self.texture ~= nil then
            self.object:set_properties({textures = {self.texture}})
        end
        self.object:set_properties({automatic_rotate = autorotate_speed})
    end,
    get_staticdata = function(self)
        if self.nodename ~= nil and self.texture ~= nil then
            return self.nodename .. ';' .. self.texture
        end
        return ""
    end,
})

local function remove_item(pos)
    local objs = nil
    objs = minetest.get_objects_inside_radius(pos, .5)
    if objs then
        for _, obj in ipairs(objs) do
            if obj and obj:get_luaentity() and obj:get_luaentity().name == "fancy_vend:display_item" then
                obj:remove()
            end
        end
    end
end

local function update_item(pos, node)
    pos.y = pos.y + 1
    remove_item(pos)
    if minetest.get_node(pos).name ~= "fancy_vend:display_node" then
        minetest.log("warning", "[fancy_vend]: Placing display item inside "..minetest.get_node(pos).name.." at "..minetest.pos_to_string(pos).." is not permitted, aborting")
        return
    end
    pos.y = pos.y - 1
    local meta = minetest.get_meta(pos)
    if meta:get_string("item") ~= "" then
        pos.y = pos.y + (12 / 16 + 0.11)
        tmp.nodename = node.name
        tmp.texture = ItemStack(meta:get_string("item")):get_name()
        local e = minetest.add_entity(pos,"fancy_vend:display_item")
        pos.y = pos.y - (12 / 16 + 0.11)
    end
end

-- ABM to refresh entities after clearobjects
minetest.register_abm({
    nodenames = {"fancy_vend:display_node"},
    interval = 60,
    chance = 1,
    action = function(pos, node, active_object_count, active_object_count_wider)
        local num

        num = #minetest.get_objects_inside_radius(pos, 0.5)
        pos.y = pos.y - 1

        if num > 0 then return end
        update_item(pos, node)
    end
})

local function set_vendor_settings(pos, SettingsDef)
    local meta = minetest.get_meta(pos)
    meta:set_string("settings", minetest.serialize(SettingsDef))
end

local function reset_vendor_settings(pos)
    local settings_default = {
        input_item = "", -- Don't change this unless you plan on setting this up to add this item to the inventories
        output_item = "", -- Don't change this unless you plan on setting this up to add this item to the inventories
        input_item_qty = 1,
        output_item_qty = 1,
        admin_vendor = false,
        depositor = false,
        currency_eject = false,
        accept_output_only = false,
        split_incoming_stacks = false,
        inactive_force = false,
        accept_worn_input = true,
        accept_worn_output = true,
        digiline_channel = "",
        co_sellers = "",
        banned_buyers = "",
    }
    set_vendor_settings(pos, settings_default)
    return settings_default
end

local function get_vendor_settings(pos)
    local meta = minetest.get_meta(pos)
    local settings = minetest.deserialize(meta:get_string("settings"))
    if not settings then
        return reset_vendor_settings(pos)
    else
        return settings
    end
end

local function can_buy_from_vendor(pos, player)
    local settings = get_vendor_settings(pos)
    local banned_buyers = string.split((settings.banned_buyers or ""),",")
    for i in pairs(banned_buyers) do
        if banned_buyers[i] == player:get_player_name() then
            return false
        end
    end
    return true
end

local function can_modify_vendor(pos, player)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local is_owner = false
    if meta:get_string("owner") == player:get_player_name() or minetest.check_player_privs(player, {protection_bypass=true}) then
        is_owner = true
    end
    return is_owner
end

local function can_dig_vendor(pos, player)
    local meta = minetest.get_meta(pos);
    local inv = meta:get_inventory()
    return inv:is_empty("main") and can_modify_vendor(pos, player)
end

local function can_access_vendor_inv(player, pos)
    local meta = minetest.get_meta(pos)
    if minetest.check_player_privs(player, {protection_bypass=true}) or meta:get_string("owner") == player:get_player_name() then return true end
    local settings = get_vendor_settings(pos)
    local co_sellers = string.split(settings.co_sellers,",")
    for i in pairs(co_sellers) do
        if co_sellers[i] == player:get_player_name() then
            return true
        end
    end
    return false
end

-- Inventory helpers:
local function inv_insert(inv, listname, itemstack, quantity, from_table, pos, input_eject)
    local stackmax = itemstack:get_stack_max()
    local stacks = {}
    local remaining_quantity = quantity

    -- Add the full stacks to the list
    while remaining_quantity > stackmax do
        table.insert(stacks, {name = itemstack:get_name(), count = stackmax})
        remaining_quantity = remaining_quantity - stackmax
    end
    -- Add the remaining stack to the list
    table.insert(stacks, {name = itemstack:get_name(), count = remaining_quantity})

    -- If tool add wears and metadatas, ignores if from_table = nil (eg, due to vendor beig admin vendor)
    if minetest.registered_tools[itemstack:get_name()] then
        for i in pairs(stacks) do
            local from_item_table = from_table[i].item:to_table()
            stacks[i].wear = from_item_table.wear
            stacks[i].metadata = from_item_table.metadata
        end
    end

    -- Add to inventory or eject to pipeworks (whichever is applicable)
    local output_tube_connected = false
    if input_eject and pos then
        local pos_under = vector.new(pos)
        pos_under.y = pos_under.y - 1
        local node_under = minetest.get_node(pos_under)
        if minetest.get_item_group(node_under.name, "tubedevice") > 0 then
            output_tube_connected = true
        end
    end
    for i in pairs(stacks) do
        if output_tube_connected and input_eject and pos then
            pipeworks.tube_inject_item(pos, pos, vector.new(0, -1, 0), stacks[i], minetest.get_meta(pos):get_string("owner"))
        else
            inv:add_item(listname, ItemStack(stacks[i]))
        end
    end
end

local function inv_remove(inv, listname, remove_table, itemstring, quantity)
    local count = 0
    for i in pairs(remove_table) do
        count = count + remove_table[i].item:get_count()
        inv:set_stack(listname, remove_table[i].id, nil)
    end
    -- Add back items if too many were taken
    if count > quantity then
        inv:add_item(listname, ItemStack({name = itemstring, count = count - quantity}))
    end
end

local function inv_contains_items(inv, listname, itemstring, quantity, ignore_wear)
    local minimum = quantity
    local get_items = {}
    local count = 0

    for i=1,inv:get_size(listname) do
        local stack = inv:get_stack(listname, i)
        if stack:get_name() == itemstring then
            if ignore_wear or (not minetest.registered_tools[itemstring] or stack:get_wear() == 0) then
                count = count + stack:get_count()
                table.insert(get_items, {id=i, item=stack})
                if count >= minimum then
                    return true, get_items
                end
            end
        end
    end
    return false
end

local function get_vendor_status(pos)
    local settings = get_vendor_settings(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    if settings.input_item == "" or settings.output_item == "" then
        return false, "unconfigured"
    elseif settings.inactive_force then
        return false, "inactive_force"
    elseif not minetest.check_player_privs(meta:get_string("owner"), {admin_vendor=true}) and settings.admin_vendor == true then
        return false, "no_privs"
    elseif not inv_contains_items(inv, "main", settings.output_item, settings.output_item_qty, settings.accept_worn_output) and not settings.admin_vendor then
        return false, "no_output"
    elseif not inv:room_for_item("main", ItemStack(settings.input_item.." "..settings.input_item_qty)) and not settings.admin_vendor then
        return false, "no_room"
    else
        return true
    end
end

local function make_inactive_string(errorcode)
    local status_str = ""
    if errorcode == "unconfigured" then
        status_str = status_str.." (unconfigured)"
    elseif errorcode == "inactive_force" then
        status_str = status_str.." (forced)"
    elseif errorcode == "no_output" then
        status_str = status_str.." (out of stock)"
    elseif errorcode == "no_room" then
        status_str = status_str.." (no room)"
    elseif errorcode == "no_privs" then
        status_str = status_str.." (seller has insufficient privilages)"
    end
    return status_str
end

-- adminstacks - inv insert issue
-- wear - invcheck and inv get and insert issue

local function run_inv_checks(pos, player, lots)
    local settings = get_vendor_settings(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local player_inv = player:get_inventory()

    local ct = {}

    -- Get input and output quantities after multiplying by lot count
    local output_qty = settings.output_item_qty * lots
    local input_qty = settings.input_item_qty * lots

    -- Perform inventory checks
    ct.player_has, ct.player_item_table = inv_contains_items(player_inv, "main", settings.input_item, input_qty, settings.accept_worn_input)
    ct.vendor_has, ct.vendor_item_table = inv_contains_items(inv, "main", settings.output_item, output_qty, settings.accept_worn_output)
    ct.player_fits = player_inv:room_for_item("main", ItemStack(settings.output_item.." "..output_qty))
    ct.vendor_fits = inv:room_for_item("main", ItemStack(settings.input_item.." "..input_qty))

    if ct.player_has and ct.vendor_has and ct.player_fits and ct.vendor_fits then
        ct.overall = true
    else
        ct.overall = false
    end

    return ct
end

local function get_max_lots(pos, player)
    local max = 0

    while run_inv_checks(pos, player, max).overall do
        max = max + 1
    end

    return max
end

local function make_purchase(pos, player, lots)
    if not can_buy_from_vendor(pos, player) then
        return false, "You cannot purchase from this vendor"
    end

    local settings = get_vendor_settings(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local player_inv = player:get_inventory()
    local status, errorcode = get_vendor_status(pos)

    if status then
        -- Get input and output quantities after multiplying by lot count
        local output_qty = settings.output_item_qty * lots
        local input_qty = settings.input_item_qty * lots

        -- Perform inventory checks
        local ct = run_inv_checks(pos, player, lots)

        if ct.player_has then
            if ct.player_fits then
                if settings.admin_vendor then
                    minetest.log("action", player:get_player_name().." trades "..settings.input_item_qty.." "..settings.input_item.." for "..settings.output_item_qty.." "..settings.output_item.." using vendor at "..minetest.pos_to_string(pos))

                    inv_remove(player_inv, "main", ct.player_item_table, settings.input_item, input_qty)
                    inv_insert(player_inv, "main", ItemStack(settings.output_item), output_qty, nil)

                    if minetest.get_modpath("digilines") then
                        send_message(pos, settings.digiline_channel, msg)
                    end

                    return true, "Trade successful"
                elseif ct.vendor_has then
                    if ct.vendor_fits then
                        minetest.log("action", player:get_player_name().." trades "..settings.input_item_qty.." "..settings.input_item.." for "..settings.output_item_qty.." "..settings.output_item.." using vendor at "..minetest.pos_to_string(pos))

                        inv_remove(inv, "main", ct.vendor_item_table, settings.output_item, output_qty)
                        inv_remove(player_inv, "main", ct.player_item_table, settings.input_item, input_qty)
                        inv_insert(player_inv, "main", ItemStack(settings.output_item), output_qty, ct.vendor_item_table)
                        inv_insert(inv, "main", ItemStack(settings.input_item), input_qty, ct.player_item_table, pos, (minetest.get_modpath("pipeworks") and settings.currency_eject))

                        return true, "Trade successful"
                    else
                        return false, "Vendor has insufficient space"
                    end
                else
                    return false, "Vendor has insufficient resources"
                end
            else
                return false, "You have insufficient space"
            end
        else
            return false, "You have insufficient funds"
        end
    else
        return false, "Vendor is inactive"..make_inactive_string(errorcode)
    end
end


local function get_vendor_buyer_fs(pos, player, lots)
    local base = "size[8,9]"..
        "label[0,0;Owner wants:]"..
        "label[0,1.25;for:]"..
        "button[0,2.7;2,1;buy;Buy]"..
        "label[2.8,2.9;lots.]"..
        "button[0,3.6;2,1;lot_fill;Fill lots to max.]"..
        "list[current_player;main;0,4.85;8,1;]"..
        "list[current_player;main;0,6.08;8,3;8]"..
        "listring[current_player;main]"..
        "field_close_on_enter[lot_count;false]"

    -- Add dynamic elements
    local settings = get_vendor_settings(pos)
    local meta = minetest.get_meta(pos)
    local status, errorcode = get_vendor_status(pos)

    local itemstuff =
    "item_image_button[0,0.4;1,1;"..settings.input_item..";ignore;]"..
    "label[0.9,0.6;"..settings.input_item_qty.." "..minetest.registered_items[settings.input_item].description.."]"..
    "item_image_button[0,1.7;1,1;"..settings.output_item..";ignore;]"..
    "label[0.9,1.9;"..settings.output_item_qty.." "..minetest.registered_items[settings.output_item].description.."]"

    local status_str
    if status then
        status_str = "active"
    else
        status_str = "inactive"..make_inactive_string(errorcode)
    end
    local status_fs =
    "label[4,0.4;Vendor status: "..status_str.."]"..
    "label[4,0.8;Message: "..meta:get_string("message").."]"..
    "label[4,0;Vendor owned by: "..meta:get_string("owner").."]"

    local setting_specific = ""
    if not settings.accept_worn_input then
        setting_specific = setting_specific.."label[4,1.6;Vendor will not accept worn tools.]"
    end
    if not settings.accept_worn_output then
        setting_specific = setting_specific.."label[4,1.2;Vendor will not sell worn tools.]"
    end

    local fields = "field[2.2,3.2;1,0.6;lot_count;;"..(lots or 1).."]"

    local fs = base..itemstuff..status_fs..setting_specific..fields
    return fs
end

local function get_vendor_settings_fs(pos)
    local base = "size[9,9]"..
        "label[2.8,0.5;Input item]"..
        "label[6.8,0.5;Output item]"..
        "image[0,1.3;1,1;debug_btn.png]"..
        "item_image_button[0,2.3;1,1;default:book;button_log;]"..
        "list[current_player;main;1,4.85;8,1;]"..
        "list[current_player;main;1,6.08;8,3;8]"..
        "listring[current_player;main]"

    -- Add dynamic elements
    local pos_str = pos.x..","..pos.y..","..pos.z
    local settings = get_vendor_settings(pos)

    if settings.admin_vendor then
        base = base.."item_image[0,0.3;1,1;default:chest]"
    else
        base = base.."item_image_button[0,0.3;1,1;default:chest;button_inv;]"
    end

    local inv =
        "list[nodemeta:"..pos_str..";wanted_item;1,0.3;1,1;]"..
        "list[nodemeta:"..pos_str..";given_item;5,0.3;1,1;]"..
        "listring[nodemeta:"..pos_str..";wanted_item]"..
        "listring[nodemeta:"..pos_str..";given_item]"

    local fields =
        "field[2.2,0.8;1,0.6;input_item_qty;;"..settings.input_item_qty.."]"..
        "field[6.2,0.8;1,0.6;output_item_qty;;"..settings.output_item_qty.."]"..
        "field[1.3,4.1;2.66,1;co_sellers;Co-Sellers:;"..settings.co_sellers.."]"..
        "field[3.86,4.1;2.66,1;banned_buyers;Banned Buyers:;"..settings.banned_buyers.."]"..
        "field_close_on_enter[input_item_qty;false]"..
        "field_close_on_enter[output_item_qty;false]"..
        "field_close_on_enter[co_sellers;false]"..
        "field_close_on_enter[banned_buyers;false]"

    local checkboxes =
        "checkbox[1,2.2;inactive_force;Force vendor into an inactive state.;"..bts(settings.inactive_force).."]"..
        "checkbox[1,2.6;depositor;Set this vendor to a Depositor.;"..bts(settings.depositor).."]"..
        "checkbox[1,3.0;accept_worn_output;Sell worn tools.;"..bts(settings.accept_worn_output).."]"..
        "checkbox[5,3.0;accept_worn_input;Buy worn tools.;"..bts(settings.accept_worn_input).."]"

    -- Admin vendor checkbox only if owner is admin
    local meta = minetest.get_meta(pos)
    if minetest.check_player_privs(meta:get_string("owner"), {admin_vendor=true}) or settings.admin_vendor then
        checkboxes = checkboxes..
            "checkbox[5,2.2;admin_vendor;Set vendor to an admin vendor.;"..bts(settings.admin_vendor).."]"
    end


    -- Optional dependancy specific elements
    if minetest.get_modpath("pipeworks") then
        checkboxes = checkboxes..
            "checkbox[1,1.3;currency_eject;Eject incomming currency.;"..bts(settings.currency_eject).."]"..
            "checkbox[5,1.3;accept_output_only;Accept for-sale item only.;"..bts(settings.accept_output_only).."]"..
            "checkbox[1,1.7;split_incoming_stacks;Split incomming stacks.;"..bts(settings.split_incoming_stacks).."]"
    end

    if minetest.get_modpath("digilines") then
        fields = fields..
            "field[6.41,4.1;2.66,1;digiline_channel;Digiline Channel:;"..settings.digiline_channel.."]"..
            "field_close_on_enter[digiline_channel;false]"
    end

    local fs = base..inv..fields..checkboxes
    return fs
end

local function get_vendor_default_fs(pos, player)
    local base = "size[16,11]"..
        "item_image[0,0.3;1,1;default:chest]"..
        "list[current_player;main;4,6.85;8,1;]"..
        "list[current_player;main;4,8.08;8,3;8]"..
        "listring[current_player;main]"..
        "button[1,6.85;3,1;inv_tovendor;All To Vendor]"..
        "button[12,6.85;3,1;inv_fromvendor;All From Vendor]"..
        "button[1,8.08;3,1;inv_output_tovendor;Output To Vendor]"..
        "button[12,8.08;3,1;inv_input_fromvendor;Input From Vendor]"


    -- Add dynamic elements
    local pos_str = pos.x..","..pos.y..","..pos.z
    local inv_lists =
        "list[nodemeta:"..pos_str..";main;1,0.3;15,6;]"..
        "listring[nodemeta:"..pos_str..";main]"

    local settings_btn = ""
    if can_modify_vendor(pos, player) then
        settings_btn =
        "image_button[0,1.3;1,1;debug_btn.png;button_settings;]"..
        "item_image_button[0,2.3;1,1;default:book;button_log;]"
    else
        settings_btn =
        "image[0,1.3;1,1;debug_btn.png]"..
        "item_image[0,2.3;1,1;default:book]"
    end

    local fs = base..inv_lists..settings_btn
    return fs
end


local function get_vendor_log_fs(pos)
    local base = "size[9,9]"..
        "image_button[0,1.3;1,1;debug_btn.png;button_settings;]"..
        "item_image[0,2.3;1,1;default:book]"

    -- Add dynamic elements
    local meta = minetest.get_meta(pos)
    local logs = minetest.deserialize(meta:get_string("log"))

    local settings = get_vendor_settings(pos)
    if settings.admin_vendor then
        base = base.."item_image[0,0.3;1,1;default:chest]"
    else
        base = base.."item_image_button[0,0.3;1,1;default:chest;button_inv;]"
    end

    if not logs then logs = {"Error loading logs",} end
    local logs_tl =
        "textlist[1,0.5;7.8,8.6;logs;"..table.concat(logs, ",").."]"..
        "label[1,0;Showing (up to "..max_logs..") recent log entries:]"

    local fs = base..logs_tl
    return fs
end


local function show_vendor_formspec(player, pos)
    local settings = get_vendor_settings(pos)
    if can_access_vendor_inv(player, pos) then
        local status, errorcode = get_vendor_status(pos)
        if ((not status and errorcode == "unconfigured") and can_modify_vendor(pos, player)) or settings.admin_vendor then
            minetest.show_formspec(player:get_player_name(), "fancy_vend:settings;"..minetest.pos_to_string(pos), get_vendor_settings_fs(pos))
        else
            minetest.show_formspec(player:get_player_name(), "fancy_vend:default;"..minetest.pos_to_string(pos), get_vendor_default_fs(pos, player))
        end
    else
        minetest.show_formspec(player:get_player_name(), "fancy_vend:buyer;"..minetest.pos_to_string(pos), get_vendor_buyer_fs(pos, player, nil))
    end
end

local function swap_vendor(pos, vendor_type)
    local node = minetest.get_node(pos)
    node.name = vendor_type
    minetest.swap_node(pos, node)
end

local function get_correct_vendor(settings)
    if settings.admin_vendor then
        if settings.depositor then
            return "fancy_vend:admin_depo"
        else
            return "fancy_vend:admin_vendor"
        end
    else
        if settings.depositor then
            return "fancy_vend:player_depo"
        else
            return "fancy_vend:player_vendor"
        end
    end
end

local function is_vendor(name)
    local vendor_names = {
        "fancy_vend:player_vendor",
        "fancy_vend:player_depo",
        "fancy_vend:admin_vendor",
        "fancy_vend:admin_depo",
    }
    for i,n in ipairs(vendor_names) do
        if name == n then
            return true
        end
    end
    return false
end


local function refresh_vendor(pos)
    local node = minetest.get_node(pos)
    if node.name:split(":")[1] ~= "fancy_vend" then
        return false, "not a vendor"
    end

    local settings = get_vendor_settings(pos)
    local meta = minetest.get_meta(pos)
    local status, errorcode = get_vendor_status(pos)
    local correct_vendor = get_correct_vendor(settings)


    if status then
        meta:set_string("infotext", (settings.admin_vendor and "Admin" or "Player").." Vendor trading "..settings.input_item_qty.." "..minetest.registered_items[settings.input_item].description.." for "..settings.output_item_qty.." "..minetest.registered_items[settings.output_item].description.." (owned by " .. meta:get_string("owner") .. ")")

        if meta:get_string("configured") == "" then
            meta:set_string("configured", "true")
            if minetest.get_modpath("awards") then
                local name = meta:get_string("owner")
                local data = awards.players[name]

                awards.increment_item_counter(data, "fancy_vend_configure", correct_vendor)

                if awards.get_item_count(data, "fancy_vend_configure", "fancy_vend:player_vendor") >= 1 then
                    awards.unlock(name, "fancy_vend_seller")
                end
                if awards.get_item_count(data, "fancy_vend_configure", "fancy_vend:player_depo") >= 1 then
                    awards.unlock(name, "fancy_vend_trader")
                end
                if awards.get_total_item_count(data, "fancy_vend_configure") >= 10 then
                    awards.unlock(name, "fancy_vend_shop_keeper")
                end
                if awards.get_total_item_count(data, "fancy_vend_configure") >= 25 then
                    awards.unlock(name, "fancy_vend_merchant")
                end
                if awards.get_total_item_count(data, "fancy_vend_configure") >= 100 then
                    awards.unlock(name, "fancy_vend_super_merchant")
                end
                if awards.get_total_item_count(data, "fancy_vend_configure") >= 9001 then
                    awards.unlock(name, "fancy_vend_god_merchant")
                end
            end
        end

        if settings.depositor then
            if meta:get_string("item") ~= settings.input_item then
                meta:set_string("item", settings.input_item)
                update_item(pos, node)
            end
        else
            if meta:get_string("item") ~= settings.output_item then
                meta:set_string("item", settings.output_item)
                update_item(pos, node)
            end
        end
    else
        meta:set_string("infotext", "Inactive "..(settings.admin_vendor and "Admin" or "Player").." Vendor"..make_inactive_string(errorcode).." (owned by " .. meta:get_string("owner") .. ")")
        if meta:get_string("item") ~= "fancy_vend:inactive" then
            meta:set_string("item", "fancy_vend:inactive")
            update_item(pos, node)
        end
    end

    if correct_vendor ~= node.name then
        swap_vendor(pos, correct_vendor)
    end
end

local function move_inv(frominv, toinv, filter)
    for i, v in ipairs(frominv:get_list("main") or {}) do
        if v:get_name() == filter or not filter then
            if toinv:room_for_item("main", v) then
                leftover = toinv:add_item("main", v)

                frominv:remove_item("main", v)

                if leftover
                and not leftover:is_empty() then
                    frominv:add_item("main", v)
                end
            end
        end
    end
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    local name = formname:split(":")[1]
    if name ~= "fancy_vend" then return end
    local formtype = formname:split(":")[2]
    formtype = formtype:split(";")[1]
    local pos = minetest.string_to_pos(formname:split(";")[2])
    if not pos then return end

    local node = minetest.get_node(pos)
    if not is_vendor(node.name) then return end

    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local player_inv = player:get_inventory()
    local settings = get_vendor_settings(pos)

    -- Handle settings changes
    if can_modify_vendor(pos, player) then
        for i in pairs(fields) do
            if stb(fields[i]) ~= settings[i] then
                settings[i] = stb(fields[i])
            end
        end
        -- Check number-only fields contain only numbers
        if not tonumber(settings.input_item_qty) then
            settings.input_item_qty = 1
        else
            settings.input_item_qty = math.floor(tonumber(settings.input_item_qty))
        end
        if not tonumber(settings.output_item_qty) then
            settings.output_item_qty = 1
        else
            settings.output_item_qty = math.floor(tonumber(settings.output_item_qty))
        end

        -- Check item quantities aren't too high (which could lead to additional processing for no reason), if so, set it to the maximum the player inventory can handle
        if ItemStack(settings.output_item):get_stack_max() * player_inv:get_size("main") < settings.output_item_qty then
            settings.output_item_qty = ItemStack(settings.output_item):get_stack_max() * player_inv:get_size("main")
        end

        if ItemStack(settings.input_item):get_stack_max() * player_inv:get_size("main") < settings.input_item_qty then
            settings.input_item_qty = ItemStack(settings.input_item):get_stack_max() * player_inv:get_size("main")
        end

        -- Admin vendor priv check
        if not minetest.check_player_privs(meta:get_string("owner"), {admin_vendor=true}) and fields.admin_vendor == "true" then
            settings.admin_vendor = false
        end

        set_vendor_settings(pos, settings)
        refresh_vendor(pos)
    end

    if fields.quit then
        return true
    end

    if fields.buy then
        local lots = math.floor(tonumber(fields.lot_count) or 1)
        local success, message = make_purchase(pos, player, lots)
        if success then
            -- Add to vendor logs
            local logs = minetest.deserialize(meta:get_string("log"))
            for i in pairs(logs) do
                if i >= max_logs then
                    table.remove(logs, 1)
                end
            end
            table.insert(logs, "Player "..player:get_player_name().." purchased "..lots.." lots from this vendor.")
            meta:set_string("log", minetest.serialize(logs))

            -- Send digiline message if applicable
            if minetest.get_modpath("digilines") then
                local msg = {
                    buyer = player:get_player_name(),
                    lots = lots,
                    settings = settings,
                }
                send_message(pos, settings.digiline_channel, msg)
            end
        end
        -- Set message and refresh vendor
        if message then
            meta:set_string("message", message)
        end
        refresh_vendor(pos)
    elseif fields.lot_fill then
        minetest.show_formspec(player:get_player_name(), "fancy_vend:buyer;"..minetest.pos_to_string(pos), get_vendor_buyer_fs(pos, player, get_max_lots(pos, player)))
        return true
    end

    if can_access_vendor_inv(player, pos) then
        if fields.inv_tovendor then
            minetest.log("action", player:get_player_name().." moves inventory contents to vendor at "..minetest.pos_to_string(pos))
            move_inv(player_inv, inv, nil)
            refresh_vendor(pos)
        elseif fields.inv_output_tovendor then
            minetest.log("action", player:get_player_name().." moves output items in inventory to vendor at "..minetest.pos_to_string(pos))
            move_inv(player_inv, inv, settings.output_item)
            refresh_vendor(pos)
        elseif fields.inv_fromvendor then
            minetest.log("action", player:get_player_name().." moves inventory contents from vendor at "..minetest.pos_to_string(pos))
            move_inv(inv, player_inv, nil)
            refresh_vendor(pos)
        elseif fields.inv_input_fromvendor then
            minetest.log("action", player:get_player_name().." moves input items from vendor at "..minetest.pos_to_string(pos))
            move_inv(inv, player_inv, settings.input_item)
            refresh_vendor(pos)
        end
    end

    -- Handle page changes
    if fields.button_log then
        minetest.show_formspec(player:get_player_name(), "fancy_vend:log;"..minetest.pos_to_string(pos), get_vendor_log_fs(pos))
        return
    elseif fields.button_settings then
        minetest.show_formspec(player:get_player_name(), "fancy_vend:settings;"..minetest.pos_to_string(pos), get_vendor_settings_fs(pos))
        return
    elseif fields.button_inv then
        minetest.show_formspec(player:get_player_name(), "fancy_vend:default;"..minetest.pos_to_string(pos), get_vendor_default_fs(pos, player))
        return
    end

    -- Update formspec
    if formtype == "log" then
        minetest.show_formspec(player:get_player_name(), "fancy_vend:log;"..minetest.pos_to_string(pos), get_vendor_log_fs(pos, player))
    elseif formtype == "settings" then
        minetest.show_formspec(player:get_player_name(), "fancy_vend:settings;"..minetest.pos_to_string(pos), get_vendor_settings_fs(pos, player))
    elseif formtype == "default" then
        minetest.show_formspec(player:get_player_name(), "fancy_vend:default;"..minetest.pos_to_string(pos), get_vendor_default_fs(pos, player))
    elseif formtype == "buyer" then
        minetest.show_formspec(player:get_player_name(), "fancy_vend:buyer;"..minetest.pos_to_string(pos), get_vendor_buyer_fs(pos, player, (tonumber(fields.lot_count) or 1)))
    end
end)

local vendor_template = {
    description = "Vending Machine",
    legacy_facedir_simple = true,
    paramtype2 = "facedir",
    groups = {choppy=2, oddly_breakable_by_hand=2, tubedevice=1, tubedevice_receiver=1},
    selection_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, 1.5, 0.5},
    },
    is_ground_content = false,
    light_source = 8,
    sounds = default.node_sound_wood_defaults(),
    drop = drop_vendor,
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext", "Unconfigured Player Vendor")
        meta:set_string("message", "Vendor initialized")
        meta:set_string("owner", "")
        local inv = meta:get_inventory()
        inv:set_size("main", 15*6)
        inv:set_size("wanted_item", 1*1)
        inv:set_size("given_item", 1*1)
        reset_vendor_settings(pos)
        meta:set_string("log", "")
    end,
    can_dig = can_dig_vendor,
    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then return end
        local pointed_node_pos = minetest.get_pointed_thing_position(pointed_thing, false)
        local pointed_node = minetest.get_node(pointed_node_pos)
        if minetest.registered_nodes[pointed_node.name].buildable_to then
            pointed_thing.above = pointed_node_pos
        end
        -- Set variables for access later (for various checks, etc.)
        local name = placer:get_player_name()
        local above_node_pos = table.copy(pointed_thing.above)
        above_node_pos.y = above_node_pos.y + 1
        local above_node = minetest.get_node(above_node_pos).name

        -- If node above is air or the display node, and it is not protected, attempt to place the vendor. If vendor sucessfully places, place display node above, otherwise alert the user
        if (minetest.registered_nodes[above_node].buildable_to or above_node == "fancy_vend:display_node") and not minetest.is_protected(above_node_pos, name) then
            local itemstack, success = minetest.item_place(itemstack, placer, pointed_thing, nil)
            if above_node ~= "fancy_vend:display_node" and success then
                minetest.set_node(above_node_pos, minetest.registered_nodes["fancy_vend:display_node"])
            end
            -- Set owner
            local meta = minetest.get_meta(pointed_thing.above)
            meta:set_string("owner", placer:get_player_name() or "")

            -- Set default meta
            meta:set_string("log", minetest.serialize({"Vendor placed by "..placer:get_player_name(),}))
            reset_vendor_settings(pointed_thing.above)
            refresh_vendor(pointed_thing.above)
        else
            minetest.chat_send_player(name, "Vendors require 2 nodes of space.")
        end

        if minetest.get_modpath("pipeworks") then
            pipeworks.after_place(pointed_thing.above)
        end

        return itemstack
    end,
    on_dig = function(pos, node, digger)
        -- Set variables for access later (for various checks, etc.)
        local name = digger:get_player_name()
        local above_node_pos = table.copy(pos)
        above_node_pos.y = above_node_pos.y + 1

        -- abandon if player shouldn't be able to dig node
        local can_dig = can_dig_vendor(pos, digger)
        if not can_dig then return end

        -- Try remove display node, if the whole node is able to be removed by the player, remove the display node and continue to remove vendor, if it doesn't exist and vendor can be dug continue to remove vendor.
        local success
        if minetest.get_node(above_node_pos).name == "fancy_vend:display_node" then
            if not minetest.is_protected(above_node_pos, name) and not minetest.is_protected(pos, name) then
                minetest.remove_node(above_node_pos)
                remove_item(above_node_pos)
                success = true
            else
                success = false
            end
        else
            if not minetest.is_protected(pos, name) then
                success = true
            else
                success = false
            end
        end

        -- If failed to remove display node, don't remove vendor. since protection for whole vendor was checked at display removal, protection need not be re-checked
        if success then
            minetest.remove_node(pos)
            minetest.handle_node_drops(pos, {drop_vendor}, digger)
            if minetest.get_modpath("pipeworks") then
                pipeworks.after_dig(pos)
            end
        end
    end,
    digiline = {
        receptor = {},
        effector = {
            action = function() end
        }
    },
    tube = {
        input_inventory = "main",
        connect_sides = {left = 1, right = 1, back = 1, bottom = 1},
        insert_object = function(pos, node, stack, direction)
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            local remaining = inv:add_item("main", stack)
            refresh_vendor(pos)
            return remaining
        end,
        can_insert = function(pos, node, stack, direction)
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            local settings = get_vendor_settings(pos)
            if settings.split_stacks then
                stack = stack:peek_item(1)
            end
            if settings.accept_output_only then
                if stack:get_name() ~= settings.output_item then
                    return false
                end
            end
            return inv:room_for_item("main", stack)
        end,
    },
    allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
        if not can_access_vendor_inv(player, pos) then
            return 0
        end
        return count
    end,
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        if not can_access_vendor_inv(player, pos) then
            return 0
        end
        if listname == "wanted_item" or listname == "given_item" then
            local inv = minetest.get_meta(pos):get_inventory()
            inv:set_stack(listname, index, ItemStack(stack:get_name()))
            local settings = get_vendor_settings(pos)
            if listname == "wanted_item" then
                settings.input_item = stack:get_name()
            elseif listname == "given_item" then
                settings.output_item = stack:get_name()
            end
            set_vendor_settings(pos, settings)
            return 0
        end
        return stack:get_count()
    end,
    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
        if not can_access_vendor_inv(player, pos) then
            return 0
        end
        if listname == "wanted_item" or listname == "given_item" then
            local inv = minetest.get_meta(pos):get_inventory()
            local fake_stack = inv:get_stack(listname, index)
            fake_stack:take_item(stack:get_count())
            inv:set_stack(listname, index, fake_stack)
            local settings = get_vendor_settings(pos)
            if listname == "wanted_item" then
                settings.input_item = ""
            elseif listname == "given_item" then
                settings.output_item = ""
            end
            set_vendor_settings(pos, settings)
            return 0
        end
        return stack:get_count()
    end,
    on_rightclick = function(pos, node, clicker)
        node = minetest.get_node(pos)
        if node.name == "fancy_vend:display_node" then
            pos.y = pos.y - 1
        end
        show_vendor_formspec(clicker, pos)
    end,
    on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
        minetest.log("action", player:get_player_name().." moves stuff in vendor at "..minetest.pos_to_string(pos))
        refresh_vendor(pos)
    end,
    on_metadata_inventory_put = function(pos, listname, index, stack, player)
        minetest.log("action", player:get_player_name().." moves "..stack:get_name().." to vendor at "..minetest.pos_to_string(pos))
        refresh_vendor(pos)
    end,
    on_metadata_inventory_take = function(pos, listname, index, stack, player)
        minetest.log("action", player:get_player_name().." takes "..stack:get_name().." from vendor at "..minetest.pos_to_string(pos))
        refresh_vendor(pos)
    end,
    on_blast = function()
        -- TNT immunity
    end,
}

local player_vendor = table.copy(vendor_template)
player_vendor.tiles = {
        "player_vend.png", "player_vend.png",
        "player_vend.png", "player_vend.png",
        "player_vend.png", "player_vend_front.png",
    }

local player_depo = table.copy(vendor_template)
player_depo.tiles = {
        "player_depo.png", "player_depo.png",
        "player_depo.png", "player_depo.png",
        "player_depo.png", "player_depo_front.png",
    }
player_depo.groups.not_in_creative_inventory = 1

local admin_vendor = table.copy(vendor_template)
admin_vendor.tiles = {
        "admin_vend.png", "admin_vend.png",
        "admin_vend.png", "admin_vend.png",
        "admin_vend.png", "admin_vend_front.png",
    }
admin_vendor.groups.not_in_creative_inventory = 1

local admin_depo = table.copy(vendor_template)
admin_depo.tiles = {
        "admin_depo.png", "admin_depo.png",
        "admin_depo.png", "admin_depo.png",
        "admin_depo.png", "admin_depo_front.png",
    }
admin_depo.groups.not_in_creative_inventory = 1

minetest.register_node("fancy_vend:player_vendor", player_vendor)
minetest.register_node("fancy_vend:player_depo", player_depo)
minetest.register_node("fancy_vend:admin_vendor", admin_vendor)
minetest.register_node("fancy_vend:admin_depo", admin_depo)

minetest.register_craft({
    output = "fancy_vend:player_vendor",
    recipe = {
        { "default:gold_ingot",display_node,          "default:gold_ingot"},
        { "default:diamond",   "default:mese_crystal",        "default:diamond"},
        { "default:gold_ingot","default:chest_locked","default:gold_ingot"},
    }
})


---------------
-- Copy Tool --
---------------

local function get_vendor_pos_and_settings(pointed_thing)
    if pointed_thing.type ~= "node" then return false end
    local pos = minetest.get_pointed_thing_position(pointed_thing, false)
    local node = minetest.get_node(pos)
    if node.name == "fancy_vend:display_node" then
        pos.y = pos.y - 1
        node = minetest.get_node(pos)
    end
    if not is_vendor(node.name) then return false end

    local settings = get_vendor_settings(pos)

    return pos, settings
end

minetest.register_tool("fancy_vend:copy_tool",{
    inventory_image = "copier.png",
    description = "Geminio Wand (For copying vendor settings, right click to save settings, left click to set settings.)",
    stack_max = 1,
    on_place = function(itemstack, placer, pointed_thing)
        local pos, settings = get_vendor_pos_and_settings(pointed_thing)
        if not pos then return end

        local meta = itemstack:get_meta()
        meta:set_string("settings", minetest.serialize(settings))

        minetest.chat_send_player(placer:get_player_name(), "Settings saved.")

        return itemstack
    end,
    on_use = function(itemstack, user, pointed_thing)
        local pos, current_settings = get_vendor_pos_and_settings(pointed_thing)
        if not pos then return end

        local meta = itemstack:get_meta()
        local node_meta = minetest.get_meta(pos)
        local new_settings = minetest.deserialize(meta:get_string("settings"))

        if can_modify_vendor(pos, user) then
            -- Admin vendor priv check
            if not minetest.check_player_privs(node_meta:get_string("owner"), {admin_vendor=true}) and new_settings.admin_vendor == true then
                settings.admin_vendor = false
            end

            new_settings.input_item = current_settings.input_item
            new_settings.input_item_qty = current_settings.input_item_qty
            new_settings.output_item = current_settings.output_item
            new_settings.output_item_qty = current_settings.output_item_qty

            -- Admin vendor priv check
            if not minetest.check_player_privs(node_meta:get_string("owner"), {admin_vendor=true}) and new_settings.admin_vendor then
                new_settings.admin_vendor = current_settings.admin_vendor
            end

            set_vendor_settings(pos, new_settings)
            refresh_vendor(pos)
            minetest.chat_send_player(user:get_player_name(), "Settings set.")
        else
            minetest.chat_send_player(user:get_player_name(), "You cannot modify this vendor.")
        end
    end,
})

minetest.register_craft({
    output = "fancy_vend:copy_tool",
    recipe = {
        {"default:stick","",                      ""               },
        {"",             "default:obsidian_shard",""               },
        {"",             "",                      "default:diamond"},
    }
})

minetest.register_craft({
    output = "fancy_vend:copy_tool",
    recipe = {
        {"",               "",                      "default:stick"},
        {"",               "default:obsidian_shard",""             },
        {"default:diamond","",                      ""             },
    }
})


---------------------------
-- Vendor Upgrade System --
---------------------------

local old_vendor_mods = string.split((minetest.setting_get("fancy_vend_old_vendor_mods") or ""), ",")
local old_vendor_mods_table = {}

for i in pairs(old_vendor_mods) do
    old_vendor_mods_table[old_vendor_mods[i]] = true
end

local base_upgrade_template = {
    description = "Shop Upgrade (Try and place to upgrade)",
    legacy_facedir_simple = true,
    paramtype2 = "facedir",
    groups = {choppy=2, oddly_breakable_by_hand=2, not_in_creative_inventory=1},
    is_ground_content = false,
    light_source = 8,
    sounds = default.node_sound_wood_defaults(),
    drop = drop_vendor,
    tiles = {
        "player_vend.png", "player_vend.png",
        "player_vend.png", "player_vend.png",
        "player_vend.png", "upgrade_front.png",
    },
    on_place = function(itemstack, placer, pointed_thing)
        return ItemStack(drop_vendor.." "..itemstack:get_count())
    end,
    allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
        local meta = minetest.get_meta(pos)
        if player:get_player_name() ~= meta:get_string("owner") then return 0 end
        return count
    end,
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        local meta = minetest.get_meta(pos)
        if player:get_player_name() ~= meta:get_string("owner") then return 0 end
        return stack:get_count()
    end,
    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
        local meta = minetest.get_meta(pos)
        if player:get_player_name() ~= meta:get_string("owner") then return 0 end
        return stack:get_count()
    end,
}

local clear_craft_vendors = {}

if old_vendor_mods_table["currency"] then
    local currency_template = table.copy(base_upgrade_template)

    currency_template.can_dig = function(pos, player)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        return inv:is_empty("stock") and inv:is_empty("customers_gave") and inv:is_empty("owner_wants") and inv:is_empty("owner_gives") and (meta:get_string("owner") == player:get_player_name() or minetest.check_player_privs(player:get_player_name(), {protection_bypass=true}))
    end
    currency_template.on_rightclick = function(pos, node, clicker, itemstack)
        local meta = minetest.get_meta(pos)
        local list_name = "nodemeta:"..pos.x..','..pos.y..','..pos.z
        if clicker:get_player_name() == meta:get_string("owner") then
            minetest.show_formspec(clicker:get_player_name(),"fancy_vend:currency_shop_formspec",
                "size[8,9.5]"..
                "label[0,0;" .. "Customers gave:" .. "]"..
                "list["..list_name..";customers_gave;0,0.5;3,2;]"..
                "label[0,2.5;" .. "Your stock:" .. "]"..
                "list["..list_name..";stock;0,3;3,2;]"..
                "label[5,0;" .. "You want:" .. "]"..
                "list["..list_name..";owner_wants;5,0.5;3,2;]"..
                "label[5,2.5;" .. "In exchange, you give:" .. "]"..
                "list["..list_name..";owner_gives;5,3;3,2;]"..
                "list[current_player;main;0,5.5;8,4;]"
            )
        end
    end

    minetest.register_node(":currency:shop", currency_template)

    table.insert(clear_craft_vendors, "currency:shop")
end

if old_vendor_mods_table["easyvend"] then
    local nodes = {"easyvend:vendor", "easyvend:vendor_on", "easyvend:depositor", "easyvend:depositor_on"}
    for i in pairs(nodes) do
        minetest.register_node(":"..nodes[i], base_upgrade_template)
        table.insert(clear_craft_vendors, nodes[i])
    end
end

if old_vendor_mods_table["vendor"] then
    local nodes = {"vendor:vendor", "vendor:depositor"}
    for i in pairs(nodes) do
        minetest.register_node(":"..nodes[i], base_upgrade_template)
        table.insert(clear_craft_vendors, nodes[i])
    end
end

if old_vendor_mods_table["money"] then
    local money_template = table.copy(base_upgrade_template)
    money_template.can_dig = function(pos, player)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        return inv:is_empty("main") and (meta:get_string("owner") == player:get_player_name() or minetest.check_player_privs(player:get_player_name(), {protection_bypass=true}))
    end
    money_template.on_rightclick = function(pos, node, clicker, itemstack)
        local meta = minetest.get_meta(pos)
        local list_name = "nodemeta:"..pos.x..','..pos.y..','..pos.z
        if clicker:get_player_name() == meta:get_string("owner") then
            minetest.show_formspec(clicker:get_player_name(),"fancy_vend:money_shop_formspec",
                "size[8,10;]"..
                "list["..listname..";main;0,0;8,4;]"..
                "list[current_player;main;0,6;8,4;]"
            )
        end
    end
    local nodes = {"money:barter_shop", "money:shop", "money:admin_shop", "money:admin_barter_shop"}
    for i in pairs(nodes) do
        minetest.register_node(":"..nodes[i], money_template)
        table.insert(clear_craft_vendors, nodes[i])
    end
end

for i_n in pairs(clear_craft_vendors) do
    local currency_crafts = minetest.get_all_craft_recipes(i_n)
    if currency_crafts then
        for i in pairs(currency_crafts) do
            minetest.clear_craft(currency_crafts[i])
        end
    end
end