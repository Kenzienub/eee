---@diagnostic disable: undefined-global, lowercase-global, unused-function, unused-local, empty-block, unbalanced-assignments, deprecated, undefined-field, code-after-break, redundant-parameter, inject-field

repeat task.wait() until game:IsLoaded() task.wait()

local Players = game:GetService("Players") or game:WaitForChild("Players", 9e9);
local LocalPlayer = Players.LocalPlayer or Players:FindFirstChild("LocalPlayer", 9e9);
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character.HumanoidRootPart or Character:WaitForChild("HumanoidRootPart", 9e9);
local Humanoid = Character.Humanoid or Character:WaitForChild("Humanoid", 9e9);
local Backpack = LocalPlayer.Backpack or LocalPlayer:WaitForChild("Backpack", 9e9);

local Workspace = game:GetService("Workspace");
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local Camera = Workspace.Camera

local RobberyState = ReplicatedStorage.RobberyState

local teleport = loadstring(game:HttpGet("https://raw.githubusercontent.com/Kenzienub/real/refs/heads/main/main.lua"))()

local dependencies = {
    variables = {
        ["AirDrop"] = true,
        ["Rob Mansion"] = true,
        ["Auto Open Safe"] = false
    },

    modules = {
        Vehicle = require(ReplicatedStorage.Vehicle.VehicleUtils),
        TeamChooseUI = require(ReplicatedStorage.TeamSelect.TeamChooseUI),
        SidebarUI = require(ReplicatedStorage.Game.SidebarUI),
        DefaultActions = require(ReplicatedStorage.Game.DefaultActions),
        ItemSystem = require(ReplicatedStorage.Game.ItemSystem.ItemSystem),
        GunItem = require(ReplicatedStorage.Game.Item.Gun),
        PlayerUtils = require(ReplicatedStorage.Game.PlayerUtils),
        Paraglide = require(ReplicatedStorage.Game.Paraglide),
        CharUtils = require(ReplicatedStorage.Game.CharacterUtil),
        Notification = require(ReplicatedStorage.Game.Notification),
        PuzzleFlow = require(ReplicatedStorage.Game.Robbery.PuzzleFlow),
        Heli = require(ReplicatedStorage.Game.Vehicle.Heli),
        Raycast = require(ReplicatedStorage.Module.RayCast),
        UI = require(ReplicatedStorage.Module.UI),
        GunShopUI = require(ReplicatedStorage.Game.GunShop.GunShopUI),
        GunShopUtils = require(ReplicatedStorage.Game.GunShop.GunShopUtils),
        AlexChassis = require(ReplicatedStorage.Module.AlexChassis),
        Store = require(ReplicatedStorage.App.store),
        TagUtils = require(ReplicatedStorage.Tag.TagUtils),
        RobberyConsts = require(ReplicatedStorage.Robbery.RobberyConsts),
        NpcShared = require(ReplicatedStorage.GuardNPC.GuardNPCShared),
        Npc = require(ReplicatedStorage.NPC.NPC),
        SafeConsts = require(ReplicatedStorage.Safes.SafesConsts),
        MansionUtils = require(ReplicatedStorage.MansionRobbery.MansionRobberyUtils),
        BossConsts = require(ReplicatedStorage.MansionRobbery.BossNPCConsts),
        BulletEmitter = require(ReplicatedStorage.Game.ItemSystem.BulletEmitter),
    }
}

repeat dependencies.modules.TeamChooseUI.Hide() task.wait(1) until Character:FindFirstChild("Head") or Character:FindFirstChild("HumanoidRootPart") or Character:FindFirstChild("Humanoid");

--// Bypass

local ExitFunc = nil

for i, v in pairs(getgc(true)) do
    if typeof(v) =="function" then
        if debug.info(v, "n"):match("CheatCheck") then
            hookfunction(v, function() end)
        end
    end

    if typeof(v) == "function" and getfenv(v).script == LocalPlayer.PlayerScripts.LocalScript then
        local con = getconstants(v)
        if table.find(con, "LastVehicleExit") and table.find(con, "tick") then
            ExitFunc = v
        end
    end
end

--// Executable

local oldIsFlying = dependencies.modules.Paraglide.IsFlying
dependencies.modules.Paraglide.IsFlying = function(...)
    local success, debugInfo = pcall(function() return debug.getinfo(2, "s") end)

    if success and debugInfo and debugInfo.source then
        if debugInfo.source:find("Falling") then
            return true
        end
    end

    return oldIsFlying(...)
end

CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
    if child.Name == 'ErrorPrompt' and child:FindFirstChild('MessageArea') and child.MessageArea:FindFirstChild("ErrorFrame") then
        --Teleport()
    end
end)

--// Local Function

local function getCharacter()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.CharacterAdded:Wait()
    end
    return LocalPlayer.Character, LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function IsArrested()
    if LocalPlayer.PlayerGui.MainGui.CellTime.Visible or LocalPlayer.Folder:FindFirstChild("Cuffed") then
        return true
    end
        
    return false
end

local function GetClosestAirdrop()
    if Workspace:FindFirstChild("Drop") then
        return Workspace:FindFirstChild("Drop")
    end
    return nil
end

local function FireTouchInterest(part)
    if Character and Character.HumanoidRootPart then
        firetouchinterest(part, Character.HumanoidRootPart, 1)
        task.wait()
        firetouchinterest(part, Character.HumanoidRootPart, 0)
    end
end

local function GetGun()
    local SetThreadId = (setidentity or set_thread_identity or (syn and syn.set_thread_identity) or setcontext or setthreadcontext or set_thread_context)
    local IsOpen = pcall(dependencies.modules.GunShopUI.open)
            
    SetThreadId(2)
    dependencies.modules.GunShopUI.displayList(dependencies.modulesGunShopUtils.getCategoryData("Held"))
    SetThreadId(7)

    repeat 
        for i, v in next, dependencies.modules.gui.Container.Container.Main.Container.Slider:GetChildren() do
            if v:IsA("ImageLabel") and v.Name == "Pistol" and (v.Bottom.Action.Text == "FREE" or v.Bottom.Action.Text == "EQUIP") then
                firesignal(v.Bottom.Action.MouseButton1Down)
            end
        end	
        task.wait()
    until LocalPlayer.Folder:FindFirstChild("Pistol")

    pcall(dependencies.modules.close)
end

local function ShootGun()
    local currentGun = dependencies.modules.ItemSystem.GetLocalEquipped()

    if not currentGun then
        return
    end

    dependencies.modules.GunItem._attemptShoot(currentGun)
end

local function ScanForAirdrop()
    local originalCameraType = Camera.CameraType
    local originalCFrame = Camera.CFrame

    for x = -1529, 1567, 255 do
        for z = -5179, 717, 255 do
            if GetClosestAirdrop() then
                Camera.CameraType = originalCameraType
                Camera.CFrame = originalCFrame
                return GetClosestAirdrop()
            end

            Camera.CameraType = Enum.CameraType.Scriptable
            Camera.CFrame = CFrame.new(x, 50, z)
            task.wait(0.1)
        end
    end
    Camera.CameraType = originalCameraType
    Camera.CFrame = originalCFrame

    return nil
end

local function RobAirDrop(drop)
    if not drop or not Character or not Character.HumanoidRootPart then
        return false;
    end

    if not drop:GetAttribute("BriefcaseLanded") then
        repeat task.wait() until drop:GetAttribute("BriefcaseLanded") == true
    elseif drop:GetAttribute("BriefcaseCollected") then
        return
    end

    local distance = (drop.PrimaryPart.Position - Character.HumanoidRootPart.Position).Magnitude

    for _, child in ipairs(Character:GetDescendants()) do
        if child:IsA("BasePart") then
            child.CanCollide = false
        end
    end

    if drop and drop:FindFirstChild("PrimaryPart") then
        for _, part in ipairs(drop:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end

    if drop.PrimaryPart and drop.Parent then
        Character.HumanoidRootPart.CFrame = drop.PrimaryPart.CFrame * CFrame.new(-1, 1, 0.25)
        task.wait(math.random(0.1, 0.2))
        --game:Service("VirtualInputManager"):SendKeyEvent(true, "C", false, game);
    end

    repeat task.wait()
        distance = (drop.PrimaryPart.Position - Character.HumanoidRootPart.Position).Magnitude
    until distance <= 10 or not drop.PrimaryPart or drop:GetAttribute("BriefcaseCollected") or not drop.Parent

    if drop:GetAttribute("BriefcaseCollected") then
        return
    end

    Character.HumanoidRootPart.Anchored = true

    repeat
        if Workspace:FindFirstChild("GuardNPCPlayers") then
            for _, guard in pairs(Workspace.GuardNPCPlayers:GetChildren()) do
                guard:Remove()
            end
        end

        drop.BriefcasePress:FireServer(false)
        task.wait(0.5)
        drop.BriefcasePress:FireServer(true)
        drop.BriefcaseCollect:FireServer()
    until drop:GetAttribute("BriefcaseCollected") == true or not drop.PrimaryPart or not drop.Parent
    
    if not drop.PrimaryPart or not drop.Parent or not GetClosestAirdrop() then return end
    drop.Name = ""
    repeat task.wait() until Workspace.DroppedCash:GetChildren()[1] ~= nil

    Character.HumanoidRootPart.Anchored = false

    for i = 1, 3 do
        for _, spec in pairs(dependencies.modules.UI.CircleAction.Specs) do
            if spec and spec.Name:sub(1, 8) == "Collect " and spec.Callback then
                spec:Callback(true)
            end
        end
        task.wait(0.1)
    end
    task.wait(1)
end

local function IsMansionOpen()
    for i,v in pairs(RobberyState:GetChildren()) do
        if v.Name == tostring(dependencies.modules.RobberyConsts.ENUM_ROBBERY.MANSION) then
            return (v.Value == 1)
        end
    end
end

local function WaitForReward()
    if LocalPlayer.PlayerGui.AppUI:FindFirstChild("RewardSpinner") then
        repeat task.wait() until not LocalPlayer.PlayerGui.AppUI:FindFirstChild("RewardSpinner")
    end
    return true
end

local function OpenAllSafe(amount)
    if dependencies.variables["Auto Open Safe"] then
        local safesInventory = dependencies.modules.Store:getState().safesInventoryItems
        local SafeAmt = #safesInventory
        
        if SafeAmt > 0 then
            task.spawn(function()
                for i = 1, amount do
                    local CurrentSafe = safesInventory[i]
                    
                    if CurrentSafe and CurrentSafe.itemOwnedId then
                        ReplicatedStorage[dependencies.modules.SafeConsts.SAFE_OPEN_REMOTE_NAME]:FireServer(CurrentSafe.itemOwnedId)
                        task.wait(3)
                    end
                end
            end)
        end
    end
    return SafeAmt
end

--// Main Source

local function MainAirDrop()
    while dependencies.variables["AirDrop"] do
        local TimeCooldown = os.clock()
        local AirDrop = GetClosestAirdrop()

        while not AirDrop do
            AirDrop = ScanForAirdrop()
            task.wait(1)
        end

        if os.clock() - TimeCooldown < 18 then
            repeat task.wait() until os.clock() - TimeCooldown >= 18 or not GetClosestAirdrop()
        end

        AirDrop = GetClosestAirdrop()
        if not AirDrop or not AirDrop.PrimaryPart then
            print("Airdrop Disappeared!")
            return
        end    

        repeat task.wait(0.1)
            if not dependencies.variables["AirDrop"] then
                return
            end

            pcall(function()
                local distance = (AirDrop.PrimaryPart.Position - Character.HumanoidRootPart.Position).Magnitude

                if distance >= 50 then
                    teleport(AirDrop.PrimaryPart.CFrame * CFrame.new(5, 15, 0))
                elseif distance >= 30 then
                    teleport(AirDrop.PrimaryPart.CFrame * CFrame.new(5, 15, 0))
                elseif distance >= 10 then
                    if AirDrop:GetAttribute("BriefcaseLanded") then
                        Character.HumanoidRootPart.CFrame = AirDrop.PrimaryPart.CFrame * CFrame.new(0, 5, 0)
                    else
                        teleport(AirDrop.PrimaryPart.CFrame * CFrame.new(0, 15, 0))
                    end
                end

                if distance <= 10 then
                    RobAirDrop(AirDrop)
                    TimeCooldown = os.clock()
                end
            end)
        until not dependencies.variables["AirDrop"] or AirDrop:GetAttribute("BriefcaseCollected") or not AirDrop.PrimaryPart or not Character or not GetClosestAirdrop()
        WaitForReward()
        OpenAllSafe(math.huge)
        task.wait(1)
    end
end

function MainRobMansion()
    if not LocalPlayer.Folder:FindFirstChild("MansionInvite") then
        return;
    end
    
    local MansionRobbery = Workspace.MansionRobbery
    local TouchToEnter = MansionRobbery.Lobby.EntranceElevator.TouchToEnter
    local ElevatorDoor = MansionRobbery.ArrivalElevator.Floors:GetChildren()[1].DoorLeft.InnerModel.Door
    local MansionTeleportCFrame = TouchToEnter.CFrame - Vector3.new(0, TouchToEnter.Size.Y / 2 - LocalPlayer.Character.Humanoid.HipHeight * 2, -TouchToEnter.Size.Z)
        
    _G.FailMansion = false
    
    task.delay(10, function()
        _G.FailMansion = true
    end)
    
    repeat
        Character.HumanoidRootPart.CFrame = MansionTeleportCFrame
        FireTouchInterest(TouchToEnter)
    
        task.wait()
    until dependencies.modules.MansionUtils.isPlayerInElevator(MansionRobbery, Player) or FailMansion
    
    if FailMansion then 
        return;
    end
    
    GetGun()
    
    repeat task.wait(0.1) until ElevatorDoor.Position.X > 3208
    
    for _, instance in pairs(MansionRobbery.Lasers:GetChildren()) do
        instance:Remove()
    end
    for _, instance in pairs(MansionRobbery.LaserTraps:GetChildren()) do
        instance:Remove()
    end

    if not Character.HumanoidRootPart(CFrame.new(3202, -200, -4703)) then return end
    if not Character.HumanoidRootPart(CFrame.new(3201, -200, -4679)) then return end
    if not Character.HumanoidRootPart(CFrame.new(3106, -204, -4675)) then return end
    if not Character.HumanoidRootPart(CFrame.new(3106, -204, -4647)) then return end
    if not Character.HumanoidRootPart(CFrame.new(3140, -204, -4647)) then return end
    if not Character.HumanoidRootPart(CFrame.new(3147, -204, -4566)) then return end
    
    repeat task.wait() until MansionRobbery:GetAttribute("MansionRobberyProgressionState") == 3
    
    dependencies.modules.MansionUtils.getProgressionStateChangedSignal(MansionRobbery):Wait()
    
    local NPC_new = dependencies.modules.Npc.new
    local NPCShared_goTo = dependencies.modules.NpcShared.goTo
    
    dependencies.modules.new = function(NPCObject, ...)
        if NPCObject.Name ~= "ActiveBoss" then
            for i,v in pairs(NPCObject:GetDescendants()) do
                pcall(function()
                    v.Transparency = 1
                end)
            end
        end
        return NPC_new(NPCObject, ...)
    end
    dependencies.modules.Npc.GetTarget = function(...)
        return MansionRobbery and MansionRobbery:FindFirstChild("ActiveBoss") and MansionRobbery:FindFirstChild("ActiveBoss").HumanoidRootPart
    end
        
    dependencies.modules.NpcShared.goTo = function(NPCData, Pos)
        if MansionRobbery and MansionRobbery:FindFirstChild("ActiveBoss") then
            return NPCShared_goTo(NPCData, MansionRobbery:FindFirstChild("ActiveBoss").HumanoidRootPart.Position)
        end
    end
        
    Workspace.Items.DescendantAdded:Connect(function(Des)
        if Des:IsA("BasePart") then
            Des.Transparency = 1
            Des:GetPropertyChangedSignal("Transparency"):Connect(function()
                Des.Transparency = 1
            end)
        end
    end)
    
    for i,v in pairs(ReplicatedStorage.Game.Item:GetChildren()) do
        require(v).ReloadDropAmmoVisual = function() end
        require(v).ReloadDropAmmoSound = function() end
        require(v).ReloadRefillAmmoSound = function() end
        require(v).ShootSound = function() end
    end
        
    getfenv(dependencies.modules.BulletEmitter.Emit).Instance = {
        new = function()
            return {
                Destroy = function() end
            }
        end
    }
    
    local BossCEO = MansionRobbery:WaitForChild("ActiveBoss")
    local OldHealth = BossCEO.Humanoid.Health
    
    dependencies.modules.Raycast.RayIgnoreNonCollideWithIgnoreList = function(...)
            local arg = {RayIgnore(...)}
                            
            if (tostring(getfenv(2).script) == "BulletEmitter" or tostring(getfenv(2).script) == "Taser") then
                arg[1] = BossCEO.Head
                arg[2] = BossCEO.Head.Position
            end
    
            return unpack(arg)
        end
    
    require(ReplicatedStorage.NPC.NPC).GetTarget = function()
        return BossCEO:FindFirstChild("Head")
    end
        
    local Start = os.time()
        
    while LocalPlayer.Folder:FindFirstChild("Pistol") and BossCEO and BossCEO:FindFirstChild("HumanoidRootPart") and BossCEO.Humanoid.Health >= 1 do
        LocalPlayer.Folder.Pistol.InventoryEquipRemote:FireServer(true)
        task.wait()
        ShootGun()
    end
    
    dependencies.modules.Raycast.RayIgnoreNonCollideWithIgnoreList = RayIgnore
    
    print("Killed boss in " .. Start - os.time())
    LocalPlayer.Folder.Pistol.InventoryEquipRemote:FireServer(false)
    repeat task.wait() until LocalPlayer.PlayerGui.AppUI:FindFirstChild("RewardSpinner")
end

spawn(function()

    task.delay(300, function()
        --Teleport()
    end)

    task.spawn(function()
        repeat task.wait() until IsArrested()
        --Teleport()
    end)

    Character.Humanoid.Died:Connect(function()
        --Teleport()
    end)
    
    pcall(MainAirDrop)

    local mansionOpen = IsMansionOpen()
    if mansionOpen then
        --call(MainRobMansion)
    end
end)
