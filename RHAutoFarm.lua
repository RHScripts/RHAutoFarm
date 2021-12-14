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

local Players = game:GetService("Players") -- Used for getting the players (kinda obvious)
local Player = Players.LocalPlayer -- Local player
local GUI = Player.PlayerGui -- Player gui

local CaptchaGUI = GUI.CaptchaGui -- Get the captcha gui
local CaptchaFrame = CaptchaGUI.Captcha -- Get the frame too

local CompUI = GUI.ComputerGamePC -- Get the computer class ui
local ChemUI = GUI.ChemistryGame -- Get the chemistry class ui
local EngUI = GUI.EnglishClass -- Get the english class ui
local TPFlash = GUI.TeleporterFlash -- Get the teleporter from the ui

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

-- Actual level farm 
Starting.OnClientEvent:Connect(function() -- When the starting event is received
    if not table.find(ClassesToSkip, CurrentClass.Value) then -- Check that the current class should not be skipped
        for i=1,getgenv().RHFarm.FireAmount do -- Loop through 1 and fire amount
            Starting:FireServer() -- Fire the remote
        end
    end
end)w

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
    
-- Anti-Bubble (skidded off someone)
coroutine.wrap(function(BubbleGUI, BubbleFrame) -- Create another thread. 
    while true do -- While true
        BubbleFrame.Top.Visible = false -- Make the bubble ui invisible
        BubbleGUI.Award.Visible = false
        for Index, Bubble in pairs(BubbleFrame.FloatArea:GetChildren()) do -- Get each bubble
            if Bubble.Name == "FloatBox" and Bubble:FindFirstChild("ImageLabel")  and Bubble.Visible then -- Verify that it is a bubble
                task.wait(getgenv().RHFarm.BubbleWaitAmount) -- Wait for an arbitrary number of seconds
                firesignal(Bubble.MouseButton1Click) -- Click it
            end 
        end
        task.wait() -- Prevent infinite loop by adding a task.wait()
    end
end)(CaptchaGUI, CaptchaFrame) -- Pass arguments
