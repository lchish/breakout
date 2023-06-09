local screenWidth = 212
local screenHeight = 64

local score = 0
local lives = 5
local bricks = {}
local brickWidth = 6
local brickHeight = 8
local brickGapWidth = 2
local brickGapHeight = 2
local visibleBricks = 0

local paddle = {}
paddle.width = 24
paddle.height = 4
paddle.x = screenWidth / 2 - paddle.width / 2
paddle.y = screenHeight - paddle.height
paddle.dx = 1

local ball = {}
ball.width = 4
ball.height = 4
ball.x = screenWidth / 2 - paddle.width
ball.y = screenHeight / 2
ball.dx = 0.5
ball.dy = 0.5

local oldTime

Brick = {
   x,
   y,
   width,
   height,
   visible
}

function Brick:create (o)
   o.parent = self
   return o
end

local function createRects()
   local i = 1
   for y = brickGapHeight + 8, screenHeight / 3, brickHeight + brickGapHeight do
      for x = brickGapWidth, screenWidth - brickWidth, brickWidth + brickGapWidth do
         bricks[i] = Brick:create{
	    x = x,
	    y = y,
	    width = brickWidth,
	    height = brickHeight,
	    visible = true
	 }
         i = i + 1
	 visibleBricks = visibleBricks + 1
      end
   end
end

local function reset()
   if lives < 0 then
      score = 0
      lives = 5
   end
   ball.x = screenWidth / 2 - paddle.width
   ball.y = screenHeight / 2
   ball.dx = 0.5
   paddle.x = screenWidth / 2 - paddle.width / 2
   paddle.y = screenHeight - paddle.height

   for i, brick in pairs(bricks) do
      brick.visible = true
      visibleBricks = visibleBricks + 1
   end
end

local function drawAll()
   for i, brick in pairs(bricks) do
      if brick.visible == true then
         lcd.drawRectangle(brick.x, brick.y, brickWidth, brickHeight)
      end
   end
   lcd.drawFilledRectangle(paddle.x, paddle.y, paddle.width, paddle.height, 0)
   lcd.drawFilledRectangle(ball.x, ball.y, ball.width, ball.height, 0)
   lcd.drawText(50, 0, "Score " .. score, 0)
   lcd.drawText(0, 0, "Lives " .. lives, 0)
end

local function collisionDetection(rect1, rect2)
   return rect1.x < rect2.x + rect2.width and
      rect1.x + rect1.width > rect2.x and
      rect1.y < rect2.y + rect2.height and
      rect1.y + rect1.height > rect2.y
end

local function update(deltaTime)
   -- check for collision with paddle
   if collisionDetection(ball, paddle) then
      if ball.y > paddle.y - paddle.height then
         ball.y = paddle.y - ball.height
      end
      ball.dy = -ball.dy
   else
      local dy_changed = false
      local dx_changed = false
      -- check for collision with bricks
      for i, brick in pairs(bricks) do
	 if brick["visible"] == true then
	    if collisionDetection(ball, brick) then
	       if not dy_changed then
		  if ball.y < brick.y + brickHeight then -- Hit was below the brick
		     ball.dy = -ball.dy
		     dy_changed = true
		  elseif ball.y + ball.height > brick.y then -- Hit was above the brick
		     ball.dy = -ball.dy
		     dy_changed = true
		  end
	       end

	       if not dx_changed then
		  if ball.x < brick.x + brickWidth then -- Brick hit on right
		     ball.dx = -ball.dx
		     dx_changed = true
		  elseif ball.x + ball.width > brick.x then -- Brick hit on left
		     ball.dx = -ball.dx
		     dx_changed = true
		  end
	       end

	       brick.visible = false
	       visibleBricks = visibleBricks - 1
	       score = score + 1
	       if visibleBricks == 0 then
		  reset()
	       end
	    end
	 end
      end
   end

   ball.x = ball.x + ball.dx * deltaTime
   ball.y = ball.y + ball.dy * deltaTime

   if getValue('rud') > 10 then
      paddle.x = paddle.x + paddle.dx * deltaTime
   end
   if getValue('rud') < -10 then
      paddle.x = paddle.x - paddle.dx * deltaTime
   end

   if ball.x + ball.width > screenWidth then
      ball.x = screenWidth - ball.width
      ball.dx = -ball.dx
   end
   if ball.x < 0 then
      ball.x = 0
      ball.dx = -ball.dx
   end
   if ball.y < 0 then
      ball.y = 0
      ball.dy = -ball.dy
   end
   if ball.y + ball.height > screenHeight then -- Lose a point!
      if math.random(2) == 1 then
	 ball.x = screenWidth / 2 - paddle.width
	 ball.dx = 0.5
      else
	 ball.x = screenWidth / 2 + paddle.width
	 ball.dx = -0.5
      end
      ball.y = screenHeight / 2
      lives = lives - 1

      if lives < 0 then
	 reset()
      end
   end

   -- Stop the paddle going off the end of the screen
   if paddle.x + paddle.width > screenWidth then
      paddle.x = screenWidth - paddle.width
   elseif paddle.x < 0 then
      paddle.x = 0
   end
end

local function init()
   lcd.refresh()
   lcd.clear()
   createRects()
   drawAll()
   oldTime = getTime()
end

local function run(event)
   if event == nil then
      raise("Cannot be run as a model script!")
   end

   if event == EVT_EXIT_BREAK then
      return 2
   end

   lcd.refresh()

   local newTime = getTime()
   local deltaTime = newTime - oldTime

   update(deltaTime)
   lcd.clear()
   drawAll()
   oldTime = newTime

   return 0
end

return {init=init, run=run}
