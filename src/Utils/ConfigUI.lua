local addonName, addon = ...
local PeaversSafeList = _G.PeaversSafeList

local ConfigUI = {}
PeaversSafeList.ConfigUI = ConfigUI

-- Access PeaversCommons utilities
local PeaversCommons = _G.PeaversCommons
local FrameUtils = PeaversCommons.FrameUtils
local ConfigUIUtils = PeaversCommons.ConfigUIUtils

-- Utility functions to reduce code duplication (using PeaversCommons.ConfigUIUtils)
local Utils = {}

-- Creates a slider with standardized formatting
function Utils:CreateSlider(parent, name, label, min, max, step, defaultVal, width, callback)
    return ConfigUIUtils.CreateSlider(parent, name, label, min, max, step, defaultVal, width, callback)
end

-- Creates a dropdown with standardized formatting
function Utils:CreateDropdown(parent, name, label, options, defaultOption, width, callback)
    return ConfigUIUtils.CreateDropdown(parent, name, label, options, defaultOption, width, callback)
end

-- Creates a checkbox with standardized formatting
function Utils:CreateCheckbox(parent, name, label, x, y, checked, callback)
    return ConfigUIUtils.CreateCheckbox(parent, name, label, x, y, checked, callback)
end

-- Creates a section header with standardized formatting
function Utils:CreateSectionHeader(parent, text, indent, yPos, fontSize)
    return ConfigUIUtils.CreateSectionHeader(parent, text, indent, yPos, fontSize)
end

-- Creates a subsection label with standardized formatting
function Utils:CreateSubsectionLabel(parent, text, indent, y)
    return ConfigUIUtils.CreateSubsectionLabel(parent, text, indent, y)
end

-- Creates a button with standardized formatting
function Utils:CreateButton(parent, name, text, x, y, width, height, onClick)
    return FrameUtils.CreateButton(parent, name, text, x, y, width, height, onClick)
end

-- Creates a separator with standardized formatting
function Utils:CreateSeparator(parent, x, y, width)
    return FrameUtils.CreateSeparator(parent, x, y, width)
end

function ConfigUI:InitializeOptions()
    -- Use the ConfigUIUtils to create a standard settings panel
    local panel = ConfigUIUtils.CreateSettingsPanel(
        "Settings",
        "Create a safelist of items to prevent auto-selling"
    )
    
    local content = panel.content
    local yPos = panel.yPos
    local baseSpacing = panel.baseSpacing
    local controlIndent = baseSpacing + 15
    
    -- SECTION 1: Commands
    local commandsHeader, newY = Utils:CreateSectionHeader(content, "Available Commands", baseSpacing, yPos)
    yPos = newY - 10
    
    local commandsList = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    commandsList:SetPoint("TOPLEFT", controlIndent, yPos)
    commandsList:SetWidth(400)
    commandsList:SetJustifyH("LEFT")
    commandsList:SetText(
        "/psl - Show command help\n" ..
        "/psl save - Save your current inventory as your safelist\n" ..
        "/psl sell - Sell all items not in your safelist\n" ..
        "/psl show - Show how many items are in your safelist\n" ..
        "/psl clear - Clear your safelist\n" ..
        "/psl debug - Toggle debug mode\n" ..
        "/psl config - Open this settings panel"
    )
    
    -- Calculate height of the text
    local textHeight = commandsList:GetStringHeight() + 15
    yPos = yPos - textHeight
    
    -- Add separator
    local _, newY = Utils:CreateSeparator(content, baseSpacing, yPos)
    yPos = newY - 15
    
    -- SECTION 2: Settings
    local settingsHeader, newY = Utils:CreateSectionHeader(content, "Settings", baseSpacing, yPos)
    yPos = newY - 10
    
    -- Debug mode checkbox
    local _, newY = Utils:CreateCheckbox(
        content,
        "PSLDebugCheckbox",
        "Enable Debug Mode",
        controlIndent,
        yPos,
        PeaversSafeList.Config.DEBUG_ENABLED,
        function(checked)
            PeaversSafeList.Config.DEBUG_ENABLED = checked
            PeaversSafeList.Config:Save()
        end
    )
    yPos = newY - 15
    
    -- Add separator
    local _, newY = Utils:CreateSeparator(content, baseSpacing, yPos)
    yPos = newY - 15
    
    -- SECTION 3: Database Management
    local dbHeader, newY = Utils:CreateSectionHeader(content, "Database Management", baseSpacing, yPos)
    yPos = newY - 15
    
    -- Add database info
    local itemCount = 0
    for _ in pairs(PeaversSafeList.Config.items or {}) do
        itemCount = itemCount + 1
    end
    
    local dbInfo = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    dbInfo:SetPoint("TOPLEFT", controlIndent, yPos)
    dbInfo:SetWidth(400)
    dbInfo:SetJustifyH("LEFT")
    dbInfo:SetText("Items in safelist: " .. itemCount)
    yPos = yPos - 25
    
    -- Save inventory button
    local saveBtn, saveY = Utils:CreateButton(
        content, 
        "PSLSaveButton", 
        "Save Current Inventory", 
        controlIndent, 
        yPos, 
        200, 
        25, 
        function()
            PeaversSafeList:SaveInventory()
            -- Update the item count after saving
            local newCount = 0
            for _ in pairs(PeaversSafeList.Config.items or {}) do
                newCount = newCount + 1
            end
            dbInfo:SetText("Items in safelist: " .. newCount)
        end
    )
    yPos = saveY - 10
    
    -- Clear database button
    local clearBtn, clearY = Utils:CreateButton(
        content, 
        "PSLClearButton", 
        "Clear Safelist", 
        controlIndent, 
        yPos, 
        200, 
        25, 
        function()
            PeaversSafeList:ClearSafeList()
            dbInfo:SetText("Items in safelist: 0")
        end
    )
    yPos = clearY - 20
    
    -- Update content height
    panel:UpdateContentHeight(yPos)
    
    return panel
end

function ConfigUI:Initialize()
    self.panel = self:InitializeOptions()
end

return ConfigUI