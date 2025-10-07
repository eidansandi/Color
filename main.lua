-- main.lua
local utf8 = require("utf8")

-------------------------------------------------
-- VARIABLES GLOBALES
-------------------------------------------------
local screenW, screenH
local currentScene
local font
local bookSprite, ground, logoSprite
local buttons
local riddles
local bgHue
local books, selectedBook, input, player

-- Ganar
local winTimer = 0
local showWin = false

-- Sonidos
local menuMusic, gameMusic, winSound, creditsMusic

-------------------------------------------------
-- LOAD
-------------------------------------------------
function love.load()
    -- Ventana
    love.window.setTitle("Color")
    love.window.setFullscreen(true, "desktop")

    -- Tamaño pantalla
    screenW, screenH = love.graphics.getDimensions()

    -- Fuente
    font = love.graphics.newFont("font.otf", 40)
    love.graphics.setFont(font)

    -- Sprites
    bookSprite = love.graphics.newImage("book.png")
    ground = love.graphics.newImage("ground.png")
    logoSprite = love.graphics.newImage("logo.png") -- logo del juego

    -- Botones menú
    buttons = {
        {text = "Jugar", action = function() startGame() end},
        {text = "Salir", action = function() love.event.quit() end}
    }

    -- Acertijos
    riddles = {
        {question = "Soy rojo, pero no ardo. ¿Qué soy?", answer = "color"},
        {question = "Me puedes ver, pero no tocar. ¿Qué soy?", answer = "sombra"},
        {question = "Tengo hojas pero no soy árbol. ¿Qué soy?", answer = "libro"},
        {question = "Cambio de forma pero no de esencia. ¿Qué soy?", answer = "agua"},
        {question = "No tengo boca y grito, no tengo alas y vuelo. ¿Qué soy?", answer = "viento"},
        {question = "Brillo sin ser estrella. ¿Qué soy?", answer = "luz"},
    }

    -- Fondo rainbow
    bgHue = 0

    -- Cargar audios
    menuMusic = love.audio.newSource("menu.mp3", "stream")
    gameMusic = love.audio.newSource("game.mp3", "stream")
    winSound  = love.audio.newSource("win.mp3", "static")
    creditsMusic = love.audio.newSource("credits.mp3", "stream")

    -- Empezar en menú
    enterMenu()
end

-------------------------------------------------
-- FUNCIONES DE ESCENAS Y SONIDO
-------------------------------------------------
function enterMenu()
    currentScene = "menu"
    stopAllAudio()
    menuMusic:setLooping(true)
    menuMusic:play()
end

function startGame()
    currentScene = "game"
    stopAllAudio()
    gameMusic:setLooping(true)
    gameMusic:play()

    books = {}
    selectedBook = nil
    input = ""
    showWin = false
    winTimer = 0

    local scale = 0.35

    -- Clonar y barajar acertijos
    local riddlesCopy = {}
    for i, r in ipairs(riddles) do table.insert(riddlesCopy, r) end
    for i = #riddlesCopy, 2, -1 do
        local j = love.math.random(i)
        riddlesCopy[i], riddlesCopy[j] = riddlesCopy[j], riddlesCopy[i]
    end

    -- Colocar libros aleatoriamente
    for i = 1, #riddlesCopy do
        local bx = love.math.random(100, screenW - 150)
        local by = love.math.random(100, screenH - 200)
        table.insert(books, {x = bx, y = by, riddle = riddlesCopy[i], solved = false, scale = scale})
    end

    -- Jugador
    player = {x = screenW/2, y = screenH/2, w = 40, h = 40, speed = 500}
end

function startWin()
    showWin = true
    winTimer = 0
    stopAllAudio()
    winSound:play()
end

function enterCredits()
    currentScene = "credits"
    stopAllAudio()
    creditsMusic:setLooping(true)
    creditsMusic:play()
end

function stopAllAudio()
    if menuMusic:isPlaying() then menuMusic:stop() end
    if gameMusic:isPlaying() then gameMusic:stop() end
    if winSound:isPlaying() then winSound:stop() end
    if creditsMusic:isPlaying() then creditsMusic:stop() end
end

-------------------------------------------------
-- UPDATE
-------------------------------------------------
function love.update(dt)
    if currentScene == "menu" then
        bgHue = (bgHue + dt*20) % 360

    elseif currentScene == "game" then
        if not selectedBook and not showWin then
            updatePlayer(dt)
            checkBookProximity()
        end

        -- Revisar si se resolvieron todos los libros
        if #books == 0 and not showWin then
            startWin()
        end

        -- Contar tiempo en pantalla ganar
        if showWin then
            winTimer = winTimer + dt
            if winTimer >= 3 then
                enterCredits() -- se asegura de que los créditos aparezcan
            end
        end
    end
end

-- Movimiento del jugador
function updatePlayer(dt)
    if love.keyboard.isDown("w") then player.y = player.y - player.speed*dt end
    if love.keyboard.isDown("s") then player.y = player.y + player.speed*dt end
    if love.keyboard.isDown("a") then player.x = player.x - player.speed*dt end
    if love.keyboard.isDown("d") then player.x = player.x + player.speed*dt end
end

-- Detectar proximidad libros
function checkBookProximity()
    selectedBook = nil
    for _, b in ipairs(books) do
        local dx = (player.x + player.w/2) - (b.x + 20)
        local dy = (player.y + player.h/2) - (b.y + 20)
        if math.sqrt(dx*dx + dy*dy) < 50 then
            selectedBook = b
            break
        end
    end
end

-------------------------------------------------
-- DRAW
-------------------------------------------------
local function hsvToRgb(h,s,v)
    local c = v*s
    local x = c*(1-math.abs((h/60)%2-1))
    local m = v-c
    local r,g,b=0,0,0
    if h<60 then r,g,b=c,x,0
    elseif h<120 then r,g,b=x,c,0
    elseif h<180 then r,g,b=0,c,x
    elseif h<240 then r,g,b=0,x,c
    elseif h<300 then r,g,b=x,0,c
    else r,g,b=c,0,x end
    return r+m,g+m,b+m
end

function love.draw()
    if currentScene=="menu" then
        drawMenu()
    elseif currentScene=="game" then
        if showWin then
            drawWinScreen()
        else
            drawGame()
        end
    elseif currentScene=="credits" then
        drawCredits()
    end
end

-------------------------------------------------
-- DRAW MENU CON LOGO Y VERSION
-------------------------------------------------
function drawMenu()
    local r,g,b = hsvToRgb(bgHue,0.6,1)
    love.graphics.clear(r,g,b)

    -- Logo abajo a la izquierda
    local logoScale = 0.5
    love.graphics.setColor(1,1,1)
    love.graphics.draw(logoSprite, 20, screenH - logoSprite:getHeight()*logoScale - 20, 0, logoScale, logoScale)

    -- Título
    love.graphics.setColor(0,0,0)
    love.graphics.printf("Color", 3, screenH*0.3, screenW, "center")

    -- Botones
    local buttonW, buttonH = 300, 70
    for i, b in ipairs(buttons) do
        local bx = (screenW - buttonW)/2
        local by = screenH*0.4 + (i-1)*(buttonH+20)
        love.graphics.setColor(1,1,1,0.85)
        love.graphics.rectangle("fill", bx, by, buttonW, buttonH, 15,15)
        love.graphics.setColor(0,0,0)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", bx, by, buttonW, buttonH, 15,15)
        love.graphics.printf(b.text, bx, by+18, buttonW, "center")
        b.x, b.y, b.w, b.h = bx, by, buttonW, buttonH
    end

    -- Texto versión abajo a la derecha
    love.graphics.setColor(0,0,0,0.6)
    love.graphics.printf("Versión 1.0", 0, screenH - 30, screenW - 20, "right")
end

-------------------------------------------------
-- DRAW GAME
-------------------------------------------------
function drawGame()
    love.graphics.setColor(1,1,1)
    love.graphics.draw(ground,0,0,0,screenW/ground:getWidth(),screenH/ground:getHeight())

    for _,b in ipairs(books) do
        love.graphics.setColor(1,1,1)
        love.graphics.draw(bookSprite,b.x,b.y,0,b.scale,b.scale)
    end

    love.graphics.setColor(0.2,0.6,1)
    love.graphics.rectangle("fill", player.x, player.y, player.w, player.h)

    if selectedBook then
        love.graphics.setColor(1,1,1)
        love.graphics.printf(selectedBook.riddle.question,0,400,screenW,"center")
        love.graphics.printf("Respuesta: "..input,0,450,screenW,"center")
    end
end

function drawWinScreen()
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle("fill",0,0,screenW,screenH)
    love.graphics.setColor(1,1,1)
    love.graphics.printf("¡GANASTE!", 0, screenH/2-40, screenW, "center")
end

function drawCredits()
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle("fill",0,0,screenW,screenH)
    love.graphics.setColor(1,1,1)
    love.graphics.printf("Créditos\n\nProgramador: Eidan Sandi \nArte: Daniel Cortez & Luciana Plata \n Música: Kendrick Lamar, Toby Fox y Tyler, The Creator \n\nGracias por ver este proyecto, habran futuras actualizaciones, visita el codigo fuente en GitHub:)!",0,screenH/4,screenW,"center")
end

-------------------------------------------------
-- INPUT
-------------------------------------------------
function love.mousepressed(x,y,button)
    if currentScene=="menu" then
        for _,b in ipairs(buttons) do
            if x>b.x and x<b.x+b.w and y>b.y and y<b.y+b.h then
                b.action()
            end
        end
    end
end

function love.textinput(t)
    if selectedBook then input=input..t end
end

function love.keypressed(key)
    if key=="backspace" then
        input = input:sub(1,-2)

    elseif key=="return" and selectedBook then
        if string.lower(input)==string.lower(selectedBook.riddle.answer) then
            for i,b in ipairs(books) do
                if b==selectedBook then
                    table.remove(books,i)
                    break
                end
            end
        end
        selectedBook=nil
        input=""

    elseif key=="escape" then
        if selectedBook then
            selectedBook=nil
            input=""
        elseif currentScene=="game" then
            enterMenu()
        end
    end
end
