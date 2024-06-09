-- Growing new crops only with 21-31-0, 23-31-0 stats.
-- Store only 21-31-0, 23-31-0 crops seeds and the weed. Trash
-- everything else in the trash can to the right of the output chest.

robot = require("robot")
computer = require("computer")
component = require("component")

-- Field size: min - 2x2, recommended - 11x11
X_MAX, Y_MAX = 11, 11

-- Crops with the required block underneath the field to fully mature
CROPS_AND_BLOCKS = {
    ["Black Stonelilly"] = "Black Granite Cobblestone",
    ["White Stonelilly"] = "Marble Cobblestone",
    ["Nether Stonelilly"] = "Netherrack",
    ["Red Stonelilly"] = "Red Granite Cobblestone",
    ["Yellow Stonelilly"] = "End Stone",
    ["Gray Stonelilly"] = "Cobblestone",
    
    ["Copper Oreberry"] = "Block of Copper",
    ["Aluminium Oreberry"] = "Block of Aluminium",
    ["Gold Oreberry"] = "Block of Gold",
    ["Iron Oreberry"] = "Block of Iron",
    ["Tin Oreberry"] = "Block of Tin",
    
    ["Olivia"] = "Block of Olivine",
    ["Tine"] = "Block of Tin",
    ["Stagnium"] = "Block of Tin",
    ["Bauxia"] = "Block of Aluminium",
    ["Nickelback"] = "Block of Nickel",
    ["Shimmerleaf"] = "Quicksilver Block",
    ["Cinderpearl"] = "Block of Blaze",
    ["Sapphirum"] = "Block of Sapphire",
    ["Argentia"] = "Block of Silver",
    ["Plumbiscus"] = "Block of Lead",
    ["Plumbilia"] = "Block of Lead",
    ["Withereed"] = "Block of Coal",
    ["Cyprium"] = "Block of Copper",
    ["Coppon"] = "Block of Copper"
    }


-- Waiting if an obstacle is in the way
function try_forward()
    while robot.forward() == nil do
        print("An obstacle in the way")
        computer.beep(500)
        os.sleep(1)
    end
end


-- Move to the field start point: x = 1, y = 1
function move_to_field_start_point()
    try_forward()
    try_forward()
    y = y + 2
    robot.turnLeft()
    try_forward()
    x = x - 1
    crop_scan()
    robot.turnRight()
end


-- Crops scanning
function crop_scan()
    -- Excluding scanning of the parent crops
    if math.fmod(x - y, 4) ~= 0 then
        geolyzerResult = component.geolyzer.analyze(0)
        -- Excluding data processing of empty crops
        if geolyzerResult["crop:name"] ~= nil then
            -- Weed: collecting and placing double crop sticks
            if (geolyzerResult["crop:name"] == "weed" or
                geolyzerResult["crop:name"] == "Grass") then
                robot.useDown()
                component.inventory_controller.equip()
                robot.useDown()
                component.inventory_controller.equip()
            -- Check the stats: remove not 21-31-0 or 23-31-0 crops
            elseif ((geolyzerResult["crop:growth"] ~= 21 and
                    geolyzerResult["crop:growth"] ~= 23) or
                    geolyzerResult["crop:gain"] ~= 31 or
                    geolyzerResult["crop:resistance"] ~= 0) then
                robot.useDown()
                component.inventory_controller.equip()
                robot.useDown()
                component.inventory_controller.equip()
            -- Mature plant: collecting and placing double crop sticks
            elseif (geolyzerResult["crop:size"] ==
                    geolyzerResult["crop:maxSize"]) then
                robot.swingDown()
                component.inventory_controller.equip()
                robot.useDown()
                robot.useDown()
                component.inventory_controller.equip()
                component.modem.broadcast(1, x, y, _, "Break")
            -- Unmature plant: check for block requirement
            else
                for crop, block in pairs(CROPS_AND_BLOCKS) do
                    -- Note: string.lower is needed because some
                    -- crop names start with a lowercase letter
                    if (string.lower(geolyzerResult["crop:name"]) ==
                        string.lower(crop)) then
                        print("[" .. x .. ", " .. y .. "] - needs ".. block)
                        component.modem.broadcast(1, x, y, block, "Place")
                    end
                end
            end
        end
    end
end


x, y = 2, -1
move_to_field_start_point()

-- Traverse the field in snake pattern
while true do
    -- Column traverse up
    while y < Y_MAX do
        try_forward()
        y = y + 1
        crop_scan()
    end
    
    -- Move to the next column at the top
    if x < X_MAX then
        robot.turnRight()
        try_forward()
        x = x + 1
        crop_scan()
        robot.turnRight()
    else
        robot.turnAround()
    end
    
    -- Column traverse down
    while y > 1 do
        try_forward()
        y = y - 1
        crop_scan()
    end
    
    -- Move to the next column at the bottom
    if x < X_MAX then
        robot.turnLeft()
        try_forward()
        x = x + 1
        crop_scan()
        robot.turnLeft()
    else
        -- Move to the service area
        robot.turnRight()
        while x > 2 do
            try_forward()
            x = x - 1
        end
        robot.turnLeft()
        try_forward()
        try_forward()
        y = y - 2
        
        -- Loading 62 crop sticks into slot #1
        robot.turnLeft()
        try_forward()
        x = x + 1
        robot.suckDown(robot.space() - 2)
        
        -- Unload 21-31-0, 23-31-0 crops and weed
        try_forward()
        x = x + 1
        for slot = 2, robot.inventorySize() do
            item = component.inventory_controller.getStackInInternalSlot(slot)
            -- Slot empty check
            if item ~= nil then
                -- Slot crop check
                if item["crop"] ~= nil then
                    -- Unload 21-31-0, 23-31-0 crops
                    if ((item["crop"]["growth"] == 21 or
                        item["crop"]["growth"] == 23) and
                        item["crop"]["gain"] == 31 and
                        item["crop"]["resistance"] == 0) then
                        robot.select(slot)
                        robot.dropDown()
                    end
                -- Unload weed
                elseif item["label"] == "Weed" then
                    robot.select(slot)
                    robot.dropDown()
                end
            end
        end
        robot.select(1)
        
        -- Trash everything else
        try_forward()
        x = x + 1
        for slot = 2, robot.inventorySize() do
            item = component.inventory_controller.getStackInInternalSlot(slot)
            if item ~= nil then
                robot.select(slot)
                robot.dropDown()
            end
        end
        robot.select(1)
        
        -- Move to the charger
        robot.turnAround()
        try_forward()
        try_forward()
        try_forward()
        x = x - 3
        robot.turnRight()
        
        -- Statistics output
        print()
        print("Uptime: " .. computer.uptime() .. " sec")
        percentMemory = math.ceil(computer.freeMemory()
                                  / computer.totalMemory() * 100)
        print("Memory: " .. computer.freeMemory() .. " / " ..
              computer.totalMemory() .. " bytes (" .. percentMemory .. "%)")
        
        os.sleep(10)
        move_to_field_start_point()
    end
end
