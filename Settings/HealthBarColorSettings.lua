local _, addonTable = ...

local featureId = "SCRB_HEALTH_BAR_COLORS"

addonTable.AvailableFeatures = addonTable.AvailableFeatures or {}
table.insert(addonTable.AvailableFeatures, featureId)

addonTable.FeaturesMetadata = addonTable.FeaturesMetadata or {}
addonTable.FeaturesMetadata[featureId] = {
	panel = "SCRBHealthBarColorSettings",
	searchTags = { "Text Colors" },
}

SCRBHealthBarColorSettingsMixin = {
	BarData = {
		{
			text = "Health",
			settingKey = "HEALTH",
		},
	},
    TextData = {
		{
			text  = "Health Number",
			settingKey = addonTable.TextId.ResourceNumber,
		},
	},
}

function SCRBHealthBarColorSettingsMixin:Init(initializer)
	if not SenseiClassResourceBarDB["_Settings"][addonTable.RegistereredBar.HealthBar.frameName] then
		SenseiClassResourceBarDB["_Settings"][addonTable.RegistereredBar.HealthBar.frameName] = {}
	end
	if not SenseiClassResourceBarDB["_Settings"][addonTable.RegistereredBar.HealthBar.frameName]["TextColors"] then
		SenseiClassResourceBarDB["_Settings"][addonTable.RegistereredBar.HealthBar.frameName]["TextColors"] = {}
	end
	if not SenseiClassResourceBarDB["_Settings"][addonTable.RegistereredBar.HealthBar.frameName]["BarColors"] then
		SenseiClassResourceBarDB["_Settings"][addonTable.RegistereredBar.HealthBar.frameName]["BarColors"] = {}
	end

	self.categoryID = initializer.data.categoryID;

	for _, data in ipairs(SCRBHealthBarColorSettingsMixin.TextData) do
		initializer:AddSearchTags(data.text);
	end

	self.NewFeature:SetShown(not SenseiClassResourceBarDB["_Settings"]["NewFeaturesShown"][featureId])
	self.Header:SetText(addonTable.RegistereredBar.HealthBar.editModeName or "Health Resource Bar")

	SenseiClassResourceBarDB["_Settings"]["NewFeaturesShown"][featureId] = true
end

function SCRBHealthBarColorSettingsMixin:GetOverrideValue(frame)
	if frame.dataType == "BarColors" then
		return addonTable:GetOverrideHealthBarColor(addonTable.RegistereredBar.HealthBar.frameName, frame.data.settingKey)
	elseif frame.dataType == "TextColors" then
		return addonTable:GetOverrideTextColor(addonTable.RegistereredBar.HealthBar.frameName, frame.data.settingKey)
	end
	error("No data type corresponding")
end

function SCRBHealthBarColorSettingsMixin:GetDefaultValue(frame)
	if frame.dataType == "BarColors" then
		return addonTable:GetHealthBarColor()
	elseif frame.dataType == "TextColors" then
		return addonTable:GetTextColor()
	end
	error("No data type corresponding")
end

function SCRBHealthBarColorSettingsMixin:SetValue(frame, value)
	SenseiClassResourceBarDB["_Settings"][addonTable.RegistereredBar.HealthBar.frameName][frame.dataType][frame.data.settingKey] = value
end

function SCRBHealthBarColorSettingsMixin:OnLoad()
	self.ColorOverrideFramePool = CreateFramePool("FRAME", self.SCRBHealthBarColorSetting, "ColorOverrideTemplate", nil)
	self.colorOverrideFrames = {}

	local function ResetColorSwatches()
		for _, frame in ipairs(self.colorOverrideFrames) do
			SenseiClassResourceBarDB["_Settings"][addonTable.RegistereredBar.HealthBar.frameName][frame.dataType][frame.data.settingKey] = nil -- Remove override
			addonTable.updateBars()

			local color = self:GetDefaultValue(frame) -- Default
			if color then
				frame.Text:SetTextColor(CreateColor(color.r, color.g, color.b):GetRGB())
				frame.ColorSwatch.Color:SetVertexColor(CreateColor(color.r, color.g, color.b):GetRGB())
			end
		end
	end
	EventRegistry:RegisterCallback("Settings.Defaulted", ResetColorSwatches)

	local function CategoryDefaulted(_, category)
		if self.categoryID == category:GetID() then
			ResetColorSwatches()
		end
	end
	EventRegistry:RegisterCallback("Settings.CategoryDefaulted", CategoryDefaulted)

	for index, data in ipairs(SCRBHealthBarColorSettingsMixin.BarData) do
		local frame = self.ColorOverrideFramePool:Acquire()
		frame.layoutIndex = index
		frame.dataType = "BarColors"
		self:SetupColorSwatch(frame, data)
		frame:Show()

		table.insert(self.colorOverrideFrames, frame)
	end

	for index, data in ipairs(SCRBHealthBarColorSettingsMixin.TextData) do
		local frame = self.ColorOverrideFramePool:Acquire()
		frame.layoutIndex = #SCRBHealthBarColorSettingsMixin.BarData + index
		frame.dataType = "TextColors"
		self:SetupColorSwatch(frame, data)
		frame:Show()

		table.insert(self.colorOverrideFrames, frame)
	end
end

function SCRBHealthBarColorSettingsMixin:SetupColorSwatch(frame, data)
	frame.data = data

    frame.Text:SetText(frame.data.text)

	local color = self:GetOverrideValue(frame)
	if color then
		frame.Text:SetTextColor(CreateColor(color.r, color.g, color.b):GetRGB())
		frame.ColorSwatch.Color:SetVertexColor(CreateColor(color.r, color.g, color.b):GetRGB())
	end

	frame.ColorSwatch:SetScript("OnClick", function()
		self:OpenColorPicker(frame)
	end)
end

function SCRBHealthBarColorSettingsMixin:OpenColorPicker(frame)
	local info = UIDropDownMenu_CreateInfo()

	local overrideInfo = SenseiClassResourceBarDB["_Settings"][addonTable.RegistereredBar.HealthBar.frameName][frame.dataType][frame.data.settingKey] -- Override

	local color = self:GetOverrideValue(frame)
	if color then
		info.r, info.g, info.b = color.r or 1, color.g or 1, color.b or 1
	end

	info.extraInfo = nil
	info.swatchFunc = function ()
		local r, g, b = ColorPickerFrame:GetColorRGB()
		frame.Text:SetTextColor(r, g, b)
		frame.ColorSwatch.Color:SetVertexColor(r, g, b)

		SenseiClassResourceBarDB["_Settings"][addonTable.RegistereredBar.HealthBar.frameName][frame.dataType][frame.data.settingKey] = { r = r, g = g, b = b } -- Set override
		addonTable.updateBars()
	end

	info.cancelFunc = function ()
		local r, g, b = ColorPickerFrame:GetPreviousValues()
		frame.Text:SetTextColor(r, g, b)
		frame.ColorSwatch.Color:SetVertexColor(r, g, b)

		if overrideInfo then
			SenseiClassResourceBarDB["_Settings"][addonTable.RegistereredBar.HealthBar.frameName][frame.dataType][frame.data.settingKey] = { r = r, g = g, b = b } -- Set override
		else
			SenseiClassResourceBarDB["_Settings"][addonTable.RegistereredBar.HealthBar.frameName][frame.dataType][frame.data.settingKey] = nil -- Remove override
		end
		addonTable.updateBars()
	end

	ColorPickerFrame:SetupColorPickerAndShow(info)
end
