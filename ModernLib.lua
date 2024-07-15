-- Services --

local Players = game:GetService("Players")
local status, response = pcall(function() return game:GetService("CoreGui") end)
local CoreGui = nil; if status == true then CoreGui = response end
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Useful Variables --

local LocalPlayer = Players.LocalPlayer
local PlayerMouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

local Executor = ((identifyexecutor and identifyexecutor()) or nil)
local writefile = writefile or function(...) end
local readfile = readfile or function(...) end
local isfile = isfile or function(...) end

local Lib = {}

-- Function Setup --

local function LibSource()
	return select(2, pcall(function() return game:HttpGet("https://raw.githubusercontent.com/Waza80/scripts/main/ModernUI_Source.lua") end))
end

local function Discordify(Item: TextLabel)
	local Match = Item.RichText
	Item.RichText = true

	for match in Item.Text:gmatch("#[a-zA-Z0-9-]+") do
		Match = true
		Item.Text = Item.Text:gsub(table.concat(string.split(match, "-"), "%-"), "<font color='rgb(0, 200, 255)'>" .. match .. "</font>")
	end

	if not Match then
		Item.RichText = false
	end
end

local function setpseudoclipboard(Item, Text, Fill)
	Fill = Fill or false

	local TextFrame = Item:Clone()
	TextFrame:ClearAllChildren()
	TextFrame.Parent = Item
	TextFrame.Active = false
	TextFrame.AnchorPoint = Vector2.new(0, 0)
	TextFrame.Position = UDim2.new(0, 0, 0, 0)
	TextFrame.Size = UDim2.new(1, 0, 1, 0)
	TextFrame.BackgroundTransparency = 1
	if TextFrame["Text"] then TextFrame.Text = "" end

	local TextBox = Instance.new("TextBox", TextFrame)
	TextBox.BackgroundTransparency = 1
	TextBox.ClearTextOnFocus = false
	TextBox.Size = UDim2.new(1, 0, 1, 0)
	TextBox.Text = Text
	TextBox.TextWrapped = true
	if Item["TextColor3"] then TextBox.TextColor3 = Item.TextColor3 else TextBox.TextColor3 = Color3.fromRGB(255, 255, 255) end
	if Item["FontFace"] then TextBox.FontFace = Item.FontFace else TextBox.FontFace = Enum.Font.Montserrat end
	if Item["TextSize"] then TextBox.TextSize = Item.TextSize end
	if Item["TextStrokeTransparency"] then TextBox.TextStrokeTransparency = Item.TextStrokeTransparency end
	if Item["TextStrokeColor3"] then TextBox.TextStrokeColor3 = Item.TextStrokeColor3 end

	if Fill then
		TextFrame.BackgroundTransparency = 0
		if Item:FindFirstChildWhichIsA("UICorner") then
			local UICorner = Instance.new("UICorner", TextFrame)
			UICorner.CornerRadius = Item:FindFirstChildWhichIsA("UICorner").CornerRadius
		end
	end

	TextBox:CaptureFocus()

	TextBox:GetPropertyChangedSignal("Text"):Connect(function()
		if TextBox.Text ~= Text then
			TextBox.Text = Text
		end
	end)

	TextBox.FocusLost:Connect(function()
		TextFrame:Destroy()
	end)
end

local setclipboard = setclipboard or setpseudoclipboard

local function KickUser()
	LocalPlayer:Kick("You tried bypassing nigger")
end

function Lib:CreateWindow(T)
	T["Name"] = T["Name"] or ""
	T["MenuTitle"] = T["MenuTitle"] or "Unnamed"
	T["MenuDesc"] = T["MenuDesc"] or ""
	T["FolderName"] = T["FolderName"] or (T["Name"] ~= "" and T["Name"]) or "Unnamed" -- Your folder's name, defaults to your lib's name
	T["SelectorTopDistance"] = T["SelectorTopDistance"] or 5
	T["Rainbow"] = T["Rainbow"] or false
	if T["ShowCloseButton"] == nil then T["ShowCloseButton"] = true end
	T["MultipleTabs"] = T["MultipleTabs"] or false
	if T["ResetTabPosition"] == nil then T["ResetTabPosition"] = true end
	T["ClosePosition"] = T["ClosePosition"] or "center"

	T["KeySystem"] = T["KeySystem"] or false
	if T["KeySetup"] then
		T["KeySetup"]["Title"] = T["KeySetup"]["Title"] or "Key System"
		T["KeySetup"]["Desc"] = T["KeySetup"]["Desc"] or "Please complete the key system in order to access premium features."
		T["KeySetup"]["Note"] = T["KeySetup"]["Note"] or nil
		T["KeySetup"]["SaveKey"] = T["KeySetup"]["SaveKey"] or false
		T["KeySetup"]["SaveFile"] = T["KeySetup"]["SaveFile"] or nil
		T["KeySetup"]["KeyLink"] = T["KeySetup"]["KeyLink"] or nil
		assert(T["KeySetup"]["Key"] and #T["KeySetup"]["Key"] > 0, "No key provided, Key System will be disabled")
		T["KeySetup"]["IncludeLinks"] = T["KeySetup"]["IncludeLinks"] or false
		T["KeySetup"]["CheckFunc"] = T["KeySetup"]["CheckFunc"] or function(Key)
			for _, key in next, T["KeySetup"]["Key"] do
				if T["KeySetup"]["IncludeLinks"] and (string.find(key:sub(1, 8), "https://") or string.find(key:sub(1, 7), "http://")) then
					local status, result = pcall(function()
						if Key == game:HttpGet(key) then
							return true
						end
					end)
					if result == true then
						return true
					end
				else
					if Key == key then
						return true
					end
				end
			end
		end
	else
		T["KeySetup"] = {
			Mandatory = false, -- Whether or not you're obligated to do the key system
			Title = "Key System",
			Desc = "Please complete the key system in order to access premium features.",
			Note = nil, -- The note; can be a way to use the key. Discord channels are highlighted in blue
			SaveKey = true, -- Whether or not to save the key
			SaveFile = nil, -- The file to save the key in. Default: Your hub's name/SavedKey
			KeyLink = nil, -- Whether or not to include a key link, and the associated link
			Key = {"Test"}, -- Keys that will be valid
			IncludeLinks = false, -- Whether or not to request key from links if given
			CheckFunc = function(Key)
				for _, key in next, T["KeySetup"]["Key"] do
					if T["KeySetup"]["IncludeLinks"] and (string.find(key:sub(1, 8), "https://") or string.find(key:sub(1, 7), "http://")) then
						local status, result = pcall(function()
							if Key == game:HttpGet(key) then
								return true
							end
						end)
						if result == true then
							return true
						end
					else
						if Key == key then
							return true
						end
					end
				end
			end
		}
	end

	local WindowItem = {}
	local SelectedTab = nil	
	local TabLayout = 0
	local IsDragging = false
	
	local Main = select(2, pcall(function() return script.Parent end))
	if Executor then
		Main = LibSource()
		for _, Item in pairs(Main:GetChildren()) do
			if table.find({"KeySystem", "Premium", "KeyClose"}, Item.Name) == nil then
				Item:Destroy()
			end
		end
	end
	
	function Lib:Destroy()
		Main:Destroy()
	end

	function WindowItem:Destroy()
		Main:Destroy()
	end
	
	local TabSelector = Main.TabSelector
	local ScriptNameHighlight = Main.ScriptNameHighlight
	
	local KeySystem = Main.KeySystem
	local Premium = Main.Premium
	local KeyClose = Main.KeyClose

	local KeyStatus = false; -- 1: Free / 2: Key
	local PremiumOpened = false
	local KeySwitchSpeed = 0.5
	
	-- Key System
	if T["KeySystem"] then
		TabSelector.Visible = false
		ScriptNameHighlight.Visible = false
		local KeySystemTitleSize = TextService:GetTextSize(T["MenuTitle"], 20, Enum.Font.Montserrat, Vector2.new(310, math.huge)).Y
		local KeySystemDescSize = TextService:GetTextSize(T["MenuDesc"], 14, Enum.Font.Montserrat, Vector2.new(310, math.huge)).Y
		local MandatoryValue = tonumber((T["KeySetup"]["Mandatory"] and "0") or 35) - 35
		KeySystem.Visible = true
		KeySystem.AnchorPoint = Vector2.new(0.5, 0.5)
		KeySystem.Position = UDim2.new(0.5, 0, 0.5, 0)
		KeySystem.Desc.Position = UDim2.new(0.5, 0, 0, 12 + KeySystemTitleSize)
		KeySystem.Size = UDim2.new(0, 330, 0, 103 + KeySystemTitleSize + KeySystemDescSize + MandatoryValue)
		KeySystem.Title.Size = UDim2.new(1, -20, 0, KeySystemTitleSize)
		KeySystem.Desc.Size = UDim2.new(1, -20, 0, KeySystemDescSize)
		KeySystem.Title.Text = T["MenuTitle"]
		KeySystem.Desc.Text = T["MenuDesc"]
		if T["KeySetup"]["Mandatory"] then 
			KeySystem.FreeVersion.Visible = false
			KeySystem.PremiumVersion.Text = "Access Script [Key System]"
		end

		local KeySetupTitleSize = TextService:GetTextSize(T["KeySetup"]["Title"], 20, Enum.Font.Montserrat, Vector2.new(310, math.huge)).Y
		local KeySetupDescSize = TextService:GetTextSize(T["KeySetup"]["Desc"], 14, Enum.Font.Montserrat, Vector2.new(310, math.huge)).Y
		local KeySetupNoteSize = (T["KeySetup"]["Note"] and TextService:GetTextSize((T["KeySetup"]["Note"] and "NOTE:\n" .. T["KeySetup"]["Note"]) or "", 14, Enum.Font.Montserrat, Vector2.new(310, math.huge)).Y) or -10
		local KeySetupCopySize = (T["KeySetup"]["KeyLink"] and 35) or 0
		Premium.Visible = true
		Premium.Close.Visible = false
		Premium.CopyLink.Visible = (T["KeySetup"]["KeyLink"] and true) or false
		Premium.AnchorPoint = Vector2.new(0, 0.5)
		Premium.Position = UDim2.new(1, 0, 0.5, 0)
		Premium.Desc.Position = UDim2.new(0.5, 0, 0, 12 + KeySetupTitleSize)
		Premium.KeyEntry.Position = UDim2.new(0.5, 0, 1, -((T["KeySetup"]["KeyLink"] and 45) or 10))
		Premium.Size = UDim2.new(0, 330, 0, 78 + KeySetupTitleSize + KeySetupDescSize + KeySetupNoteSize + KeySetupCopySize)
		Premium.Title.Size = UDim2.new(1, -20, 0, KeySetupTitleSize)
		Premium.Desc.Size = UDim2.new(1, -20, 0, KeySetupDescSize)
		Premium.Note.Size = UDim2.new(1, -20, 0, KeySetupNoteSize)
		Premium.Title.Text = T["KeySetup"]["Title"]
		Premium.Desc.Text = T["KeySetup"]["Desc"]
		Premium.Note.Text = (T["KeySetup"]["Note"] and "<font weight='900'>NOTE:</font>\n" .. T["KeySetup"]["Note"]) or ""
		Discordify(Premium.Note)

		KeyClose.Visible = true
		KeyClose.Position = UDim2.new(0.5, 0, 0.5, -(KeySystem.AbsoluteSize.Y / 2) - 10)
		KeyClose.MouseButton1Click:Connect(function() Lib:Destroy() end)

		KeySystem.FreeVersion.MouseButton1Click:Connect(function()
			KeyStatus = 1
		end)

		KeySystem.PremiumVersion.MouseButton1Click:Connect(function()
			PremiumOpened = not PremiumOpened
			if PremiumOpened then
				TweenService:Create(KeySystem, TweenInfo.new(KeySwitchSpeed, Enum.EasingStyle.Quad), {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(0.5, -10, 0.5, 0)}):Play()
				TweenService:Create(Premium, TweenInfo.new(KeySwitchSpeed, Enum.EasingStyle.Quad), {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0.5, 10, 0.5, 0)}):Play()
				TweenService:Create(KeyClose, TweenInfo.new(KeySwitchSpeed, Enum.EasingStyle.Quad), {Position = UDim2.new(0.5, 0, 0.5, -(math.max(KeySystem.AbsoluteSize.Y, Premium.AbsoluteSize.Y) / 2) - 10)}):Play()
			else
				TweenService:Create(KeySystem, TweenInfo.new(KeySwitchSpeed, Enum.EasingStyle.Quad), {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
				TweenService:Create(Premium, TweenInfo.new(KeySwitchSpeed, Enum.EasingStyle.Quad), {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(1, 0, 0.5, 0)}):Play()
				TweenService:Create(KeyClose, TweenInfo.new(KeySwitchSpeed, Enum.EasingStyle.Quad), {Position = UDim2.new(0.5, 0, 0.5, -(KeySystem.AbsoluteSize.Y / 2) - 10)}):Play()
			end
		end)

		if T["KeySetup"]["KeyLink"] then
			Premium.CopyLink.MouseButton1Click:Connect(function()
				if Executor then
					setclipboard(T["KeySetup"]["KeyLink"])
				else
					setpseudoclipboard(Premium.CopyLink, T["KeySetup"]["KeyLink"], true)
				end
			end)
		end

		Premium.KeyEntry.FocusLost:Connect(function()
			if Premium.KeyEntry.Text == "" then return end

			local ValidKey = false
			local KeyAttempt = Premium.KeyEntry.Text

			if T["KeySetup"]["CheckFunc"](KeyAttempt) then
				KeyStatus = 2
				if T["KeySetup"]["SaveKey"] then
					if Executor then
						if T["KeySetup"]["SaveFile"] then
							writefile(T["FolderName"] .. "/" .. T["KeySetup"]["SaveFile"], KeyAttempt)
						else
							writefile(T["FolderName"] .. "/" .. "Key", KeyAttempt)
						end
					end
				end
			else
				local OriginalPos = Premium.KeyEntry.Position
				for i = 1, 2 do
					TweenService:Create(Premium.KeyEntry, TweenInfo.new(0.1), {Position = UDim2.new(0.5, OriginalPos.X.Offset + 5, 1, OriginalPos.Y.Offset)}):Play()
					task.wait(0.1)
					TweenService:Create(Premium.KeyEntry, TweenInfo.new(0.1), {Position = UDim2.new(0.5, OriginalPos.X.Offset - 5, 1, OriginalPos.Y.Offset)}):Play()
					task.wait(0.1)
				end
				TweenService:Create(Premium.KeyEntry, TweenInfo.new(0.1), {Position = OriginalPos}):Play()
			end
		end)

		if Executor and T["KeySetup"]["SaveKey"] and ((T["KeySetup"]["SaveFile"] and isfile(T["FolderName"] .. "/" .. T["KeySetup"]["SaveFile"])) or isfile(T["FolderName"] .. "/" .. "Key")) then
			local SavedKey = ((T["KeySetup"]["SaveFile"] and readfile(T["FolderName"] .. "/" .. T["KeySetup"]["SaveFile"])) or readfile(T["FolderName"] .. "/" .. "Key"))
			if T["KeySetup"]["CheckFunc"](SavedKey) then
				KeyStatus = 2
			end
		end

		repeat task.wait() until KeyStatus

		TweenService:Create(KeySystem, TweenInfo.new(0.65, Enum.EasingStyle.Quad), {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(0, 0, 0.5, 0)}):Play()
		TweenService:Create(Premium, TweenInfo.new(0.65, Enum.EasingStyle.Quad), {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(1, 0, 0.5, 0)}):Play()
		TweenService:Create(KeyClose, TweenInfo.new(0.65, Enum.EasingStyle.Quad), {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, 0)}):Play()	

		if KeyStatus == 1 then
			KeySystem:Destroy()
			KeyClose:Destroy()

			if Executor then
				Main = LibSource()
				for _, Item in pairs(Main:GetChildren()) do
					if table.find({"KeySystem", "KeyClose"}, Item.Name) then
						Item:Destroy()
					end
				end
			end
		else
			KeySystem:Destroy()
			KeyClose:Destroy()
			Premium:Destroy()

			if Executor then
				Main:Destroy()
				Main = LibSource()
				for _, Item in pairs(Main:GetChildren()) do
					if table.find({"KeySystem", "Premium", "KeyClose"}, Item.Name) then
						Item:Destroy()
					end
				end

				for _, Item in pairs(Main:GetDescendants()) do
					if Item:IsA("UIGradient") then
						Item.Enabled = T["UseGradient"]
					end
				end
			end
		end

		TabSelector.Visible = true
		ScriptNameHighlight.Visible = true
	else
		if Executor then
			Main:Destroy()
			Main = LibSource()

			for _, Item in pairs(Main:GetDescendants()) do
				if Item:IsA("UIGradient") then
					Item.Enabled = T["UseGradient"]
				end
			end
		end
		for _, Item in pairs(Main:GetChildren()) do
			if table.find({"KeySystem", "Premium", "KeyClose"}, Item.Name) then
				Item:Destroy()
			end
		end
	end

	if not KeyStatus and not T["KeySystem"] then
		return
	end
	
	
	local Tabs = Main.Tabs
	local ScriptNameHighlight = Main.ScriptNameHighlight
	local TabSelector = Main.TabSelector
	local TabContainer = TabSelector.Container.Tabs
	local SelectedTabButton = nil
	local Templates = Main.Templates
	
	if T["Name"] == "" then
		ScriptNameHighlight.Visible = false
	else
		ScriptNameHighlight.ScriptName.Text = T["Name"]
		ScriptNameHighlight.Size = UDim2.new(0, ScriptNameHighlight.ScriptName.TextBounds.X + 8, 0, ScriptNameHighlight.ScriptName.TextBounds.Y + 4)
		ScriptNameHighlight.ScriptName.Size = 	UDim2.new(0, ScriptNameHighlight.ScriptName.TextBounds.X + 8, 0, ScriptNameHighlight.ScriptName.TextBounds.Y)
		ScriptNameHighlight.ScriptName.TextTruncate = Enum.TextTruncate.AtEnd	
	end
	
	TabContainer:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()
		-- if script.Parent.AbsoluteCanvasSize.X == 0 then script.Parent.Visible = false; return else script.Parent.Visible = true end
		if Camera.ViewportSize.X - 50 > TabContainer.AbsoluteCanvasSize.X then
			TabContainer.Size = UDim2.new(0, TabContainer.AbsoluteCanvasSize.X, 0, 30)
		else
			TabContainer.Size = UDim2.new(0, Camera.ViewportSize.X - 50, 0, 30)
		end
	end)
	
	TabContainer.ChildAdded:Connect(function(TabButton)
		TabButton.ClickPart.MouseButton1Click:Connect(function()
			local Tab = Tabs:FindFirstChild(TabButton.Name)
			if T["MultipleTabs"] == false then
				if SelectedTabButton then
					TweenService:Create(SelectedTabButton, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
					TweenService:Create(SelectedTabButton.Label, TweenInfo.new(0.5), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
					Tabs:FindFirstChild(SelectedTabButton.Name).Visible = false
					TabButton.IsOpened.Value = false
					if SelectedTabButton == TabButton then SelectedTabButton = nil; return end
				end
				TweenService:Create(TabButton, TweenInfo.new(0.5), {BackgroundTransparency = 0.2}):Play()
				TweenService:Create(TabButton.Label, TweenInfo.new(0.5), {TextColor3 = Color3.fromRGB(24, 24, 28)}):Play()
				SelectedTabButton = TabButton
				if Tab.Position == UDim2.new(0.5, 0, 0.5, 0) or T["ResetTabPosition"] == true then
					if T["MultipleTabs"] == false then
						Tab.Position = UDim2.new(0.5, 0, 0.5, 0)
					end
				end
				Tab.Visible = true
				TabButton.IsOpened.Value = true
			else
				if TabButton.IsOpened.Value == true then
					TabButton.IsOpened.Value = false
					Tab.Visible = false
					TweenService:Create(TabButton, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
					TweenService:Create(TabButton.Label, TweenInfo.new(0.5), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
				else
					TabButton.IsOpened.Value = true
					Tab.Visible = true
					if Tab.Position == UDim2.new(0.5, 0, 0.5, 0) or T["ResetTabPosition"] == true then
						Tab.Position = UDim2.new(0.5, math.random(-20, 20), 0.5, math.random(-20, 20))
					end
					TweenService:Create(TabButton, TweenInfo.new(0.5), {BackgroundTransparency = 0.2}):Play()
					TweenService:Create(TabButton.Label, TweenInfo.new(0.5), {TextColor3 = Color3.fromRGB(24, 24, 28)}):Play()
				end
			end
		end)
	end)
	
	TabSelector.Position = UDim2.new(0.5, 0, 0, T["SelectorTopDistance"])
	
	if T["Rainbow"] == true then
		task.spawn(function()
			pcall(function() 
				while true do
					for i = 0, 1, 0.001 * 2.5 do
						TabSelector.UIStroke.Color = Color3.fromHSV(i, 1, 1)
						TabSelector.Container.CloseButton.BackgroundColor3 = Color3.fromHSV(i, 1, 1)
						task.wait()
					end
				end
			end) 
		end)
	end
	
	if T["ShowCloseButton"] == false then
		TabSelector.Container.CloseButton.Visible = false
	else
		local OldTextBounds = nil
		local CloseButtonClosed = false
		local CloseButtonOnCooldown = false

		TabSelector.Container.CloseButton.ClickPart.MouseButton1Click:Connect(function()
			if CloseButtonOnCooldown then return end
			CloseButtonClosed = not CloseButtonClosed
			if CloseButtonClosed == true then
				if T["ClosePosition"] == "center" then
					TweenService:Create(TabSelector, TweenInfo.new(0.2), {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, TabSelector.AbsolutePosition.Y)}):Play()
				elseif T["ClosePosition"] == "left" then
					TweenService:Create(TabSelector, TweenInfo.new(0.2), {AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 25, 0, TabSelector.AbsolutePosition.Y)}):Play()
				elseif T["ClosePosition"] == "right" then
					TweenService:Create(TabSelector, TweenInfo.new(0.2), {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -25, 0, TabSelector.AbsolutePosition.Y)}):Play()
				end

				TweenService:Create(TabContainer, TweenInfo.new(0.2), {Size = UDim2.new(0, 0, 0, 30)}):Play()
				TweenService:Create(TabSelector.Container.UIListLayout, TweenInfo.new(0.2), {Padding = UDim.new(0, 0)}):Play()
				TweenService:Create(TabSelector.Container.CloseButton.Icon, TweenInfo.new(0.2), {Rotation = 45}):Play()

				if T["Name"] ~= "" then
					TweenService:Create(ScriptNameHighlight, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 0, 0, ScriptNameHighlight.ScriptName.TextBounds.Y + 4)}):Play()
					TweenService:Create(ScriptNameHighlight.ScriptName, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 0, 0, ScriptNameHighlight.ScriptName.TextBounds.Y)}):Play()
					TweenService:Create(ScriptNameHighlight.UIStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Thickness = 0}):Play()
					OldTextBounds = ScriptNameHighlight.ScriptName.TextBounds
				end
			elseif CloseButtonClosed == false then
				if Camera.ViewportSize.X - 50 > TabContainer.AbsoluteCanvasSize.X then
					TweenService:Create(TabContainer, TweenInfo.new(0.2), {Size = UDim2.new(0, TabContainer.AbsoluteCanvasSize.X, 0, 30)}):Play()

				else
					TweenService:Create(TabContainer, TweenInfo.new(0.2), {Size = UDim2.new(0, Camera.ViewportSize.X - 50, 0, 30)}):Play()

				end
				
				TweenService:Create(TabSelector, TweenInfo.new(0.2), {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, TabSelector.AbsolutePosition.Y)}):Play()
				TweenService:Create(TabSelector.Container.UIListLayout, TweenInfo.new(0.2), {Padding = UDim.new(0, 5)}):Play()
				TweenService:Create(TabSelector.Container.CloseButton.Icon, TweenInfo.new(0.2), {Rotation = 0}):Play()

				if T["Name"] ~= "" then
					TweenService:Create(ScriptNameHighlight, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(0, OldTextBounds.X + 8, 0, OldTextBounds.Y + 4)}):Play()
					TweenService:Create(ScriptNameHighlight.ScriptName, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(0, OldTextBounds.X, 0, OldTextBounds.Y)}):Play()
					TweenService:Create(ScriptNameHighlight.UIStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Thickness = 1}):Play()
				end
			end
			CloseButtonOnCooldown = true
			task.wait(0.2)
			CloseButtonOnCooldown = false
		end)
	end
	
	function WindowItem:CreateTab(Name)
		local TabItem = {}
		local TabItemLayout = 0
		local IsTabDragging, TabDragStart, TabDragPos = nil, nil, nil
		local RandomTabName =  "_" .. math.random(1000000000000, 9999999999999)
		
		local Tab = Templates.TabTemplate:Clone()
		Tab.Parent = Tabs
		Tab.Topbar.Label.Text = Name
		Tab.Visible = false
		Tab.Name = Name .. RandomTabName

		Tab.Topbar.ClickPart.InputBegan:Connect(function(Input)
			if IsDragging then return end
			if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
				IsDragging = true
				IsTabDragging = true
				TabDragStart = Input.Position
				TabDragPos = Tab.Position

				for _, Tab in pairs(Tabs:GetChildren()) do
					Tab.ZIndex = 1
				end
				Tab.ZIndex = 2

				local InputConnection = Input.Changed:Connect(function()
					if Input.UserInputState == Enum.UserInputState.End then
						IsDragging = false
						IsTabDragging = false
					end
				end)
				repeat task.wait() until IsTabDragging == false
				InputConnection:Disconnect()
			end
		end)

		UserInputService.InputChanged:Connect(function(Input)
			if (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
				if IsTabDragging == true then
					local delta = Input.Position - TabDragStart
					local position = UDim2.new(TabDragPos.X.Scale, TabDragPos.X.Offset + delta.X, TabDragPos.Y.Scale, TabDragPos.Y.Offset + delta.Y)
					Tab.Position = position
					-- TweenService:Create(Tab, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Position = position}):Play()
				end
			end
		end)
		
		local TabButton = Templates.TabButtonTemplate:Clone()
		TabButton.Parent = TabContainer
		TabButton.Label.Text = Name
		TabButton.Name = Name .. RandomTabName
		TabButton.LayoutOrder = TabLayout; TabLayout = TabLayout + 1
		TabButton.Size = UDim2.new(0, TabButton.Label.TextBounds.X + 8, 1, 0)
		
		function TabItem:CreateLabel(Text)
			local LabelItem = {}

			local Label = Templates.LabelTemplate:Clone()
			Label.Parent = Tab.Container
			Label.Name = "Label"
			Label.Title.Text = Text
			Label.LayoutOrder = TabItemLayout; TabItemLayout = TabItemLayout + 1

			function LabelItem:Set(NewText)
				Label.Title.Text = NewText
			end

			return LabelItem
		end

		function TabItem:CreateParagraph(Text, Description)
			local ParagraphItem = {}

			local Paragraph = Templates.ParagraphTemplate:Clone()
			Paragraph.Parent = Tab.Container
			Paragraph.Name = "Paragraph"
			Paragraph.Title.Text = Text
			Paragraph.Description.Text = Description
			Paragraph.LayoutOrder = TabItemLayout; TabItemLayout = TabItemLayout + 1
			
			if Paragraph.Description.AbsoluteSize.Y == 0 then
				Paragraph.Size = UDim2.new(1, -10, 0, 30)
			else
				Paragraph.Size = UDim2.new(1, -10, 0, 30 + Paragraph.Description.AbsoluteSize.Y)
			end

			Paragraph.Description:GetPropertyChangedSignal("Text"):Connect(function()
				if Paragraph.Description.AbsoluteSize.Y == 0 then
					Paragraph.Size = UDim2.new(1, -10, 0, 30)
				else
					Paragraph.Size = UDim2.new(1, -10, 0, 30 + Paragraph.Description.AbsoluteSize.Y)
				end
			end)
			
			function ParagraphItem:Set(NewText, NewDescription)
				Paragraph.Title.Text = NewText
				Paragraph.Description.Text = NewDescription
			end

			return ParagraphItem
		end

		function TabItem:CreateSection(Text)
			local Section = Templates.SectionTemplate:Clone()
			Section.Parent = Tab.Container
			Section.Name = "Section"
			Section.Label.Text = Text
			Section.LayoutOrder = TabItemLayout; TabItemLayout = TabItemLayout + 1
		end

		function TabItem:CreateButton(T)
			T["Name"] = T["Name"] or "Unnamed"
			T["Callback"] = T["Callback"] or function(...) end

			local Button = Templates.ButtonTemplate:Clone()
			Button.Parent = Tab.Container
			Button.Name = "Button"
			Button.LayoutOrder = TabItemLayout; TabItemLayout = TabItemLayout + 1
			Button.Title.Text = T["Name"]
			Button.ClickPart.MouseButton1Click:Connect(T["Callback"])

			Button.ClickPart.MouseButton1Click:Connect(function()
				local MouseDistanceLeft = PlayerMouse.X - Button.AbsolutePosition.X
				local MouseDistanceRight = (Button.AbsolutePosition.X + Button.AbsoluteSize.X) - PlayerMouse.X

				local Circle = Button.RoundAnimationContainer.Circle:Clone()
				Circle.Parent = Button.RoundAnimationContainer

				Circle.BackgroundTransparency = 0.8
				Circle.Position = UDim2.new(0, PlayerMouse.X -Button.AbsolutePosition.X, 0, PlayerMouse.Y - Button.AbsolutePosition.Y)
				Circle.Size = UDim2.new(0, 0, 0, 1000000000)
				TweenService:Create(Circle, TweenInfo.new(0.35), {Size = UDim2.new(0, math.max(MouseDistanceLeft, MouseDistanceRight) * 2, 0, 1000000000)}):Play()
				task.wait(0.35)
				TweenService:Create(Circle, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
				task.wait(0.2)
				Circle:Destroy()
				Circle = nil
			end)
			
			return T
		end

		function TabItem:CreateToggle(T)
			T["Name"] = T["Name"] or "Unnamed"
			T["Value"] = T["Value"] or false
			T["Callback"] = T["Callback"] or function(...) end

			local ToggleItem = T
			local ToggleIsEnabled = T["Value"]
			
			local Toggle = Templates.ToggleTemplate:Clone()
			Toggle.Parent = Tab.Container
			Toggle.Name = "Toggle"
			Toggle.LayoutOrder = TabItemLayout; TabItemLayout = TabItemLayout + 1
			Toggle.Title.Text = T["Name"]
			
			if ToggleIsEnabled == true then
				TweenService:Create(Toggle.Toggle, TweenInfo.new(0.35), {BackgroundColor3 = Color3.fromRGB(0, 192, 114)}):Play()
			else
				TweenService:Create(Toggle.Toggle, TweenInfo.new(0.35), {BackgroundColor3 = Color3.fromRGB(33, 33, 33)}):Play()
			end
			T["Callback"](ToggleIsEnabled)
			
			Toggle.ClickPart.MouseButton1Click:Connect(function() 
				ToggleIsEnabled = not ToggleIsEnabled
				ToggleItem.Value = ToggleIsEnabled
				
				if ToggleIsEnabled == true then
					TweenService:Create(Toggle.Toggle, TweenInfo.new(0.35), {BackgroundColor3 = Color3.fromRGB(0, 192, 114)}):Play()
				else
					TweenService:Create(Toggle.Toggle, TweenInfo.new(0.35), {BackgroundColor3 = Color3.fromRGB(33, 33, 33)}):Play()
				end
				
				T["Callback"](ToggleIsEnabled)
			end)

			function ToggleItem:Set(Status)
				ToggleIsEnabled = Status
				ToggleItem.Value = Status
				
				if ToggleIsEnabled == true then
					TweenService:Create(Toggle.Toggle, TweenInfo.new(0.35), {BackgroundColor3 = Color3.fromRGB(0, 192, 114)}):Play()
				else
					TweenService:Create(Toggle.Toggle, TweenInfo.new(0.35), {BackgroundColor3 = Color3.fromRGB(33, 33, 33)}):Play()
				end
				
				T["Callback"](Status)
			end

			return ToggleItem
		end

		function TabItem:CreateSlider(T)
			T["Name"] = T["Name"] or "Unnamed"
			T["Callback"] = T["Callback"] or nil
			T["Default"] = T["Default"] or T["Min"]
			T["Increment"] = T["Increment"] or 1

			local SliderItem = T
			local OldSliderValue = ""
			local MovingSlider = false
			local ValueIncrement = tostring(#(string.match(T["Increment"], "%.%d+") or ""))

			local Slider = Templates.SliderTemplate:Clone()
			Slider.Parent = Tab.Container
			Slider.Name = "Slider"
			Slider.LayoutOrder = TabItemLayout; TabItemLayout = TabItemLayout + 1
			Slider.Title.Text = T["Name"]
			Slider.Slider.Progression.Size = UDim2.new((T["Default"] - T["Min"]) / (T["Max"] - T["Min"]), 0, 1, 0)
			Slider.TextBox.Text = T["Default"]
			
			local GetClosestValue = function(Value)
				local Inc_N = math.floor((Value - T["Min"]) / T["Increment"])
				local LowerValue = T["Min"] + Inc_N * T["Increment"]
				local UpperValue = LowerValue + T["Increment"]
				
				if Value - LowerValue < UpperValue - Value then
					return LowerValue
				else
					return UpperValue
				end
			end

			local UpdateSlider = function()
				local FilteredString = ""
				for i = 1, #Slider.TextBox.Text do
					if i == 15 then break end
					if string.gmatch(Slider.TextBox.Text:sub(i, i), "(%d|%.)") then
						FilteredString = FilteredString .. Slider.TextBox.Text:sub(i, i)
					end
				end
				
				if FilteredString ~= "" then FilteredString = GetClosestValue(tonumber(FilteredString)) end
				FilteredString = string.format("%." .. ValueIncrement .. "f", FilteredString)
				
				local Percentage = math.clamp((tonumber(FilteredString) - T["Min"]) / (T["Max"] - T["Min"]), 0, 1)
				Slider.Slider.Progression.Size = UDim2.new(Percentage, 0, 1, 0)
				Slider.TextBox.Text = tostring(math.clamp(tonumber(FilteredString), T["Min"], T["Max"]))
				
				if T["Callback"] ~= nil then
					if OldSliderValue ~= Slider.TextBox.Text then 
						T["Callback"](Slider.TextBox.Text)
						OldSliderValue = Slider.TextBox.Text
					end
				end

				SliderItem.Value = Slider.TextBox.Text
			end
			
			Slider.TextBox:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				Slider.Precision.Position = UDim2.new(1, -10 - Slider.TextBox.AbsoluteSize.X, 0, 5)
			end)

			Slider.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
				if Slider.TextBox.TextBounds.X > 40 then
					if string.len(Slider.TextBox.Text) <= 14 then
						Slider.TextBox.Size = UDim2.new(0, Slider.TextBox.TextBounds.X + 4, 0, 20)
					end
				elseif Slider.TextBox.Size.X.Offset > 40 then
					Slider.TextBox.Size = UDim2.new(0, 40, 0, 20)
				end
			end)
			
			Slider.TextBox.FocusLost:Connect(UpdateSlider)

			Slider.Slider.InputBegan:Connect(function(Input)
				if IsDragging then return end
				if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
					IsDragging = true
					MovingSlider = true
					local InputConnection = Input.Changed:Connect(function()
						if Input.UserInputState == Enum.UserInputState.End then
							IsDragging = false
							MovingSlider = false
						end
					end)
					repeat task.wait() until MovingSlider == false
					InputConnection:Disconnect()
				end
			end)

			UserInputService.InputChanged:Connect(function(Input)
				if (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
					if MovingSlider == true then
						Slider.Slider.Progression.Size = UDim2.new(math.clamp((Input.Position.X - Slider.Slider.AbsolutePosition.X) / Slider.Slider.AbsoluteSize.X, 0, 1), 0, 1, 0)
						Slider.TextBox.Text = tostring(GetClosestValue(T["Min"] + Slider.Slider.Progression.Size.X.Scale * (T["Max"] - T["Min"])))
						UpdateSlider()
					end
				end
			end)

			Slider.Precision.Plus.MouseButton1Click:Connect(function()
				Slider.TextBox.Text = tostring(GetClosestValue(tonumber(Slider.TextBox.Text) + T["Increment"]))
				UpdateSlider()
				
			end)

			Slider.Precision.Minus.MouseButton1Click:Connect(function()
				Slider.TextBox.Text = tostring(GetClosestValue(tonumber(Slider.TextBox.Text) - T["Increment"]))
				UpdateSlider()
			end)

			function SliderItem:Set(NewValue)
				Slider.TextBox.Text = tostring(tonumber(NewValue))
				UpdateSlider()
			end

			return SliderItem
		end

		function TabItem:CreateDropdown(T)
			T["Name"] = T["Name"] or "Unnamed"
			T["Items"] = T["Items"] or {}
			T["Callback"] = T["Callback"] or nil
			T["Multiple"] = T["Multiple"] or false

			local DropdownItem = T
			local DropdownIsOpened = false

			local Dropdown = Templates.DropdownTemplate:Clone()
			Dropdown.Parent = Tab.Container
			Dropdown.Name = "Dropdown"
			Dropdown.LayoutOrder = TabItemLayout; TabItemLayout = TabItemLayout + 1
			Dropdown.Title.Text = T["Name"]

			Dropdown.ClickPart.MouseButton1Click:Connect(function()
				DropdownIsOpened = not DropdownIsOpened
				if DropdownIsOpened == false then
					TweenService:Create(Dropdown.Arrow, TweenInfo.new(0.35), {Rotation = 270}):Play()
					TweenService:Create(Dropdown.Options, TweenInfo.new(0.35), {Size = UDim2.new(1, -10, 0, 0)}):Play()
				else
					TweenService:Create(Dropdown.Arrow, TweenInfo.new(0.35), {Rotation = 360}):Play()
					TweenService:Create(Dropdown.Options, TweenInfo.new(0.35), {Size = UDim2.new(1, -10, 0, Dropdown.Options.AbsoluteCanvasSize.Y)}):Play()
				end
			end)

			Dropdown.Options:GetPropertyChangedSignal("Size"):Connect(function()
				Dropdown.Size = UDim2.new(1, -10, 0, 30 + ((Dropdown.Options.AbsoluteSize.Y / Dropdown.Options.AbsoluteCanvasSize.Y) * 5) + Dropdown.Options.AbsoluteSize.Y)
			end)
			
			local EntryLayout, ActivatedButton, MultipleButton = 0, nil, {}

			for _, Item in pairs(T["Items"]) do
				local DropdownEntry = Templates.DropdownEntryTemplate:Clone()
				DropdownEntry.Parent = Dropdown.Options
				DropdownEntry.Name = "DropdownEntry"
				DropdownEntry.LayoutOrder = EntryLayout; EntryLayout = EntryLayout + 1
				DropdownEntry.Label.Text = Item
				
				DropdownEntry.IsEnabled:GetPropertyChangedSignal("Value"):Connect(function()
					if DropdownEntry.IsEnabled.Value == true then
						TweenService:Create(DropdownEntry, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 41, 63)}):Play()
					elseif DropdownEntry.IsEnabled.Value == false then
						TweenService:Create(DropdownEntry, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(21, 21, 32)}):Play()
					end
				end)
				
				if T["Multiple"] == false then
					DropdownEntry.ClickPart.MouseButton1Click:Connect(function()
						if ActivatedButton then
							ActivatedButton.IsEnabled.Value = false
						end

						if ActivatedButton == DropdownEntry then 
							ActivatedButton = nil
							DropdownItem.Value = nil
							return 
						end
						if T["Callback"] then T["Callback"](DropdownEntry.Label.Text) end

						ActivatedButton = DropdownEntry
						DropdownItem.Value = DropdownEntry.Label.Text
						DropdownEntry.IsEnabled.Value = true
					end)
				elseif T["Multiple"] == true then
					DropdownEntry.ClickPart.MouseButton1Click:Connect(function()
						DropdownEntry.IsEnabled.Value = not DropdownEntry.IsEnabled.Value

						local EphemeralTable = {}
						for _, Entry in pairs(Dropdown.Options:GetChildren()) do
							if not Entry:IsA("UIListLayout") then
								if Entry.IsEnabled.Value == true then
									local Label = Entry.Label.Text
									table.insert(EphemeralTable, Label)
								end
							end
						end

						MultipleButton = EphemeralTable
						DropdownItem.Value = MultipleButton

						if T["Callback"] then
							T["Callback"](MultipleButton)
						end
					end)
				end
			end

			function DropdownItem:Set(Items, Reset)
				if Reset then
					ActivatedButton = nil

					for _, Entry in pairs(Dropdown.Options:GetChildren()) do
						if not Entry:IsA("UIListLayout") then
							Entry:Destroy()
						end
					end
				end

				for _, Item in pairs(Items) do
					local DropdownEntry = Templates.DropdownEntryTemplate:Clone()
					DropdownEntry.Parent = Dropdown.Options
					DropdownEntry.Name = "DropdownEntry"
					DropdownEntry.LayoutOrder = EntryLayout; EntryLayout = EntryLayout + 1
					DropdownEntry.Label.Text = Item
					
					DropdownEntry.IsEnabled:GetPropertyChangedSignal("Value"):Connect(function()
						if DropdownEntry.IsEnabled.Value == true then
							TweenService:Create(DropdownEntry, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 41, 63)}):Play()
						elseif DropdownEntry.IsEnabled.Value == false then
							TweenService:Create(DropdownEntry, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(21, 21, 32)}):Play()
						end
					end)
					
					if T["Multiple"] == false then
						DropdownEntry.ClickPart.MouseButton1Click:Connect(function()
							if ActivatedButton then
								ActivatedButton.IsEnabled.Value = false
							end

							if ActivatedButton == DropdownEntry then 
								ActivatedButton = nil
								DropdownItem.Value = nil
								return 
							end
							if T["Callback"] then T["Callback"](DropdownEntry.Label.Text) end

							ActivatedButton = DropdownEntry
							DropdownItem.Value = DropdownEntry.Label.Text
							DropdownEntry.IsEnabled.Value = true
						end)
					elseif T["Multiple"] == true then
						DropdownEntry.ClickPart.MouseButton1Click:Connect(function()
							DropdownEntry.IsEnabled.Value = not DropdownEntry.IsEnabled.Value

							local EphemeralTable = {}
							for _, Entry in pairs(Dropdown.Options:GetChildren()) do
								if not Entry:IsA("UIListLayout") then
									if Entry.IsEnabled.Value == true then
										local Label = Entry.Label.Text
										table.insert(EphemeralTable, Label)
									end
								end
							end

							MultipleButton = EphemeralTable
							DropdownItem.Value = MultipleButton

							if T["Callback"] then
								T["Callback"](MultipleButton)
							end
						end)
					end
				end
			end

			return DropdownItem
		end

		function TabItem:CreateInput(T)
			T["Name"] = T["Name"] or "Unnamed"
			T["Type"] = T["Type"] or "string"; if table.find({"string", "int"}, T["Type"]) == nil then T["Type"] = "string" end
			T["ClearOnFocus"] = T["ClearOnFocus"] or false
			T["PlaceholderText"] = T["PlaceholderText"] or ""
			T["Callback"] = T["Callback"] or nil

			local InputItem = T
			local OldInputValue = ""

			local Input = Templates.InputTemplate:Clone()
			Input.Parent = Tab.Container
			Input.Name = "Input"
			Input.LayoutOrder = TabItemLayout; TabItemLayout = TabItemLayout + 1
			Input.Title.Text = T["Name"]
			Input.TextBox.ClearTextOnFocus = T["ClearOnFocus"]
			Input.TextBox.PlaceholderText = string.sub(T["PlaceholderText"], 0, 35)
			
			if Input.TextBox.TextBounds.X > 40 then
				if string.len(Input.TextBox.Text) <= 35 then
					Input.TextBox.Size = UDim2.new(0, Input.TextBox.TextBounds.X + 4, 0, 20)
				end
			end
			
			Input.Title.Size = UDim2.new(1, -20 - Input.TextBox.AbsoluteSize.X, 1, -10)
			
			local UpdateInput = function()
				if T["Callback"] ~= nil then
					if OldInputValue ~= Input.TextBox.Text then 
						T["Callback"](Input.TextBox.Text)
						OldInputValue = Input.TextBox.Text 
					end
				end

				InputItem.Value = Input.TextBox.Text
			end
			
			Input.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
				if Input.TextBox.TextBounds.X > 40 then
					if string.len(Input.TextBox.Text) <= 35 then
						Input.TextBox.Size = UDim2.new(0, Input.TextBox.TextBounds.X + 4, 0, 20)
					end
				elseif Input.TextBox.Size.X.Offset > 40 then
					Input.TextBox.Size = UDim2.new(0, 40, 0, 20)
				end
				
				local FilteredString = ""
				local Filter = (T["Type"] == "int" and "%d") or (T["Type"] == "string" and "")
				for i = 1, #Input.TextBox.Text do
					if i == 36 then break end
					if string.find(Input.TextBox.Text:sub(i, i), Filter) then
						FilteredString = FilteredString .. Input.TextBox.Text:sub(i, i)
					end
				end

				Input.TextBox.Text = FilteredString
				
				Input.Title.Size = UDim2.new(1, -20 - Input.TextBox.AbsoluteSize.X, 1, -10)
			end)
			
			Input.TextBox.FocusLost:Connect(UpdateInput)
			
			--[[ DEPRECATED FUNCTION
			function InputItem:Set(Type)
				if table.find({"string", "int"}, Type) ~= nil then
					Input.ValueType.Value = Type
					InputItem["Type"] = Type
				end
			end
			]]
			
			return InputItem
		end

		return TabItem
	end
	
	return WindowItem
end

return Lib;
