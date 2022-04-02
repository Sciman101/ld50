-- Boilerplate initialization
package.path = ";src.\\?.lua;lib.\\?.lua;" .. package.path -- Add the source directory to path
love.graphics.setDefaultFilter("nearest", "nearest") -- This is a pixel art game!
local mainCanvas, canvasWidth, canvasHeight

local loadStrip = require('loadStrip')

local StructureTextures = {
    scrap = love.graphics.newImage('assets/scrap.png'),
    laser = love.graphics.newImage('assets/laser.png'),
    button = love.graphics.newImage('assets/button.png'),
    block = love.graphics.newImage('assets/block.png'),
    rocket = love.graphics.newImage('assets/rocket.png'),
}
local PlayerTex = love.graphics.newImage('assets/player.png')
local PlayerSprites = {
    fwd = loadStrip('assets/player/PlayerForward.png',4),
    back = loadStrip('assets/player/PlayerBackward.png',4),
    right = loadStrip('assets/player/PlayerRight.png',4),
}

local BuildInfo = {
    q = {
        cost=2,
        type='laser'
    },
    w = {
        cost=3,
        type='block'
    },
    r = {
        cost=4,
        type='rocket'
    }
}
local StructInfo = {
    scrap = {
        health = 5,
        width = 130,
        height = 40,
        ox = 70,
        oy = 20
    },
    button = {
        health = 250,
        width = 130,
        height = 40,
        ox = 70,
        oy = 20
    },
    laser = {
        health = 25,
        width = 130,
        height = 40,
        ox = 70,
        oy = 20
    },
    block = {
        health = 100,
        width = 80,
        height = 40,
        ox = 70,
        oy = 20
    },
    rocket = {
        health = 1,
        width = 80,
        height = 40,
        ox = 70,
        oy = 20
    },
}

local theWall = 0
local wallHit = 0
local wallSpeed = 10
local player = {x=80, y=80, spd=160, hoverStruct=nil, buildProgress=0, scrapCount=0, dir=0, frame=1, wasMoving=false}

local timeAlive = 0

local structures = {}

function love.load()

    -- setup canvas
	canvasWidth = love.graphics.getWidth()/2
	canvasHeight = love.graphics.getHeight()/2
    mainCanvas = love.graphics.newCanvas(canvasWidth,canvasHeight)

    -- load some initial scrap
    summonScrap()
    addStructure(2,canvasHeight/2,'button')
end

-- try and place a structure
function love.keypressed(key,code,isrepeat)
    if BuildInfo[key] then
        local build = BuildInfo[key]
        if player.scrapCount >= build.cost then
            player.scrapCount = player.scrapCount - build.cost
            local struct = addStructure(player.x,player.y,build.type,true)
        end
    end
end

function getWallX()
    return canvasWidth-theWall
end

function kill()
    love.event.quit()
end

function love.update(dt)

    local speedMod = 1

    -- move player
    local moving = false
    if love.keyboard.isDown('right') then 
        player.x = player.x + player.spd * dt
        player.dir = 0
        moving = true
    end
    if love.keyboard.isDown('left') then 
        player.x = player.x - player.spd * dt
        player.dir = 2
        moving = true
    end
    if love.keyboard.isDown('up') then
        player.y = player.y - player.spd * dt
        player.dir = 3
        moving = true
    end
    if love.keyboard.isDown('down') then
        player.y = player.y + player.spd * dt
        player.dir = 1
        moving = true
    end
    if moving and not player.wasMoving then
        player.frame = 2
    end
    player.wasMoving = moving
    -- animate
    if moving then
        player.frame = player.frame + dt * 10
        if player.frame >= 5 then player.frame = 1 end
    else
        player.frame = 1
    end

    -- build
    if love.keyboard.isDown('space') then
        if player.hoverStruct then
            player.buildProgress = player.buildProgress + dt * 0.5

            -- check for building completion
            if player.buildProgress >= 1 then

                if player.hoverStruct.unfinished then
                    player.hoverStruct.unfinished = false

                elseif player.hoverStruct.type == 'scrap' then
                    -- destroy and award
                    removeStructure(player.hoverStruct)
                    player.scrapCount = player.scrapCount + 3
                
                elseif player.hoverStruct.type == 'button' then
                    summonScrap()
                end

                player.hoverStruct = nil
                player.buildProgress = 0
            end
        end
    end

    -- clamp player
    if player.x < 16 then player.x = 16 end
    if player.y < 16 then player.y = 16 end
    if player.y > canvasHeight-16 then player.y = canvasHeight-16 end

    local prevStruct = player.hoverStruct
    player.hoverStruct = nil
    -- loop structs
    local structsToRemove = {}
    for i=#structures,1,-1 do
        local struct = structures[i] 

        -- Structure behaviours
        if not struct.unfinished then
            -- laser kill
            if struct.type == 'laser' then
                speedMod = speedMod * 0.75
                if player.x > struct.x + 130 and player.y > struct.y and player.y < struct.y + 48 then
                    kill()
                end
            end

            -- rocket move
            if struct.type == 'rocket' then
                struct.x = struct.x + 250 * dt
            end
        end

        -- overlap the player
        if not player.hoverStruct then
            if struct.unfinished or struct.type == 'scrap' or struct.type=='button' then
                -- check for player overlap
                if player.x > struct.x-struct.ox and player.y > struct.y-struct.oy and player.x < struct.x + struct.width - struct.ox and player.y < struct.y - struct.oy + struct.width then
                    player.hoverStruct = struct
                end
            end
        end

        -- push or destroy structures
        if struct.x - struct.ox + struct.width > getWallX() then
            if struct.type == 'scrap' then
                -- push
                struct.x = getWallX() - 130
            else
                if struct.health > 0 and not unfinished then
                    speedMod = 0
                    struct.health = struct.health - dt * 5
                else
                    -- destroy
                    if struct.type == 'rocket' and not struct.unfinished then
                        wallHit = 1.5
                    end
                    removeStructure(struct)
                end
            end
        end
    end
    -- reset build progress if we're hovering over the wrong thing
    if player.hoverStruct ~= prevStruct then
        player.buildProgress = 0
    end

    -- death
    if player.x > getWallX()-8 then
        kill()
    end

    timeAlive = timeAlive + dt

    -- move in the wall
    if wallHit <= 0 then
        theWall = theWall + wallSpeed * dt * speedMod
        wallSpeed = wallSpeed + dt * 0.1
    else
        wallHit = wallHit - dt
        theWall = theWall - wallHit * dt * wallSpeed
        if theWall < 0 then
            theWall = 0
            wallHit = 0
            wallSpeed = wallSpeed * 1.5
        end
    end

end

function addStructure(x,y,structType,unfinished)
    local struct = {
        x=x,y=y,type=structType,
        health=0,
        unfinished=unfinished
    }
    local info = StructInfo[structType]
    if info then
        struct.health = info.health
        struct.width = info.width
        struct.height = info.height
        struct.ox = info.ox
        struct.oy = info.oy
    end
    
    -- insert into array
    if #structures == 0 then
        structures[1] = struct
    elseif structures[1].y > struct.y then
        table.insert(structures,1,struct)
    else
        for i=1,#structures do
            if structures[i].y < struct.y then
                table.insert(structures,i+1,struct)
                break
            end
        end
    end
    return struct
end

function removeStructure(struct)
    local index = 0
    for i=1,#structures do
        if structures[i] == struct then
            index = i
            break
        end
    end
    if index ~= 0 then
        table.remove(structures,index)
    end
end

function summonScrap()
    for i=1,3 do
        addStructure(love.math.random(24,500),love.math.random(24,500),'scrap')
    end
end

-- sort structures by y position
function ySort()
    table.sort(structures,function (a,b) return a.y < b.y end)
end

function love.draw()
    -- bg
    love.graphics.clear(0.4,0.4,0.4)

    -- reset color
    love.graphics.setColor(1,1,1)

    -- Set scaled canvas
    love.graphics.setCanvas(mainCanvas)
    love.graphics.clear()
    love.graphics.setBlendMode("alpha")
    --- START NORMAL DRAWING ---

    love.graphics.print("TIME: " .. tostring(timeAlive),8,8)
    love.graphics.print("speed: " .. tostring(wallSpeed),8,24)
    love.graphics.print("Build Progress: " .. tostring(player.buildProgress),8,40)
    love.graphics.print("Scrap: " .. tostring(player.scrapCount),8,56)

    -- draw structures
    local playerDrawn = false
    if #structures == 0 or player.y < structures[1].y then
        playerDrawn = true
        drawPlayer()
    end

    for i=1,#structures do

        local struct = structures[i]
        drawStruct(struct)
        
        local nextStruct = i ~= #structures and structures[i+1] or nil
        if not playerDrawn and (not nextStruct or (player.y > struct.y and player.y < nextStruct.y)) then
            -- draw player
            drawPlayer()
            playerDrawn = true
        end
    end

    -- Draw the wall
    love.graphics.rectangle('fill',getWallX(),0,theWall,canvasHeight)

    --- END NORMAL DRAWING ---
    love.graphics.setCanvas()
    love.graphics.setColor(1,1,1)
    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.draw(mainCanvas,0,0,0,2,2)
end

function drawStruct(struct)

    -- extra drawing
    if not struct.unfinished then
        if struct.type == 'laser' then
            love.graphics.setColor(1,0,0)
            local h = love.math.random(8,12)
            love.graphics.rectangle('fill',struct.x+130,struct.y-h/2+32,canvasWidth,h)
            love.graphics.circle('fill',getWallX(),struct.y-h/2+32,8+h)
        end
    end

    love.graphics.setColor(1,1,1)
    local tex = StructureTextures[struct.type]
    if struct.unfinished then
        -- draw unfinished structures as silouhettes
        love.graphics.setColor(0,0,0,0.5)
    end
    if tex then
        love.graphics.draw(tex,struct.x,struct.y,0,1,1,struct.ox,struct.oy)
    else
        print(struct.type,struct.becomes)
    end

end

function drawPlayer()
    local sprite = PlayerSprites.right
    local flip = false

    if player.dir == 0 or player.dir == 2 then
        sprite = PlayerSprites.right
        flip = player.dir == 2
    elseif player.dir == 1 then
        sprite = PlayerSprites.fwd
    else
        sprite = PlayerSprites.back
    end
    love.graphics.draw(sprite.sprite,sprite.frames[math.floor(player.frame)],player.x,player.y,0,flip and -1 or 1,1,16,32)
end