--[[
    LopopUI  v2.0   -   UI Library premium para Roblox (tema pirulito)
    Suba ESTE arquivo no GitHub (nome: LopopUI.lua) e carregue com loadstring + link RAW.

    ===================== TEMPLATE / API =====================
    local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPO/main/LopopUI.lua"))()

    local Window = Library:CreateWindow({Title = "Meu Hub"})
    local Tabs = Window:AddTabs({"Main", "Settings", "Config"})   -- cria varias abas: Tabs.Main, Tabs.Config ...
    -- (ou uma por vez: local Main = Window:AddTab("Main")   | aliases: Window:Tab / :CreateTab / :MakeTab)

    Tabs.Main:AddSection("Farm")
    Tabs.Main:AddToggle({Name = "Auto Farm", Flag = "AutoFarm", Default = false, Desc = "opcional", Callback = function(v) end})
    Tabs.Main:AddSlider({Name = "Speed", Flag = "Speed", Min = 16, Max = 100, Step = 1, Default = 16, Suffix = "", Callback = function(v) end})
    Tabs.Main:AddButton({Name = "Botao", Primary = false, Callback = function() end})
    Tabs.Main:AddButtonRow({ {Name = "A", Callback = f}, {Name = "B", Primary = true, Callback = f} })
    Tabs.Main:AddInput({Name = "JobID", Flag = "JobID", Placeholder = "...", Width = 170, Callback = function(text, enter, loaded) end})
    Tabs.Main:AddDropdown({Name = "Modo", Flag = "Modo", Options = {"A", "B"}, Default = "A", Callback = function(v) end})  -- :Set :Get :SetOptions
    Tabs.Main:AddLabel("texto")   Tabs.Main:AddInfoCard("Titulo", "sub")   Tabs.Settings:AddThemePicker()
    -- Todo metodo tem alias curto: Tab:Toggle(...) = Tab:AddToggle(...), Tab:Button(...), Tab:Slider(...), etc.

    Library:Notify({Title = "Oi", Content = "texto", Type = "Success", Duration = 4})   -- Success | Error | Info | Warning
    Library:SetTheme("Pure White")
    Library:AddTheme("Meu Tema", {Main=..., Panel=..., Accent=..., Accent2=..., Text=..., SubText=..., Particle=..., Off=..., Pill=..., PillText=...})  -- antes do AddThemePicker
    Window:SetVisible(true/false)    Window:SetMinimized(true/false)    Window:SetPattern(true/false)    Window:SetBackground("ID")    Window:SetBackgroundOpacity(0.7)
    Library.Flags["AutoFarm"]        -- le o valor de qualquer elemento pelo Flag
    Library:SaveConfig("nome")  :LoadConfig("nome")  :CreateConfig("nome")  :DeleteConfig("nome")  :ListConfigs()
    table.insert(Library.OnDestroy, function() end)   -- roda quando a UI fechar (botao X)
    Library:Start()                  -- chame POR ULTIMO (restaura o autosave e liga o salvamento em tempo real)
    Library:Destroy()                -- fecha tudo
    ==========================================================
]]


local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local ContentProvider = game:GetService("ContentProvider")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

if _G.LopopUI and type(_G.LopopUI.Destroy) == "function" then
    pcall(function() _G.LopopUI:Destroy() end)
end

--------------------------------------------------------------------------------
-- BASE
--------------------------------------------------------------------------------
local Library = {
    Flags = {}, Setters = {}, NoSave = {}, Registry = {}, Hooks = {}, Connections = {},
    ToggleKey = Enum.KeyCode.RightControl, Notifications = true, ParticlesEnabled = true, ParticleSpeed = 1,
    AutoSaveEnabled = true, Loading = false, Ready = false, Dirty = false, Alive = true, OnDestroy = {},
}

local function C(r, g, b) return Color3.fromRGB(r, g, b) end
local function FinishTheme(t)
    t.Card = t.Panel:Lerp(t.Accent, 0.16)
    t.CardHover = t.Card:Lerp(t.Accent, 0.2)
    t.Active = t.Card:Lerp(t.Accent, 0.42)
    t.Pat1 = t.Accent2:Lerp(Color3.new(1, 1, 1), 0.25)
    t.Pat2 = t.Accent2:Lerp(t.Panel, 0.3)
    return t
end
local Themes = {
    ["Strawberry"]     = {Main = C(255,96,140),  Panel = C(96,30,72),   Accent = C(255,64,140),  Accent2 = C(255,170,225), Text = C(255,255,255), SubText = C(255,215,235), Particle = C(255,230,245), Off = C(140,60,100),  Pill = C(255,140,225), PillText = C(50,8,40)},
    ["Bubblegum"]      = {Main = C(255,140,200), Panel = C(130,50,110), Accent = C(255,90,190),  Accent2 = C(255,200,240), Text = C(255,255,255), SubText = C(255,225,245), Particle = C(255,240,250), Off = C(150,80,130),  Pill = C(255,175,235), PillText = C(60,10,60)},
    ["Cotton White"]   = {Main = C(250,240,250), Panel = C(255,255,255),Accent = C(240,80,150),  Accent2 = C(255,170,210), Text = C(70,20,50),    SubText = C(140,90,115),  Particle = C(255,170,210), Off = C(225,205,218), Pill = C(255,205,235), PillText = C(70,20,50)},
    ["Lemon Drop"]     = {Main = C(255,205,80),  Panel = C(120,80,20),  Accent = C(255,170,0),   Accent2 = C(255,230,140), Text = C(255,255,255), SubText = C(255,240,200), Particle = C(255,245,190), Off = C(150,110,40),  Pill = C(255,225,120), PillText = C(70,40,0)},
    ["Cherry Red"]     = {Main = C(225,40,70),   Panel = C(90,12,28),   Accent = C(255,60,90),   Accent2 = C(255,140,160), Text = C(255,255,255), SubText = C(255,200,210), Particle = C(255,170,185), Off = C(120,35,52),   Pill = C(255,110,135), PillText = C(50,0,12)},
    ["Grape Pop"]      = {Main = C(150,90,230),  Panel = C(60,28,110),  Accent = C(190,110,255), Accent2 = C(225,190,255), Text = C(255,255,255), SubText = C(232,215,255), Particle = C(225,200,255), Off = C(92,60,150),   Pill = C(200,150,255), PillText = C(35,10,70)},
    ["Mint Candy"]     = {Main = C(80,215,185),  Panel = C(16,84,76),   Accent = C(40,200,160),  Accent2 = C(170,245,225), Text = C(255,255,255), SubText = C(210,250,240), Particle = C(200,255,240), Off = C(36,110,100),  Pill = C(140,235,210), PillText = C(5,50,44)},
    ["Midnight Neon"]  = {Main = C(34,20,74),    Panel = C(14,8,34),    Accent = C(255,70,170),  Accent2 = C(120,200,255), Text = C(255,255,255), SubText = C(200,190,235), Particle = C(150,210,255), Off = C(48,34,96),   Pill = C(70,44,140),   PillText = C(255,255,255)},
}
local ThemeOrder = {"Strawberry", "Bubblegum", "Cotton White", "Lemon Drop", "Cherry Red", "Grape Pop", "Mint Candy", "Midnight Neon"}
for _, t in pairs(Themes) do FinishTheme(t) end
Library.Theme = Themes["Strawberry"]
Library.ThemeName = "Strawberry"
Library.Flags["__theme"] = "Strawberry"

local WHITE = Color3.new(1, 1, 1)
local FONT_B, FONT_M, FONT_R = Enum.Font.GothamBold, Enum.Font.GothamMedium, Enum.Font.Gotham

local function Tween(obj, time, props, style, dir)
    local tw = TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

local function Create(class, props, children)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    for _, c in ipairs(children or {}) do c.Parent = o end
    return o
end

local function Corner(r) return Create("UICorner", {CornerRadius = UDim.new(0, r)}) end
local function Round() return Create("UICorner", {CornerRadius = UDim.new(1, 0)}) end
local function Pad(l, r, t, b)
    return Create("UIPadding", {PaddingLeft = UDim.new(0, l), PaddingRight = UDim.new(0, r), PaddingTop = UDim.new(0, t), PaddingBottom = UDim.new(0, b)})
end

local function Reg(obj, prop, key)
    obj[prop] = Library.Theme[key]
    table.insert(Library.Registry, {obj, prop, key})
end

local function Connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(Library.Connections, c)
    return c
end

function Library:SetTheme(name)
    local t = Themes[name]
    if not t then return end
    self.Theme, self.ThemeName = t, name
    self.Flags["__theme"] = name
    for i = #self.Registry, 1, -1 do
        local r = self.Registry[i]
        if r[1].Parent == nil then
            table.remove(self.Registry, i)
        else
            Tween(r[1], 0.35, {[r[2]] = t[r[3]]})
        end
    end
    for _, h in ipairs(self.Hooks) do pcall(h, t) end
    self:_changed("__theme")
end
Library.Setters["__theme"] = function(n) Library:SetTheme(n) end

local gui = Create("ScreenGui", {Name = "LopopUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true})
do
    local ok = pcall(function() gui.Parent = (type(gethui) == "function" and gethui()) or CoreGui end)
    if not ok or not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
end

local function Safe(cb, ...)
    if type(cb) ~= "function" then return end
    local ok, err = pcall(cb, ...)
    if not ok then
        warn("[LopopUI] " .. tostring(err))
        Library:Notify({Title = "Erro no callback", Content = tostring(err):sub(1, 90), Type = "Error"})
    end
end

--------------------------------------------------------------------------------
-- NOTIFICAÇÕES
--------------------------------------------------------------------------------
local NotifyHolder = Create("Frame", {
    AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.new(0, 300, 1, -32), BackgroundTransparency = 1, Parent = gui,
}, {Create("UIListLayout", {Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Bottom, SortOrder = Enum.SortOrder.LayoutOrder})})

local TypeInfo = {
    Success = {C(90, 220, 140), "SUCCESS"}, Error = {C(255, 85, 100), "ERROR"},
    Info = {C(100, 175, 255), "INFO"}, Warning = {C(255, 200, 70), "WARNING"},
}

function Library:Notify(opt)
    opt = type(opt) == "table" and opt or {Content = tostring(opt)}
    if (not self.Notifications or self.Loading) and not opt.Force then return end
    local info = TypeInfo[opt.Type or "Info"] or TypeInfo.Info
    local title, content = tostring(opt.Title or "LopopUI"), tostring(opt.Content or "")
    local duration = tonumber(opt.Duration) or 4
    local W, textH = 280, 14
    pcall(function() textH = TextService:GetTextSize(content, 12, FONT_R, Vector2.new(W - 34, 1000)).Y end)
    local H = math.max(64, 46 + textH + 12)

    local wrap = Create("Frame", {Size = UDim2.new(0, W, 0, H), BackgroundTransparency = 1, Parent = NotifyHolder})
    local card = Create("Frame", {Size = UDim2.fromScale(1, 1), Position = UDim2.new(1, 60, 0, 0), BorderSizePixel = 0, BackgroundTransparency = 0.03,
        ClipsDescendants = true, Active = true, Parent = wrap}, {Corner(8)})
    Reg(card, "BackgroundColor3", "Panel")
    local st = Create("UIStroke", {Thickness = 1, Transparency = 0.55, Parent = card})
    Reg(st, "Color", "Accent2")
    Create("Frame", {Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = info[1], BorderSizePixel = 0, Parent = card})
    Create("TextLabel", {Position = UDim2.fromOffset(16, 8), Size = UDim2.new(1, -28, 0, 12), BackgroundTransparency = 1, Text = info[2], Font = FONT_B, TextSize = 10,
        TextColor3 = info[1], TextXAlignment = Enum.TextXAlignment.Left, Parent = card})
    local tl = Create("TextLabel", {Position = UDim2.fromOffset(16, 21), Size = UDim2.new(1, -28, 0, 18), BackgroundTransparency = 1, Text = title, Font = FONT_B,
        TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card})
    Reg(tl, "TextColor3", "Text")
    local cl = Create("TextLabel", {Position = UDim2.fromOffset(16, 41), Size = UDim2.new(1, -28, 1, -50), BackgroundTransparency = 1, Text = content, Font = FONT_R,
        TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Parent = card})
    Reg(cl, "TextColor3", "SubText")
    local bar = Create("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = info[1], BorderSizePixel = 0, Parent = card})

    local closed = false
    local function close()
        if closed then return end
        closed = true
        Tween(card, 0.35, {Position = UDim2.new(1, 60, 0, 0)}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.delay(0.3, function()
            if wrap.Parent then
                Tween(wrap, 0.2, {Size = UDim2.new(0, W, 0, 0)})
                task.delay(0.22, function() wrap:Destroy() end)
            end
        end)
    end
    card.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then close() end
    end)
    Tween(card, 0.45, {Position = UDim2.new(0, 0, 0, 0)}, Enum.EasingStyle.Back)
    Tween(bar, duration, {Size = UDim2.new(0, 0, 0, 2)}, Enum.EasingStyle.Linear)
    task.delay(duration, close)
end

--------------------------------------------------------------------------------
-- CONFIG + AUTOSAVE
--------------------------------------------------------------------------------
local ROOT_FOLDER, CFG_FOLDER, AUTO_PATH = "LopopUI", "LopopUI/Configs", "LopopUI/AutoSave.json"

local function hasFS()
    return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
        and type(isfolder) == "function" and type(makefolder) == "function"
end

local function cleanName(name)
    name = (tostring(name or ""):gsub("[^%w%-_ ]", ""))
    return name:match("^%s*(.-)%s*$") or ""
end

local function noFS()
    Library:Notify({Title = "Config", Content = "Seu executor não suporta salvar arquivos.", Type = "Warning"})
end

function Library:EnsureFolders()
    if not hasFS() then return false end
    return pcall(function()
        if not isfolder(ROOT_FOLDER) then makefolder(ROOT_FOLDER) end
        if not isfolder(CFG_FOLDER) then makefolder(CFG_FOLDER) end
    end)
end

-- auto = true inclui o estado da janela (posição/aba), que só o autosave guarda
function Library:Collect(auto)
    local data = {}
    for k, v in pairs(self.Flags) do
        local t = type(v)
        if not self.NoSave[k] and (t == "string" or t == "number" or t == "boolean") then
            if auto or not tostring(k):match("^__ui_") then data[k] = v end
        end
    end
    return data
end

function Library:_apply(data)
    self.Loading = true
    for k, v in pairs(data) do
        local s = self.Setters[k]
        if s then pcall(s, v) end
    end
    self.Loading = false
end

function Library:_status(text, good)
    if self.StatusFn then pcall(self.StatusFn, text, good) end
end

-- chamado por todo elemento quando um valor muda
function Library:_changed(flag)
    if self.Loading or not self.Ready or self.NoSave[flag] or not self.AutoSaveEnabled then return end
    self.Dirty = true
    self:_status("Saving...", nil)
    if self._timer then return end
    self._timer = task.delay(0.8, function()
        self._timer = nil
        self:FlushAutoSave()
    end)
end

function Library:FlushAutoSave(force)
    if not self.Ready then return end
    if not (force or self.Dirty) then return end
    if not hasFS() then return end
    self:EnsureFolders()
    local ok, err = pcall(function() writefile(AUTO_PATH, HttpService:JSONEncode(self:Collect(true))) end)
    self.Dirty = false
    if ok then
        self:_status("Saved", true)
    else
        warn("[LopopUI] autosave: " .. tostring(err))
        self:_status("Save failed", false)
    end
end

function Library:LoadAutoSave()
    if not hasFS() then return false end
    local ok, exists = pcall(isfile, AUTO_PATH)
    if not ok or not exists then return false end
    local ok2, data = pcall(function() return HttpService:JSONDecode(readfile(AUTO_PATH)) end)
    if not ok2 or type(data) ~= "table" then return false end
    self:_apply(data)
    return true
end

function Library:ListConfigs()
    local out = {}
    if not hasFS() or type(listfiles) ~= "function" then return out end
    self:EnsureFolders()
    pcall(function()
        for _, path in ipairs(listfiles(CFG_FOLDER)) do
            local n = tostring(path):match("([^/\\]+)%.json$")
            if n then table.insert(out, n) end
        end
    end)
    table.sort(out)
    return out
end

function Library:SaveConfig(name, silent)
    name = cleanName(name)
    if name == "" then self:Notify({Title = "Config", Content = "Digite um nome para a config.", Type = "Warning"}) return false end
    if not hasFS() then noFS() return false end
    self:EnsureFolders()
    local ok, err = pcall(function() writefile(CFG_FOLDER .. "/" .. name .. ".json", HttpService:JSONEncode(self:Collect(false))) end)
    if ok then
        if not silent then self:Notify({Title = "Config salva", Content = "Arquivo '" .. name .. ".json' salvo com sucesso.", Type = "Success"}) end
    else
        self:Notify({Title = "Erro ao salvar", Content = tostring(err):sub(1, 80), Type = "Error"})
    end
    return ok
end

function Library:CreateConfig(name)
    name = cleanName(name)
    if name == "" then self:Notify({Title = "Config", Content = "Digite um nome para criar a config.", Type = "Warning"}) return false end
    if not hasFS() then noFS() return false end
    self:EnsureFolders()
    local exists = false
    pcall(function() exists = isfile(CFG_FOLDER .. "/" .. name .. ".json") end)
    if exists then self:Notify({Title = "Config", Content = "Já existe uma config chamada '" .. name .. "'.", Type = "Warning"}) return false end
    local ok = self:SaveConfig(name, true)
    if ok then self:Notify({Title = "Config criada", Content = "'" .. name .. ".json' criada em " .. CFG_FOLDER, Type = "Success"}) end
    return ok
end

function Library:LoadConfig(name)
    name = cleanName(name)
    if name == "" then self:Notify({Title = "Config", Content = "Selecione ou digite uma config.", Type = "Warning"}) return false end
    if not hasFS() then noFS() return false end
    local path = CFG_FOLDER .. "/" .. name .. ".json"
    local exists = false
    pcall(function() exists = isfile(path) end)
    if not exists then self:Notify({Title = "Config", Content = "Config '" .. name .. "' não encontrada.", Type = "Error"}) return false end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
    if not ok or type(data) ~= "table" then
        self:Notify({Title = "Config", Content = "Arquivo inválido ou corrompido.", Type = "Error"})
        return false
    end
    self:_apply(data)
    self.Dirty = true
    self:_changed("__loaded")
    self:Notify({Title = "Config carregada", Content = "'" .. name .. "' aplicada.", Type = "Success"})
    return true
end

function Library:DeleteConfig(name)
    name = cleanName(name)
    if name == "" then self:Notify({Title = "Config", Content = "Selecione uma config.", Type = "Warning"}) return false end
    if not hasFS() or type(delfile) ~= "function" then noFS() return false end
    local ok = pcall(function() delfile(CFG_FOLDER .. "/" .. name .. ".json") end)
    self:Notify({Title = ok and "Config removida" or "Erro", Content = ok and ("'" .. name .. "' foi deletada.") or "Não foi possível deletar.", Type = ok and "Success" or "Error"})
    return ok
end

--------------------------------------------------------------------------------
-- ELEMENTOS
--------------------------------------------------------------------------------
local Elements = {}

local function NewText(parent, text, size, font, colorKey, props)
    local l = Create("TextLabel", {BackgroundTransparency = 1, Text = text, TextSize = size, Font = font, TextXAlignment = Enum.TextXAlignment.Left, Parent = parent})
    for k, v in pairs(props or {}) do l[k] = v end
    Reg(l, "TextColor3", colorKey)
    return l
end

local function NewCard(scroll, h)
    local f = Create("Frame", {Size = UDim2.new(1, 0, 0, h or 38), BackgroundTransparency = 0.3, BorderSizePixel = 0, ClipsDescendants = true, Parent = scroll}, {Corner(10)})
    Reg(f, "BackgroundColor3", "Card")
    local s = Create("UIStroke", {Thickness = 1, Transparency = 0.7, Parent = f})
    Reg(s, "Color", "Accent2")
    f.MouseEnter:Connect(function() Tween(f, 0.2, {BackgroundColor3 = Library.Theme.CardHover}) end)
    f.MouseLeave:Connect(function() Tween(f, 0.25, {BackgroundColor3 = Library.Theme.Card}) end)
    return f, s
end

local function Ripple(parent, color)
    pcall(function()
        local m = UserInputService:GetMouseLocation()
        local x, y = m.X - parent.AbsolutePosition.X, m.Y - parent.AbsolutePosition.Y
        local big = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2.4
        local r = Create("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(0, 0), BackgroundColor3 = color,
            BackgroundTransparency = 0.6, BorderSizePixel = 0, ZIndex = 2, Parent = parent}, {Round()})
        Tween(r, 0.55, {Size = UDim2.fromOffset(big, big), BackgroundTransparency = 1})
        task.delay(0.6, function() r:Destroy() end)
    end)
end

local function Chevron(parent, pos)
    local c = Create("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1, Parent = parent})
    for _, rot in ipairs({40, -40}) do
        local bar = Create("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, rot > 0 and -3 or 3, 0.5, 0), Size = UDim2.fromOffset(8, 2),
            Rotation = rot, BorderSizePixel = 0, Parent = c}, {Corner(1)})
        Reg(bar, "BackgroundColor3", "Accent")
    end
    return c
end

local function MakeButton(parent, o, size)
    local primary = o.Primary
    local b = Create("TextButton", {Size = size, Text = "", AutoButtonColor = false, BorderSizePixel = 0, BackgroundTransparency = primary and 0.05 or 0.3,
        ClipsDescendants = true, Parent = parent}, {Corner(10)})
    Reg(b, "BackgroundColor3", primary and "Accent" or "Card")
    local st = Create("UIStroke", {Thickness = 1, Transparency = primary and 1 or 0.7, Parent = b})
    Reg(st, "Color", "Accent2")
    local t = Create("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = o.Name, Font = FONT_B, TextSize = 13, ZIndex = 3, Parent = b})
    if primary then t.TextColor3 = WHITE else Reg(t, "TextColor3", "Text") end
    b.MouseEnter:Connect(function()
        Tween(b, 0.2, {BackgroundColor3 = primary and Library.Theme.Accent:Lerp(WHITE, 0.15) or Library.Theme.CardHover})
        if not primary then Tween(st, 0.2, {Transparency = 0.2}) end
    end)
    b.MouseLeave:Connect(function()
        Tween(b, 0.25, {BackgroundColor3 = primary and Library.Theme.Accent or Library.Theme.Card})
        if not primary then Tween(st, 0.25, {Transparency = 0.7}) end
    end)
    b.MouseButton1Click:Connect(function()
        Ripple(b, primary and WHITE or Library.Theme.Accent)
        Safe(o.Callback)
    end)
    return b
end

function Elements:AddSection(text)
    text = string.upper(text)
    local row = Create("Frame", {Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Parent = self.Scroll})
    local w = 40
    pcall(function() w = TextService:GetTextSize(text, 11, FONT_B, Vector2.new(1000, 20)).X end)
    NewText(row, text, 11, FONT_B, "Accent", {Size = UDim2.new(0, w + 2, 1, 0)})
    local line = Create("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, w + 12, 0.5, 0), Size = UDim2.new(1, -(w + 12), 0, 1),
        BackgroundTransparency = 0.7, BorderSizePixel = 0, Parent = row})
    Reg(line, "BackgroundColor3", "Accent2")
end

function Elements:AddLabel(text)
    local l = NewText(self.Scroll, text, 12, FONT_R, "SubText", {Size = UDim2.new(1, 0, 0, 16), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true})
    return {Set = function(_, t) l.Text = t end}
end

function Elements:AddInfoCard(title, sub)
    local card = NewCard(self.Scroll, 56)
    local a = NewText(card, title, 15, FONT_B, "Text", {Position = UDim2.fromOffset(14, 9), Size = UDim2.new(1, -28, 0, 20), TextTruncate = Enum.TextTruncate.AtEnd})
    local b = NewText(card, sub, 12, FONT_R, "SubText", {Position = UDim2.fromOffset(14, 31), Size = UDim2.new(1, -28, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd})
    return {Set = function(_, t1, t2) a.Text = t1 b.Text = t2 end}
end

function Elements:AddButton(o)
    o.Name = o.Name or "Button"
    return MakeButton(self.Scroll, o, UDim2.new(1, 0, 0, 34))
end

function Elements:AddButtonRow(list)
    local n = #list
    local pad = 8
    local row = Create("Frame", {Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Parent = self.Scroll},
        {Create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, pad), SortOrder = Enum.SortOrder.LayoutOrder})})
    for i, o in ipairs(list) do
        local b = MakeButton(row, o, UDim2.new(1 / n, -(pad * (n - 1)) / n, 1, 0))
        b.LayoutOrder = i
    end
end

function Elements:AddToggle(o)
    local flag = o.Flag or o.Name
    local state = o.Default and true or false
    local h = o.Desc and 50 or 38
    local card = NewCard(self.Scroll, h)
    NewText(card, o.Name, 13, FONT_M, "Text", {Position = UDim2.fromOffset(12, o.Desc and 7 or 0), Size = UDim2.new(1, -72, 0, o.Desc and 18 or h)})
    if o.Desc then NewText(card, o.Desc, 11, FONT_R, "SubText", {Position = UDim2.fromOffset(12, 26), Size = UDim2.new(1, -72, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd}) end
    local sw = Create("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(38, 20), BorderSizePixel = 0, Parent = card}, {Round()})
    local knob = Create("Frame", {AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = sw}, {Round()})
    local function pos() return state and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) end
    local function render()
        Tween(sw, 0.25, {BackgroundColor3 = state and Library.Theme.Accent or Library.Theme.Off})
        Tween(knob, 0.25, {Position = pos()}, Enum.EasingStyle.Back)
    end
    table.insert(Library.Hooks, render)
    sw.BackgroundColor3 = state and Library.Theme.Accent or Library.Theme.Off
    knob.Position = pos()
    Library.Flags[flag] = state
    local function set(v)
        state = v and true or false
        Library.Flags[flag] = state
        render()
        Library:_changed(flag)
        Safe(o.Callback, state)
    end
    Library.Setters[flag] = set
    if o.NoSave then Library.NoSave[flag] = true end
    Create("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Parent = card}).MouseButton1Click:Connect(function() set(not state) end)
    if state then task.defer(function() Safe(o.Callback, state) end) end
    return {Set = function(_, v) set(v) end, Get = function() return state end}
end

function Elements:AddSlider(o)
    local flag = o.Flag or o.Name
    local min, max, step = o.Min or 0, o.Max or 100, o.Step or 1
    local value = math.clamp(o.Default or min, min, max)
    local suffix = o.Suffix or ""
    local decimals = step < 1 and 2 or 0
    local card = NewCard(self.Scroll, o.Desc and 62 or 52)
    local top = o.Desc and 6 or 7
    NewText(card, o.Name, 13, FONT_M, "Text", {Position = UDim2.fromOffset(12, top), Size = UDim2.new(1, -90, 0, 18)})
    if o.Desc then NewText(card, o.Desc, 11, FONT_R, "SubText", {Position = UDim2.fromOffset(12, 24), Size = UDim2.new(1, -24, 0, 14), TextTruncate = Enum.TextTruncate.AtEnd}) end
    local valLabel = NewText(card, "", 12, FONT_B, "Accent", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, top), Size = UDim2.fromOffset(70, 18), TextXAlignment = Enum.TextXAlignment.Right})
    local ty = o.Desc and 48 or 36
    local track = Create("Frame", {Position = UDim2.new(0, 12, 0, ty), Size = UDim2.new(1, -24, 0, 4), BorderSizePixel = 0, Parent = card}, {Corner(2)})
    Reg(track, "BackgroundColor3", "Off")
    local fill = Create("Frame", {Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, Parent = track}, {Corner(2)})
    Reg(fill, "BackgroundColor3", "Accent")
    local knob = Create("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = track}, {Round()})
    local function render()
        local a = (max > min) and (value - min) / (max - min) or 0
        Tween(fill, 0.08, {Size = UDim2.fromScale(a, 1)})
        Tween(knob, 0.08, {Position = UDim2.new(a, 0, 0.5, 0)})
        valLabel.Text = string.format("%." .. decimals .. "f", value) .. suffix
    end
    local function set(v, silent)
        v = tonumber(v)
        if not v then return end
        v = math.clamp(math.floor(v / step + 0.5) * step, min, max)
        if v == value and Library.Flags[flag] == value then return end
        value = v
        Library.Flags[flag] = v
        render()
        if not silent then
            Library:_changed(flag)
            Safe(o.Callback, v)
        end
    end
    Library.Flags[flag] = value
    render()
    if o.NoSave then Library.NoSave[flag] = true end
    Library.Setters[flag] = function(v) set(v) end

    local dragging = false
    local function fromX(x)
        local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        set(min + a * (max - min))
    end
    local hit = Create("TextButton", {Position = UDim2.new(0, 8, 0, ty - 10), Size = UDim2.new(1, -16, 0, 24), BackgroundTransparency = 1, Text = "", Parent = card})
    hit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            fromX(i.Position.X)
        end
    end)
    Connect(UserInputService.InputChanged, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then fromX(i.Position.X) end
    end)
    Connect(UserInputService.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    return {Set = function(_, v) set(v) end, Get = function() return value end}
end

function Elements:AddInput(o)
    local flag = o.Flag or o.Name
    local w = o.Width or 170
    local card = NewCard(self.Scroll, 38)
    NewText(card, o.Name, 13, FONT_M, "Text", {Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -(w + 24), 1, 0)})
    local box = Create("TextBox", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(w, 26),
        Text = tostring(o.Default or ""), PlaceholderText = o.Placeholder or "", ClearTextOnFocus = false, Font = FONT_R, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, ClipsDescendants = true, BorderSizePixel = 0, BackgroundTransparency = 0.35, Parent = card}, {Corner(5), Pad(8, 8, 0, 0)})
    Reg(box, "BackgroundColor3", "Panel")
    Reg(box, "TextColor3", "Text")
    Reg(box, "PlaceholderColor3", "SubText")
    local st = Create("UIStroke", {Thickness = 1, Transparency = 1, Parent = box})
    Reg(st, "Color", "Accent")
    box.Focused:Connect(function() Tween(st, 0.2, {Transparency = 0}) end)
    Library.Flags[flag] = box.Text
    if o.NoSave then Library.NoSave[flag] = true end
    box.FocusLost:Connect(function(enter)
        Tween(st, 0.2, {Transparency = 1})
        Library.Flags[flag] = box.Text
        Library:_changed(flag)
        Safe(o.Callback, box.Text, enter, false)
    end)
    Library.Setters[flag] = function(v)
        box.Text = tostring(v)
        Library.Flags[flag] = box.Text
        Safe(o.Callback, box.Text, false, true)
    end
    return {Set = function(_, v) box.Text = tostring(v) Library.Flags[flag] = box.Text Library:_changed(flag) end, Get = function() return box.Text end}
end

function Elements:AddDropdown(o)
    local flag = o.Flag or o.Name
    local options = o.Options or {}
    local value = o.Default
    local open = false
    local buttons = {}

    local container = Create("Frame", {Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 0.3, BorderSizePixel = 0, ClipsDescendants = true, Parent = self.Scroll}, {Corner(10)})
    Reg(container, "BackgroundColor3", "Card")
    local cs = Create("UIStroke", {Thickness = 1, Transparency = 0.7, Parent = container})
    Reg(cs, "Color", "Accent2")
    NewText(container, o.Name, 13, FONT_M, "Text", {Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.5, -12, 0, 38)})
    local valueLabel = NewText(container, "", 12, FONT_R, "SubText", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -32, 0, 0), Size = UDim2.new(0.5, -34, 0, 38),
        TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd})
    local arrow = Chevron(container, UDim2.new(1, -17, 0, 19))
    local list = Create("Frame", {Position = UDim2.fromOffset(6, 42), Size = UDim2.new(1, -12, 0, 0), BackgroundTransparency = 1, Parent = container},
        {Create("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder})})

    local function expandedH()
        local n = #options
        return 38 + 4 + n * 28 + math.max(n - 1, 0) * 4 + 8
    end
    local function render()
        valueLabel.Text = value ~= nil and tostring(value) or "Selecionar"
        for opt, b in pairs(buttons) do
            Tween(b, 0.2, {BackgroundColor3 = (opt == value) and Library.Theme.Active or Library.Theme.Panel})
        end
    end
    table.insert(Library.Hooks, render)

    local function set(v, silent)
        value = v
        Library.Flags[flag] = v
        render()
        if not silent then
            Library:_changed(flag)
            Safe(o.Callback, v)
        end
    end
    local function setOpen(s)
        open = s
        Tween(container, 0.28, {Size = UDim2.new(1, 0, 0, s and expandedH() or 38)})
        Tween(arrow, 0.28, {Rotation = s and 180 or 0})
    end
    local function rebuild()
        for _, b in pairs(buttons) do b:Destroy() end
        buttons = {}
        for i, opt in ipairs(options) do
            local b = Create("TextButton", {LayoutOrder = i, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 0.35, Text = tostring(opt), Font = FONT_M,
                TextSize = 12, AutoButtonColor = false, BorderSizePixel = 0, Parent = list}, {Corner(5)})
            Reg(b, "TextColor3", "Text")
            b.BackgroundColor3 = Library.Theme.Panel
            b.MouseButton1Click:Connect(function() set(opt) setOpen(false) end)
            buttons[opt] = b
        end
        render()
        if open then Tween(container, 0.2, {Size = UDim2.new(1, 0, 0, expandedH())}) end
    end
    rebuild()

    Create("TextButton", {Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Text = "", Parent = container}).MouseButton1Click:Connect(function() setOpen(not open) end)

    if value ~= nil then Library.Flags[flag] = value end
    if o.NoSave then Library.NoSave[flag] = true end
    Library.Setters[flag] = function(v) set(v) end
    local obj = {}
    function obj:Set(v, silent) set(v, silent) end
    function obj:Get() return value end
    function obj:SetOptions(list2)
        options = list2 or {}
        local found = false
        for _, opt in ipairs(options) do if opt == value then found = true end end
        if not found then value = nil Library.Flags[flag] = nil end
        rebuild()
    end
    return obj
end

function Elements:AddThemePicker()
    local holder = Create("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = self.Scroll},
        {Create("UIGridLayout", {CellSize = UDim2.new(0.5, -4, 0, 40), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder})})
    local items = {}
    for i, name in ipairs(ThemeOrder) do
        local t = Themes[name]
        local b = Create("TextButton", {LayoutOrder = i, BackgroundTransparency = 0.3, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Parent = holder}, {Corner(10)})
        Reg(b, "BackgroundColor3", "Card")
        local st = Create("UIStroke", {Thickness = 1, Transparency = 0.7, Parent = b})
        Reg(st, "Color", "Accent2")
        Create("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 9, 0.5, 0), Size = UDim2.fromOffset(24, 24), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = b},
            {Corner(6), Create("UIGradient", {Rotation = 45, Color = ColorSequence.new(t.Accent, t.Main)})})
        NewText(b, name, 12, FONT_M, "Text", {Position = UDim2.fromOffset(42, 0), Size = UDim2.new(1, -46, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd})
        b.MouseButton1Click:Connect(function()
            Library:SetTheme(name)
            Library:Notify({Title = "Tema alterado", Content = name, Type = "Success", Duration = 2.5})
        end)
        b.MouseEnter:Connect(function() Tween(b, 0.2, {BackgroundColor3 = Library.Theme.CardHover}) end)
        b.MouseLeave:Connect(function() Tween(b, 0.2, {BackgroundColor3 = Library.Theme.Card}) end)
        items[name] = st
    end
    local function render()
        for name, st in pairs(items) do
            local sel = (name == Library.ThemeName)
            Tween(st, 0.25, {Thickness = sel and 2 or 1, Transparency = sel and 0 or 0.7, Color = sel and Library.Theme.Accent or Library.Theme.Accent2})
        end
    end
    table.insert(Library.Hooks, render)
    render()
end

for _, n in ipairs({"Section", "Label", "InfoCard", "Button", "ButtonRow", "Toggle", "Slider", "Input", "Dropdown", "ThemePicker"}) do
    Elements[n] = Elements["Add" .. n]
end


--------------------------------------------------------------------------------
-- JANELA
--------------------------------------------------------------------------------
function Library:CreateWindow(opt)
    opt = opt or {}
    local Window = {Tabs = {}, Visible = true, Minimized = false, _bgToken = 0}
    local MINW, MINH, MAXW, MAXH, HEADER = 540, 380, 860, 580, 58
    local sizeW, sizeH = 640, 440     -- tamanho exibido agora
    local fullW, fullH = 640, 440     -- tamanho normal (quando não está minimizada)

    local root = Create("Frame", {
        Name = "Root", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(sizeW, sizeH),
        BackgroundColor3 = WHITE, BackgroundTransparency = 0.08, BorderSizePixel = 0, ClipsDescendants = true, Active = true, Parent = gui,
    }, {Corner(16)})
    local scale = Create("UIScale", {Scale = 0, Parent = root})
    local rootStroke = Create("UIStroke", {Thickness = 2.4, Color = WHITE, Parent = root})
    local strokeGrad = Create("UIGradient", {Parent = rootStroke})
    local grad = Create("UIGradient", {Rotation = 90, Parent = root})
    local function applyGrad(t)
        grad.Color = ColorSequence.new(t.Main:Lerp(WHITE, 0.2), t.Main)
        strokeGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, t.Accent), ColorSequenceKeypoint.new(0.5, t.Accent2), ColorSequenceKeypoint.new(1, t.Accent)})
    end
    applyGrad(Library.Theme)
    table.insert(Library.Hooks, applyGrad)

    ---------------- camadas de fundo: imagem -> escurecimento -> pirulitos -> brilhos
    local bg = Create("ImageLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ImageTransparency = 1, ScaleType = Enum.ScaleType.Crop, Parent = root}, {Corner(16)})
    local dim = Create("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0.5, BorderSizePixel = 0, Visible = false, Parent = root}, {Corner(16)})
    Reg(dim, "BackgroundColor3", "Panel")

    local patternClip = Create("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, Parent = root})
    local TILE = 220
    local cols, rows = math.ceil(MAXW / TILE) + 1, math.ceil(MAXH / TILE) + 1
    local patHolder = Create("Frame", {Size = UDim2.fromOffset(cols * TILE, rows * TILE), BackgroundTransparency = 1, Parent = patternClip})
    local patHeads, patDeco, patRings = {}, {}, {}

    local function lollipop(x, y, size, rot)
        local g = Create("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(size, size * 2.7),
            Rotation = rot, BackgroundTransparency = 1, Parent = patHolder})
        local stick = Create("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, size * 0.8),
            Size = UDim2.fromOffset(math.max(3, size * 0.12), size * 1.9), BackgroundTransparency = 0.78, BorderSizePixel = 0, Parent = g}, {Corner(2)})
        local head = Create("Frame", {Size = UDim2.fromOffset(size, size), BackgroundTransparency = 0.7, BorderSizePixel = 0, Parent = g}, {Round()})
        local ring = Create("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.56, 0.56),
            BackgroundTransparency = 1, BorderSizePixel = 0, Parent = head}, {Round()})
        local rs = Create("UIStroke", {Thickness = 2, Transparency = 0.55, Parent = ring})
        table.insert(patDeco, stick)
        table.insert(patHeads, head)
        table.insert(patRings, rs)
    end
    local function heart(x, y, s)
        local function piece(nx, ny, rot, round)
            local f = Create("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x - s / 2 + nx * s, y - s / 2 + ny * s),
                Size = UDim2.fromOffset(0.6 * s, 0.6 * s), Rotation = rot, BackgroundTransparency = 0.68, BorderSizePixel = 0, Parent = patHolder})
            if round then Round().Parent = f end
            table.insert(patDeco, f)
        end
        piece(0.5, 0.58, 45, false)
        piece(0.288, 0.368, 0, true)
        piece(0.712, 0.368, 0, true)
    end
    for cx = 0, cols - 1 do
        for cy = 0, rows - 1 do
            local ox, oy = cx * TILE, cy * TILE
            lollipop(ox + 52, oy + 22, 48, -10)
            lollipop(ox + 150, oy + 96, 34, 14)
            heart(ox + 160, oy + 36, 24)
            heart(ox + 88, oy + 170, 18)
        end
    end
    local function setPat(t, dur)
        local function put(o, prop, col)
            if dur > 0 then Tween(o, dur, {[prop] = col}) else o[prop] = col end
        end
        for _, o in ipairs(patHeads) do put(o, "BackgroundColor3", t.Pat1) end
        for _, o in ipairs(patDeco) do put(o, "BackgroundColor3", t.Pat2) end
        for _, s in ipairs(patRings) do put(s, "Color", t.Pat2) end
    end
    setPat(Library.Theme, 0)
    table.insert(Library.Hooks, function(t) setPat(t, 0.35) end)

    local patternWanted, hasImage = true, false
    local function refreshPattern() patternClip.Visible = patternWanted and not hasImage end
    function Window:SetPattern(v)
        patternWanted = v and true or false
        refreshPattern()
    end

    -- brilhos subindo (círculos e losangos), com cintilação
    local layer = Create("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, Parent = root})
    local rng = Random.new()
    local sparks = {}
    local function resetSpark(p, initial)
        p.x = rng:NextNumber(0, 1)
        p.y = initial and rng:NextNumber(0, sizeH) or (sizeH + p.size + rng:NextNumber(0, 80))
        p.phase = rng:NextNumber(0, 6.28)
    end
    for i = 1, 30 do
        local size = rng:NextInteger(3, 9)
        local diamond = (i % 3 == 0)
        local f = Create("Frame", {Size = UDim2.fromOffset(size, size), AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Rotation = diamond and 45 or 0,
            Parent = layer}, {Corner(diamond and 1 or 99)})
        Reg(f, "BackgroundColor3", "Particle")
        local p = {f = f, size = size, speed = rng:NextNumber(18, 55), sway = rng:NextNumber(4, 14), tw = rng:NextNumber(1.5, 3)}
        resetSpark(p, true)
        table.insert(sparks, p)
    end

    ---------------- cabeçalho
    local drag = Create("Frame", {Size = UDim2.new(1, 0, 0, HEADER), BackgroundTransparency = 1, Active = true, Parent = root})
    local title = tostring(opt.Title or "LopopUI")
    local tw = 90
    pcall(function() tw = TextService:GetTextSize(title, 20, Enum.Font.JosefinSans, Vector2.new(400, 30)).X end)
    local pill = Create("Frame", {Position = UDim2.fromOffset(14, 12), Size = UDim2.fromOffset(tw + 30, 34), BackgroundTransparency = 0.05, BorderSizePixel = 0, Parent = root},
        {Round(), Create("UIStroke", {Color = WHITE, Thickness = 1.5, Transparency = 0.55})})
    Reg(pill, "BackgroundColor3", "Pill")
    local pillText = Create("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = title, Font = Enum.Font.JosefinSans, TextSize = 20, Parent = pill})
    Reg(pillText, "TextColor3", "PillText")

    local fpsLabel = NewText(root, "-- FPS", 11, FONT_M, "SubText", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -86, 0, 12), Size = UDim2.fromOffset(160, 14), TextXAlignment = Enum.TextXAlignment.Right})
    local statusLabel = Create("TextLabel", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -86, 0, 28), Size = UDim2.fromOffset(160, 14), BackgroundTransparency = 1,
        Text = "", Font = FONT_B, TextSize = 10, TextTransparency = 1, TextXAlignment = Enum.TextXAlignment.Right, Parent = root})
    local statusToken = 0
    Library.StatusFn = function(text, good)
        statusToken = statusToken + 1
        local my = statusToken
        statusLabel.Text = text
        statusLabel.TextColor3 = (good == true) and C(90, 235, 150) or ((good == false) and C(255, 90, 100) or Library.Theme.SubText)
        statusLabel.TextTransparency = 0
        if good ~= nil then
            task.delay(2, function() if my == statusToken then Tween(statusLabel, 0.6, {TextTransparency = 1}) end end)
        end
    end

    local function WinBtn(xoff, color)
        local b = Create("TextButton", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, xoff, 0, 17), Size = UDim2.fromOffset(24, 24), BackgroundColor3 = color,
            Text = "", AutoButtonColor = false, BorderSizePixel = 0, Parent = root}, {Corner(8), Create("UIStroke", {Color = C(20, 6, 14), Thickness = 1.5, Transparency = 0.2})})
        b.MouseEnter:Connect(function() Tween(b, 0.15, {BackgroundColor3 = color:Lerp(WHITE, 0.3)}) end)
        b.MouseLeave:Connect(function() Tween(b, 0.2, {BackgroundColor3 = color}) end)
        return b
    end
    local closeBtn = WinBtn(-14, C(255, 52, 52))   -- vermelho: fecha o script (Destroy)
    local minBtn = WinBtn(-46, C(255, 170, 48))    -- laranja: minimiza
    for _, rot in ipairs({45, -45}) do
        Create("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(12, 2), Rotation = rot,
            BackgroundColor3 = C(60, 10, 20), BorderSizePixel = 0, Parent = closeBtn})
    end
    Create("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(12, 2),
        BackgroundColor3 = C(60, 10, 20), BorderSizePixel = 0, Parent = minBtn})

    ---------------- tamanho / posição
    local function applySize(w, h, t)
        local p = root.Position
        local np = UDim2.new(p.X.Scale, p.X.Offset + (w - sizeW) / 2, p.Y.Scale, p.Y.Offset + (h - sizeH) / 2)
        sizeW, sizeH = w, h
        if t and t > 0 then
            Tween(root, t, {Size = UDim2.fromOffset(w, h), Position = np})
        else
            root.Size, root.Position = UDim2.fromOffset(w, h), np
        end
    end
    local function saveWin()
        local w = Window.Minimized and fullW or sizeW
        local h = Window.Minimized and fullH or sizeH
        local sz = gui.AbsoluteSize
        if sz.X <= 0 or sz.Y <= 0 then return end
        local cx = (root.AbsolutePosition.X + w / 2) / sz.X
        local cy = (root.AbsolutePosition.Y + h / 2) / sz.Y
        Library.Flags["__ui_win"] = string.format("%.4f,%.4f,%d,%d", cx, cy, math.floor(w), math.floor(h))
        Library:_changed("__ui_win")
    end
    Library.Setters["__ui_win"] = function(v)
        local cx, cy, w, h = tostring(v):match("([%d%.%-]+),([%d%.%-]+),(%d+),(%d+)")
        cx, cy, w, h = tonumber(cx), tonumber(cy), tonumber(w), tonumber(h)
        if cx and cy and w and h then
            w, h = math.clamp(w, MINW, MAXW), math.clamp(h, MINH, MAXH)
            fullW, fullH, sizeW, sizeH = w, h, w, h
            if not Window.Minimized then root.Size = UDim2.fromOffset(w, h) end
            root.Position = UDim2.fromScale(math.clamp(cx, 0.05, 0.95), math.clamp(cy, 0.05, 0.95))
        end
    end

    local dragging, dragStart, startPos
    drag.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, i.Position, root.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging = false saveWin() end
            end)
        end
    end)
    Connect(UserInputService.InputChanged, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)

    ---------------- corpo: sidebar + conteúdo
    local body = Create("Frame", {Position = UDim2.fromOffset(0, HEADER), Size = UDim2.new(1, 0, 1, -HEADER), BackgroundTransparency = 1, Parent = root})
    local function Panel(pos, size)
        local f = Create("Frame", {Position = pos, Size = size, BackgroundTransparency = 0.4, BorderSizePixel = 0, Parent = body}, {Corner(12)})
        Reg(f, "BackgroundColor3", "Panel")
        local s = Create("UIStroke", {Thickness = 1.5, Transparency = 0.45, Parent = f})
        Reg(s, "Color", "Accent2")
        return f
    end
    local SBW = 150
    local sidebar = Panel(UDim2.fromOffset(14, 0), UDim2.new(0, SBW, 1, -16))
    local content = Panel(UDim2.fromOffset(14 + SBW + 10, 0), UDim2.new(1, -(14 + SBW + 10) - 14, 1, -16))
    content.ClipsDescendants = true
    local sideList = Create("ScrollingFrame", {Size = UDim2.new(1, 0, 1, -62), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = sidebar},
        {Create("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}), Pad(10, 10, 10, 8)})

    -- perfil
    local profile = Create("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 8, 1, -8), Size = UDim2.new(1, -16, 0, 44), BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = sidebar}, {Corner(10)})
    Reg(profile, "BackgroundColor3", "Card")
    local avatar = Create("ImageLabel", {Position = UDim2.fromOffset(7, 7), Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 0.4, BorderSizePixel = 0, Image = "", Parent = profile}, {Round()})
    Reg(avatar, "BackgroundColor3", "Off")
    NewText(profile, LocalPlayer.DisplayName, 12, FONT_B, "Text", {Position = UDim2.fromOffset(44, 6), Size = UDim2.new(1, -50, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd})
    NewText(profile, "@" .. LocalPlayer.Name, 10, FONT_R, "SubText", {Position = UDim2.fromOffset(44, 22), Size = UDim2.new(1, -50, 0, 14), TextTruncate = Enum.TextTruncate.AtEnd})
    task.spawn(function()
        local ok, url = pcall(function() return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48) end)
        if ok and url then avatar.Image = url end
    end)

    -- canto de redimensionar (arraste)
    local handle = Create("TextButton", {AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -3, 1, -3), Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1, Text = "", Parent = body})
    for _, horizontal in ipairs({true, false}) do
        local bar = Create("Frame", {AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Size = horizontal and UDim2.fromOffset(16, 2) or UDim2.fromOffset(2, 16),
            BorderSizePixel = 0, Parent = handle}, {Corner(1)})
        Reg(bar, "BackgroundColor3", "Text")
    end
    local resizing, rStart, rW, rH = false, nil, 0, 0
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            resizing, rStart, rW, rH = true, i.Position, sizeW, sizeH
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then
                    resizing = false
                    fullW, fullH = sizeW, sizeH
                    saveWin()
                end
            end)
        end
    end)
    Connect(UserInputService.InputChanged, function(i)
        if resizing and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - rStart
            applySize(math.clamp(rW + d.X, MINW, MAXW), math.clamp(rH + d.Y, MINH, MAXH), 0)
        end
    end)

    ---------------- minimizar / fechar / abrir (tecla)
    function Window:SetMinimized(v)
        if v == Window.Minimized then return end
        Window.Minimized = v
        if v then
            fullW, fullH = sizeW, sizeH
            applySize(sizeW, HEADER, 0.3)
            task.delay(0.28, function() if Window.Minimized then body.Visible = false end end)
        else
            body.Visible = true
            applySize(fullW, fullH, 0.35)
        end
    end
    minBtn.MouseButton1Click:Connect(function() Window:SetMinimized(not Window.Minimized) end)

    function Window:SetVisible(v)
        Window.Visible = v
        if v then
            root.Visible = true
            Tween(scale, 0.4, {Scale = 1}, Enum.EasingStyle.Back)
        else
            Tween(scale, 0.22, {Scale = 0}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            task.delay(0.23, function() if not Window.Visible then root.Visible = false end end)
        end
    end
    -- X vermelho = fecha o script por inteiro (Destroy). A tecla de toggle só mostra/esconde.
    local closing = false
    closeBtn.MouseButton1Click:Connect(function()
        if closing then return end
        closing = true
        Tween(scale, 0.25, {Scale = 0}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.delay(0.28, function() Library:Destroy() end)
    end)
    Connect(UserInputService.InputBegan, function(i, gp)
        if gp then return end
        if i.KeyCode == Library.ToggleKey then Window:SetVisible(not Window.Visible) end
    end)
    Tween(scale, 0.6, {Scale = 1}, Enum.EasingStyle.Back)

    ---------------- loop: FPS/ping, borda animada, pirulitos e brilhos
    local clock, frames, acc = 0, 0, 0
    Connect(RunService.Heartbeat, function(dt)
        frames, acc = frames + 1, acc + dt
        if acc >= 0.5 then
            local ping = 0
            pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
            fpsLabel.Text = math.floor(frames / acc + 0.5) .. " FPS  |  " .. ping .. " ms"
            frames, acc = 0, 0
        end
        if not root.Visible then return end
        clock = clock + dt
        strokeGrad.Rotation = (clock * 60) % 360
        if patternClip.Visible then
            patHolder.Position = UDim2.fromOffset(-((clock * 9) % TILE), -((clock * 6) % TILE))
        end
        if not Library.ParticlesEnabled then
            layer.Visible = false
            return
        end
        layer.Visible = true
        local sp = Library.ParticleSpeed
        for _, p in ipairs(sparks) do
            p.y = p.y - p.speed * dt * sp
            if p.y < -p.size then resetSpark(p, false) end
            p.f.Position = UDim2.new(p.x, math.sin(clock * 1.1 + p.phase) * p.sway, 0, p.y)
            p.f.BackgroundTransparency = 0.35 + 0.45 * (0.5 + 0.5 * math.sin(clock * p.tw + p.phase))
        end
    end)

    ---------------- fundo por ID (imagem / decal 2D)
    local bgOpacity = 0.7
    function Window:SetBackgroundOpacity(v)
        bgOpacity = math.clamp(v, 0, 1)
        if bg.Image ~= "" then Tween(bg, 0.3, {ImageTransparency = 1 - bgOpacity}) end
    end

    function Window:SetBackground(idText, silent)
        Window._bgToken = Window._bgToken + 1
        local token = Window._bgToken
        local digits = (tostring(idText or ""):gsub("%D", ""))
        if digits == "" then
            Tween(bg, 0.3, {ImageTransparency = 1})
            dim.Visible = false
            hasImage = false
            refreshPattern()
            task.delay(0.32, function() if token == Window._bgToken then bg.Image = "" end end)
            if not silent then Library:Notify({Title = "Background", Content = "Fundo removido.", Type = "Info", Duration = 2.5}) end
            return
        end
        local id = tonumber(digits)
        task.spawn(function()
            if not silent then Library:Notify({Title = "Background", Content = "Verificando ID " .. digits .. "...", Type = "Info", Duration = 2}) end
            local ok, info = pcall(function() return MarketplaceService:GetProductInfo(id, Enum.InfoType.Asset) end)
            if token ~= Window._bgToken then return end
            if not ok or type(info) ~= "table" then
                Library:Notify({Title = "Background", Content = "ID inválido ou indisponível.", Type = "Error", Force = true})
                return
            end
            local at = info.AssetTypeId
            if at ~= 1 and at ~= 13 then
                Library:Notify({Title = "Background", Content = "Esse ID não é uma imagem ou decal (tipo " .. tostring(at) .. ").", Type = "Error", Force = true})
                return
            end
            local loaded = false
            for _, url in ipairs({"rbxthumb://type=Asset&id=" .. id .. "&w=420&h=420", "rbxassetid://" .. id}) do
                bg.Image = url
                pcall(function() ContentProvider:PreloadAsync({bg}) end)
                if token ~= Window._bgToken then return end
                if bg.IsLoaded then loaded = true break end
            end
            if not loaded then
                bg.Image = ""
                Library:Notify({Title = "Background", Content = "Não foi possível carregar a imagem (privada ou em moderação).", Type = "Error", Force = true})
                return
            end
            hasImage = true
            refreshPattern()
            dim.Visible = true
            bg.ImageTransparency = 1
            Tween(bg, 0.6, {ImageTransparency = 1 - bgOpacity})
            Library:Notify({Title = "Background aplicado", Content = tostring(info.Name or digits), Type = "Success", Force = true})
        end)
    end

    ---------------- abas
    function Window:AddTab(name)
        local Tab = setmetatable({Name = name}, {__index = Elements})

        local btn = Create("TextButton", {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 0.2, Text = "", AutoButtonColor = false, BorderSizePixel = 0,
            LayoutOrder = #Window.Tabs + 1, Parent = sideList}, {Round()})
        btn.BackgroundColor3 = Library.Theme.Pill
        local stroke = Create("UIStroke", {Thickness = 1, Transparency = 1, Parent = btn})
        Reg(stroke, "Color", "Text")
        local lbl = Create("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = name, Font = Enum.Font.JosefinSans, TextSize = 18, Parent = btn})
        Reg(lbl, "TextColor3", "PillText")

        local page = Create("CanvasGroup", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, GroupTransparency = 1, Visible = false, Parent = content})
        local scroll = Create("ScrollingFrame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = page},
            {Create("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}), Pad(12, 14, 10, 10)})
        Reg(scroll, "ScrollBarImageColor3", "Accent")
        NewText(scroll, name, 24, Enum.Font.JosefinSans, "Text", {LayoutOrder = -1000, Size = UDim2.new(1, 0, 0, 30)})
        Tab.Scroll, Tab.Page = scroll, page

        function Tab._render()
            local sel = Window.Current == Tab
            Tween(btn, 0.25, {BackgroundColor3 = sel and Library.Theme.Pill:Lerp(WHITE, 0.3) or Library.Theme.Pill, BackgroundTransparency = sel and 0 or 0.2})
            Tween(stroke, 0.25, {Transparency = sel and 0.05 or 1, Thickness = sel and 2.5 or 1})
        end
        table.insert(Library.Hooks, Tab._render)
        btn.MouseEnter:Connect(function() if Window.Current ~= Tab then Tween(btn, 0.2, {BackgroundTransparency = 0.02}) end end)
        btn.MouseLeave:Connect(function() if Window.Current ~= Tab then Tween(btn, 0.2, {BackgroundTransparency = 0.2}) end end)

        function Tab:Select()
            if Window.Current == Tab then return end
            Window.Current = Tab
            Library.Flags["__ui_tab"] = name
            Library:_changed("__ui_tab")
            for _, t in ipairs(Window.Tabs) do
                t._render()
                if t ~= Tab and t.Page.Visible then
                    Tween(t.Page, 0.15, {GroupTransparency = 1})
                    task.delay(0.16, function() if Window.Current ~= t then t.Page.Visible = false end end)
                end
            end
            page.Visible = true
            page.GroupTransparency = 1
            page.Position = UDim2.fromOffset(0, 14)
            Tween(page, 0.35, {GroupTransparency = 0, Position = UDim2.fromOffset(0, 0)})
        end
        btn.MouseButton1Click:Connect(function() Tab:Select() end)

        table.insert(Window.Tabs, Tab)
        Tab._render()
        if #Window.Tabs == 1 then Tab:Select() end
        return Tab
    end

    -- cria várias abas de uma vez: local Tabs = Window:AddTabs({"Main", "Settings"})  ->  Tabs.Main, Tabs.Settings
    function Window:AddTabs(names)
        local out = {}
        for _, n in ipairs(names) do out[n] = Window:AddTab(n) end
        return out
    end
    Window.Tab, Window.CreateTab, Window.MakeTab = Window.AddTab, Window.AddTab, Window.AddTab

    Library.Setters["__ui_tab"] = function(n)
        for _, t in ipairs(Window.Tabs) do if t.Name == n then t:Select() end end
    end

    Library.Window = Window
    return Window
end

function Library:Destroy()
    self.Alive = false
    for _, fn in ipairs(self.OnDestroy) do pcall(fn) end
    pcall(function() self:FlushAutoSave() end)
    for _, c in ipairs(self.Connections) do pcall(function() c:Disconnect() end) end
    self.Connections = {}
    pcall(function() gui:Destroy() end)
    _G.LopopUI = nil
end


function Library:AddTheme(name, t)
    Themes[name] = FinishTheme(t)
    table.insert(ThemeOrder, name)
end

function Library:Start()
    local restored = self:LoadAutoSave()
    self.Ready = true
    if not hasFS() then
        self:Notify({Title = "Auto Save", Content = "Seu executor não suporta arquivos; o autosave está indisponível.", Type = "Warning", Force = true})
    end
    task.delay(0.8, function()
        self:Notify({Title = "LopopUI", Content = restored and "Configurações restauradas do autosave." or ("Carregada! Abra/feche com " .. self.ToggleKey.Name .. "."), Type = "Success"})
    end)
    return restored
end

Library.Version = "2.0"
Library.Gui = gui
Library.Themes, Library.ThemeOrder = Themes, ThemeOrder
Library.CleanName, Library.HasFS = cleanName, hasFS
function Library:Connect(signal, fn) return Connect(signal, fn) end

_G.LopopUI = Library

return Library
