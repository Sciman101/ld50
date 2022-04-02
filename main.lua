-- Boilerplate initialization
package.path = ";src.\\?.lua;lib.\\?.lua;" .. package.path -- Add the source directory to path
love.graphics.setDefaultFilter("nearest", "nearest") -- This is a pixel art game!
local mainCanvas, canvasWidth, canvasHeight

local loadStrip = require('loadStrip')

-- Load fonts
local Fonts = {
    monogram = love.graphics.newFont("assets/monogram.ttf",16)
}

-- Music
local Music = {
    love.audio.newSource('assets/music/crusher_calm.ogg','stream'),
    love.audio.newSource('assets/music/crusher_mid.ogg','stream'),
    love.audio.newSource('assets/music/crusher_extreme.ogg','stream'),
    targetTrack = 1,
    currentTrack = 1,
    fadeProgress = 0
}

local Sfx = {
    progress = love.audio.newSource('assets/sfx/progress.wav','static')
}

local StructureSprites = {
    scrap = loadStrip('assets/structures/Scrap.png',1),
    laser = loadStrip('assets/structures/Laser.png',4),
    block = loadStrip('assets/structures/Block.png',1),
    rocket = loadStrip('assets/structures/Rocket.png',1),
    button = loadStrip('assets/structures/Lever.png',5),
}
local PlayerSprites = {
    fwd = loadStrip('assets/player/PlayerForward.png',4),
    back = loadStrip('assets/player/PlayerBackward.png',4),
    right = loadStrip('assets/player/PlayerRight.png',4),
}
local WallTex = love.graphics.newImage('assets/wall/Wall.png')
local GearTex = love.graphics.newImage('assets/wall/Gear.png')

local BuildInfo = {
    q = {
        cost=2,
        type='laser'
    },
    w = {
        cost=3,
        type='block'
    },
    e = {
        cost=4,
        type='rocket'
    }
}
local StructInfo = {
    scrap = {
        health = 5,
        width = 48,
        height = 38,
        ox = 24,
        oy = 38
    },
    button = {
        health = 5,
        width = 48,
        height = 64,
        ox = 0,
        oy = 81
    },
    laser = {
        health = 2.5,
        width = 48,
        height = 38,
        ox = 24,
        oy = 38
    },
    block = {
        health = 10,
        width = 42,
        height = 30,
        ox = 24,
        oy = 36
    },
    rocket = {
        health = 0.05,
        width = 42,
        height = 14,
        ox = 48,
        oy = 18
    },
}

local theWall = 0
local wallHit = 0
local wallSpeed = 5
local player = {x=80, y=80, spd=160, hoverStruct=nil, buildProgress=0, scrapCount=50, dir=0, frame=1, wasMoving=false}

local timeAlive = 0
local alarm = false

local structures = {}

function love.load()

    -- setup canvas
	canvasWidth = love.graphics.getWidth()/2
	canvasHeight = love.graphics.getHeight()/2
    mainCanvas = love.graphics.newCanvas(canvasWidth,canvasHeight)

    -- load some initial scrap
    summonScrap()
    addStructure(0,canvasHeight/2+24,'button')

    -- Start music
    for i=1,3 do
        Music[i]:play()
        Music[i]:setVolume(0)
        Music[i]:setLooping(true)
    end
    Music[1]:setVolume(1)
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

function switchTrack(track)
    Music.currentTrack = track
    if Music.currentTrack ~= Music.targetTrack then
        fadeProgress = 1
    end
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
            if not Sfx.progress:isPlaying() then
                Sfx.progress:play()
            end

            if player.hoverStruct.type == 'button' then
                player.hoverStruct.frame = player.buildProgress * 4 + 2
            end

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
                Sfx.progress:stop()
            end
        end
    else
        player.buildProgress = 0
        if Sfx.progress:isPlaying() then
            Sfx.progress:stop()
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

        if struct.type ~= 'button' then
            local sprite = StructureSprites[struct.type]
            if sprite and #sprite.frames > 1 then
                struct.frame = struct.frame + dt * 10
                if struct.frame > #sprite.frames+1 then
                    struct.frame = 1
                end
            end
        end

        -- Structure behaviours
        if not struct.unfinished then
            -- laser kill
            if struct.type == 'laser' then
                speedMod = speedMod * 0.75
                --[[if player.x > struct.x + 20 and player.y > struct.y-31 and player.y < struct.y - 23 then
                    kill()
                end]]
            end

            -- rocket move
            if struct.type == 'rocket' then
                struct.speed = (struct.speed or 0) + dt * 200
                struct.x = struct.x + struct.speed* dt
            end
        end

        -- overlap the player
        if not player.hoverStruct then
            if struct.unfinished or (struct.type == 'scrap') or struct.type=='button' then
                -- check for player overlap
                if player.x > struct.x-struct.ox and player.y > struct.y-struct.oy+struct.height*0.5 and player.x < struct.x + struct.width - struct.ox and player.y < struct.y - struct.oy + struct.height*1.5 then
                    player.hoverStruct = struct
                end
            end
        end

        -- push or destroy structures
        struct.damaging = false
        if struct.x - struct.ox + struct.width > getWallX() then
            if struct.type == 'scrap' then
                -- push
                struct.x = getWallX() - struct.ox
            else
                if struct.health > 0 and not struct.unfinished then
                    speedMod = 0
                    struct.health = struct.health - dt
                    struct.damaging = true
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
    if player.x + 16 > getWallX() then
        player.x = getWallX() - 16
        if player.x < 8 then
            kill()
        end
    end

    -- Increment time
    timeAlive = timeAlive + dt

    -- move in the wall
    if wallHit <= 0 then
        theWall = theWall + wallSpeed * dt * speedMod
        wallSpeed = wallSpeed + dt * 0.05

        if theWall > canvasWidth*0.3 and Music.currentTrack == 1 then
            switchTrack(2)
        elseif theWall > canvasWidth*0.6 and Music.currentTrack == 2 then
            switchTrack(3)
            alarm = true
        end
    else
        theWall = theWall - wallHit * wallHit * dt * 15
        wallHit = wallHit - dt
        if theWall < 0 then
            theWall = 0
            wallHit = 0
            wallSpeed = wallSpeed * 1.5
        end
    end

    -- Music
    if Music.currentTrack ~= Music.targetTrack then
        Music[Music.currentTrack]:setVolume(1-fadeProgress)
        Music[Music.targetTrack]:setVolume(fadeProgress)
        fadeProgress = fadeProgress - dt
        if fadeProgress <= 0 then
            fadeProgress = 0
            Music[Music.currentTrack]:setVolume(1)
            Music[Music.targetTrack]:setVolume(0)
        end
    end

end

function addStructure(x,y,structType,unfinished)
    local struct = {
        x=x,y=y,type=structType,
        health=0,
        unfinished=unfinished,
        frame=1,
        damaging=false
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
            local next = structures[i+1]
            if structures[i].y < struct.y and (not next or (next.y > struct.y))then
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
        local scrap = addStructure(love.math.random(24,getWallX()-32),love.math.random(48,canvasHeight-48),'scrap')
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

    -- draw structures
    local playerDrawn = false
    if #structures == 0 or player.y < structures[1].y then
        playerDrawn = true
        drawPlayer()
    end

    for i=1,#structures do

        local struct = structures[i]
        drawStruct(struct,i)
        
        local nextStruct = i ~= #structures and structures[i+1] or nil
        if not playerDrawn and (not nextStruct or (player.y > struct.y and player.y < nextStruct.y)) then
            -- draw player
            drawPlayer()
            playerDrawn = true
        end
    end

    -- Draw the wall
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle('fill',getWallX(),0,theWall,canvasHeight)
    love.graphics.setColor(44/255,53/255,77/255)
    for j=1,2 do
        local yoff = j == 2 and -10 or 0
        for i=1,8 do
            local dir = i % 2 == 0 and 1 or -1
            local offset = i % 2 == 0 and 1 or 0
            local gx ,gy = 0, 0
            if wallHit > 0 then
                gx = love.math.random(-2,2)
                gy = love.math.random(-2,2)
            end
            love.graphics.draw(GearTex,getWallX()+60+gx,(i-1)*50+yoff+gy,timeAlive*dir+offset,1,1,30,30)
        end
        love.graphics.setColor(64/255,73/255,115/255)
    end
    love.graphics.setColor(1,1,1)
    for i=1,3 do
        love.graphics.draw(WallTex,getWallX(),(i-1)*148)
    end

    -- Uh oh sisters!
    if true or alarm then
        local a = math.abs(math.sin(timeAlive))
        love.graphics.setColor(1,0,0,a*0.2+0.1)
        love.graphics.setBlendMode('add')
        love.graphics.rectangle('fill',-64,-64,canvasWidth+64,canvasHeight+64)
        love.graphics.setColor(1,1,1)
        love.graphics.setBlendMode('alpha')
    end

    -- Draw tooltip
    if player.hoverStruct then
        local tooltip = "[space] - "
        if player.hoverStruct.unfinished then
            tooltip = tooltip .. "Build structure"
        elseif player.hoverStruct.type == 'scrap' then
            tooltip = tooltip .. "Harvest Scrap"
        elseif player.hoverStruct.type == 'button' then
            tooltip = tooltip .. "Pull scrap lever"
        end

        love.graphics.setFont(Fonts.monogram)

        love.graphics.setColor(0,0,0,0.5)
        local w = Fonts.monogram:getWidth(tooltip) + 4
        local tx = player.x - w/2
        local ty = player.y-48
        if tx < 8 then
            tx = 8
        elseif tx + w >= getWallX() - 8 then
            tx = getWallX() - 8 - w
        end
        if ty < 32 then ty = 32 end

        love.graphics.rectangle('fill',tx,ty,w,16)

        love.graphics.setColor(1,1,1)
        if player.buildProgress > 0 then
            love.graphics.line(tx,ty+16,tx+(w*player.buildProgress*player.buildProgress),ty+16)
        end

        love.graphics.printf(tooltip,tx+w/2-128,ty,256,'center')
    end

    -- HUD
    love.graphics.print("TIME: " .. tostring(timeAlive),8,8)
    love.graphics.print("Scrap: " .. tostring(player.scrapCount),8,24)

    --- END NORMAL DRAWING ---
    love.graphics.setCanvas()
    love.graphics.setColor(1,1,1)
    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.draw(mainCanvas,0,0,0,2,2)
end

function drawStruct(struct,idx)

    -- extra drawing
    if not struct.unfinished then
        if struct.type == 'laser' then
            love.graphics.setColor(1,0,0)
            local h = love.math.random(4,7)
            love.graphics.rectangle('fill',struct.x+20,struct.y-31+(4-h/2),canvasWidth-struct.x-theWall,h)
            love.graphics.circle('fill',getWallX(),struct.y-31+h/2,h*1.5)
            love.graphics.setColor(1,1,1)
            h = h * 0.25
            love.graphics.rectangle('fill',struct.x+20,struct.y-31+2+(2-h/2),canvasWidth-struct.x-theWall,h)
            love.graphics.circle('fill',getWallX(),struct.y-31+2+h/2,h)
        end
    end

    love.graphics.setColor(1,1,1)
    local sprite = StructureSprites[struct.type]
    local frame = struct.frame
    if struct.unfinished then
        -- draw unfinished structures as silouhettes
        love.graphics.setColor(0,0,0,0.5)
        frame = 1
    end
    if sprite then
        local y = struct.y
        local x = struct.x
        if struct.damaging then
            x = x + love.math.random(-1,1)
            y = y + love.math.random(-1,1)

            local maxHealth = StructInfo[struct.type].health
            local healthPercent = struct.health/maxHealth
            love.graphics.setColor(0,0,0)
            love.graphics.line(struct.x-struct.width*0.5,struct.y+8,struct.x+struct.width*0.5,struct.y+8)
            love.graphics.setColor(1,0,0)
            love.graphics.line(struct.x-struct.width*0.5,struct.y+8,struct.x+(struct.width*(healthPercent-0.5)),struct.y+8)
            love.graphics.setColor(1,1,1)
        end
        if frame > #sprite.frames then frame = #sprite.frames end
        love.graphics.draw(sprite.sprite,sprite.frames[math.floor(frame)],x,y,0,1,1,struct.ox,struct.oy)
    end
end

function drawPlayer()
    love.graphics.setColor(1,1,1)
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