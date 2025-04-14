local PeaversSafeList = CreateFrame("Frame", "PeaversSafeListFrame")
PeaversSafeList:RegisterEvent("ADDON_LOADED")
PeaversSafeList:RegisterEvent("MERCHANT_SHOW")

-- Local variables
local addonName = "PeaversSafeList"
local safeListDB = {}
local debugMode = false

-- Print function for addon messages
local function Print(msg)
    print("|cFF00CCFF" .. addonName .. ":|r " .. msg)
end

-- Debug function for development
local function Debug(msg)
    if debugMode then
        print("|cFFFF9900" .. addonName .. " Debug:|r " .. msg)
    end
end

-- Initialize saved variables
function PeaversSafeList:Initialize()
    if not PeaversSafeListDB then
        PeaversSafeListDB = {}
    end

    safeListDB = PeaversSafeListDB
    Print("Addon loaded! Type '/psafe help' for commands.")
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

    Print("Saved " .. count .. " items to your safelist!")
end

-- Sell items not in safelist when at vendor
function PeaversSafeList:SellJunkItems()
    if not MerchantFrame:IsShown() then
        Print("You need to be at a vendor to sell items!")
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
        Print("Sold " .. soldCount .. " items for " .. gold .. "g " .. silver .. "s " .. copper .. "c")
    else
        Print("No items to sell!")
    end
end

-- Show safelist count
function PeaversSafeList:ShowSafeList()
    local count = 0
    for _ in pairs(safeListDB) do
        count = count + 1
    end

    Print("You have " .. count .. " items in your safelist.")
end

-- Clear the safelist
function PeaversSafeList:ClearSafeList()
    table.wipe(safeListDB)
    Print("Your safelist has been cleared!")
end

-- Event handler
PeaversSafeList:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        self:Initialize()
    elseif event == "MERCHANT_SHOW" then
        -- Optional: Auto-repair if you want to add that functionality
        -- self:AutoRepair()
    end
end)

-- Slash commands
SLASH_PEAVERSSAFELIST1 = "/psafe"
SLASH_PEAVERSSAFELIST2 = "/peaverssafelist"
SlashCmdList["PEAVERSSAFELIST"] = function(msg)
    msg = string.lower(msg)

    if msg == "save" or msg == "snapshot" then
        PeaversSafeList:SaveInventory()
    elseif msg == "sell" then
        PeaversSafeList:SellJunkItems()
    elseif msg == "show" or msg == "list" then
        PeaversSafeList:ShowSafeList()
    elseif msg == "clear" then
        PeaversSafeList:ClearSafeList()
    elseif msg == "debug" then
        debugMode = not debugMode
        Print("Debug mode " .. (debugMode and "enabled" or "disabled"))
    else
        Print("Commands:")
        Print("/psafe save - Save your current inventory as your safelist")
        Print("/psafe sell - Sell all items not in your safelist")
        Print("/psafe show - Show how many items are in your safelist")
        Print("/psafe clear - Clear your safelist")
        Print("/psafe debug - Toggle debug mode")
    end
end
