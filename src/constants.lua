local loadStrip = require 'loadStrip'

Fonts = {
    monogram = love.graphics.newFont("assets/font/monogram.ttf",16),
    sevenseg = love.graphics.newFont('assets/font/Seven Segment.ttf',32)
}

Music = {
    love.audio.newSource('assets/music/crusher_calm.ogg','stream'),
    love.audio.newSource('assets/music/crusher_mid.ogg','stream'),
    love.audio.newSource('assets/music/crusher_extreme.ogg','stream'),
    targetTrack = 1,
    currentTrack = 1,
    fadeProgress = 0
}

Sfx = {
    progress = love.audio.newSource('assets/sfx/progress.wav','static')
}

StructureSprites = {
    scrap = loadStrip('assets/structures/Scrap.png',1),
    laser = loadStrip('assets/structures/Laser.png',4),
    block = loadStrip('assets/structures/Block.png',1),
    rocket = loadStrip('assets/structures/Rocket.png',1),
    button = loadStrip('assets/structures/Lever.png',5),
}
PlayerSprites = {
    fwd = loadStrip('assets/player/PlayerForward.png',4),
    back = loadStrip('assets/player/PlayerBackward.png',4),
    right = loadStrip('assets/player/PlayerRight.png',4),
}
WallTex = love.graphics.newImage('assets/wall/Wall.png')
GearTex = love.graphics.newImage('assets/wall/Gear.png')
ShadowTex = love.graphics.newImage('assets/structures/Shadow.png')
Background = love.graphics.newImage('assets/Background.png')

BuildInfo = {
    q = {
        cost=3,
        type='laser'
    },
    w = {
        cost=4,
        type='block'
    },
    e = {
        cost=6,
        type='rocket'
    }
}
BuildKeys = {'q','w','e'}
ShopInfo = {}
for i=1,3 do
    local k = BuildKeys[i]
    local v = BuildInfo[k]
    ShopInfo[#ShopInfo+1] = '['..k..'] Place ' .. v.type .. ' (' .. tostring(v.cost) .. ' scrap)'
end
StructInfo = {
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