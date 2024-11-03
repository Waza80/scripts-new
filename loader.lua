-- Services --

local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

-- Variables --

local placeId = game.PlaceId
local parent = (gethui and gethui()) or CoreGui:FindFirstChild("RobloxGui") or CoreGui
local env = (getgenv and getgenv()) or _G
local gameFound = false

local notificationTime = 0.85
local notificationSettings = TweenInfo.new(notificationTime, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
local hasNotified = false
local N = {}

-- Create Message Instances -- [This was not made with any tool]

-- ScreenGui
N['1'] = Instance.new("ScreenGui", parent)

-- Notification
N['2'] = Instance.new('Frame', N['1'])
N['2'].AnchorPoint = Vector2.new(1, 1)
N['2'].BackgroundColor3 = Color3.fromRGB(12, 16, 18)
N['2'].Position = UDim2.new(1, -30, 1, -50)
N['2'].Size = UDim2.new(0, 0, 0, 0)
N['2'].Visible = false

-- Notification.UICorner
N['3'] = Instance.new('UICorner', N['2'])
N['3'].CornerRadius = UDim.new(1, 0)

-- OrbitProps
N['4'] = Instance.new('Frame', N['2'])
N['4'].Position = UDim2.new(0, 0, 0, 0)
N['4'].Size = UDim2.new(1, 0, 1, 0)

-- OrbitProps.Frame1
N['5'] = Instance.new('Frame', N['4'])
N['5'].AnchorPoint = Vector2.new(0.5, 0.5)
N['5'].BackgroundColor3 = Color3.fromRGB(255, 255, 255)
N['5'].Position = UDim2.new(0.5, 0, 0.5, 0)
N['5'].Size = UDim2.new(0, 0, 0, 0)

-- OrbitProps.Frame1.UICorner
N['6'] = Instance.new('UICorner', N['5'])
N['6'].CornerRadius = UDim.new(1, 0)

-- OrbitProps.Frame2
N['7'] = N['5']:Clone()
N['7'].Parent = N['4']

-- NotificationText
N['8'] = Instance.new('TextLabel', N['2'])
N['8'].AnchorPoint = Vector2.new(0, 0.5)
N['8'].Position = UDim2.new(0, 45, 0.5, 0)
N['8'].Size = UDim2.new(0, 0, 1, 0)
N['8'].FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold)
N['8'].TextColor3 = Color3.fromRGB(255, 255, 255)
N['8'].TextSize = 14
N['8'].TextTransparency = 1
N['8'].TextXAlignment = Enum.TextXAlignment.Left

-- Status Function --

local function ShowStatus(message)
	if hasNotified then return end
	hasNotified = true
	
	for _, item in next, {N['2'], N['4'], N['5'], N['7'], N['8']} do
		item.BackgroundTransparency = 1
	end
	
	local messageBounds = TextService:GetTextSize(message, 14, Enum.Font.Montserrat, Vector2.new(math.huge, 14)).X
	N['2'].Visible = true
	N['8'].Text = message
	
	task.spawn(function()
		TweenService:Create(N['2'], notificationSettings, {BackgroundTransparency = 0, Position = UDim2.new(1, -30, 1, -30), Size = UDim2.new(0, 40, 0, 40)}):Play()
		TweenService:Create(N['5'], notificationSettings, {BackgroundTransparency = 0, Size = UDim2.new(0, 8, 0, 8)}):Play()
		TweenService:Create(N['7'], notificationSettings, {BackgroundTransparency = 0, Size = UDim2.new(0, 8, 0, 8)}):Play()
		task.wait(notificationTime * 1.15)

        N['4'].Size = UDim2.new(0, 40, 0, 40)
		TweenService:Create(N['2'], notificationSettings, {Size = UDim2.new(0, 66 + messageBounds, 0, 40)}):Play()
		TweenService:Create(N['4'], notificationSettings, {Rotation = -360}):Play()
		TweenService:Create(N['5'], notificationSettings, {AnchorPoint = Vector2.new(1, 0), Size = UDim2.new(1/3, 0, 1/3, 0)}):Play()
		TweenService:Create(N['7'], notificationSettings, {AnchorPoint = Vector2.new(0, 1), Size = UDim2.new(1/3, 0, 1/3, 0)}):Play()
		task.wait(notificationTime / 2)

		TweenService:Create(N['8'], notificationSettings, {TextTransparency = 0}):Play()
		task.wait(notificationTime + 0.5 * #(string.split(message, " ")))

		TweenService:Create(N['8'], notificationSettings, {TextTransparency = 1}):Play()
		task.wait(notificationTime / 2)

		TweenService:Create(N['2'], notificationSettings, {Size = UDim2.new(0, 4, 0, 40)}):Play()
		TweenService:Create(N['4'], notificationSettings, {Rotation = 0}):Play()
		TweenService:Create(N['5'], notificationSettings, {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 8, 0, 8)}):Play()
		TweenService:Create(N['7'], notificationSettings, {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 8, 0, 8)}):Play()
		for _, item in next, {N['2'], N['4'], N['5'], N['7'], N['8']} do
			TweenService:Create(item, TweenInfo.new(notificationTime * 0.6, Enum.EasingStyle.Linear), {BackgroundTransparency = 1}):Play()
		end
    task.wait(notificationTime)

    N['1']:Destroy()
	end)
end

-- Import Supported Games --

local supportedGames

-- Try to fetch supported games
if pcall(function()
		supportedGames = HttpService:JSONDecode(game:HttpGet("https://raw.githubusercontent.com/Waza80/scripts-new/refs/heads/main/SupportedGames.json"))
	end) == false then
	-- Tell the user that it failed to fetch and exit
	ShowStatus("Failed to fetch supported games.")
	return
end

-- Search for Games --

for _, item in next, supportedGames do
	-- Game Id matches JSON
	if table.find(item.ids, placeId) then
		gameFound = true

		-- Check for required custom functions
		-- This is not an issue if your executor has fake functions; the end script will not work anyways, this is just some protection
		if item.reqs then
			for _, req in next, item.reqs do
				if not table.find(env, req) then
					-- Tell the user that the script cannot run and exit
					ShowStatus("Orbit is not able to run on your executor.")
					return
				end
			end
		end

		-- Load the loadstring
		ShowStatus("Orbit has successfully executed.")
		loadstring(game:HttpGet("https://raw.githubusercontent.com/Waza80/scripts-new/refs/heads/main/" .. (item.load or item.name) .. ".lua"))()
		break
	end
end

-- Tell the user if it hasn't found anything and exit
if not gameFound then
	ShowStatus("Orbit does not support this game.")
end
