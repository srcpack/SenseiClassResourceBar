local _, addonTable = ...

local LEM = addonTable.LEM or LibStub("LibEditMode")

local HealthBarMixin = Mixin({}, addonTable.BarMixin)
local buildVersion = select(4, GetBuildInfo())

function HealthBarMixin:GetBarColor()
    local playerClass = select(2, UnitClass("player"))

    local data = self:GetData()

    if data and data.useClassColor == true then
        local r,g, b = GetClassColor(playerClass)
        return { r = r, g = g, b = b }
    else
        return addonTable:GetOverrideHealthBarColor(addonTable.RegistereredBar.HealthBar.frameName, self:GetResource())
    end
end

function HealthBarMixin :GetResourceNumberColor()
    return addonTable:GetOverrideTextColor(addonTable.RegistereredBar.HealthBar.frameName, addonTable.TextId.ResourceNumber) or { r = 1, b = 1, g = 1}
end

function HealthBarMixin:GetResourceChargeTimerColor()
    return addonTable:GetOverrideTextColor(addonTable.RegistereredBar.HealthBar.frameName, addonTable.TextId.ResourceChargeNumber) or { r = 1, b = 1, g = 1}
end

function HealthBarMixin:GetResource()
    return "HEALTH"
end

function HealthBarMixin:GetResourceValue()
    local current = UnitHealth("player")
    local max = UnitHealthMax("player")
    if max <= 0 then return nil, nil, nil, nil end

    local data = self:GetData()
    if data and data.showHealthAsPercent then
        -- UnitHealthPercent does not exist prior to Midnight
        if (buildVersion or 0) < 120000 then
            return max, current, math.floor((current / max) * 100 + 0.5), "percent"
        else
            return max, current, UnitHealthPercent("player", true, true), "percent"
        end
    else
        return max, current, current, "number"
    end
end

function HealthBarMixin:OnLoad()
    self.Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.Frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
    self.Frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.Frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.Frame:RegisterEvent("PLAYER_TARGET_CHANGED")
end

function HealthBarMixin:OnEvent(event, ...)
    local unit = ...

    if event == "PLAYER_ENTERING_WORLD"
        or (event == "PLAYER_SPECIALIZATION_CHANGED" and unit == "player") then

        self:ApplyVisibilitySettings()
        self:ApplyLayout()
        self:UpdateDisplay()

    elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_TARGET_CHANGED" then

            self:ApplyVisibilitySettings(nil, event == "PLAYER_REGEN_DISABLED")
            self:UpdateDisplay()

    end
end

addonTable.HealthBarMixin = HealthBarMixin

addonTable.RegistereredBar = addonTable.RegistereredBar or {}
addonTable.RegistereredBar.HealthBar = {
    mixin = addonTable.HealthBarMixin,
    dbName = "healthBarDB",
    editModeName = "Health Bar",
    frameName = "HealthBar",
    frameLevel = 0,
    defaultValues = {
        point = "CENTER",
        x = 0,
        y = 40,
        barVisible = "Hidden",
        hideBlizzardPlayerContainerUi = false,
        showHealthAsPercent = false,
        useClassColor = true,
    },
    lemSettings = function(bar, defaults)
        local dbName = bar:GetConfig().dbName

        return {
            {
                order = 2,
                name = "Hide Blizzard UI",
                kind = LEM.SettingType.Checkbox,
                default = defaults.hideBlizzardPlayerContainerUi,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.hideBlizzardPlayerContainerUi ~= nil then
                        return data.hideBlizzardPlayerContainerUi
                    else
                        return defaults.hideBlizzardPlayerContainerUi
                    end
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].hideBlizzardPlayerContainerUi = value
                    bar:HideBlizzardPlayerContainer(layoutName)
                end,
            },
            {
                order = 41,
                name = "Show As Percent",
                kind = LEM.SettingType.Checkbox,
                default = defaults.showHealthAsPercent,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.showHealthAsPercent ~= nil then
                        return data.showHealthAsPercent
                    else
                        return defaults.showHealthAsPercent
                    end
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].showHealthAsPercent = value
                    bar:UpdateDisplay(layoutName)
                end,
            },
            {
                order = 63,
                name = "Use Class Color",
                kind = LEM.SettingType.Checkbox,
                default = defaults.useClassColor,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.useClassColor ~= nil then
                        return data.useClassColor
                    else
                        return defaults.useClassColor
                    end
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].useClassColor = value
                    bar:ApplyLayout(layoutName)
                end,
            }
        }
    end,
}