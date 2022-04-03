local loadStrip = require 'loadStrip'

Fonts = {
    monogram = love.graphics.newFont("assets/font/monogram.ttf",16)
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

BuildInfo = {
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