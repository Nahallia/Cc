local HttpService = game:GetService('HttpService')
local CoreGui = game:GetService('CoreGui')
local urls = {
    'https://raw.githubusercontent.com/Nahalliaa/CasualComas/refs/heads/main/P1.luau',
    'https://raw.githubusercontent.com/Nahallia/Cc/refs/heads/main/Part2.luau',
    'https://raw.githubusercontent.com/Nahalliaa/CasualComas/refs/heads/main/CarMods',
}

for _, url in ipairs(urls)do
    loadstring(game:HttpGet(url))()
end

task.spawn(function()
    task.wait(1)

    local function findRayfield()
        for _, gui in ipairs(CoreGui:GetChildren())do
            local rf = gui:FindFirstChild('Rayfield')

            if rf then
                return rf
            end
        end
    end
    local function apply()
        local rayfield = findRayfield()

        if not rayfield then
            return
        end

        local prompt = rayfield:FindFirstChild('Prompt')

        if not prompt then
            return
        end
        if prompt:IsA('Frame') or prompt:IsA('TextButton') or prompt:IsA('ImageButton') then
            prompt.BackgroundColor3 = Color3.fromRGB(58, 48, 68)
        end

        local title = prompt:FindFirstChild('Title')

        if title and title:IsA('TextLabel') then
            title.Text = 'Casual Comas'
            title.TextColor3 = Color3.fromRGB(240, 235, 230)
        end
    end

    apply()

    while task.wait(1.5) do
        apply()
    end
end)

local Env = getgenv().PL_Hub

if not Env then
    return warn('Load Part 1 First!')
end

local HttpService = Env.Services.HttpService
local ReplicatedStorage = Env.Services.ReplicatedStorage
local Players = Env.Services.Players
local LocalPlayer = Players.LocalPlayer
local RunService = Env.Services.RunService
local Workspace = game:GetService('Workspace')

if Env.cfg.autoarrest == nil then
    Env.cfg.autoarrest = false
end
if Env.cfg.punchaura == nil then
    Env.cfg.punchaura = false
end
if Env.cfg.ws_enabled == nil then
    Env.cfg.ws_enabled = false
end
if Env.cfg.walkspeed == nil then
    Env.cfg.walkspeed = 16
end
if Env.cfg.jp_enabled == nil then
    Env.cfg.jp_enabled = false
end
if Env.cfg.jumppower == nil then
    Env.cfg.jumppower = 50
end
if Env.cfg.noclip == nil then
    Env.cfg.noclip = false
end
if Env.cfg.shootarrested == nil then
    Env.cfg.shootarrested = false
end
if Env.cfg.autograb == nil then
    Env.cfg.autograb = false
end

local noclipConnection = nil

local function updateNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()

        noclipConnection = nil
    end
    if Env.cfg.noclip then
        noclipConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character

            if char then
                for _, part in pairs(char:GetDescendants())do
                    if part:IsA('BasePart') then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
end

task.spawn(function()
    pcall(function()
        local hook = newcclosure(function()
            return
        end)

        for _, obj in getgc(false)do
            if typeof(obj) == 'function' then
                local source = debug.info(obj, 's')

                if source and source:find('CharacterCollision') then
                    hookfunction(obj, hook)
                end
            end
        end
    end)
end)
task.spawn(function()
    while true do
        if Env.cfg.shootarrested then
            local rs = ReplicatedStorage
            local re = rs:FindFirstChild('Remotes') and rs.Remotes:FindFirstChild('ClientArrested')

            if re then
                for _, cn in pairs(getconnections(re.OnClientEvent))do
                    cn:Disable()
                end
            end
        end

        task.wait(1)
    end
end)

local grab_dist_sq = 144
local last_grab = 0
local giver_remote = ReplicatedStorage:WaitForChild('Remotes'):FindFirstChild('GiverPressed')
local grab_cache = {}
local cache_update_interval = 2
local last_cache_update = 0

local function updateGrabCache()
    grab_cache = {}

    for _, obj in pairs(Workspace:GetDescendants())do
        if obj:IsA('Model') and (obj.Name:lower():find('keycard') or obj.Name == 'M9') then
            local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA('BasePart', true)

            if part then
                local isOwned = false
                local anc = obj.Parent

                while anc and anc ~= Workspace do
                    if anc:FindFirstChild('Humanoid') or anc.Name == 'Backpack' then
                        isOwned = true

                        break
                    end

                    anc = anc.Parent
                end

                if not isOwned then
                    table.insert(grab_cache, {
                        model = obj,
                        part = part,
                    })
                end
            end
        end
    end
end

RunService.Heartbeat:Connect(function()
    local myChar = LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild('HumanoidRootPart')
    local myHum = myChar and myChar:FindFirstChild('Humanoid')

    if myHum and myHrp then
        if Env.cfg.ws_enabled then
            myHum.WalkSpeed = Env.cfg.walkspeed
        end
        if Env.cfg.jp_enabled then
            myHum.JumpPower = Env.cfg.jumppower
        end
    end
    if Env.cfg.autograb and myHrp and giver_remote then
        local now = tick()

        if now - last_cache_update > cache_update_interval then
            updateGrabCache()

            last_cache_update = now
        end
        if now - last_grab > 0.5 then
            for _, cached in ipairs(grab_cache)do
                if cached.model and cached.part and cached.part.Parent then
                    local distSq = (cached.part.Position - myHrp.Position).Magnitude ^ 2

                    if distSq <= grab_dist_sq then
                        last_grab = now

                        giver_remote:FireServer(cached.model)

                        break
                    end
                end
            end
        end
    end
    -- Auto Arrest Logic
    if Env.cfg.autoarrest and myHrp then
        local arrestRemote = ReplicatedStorage:FindFirstChild('Remotes') and ReplicatedStorage.Remotes:FindFirstChild('ArrestPlayer')
        local ARREST_RANGE = 10
        
        if arrestRemote then
            for _, target in ipairs(Players:GetPlayers())do
                if target == LocalPlayer then continue end
                
                local char = target.Character
                if not char then continue end
                
                local hrp = char:FindFirstChild('HumanoidRootPart')
                local hum = char:FindFirstChild('Humanoid')
                
                -- Checks: Part existence, Health, and Distance
                if hrp and hum and hum.Health > 0 then
                    if (myHrp.Position - hrp.Position).Magnitude <= ARREST_RANGE then
                        task.spawn(function()
                            pcall(function()
                                arrestRemote:InvokeServer(target)
                            end)
                        end)
                    end
                end
            end
        end
    end
    
    -- Punch Aura Logic
    if Env.cfg.punchaura and myHrp then
        for _, target in ipairs(Players:GetPlayers())do
            if target ~= LocalPlayer and target.Character and target.Character:FindFirstChild('HumanoidRootPart') then
                local targetHrp = target.Character.HumanoidRootPart
                local dist = (targetHrp.Position - myHrp.Position).Magnitude

                if dist <= 25 then
                    if target.Team ~= LocalPlayer.Team then
                        if not target.Character:FindFirstChild('ForceField') then
                            ReplicatedStorage.meleeEvent:FireServer(target)
                        end
                    end
                end
            end
        end
    end
end)

local configFolder = 'CasualComasConfigs'

local function serializeColor3(color)
    return {
        R = color.R,
        G = color.G,
        B = color.B,
    }
end
local function deserializeColor3(tbl)
    if tbl and tbl.R and tbl.G and tbl.B then
        return Color3.new(tbl.R, tbl.G, tbl.B)
    end

    return Color3.new(1, 1, 1)
end
local function serializeConfig()
    local data = {}

    for key, value in pairs(Env.cfg)do
        if typeof(value) == 'Color3' then
            data[key] = {
                type = 'Color3',
                value = serializeColor3(value),
            }
        elseif typeof(value) == 'EnumItem' then
            data[key] = {
                type = 'EnumItem',
                value = tostring(value),
            }
        elseif typeof(value) == 'table' then
            data[key] = {
                type = 'table',
                value = value,
            }
        else
            data[key] = {
                type = typeof(value),
                value = value,
            }
        end
    end

    return HttpService:JSONEncode(data)
end
local function deserializeConfig(jsonString)
    local success, data = pcall(function()
        return HttpService:JSONDecode(jsonString)
    end)

    if not success then
        return nil
    end

    local result = {}

    for key, entry in pairs(data)do
        if entry.type == 'Color3' then
            result[key] = deserializeColor3(entry.value)
        elseif entry.type == 'EnumItem' then
            local enumPath = entry.value:match('Enum%.(.+)')

            if enumPath then
                local parts = enumPath:split('.')

                if #parts == 2 then
                    local enumType = Enum[parts[1] ]

                    if enumType then
                        result[key] = enumType[parts[2] ]
                    end
                end
            end
        elseif entry.type == 'table' then
            result[key] = entry.value
        else
            result[key] = entry.value
        end
    end

    return result
end
local function saveConfig(name)
    if not isfolder then
        return false
    end
    if not isfolder(configFolder) then
        makefolder(configFolder)
    end

    local path = configFolder .. '/' .. name .. '.json'

    writefile(path, serializeConfig())

    return true
end
local function loadConfig(name)
    if not isfolder or not isfile then
        return false
    end

    local path = configFolder .. '/' .. name .. '.json'

    if not isfile(path) then
        return false
    end

    local data = readfile(path)
    local loaded = deserializeConfig(data)

    if not loaded then
        return false
    end

    for key, value in pairs(loaded)do
        if Env.cfg[key] ~= nil then
            Env.cfg[key] = value
        end
    end

    if Env.updateEsp then
        Env.updateEsp()
    end
    if Env.updateC4Esp then
        Env.updateC4Esp()
    end

    updateNoclip()

    return true
end

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local customTheme = {
    TextColor = Color3.fromRGB(245, 240, 255),
    PlaceholderColor = Color3.fromRGB(135, 125, 155),
    Background = Color3.fromRGB(10, 8, 18),
    Topbar = Color3.fromRGB(16, 13, 28),
    Shadow = Color3.fromRGB(4, 2, 8),
    NotificationBackground = Color3.fromRGB(18, 15, 30),
    NotificationActionsBackground = Color3.fromRGB(26, 22, 40),
    TabBackground = Color3.fromRGB(22, 18, 35),
    TabStroke = Color3.fromRGB(55, 45, 75),
    TabBackgroundSelected = Color3.fromRGB(255, 145, 175),
    TabTextColor = Color3.fromRGB(245, 240, 255),
    SelectedTabTextColor = Color3.fromRGB(10, 8, 18),
    ElementBackground = Color3.fromRGB(18, 15, 30),
    ElementBackgroundHover = Color3.fromRGB(30, 25, 45),
    SecondaryElementBackground = Color3.fromRGB(14, 11, 24),
    ElementStroke = Color3.fromRGB(65, 55, 90),
    SecondaryElementStroke = Color3.fromRGB(50, 40, 70),
    SliderBackground = Color3.fromRGB(28, 24, 42),
    SliderProgress = Color3.fromRGB(255, 145, 175),
    SliderStroke = Color3.fromRGB(75, 65, 100),
    ToggleBackground = Color3.fromRGB(18, 15, 30),
    ToggleEnabled = Color3.fromRGB(255, 145, 175),
    ToggleDisabled = Color3.fromRGB(55, 45, 70),
    ToggleEnabledStroke = Color3.fromRGB(255, 165, 195),
    ToggleDisabledStroke = Color3.fromRGB(40, 30, 55),
    ToggleEnabledOuterStroke = Color3.fromRGB(75, 65, 95),
    ToggleDisabledOuterStroke = Color3.fromRGB(32, 22, 48),
    DropdownSelected = Color3.fromRGB(32, 27, 48),
    DropdownUnselected = Color3.fromRGB(18, 15, 30),
    InputBackground = Color3.fromRGB(18, 15, 30),
}
local Window = Rayfield:CreateWindow({
    Name = 'Casual Comas',
    Icon = 79844328689721,
    LoadingTitle = 'Casual Comas Hub',
    LoadingSubtitle = 'v' .. Env.Version,
    Theme = customTheme,
    ConfigurationSaving = {Enabled = false},
    KeySystem = false,
})
local CombatTab = Window:CreateTab('Combat', 'crosshair')
local VisualsTab = Window:CreateTab('Visuals', 'eye')
local MovementTab = Window:CreateTab('Movement', 'wind')
local VehicleTab = Window:CreateTab('Vehicle', 'car')
local UtilityTab = Window:CreateTab('Utility', 'box')
local ConfigTab = Window:CreateTab('Config', 'settings')

CombatTab:CreateSection('Silent Aim')
CombatTab:CreateToggle({
    Name = 'Enable Silent Aim',
    CurrentValue = Env.cfg.enabled,
    Callback = function(v)
        Env.cfg.enabled = v
    end,
})
CombatTab:CreateSlider({
    Name = 'FOV Radius',
    Range = {10, 500},
    Increment = 1,
    Suffix = 'px',
    CurrentValue = Env.cfg.fov,
    Callback = function(v)
        Env.cfg.fov = v
    end,
})
CombatTab:CreateToggle({
    Name = 'Show FOV Circle',
    CurrentValue = Env.cfg.showfov,
    Callback = function(v)
        Env.cfg.showfov = v
    end,
})
CombatTab:CreateSlider({
    Name = 'Hit Chance',
    Range = {0, 100},
    Increment = 1,
    Suffix = '%',
    CurrentValue = Env.cfg.hitchance,
    Callback = function(v)
        Env.cfg.hitchance = v
    end,
})
CombatTab:CreateDropdown({
    Name = 'Target Part',
    Options = Env.cfg.partslist,
    CurrentOption = {
        Env.cfg.aimpart,
    },
    MultipleOptions = false,
    Callback = function(o)
        Env.cfg.aimpart = o[1]
    end,
})
CombatTab:CreateToggle({
    Name = 'Random Parts',
    CurrentValue = Env.cfg.randomparts,
    Callback = function(v)
        Env.cfg.randomparts = v
    end,
})
CombatTab:CreateSection('Targeting')
CombatTab:CreateToggle({
    Name = 'Team Check',
    CurrentValue = Env.cfg.teamcheck,
    Callback = function(v)
        Env.cfg.teamcheck = v
    end,
})
CombatTab:CreateToggle({
    Name = 'Wall Check',
    CurrentValue = Env.cfg.wallcheck,
    Callback = function(v)
        Env.cfg.wallcheck = v
    end,
})
CombatTab:CreateToggle({
    Name = 'Death Check',
    CurrentValue = Env.cfg.deathcheck,
    Callback = function(v)
        Env.cfg.deathcheck = v
    end,
})
CombatTab:CreateToggle({
    Name = 'ForceField Check',
    CurrentValue = Env.cfg.ffcheck,
    Callback = function(v)
        Env.cfg.ffcheck = v
    end,
})
CombatTab:CreateToggle({
    Name = 'Vehicle Check',
    CurrentValue = Env.cfg.vehiclecheck,
    Callback = function(v)
        Env.cfg.vehiclecheck = v
    end,
})
CombatTab:CreateToggle({
    Name = 'Hostile Check (Guards)',
    CurrentValue = Env.cfg.hostilecheck,
    Callback = function(v)
        Env.cfg.hostilecheck = v
    end,
})
CombatTab:CreateToggle({
    Name = 'Trespass Check (Guards)',
    CurrentValue = Env.cfg.trespasscheck,
    Callback = function(v)
        Env.cfg.trespasscheck = v
    end,
})
CombatTab:CreateSection('Automation')
CombatTab:CreateToggle({
    Name = 'Auto Shoot',
    CurrentValue = Env.cfg.autoshoot,
    Callback = function(v)
        Env.cfg.autoshoot = v
    end,
})
CombatTab:CreateSlider({
    Name = 'Shot Delay',
    Range = {0.05, 0.5},
    Increment = 0.01,
    Suffix = 's',
    CurrentValue = Env.cfg.autoshootdelay,
    Callback = function(v)
        Env.cfg.autoshootdelay = v
    end,
})
CombatTab:CreateSlider({
    Name = 'Start Delay',
    Range = {0, 1},
    Increment = 0.05,
    Suffix = 's',
    CurrentValue = Env.cfg.autoshootstartdelay,
    Callback = function(v)
        Env.cfg.autoshootstartdelay = v
    end,
})
CombatTab:CreateToggle({
    Name = 'Auto Arrest',
    CurrentValue = Env.cfg.autoarrest,
    Callback = function(v)
        Env.cfg.autoarrest = v
    end,
})
CombatTab:CreateToggle({
    Name = 'Punch Aura',
    CurrentValue = Env.cfg.punchaura,
    Callback = function(v)
        Env.cfg.punchaura = v
    end,
})
CombatTab:CreateSection('Shield Breaker')
CombatTab:CreateToggle({
    Name = 'Enable Shield Breaker',
    CurrentValue = Env.cfg.shieldbreaker,
    Callback = function(v)
        Env.cfg.shieldbreaker = v
    end,
})
CombatTab:CreateSlider({
    Name = 'Head Shot Chance',
    Range = {0, 100},
    Increment = 1,
    Suffix = '%',
    CurrentValue = Env.cfg.shieldheadchance,
    Callback = function(v)
        Env.cfg.shieldheadchance = v
    end,
})
VisualsTab:CreateSection('Player ESP')
VisualsTab:CreateToggle({
    Name = 'Enable ESP',
    CurrentValue = Env.cfg.esp,
    Callback = function(v)
        Env.cfg.esp = v

        Env.updateEsp()
    end,
})
VisualsTab:CreateToggle({
    Name = 'Team Check',
    CurrentValue = Env.cfg.espteamcheck,
    Callback = function(v)
        Env.cfg.espteamcheck = v

        Env.updateEsp()
    end,
})
VisualsTab:CreateToggle({
    Name = 'Use Team Colors',
    CurrentValue = Env.cfg.espuseteamcolors,
    Callback = function(v)
        Env.cfg.espuseteamcolors = v

        Env.updateEsp()
    end,
})
VisualsTab:CreateSlider({
    Name = 'Max Distance',
    Range = {50, 1000},
    Increment = 10,
    Suffix = 'm',
    CurrentValue = Env.cfg.espmaxdist,
    Callback = function(v)
        Env.cfg.espmaxdist = v

        Env.updateEsp()
    end,
})
VisualsTab:CreateSection('Team Colors')
VisualsTab:CreateColorPicker({
    Name = 'Guards',
    Color = Env.cfg.espguards,
    Callback = function(v)
        Env.cfg.espguards = v

        Env.updateEsp()
    end,
})
VisualsTab:CreateColorPicker({
    Name = 'Inmates',
    Color = Env.cfg.espinmates,
    Callback = function(v)
        Env.cfg.espinmates = v

        Env.updateEsp()
    end,
})
VisualsTab:CreateColorPicker({
    Name = 'Criminals',
    Color = Env.cfg.espcriminals,
    Callback = function(v)
        Env.cfg.espcriminals = v

        Env.updateEsp()
    end,
})
VisualsTab:CreateSection('C4 ESP')
VisualsTab:CreateToggle({
    Name = 'Enable C4 ESP',
    CurrentValue = Env.cfg.c4esp,
    Callback = function(v)
        Env.cfg.c4esp = v

        Env.updateC4Esp()
    end,
})
VisualsTab:CreateColorPicker({
    Name = 'C4 Color',
    Color = Env.cfg.c4espcolor,
    Callback = function(v)
        Env.cfg.c4espcolor = v

        Env.updateC4Esp()
    end,
})

VisualsTab:CreateSection("Camera")

VisualsTab:CreateSlider({
    Name = "Camera FOV",
    Range = { 70, 120 },
    Increment = 1,
    CurrentValue = Workspace.CurrentCamera.FieldOfView,
    Callback = function(v)
        Workspace.CurrentCamera.FieldOfView = v
    end
})

local VisualsSection = VisualsTab:CreateSection("Visual Features")

local TracerToggle = VisualsTab:CreateToggle({
    Name = "Enable Tracers",
    CurrentValue = Env.cfg.tracer.enabled,
    Flag = "TracerToggle",
    Callback = function(Value)
        Env.cfg.tracer.enabled = Value
    end,
})

local TracerColor = VisualsTab:CreateColorPicker({
    Name = "Tracer Color",
    Color = Env.cfg.tracer.color,
    Flag = "TracerColor",
    Callback = function(Value)
        Env.cfg.tracer.color = Value
    end
})

local TracerThickness = VisualsTab:CreateSlider({
    Name = "Tracer Thickness",
    Range = {0.05, 0.5},
    Increment = 0.01,
    CurrentValue = Env.cfg.tracer.thickness,
    Flag = "TracerThickness",
    Callback = function(Value)
        Env.cfg.tracer.thickness = Value
    end,
})

local TracerLifetime = VisualsTab:CreateSlider({
    Name = "Tracer Lifetime",
    Range = {0.1, 1},
    Increment = 0.05,
    CurrentValue = Env.cfg.tracer.lifetime,
    Flag = "TracerLifetime",
    Callback = function(Value)
        Env.cfg.tracer.lifetime = Value
    end,
})

local TracerFade = VisualsTab:CreateSlider({
    Name = "Tracer Fade Duration",
    Range = {0.1, 1},
    Increment = 0.05,
    CurrentValue = Env.cfg.tracer.fade,
    Flag = "TracerFade",
    Callback = function(Value)
        Env.cfg.tracer.fade = Value
    end,
})

local HitSoundSection = VisualsTab:CreateSection("Hit Sound")

local HitSoundToggle = VisualsTab:CreateToggle({
    Name = "Enable Hit Sound",
    CurrentValue = Env.cfg.hitsound.enabled,
    Flag = "HitSoundToggle",
    Callback = function(Value)
        Env.cfg.hitsound.enabled = Value
    end,
})

local HitSoundVolume = VisualsTab:CreateSlider({
    Name = "Hit Sound Volume",
    Range = {0, 5},
    Increment = 0.1,
    CurrentValue = Env.cfg.hitsound.volume,
    Flag = "HitSoundVolume",
    Callback = function(Value)
        Env.cfg.hitsound.volume = Value
        HitSound.Volume = Value
    end,
})

local NormalHitSound = VisualsTab:CreateInput({
    Name = "Normal Hit Sound ID",
    PlaceholderText = "Asset ID",
    RemoveTextAfterFocusLost = false,
    CurrentValue = tostring(Env.cfg.hitsound.normal),
    Flag = "NormalHitSound",
    Callback = function(Value)
        local id = tonumber(Value)
        if id then
            Env.cfg.hitsound.normal = id
        end
    end,
})

local HeadshotSound = VisualsTab:CreateInput({
    Name = "Headshot Sound ID",
    PlaceholderText = "Asset ID",
    RemoveTextAfterFocusLost = false,
    CurrentValue = tostring(Env.cfg.hitsound.headshot),
    Flag = "HeadshotSound",
    Callback = function(Value)
        local id = tonumber(Value)
        if id then
            Env.cfg.hitsound.headshot = id
        end
    end,
})

local HitmarkerSection = VisualsTab:CreateSection("Hitmarker")

local HitmarkerToggle = VisualsTab:CreateToggle({
    Name = "Enable Hitmarker",
    CurrentValue = Env.cfg.hitmarker.enabled,
    Flag = "HitmarkerToggle",
    Callback = function(Value)
        Env.cfg.hitmarker.enabled = Value
    end,
})

local HitmarkerThickness = VisualsTab:CreateSlider({
    Name = "Hitmarker Thickness",
    Range = {1, 5},
    Increment = 0.5,
    CurrentValue = Env.cfg.hitmarker.thickness,
    Flag = "HitmarkerThickness",
    Callback = function(Value)
        Env.cfg.hitmarker.thickness = Value
    end,
})

local HitmarkerLength = VisualsTab:CreateSlider({
    Name = "Hitmarker Length",
    Range = {3, 15},
    Increment = 1,
    CurrentValue = Env.cfg.hitmarker.length,
    Flag = "HitmarkerLength",
    Callback = function(Value)
        Env.cfg.hitmarker.length = Value
    end,
})

local HitmarkerGap = VisualsTab:CreateSlider({
    Name = "Hitmarker Gap",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = Env.cfg.hitmarker.gap,
    Flag = "HitmarkerGap",
    Callback = function(Value)
        Env.cfg.hitmarker.gap = Value
    end,
})

local CrosshairSection = VisualsTab:CreateSection("Crosshair")

local CustomCrosshair = VisualsTab:CreateInput({
    Name = "Custom Crosshair Image ID",
    PlaceholderText = "Asset ID (leave empty for default)",
    RemoveTextAfterFocusLost = false,
    CurrentValue = Env.cfg.crosshair.customImage,
    Flag = "CustomCrosshair",
    Callback = function(Value)
        Env.cfg.crosshair.customImage = Value
        updateCrosshair()
    end,
})

VisualsTab:CreateSection("World Aesthetics")

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local timeLoop
local desiredTime = 14
local freezeTime = false

VisualsTab:CreateToggle({
    Name = "Freeze Time (Bypass Game Cycle)",
    CurrentValue = false,
    Callback = function(v)
        freezeTime = v

        if v then
            timeLoop = RunService.RenderStepped:Connect(function()
                if freezeTime then
                    Lighting.ClockTime = desiredTime
                end
            end)
        else
            if timeLoop then
                timeLoop:Disconnect()
                timeLoop = nil
            end
        end
    end
})

VisualsTab:CreateSlider({
    Name = "Time of Day",
    Range = { 0, 24 },
    Increment = 0.5,
    CurrentValue = desiredTime,
    Callback = function(v)
        desiredTime = v
        if not freezeTime then
            Lighting.ClockTime = v
        end
    end
})

local ColorCorr =
    Lighting:FindFirstChild("CasualWorldTint")
    or Instance.new("ColorCorrectionEffect")

ColorCorr.Name = "CasualWorldTint"
ColorCorr.Parent = Lighting
ColorCorr.Enabled = false

VisualsTab:CreateToggle({
    Name = "Enable World Tint",
    CurrentValue = false,
    Callback = function(v)
        ColorCorr.Enabled = v
    end
})

VisualsTab:CreateColorPicker({
    Name = "Tint Color",
    Color = Color3.fromRGB(255, 255, 255),
    Callback = function(v)
        ColorCorr.TintColor = v
    end
})

VisualsTab:CreateSection("Lighting & Skybox")

VisualsTab:CreateLabel("Tip: Increase Ambient to see Sky at Night")

VisualsTab:CreateColorPicker({
    Name = "Ambient Color (Brightness)",
    Color = Lighting.Ambient,
    Callback = function(v)
        Lighting.Ambient = v
        Lighting.OutdoorAmbient = v
    end
})

local defaultSky = Lighting:FindFirstChildOfClass("Sky")

if not defaultSky then
    defaultSky = Instance.new("Sky")
    defaultSky.Name = "DefaultSky"
    defaultSky.Parent = Lighting
end

local origSky = {
    Bk = defaultSky.SkyboxBk,
    Dn = defaultSky.SkyboxDn,
    Ft = defaultSky.SkyboxFt,
    Lf = defaultSky.SkyboxLf,
    Rt = defaultSky.SkyboxRt,
    Up = defaultSky.SkyboxUp,
    Sun = defaultSky.SunTextureId,
    Moon = defaultSky.MoonTextureId,
    Stars = defaultSky.StarCount
}

local skyList = {
    ["Default"] = origSky,

    ["Purple Galaxy"] = {
        Bk = "http://www.roblox.com/asset/?id=159454299",
        Dn = "http://www.roblox.com/asset/?id=159454296",
        Ft = "http://www.roblox.com/asset/?id=159454293",
        Lf = "http://www.roblox.com/asset/?id=159454286",
        Rt = "http://www.roblox.com/asset/?id=159454300",
        Up = "http://www.roblox.com/asset/?id=159454288",
        Sun = "",
        Moon = "",
        Stars = 3000
    },

    ["Realism Sky"] = {
        Bk = "rbxassetid://2178907873",
        Dn = "rbxassetid://2178907663",
        Ft = "rbxassetid://2178906994",
        Lf = "rbxassetid://2178907310",
        Rt = "rbxassetid://2178906665",
        Up = "rbxassetid://2178907997",
        Sun = "",
        Moon = "",
        Stars = 0
    },

    ["Red Moon"] = {
        Bk = "rbxassetid://482655387",
        Dn = "rbxassetid://482655387",
        Ft = "rbxassetid://482655387",
        Lf = "rbxassetid://482655387",
        Rt = "rbxassetid://482655387",
        Up = "rbxassetid://482655387",
        Sun = "",
        Moon = "",
        Stars = 3000
    }
}

VisualsTab:CreateDropdown({
    Name = "Skybox Theme",
    Options = { "Default", "Purple Galaxy", "Realism Sky", "Red Moon" },
    CurrentOption = { "Default" },
    MultipleOptions = false,
    Callback = function(option)
        local data = skyList[option[1]]
        if not data then return end

        local sky = Lighting:FindFirstChildOfClass("Sky")
        if not sky then
            sky = Instance.new("Sky")
            sky.Parent = Lighting
        end

        sky.SkyboxBk = data.Bk
        sky.SkyboxDn = data.Dn
        sky.SkyboxFt = data.Ft
        sky.SkyboxLf = data.Lf
        sky.SkyboxRt = data.Rt
        sky.SkyboxUp = data.Up

        if data.Sun ~= nil then sky.SunTextureId = data.Sun end
        if data.Moon ~= nil then sky.MoonTextureId = data.Moon end
        if data.Stars ~= nil then sky.StarCount = data.Stars end
    end
})

VisualsTab:CreateSlider({
    Name = "Fog Distance",
    Range = { 0, 10000 },
    Increment = 10,
    CurrentValue = Lighting.FogEnd,
    Callback = function(v)
        Lighting.FogEnd = v
    end
})

MovementTab:CreateSection('Speed')
MovementTab:CreateToggle({
    Name = 'Enable WalkSpeed',
    CurrentValue = Env.cfg.ws_enabled,
    Callback = function(v)
        Env.cfg.ws_enabled = v
    end,
})
MovementTab:CreateSlider({
    Name = 'WalkSpeed',
    Range = {16, 200},
    Increment = 1,
    CurrentValue = Env.cfg.walkspeed,
    Callback = function(v)
        Env.cfg.walkspeed = v
    end,
})
MovementTab:CreateToggle({
    Name = 'Enable JumpPower',
    CurrentValue = Env.cfg.jp_enabled,
    Callback = function(v)
        Env.cfg.jp_enabled = v
    end,
})
MovementTab:CreateSlider({
    Name = 'JumpPower',
    Range = {50, 500},
    Increment = 1,
    CurrentValue = Env.cfg.jumppower,
    Callback = function(v)
        Env.cfg.jumppower = v
    end,
})
MovementTab:CreateSection('Physics')
MovementTab:CreateToggle({
    Name = 'Noclip',
    CurrentValue = Env.cfg.noclip,
    Callback = function(v)
        Env.cfg.noclip = v

        updateNoclip()
    end,
})

MovementTab:CreateSection('Teleports')

local function tp(pos)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos)
    end
end

MovementTab:CreateButton({
    Name = 'Yard',
    Callback = function()
        tp(Vector3.new(780, 98, 2470))
    end,
})
MovementTab:CreateButton({
    Name = 'Prison Interior',
    Callback = function()
        tp(Vector3.new(913, 100, 2388))
    end,
})
MovementTab:CreateButton({
    Name = 'Armory',
    Callback = function()
        tp(Vector3.new(831, 100, 2233))
    end,
})
MovementTab:CreateButton({
    Name = 'Cafeteria',
    Callback = function()
        tp(Vector3.new(905, 100, 2316))
    end,
})
MovementTab:CreateButton({
    Name = 'Criminal Base',
    Callback = function()
        tp(Vector3.new(-931, 94, 2063))
    end,
})
MovementTab:CreateButton({
    Name = 'Instant Escape',
    Callback = function()
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChild('HumanoidRootPart')

        if h then
            local containers = Workspace:FindFirstChild('Shippingcontainers')

            if containers then
                pcall(function()
                    h.CFrame = containers:GetChildren()[6]:GetChildren()[2].CFrame
                end)
            else
                h.CFrame = CFrame.new(-931, 94, 2063)
            end

            task.wait(0.5)

            local hum = c:FindFirstChild('Humanoid')

            if hum then
                hum.Health = 0
            end
        end
    end,
})

VehicleTab:CreateSection('Vehicle Modifications')
VehicleTab:CreateToggle({
    Name = 'Enable Vehicle Mods',
    CurrentValue = Env.cfg.vehicle.enabled,
    Callback = function(v)
        Env.cfg.vehicle.enabled = v

        if v then
            getgenv().startVehicleMonitoring()
        else
            getgenv().stopVehicleMonitoring()
        end
    end,
})
VehicleTab:CreateSlider({
    Name = 'Max Speed',
    Range = {10, 200},
    Increment = 5,
    CurrentValue = Env.cfg.vehicle.maxSpeed,
    Callback = function(v)
        Env.cfg.vehicle.maxSpeed = v
    end,
})
VehicleTab:CreateSlider({
    Name = 'Turn Speed',
    Range = {0.5, 5},
    Increment = 0.1,
    CurrentValue = Env.cfg.vehicle.turnSpeed,
    Callback = function(v)
        Env.cfg.vehicle.turnSpeed = v
    end,
})
VehicleTab:CreateSlider({
    Name = 'Torque',
    Range = {10, 200},
    Increment = 5,
    CurrentValue = Env.cfg.vehicle.torque,
    Callback = function(v)
        Env.cfg.vehicle.torque = v
    end,
})
VehicleTab:CreateSlider({
    Name = 'Steer Responsiveness',
    Range = {0.1, 2},
    Increment = 0.1,
    CurrentValue = Env.cfg.vehicle.steerFloat,
    Callback = function(v)
        Env.cfg.vehicle.steerFloat = v
    end,
})
VehicleTab:CreateSection('Vehicle Flight')

local RunService = game:GetService('RunService')
local Players = game:GetService('Players')
local Workspace = game:GetService('Workspace')
local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local FlyEnabled = false
local FlySpeed = 150

VehicleTab:CreateToggle({
    Name = 'Enable Vehicle Fly',
    CurrentValue = false,
    Flag = 'FlyToggle',
    Callback = function(Value)
        FlyEnabled = Value

        if not FlyEnabled then
            local char = Player.Character

            if char then
                local hum = char:FindFirstChild('Humanoid')

                if hum and hum.SeatPart then
                    local s = hum.SeatPart

                    if s:FindFirstChild('FlyVelocity') then
                        s.FlyVelocity:Destroy()
                    end
                    if s:FindFirstChild('FlyGyro') then
                        s.FlyGyro:Destroy()
                    end
                end
            end
        end
    end,
})
VehicleTab:CreateSlider({
    Name = 'Fly Speed',
    Range = {0, 500},
    Increment = 10,
    Suffix = 'Speed',
    CurrentValue = 150,
    Flag = 'SpeedSlider',
    Callback = function(Value)
        FlySpeed = Value
    end,
})

local function setupVehicle(seat)
    local bv = seat:FindFirstChild('FlyVelocity') or Instance.new('BodyVelocity')

    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = Vector3.zero
    bv.Name = 'FlyVelocity'
    bv.Parent = seat

    local bg = seat:FindFirstChild('FlyGyro') or Instance.new('BodyGyro')

    bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bg.P = 3000
    bg.D = 100
    bg.CFrame = seat.CFrame
    bg.Name = 'FlyGyro'
    bg.Parent = seat

    return bv, bg
end

RunService.Heartbeat:Connect(function()
    if not FlyEnabled then
        return
    end

    local character = Player.Character

    if not character then
        return
    end

    local humanoid = character:FindFirstChild('Humanoid')

    if not humanoid then
        return
    end

    local seat = humanoid.SeatPart

    if seat and seat:IsA('VehicleSeat') then
        if Camera.CameraSubject ~= humanoid then
            Camera.CameraSubject = humanoid
        end

        seat.AssemblyLinearVelocity = Vector3.zero

        local bv, bg = setupVehicle(seat)
        local throttle = seat.Throttle
        local steer = seat.Steer

        if math.abs(throttle) > 0 then
            bv.Velocity = Camera.CFrame.LookVector * (throttle * FlySpeed)
            bg.CFrame = Camera.CFrame * CFrame.Angles(0, 0, -steer * 0.5)
        else
            bv.Velocity = Vector3.zero
            bg.CFrame = seat.CFrame
        end
    end
end)
UtilityTab:CreateSection('Bypass')
UtilityTab:CreateToggle({
    Name = 'Walk While Arrested',
    CurrentValue = Env.cfg.shootarrested,
    Callback = function(v)
        Env.cfg.shootarrested = v
    end,
})
UtilityTab:CreateSection('Item Pickup')
UtilityTab:CreateToggle({
    Name = 'Auto Grab Items',
    CurrentValue = Env.cfg.autograb,
    Callback = function(v)
        Env.cfg.autograb = v
    end,
})

UtilityTab:CreateSection('Server')
UtilityTab:CreateButton({
    Name = "Rejoin",
    Callback = function()
        local Players = game:GetService("Players")
        local TeleportService = game:GetService("TeleportService")

        local player = Players.LocalPlayer

        if queue_on_teleport then
            queue_on_teleport([[loadstring(game:HttpGet("https://raw.githubusercontent.com/Nahallia/Cc/refs/heads/main/P3.luau"))()]])
        end

        TeleportService:TeleportToPlaceInstance(
            game.PlaceId,
            game.JobId,
            player
        )
    end,
})

UtilityTab:CreateToggle({
    Name = "Auto Rejoin (IsBadGuard)",
    CurrentValue = false,
    Flag = "AutoRejoinBadGuard",
    Callback = function(state)
        local Players = game:GetService("Players")
        local TeleportService = game:GetService("TeleportService")

        local player = Players.LocalPlayer
        local placeId = game.PlaceId
        local jobId = game.JobId

        if not getgenv().BadGuardConnection then
            getgenv().BadGuardConnection = nil
        end

        local function rejoin()
            if queue_on_teleport then
                queue_on_teleport([[loadstring(game:HttpGet("https://raw.githubusercontent.com/Nahallia/Cc/refs/heads/main/P3.luau"))()]])
            end
            TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
        end

        if state then
            if player:GetAttribute("IsBadGuard") == true then
                rejoin()
                return
            end

            getgenv().BadGuardConnection =
                player:GetAttributeChangedSignal("IsBadGuard"):Connect(function()
                    if player:GetAttribute("IsBadGuard") == true then
                        rejoin()
                    end
                end)
        else
            if getgenv().BadGuardConnection then
                getgenv().BadGuardConnection:Disconnect()
                getgenv().BadGuardConnection = nil
            end
        end
    end,
})

UtilityTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        local Players = game:GetService("Players")
        local TeleportService = game:GetService("TeleportService")

        local player = Players.LocalPlayer

        if queue_on_teleport then
            queue_on_teleport([[loadstring(game:HttpGet("https://raw.githubusercontent.com/Nahallia/Cc/refs/heads/main/P3.luau"))()]])
        end

        TeleportService:Teleport(game.PlaceId, player)
    end,
})
ConfigTab:CreateSection('Configuration Manager')

local configNameInput = ''

ConfigTab:CreateInput({
    Name = 'Config Name',
    PlaceholderText = 'Enter config name...',
    RemoveTextAfterFocusLost = false,
    Callback = function(t)
        configNameInput = t
    end,
})
ConfigTab:CreateButton({
    Name = 'Save Config',
    Callback = function()
        if configNameInput == '' then
            Rayfield:Notify({
                Title = 'Config',
                Content = 'Please enter a config name!',
                Duration = 3,
            })

            return
        end
        if saveConfig(configNameInput) then
            Rayfield:Notify({
                Title = 'Config Saved',
                Content = 'Saved: ' .. configNameInput,
                Duration = 3,
            })
        else
            Rayfield:Notify({
                Title = 'Config Error',
                Content = 'Failed to save config!',
                Duration = 3,
            })
        end
    end,
})
ConfigTab:CreateButton({
    Name = 'Load Config',
    Callback = function()
        if configNameInput == '' then
            Rayfield:Notify({
                Title = 'Config',
                Content = 'Please enter a config name!',
                Duration = 3,
            })

            return
        end
        if loadConfig(configNameInput) then
            Rayfield:Notify({
                Title = 'Config Loaded',
                Content = 'Loaded: ' .. configNameInput,
                Duration = 3,
            })
        else
            Rayfield:Notify({
                Title = 'Config Error',
                Content = 'Config not found!',
                Duration = 3,
            })
        end
    end,
})
ConfigTab:CreateSection('Reset')
ConfigTab:CreateButton({
    Name = 'Reset to Defaults',
    Callback = function()
        Env.cfg.enabled = true
        Env.cfg.teamcheck = false
        Env.cfg.esp = false
        Env.cfg.autoarrest = false
        Env.cfg.punchaura = false
        Env.cfg.noclip = false
        Env.cfg.shootarrested = false
        Env.cfg.autograb = false
        Env.cfg.ws_enabled = false
        Env.cfg.jp_enabled = false

        updateNoclip()
        Env.updateEsp()
        Rayfield:Notify({
            Title = 'Reset Complete',
            Content = 'All settings restored to default',


            Duration = 3,
        })
    end,
})
Rayfield:Notify({
    Title = 'Welcome!',
    Content = 'Casual Comas v' .. Env.Version,
    Duration = 5,
})
