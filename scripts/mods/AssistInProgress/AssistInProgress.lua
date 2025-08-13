local mod = get_mod("AssistInProgress")

local UIHudSettings = require("scripts/settings/ui/ui_hud_settings")

----------------
-- Utility stuff

mod.players_being_helped = {}

local table_remove_elem = function(table, element)
    local i = -1
    for key, elem in pairs(table) do
        if elem == element then
            i = key
        end
    end
    if i >= 0 then
        table.remove(table, i)
    end
    return i >= 0
end

local name_from_player = function(player)
	local account_id = player and player:account_id()
	local account_name = account_id and Managers.data_service.social:get_player_info_by_account_id(account_id)
	local character_name = player and player:name()
	if character_name then
		return tostring(character_name)
	else
		return "A:"..tostring(account_name)
	end
end


----------------------------
-- Track who is being helped

mod:hook_safe(CLASS.CharacterStateMachine, "fixed_update", function(self, unit, dt, t, frame, ...)
    local state = self._state_current
    if not state then
        mod:echo("Error - state = nil")
        return
    end
    local assist = state._assist
    local being_assisted = assist and assist:in_progress()
    local player = state._player
    if not player then
        mod:echo("Error - player = nil")
        return
    end
    if not being_assisted then
        -- Player is not being helped
        local removed = table_remove_elem(mod.players_being_helped, player)
        if removed then
            mod:echo("Removed player from mod.players_being_helped: "..name_from_player(player))
        end
    elseif not table.contains(mod.players_being_helped, player) then
        -- Player is being helped, and was not known to be in the process of being helped
        table.insert(mod.players_being_helped, player)
        mod:echo("Added player to mod.players_being_helped: "..name_from_player(player))
    end
end)


------------------------------------------------------------------------------
--

-- Hook function - Adapt the icon on player portraits if a player is disabled but being helped
local set_portrait_icons = function(self, dt, t, player, ui_renderer)
    local supported_features = self._supported_features
    if not supported_features.status_icon then
        return
    end
    if not table.contains(mod.players_being_helped, player) then
        return
    end
    -- Player is being helped
    local player_status = self._player_status
    local status_icon = UIHudSettings.player_status_icons[player_status]
    --local status_color = UIHudSettings.player_status_colors[player_status]
    -- Make status icon rainbow (for testing)
    local col = function()
        return math.floor(1 + 254 * math.random())
    end
    local status_color = {255, col(), col(), col()}
    self:_set_status_icon(status_icon, status_color, ui_renderer)
    --[[
    local widgets_by_name = self._widgets_by_name
	local widget = widgets_by_name.status_icon
    self:_set_widget_visible(widget, false, ui_renderer)
    --]]
end

-- Hook function - 
local handle_assist_world_marker = function(self, dt, t, player, ui_renderer)
    local extensions = self:_player_extensions(player)
    local health_extension = extensions and extensions.health
    local unit_data_extension = extensions and extensions.unit_data
    local parent = self._parent
    --local disabled = self._disabled
    --local hogtied = self._hogtied

    local dead
	if health_extension then
		dead = not health_extension or not health_extension:is_alive()
	else
		dead = true
	end

    local disabled = false
	local knocked_down = false
	local hogtied = false
	local ledge_hanging = false
	local pounced = false
	local netted = false
	local warp_grabbed = false
	local mutant_charged = false
	local consumed = false
	local grabbed = false

	if not dead then
		disabled, knocked_down, hogtied, ledge_hanging, pounced, netted, warp_grabbed, mutant_charged, consumed, grabbed = self:_is_player_disabled(unit_data_extension)
	end

    if self._disabled_world_marker_id and table.contains(mod.players_being_helped, player) then
        -- World marker exists for disabled player, but they are being helped, so we remove the marker
        mod:echo("Removing assist world marker for player: "..name_from_player(player))
        Managers.event:trigger("remove_world_marker", self._disabled_world_marker_id)
        self._disabled_world_marker_id = nil
    end

    -- TODO: Add world marker if assist in cancelled?

    --[[
    if disabled and not hogtied and not consumed then
		local my_player = parent:player()

		if my_player ~= player and not self._disabled_world_marker_id then
			local player_unit = player.player_unit

			if Unit.alive(player_unit)  then

            end
        end
    end
    --]]
end

mod:hook_safe(CLASS.HudElementPlayerPanelBase, "_update_player_features", function(self, dt, t, player, ui_renderer)
    set_portrait_icons(self, dt, t, player, ui_renderer)
    handle_assist_world_marker(self, dt, t, player, ui_renderer)
end)