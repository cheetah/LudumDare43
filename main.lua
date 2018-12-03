array = require("array")

game = {
  w     = 600,
  h     = 400,
  g     = 9.81,
  meter = 64,

  blockW     = 50,
  blockH     = 50,
  ropeLength = 100,

  blockCategory  = 2,
  groundCategory = 3,

  isFirstRun   = true,
  isZoomingOut = false,
}

objs = {
  blocks       = {},
  fallingBlock = {},
}

interferenceTimer = {
  elapsed = 0,
  expected = 0,
}

blockTimer = {
  elapsed = 0,
  expected = 5,
}

zoom = {
  translateX = 0,
  translateY = 0,
  scaleFactor = 1,
}

firstRunText = "Hi!\n\nLet's go straight to the point. We need to build the highest tower in the world, but we need to do it as fast as possible, so we must sacrifice quality for the speed. There is an indicator at the top, the more time is left on it, the more points you get for the block. Hit Space button to release block, but beware, it's a bit windy here. You can continue building until five blocks falls. Hold Z to observe the whole tower.\n\nGood luck! (Press return to continue)"
gameOverText = "Ok, that's it. I hope no one was hurt in process.\n\nYour score is %d (Press R to restart)\n\n"

palette = {
  { 0.0000, 0.0000, 0.0000, 1.0 },
  { 0.3164, 0.3594, 0.0859, 1.0 },
  { 0.5156, 0.2383, 0.3203, 1.0 },
  { 0.9141, 0.4883, 0.1523, 1.0 },
  { 0.3164, 0.2813, 0.5313, 1.0 },
  { 0.9063, 0.3633, 0.9336, 1.0 },
  { 0.9570, 0.7148, 0.7852, 1.0 },
  { 0.0000, 0.4023, 0.3203, 1.0 },
  { 0.0000, 0.7813, 0.1719, 1.0 },
  { 0.5664, 0.5664, 0.5664, 1.0 },
  { 0.7852, 0.8164, 0.5977, 1.0 },
  { 0.0000, 0.6484, 0.9375, 1.0 },
  { 0.5938, 0.8555, 0.7852, 1.0 },
  { 0.7813, 0.7539, 0.9648, 1.0 },
  { 0.9961, 0.9961, 0.9961, 1.0 },
}

-- SECTION Helper funcs

function lerp(a, b, dt)
  return a + (b - a) * dt
end

function resetGame()
  state = {
    score   = 0,
    lives   = 5,
    screenY = 0,
  }

  for _, block in pairs(array.filter(objs.blocks, function(el) return not el.body:isDestroyed() end)) do
    block.body:destroy()
  end

  objs.blocks       = {}
  objs.fallingBlock = {}

  resetBlockTimer()
end

function destroyBlock(block)
  block.body:destroy()
  state.lives = state.lives - 1
end

function resetBlockTimer()
  blockTimer = {
    elapsed = 0,
    expected = 5,
  }
end

-- SECTION Create funcs

function createGround()
  objs.ground         = {}
  objs.ground.h       = 20
  objs.ground.body    = love.physics.newBody(world, 0, game.h - objs.ground.h / 2, "static")
  objs.ground.shape   = love.physics.newRectangleShape(game.w * 16, objs.ground.h)
  objs.ground.fixture = love.physics.newFixture(objs.ground.body, objs.ground.shape)

  objs.ground.fixture:setCategory(game.groundCategory)
end

function createFoundation()
  objs.foundation         = {}
  objs.foundation.body    = love.physics.newBody(world, game.w / 2, game.h - game.blockH + 5, "static")
  objs.foundation.shape   = love.physics.newRectangleShape(game.blockW, game.blockH)
  objs.foundation.fixture = love.physics.newFixture(objs.foundation.body, objs.foundation.shape)

  objs.foundation.fixture:setCategory(game.blockCategory)
end

function createHook()
  objs.hook         = {}
  objs.hook.w       = 10
  objs.hook.h       = 10
  objs.hook.body    = love.physics.newBody(world, game.w / 2, objs.hook.h / 2, "static")
  objs.hook.shape   = love.physics.newRectangleShape(objs.hook.w, objs.hook.h)
  objs.hook.fixture = love.physics.newFixture(objs.hook.body, objs.hook.shape)
end

function createBlock()
  objs.block         = {}
  objs.block.body    = love.physics.newBody(world, game.w / 2, game.ropeLength - state.screenY, "dynamic")
  objs.block.shape   = love.physics.newRectangleShape(game.blockW, game.blockH)
  objs.block.fixture = love.physics.newFixture(objs.block.body, objs.block.shape)
  objs.block.color   = love.math.random(2, 9)

  objs.block.rope       = {}
  objs.block.rope.joint = love.physics.newRopeJoint(
    objs.hook.body,
    objs.block.body,
    objs.hook.body:getX(),
    objs.hook.body:getY(),
    objs.block.body:getX(),
    objs.block.body:getY(),
    game.ropeLength,
    false
  )

  objs.block.body:setLinearDamping(0.5)

  objs.block.fixture:setCategory(game.blockCategory)
  objs.block.fixture:setFriction(0.5)

  interfereBlock(0, true)
  resetBlockTimer()
end

-- SECTION Update function

function updateScreenY(dt)
  local minY = objs.foundation.body:getY()
  if not array.isEmpty(objs.blocks) then
    minY = array.minBy(objs.blocks, function(el)
      if not el.body:isDestroyed() then
        return el.body:getY()
      else
        return math.huge
      end
    end)
  end

  local offsetY = game.h - minY - game.blockH * 2
  if offsetY < 0 then
    offsetY = 0
  end

  state.screenY = lerp(state.screenY, offsetY, dt)
end

function updateHookPosition()
  objs.hook.body:setY(-state.screenY)
end

function checkGameOver()
  if state.lives <= 0 then
    return true
  end

  return false
end

function checkBlocks()
  local blocksToDestroy = {}

  for i, block in ipairs(array.filter(objs.blocks, function(el) return not el.body:isDestroyed() end)) do
    for _, contact in pairs(block.body:getContactList()) do
      a, b = contact:getFixtures()
      if a:getCategory() == game.groundCategory or b:getCategory() == game.groundCategory then
        table.insert(blocksToDestroy, block)
        table.remove(objs.blocks, i)
      end
    end
  end

  for _, block in pairs(blocksToDestroy) do
    destroyBlock(block)
  end
end

function checkFallingBlock()
  if next(objs.fallingBlock) == nil then
    return nil
  end

  for _, contact in pairs(objs.fallingBlock.body:getContactList()) do
    a, b = contact:getFixtures()
    if a:getCategory() == game.groundCategory or b:getCategory() == game.groundCategory then
      destroyBlock(objs.fallingBlock)
      objs.fallingBlock = {}
      createBlock()

      return nil
    end

    if a:getCategory() == game.blockCategory and
       b:getCategory() == game.blockCategory and
       objs.block.rope.joint:isDestroyed() then
        table.insert(objs.blocks, objs.fallingBlock)
        objs.fallingBlock = {}

        state.score = state.score + 10.0 * (blockTimer.expected - blockTimer.elapsed + 1.0)
        createBlock()
    end
  end
end

function interfereBlock(dt, instant)
  interferenceTimer.elapsed = interferenceTimer.elapsed + dt
  if interferenceTimer.elapsed > interferenceTimer.expected or instant then
    interferenceTimer.elapsed = 0
    interferenceTimer.expected = love.math.random(1, 5)

    objs.block.body:applyLinearImpulse(
      love.math.random(-100, 100),
      love.math.random(-150, 0)
    )
  end
end

function updateBlockTimer(dt)
  if blockTimer.elapsed >= blockTimer.expected then
    blockTimer.elapsed = blockTimer.expected
    return nil
  end

  blockTimer.elapsed = blockTimer.elapsed + dt
end

function updateZoom(dt)
  if not game.isZoomingOut or #objs.blocks < 4 then
    return nil
  end

  local scaleFactor = game.h / (#objs.blocks * game.h / 3)
  zoom.scaleFactor = lerp(zoom.scaleFactor, scaleFactor, dt)

  local translateX = 1 / scaleFactor * game.w / 2 - game.w / 2
  local translateY = 1 / scaleFactor * game.h / 2 - game.h / 2
  zoom.translateX = lerp(zoom.translateX, translateX, dt)
  zoom.translateY = lerp(zoom.translateY, translateY, dt)
end

-- SECTION Draw funcs

function drawGround()
  love.graphics.setColor(palette[3])
  love.graphics.polygon("fill", objs.ground.body:getWorldPoints(objs.ground.shape:getPoints()))
end

function drawFoundation()
  love.graphics.setColor(palette[11])
  love.graphics.polygon("fill", objs.foundation.body:getWorldPoints(objs.foundation.shape:getPoints()))
end

function drawBlocks()
  if not objs.block.rope.joint:isDestroyed() then
    love.graphics.setColor(palette[3])
    love.graphics.line(objs.block.rope.joint:getAnchors())
  end

  love.graphics.setColor(palette[objs.block.color])
  love.graphics.polygon("fill", objs.block.body:getWorldPoints(objs.block.shape:getPoints()))
  for i, block in ipairs(objs.blocks) do
    if not block.body:isDestroyed() then
      love.graphics.setColor(palette[block.color])
      love.graphics.polygon("fill", block.body:getWorldPoints(objs.block.shape:getPoints()))
    end
  end
end

function drawUI()
  love.graphics.push()
  love.graphics.translate(0, -state.screenY)

  local offset = 20
  love.graphics.setColor(palette[1])
  love.graphics.print(string.format("Score: %d", state.score), offset, offset)

  local offsetX = 30
  local offsetY = 50
  love.graphics.setColor(palette[13])
  for i = 1, state.lives do
    love.graphics.rectangle("fill", offsetX, offsetY + i * 20, 10, 10)
  end

  local offsetX = 120
  local offsetY = 20
  local fullW   = game.w - offsetX * 2
  love.graphics.rectangle("fill", offsetX, offsetY, fullW - fullW * blockTimer.elapsed / blockTimer.expected, 20)

  love.graphics.pop()
end

function drawGameOver()
  if not checkGameOver() then
    return nil
  end

  local offset = 100
  love.graphics.push()
  love.graphics.translate(offset, offset - state.screenY)

  love.graphics.setColor(palette[13])
  love.graphics.rectangle("fill", 0, 0, game.w - offset * 2, game.h - offset * 2)
  love.graphics.setColor(palette[1])
  love.graphics.rectangle("line", 0, 0, game.w - offset * 2, game.h - offset * 2)
  love.graphics.printf(string.format(gameOverText, state.score), 10, 10, game.w - offset * 2 - 10, "left")

  love.graphics.pop()
end

function drawFirstRunScreen()
  if not game.isFirstRun then
    return nil
  end

  local offset = 100
  love.graphics.push()
  love.graphics.translate(offset, offset - state.screenY)

  love.graphics.setColor(palette[13])
  love.graphics.rectangle("fill", 0, 0, game.w - offset * 2, game.h - offset * 2)
  love.graphics.setColor(palette[1])
  love.graphics.rectangle("line", 0, 0, game.w - offset * 2, game.h - offset * 2)
  love.graphics.printf(firstRunText, 10, 10, game.w - offset * 2 - 10, "left")

  love.graphics.pop()
end

-- SECTION Love2d funcs

function love.load()
  resetGame()

  love.physics.setMeter(game.meter)
  love.graphics.setBackgroundColor(palette[12])
  -- love.window.setMode(game.w, game.h)

  world = love.physics.newWorld(0, game.g * game.meter, true)

  createGround()
  createFoundation()
  createHook()
  createBlock()
end

function love.update(dt)
  world:update(dt)
  updateScreenY(dt)
  updateZoom(dt)

  if game.isFirstRun then
    if love.keyboard.isDown("return") then
      game.isFirstRun = false
    end

    return nil
  end

  game.isZoomingOut = false
  if love.keyboard.isDown("z") and #objs.blocks >= 3 then
    game.isZoomingOut = true
  end

  updateHookPosition()
  checkBlocks()
  checkFallingBlock()

  if checkGameOver() then
    if love.keyboard.isDown("r") then
      resetGame()
    end

    return nil
  end

  updateBlockTimer(dt)

  if not objs.block.rope.joint:isDestroyed() then
    interfereBlock(dt, false)
    if love.keyboard.isDown("space") then
      objs.fallingBlock = objs.block
      objs.block.rope.joint:destroy()
    end
  end
end

function love.draw()
  if not game.isZoomingOut then
    love.graphics.translate(0, state.screenY)
  else
    love.graphics.scale(zoom.scaleFactor, zoom.scaleFactor)
    love.graphics.translate(zoom.translateX, zoom.translateY)
  end

  drawGround()
  drawFoundation()
  drawBlocks()

  if not game.isZoomingOut then
    drawUI()
    drawGameOver()
    drawFirstRunScreen()
  end
end
