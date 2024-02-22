local util = require("__core__/lualib/util")
local SelectorAppearance = require("scripts.selector_appearance")
local SelectorGui = require("scripts.selector_gui")
local SelectorSimulation = require("scripts.selector_simulation")

script.on_init(function()
    SelectorSimulation.init()
end)

local selector_filter = {
    filter = "name",
    name = "selector-combinator",
}

local function on_added(event)
    SelectorSimulation.add_combinator(event)
end

local function on_entity_settings_pasted(event)
    local source = event.source
    local destination = event.destination

    if not source or not destination or
        source.name ~= "selector-combinator" or
        destination.name ~= "selector-combinator" then
        return
    end

    local source_unit_number = source.unit_number
    local destination_unit_number = destination.unit_number

    -- Replace source and destination with the underlying Selectors
    source = global.selector_combinators[source.unit_number]
    destination = global.selector_combinators[destination.unit_number]

    if not source or not destination then return end

    destination.settings = util.table.deepcopy(source.settings)

    SelectorAppearance.update_combinator_appearance(destination)
end

local function get_blueprint(event)
    local player = game.get_player(event.player_index)
    if not player then return end

    local bp = player.blueprint_to_setup
    if bp and bp.valid_for_read then
        return bp
    end

    bp = player.cursor_stack
    if not bp or not bp.valid_for_read then return end

    if bp.type == "blueprint-book" then
        local item_inventory = bp.get_inventory(defines.inventory.item_main)
        if item_inventory then
            bp = item_inventory[bp.active_index]
        else
            return
        end
    end

    return bp
end

local function on_player_setup_blueprint(event)
    local blueprint = get_blueprint(event)
    if not blueprint then return end

    local entities = blueprint.get_blueprint_entities()
    if not entities then return end

    for i, entity in pairs(entities) do
        if entity.name == "selector-combinator" then
            local selector = event.surface.find_entity(entity.name, entity.position)
            if selector then
                selector = global.selector_combinators[selector.unit_number]
                if selector then
                    blueprint.set_blueprint_entity_tag(i, "selector-combinator", util.table.deepcopy(selector.settings))
                end
            end
        end
    end
end

local function on_entity_destroyed(event)
    SelectorSimulation.remove_combinator(event.entity.unit_number)
end

local function on_destroyed(event)
    SelectorSimulation.remove_combinator(event.unit_number)
end

local function on_gui_opened(event)
    local entity = event.entity

    if not entity then
        return
    end

    if not entity.valid then
        return
    end

    if entity.name ~= "selector-combinator" then
        return
    end

    local player = game.get_player(event.player_index)

    if not player then
        return
    end

    SelectorGui.on_gui_added(player, entity)
end

local function on_gui_closed(event)
    local element = event.element

    if not element then
        return
    end

    if element.name ~= "selector-gui" then
        return
    end

    local player = game.get_player(event.player_index)

    if not player then
        return
    end

    SelectorGui.gui_closed(player)
end

local function on_tick()
    SelectorSimulation.update()
end

SelectorGui.bind_all_events()

-- Added Events
script.on_event(defines.events.on_built_entity, on_added, {selector_filter})
script.on_event(defines.events.on_robot_built_entity, on_added, {selector_filter})

-- Paste events
script.on_event(defines.events.on_entity_settings_pasted, on_entity_settings_pasted)

-- Blueprint events
script.on_event(defines.events.on_player_setup_blueprint, on_player_setup_blueprint)

-- Removed Events
script.on_event(defines.events.on_player_mined_entity, on_entity_destroyed, {selector_filter})
script.on_event(defines.events.on_robot_mined_entity, on_entity_destroyed, {selector_filter})
script.on_event(defines.events.script_raised_destroy, on_entity_destroyed, {selector_filter})

-- *Special* Removed Events
script.on_event(defines.events.on_entity_destroyed, on_destroyed)

-- GUI Events
script.on_event(defines.events.on_gui_opened, on_gui_opened)
script.on_event(defines.events.on_gui_closed, on_gui_closed)

-- Update Event
script.on_event(defines.events.on_tick, on_tick)

-- Put every player that joins into editor mode
script.on_event(defines.events.on_player_created, function(event)
    local player = game.get_player(event.player_index)
    player.cheat_mode = true

    if not player then
        return
    end

    for _, tech in pairs(player.force.technologies) do
        tech.researched = true
    end
end)
