local ADDON_NAME, L = ...;

local I18N = LibStub("AceLocale-3.0"):GetLocale("TitanChallengeMode")
local TITAN_I18N = LibStub("AceLocale-3.0"):GetLocale("Titan", true)
local PLUGIN_NAME = "TITAN_CHALLENGE_MODE"

local Console = LibStub("AceConsole-3.0")
local sortedMaps = {}
local currentTooltipText = ""
local currentButtonText = ""

local chestRewards = {
    [0] = nil,
    [2] = 910,
    [3] = 910,
    [4] = 915,
    [5] = 915,
    [6] = 920,
    [7] = 925,
    [8] = 925,
    [9] = 930,
    [10] = 935,
    [11] = 940,
    [12] = 945,
    [13] = 950,
    [14] = 955,
    [15] = 960,
};

function GetLevelRewardColor(mythicLevel)
    local quality = {}
    if not mythicLevel then
        quality = ITEM_QUALITY_COLORS[0] -- poor
    elseif mythicLevel == nil then
        quality = ITEM_QUALITY_COLORS[0] -- poor
    elseif mythicLevel == 0 then
        quality = ITEM_QUALITY_COLORS[0] -- poor
    elseif mythicLevel < 4 then
        quality = ITEM_QUALITY_COLORS[1]  -- common
    elseif mythicLevel < 7 then
        quality = ITEM_QUALITY_COLORS[2] -- uncommon
    elseif mythicLevel < 10 then
        quality = ITEM_QUALITY_COLORS[3] -- rare
    elseif mythicLevel < 15 then
        quality = ITEM_QUALITY_COLORS[4] -- epic
    else
        quality = ITEM_QUALITY_COLORS[5] -- legendary
    end

    return { r = quality.r, g= quality.g, b=quality.b }

end

function ChallengeModeMapsUpdatedCallback()
    -- Console:Print("ChallengeModeMapsUpdatedCallback")
    local mapTable = C_ChallengeMode.GetMapTable()
    local mapNames = {}

    newMaps = {};
    local weeklyBest = 0;
    for index = 1, #mapTable do

        local mapChallengeModeId = mapTable[index]
        C_ChallengeMode.RequestLeaders(mapChallengeModeId)
        if (not mapNames[mapChallengeModeId] ) then
            mapNames[mapChallengeModeId] = C_ChallengeMode.GetMapInfo(mapChallengeModeId)
        end

        local lastCompletion, bestCompletion, bestLevel, affixes = C_ChallengeMode.GetMapPlayerStats(mapChallengeModeId);
        if (not bestLevel) then
            bestLevel = 0
        end
        if (bestLevel > weeklyBest) then
            weeklyBest = bestLevel
        end

        local recentBestTime, recentBestLevel = C_ChallengeMode.GetRecentBestForMap(mapChallengeModeId);
        tinsert(newMaps, { id = mapId , level = bestLevel, affixes = affixes, name =  mapNames[mapChallengeModeId], recentBestLevel =  recentBestLevel, recentBestTime = recentBestTime});
    end

    table.sort(newMaps, function(a, b) return a.name < b.name end);
    sortedMaps = newMaps
    updateTooltipText()
    TitanPanelButton_UpdateButton(PLUGIN_NAME)
end


function ChallengeModeLeadersUpdatedCallback()
    local topAttemptArray = C_ChallengeMode.GetGuildLeaders();
    if (topAttemptArray) then
        for index = 1, #topAttemptArray do
            local topAttempt = topAttemptArray[index]
        end
    end
    TitanPanelButton_UpdateButton(PLUGIN_NAME)
end

function ChallengeModeCompletedCallback()
    C_ChallengeMode.RequestMapInfo();
    C_ChallengeMode.RequestRewards();

end

function updateTooltipText()
    local tooltipText = ""

    if (sortedMaps and #sortedMaps) then
        local weeklyRuns = ""
        for mapIndex = 1, #sortedMaps do
            local thisMap = sortedMaps[mapIndex]
            if(thisMap.level > 0 ) then
                weeklyRuns = weeklyRuns ..
                        TitanUtils_GetColoredText(thisMap.name, NORMAL_FONT_COLOR) ..
                        " " .. TitanUtils_GetColoredText("[", HIGHLIGHT_FONT_COLOR) ..
                        TitanUtils_GetColoredText("+" .. thisMap.level, GetLevelRewardColor(thisMap.level)) ..
                        TitanUtils_GetColoredText("]", HIGHLIGHT_FONT_COLOR) .. "\r"
            end
        end

        if (weeklyRuns == "") then
            tooltipText = tooltipText .. TitanUtils_GetColoredText(I18N["You have not completed any mythic keystone dungeons this week."], NORMAL_FONT_COLOR)
        else
            tooltipText = tooltipText .. TitanUtils_GetColoredText(I18N["Your best runs this week:"], HIGHLIGHT_FONT_COLOR) .. "\r" .. weeklyRuns
        end
    end
    --        tooltipText = tooltipText .. TitanUtils_GetColoredText(mapName, HIGHLIGHT_FONT_COLOR)  .. "\r"
    currentTooltipText = tooltipText

end

local function ChallengeModeButtonText()
    local shouldDisplayLabelText = TitanGetVar(PLUGIN_NAME, "ShowLabelText")
    local shouldColorLabelText = TitanGetVar(PLUGIN_NAME, "LabelTextColor")

    local bestMap;
    local bestLevel = 0;
    if (sortedMaps and #sortedMaps) then
        for mapIndex = 1, #sortedMaps do
            local thisMap = sortedMaps[mapIndex]
            if(thisMap.level > bestLevel ) then
                bestLevel = thisMap.level
                bestMap = thisMap
            end
        end
    end

    local newButtonText = ""
    if (shouldDisplayLabelText) then
        local dungeonLabelColor
        if shouldColorLabelText then
            if bestMap and bestMap.name then
                -- color by dungeon level
                dungeonLabelColor = GetLevelRewardColor(bestMap.level)
            else
                -- color red - no dungeons
                dungeonLabelColor = RED_FONT_COLOR
            end
        else
            -- do not color
            dungeonLabelColor = NORMAL_FONT_COLOR
        end

        if (bestMap and bestMap.name) then
            newButtonText = TitanUtils_GetColoredText(bestMap.name, dungeonLabelColor)
        else
            newButtonText = TitanUtils_GetColoredText(I18N["None"], dungeonLabelColor)
        end
    end
    return newButtonText
end

local function ChallengeModeTooltipText()
    return currentTooltipText;
end

function PrepareMenuCallback()
    TitanPanelRightClickMenu_AddTitle(TitanPlugins[PLUGIN_NAME].menuText)
    TitanPanelRightClickMenu_AddToggleIcon(PLUGIN_NAME)
    TitanPanelRightClickMenu_AddToggleLabelText(PLUGIN_NAME)

    L_UIDropDownMenu_AddButton({
        checked = TitanGetVar(PLUGIN_NAME, "DisplayOnRightSide"),
        text = TITAN_I18N["TITAN_CLOCK_MENU_DISPLAY_ON_RIGHT_SIDE"],
        func = function (self)
            TitanToggleVar(PLUGIN_NAME, "DisplayOnRightSide");
            TitanPanel_InitPanelButtons();
        end
    });

    L_UIDropDownMenu_AddButton({
        checked = TitanGetVar(PLUGIN_NAME, "LabelTextColor"),
        text = I18N["Color Dungeon Name"],
        func = function (self)
            TitanToggleVar(PLUGIN_NAME, "LabelTextColor")
            TitanPanelButton_UpdateButton(PLUGIN_NAME)
            TitanPanel_InitPanelButtons();
        end
    });

    TitanPanelRightClickMenu_AddSpacer();
    TitanPanelRightClickMenu_AddCommand(TITAN_I18N["TITAN_PANEL_MENU_HIDE"], PLUGIN_NAME, TITAN_PANEL_MENU_FUNC_HIDE);
end

function GetInterfaceIcon()
    if C_ChallengeMode.IsWeeklyRewardAvailable() then
        return "Interface\\Icons\\Achievement_challengemode_gold"
    else
        return "Interface\\Icons\\Achievement_challengemode_silver"
    end
end

function RegisterPlugin()

    local frame = CreateFrame("Button", "TitanPanel" .. PLUGIN_NAME .."Button", CreateFrame("Frame", nil, UIParent), "TitanPanelComboTemplate")
    frame:SetFrameStrata("FULLSCREEN")
    frame:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
    frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnClick", function(self, button, ...)
        TitanPanelButton_OnClick(self, button)
    end)
    frame:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
    frame:RegisterEvent("CHALLENGE_MODE_LEADERS_UPDATE")
    frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")

    frame["CHALLENGE_MODE_MAPS_UPDATE"] = function (self) ChallengeModeMapsUpdatedCallback() end
    frame["CHALLENGE_MODE_LEADERS_UPDATE"] = function (self) ChallengeModeLeadersUpdatedCallback() end
    frame["CHALLENGE_MODE_COMPLETED"] = function (self) ChallengeModeCompletedCallback() end

    function frame:ADDON_LOADED(a1)
        if a1 ~= ADDON_NAME then
            return
        end

        self:UnregisterEvent("ADDON_LOADED")
        self.ADDON_LOADED = nil
        self.registry = {
            id = PLUGIN_NAME,
            menuText = "Challenge Modes|r",
            buttonTextFunction = "TitanPanelButton_ChallengeModeButtonText",
            tooltipTitle = I18N["Mythic Keystones"],
            tooltipTextFunction = "TitanPanelButton_ChallengeModeTooltipText",
            frequency = 1,
            icon = GetInterfaceIcon(),
            iconWidth = 16,
            category = "Information",
            version = GetAddOnMetadata(ADDON_NAME, "Version"),
            savedVariables = {
                ShowIcon = 1,
                DisplayOnRightSide = false,
                ShowLabelText = true,
                LabelTextColor = true
            }
        }
        C_ChallengeMode.RequestMapInfo();
        C_ChallengeMode.RequestRewards();
    end

    _G["TitanPanelRightClickMenu_Prepare" .. PLUGIN_NAME .. "Menu"] = PrepareMenuCallback
    _G["TitanPanelButton_ChallengeModeButtonText"] = ChallengeModeButtonText
    _G["TitanPanelButton_ChallengeModeTooltipText"] = ChallengeModeTooltipText

    return frame
end

RegisterPlugin()
