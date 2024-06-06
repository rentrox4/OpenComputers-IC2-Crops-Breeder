robot = require("robot")
computer = require("computer")
component = require("component")
event = require("event")


-- Waiting if obstacle is in the way
function try_forward()
    while robot.forward() == nil do
        print("Obstacle in the way")
        computer.beep(500)
        os.sleep(1)
    end
end


-- Move to the coordinates, perform the action, return to the service area
function move_XY(xPoint, yPoint, blockAction)
    -- Move to the field start point: x = 1, y = 1
    try_forward()
    try_forward()
    y = y + 2
    robot.turnLeft()
    try_forward()
    x = x - 1
    robot.turnRight()
    
    -- Move to the y-coordinate of the block
    while y < yPoint do
        try_forward()
        y = y + 1
    end
    
    -- Move to the x-coordinate of the block
    robot.turnRight()
    while x < xPoint do
        try_forward()
        x = x + 1
    end
    
    -- Place or break the block
    if blockAction == "Place" then
        robot.placeUp()
        table.insert(occupiedCoords, {x, y})
        totalInstalledBlocks = totalInstalledBlocks + 1
        print("Total installed blocks: " .. totalInstalledBlocks)
    elseif blockAction == "Break" then
        robot.swingUp()
        table.remove(occupiedCoords, table_search(occupiedCoords, {x, y}))
    end
    
    -- Return to the field start point by x-coordinate: x = 1
    robot.turnAround()
    while x > 1 do
        try_forward()
        x = x - 1
    end
    
    -- Return to the field start point by y-coordinate: y = 1
    robot.turnLeft()
    while y > 1 do
        try_forward()
        y = y - 1
    end
    
    -- Move to the service area: x = 2, y = -1
    robot.turnLeft()
    try_forward()
    x = x + 1
    robot.turnRight()
    try_forward()
    try_forward()
    y = y - 2
    robot.turnAround()
end


-- Search in a table: index - if found, 0 - if not found
-- Table type example: {{4, 9}, {2, 5}, ...}
-- Searched item type example: {2, 5}
function table_search(table1, item)
    for i = 1, #table1 do
        if table1[i][1] == item[1] and table1[i][2] == item[2] then
            return i
        end
    end
    return 0
end


component.modem.open(1)
totalInstalledBlocks = 0  -- Statistics variable
x, y = 2, -1
occupiedCoords = {}

while true do
    -- Pulling the data of the next available signal from the queue
    _, _, _, _, _, xPoint, yPoint, block, blockAction = event.pull("modem")
    -- Unmature crop: place the block if the coordinates are not occupied
    if (blockAction == "Place" and
        table_search(occupiedCoords, {xPoint, yPoint}) == 0) then
        print("x = " .. xPoint .. ", y = " .. yPoint .. " - " ..
              blockAction .. " " .. block)
        -- Getting the block from the chest
        robot.turnRight()
        try_forward()
        for i = 1, component.inventory_controller.getInventorySize(0) do
            item = component.inventory_controller.getStackInSlot(0, i)
            if item ~= nil and item["label"] == block then
                component.inventory_controller.suckFromSlot(0, i, 1)
            end
        end
        robot.turnAround()
        try_forward()
        robot.turnRight()
        -- If the block is not found in the chest, do nothing
        if robot.count(1) ~= 0 then
            move_XY(xPoint, yPoint, "Place")
        else
            print(block .. " is not found in the chest")
        end
    -- Mature crop: break the block if the coordinates are occupied
    elseif (blockAction == "Break" and
            table_search(occupiedCoords, {xPoint, yPoint}) ~= 0) then
        print("x = " .. xPoint .. ", y = " .. yPoint .. " - " .. blockAction)
        move_XY(xPoint, yPoint, "Break")
        -- Store the breaked block in the chest
        robot.turnRight()
        try_forward()
        robot.dropDown()
        robot.turnAround()
        try_forward()
        robot.turnRight()
    end
end