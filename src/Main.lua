local addonName, addon = ...
local PeaversSafeList = CreateFrame("Frame", "PeaversSafeListFrame")
_G.PeaversSafeList = PeaversSafeList

-- Access the PeaversCommons library
local PeaversCommons = _G.PeaversCommons
local Utils = PeaversCommons.Utils

-- Initialize addon metadata
PeaversSafeList.name = addonName
PeaversSafeList.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "1.0.0"

-- Local variables
local safeListDB = {}
local debugMode = false

-- Debug function for development (internal use)
local function Debug(msg)
    if debugMode then
        Utils.Debug(PeaversSafeList, msg)
    end
end

-- Initialize saved variables
function PeaversSafeList:Initialize()
    if not PeaversSafeListDB then
        PeaversSafeListDB = {}
    end

    safeListDB = PeaversSafeListDB

    -- Register for MERCHANT_SHOW event
    PeaversCommons.Events:RegisterEvent("MERCHANT_SHOW", function()
        -- Optional: Auto-repair if you want to add that functionality
        -- self:AutoRepair()
    end)
end

-- Create item key for database storage
function PeaversSafeList:CreateItemKey(itemLink)
    local itemID = GetItemInfoInstant(itemLink)
    if itemID then
        return tostring(itemID)
    end
    return nil
end

-- Save current inventory to safelist
function PeaversSafeList:SaveInventory()
    local count = 0

    -- Clear current safelist
    table.wipe(safeListDB)

    -- Loop through all bags
    for bag = 0, NUM_BAG_FRAMES do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemLink = C_Container.GetContainerItemLink(bag, slot)

            if itemLink then
                local itemKey = self:CreateItemKey(itemLink)
                if itemKey then
                    safeListDB[itemKey] = true
                    count = count + 1
                    Debug("Added to safelist: " .. itemLink)
                end
            end
        end
    end

    Utils.Print(PeaversSafeList, "Saved " .. count .. " items to your safelist!")
end

-- Sell items not in safelist when at vendor
function PeaversSafeList:SellJunkItems()
    if not MerchantFrame:IsShown() then
        Utils.Print(PeaversSafeList, "You need to be at a vendor to sell items!")
        return
    end

    local soldCount = 0
    local earnedMoney = 0

    -- Loop through all bags
    for bag = 0, NUM_BAG_FRAMES do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemLink = C_Container.GetContainerItemLink(bag, slot)

            if itemLink then
                local itemKey = self:CreateItemKey(itemLink)

                -- If item is not in safelist, sell it
                if itemKey and not safeListDB[itemKey] then
                    local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
                    local itemCount = itemInfo and itemInfo.stackCount or 0
                    local vendorPrice = select(11, GetItemInfo(itemKey)) or 0

                    -- Skip items with no vendor price
                    if vendorPrice > 0 then
                        C_Container.UseContainerItem(bag, slot)
                        soldCount = soldCount + 1
                        earnedMoney = earnedMoney + (vendorPrice * itemCount)
                        Debug("Sold: " .. itemLink .. " x" .. itemCount)
                    end
                end
            end
        end
    end

    -- Format gold for output
    local gold = math.floor(earnedMoney / 10000)
    local silver = math.floor((earnedMoney % 10000) / 100)
    local copper = earnedMoney % 100

    if soldCount > 0 then
        Utils.Print(PeaversSafeList, "Sold " .. soldCount .. " items for " .. gold .. "g " .. silver .. "s " .. copper .. "c")
    else
        Utils.Print(PeaversSafeList, "No items to sell!")
    end
end

-- Show safelist count
function PeaversSafeList:ShowSafeList()
    local count = 0
    for _ in pairs(safeListDB) do
        count = count + 1
    end

    Utils.Print(PeaversSafeList, "You have " .. count .. " items in your safelist.")
end

-- Clear the safelist
function PeaversSafeList:ClearSafeList()
    table.wipe(safeListDB)
    Utils.Print(PeaversSafeList, "Your safelist has been cleared!")
end

-- Register slash commands
PeaversCommons.SlashCommands:Register(addonName, "psl", {
    default = function()
        Utils.Print(PeaversSafeList, "Commands:")
        print("  /psl save - Save your current inventory as your safelist")
        print("  /psl sell - Sell all items not in your safelist")
        print("  /psl show - Show how many items are in your safelist")
        print("  /psl clear - Clear your safelist")
        print("  /psl debug - Toggle debug mode")
    end,
    save = function()
        PeaversSafeList:SaveInventory()
    end,
    snapshot = function()
        PeaversSafeList:SaveInventory()
    end,
    sell = function()
        PeaversSafeList:SellJunkItems()
    end,
    show = function()
        PeaversSafeList:ShowSafeList()
    end,
    list = function()
        PeaversSafeList:ShowSafeList()
    end,
    clear = function()
        PeaversSafeList:ClearSafeList()
    end,
    debug = function()
        debugMode = not debugMode
        Utils.Print(PeaversSafeList, "Debug mode " .. (debugMode and "enabled" or "disabled"))
    end,
})

-- Initialize addon using PeaversCommons Events module
PeaversCommons.Events:Init(addonName, function()
    PeaversSafeList:Initialize()
    
    -- DIRECT REGISTRATION APPROACH
    -- This ensures the addon appears in Options > Addons regardless of PeaversCommons logic
    C_Timer.After(0.5, function()
        -- Create the main panel (Support UI as landing page)
        local mainPanel = CreateFrame("Frame")
        mainPanel.name = "PeaversSafeList"
        
        -- Required callbacks
        mainPanel.OnRefresh = function() end
        mainPanel.OnCommit = function() end
        mainPanel.OnDefault = function() end
        
        -- Get addon version
        local version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "1.0.0"
        
        -- Add background image
        local ICON_ALPHA = 0.1
        local iconPath = "Interface\\AddOns\\" .. addonName .. "\\src\\Media\\Icon"
        local largeIcon = mainPanel:CreateTexture(nil, "BACKGROUND")
        largeIcon:SetTexture(iconPath)
        largeIcon:SetPoint("TOPLEFT", mainPanel, "TOPLEFT", 0, 0)
        largeIcon:SetPoint("BOTTOMRIGHT", mainPanel, "BOTTOMRIGHT", 0, 0)
        largeIcon:SetAlpha(ICON_ALPHA)
        
        -- Create header and description
        local titleText = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        titleText:SetPoint("TOPLEFT", 16, -16)
        titleText:SetText("Peavers Safe List")
        titleText:SetTextColor(1, 0.84, 0)  -- Gold color for title
        
        -- Version information
        local versionText = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        versionText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -8)
        versionText:SetText("Version: " .. version)
        
        -- Support information
        local supportInfo = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        supportInfo:SetPoint("TOPLEFT", 16, -70)
        supportInfo:SetPoint("TOPRIGHT", -16, -70)
        supportInfo:SetJustifyH("LEFT")
        supportInfo:SetText("Create a safelist of items to prevent auto-selling. If you enjoy this addon and would like to support its development, or if you need help, stop by the website.")
        supportInfo:SetSpacing(2)
        
        -- Website URL
        local websiteLabel = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        websiteLabel:SetPoint("TOPLEFT", 16, -120)
        websiteLabel:SetText("Website:")
        
        local websiteURL = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        websiteURL:SetPoint("TOPLEFT", websiteLabel, "TOPLEFT", 70, 0)
        websiteURL:SetText("https://peavers.io")
        websiteURL:SetTextColor(0.3, 0.6, 1.0)
        
        -- Additional info
        local additionalInfo = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        additionalInfo:SetPoint("BOTTOMRIGHT", -16, 16)
        additionalInfo:SetJustifyH("RIGHT")
        additionalInfo:SetText("Thank you for using Peavers Addons!")
        
        -- Create a settings panel with commands
        local settingsPanel = CreateFrame("Frame")
        settingsPanel.name = "Settings"
        
        -- Required callbacks
        settingsPanel.OnRefresh = function() end
        settingsPanel.OnCommit = function() end
        settingsPanel.OnDefault = function() end
        
        -- Add content
        local settingsTitle = settingsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        settingsTitle:SetPoint("TOPLEFT", 16, -16)
        settingsTitle:SetText("Settings")
        
        -- Add commands section
        local commandsTitle = settingsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        commandsTitle:SetPoint("TOPLEFT", settingsTitle, "BOTTOMLEFT", 0, -16)
        commandsTitle:SetText("Available Commands:")
        
        local commandsList = settingsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        commandsList:SetPoint("TOPLEFT", commandsTitle, "BOTTOMLEFT", 10, -8)
        commandsList:SetJustifyH("LEFT")
        commandsList:SetText(
            "/psl save - Save your current inventory as your safelist\n" ..
            "/psl sell - Sell all items not in your safelist\n" ..
            "/psl show - Show how many items are in your safelist\n" ..
            "/psl clear - Clear your safelist\n" ..
            "/psl debug - Toggle debug mode"
        )
        
        -- Register with the Settings API
        if Settings then
            -- Register main category
            local category = Settings.RegisterCanvasLayoutCategory(mainPanel, mainPanel.name)
            
            -- This is the CRITICAL line to make it appear in Options > Addons
            Settings.RegisterAddOnCategory(category)
            
            -- Store the category
            PeaversSafeList.directCategory = category
            PeaversSafeList.directPanel = mainPanel
            
            -- Register settings panel as subcategory
            local settingsCategory = Settings.RegisterCanvasLayoutSubcategory(category, settingsPanel, settingsPanel.name)
            PeaversSafeList.directSettingsCategory = settingsCategory
            
            -- Debug output
            if debugMode then
                Debug("Direct registration complete")
            end
        end
    end)
end, {
	announceMessage = "Type /psl config for options."
})
