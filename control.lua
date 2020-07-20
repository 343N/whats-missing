require("mod-gui")
require('util')

local unfulfilled_requests = {}
local bufferRequests = {}
local buttonQueue = {}
local all_requests = {}

-- global.plySettings = global.plySettings or {}
-- script.on_load(function()
--     global.plySettings = global.plySettings or {}

-- end)
script.on_configuration_changed(function(event)
    for k, v in pairs(game.players) do
        local flow = mod_gui.get_button_flow(v)
        local button = flow['whats-missing-button']
        if (button and button.valid) then
            button.destroy()
        end
    end
    global.plySettings = global.plySettings or {}
end)

local defaultSettings = {
    includeBuffer = true
}

script.on_init(function(event)
    global.plySettings = global.plySettings or {}
end)

script.on_event(defines.events.on_gui_click, function(event)
    -- local buttonFlow = mod_gui.get_button_flow
    local button = event.element
    local ply = game.players[event.player_index]

    if (button.name == 'whats-missing-button') then
        if (ply.gui.screen['whats-missing-gui'] and ply.gui.screen['whats-missing-gui'].valid) then
            ply.gui.screen['whats-missing-gui'].destroy()
            return
        end
        -- game.print("Hello!")
        local frame = ply.gui.screen.add({
            name = "whats-missing-gui",
            type = "frame",
            caption = "What's Missing?",
            direction = "vertical"
            -- style="window"
        })
        local WIDTH = 412 + 25;
        local HEIGHT = 200 + 170;
        local res = ply.display_resolution
        local scl = ply.display_scale
        frame.location = {
            (res.width / 2) - ((WIDTH / 2) * scl),
            (res.height / 2) - ((HEIGHT / 2) * scl)
        }
        local labelFrame = frame.add({
            name = "labelFrame",
            type = "frame",
            style = "inside_shallow_frame"
        })
        setGUISize(labelFrame, WIDTH - 25, 28);

        labelFrame.style.vertical_align = "center";
        labelFrame.style.top_padding = 4
        labelFrame.style.bottom_padding = 4

        local scrollPaneFrame = frame.add({
            name = "frame",
            type = "frame",
            style = "inside_shallow_frame",
            direction = "vertical"
        })

        local scrollPane = scrollPaneFrame.add({
            name = "scrollpane",
            type = "scroll-pane",
            vertical_scroll_policy = "always",
            horizontal_scroll_policy = "never"
            -- style="filter_scroll_pane"
        })
        local scrollPaneInnerFrame = scrollPane.add({
            name = "innerFrame",
            type = "frame",
            style = "filter_scroll_pane_background_frame",
            direction = "vertical"
        })
        local contentTable = scrollPaneInnerFrame.add({
            name = "itemTable",
            type = "table",
            style = "filter_slot_table",
            column_count = 10
        })

        local bufferCheck = frame.add({
            name = "bufferIncludeCheckbox",
            type = 'checkbox',
            caption = "Include requests from buffer chests.",
            state = true
        })
        if (global.plySettings[ply.index]) then
            bufferCheck.state = global.plySettings[ply.index].includeBuffer
        end

        setGUISize(bufferCheck, nil, 20)

        local refreshButton = frame.add({
            name = "whats-missing-refresh",
            type = "button",
            caption = "Refresh"
        })

        local closeButton = frame.add({
            name = "whats-missing-close",
            type = "button",
            caption = "Close"
        })
        -- scrollPaneInnerFrame.style.padding = 10
        local SIDE_PADDING = 8
        -- scrollPaneFrame.style.left_padding = SIDE_PADDING
        -- scrollPaneFrame.style.right_padding = SIDE_PADDING
        scrollPaneFrame.style.width = WIDTH - 25
        scrollPaneInnerFrame.style.width = WIDTH - 25
        -- scrollPaneInnerFrame.style.padding = 0
        local rowcount = 5
        scrollPaneInnerFrame.style.padding = 0
        scrollPaneFrame.style.left_padding = 0
        scrollPaneFrame.style.right_padding = 0
        frame.style.width = WIDTH
        frame.style.height = HEIGHT
        scrollPaneFrame.style.width = WIDTH - 25
        scrollPaneFrame.style.height = rowcount * 40
        scrollPane.style.height = rowcount * 40
        scrollPane.style.extra_top_padding_when_activated = 0
        scrollPane.style.extra_bottom_padding_when_activated = 0
        scrollPane.style.extra_left_padding_when_activated = 0
        scrollPane.style.extra_right_padding_when_activated = 0
        -- scrollPane.style.width = WIDTH - 25 - (12 * 2);
        -- scrollPane.style.width = HEIGHT - 175 - 8;
        scrollPane.style.horizontal_align = "center"
        scrollPane.style.vertical_align = "center"
        -- centering stuff
        frame.location = {
            (res.width / 2) - ((WIDTH / 2) * scl),
            (res.height / 2) - ((HEIGHT / 2) * scl)
        }

        updateGUI(ply, ply.gui.screen)

    elseif (button.name == "whats-missing-close" and ply.gui.screen['whats-missing-gui'] and
        ply.gui.screen['whats-missing-gui'].valid) then
        ply.gui.screen['whats-missing-gui'].destroy()

    elseif (button.name == 'whats-missing-refresh') then
        updateGUI(ply, ply.gui.screen)
    elseif (button.name == 'bufferIncludeCheckbox') then
        global.plySettings[ply.index] = global.plySettings[ply.index] or {}
        global.plySettings[ply.index].includeBuffer = button.state
        updateGUI(ply, ply.gui.screen)
    end

end)

script.on_nth_tick(60, function(event)
    checkGUIExistence()
end)

function checkGUIExistence()
    for k, ply in pairs(game.players) do
        local gui = ply.gui.top
        local buttonFlow = mod_gui.get_button_flow(ply)
        if (not buttonFlow['whats-missing-button']) then
            -- local button = gui.add()
            buttonFlow.add {
                type = 'sprite-button',
                style = 'mod_gui_button',
                name = 'whats-missing-button',
                sprite = 'whats-missing-button',
                tooltip = "What's Missing?\nShow what's being requested and \nnot fulfilled in your logistics network."
                -- caption = "What's Missing?\nShow what's being requested and not fulfilled in your logistics network."
            }

        end

    end

end

function updateGUI(player, gui)
    if (not gui['whats-missing-gui'] or not gui['whats-missing-gui'].valid) then
        return
    end
    local scrollPane = gui['whats-missing-gui']['frame']['scrollpane']['innerFrame']
    scrollPane['itemTable'].clear()
    local frame = gui['whats-missing-gui']['labelFrame'];

    local label

    -- if (not player.character) then

    --     label = scrollPane.add {
    --         name = 'label',
    --         caption = "You need to be a character, not god! :(",
    --         type = "label"
    --     }
    -- end

    local network = player.surface.find_logistic_network_by_position(player.position, player.force)
    if (frame['label'] and frame['label'].valid) then
        frame['label'].destroy()
    end
    if (not network) then
        label = frame.add {
            name = 'label',
            caption = "You're not in a logistics network! :(",
            type = "label"
        }
    elseif (not logisticNetworkHasMembers(network, player)) then

        label = frame.add {
            name = 'label',
            caption = "Your logistics network has no requester points! :(",
            type = "label"
        }

    elseif (not logisticNetworkHasRequests(network, player)) then
        label = frame.add {
            name = 'label',
            caption = "Your logistics network has no requests! :(",
            type = "label"
        }
    elseif (logisticNetworkHasRequests(network, player)) then
        -- if (logistic)
        lockButtons(player)
        updateLogisticNetworkRequests(network)

        if (logisticNetworkHasUnfulfilledRequests(network, player)) then
            buildGUIList(player, scrollPane, network)
            label = frame.add {
                name = 'label',
                caption = "You have " .. table_size(getRelativeRequestTable(network, player)) ..
                    " unfulfilled requests.",
                type = "label"
            }
        else
            label = frame.add {
                name = 'label',
                caption = "Your logistics network has no unfulfilled requests! :(",
                type = "label"
            }
        end
    end
    if (label) then
        label.style.horizontal_align = "center"
        label.style.vertical_align = "center"
        -- 329, 314 ends up being parent content-size
        setGUISize(label, label.parent.style.maximal_width)
    end
end

function logisticNetworkHasMembers(ln, ply)
    for k, v in pairs(ln.requester_points) do
        if (v.owner.name ~= "character") then
            local incBuffers = (global.plySettings[ply.index] and global.plySettings[ply.index].includeBuffer)
            local logicTest = incBuffers or (not incBuffers and v.owner.prototype.logistic_mode ~= 'buffer')
            if (incBuffers or (not incBuffers and v.owner.prototype.logistic_mode ~= 'buffer')) then
                return true
            end
        end
    end
    return false
end

function setGUISize(element, w, h)
    if (not element.style) then
        return
    end
    if (w) then
        element.style.width = w
    end
    if (h) then
        element.style.height = h
    end
end

function logisticNetworkHasRequests(ln, player)

    for k, v in pairs(ln.requester_points) do
        if (v.owner.name ~= "character") then
            -- __DebugAdapter.print(v.owner.name)
            local incBuffers = (global.plySettings[player.index] and global.plySettings[player.index].includeBuffer)
            if (incBuffers or (not incBuffers and v.owner.prototype.logistic_mode ~= 'buffer')) then
                if (v.filters ~= nil and table_size(v.filters) > 0) then
                    return true
                end
            end

            -- if (global.plySettings[player.index].includeBuffer and v.owner.logistic_mode == 'buffer')
        end
    end
    return false
end

function updateLogisticNetworkRequests(ln)

    unfulfilled_requests[ln] = {}
    -- all_requests[ln] = {}

    for k, v in pairs(ln.requester_points) do
        if (v.owner.name ~= "character") then
            if (v.filters and table_size(v.filters) > 0) then
                for k2, v2 in pairs(v.filters) do
                    local count = v2.count
                    -- all_requests[ln][v2.name] = count + (all_requests[ln][v2.name] or 0)
                    if (v.targeted_items_deliver[v2.name] ~= nil) then
                        count = count - v.targeted_items_deliver[v2.name]
                    end
                    -- local networkCount = ln.get_item_count(v2.name)
                    if (v.owner.prototype.logistic_mode ~= 'buffer') then
                        local containerCount = v.owner.get_item_count(v2.name)
                        count = count - containerCount
                    end

                    if (count > 0) then
                        addItemToUnfulfilledRequests(ln, v, v2.name, count)
                    end
                end
            end
        end
    end

    local ln_tbl = unfulfilled_requests[ln]
    local networkContents = ln.get_contents()
    -- max positive int
    local maxcount = 2147483647

    for k, v in pairs(networkContents) do
        if (ln_tbl[k] and v < maxcount) then
            ln_tbl[k] = ln_tbl[k] - v
            if (ln_tbl[k] <= 0) then
                ln_tbl[k] = nil
            end
        end
    end
end

function buildGUIList(player, basegui, network)

    -- basegui['itemTable'].clear();
    for k, v in pairs(getRelativeRequestTable(network, player)) do
        local itemProto = game.item_prototypes[k]
        -- local itemProto = game.item_prototypes[k].name
        -- local localeName = player.request_translation()
        -- local itemflow = basegui.add({
        --     name = k .. "-flow",
        --     type = "flow",
        --     direction = "horizontal"
        -- })
        local itembutton = basegui['itemTable'].add({
            name = k .. "-spritebutton-",
            tooltip = {
                "",
                itemProto.localised_name,
                '\nMissing: ' .. v
            },
            count = v,
            number = v,
            type = "sprite-button",
            style = "slot_button",
            sprite = 'item/' .. k
        })

        -- local itemsprite =
        --     itemflow.add({name = k .. '-sprite', type = 'sprite'})
        -- local itemlabel = itemflow.add({
        --     name = 'itemlabel',
        --     type = 'label',
        --     caption = {"", itemProto.localised_name, '\nMissing: ' .. v}
        -- })

        -- itemflow.style.vertical_align = "center"
        -- itemsprite.sprite = 'item/' .. k
        -- itemlabel.style.single_line = false
        -- itemlabel.style.vertical_align = "center"
        -- local line = basegui.add({type = "line", direction = "horizontal"})

    end
end

function addItemToUnfulfilledRequests(network, source, item, count)
    unfulfilled_requests[network] = unfulfilled_requests[network] or {}

    local reqItem = unfulfilled_requests[network][item]

    unfulfilled_requests[network][item] = count + (reqItem or 0)

    if (source.owner.prototype.logistic_mode == 'buffer') then
        bufferRequests[network] = bufferRequests[network] or {}
        local reqItemBuffer = bufferRequests[network][item]
        bufferRequests[network][item] = count + (reqItemBuffer or 0)
    end
end

function logisticNetworkHasUnfulfilledRequests(network, player)
    return not isEmptyTable(getRelativeRequestTable(network, player))
end

function getRequestsMinusBuffer(network)
    local diffTable = {}
    if (not bufferRequests[network]) then
        return unfulfilled_requests[network]
    end
    diffTable = util.copy(unfulfilled_requests[network])
    for k, v in pairs(bufferRequests[network]) do
        if (bufferRequests[network][k] and diffTable[k]) then
            diffTable[k] = math.max(diffTable[k] - bufferRequests[network][k], 0)
        end
        if (diffTable[k] == 0) then
            diffTable[k] = nil
        end
    end
    return diffTable
end

function getRelativeRequestTable(network, ply)
    local settings = global.plySettings[ply.index]
    local returnResult = (not settings or settings.includeBuffer) and unfulfilled_requests[network] or
                             getRequestsMinusBuffer(network)
    return returnResult
end

function isEmptyTable(tbl)
    return table_size(purgeTable(tbl)) == 0
end

-- Purges keys in table with 0
function purgeTable(tbl)
    for k, v in pairs(tbl) do
        if (v == 0) then
            tbl.k = nil
        end
    end

    return tbl
end

function unlockButtons(ply)
    if (ply.gui.screen['whats-missing-gui'] and ply.gui.screen['whats-missing-gui'].valid) then
        local bufferCheckbox = ply.gui.screen['whats-missing-gui']['bufferIncludeCheckbox']
        local refreshButton = ply.gui.screen['whats-missing-gui']['whats-missing-refresh']
        refreshButton.enabled = true
        bufferCheckbox.enabled = true
    end
end

function lockButtons(ply)
    if (ply.gui.screen['whats-missing-gui'] and ply.gui.screen['whats-missing-gui'].valid) then
        if (not __DebugAdapter) then
            local bufferCheckbox = ply.gui.screen['whats-missing-gui']['bufferIncludeCheckbox']
            local refreshButton = ply.gui.screen['whats-missing-gui']['whats-missing-refresh']
            refreshButton.enabled = false
            bufferCheckbox.enabled = false
            buttonQueue[ply.index] = game.tick + 60
        end
    end
end

function processQueue()
    for k, v in pairs(buttonQueue) do
        if (game.tick > v) then
            unlockButtons(game.players[k])
            table.remove(buttonQueue, k)
        end
    end
end

script.on_nth_tick(3, processQueue)
