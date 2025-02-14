_addon.name = 'MogsNotes'
_addon.author = 'Jonesy'
_addon.version = 1.0
_addon.commands = {'mogsnotes', 'mogs', 'mnotes'}

config = require('config')
defaults = require('defaults')
images = require('images')
packets = require('packets')
resources = require('resources')
strings = require('strings')
texts = require('texts')
require('logger')

local settings = config.load(defaults)
local last_target = ''
local mob_data = {}
local target_data = ''

-- Create a text box for target_data
local target_box = texts.new('${data}', settings.target_box, settings)
target_box.data = target_data

-- Load the zone data for the current zone
windower.register_event('zone change', function(new_id, old_id)
    load_zone_data()
    set_up_mob_box()
end)

windower.register_event('target change', function(new_id, old_id)
    local target = windower.ffxi.get_mob_by_target('st') or windower.ffxi.get_mob_by_target('t')    

    if target and target.id > 0 and target.name ~= last_target then
        if mob_data and mob_data.Names then
            local target_info = mob_data.Names[target.name]
            last_target = target.name
            if target_info then
                target_data = '\\cs(255,215,0)' .. target_info.Name .. '\\cr\n'

                -- Construct the Aggro conditions line
                if target_info.Link then
                    target_data = target_data .. 'Linking '
                end
                if target_info.TrueSight then
                    target_data = target_data .. 'TrueSight '
                end
                target_data = target_data .. '\n'

                -- Construct the Aggro line
                target_data = target_data .. '\\cs(173,216,230)Aggro: \\cr'
                if target_info.Sight then
                    target_data = target_data .. 'Sight '
                end
                if target_info.Sound then
                    target_data = target_data .. 'Sound '
                end
                if target_info.Blood then
                    target_data = target_data .. 'Blood '
                end
                if target_info.Magic then
                    target_data = target_data .. 'Magic '
                end
                if target_info.Scent then
                    target_data = target_data .. 'Scent '
                end
                if target_info.JA then
                    target_data = target_data .. 'JA '
                end
                target_data = target_data .. '\n'

                --target_data = target_data .. '\\cs(173,216,230)Job: \\cr' .. tostring(target_info.Job) .. '\n'

                -- Construct the Level range line
                target_data = target_data .. '\\cs(173,216,230)Level Range: \\cr' .. tostring(target_info.MinLevel) .. ' - ' .. tostring(target_info.MaxLevel) .. '\n'

                target_data = target_data .. '\\cs(173,216,230)Immunities: \\cr' .. get_immunity_text(target_info.Immunities) .. '\n'
                target_data = target_data .. '\\cs(173,216,230)Respawn: \\cr' .. tostring(target_info.Respawn) .. '\n'                
                target_data = target_data .. '\\cs(173,216,230)Spells: \\cr' .. format_spells(target_info.Spells) .. '\n'
                target_data = target_data .. '\\cs(173,216,230)Drops: \\cr' .. format_drops(target_info.Drops) .. '\n\n'

                -- Define color mappings for each modifier
                local color_mappings = {
                    Fire = {255, 0, 0},       -- Red
                    Ice = {0, 0, 255},        -- Blue
                    Wind = {0, 255, 0},       -- Green
                    Earth = {139, 69, 19},    -- Brown
                    Lightning = {255, 255, 0},-- Yellow
                    Water = {0, 191, 255},    -- Deep Sky Blue
                    Light = {255, 255, 255},  -- White
                    Dark = {128, 0, 128}      -- Purple
                }

                -- Group weapon and elemental modifiers
                local weapon_modifiers = {'Slashing', 'Piercing', 'H2H', 'Impact'}
                local light_modifiers = {'Fire', 'Ice', 'Wind', 'Light'}
                local dark_modifiers = {'Earth', 'Lightning', 'Water', 'Dark'}                

                -- Add weapon modifiers
                target_data = target_data .. '\\cs(173,216,230)Weapon: \\cr\n'
                for _, mod in ipairs(weapon_modifiers) do
                    if target_info.Modifiers[mod] then
                        local value = target_info.Modifiers[mod]
                        local value_color = '\\cs(255,255,255)' -- Default to white
                        if value > 1 then
                            value_color = '\\cs(0,255,0)' -- Green for values over 1
                        elseif value < 1 then
                            value_color = '\\cs(255,0,0)' -- Red for values under 1
                        end
                        target_data = target_data .. mod .. ': ' .. value_color .. tostring(value) .. ' \\cr'
                    end
                end
                target_data = target_data .. '\n'

                -- Add elemental modifiers
                target_data = target_data .. '\\cs(173,216,230)Element: \\cr\n'
                for _, mod in ipairs(dark_modifiers) do
                    if target_info.Modifiers[mod] then
                        local color = color_mappings[mod]
                        local value = target_info.Modifiers[mod]
                        local display_value = tostring(value)
                        local value_color = '\\cs(255,255,255)' -- Default to white
                    
                        if value == -1 then
                            value_color = '\\cs(0,0,255)' -- Blue for value -1
                            display_value = 'A'
                        elseif value > 1 then
                            value_color = '\\cs(0,255,0)' -- Green for values over 1
                        elseif value < 1 then
                            value_color = '\\cs(255,0,0)' -- Red for values under 1
                        end                    
                        target_data = target_data .. '\\cs(' .. color[1] .. ',' .. color[2] .. ',' .. color[3] .. ')' .. mod .. ': ' .. value_color .. display_value .. ' \\cr'
                    end
                end
                target_data = target_data .. '\n'
                for _, mod in ipairs(light_modifiers) do
                    if target_info.Modifiers[mod] then
                        local color = color_mappings[mod]
                        local value = target_info.Modifiers[mod]
                        local display_value = tostring(value)
                        local value_color = '\\cs(255,255,255)' -- Default to white
                        if value == -1 then
                            value_color = '\\cs(0,0,255)' -- Blue for value -1
                            display_value = 'A'
                        elseif value > 1 then
                            value_color = '\\cs(0,255,0)' -- Green for values over 1
                        elseif value < 1 then
                            value_color = '\\cs(255,0,0)' -- Red for values under 1
                        end
                        target_data = target_data .. '\\cs(' .. color[1] .. ',' .. color[2] .. ',' .. color[3] .. ')' .. mod .. ': ' .. value_color .. display_value .. ' \\cr'
                    end
                end
                target_data = target_data .. '\n'
            else
                target_data = 'No data available for this target.'
            end
        else
            target_data = 'Mob data not loaded.'
        end
        -- Update the text box with the new target_data
        target_box.data = target_data
        target_box:update()
        target_box:show()
    end
end)

windower.register_event('addon command', function(command, ...)
    command = command and command:lower() or 'help'
    local args = {...}
    if command == 'help' then
        add_to_chat(123, 'MogsNotes Commands:')
        add_to_chat(123, '  //mogsnotes help : Shows this help message')
        add_to_chat(123, '  //mogsnotes show : Shows the target_box')
        add_to_chat(123, '  //mogsnotes hide : Hides the target_box')
        add_to_chat(123, '  //mogsnotes rezone : Reloads the zone data')
        add_to_chat(123, '  //mogsnotes save : Resaves the settings')
    elseif command == 'zone' then
        settings.target_box.show = true
        target_box:show()
    elseif command == 'hide' then
        settings.target_box.show = false
        target_box:hide()
    elseif command == 'rezone' then
        load_zone_data()
    elseif command == 'save' then
        config.save(settings)
        add_to_chat(123, 'Settings have been saved.')
    end
end)


function load_zone_data()
    local currentZone = windower.ffxi.get_info().zone
    local currentZoneName = resources.zones[windower.ffxi.get_info().zone].name

    -- Construct the file path based on the zone ID
    local file_path = string.format('mobdata/%d', currentZone)
    
    -- Attempt to load the data from the file
    local success, data = pcall(require, file_path)
    
    if success then
        mob_data = data
        add_to_chat(123, 'Loaded zone: (' .. currentZone .. ') ' .. currentZoneName)
    else
        add_to_chat(123, 'Loaded zone: (' .. currentZone .. ') ' .. currentZoneName .. ' - No mob data available')
    end
end

function get_immunity_text(immunities)
    local immunity_text = ''
    if immunities == 0 then
        immunity_text = 'None'
    else
        if immunities % 2 == 1 then
            immunity_text = immunity_text .. 'Sleep '
        end
        if immunities % 4 >= 2 then
            immunity_text = immunity_text .. 'Gravity '
        end
        if immunities % 8 >= 4 then
            immunity_text = immunity_text .. 'Bind '
        end
        if immunities % 16 >= 8 then
            immunity_text = immunity_text .. 'Stun '
        end
        if immunities % 32 >= 16 then
            immunity_text = immunity_text .. 'Silence '
        end
        if immunities % 64 >= 32 then
            immunity_text = immunity_text .. 'Paralyze '
        end
        if immunities % 128 >= 64 then
            immunity_text = immunity_text .. 'Blind '
        end
        if immunities % 256 >= 128 then
            immunity_text = immunity_text .. 'Slow '
        end
        if immunities % 512 >= 256 then
            immunity_text = immunity_text .. 'Poison '
        end
        if immunities % 1024 >= 512 then
            immunity_text = immunity_text .. 'Petrify '
        end
        if immunities % 2048 >= 1024 then
            immunity_text = immunity_text .. 'Curse '
        end
        if immunities % 4096 >= 2048 then
            immunity_text = immunity_text .. 'Virus '
        end
        if immunities % 8192 >= 4096 then
            immunity_text = immunity_text .. 'Charm '
        end
    end
    return immunity_text
end

-- Function to format drops with word wrapping every 5 items
function format_drops(drops)
    local formatted_drops = ''
    for i, drop in ipairs(drops) do
        if i % 3 == 0 then
            formatted_drops = formatted_drops .. get_item_name(drop) .. '\n'
        else
            formatted_drops = formatted_drops .. get_item_name(drop) .. ', '
        end
    end
    -- Remove trailing comma and space if present
    if formatted_drops:sub(-2) == ', ' then
        formatted_drops = formatted_drops:sub(1, -3)
    end
    return formatted_drops
end

-- Function to format spells with word wrapping every 5 items
function format_spells(spells)
    local formatted_spells = ''
    for i, spell in ipairs(spells) do
        if i % 3 == 0 then
            formatted_spells = formatted_spells .. get_spell_name(spell) .. '\n'
        else
            formatted_spells = formatted_spells .. get_spell_name(spell) .. ', '
        end
    end
    -- Remove trailing comma and space if present
    if formatted_spells:sub(-2) == ', ' then
        formatted_spells = formatted_spells:sub(1, -3)
    end
    return formatted_spells
end

function get_item_name(item_id)
    local item = resources.items[item_id]
    if item then
        return item.name
    else
        return 'Unknown Item'
    end
end

function get_spell_name(spell_id)
    local spell = resources.spells[spell_id]
    if spell then
        return spell.name
    else
        return 'Unknown Spell'
    end
end

function add_to_chat(color, text)
    windower.add_to_chat(color, text)
end