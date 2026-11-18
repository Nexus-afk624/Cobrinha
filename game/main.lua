local COLS, LINHAS = 20, 20
local TAM, ox, oy = 24, 0, 0
local W, H = 480, 640
local fonte
local botoes = {}
local cobra, dir, prox, comida
local pontos, vivo, timer, passo
local toque = nil

local function layout()
  W, H = love.graphics.getDimensions()
  local bs, cx, cy
  if H >= W then
    TAM = math.floor(W / COLS)
    local fh = H - TAM * LINHAS
    bs = math.floor(math.min(fh / 3.4, W / 3.6))
    ox = math.floor((W - TAM * COLS) / 2)
    cx = W / 2
    cy = TAM * LINHAS + fh * 0.62
  else
    TAM = math.floor(H / LINHAS)
    local fw = W - TAM * COLS
    bs = math.floor(math.min(fw / 3.4, H / 3.6))
    ox = 0
    cx = TAM * COLS + fw / 2
    cy = H * 0.6
  end
  oy = 0
  fonte = love.graphics.newFont(math.max(14, math.floor(TAM * 0.8)))
  local function b(px, py, dx, dy, t)
    return { x = px - bs/2 + 3, y = py - bs/2 + 3,
             w = bs - 6, h = bs - 6, dx = dx, dy = dy, t = t }
  end
  botoes = {
    b(cx, cy - bs, 0, -1, "^"),
    b(cx - bs, cy, -1, 0, "<"),
    b(cx, cy, 0, 1, "v"),
    b(cx + bs, cy, 1, 0, ">"),
  }
end

local function nova_comida()
  local livre
  repeat
    comida = { x = love.math.random(1, COLS), y = love.math.random(1, LINHAS) }
    livre = true
    for _, s in ipairs(cobra) do
      if s.x == comida.x and s.y == comida.y then livre = false end
    end
  until livre
end

local function reiniciar()
  cobra = { {x=10,y=10}, {x=9,y=10}, {x=8,y=10} }
  dir  = { x = 1, y = 0 }
  prox = { x = 1, y = 0 }
  pontos, vivo, timer, passo = 0, true, 0, 0.15
  nova_comida()
end

local function virar(x, y)
  if not (x == -dir.x and y == -dir.y) then
    prox = { x = x, y = y }
  end
end

function love.load()
  love.window.setTitle("Cobrinha")
  if love.system.getOS() ~= "Android" then
    love.window.setMode(480, 640, { resizable = true })
  end
  layout()
  reiniciar()
end

function love.resize()
  layout()
end

function love.update(dt)
  if not vivo then return end
  timer = timer + dt
  if timer < passo then return end
  timer = timer - passo

  dir = prox
  local nx, ny = cobra[1].x + dir.x, cobra[1].y + dir.y

  if nx < 1 then nx = COLS end
  if nx > COLS then nx = 1 end
  if ny < 1 then ny = LINHAS end
  if ny > LINHAS then ny = 1 end

  for _, s in ipairs(cobra) do
    if s.x == nx and s.y == ny then vivo = false return end
  end

  table.insert(cobra, 1, { x = nx, y = ny })
  if nx == comida.x and ny == comida.y then
    pontos = pontos + 1
    passo = math.max(0.06, passo - 0.004)
    nova_comida()
  else
    table.remove(cobra)
  end
end

function love.keypressed(k)
  if k == "up" or k == "w" then virar(0, -1)
  elseif k == "down" or k == "s" then virar(0, 1)
  elseif k == "left" or k == "a" then virar(-1, 0)
  elseif k == "right" or k == "d" then virar(1, 0)
  elseif k == "r" then reiniciar()
  elseif k == "escape" then love.event.quit() end
end

function love.mousepressed(mx, my)
  if not vivo then reiniciar() return end
  toque = { x = mx, y = my }
  for _, b in ipairs(botoes) do
    if mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h then
      virar(b.dx, b.dy)
      toque = nil
    end
  end
end

function love.mousemoved(mx, my)
  if not toque then return end
  local dx, dy = mx - toque.x, my - toque.y
  local limite = math.max(20, TAM * 0.8)
  if math.abs(dx) > limite or math.abs(dy) > limite then
    if math.abs(dx) > math.abs(dy) then
      virar(dx > 0 and 1 or -1, 0)
    else
      virar(0, dy > 0 and 1 or -1)
    end
    toque = { x = mx, y = my }
  end
end

function love.mousereleased()
  toque = nil
end

function love.draw()
  love.graphics.setFont(fonte)

  for x = 1, COLS do
    for y = 1, LINHAS do
      if (x + y) % 2 == 0 then
        love.graphics.setColor(0.45, 0.28, 0.15)
      else
        love.graphics.setColor(0.68, 0.48, 0.30)
      end
      love.graphics.rectangle("fill", ox + (x-1)*TAM, oy + (y-1)*TAM, TAM, TAM)
    end
  end

  local cx = ox + (comida.x-1)*TAM + TAM/2
  local cy = oy + (comida.y-1)*TAM + TAM/2
  local pulso = math.sin(love.timer.getTime() * 8) * 3
  love.graphics.setColor(1, 1, 0.3, 0.5)
  love.graphics.circle("fill", cx, cy, TAM/2 + 3 + pulso)
  love.graphics.setColor(1, 1, 1)
  love.graphics.circle("fill", cx, cy, TAM/2 - 1)
  love.graphics.setColor(0.9, 0.1, 0.1)
  love.graphics.circle("fill", cx, cy, TAM/2 - 4)

  for i, s in ipairs(cobra) do
    if i == 1 then love.graphics.setColor(0.3, 1, 0.3)
    else love.graphics.setColor(0.1, 0.6, 0.1) end
    love.graphics.rectangle("fill", ox + (s.x-1)*TAM+1, oy + (s.y-1)*TAM+1, TAM-2, TAM-2)
  end

  love.graphics.setColor(1, 1, 1)
  if H >= W then
    love.graphics.print("Pontos: " .. pontos, ox + 8, TAM * LINHAS + 8)
  else
    love.graphics.print("Pontos: " .. pontos, TAM * COLS + 12, 12)
  end

  for _, b in ipairs(botoes) do
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.rectangle("fill", b.x, b.y, b.w, b.h, 8, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(b.t, b.x, b.y + (b.h - fonte:getHeight()) / 2, b.w, "center")
  end

  if not vivo then
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", ox, oy + TAM*LINHAS/2 - TAM*2, TAM*COLS, TAM*4)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("FIM DE JOGO\nToque para jogar de novo",
      ox, oy + TAM*LINHAS/2 - fonte:getHeight(), TAM*COLS, "center")
  end
end
