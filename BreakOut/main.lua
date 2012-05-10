
local sprite = require "sprite"

---------------
-- PHYSICS SETUP
---------------
local physics = require "physics"

physics.start()
physics.setGravity( 0, 0 )

---------------
-- RNG
---------------
local mRand = math.random

---------------
-- SCREEN DIMENSIONS
---------------
local screenW, screenH = display.contentWidth, display.contentHeight

---------------
-- BACKGROUND
---------------
local background = display.newImage( "metal_bg.jpg", true )
background.x = screenW / 2
background.y = screenH / 2
background.label = "background"

---------------
-- BORDER
---------------
borderBody = { density = 1.0, friction=0, bounce=0 }

-- Left border that the ball bounces off of
local borderLeft = display.newRect( 0, 1, 1, 480 )
borderLeft:setFillColor(255, 255, 255, 0)
physics.addBody( borderLeft, "static",  borderBody )
 
-- Right border that the ball bounces off of
local borderRight = display.newRect( 319, 1, 1, 480 )
borderRight:setFillColor(255, 255, 255, 0)
physics.addBody( borderRight, "static",  borderBody )

-- Top border that the ball bounces off of
local borderTop = display.newRect( 0, 0, 320, 1 )
borderTop:setFillColor(255, 255, 255, 0)
physics.addBody( borderTop, "static",  borderBody )
 
-- Bottom sensor that lights up when the ball passes it
local borderBottom = display.newRect( 0, 479, 320, 5 )
borderBottom:setFillColor(255, 255, 255, 0)
physics.addBody( borderBottom, "static", borderBody )
borderBottom.isSensor = true
borderBottom.label = "borderBottom"
 

---------------
-- BALL
---------------
local ball = display.newCircle( screenW * 0.5, screenH * 0.5, 14)
ball:setFillColor(255, 255, 255, 255)
--ball.x = screenW * 0.5
--ball.y = screenH * 0.2
ball.label = "ball"

physics.addBody( ball, { density = 1.0, friction = 0, 
                         bounce = 1.01,  radius = ( ball.width / 2 ) } )
ball:setLinearVelocity( -100, 300 )

---------------
-- PADDLE
---------------
local paddleSpriteData = require( "paddleSpriteData" )
local paddleSpriteSheet = sprite.newSpriteSheetFromData( "paddleReverse.png", paddleSpriteData.getSpriteSheetData() )
local paddleSpriteSet   = sprite.newSpriteSet( paddleSpriteSheet, 1, 9)
local paddle = sprite.newSprite( paddleSpriteSet )
sprite.add( paddleSpriteSet, "paddleHit", 1, 9, 75, 1 )
paddle:prepare( "paddleHit" )
paddle.x = 100
paddle.y = 420
physics.addBody( paddle, "static", { density = 1.0, friction = 1, bounce = 0} )
paddle.label = "paddle"

---------------
-- BLOCKS
---------------
local blocks = {}
local blockGutter = 50
local blockGap = 10

---------------
-- GAMEPLAY
---------------
local ballInPlay = true

-------------------------------------------
-- Set a value to bounds
-------------------------------------------
local function clamp(value, low, high)
    if value < low then value = low
    elseif high and value > high then value = high end
    return value
end

-- A general function for dragging objects
local function handleTouch( event )
	local t = event.target
	local phase = event.phase
	
	--print( "touch event called for: " .. t.label )
	
	if phase == "began" then
		
		-- If the ball is being reset 
		if t.label == "background" and not ballInPlay then
			ball.x = event.x
			ball.y = event.y
			t = ball
			
			background:removeEventListener("touch",handleTouch )
		end
		
		-- Store initial position
		t.x0 = event.x - t.x
		
		display.getCurrentStage():setFocus( t )
		t.isFocus = true	
	elseif t.isFocus then
		if "moved" == phase then
			if t.label == "paddle" then
				paddle.x = clamp( event.x - t.x0, paddle.width / 2, screenW - paddle.width / 2 ) 
			elseif t.label == "ball" then
				ball.x = event.x
				ball.y = event.y
			end
		elseif "ended" == phase or "cancelled" == phase then
			display.getCurrentStage():setFocus( nil )
			t.isFocus = false
			
			if t.label == "ball" then
				ball.isBodyActive = true
				ballInPlay = true
				ball:setLinearVelocity( -50, 300 )
				ball:removeEventListener( "touch",handleTouch )
			end
				
		end
	end

	-- Stop further propagation of touch event!
	return true
end		

-- If the ball falls through the bottom of the screen
local function ballLost( self, event )

	if event.phase == "began" then
		-- Start listening for touching anywhere on the background (to reset the ball)
		ball:addEventListener( "touch",handleTouch )
		background:addEventListener("touch",handleTouch )

		ballInPlay = false
		
		print( "ball lost!" )
	elseif event.phase == "ended" then
		ball:setLinearVelocity( 0, 0 )
	end
	
end

-- Load a grid of blocks
local function loadBlocks( width, height )

	
	local blockWidth = ( screenW - ( blockGutter * 2 ) - ( blockGap * ( width - 1 ) ) ) / width
	local blockHeight = 20
	
	--blocks = {}
	
	for blockX = 0, width - 1 do
		for blockY = 0, height - 1 do
			local block = display.newRect( blockGutter + blockX * ( blockWidth + blockGap ), blockGutter + blockY * ( blockHeight + blockGap ), 
												  blockWidth, blockHeight, 4 )
			block:setFillColor(255, 0, 0, 255)
			physics.addBody( block, "static", { density = 1.0, friction = 0, bounce = 0} )
			block.label = "block"
			--block.index = #blocks + 1
			blocks[ #blocks + 1 ] = block
		end
	end

	
end

--local function removeBlock( block )
--		table.remove( blocks, table.indexOf( blocks, block ) )
--		block:removeSelf()
--		print( "block removed (" .. #blocks .. " blocks left)" )
--end

local function processBallCollision( self, event )

	if event.phase == "began" and event.other.label == "paddle" then
		paddle:prepare( "paddleHit" )
		paddle:play()
	elseif event.phase == "ended" and event.other.label == "block" then
		--timer.performWithDelay( 500, removeBlock( event.other ), 0 )
		table.remove( blocks, table.indexOf( blocks, event.other ) )
		event.other:removeSelf()
		print( "block removed (" .. #blocks .. " blocks left)" )
	end

end


-- Load a random set of blocks
loadBlocks( mRand( 3, 7 ), mRand( 2, 5 ) )

---------------
-- EVENT LISTENERS
---------------
borderBottom.collision = ballLost
borderBottom:addEventListener("collision", borderBottom )

ball.collision = processBallCollision
ball:addEventListener("collision", ball )

paddle:addEventListener( "touch", handleTouch )
