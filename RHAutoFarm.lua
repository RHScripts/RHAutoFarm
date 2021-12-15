getgenv().RHFarm = {
    ["BubbleWaitAmount"] = 1, -- The delay between clicking for each bubble
    ["FireAmount"] = 12000,  -- The number of times to join classes. Higher the number, the laggier the game.
    ["LevelLock"] = 20000, -- Kicks you once you reach this level (set to math.max for no kick)
    ["NoFlashTP"] = true, -- Whether to display a black flash whenever you teleport
}
local RS = game:GetService("ReplicatedStorage") -- Used for storage ... that replicates

local CurrentClass = RS.CurrentActivity -- Used to determine the current activity or class

local Starting = RS.Classes.Starting -- Used to receive class start events and fire "go to class" events

local Code = RS.Lockers.Code -- For entering code in lockers
local Contents = RS.Lockers.Contents -- For taking items out of the lockers

local TriggerCaptcha = RS.CaptchaRemote.TriggerCaptcha -- Get the captcha trigger event
local SolvedCaptcha = RS.CaptchaRemote.SolvedRemoteEvent -- Get the captcha solve event

local Players = game:GetService("Players") -- Used for getting the players (kinda obvious)
local Player = Players.LocalPlayer -- Local player
local GUI = Player.PlayerGui -- Player gui

local CompUI = GUI.ComputerGamePC -- Get the computer class ui
local ChemUI = GUI.ChemistryGame -- Get the chemistry class ui
local EngUI = GUI.EnglishClass -- Get the english class ui
local TPFlash = GUI.TeleporterFlash -- Get the teleporter from the ui

local BubbleFrame = GUI.CaptchaGUI.Captcha -- Get the frame containing the bubbles too

local SideBar = GUI.HUD.Center -- Get the side bar
local Levels = SideBar.Level -- Get the textlabel containing the levels (inefficient method)
local Diamonds = SideBar.DiamondAmount -- Get the textlabel containing the diamonds (inefficient method)

local Books = {"Paint Brush Book Set", -- Books to get from the locker (paint brush book unused)
    "Recipe Book",
    "Chemistry Book",
    "Coding Book",
    "English Book"
} 

local ClassesToSkip = {"Art", -- Classes/activities to skip
    "Breakfast", 
    "Dance", 
    "Evening", 
    "Lunch", 
    "PE", 
    "Swimming",
}    

-- Locker claim script
local function ClaimLocker() -- Go to a locker, claim it, and take all the books 
    for Index, Door in pairs(workspace:GetDescendants()) do -- Find closest locker
        if Door.Name == "LockerDoor" and Door.Claim.TextLabel.Text == "Claim" then
            fireclickdetector(Door.ClickDetector) -- Click the locker
            Code:FireServer(Door, "0", "Create") -- Create password combo "0"
            for Index, Book in pairs(Books) do -- For each book (in table defined earlier)
                Contents:InvokeServer("Take", Player.Locker[Book]) -- Take the book
            end
            break -- Break loop
        end
    end
end

CaptchaGUI.DisplayOrder = -1000000 -- Throw the UI to the back. Arbritrary number (no special meaning)

ClaimLocker() -- Execute locker claim defined earlier

ChemUI:Destroy() -- Remove chemistry ui (prevent lag)
CompUI:Destroy() -- Remove computer ui (prevent lag)
EngUI:Destroy() -- Remove english ui (guess the reason for this)

if getgenv().RHFarm.NoFlashTP then
    TPFlash.Black.Size = UDim2.new(0, 0, 0, 0) -- Make teleporter not flash black
end


-- Anti bubble (on execution)
for Index, Bubble in pairs(BubbleFrame.FloatArea:GetChildren()) do -- Get each bubble
    if Bubble.Name == "FloatBox" and Bubble:FindFirstChild("ImageLabel")  and Bubble.Visible then -- Verify that it is a bubble
        firesignal(Bubble.MouseButton1Click) -- Click it
    end 
end

-- Actual level farm 
Starting.OnClientEvent:Connect(function() -- When the starting event is received
    if not table.find(ClassesToSkip, CurrentClass.Value) then -- Check that the current class should not be skipped
        for i=1,getgenv().RHFarm.FireAmount do -- Loop through 1 and fire amount
            Starting:FireServer() -- Fire the remote
        end
    end
end)

-- Level lock
Levels:GetPropertyChangedSignal("Text"):Connect(function() -- When the levels change
    if tonumber(Levels.Text) > getgenv().RHFarm.LevelLock then -- If the level text is greater than level lock
        Player:Kick(string.format( -- Kick player with message
            "Level Locked, current level: %s, current diamond count: %s", 
            Levels.Text, 
            Diamonds.Text
        ))
    end
end)
    
-- More efficient anti-bubble
TriggerCaptcha.OnClientEvent:Connect(function(UUID)
    for Bubble=1,3 do
        SolvedCaptcha:FireServer("FloatingBubble_" .. Bubble, UUID)
    end
end)
