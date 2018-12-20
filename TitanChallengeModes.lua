local ADDON_NAME, L = ...;

local I18N = LibStub("AceLocale-3.0"):GetLocale("TitanChallengeMode")
local TITAN_I18N = LibStub("AceLocale-3.0"):GetLocale("Titan", true)
local PLUGIN_NAME = "TITAN_CHALLENGE_MODE"

-- local Console = LibStub("AceConsole-3.0")
local Console = {}
function Console:Print() end

local sortedMaps = {}
local chestRewardLevel = {
    [0] = nil,
    [2] = 355,
    [3] = 355,
    [4] = 360,
    [5] = 360,
    [6] = 365,
    [7] = 370,
    [8] = 370,
    [9] = 375,
    [10] = 380,
    [11] = 380,
    [12] = 380,
    [13] = 380,
    [14] = 380,
    [15] = 380,
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
        quality = ITEM_QUALITY_COLORS[1] -- common
    elseif mythicLevel < 7 then
        quality = ITEM_QUALITY_COLORS[2] -- uncommon
    elseif mythicLevel < 10 then
        quality = ITEM_QUALITY_COLORS[3] -- rare
    elseif mythicLevel < 15 then
        quality = ITEM_QUALITY_COLORS[4] -- epic
    else
        quality = ITEM_QUALITY_COLORS[5] -- legendary
    end

    return { r = quality.r, g = quality.g, b = quality.b }
end

function ChallengeModeMapsUpdatedCallback(p_frame, p_event, ...)
    local mapTable = C_ChallengeMode.GetMapTable()
    local mapNames = {}

    newMaps = {};
    local weeklyBest = 0;
    for index = 1, #mapTable do
        local mapChallengeModeId = mapTable[index]

        if (not mapNames[mapChallengeModeId]) then
            local mapName, id, timeLimit, texture, backgroundTexture = C_ChallengeMode.GetMapUIInfo(mapChallengeModeId);
            mapNames[mapChallengeModeId] = mapName
            C_ChallengeMode.RequestLeaders(mapChallengeModeId)
        end

        -- local lastCompletion, bestCompletion, bestLevel, affixes = C_ChallengeMode.GetMapPlayerStats(mapChallengeModeId);
        local duration, bestCompletion, completionDate, affixes, members = C_MythicPlus.GetWeeklyBestForMap(mapChallengeModeId);
        if (not bestCompletion) then
            bestCompletion = 0
        end
        if (bestCompletion > weeklyBest) then
            weeklyBest = bestCompletion
        end
---        local recentBestTime, recentBestLevel = C_MythicPlus.GetWeeklyBestForMap(mapChallengeModeId);
        tinsert(newMaps, { id = mapChallengeModeId, level = bestCompletion, affixes = affixes, name = mapNames[mapChallengeModeId], recentBestLevel = bestCompletion });
    end

    table.sort(newMaps, function(a, b) return a.name < b.name end);
    sortedMaps = newMaps

    local button = TitanUtils_GetButton(PLUGIN_NAME);

    local icon = _G[button:GetName().."Icon"];
    TitanUtils_GetPlugin(PLUGIN_NAME).icon = GetInterfaceIcon()
    icon:SetTexture(TitanUtils_GetPlugin(PLUGIN_NAME).icon)

    TitanPanelButton_UpdateButton(PLUGIN_NAME)
    TitanPanelButton_SetButtonIcon(PLUGIN_NAME)
end


local function ChallengeModeButtonText()
    Console.Print("ChallengeModeButtonText")
    local bestMap;
    local bestLevel = 0;

    if (sortedMaps and #sortedMaps) then
        for mapIndex = 1, #sortedMaps do
            local thisMap = sortedMaps[mapIndex]
            if (thisMap.level > bestLevel) then
                bestLevel = thisMap.level
                bestMap = thisMap
            end
        end
    end

    local newButtonText = ""
    if (TitanGetVar(PLUGIN_NAME, "ShowLabelText")) then
        local dungeonLabelColor
        if (TitanGetVar(PLUGIN_NAME, "LabelTextColor")) then
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

    if (TitanGetVar(PLUGIN_NAME, "DisplayWeeklyBest")) then
        local highestLevelColor = GetLevelRewardColor(bestLevel)
        newButtonText = newButtonText .. TitanUtils_GetColoredText(" [+" .. bestLevel .. "]", highestLevelColor)
    end
    return newButtonText
end

local function ChallengeModeTooltipText()
    local tooltipText = ""
    local bestRunLevel = 0;

    local level, rewardLevel, nextRewardLevel = C_MythicPlus.GetWeeklyChestRewardLevel();
    local rewardAvailable = C_MythicPlus.IsWeeklyRewardAvailable()

    if rewardAvailable then
        Console.Print("reward available")
        tooltipText = tooltipText .. TitanUtils_GetColoredText(I18N["You still haven't claimed your rewards for this week."], RED_FONT_COLOR) .. "\n"
        RequestMythicPlusInfo()
    else
        Console.Print("reward not available")
    end

    if (sortedMaps and #sortedMaps) then
        local dungeonRuns = ""
        for mapIndex = 1, #sortedMaps do
            local thisMap = sortedMaps[mapIndex]
            if (thisMap.level > 0) then
                dungeonRuns = dungeonRuns ..
                        TitanUtils_GetColoredText(thisMap.name, NORMAL_FONT_COLOR) ..
                        " " .. TitanUtils_GetColoredText("[", HIGHLIGHT_FONT_COLOR) ..
                        TitanUtils_GetColoredText("+" .. thisMap.level, GetLevelRewardColor(thisMap.level)) ..
                        TitanUtils_GetColoredText("]", HIGHLIGHT_FONT_COLOR) .. "\r"
            end
            if (thisMap.level > bestRunLevel) then
                bestRunLevel = thisMap.level
            end
        end

        tooltipText = tooltipText .. dungeonRuns
        if (bestRunLevel == 0) then
            tooltipText = tooltipText .. TitanUtils_GetColoredText(I18N["You have not completed any mythic keystone dungeons this week."], NORMAL_FONT_COLOR)
        else

            if (bestRunLevel > 15) then
                weeklyRewardItemLevel = chestRewardLevel[15]
            else
                weeklyRewardItemLevel = chestRewardLevel[bestRunLevel]
            end

            local highestDungeonThisWeek = string.format(I18N["You've completed a +%s this week."], bestRunLevel)
            local weeklyChestContents = string.format(I18N["Your next weekly chest will contain an item of item level %s or above."], weeklyRewardItemLevel)

            tooltipText = tooltipText .. TitanUtils_GetColoredText(highestDungeonThisWeek, NORMAL_FONT_COLOR) .. "\n" ..
                    TitanUtils_GetColoredText(weeklyChestContents, NORMAL_FONT_COLOR) .. "\n" ..
                    TitanUtils_GetColoredText(I18N["Your best runs this week:"], HIGHLIGHT_FONT_COLOR) .. "\r" .. dungeonRuns
        end
    end
    return tooltipText
end

function ChallengeModeRightClickMenuPrepare()
    Console.Print("ChallengeModeRightClickMenuPrepare")

    TitanPanelRightClickMenu_AddTitle(TitanPlugins[PLUGIN_NAME].menuText)
    TitanPanelRightClickMenu_AddToggleIcon(PLUGIN_NAME)
    TitanPanelRightClickMenu_AddToggleLabelText(PLUGIN_NAME)

    L_UIDropDownMenu_AddButton({
        checked = TitanGetVar(PLUGIN_NAME, "DisplayOnRightSide"),
        text = TITAN_I18N["TITAN_CLOCK_MENU_DISPLAY_ON_RIGHT_SIDE"],
        func = function(self)
            TitanToggleVar(PLUGIN_NAME, "DisplayOnRightSide");
            TitanPanel_InitPanelButtons();
        end
    });

    L_UIDropDownMenu_AddButton({
        checked = TitanGetVar(PLUGIN_NAME, "LabelTextColor"),
        text = I18N["Color Label Text"],
        func = function(self)
            TitanToggleVar(PLUGIN_NAME, "LabelTextColor")
            TitanPanelButton_UpdateButton(PLUGIN_NAME)
            TitanPanel_InitPanelButtons();
        end
    });

    L_UIDropDownMenu_AddButton({
        checked = TitanGetVar(PLUGIN_NAME, "DisplayWeeklyBest"),
        text = I18N["Display Weekly Best Level"],
        func = function(self)
            TitanToggleVar(PLUGIN_NAME, "DisplayWeeklyBest")
            TitanPanelButton_UpdateButton(PLUGIN_NAME)
            TitanPanel_InitPanelButtons();
        end
    });

    TitanPanelRightClickMenu_AddSpacer();
    TitanPanelRightClickMenu_AddCommand(TITAN_I18N["TITAN_PANEL_MENU_HIDE"], PLUGIN_NAME, TITAN_PANEL_MENU_FUNC_HIDE);
end

function GetInterfaceIcon()
    local level, rewardLevel, nextRewardLevel = C_MythicPlus.GetWeeklyChestRewardLevel();
    if C_MythicPlus.IsWeeklyRewardAvailable() then
        return "Interface\\Icons\\Achievement_challengemode_gold"
    else
        return "Interface\\Icons\\Achievement_challengemode_silver"
    end
end

function RequestMythicPlusInfo()
    C_MythicPlus.RequestMapInfo();
    C_MythicPlus.RequestRewards();
end


function RegisterPlugin()
    Console.Print("RegisterPlugin")

    local frame = CreateFrame("Button", "TitanPanelTITAN_CHALLENGE_MODEButton", CreateFrame("Frame", nil, UIParent), "TitanPanelComboTemplate")
    frame["CHALLENGE_MODE_MAPS_UPDATE"] = function(self, event, ...) ChallengeModeMapsUpdatedCallback(self, event,...) end
    frame["CHALLENGE_MODE_COMPLETED"] = function(self,event, ...) RequestMythicPlusInfo(self, event, ...) end
    frame["PLAYER_ENTERING_WORLD"] = function(self,event, ...) RequestMythicPlusInfo(self, event, ...) end

    frame:SetScript("OnEvent", function(self, event, ...)
        Console.Print(event)
        if self[event] then
            self[event](self, event, ...)
        end
    end)
    frame:SetFrameStrata("FULLSCREEN")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
    frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")


    frame:SetScript("OnClick", function(self, button, ...)
        TitanPanelButton_OnClick(self, button)
    end)

    C_MythicPlus.RequestMapInfo();
    C_MythicPlus.RequestRewards();



    frame.registry = {
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
            LabelTextColor = true,
            DisplayWeeklyBest = true,
            DisplayHighestLevel = true
        }
    }


    function frame:ADDON_LOADED(a1)
        if a1 ~= ADDON_NAME then
            return
        end
        Console.Print("ADDON_LOADED")

        self:UnregisterEvent("ADDON_LOADED")
        self.ADDON_LOADED = nil
    end

    _G["TitanPanelRightClickMenu_Prepare" .. PLUGIN_NAME .. "Menu"] = ChallengeModeRightClickMenuPrepare
    _G["TitanPanelButton_ChallengeModeButtonText"] = ChallengeModeButtonText
    _G["TitanPanelButton_ChallengeModeTooltipText"] = ChallengeModeTooltipText

    RequestMythicPlusInfo()
    return frame
end

RegisterPlugin()

