--[[
    GD50
    Super Mario Bros. Remake

    -- LevelMaker Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

LevelMaker = Class{}
keyCollected = false

function LevelMaker.generate(width, height)
    local tiles = {}
    local entities = {}
    local objects = {}

    local tileID = TILE_ID_GROUND
    
    -- whether we should draw our tiles with toppers
    local topper = true
    local tileset = math.random(20)
    local topperset = math.random(20)

    -- insert blank tables into tiles for later access
    for x = 1, height do
        table.insert(tiles, {})
    end

    -- generate one key and one lock box in random position
    local lockBoxPosition = math.random(1, width)
    local keyPosition = math.random(1, width)
    local keySkin = math.random(1, 4)

    -- column by column generation instead of row; sometimes better for platformers
    for x = 1, width do
        local tileID = TILE_ID_EMPTY
        
        -- lay out the empty space
        for y = 1, 6 do
            table.insert(tiles[y],
                Tile(x, y, tileID, nil, tileset, topperset))
        end

        -- chance to just be emptiness
        if math.random(7) == 1 and x ~= 1 and lockBoxPosition ~= x and keyPosition ~= x then
            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, nil, tileset, topperset))
            end
        else
            tileID = TILE_ID_GROUND

            local blockHeight = 4

            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end

            -- chance to generate a pillar
            if math.random(8) == 1 then
                blockHeight = 2
                
                -- chance to generate bush on pillar
                if math.random(8) == 1 then
                    table.insert(objects,
                        GameObject {
                            texture = 'bushes',
                            x = (x - 1) * TILE_SIZE,
                            y = (4 - 1) * TILE_SIZE,
                            width = 16,
                            height = 16,
                            
                            -- select random frame from bush_ids whitelist, then random row for variance
                            frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7
                        }
                    )
                end
                
                -- pillar tiles
                tiles[5][x] = Tile(x, 5, tileID, topper, tileset, topperset)
                tiles[6][x] = Tile(x, 6, tileID, nil, tileset, topperset)
                tiles[7][x].topper = nil
            
            -- chance to generate bushes
            elseif math.random(8) == 1 and keyPosition ~= x then
                table.insert(objects,
                    GameObject {
                        texture = 'bushes',
                        x = (x - 1) * TILE_SIZE,
                        y = (6 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                        collidable = false
                    }
                )
            end

            if x == keyPosition then 
                table.insert(objects,
                    GameObject {
                        texture = 'keys-and-locks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight + 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = keySkin,
                        collidable = true,
                        consumable = true,
                        solid = false,

                        -- key has its own function to add to the player's score
                        onConsume = function(player, object)
                            gSounds['pickup']:play()
                            player.score = player.score + 500
                            keyCollected = true
                        end
                    }
                )
            end

            -- spawn a lock box
            if x == lockBoxPosition then 
                table.insert(objects,
                    GameObject {
                        texture = 'keys-and-locks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,

                        -- make it a random variant
                        frame = keySkin + 4,
                        collidable = true,
                        hit = false,
                        solid = true,
                        lockedBox = false,

                        -- collision function takes itself
                        onCollide = function(obj)
                            if not obj.hit then
                                if keyCollected then
                                    gSounds['pickup']:play()
                                    obj.hit = true

                                    -- spawn a flagpost
                                    local flagpost = GameObject {
                                        texture = 'flagposts',
                                        x = obj.x + 4,
                                        y = (blockHeight - 4) * TILE_SIZE,
                                        width = 8,
                                        height = 48,
                                        frame = 1,
                                        collidable = true,
                                        consumable = true,
                                        solid = false,

                                        -- gem has its own function to add the player's score
                                        onConsume = function(player, object)
                                            gSounds['pickup']:play()
                                            player.score = player.score + 1000

                                            -- end level here
                                            gStateMachine:change('play', { score = player.score, lastLevelWidth = width })
                                        end
                                    }

                                    -- spawn flag 
                                    local flag = GameObject {
                                        texture = 'flags',
                                        x = obj.x + 6,
                                        y = (blockHeight - 2) * TILE_SIZE,
                                        width = 16, 
                                        height = 10,
                                        frame = 1, 
                                        collidable = true,
                                        consumable = true,
                                        solid = false,

                                        onConsume = function(player, object)
                                            gSounds['pickup']:play()
                                            player.score = player.score + 1000

                                            gStateMachine:change('play', { score = player.score, lastLevelWidth = width})
                                        end
                                    }

                                    Timer.tween(2.0, {
                                        [flag] = {y = ((blockHeight - 4) * TILE_SIZE) + 4}
                                    })
                                    gSounds['powerup-reveal']:play()

                                    table.insert(objects, flagpost)
                                    table.insert(objects, flag)

                                end
                            end

                            gSounds['empty-block']:play()
                        end
                    }
                )
            -- chance to spawn a block
            elseif math.random(10) == 1 then
                table.insert(objects,

                    -- jump block
                    GameObject {
                        texture = 'jump-blocks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,

                        -- make it a random variant
                        frame = math.random(#JUMP_BLOCKS),
                        collidable = true,
                        hit = false,
                        solid = true,

                        -- collision function takes itself
                        onCollide = function(obj)

                            -- spawn a gem if we haven't already hit the block
                            if not obj.hit then

                                -- chance to spawn gem, not guaranteed
                                if math.random(5) == 1 then

                                    -- maintain reference so we can set it to nil
                                    local gem = GameObject {
                                        texture = 'gems',
                                        x = (x - 1) * TILE_SIZE,
                                        y = (blockHeight - 1) * TILE_SIZE - 4,
                                        width = 16,
                                        height = 16,
                                        frame = math.random(#GEMS),
                                        collidable = true,
                                        consumable = true,
                                        solid = false,

                                        -- gem has its own function to add to the player's score
                                        onConsume = function(player, object)
                                            gSounds['pickup']:play()
                                            player.score = player.score + 100
                                        end
                                    }
                                    
                                    -- make the gem move up from the block and play a sound
                                    Timer.tween(0.1, {
                                        [gem] = {y = (blockHeight - 2) * TILE_SIZE}
                                    })
                                    gSounds['powerup-reveal']:play()

                                    table.insert(objects, gem)
                                end

                                obj.hit = true
                            end

                            gSounds['empty-block']:play()
                        end
                    }
                )
            end
        end
    end

    local map = TileMap(width, height)
    map.tiles = tiles
    
    return GameLevel(entities, objects, map)
end