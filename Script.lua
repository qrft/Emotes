--keybind to open is comma
--made by Gi#7331

local IsStudio = false

local ContextActionService = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")
local AvatarEditorService = game:GetService("AvatarEditorService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local Emotes = {}
local function AddEmote(name: string, id: IntValue, price: IntValue?)
	if not (name and id) then
		return
	end

	table.insert(Emotes, {
		["name"] = name,
		["id"] = id,
		["icon"] = "rbxthumb://type=Asset&id=".. id .."&w=150&h=150",
		["price"] = price or 0,
		["index"] = #Emotes + 1,
		["sort"] = {}
	})
end
local CurrentSort = "newestfirst"

local FavoriteOff = "rbxassetid://10651060677"
local FavoriteOn = "rbxassetid://10651061109"
local FavoritedEmotes = {}

local Settings = {
	ShowNumbers = true,
	ShowRandomButton = true,
	ShowFavoritesOnly = false,
	ShowFavoriteButton = true
}

-- File helpers -- robust across executors (Median, Xeno, Velocity, Synapse, KRNL, Fluxus, etc.)
-- All ops wrapped in pcall so a missing/broken API never crashes the script.

local function WriteFileFunc(path, data)
	if IsStudio then return true end
	local ok = pcall(function()
		if writefile then
			writefile(path, tostring(data))
		end
	end)
	return ok
end

local function ReadFileFunc(path)
	if IsStudio then return nil end
	local ok, result = pcall(function()
		if readfile then
			return readfile(path)
		end
		return nil
	end)
	if ok and type(result) == "string" then
		return result
	end
	return nil
end

local function IsFileFunc(path)
	if IsStudio then return false end
	-- 1) Try native isfile (most executors)
	if isfile then
		local ok, result = pcall(isfile, path)
		if ok then return result == true end
	end
	-- 2) Fallback: attempt a readfile and treat success as file-exists
	--    (covers Median and executors that skip isfile)
	local ok, result = pcall(function()
		if readfile then
			local content = readfile(path)
			return type(content) == "string"
		end
		return false
	end)
	return ok and result == true
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Emotes"
ScreenGui.DisplayOrder = 2
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false
ScreenGui.Enabled = false

local BackFrame = Instance.new("Frame")
BackFrame.Size = UDim2.new(0.9, 0, 0.5, 0)
BackFrame.AnchorPoint = Vector2.new(0.5, 0.5)
BackFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
BackFrame.SizeConstraint = Enum.SizeConstraint.RelativeYY
BackFrame.BackgroundTransparency = 1
BackFrame.BorderSizePixel = 0
BackFrame.Parent = ScreenGui

local EmoteName = Instance.new("TextLabel")
EmoteName.Name = "EmoteName"
EmoteName.TextScaled = true
EmoteName.AnchorPoint = Vector2.new(0.5, 0.5)
EmoteName.Position = UDim2.new(-0.1, 0, 0.5, 0)
EmoteName.Size = UDim2.new(0.2, 0, 0.2, 0)
EmoteName.SizeConstraint = Enum.SizeConstraint.RelativeYY
EmoteName.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
EmoteName.TextColor3 = Color3.new(1, 1, 1)
EmoteName.BorderSizePixel = 0
EmoteName.Parent = BackFrame

local Corner = Instance.new("UICorner")
Corner.Parent = EmoteName

local Loading = Instance.new("TextLabel", BackFrame)
Loading.AnchorPoint = Vector2.new(0.5, 0.5)
Loading.Text = "Loading..."
Loading.TextColor3 = Color3.new(1, 1, 1)
Loading.BackgroundColor3 = Color3.new(0, 0, 0)
Loading.TextScaled = true
Loading.BackgroundTransparency = 0.5
Loading.Size = UDim2.fromScale(0.2, 0.1)
Loading.Position = UDim2.fromScale(0.5, 0.2)
Corner:Clone().Parent = Loading

local Frame = Instance.new("ScrollingFrame")
Frame.Size = UDim2.new(1, 0, 1, 0)
Frame.CanvasSize = UDim2.new(0, 0, 0, 0)
Frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
Frame.ScrollingDirection = Enum.ScrollingDirection.Y
Frame.AnchorPoint = Vector2.new(0.5, 0.5)
Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
Frame.BackgroundTransparency = 1
Frame.ScrollBarThickness = 5
Frame.BorderSizePixel = 0
Frame.MouseLeave:Connect(function()
	EmoteName.Text = "Select an Emote"
end)
Frame.Parent = BackFrame

local Grid = Instance.new("UIGridLayout")
Grid.CellSize = UDim2.new(0.105, 0, 0, 0)
Grid.CellPadding = UDim2.new(0.006, 0, 0.006, 0)
Grid.SortOrder = Enum.SortOrder.LayoutOrder
Grid.Parent = Frame

local function SortEmotes()
	for i,Emote in pairs(Emotes) do
		local EmoteButton = Frame:FindFirstChild(Emote.id)
		if not EmoteButton then
			continue
		end
		local IsFavorited = table.find(FavoritedEmotes, Emote.id)
		if Settings.ShowFavoritesOnly and not IsFavorited then
			EmoteButton.Visible = false
		else
			EmoteButton.Visible = true
			EmoteButton.LayoutOrder = Emote.sort[CurrentSort] + ((IsFavorited and 0) or #Emotes)
		end
		if EmoteButton:FindFirstChild("number") then
			EmoteButton.number.Text = Emote.sort[CurrentSort]
		end
	end
end

local SettingsFrame = Instance.new("Frame")
SettingsFrame.Visible = false
SettingsFrame.BorderSizePixel = 0
SettingsFrame.Position = UDim2.new(1, 5, -0.125, 0)
SettingsFrame.Size = UDim2.new(0.25, 0, 0, 0)
SettingsFrame.AutomaticSize = Enum.AutomaticSize.Y
SettingsFrame.BackgroundTransparency = 1
Corner:Clone().Parent = SettingsFrame
SettingsFrame.Parent = BackFrame

local SettingsList = Instance.new("UIListLayout")
SettingsList.Padding = UDim.new(0.02, 0)
SettingsList.HorizontalAlignment = Enum.HorizontalAlignment.Center
SettingsList.VerticalAlignment = Enum.VerticalAlignment.Top
SettingsList.SortOrder = Enum.SortOrder.LayoutOrder
SettingsList.Parent = SettingsFrame

local function createsort(order, text, sort)
	local CreatedSort = Instance.new("TextButton")
	CreatedSort.SizeConstraint = Enum.SizeConstraint.RelativeXX
	CreatedSort.Size = UDim2.new(1, 0, 0.2, 0)
	CreatedSort.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	CreatedSort.LayoutOrder = order
	CreatedSort.TextColor3 = Color3.new(1, 1, 1)
	CreatedSort.Text = text
	CreatedSort.TextScaled = true
	CreatedSort.BorderSizePixel = 0
	Corner:Clone().Parent = CreatedSort
	CreatedSort.Parent = SettingsFrame
	CreatedSort.MouseButton1Click:Connect(function()
		CurrentSort = sort
		SortEmotes()
		-- persist sort choice alongside existing settings
		pcall(function()
			local raw = ReadFileFunc("EmoteSettings.txt") or "{}"
			local saved = HttpService:JSONDecode(raw)
			saved.CurrentSort = CurrentSort
			WriteFileFunc("EmoteSettings.txt", HttpService:JSONEncode(saved))
		end)
	end)
	return CreatedSort
end

local function CreateSettingToggle(order, text, settingKey)
	local ToggleButton = Instance.new("TextButton")
	ToggleButton.SizeConstraint = Enum.SizeConstraint.RelativeXX
	ToggleButton.Size = UDim2.new(1, 0, 0.2, 0)
	ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	ToggleButton.LayoutOrder = order
	ToggleButton.TextColor3 = Color3.new(1, 1, 1)
	ToggleButton.Text = text .. ": " .. (Settings[settingKey] and "ON" or "OFF")
	ToggleButton.TextScaled = true
	ToggleButton.BorderSizePixel = 0
	Corner:Clone().Parent = ToggleButton
	ToggleButton.Parent = SettingsFrame
	ToggleButton.MouseButton1Click:Connect(function()
		Settings[settingKey] = not Settings[settingKey]
		ToggleButton.Text = text .. ": " .. (Settings[settingKey] and "ON" or "OFF")
		local toSave = {}
		for k,v in pairs(Settings) do toSave[k] = v end
		toSave.CurrentSort = CurrentSort
		WriteFileFunc("EmoteSettings.txt", HttpService:JSONEncode(toSave))
		if settingKey == "ShowNumbers" then
			for _, child in pairs(Frame:GetChildren()) do
				if child:IsA("GuiButton") and child:FindFirstChild("number") then
					child.number.Visible = Settings.ShowNumbers
				end
			end
		elseif settingKey == "ShowRandomButton" then
			local randomBtn = Frame:FindFirstChild("Random")
			if randomBtn then
				randomBtn.Visible = Settings.ShowRandomButton
			end
		elseif settingKey == "ShowFavoritesOnly" then
			SortEmotes()
		elseif settingKey == "ShowFavoriteButton" then
			for _, child in pairs(Frame:GetChildren()) do
				if child:IsA("GuiButton") and child:FindFirstChild("favorite") then
					child.favorite.Visible = Settings.ShowFavoriteButton
				end
			end
		end
	end)
	return ToggleButton
end

createsort(1, "Newest First", "newestfirst")
createsort(2, "Oldest First", "oldestfirst")
createsort(3, "Alphabetically First", "alphabeticfirst")
createsort(4, "Alphabetically Last", "alphabeticlast")
createsort(5, "Highest Price", "highestprice")
createsort(6, "Lowest Price", "lowestprice")

local SettingsButton = Instance.new("TextButton")
SettingsButton.BorderSizePixel = 0
SettingsButton.AnchorPoint = Vector2.new(0.5, 0.5)
SettingsButton.Position = UDim2.new(0.925, -5, -0.075, 0)
SettingsButton.Size = UDim2.new(0.15, 0, 0.1, 0)
SettingsButton.TextScaled = true
SettingsButton.TextColor3 = Color3.new(1, 1, 1)
SettingsButton.BackgroundColor3 = Color3.new(0, 0, 0)
SettingsButton.BackgroundTransparency = 0.3
SettingsButton.Text = "Settings"
SettingsButton.MouseButton1Click:Connect(function()
	SettingsFrame.Visible = not SettingsFrame.Visible
end)
Corner:Clone().Parent = SettingsButton
SettingsButton.Parent = BackFrame

local CloseButton = Instance.new("TextButton")
CloseButton.BorderSizePixel = 0
CloseButton.AnchorPoint = Vector2.new(0.5, 0.5)
CloseButton.Position = UDim2.new(0.075, 0, -0.075, 0)
CloseButton.Size = UDim2.new(0.15, 0, 0.1, 0)
CloseButton.TextScaled = true
CloseButton.TextColor3 = Color3.new(1, 1, 1)
CloseButton.BackgroundColor3 = Color3.new(0, 0, 0)
CloseButton.BackgroundTransparency = 0.3
CloseButton.Text = "Close"
CloseButton.MouseButton1Click:Connect(function()
	ScreenGui.Enabled = false
end)
Corner:Clone().Parent = CloseButton
CloseButton.Parent = BackFrame

local SearchBar = Instance.new("TextBox")
SearchBar.BorderSizePixel = 0
SearchBar.AnchorPoint = Vector2.new(0.5, 0.5)
SearchBar.Position = UDim2.new(0.5, 0, -0.075, 0)
SearchBar.Size = UDim2.new(0.55, 0, 0.1, 0)
SearchBar.TextScaled = true
SearchBar.PlaceholderText = "Search"
SearchBar.TextColor3 = Color3.new(1, 1, 1)
SearchBar.BackgroundColor3 = Color3.new(0, 0, 0)
SearchBar.BackgroundTransparency = 0.3
SearchBar:GetPropertyChangedSignal("Text"):Connect(function()
	local text = SearchBar.Text:lower()
	local buttons = Frame:GetChildren()
	if text ~= text:sub(1,50) then
		SearchBar.Text = SearchBar.Text:sub(1,50)
		text = SearchBar.Text:lower()
	end
	if text ~= ""  then
		for i,button in pairs(buttons) do
			if button:IsA("GuiButton") then
				local name = button:GetAttribute("name"):lower()
				if name:match(text) then
					button.Visible = true
				else
					button.Visible = false
				end
			end
		end
	else
		for i,button in pairs(buttons) do
			if button:IsA("GuiButton") then
				if button.Name == "Random" then
					button.Visible = Settings.ShowRandomButton
				else
					button.Visible = true
				end
			end
		end
	end
end)
Corner:Clone().Parent = SearchBar
SearchBar.Parent = BackFrame

local function openemotes(name, state, input)
	if state == Enum.UserInputState.Begin then
		ScreenGui.Enabled = not ScreenGui.Enabled
	end
end

if IsStudio then
	ContextActionService:BindActionAtPriority(
		"Emote Menu",
		openemotes,
		true,
		2001,
		Enum.KeyCode.Comma
	)
else
	ContextActionService:BindCoreActionAtPriority(
		"Emote Menu",
		openemotes,
		true,
		2001,
		Enum.KeyCode.Comma
	)
end

local inputconnect
ScreenGui:GetPropertyChangedSignal("Enabled"):Connect(function()
	if ScreenGui.Enabled == true then
		EmoteName.Text = "Select an Emote"
		SearchBar.Text = ""
		SettingsFrame.Visible = false
		GuiService:SetEmotesMenuOpen(false)
		inputconnect = UserInputService.InputBegan:Connect(function(input, processed)
			if not processed then
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					ScreenGui.Enabled = false
				end
			end
		end)
	else
		inputconnect:Disconnect()
	end
end)

if not IsStudio then
	GuiService.EmotesMenuOpenChanged:Connect(function(isopen)
		if isopen then
			ScreenGui.Enabled = false
		end
	end)
end

GuiService.MenuOpened:Connect(function()
	ScreenGui.Enabled = false
end)

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local LocalPlayer = Players.LocalPlayer

if IsStudio then
	ScreenGui.Parent = LocalPlayer.PlayerGui
else
	--thanks inf yield
	local SynV3 = syn and DrawingImmediate
	if (not is_sirhurt_closure) and (not SynV3) and (syn and syn.protect_gui) then
		syn.protect_gui(ScreenGui)
		ScreenGui.Parent = CoreGui
	elseif get_hidden_gui or gethui then
		local hiddenUI = get_hidden_gui or gethui
		ScreenGui.Parent = hiddenUI()
	else
		ScreenGui.Parent = CoreGui
	end
end


local function SendNotification(title, text)
	if (not IsStudio) and syn and syn.toast_notification then
		syn.toast_notification({
			Type = ToastType.Error,
			Title = title,
			Content = text
		})
	else
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text
		})
	end
end

local function HumanoidPlayEmote(humanoid, name, id)
	if IsStudio then
		return humanoid:PlayEmote(name)
	else
		return humanoid:PlayEmoteAndGetAnimTrackById(id)
	end
end

local function PlayEmote(name: string, id: IntValue)
	local Humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	local Description = Humanoid and Humanoid:FindFirstChildOfClass("HumanoidDescription")
	if not Description then
		return
	end
	if LocalPlayer.Character.Humanoid.RigType ~= Enum.HumanoidRigType.R6 then
		local succ, err = pcall(function()
			HumanoidPlayEmote(Humanoid, name, id)
		end)
		if not succ then
			Description:AddEmote(name, id)
			HumanoidPlayEmote(Humanoid, name, id)
		end
	else
		SendNotification(
			"r6? lol",
			"you gotta be r15 dude"
		)
	end
end

local function WaitForChildOfClass(parent, class)
	local child = parent:FindFirstChildOfClass(class)
	while not child or child.ClassName ~= class do
		child = parent.ChildAdded:Wait()
	end
	return child
end

local params = CatalogSearchParams.new()
params.AssetTypes = {Enum.AvatarAssetType.EmoteAnimation}
params.SortType = Enum.CatalogSortType.RecentlyCreated
params.SortAggregation = Enum.CatalogSortAggregation.AllTime
params.IncludeOffSale = true
params.CreatorName = "Roblox"
params.Limit = 120

local function getCatalogPage()
	local success, catalogPage = pcall(function()
		return AvatarEditorService:SearchCatalog(params)
	end)
	if not success then
		task.wait(5)
		return getCatalogPage()
	end
	return catalogPage
end

local catalogPage = getCatalogPage()

local pages = {}

while true do
	local currentPage = catalogPage:GetCurrentPage()
	table.insert(pages, currentPage)
	if catalogPage.IsFinished then
		break
	end
	local function AdvanceToNextPage()
		local success = pcall(function()
			catalogPage:AdvanceToNextPageAsync()
		end)
		if not success then
			task.wait(5)
			return AdvanceToNextPage()
		end
	end
	AdvanceToNextPage()
end

local totalEmotes = {}
for _, page in pairs(pages) do
	for _, emote in pairs(page) do
		table.insert(totalEmotes, emote)
	end
end

for i, Emote in pairs(totalEmotes) do
	AddEmote(Emote.Name, Emote.Id, Emote.Price)
end

--unreleased emotes
AddEmote("Arm Wave", 5915773155)
AddEmote("Head Banging", 5915779725)
AddEmote("Face Calisthenics", 9830731012)
AddEmote("TWICE Feel Special", 14900153406)
AddEmote("Tommy - Archer", 13823339506)
AddEmote("Baby Queen - Face Frame", 14353421343)
AddEmote("Shattered", 124305244640379)
AddEmote("Falling Apart", 138768535525292)
AddEmote("Mime", 121558490761409)
AddEmote("Floor Rock Freeze - Tommy Hilfiger", 10214411646)
AddEmote("Jester", 124057206061364)
AddEmote("Fright Funk", 101675537943749)
AddEmote("Olivia Rodrigo Fall Back to Float", 15554016057)
AddEmote("tanging philly", 84028672169998)
AddEmote("Blue Top Rock", 102222849201801)
AddEmote("Shocked", 124594509997508)
AddEmote("Head Pat", 80157195300523)
AddEmote("Popular", 71302743123422)
AddEmote("Laugh It Up", 88524886385664)
AddEmote("Hands Up", 108894965141226)
AddEmote("Baby Queen - Bouncy Twirl", 14353423348)
AddEmote("Mii Height Swing", 95276923919374)
AddEmote("Slow Dembow", 73236219340808)
AddEmote("Yungblud Happier Jump", 15610015346)
AddEmote("Big Bad Wolf", 107112614895073)

--finished loading
Loading:Destroy()

--sorting options setup
table.sort(Emotes, function(a, b)
	return a.index < b.index
end)
for i,v in pairs(Emotes) do
	v.sort.newestfirst = i
end

table.sort(Emotes, function(a, b)
	return a.index > b.index
end)
for i,v in pairs(Emotes) do
	v.sort.oldestfirst = i
end

table.sort(Emotes, function(a, b)
	return a.name:lower() < b.name:lower()
end)
for i,v in pairs(Emotes) do
	v.sort.alphabeticfirst = i
end

table.sort(Emotes, function(a, b)
	return a.name:lower() > b.name:lower()
end)
for i,v in pairs(Emotes) do
	v.sort.alphabeticlast = i
end

table.sort(Emotes, function(a, b)
	return a.price < b.price
end)
for i,v in pairs(Emotes) do
	v.sort.lowestprice = i
end

table.sort(Emotes, function(a, b)
	return a.price > b.price
end)
for i,v in pairs(Emotes) do
	v.sort.highestprice = i
end



if not IsStudio then
	if IsFileFunc("EmoteSettings.txt") then
		pcall(function()
			local raw = ReadFileFunc("EmoteSettings.txt")
			if not raw then return end
			local loaded = HttpService:JSONDecode(raw)
			if loaded.ShowNumbers ~= nil then Settings.ShowNumbers = loaded.ShowNumbers end
			if loaded.ShowRandomButton ~= nil then Settings.ShowRandomButton = loaded.ShowRandomButton end
			if loaded.ShowFavoritesOnly ~= nil then Settings.ShowFavoritesOnly = loaded.ShowFavoritesOnly end
			if loaded.ShowFavoriteButton ~= nil then Settings.ShowFavoriteButton = loaded.ShowFavoriteButton end
			-- restore last used sort
			local validSorts = {
				newestfirst=true, oldestfirst=true,
				alphabeticfirst=true, alphabeticlast=true,
				lowestprice=true, highestprice=true
			}
			if loaded.CurrentSort and validSorts[loaded.CurrentSort] then
				CurrentSort = loaded.CurrentSort
			end
		end)
	else
		-- first run: write defaults (include CurrentSort)
		local defaults = {}
		for k,v in pairs(Settings) do defaults[k] = v end
		defaults.CurrentSort = CurrentSort
		WriteFileFunc("EmoteSettings.txt", HttpService:JSONEncode(defaults))
	end
end

-- Settings are now loaded before building toggles so button labels reflect saved state
CreateSettingToggle(100, "Show Numbers", "ShowNumbers")
CreateSettingToggle(101, "Show Random", "ShowRandomButton")
CreateSettingToggle(102, "Favorites Only", "ShowFavoritesOnly")
CreateSettingToggle(103, "Show Fav Button", "ShowFavoriteButton")

if not IsStudio then
	if IsFileFunc("FavoritedEmotes.txt") then
		if not pcall(function()
			FavoritedEmotes = HttpService:JSONDecode(ReadFileFunc("FavoritedEmotes.txt"))
		end) then
			FavoritedEmotes = {}
		end
	else
		WriteFileFunc("FavoritedEmotes.txt", HttpService:JSONEncode(FavoritedEmotes))
	end
	local UpdatedFavorites = {}
	for i,name in pairs(FavoritedEmotes) do
		if typeof(name) == "string" then
			for i,emote in pairs(Emotes) do
				if emote.name == name then
					table.insert(UpdatedFavorites, emote.id)
					break
				end
			end
		end
	end
	if #UpdatedFavorites ~= 0 then
		FavoritedEmotes = UpdatedFavorites
		WriteFileFunc("FavoritedEmotes.txt", HttpService:JSONEncode(FavoritedEmotes))
	end
end


local ButtonsBuilt = false

local function CharacterAdded(Character)
	if ButtonsBuilt then
		return
	end
	local Humanoid = WaitForChildOfClass(Character, "Humanoid")
	local Description = Humanoid:WaitForChild("HumanoidDescription", 5) or Instance.new("HumanoidDescription", Humanoid)
	local random = Instance.new("TextButton")
	local Ratio = Instance.new("UIAspectRatioConstraint")
	Ratio.AspectType = Enum.AspectType.ScaleWithParentSize
	Ratio.Parent = random
	random.LayoutOrder = 0
	random.TextColor3 = Color3.new(1, 1, 1)
	random.BorderSizePixel = 0
	random.BackgroundTransparency = 0.5
	random.BackgroundColor3 = Color3.new(0, 0, 0)
	random.TextScaled = true
	random.Name = "Random"
	random.Text = "Random"
	random:SetAttribute("name", "")
	random.Visible = Settings.ShowRandomButton
	Corner:Clone().Parent = random
	random.MouseButton1Click:Connect(function()
		local randomemote = Emotes[math.random(1, #Emotes)]
		PlayEmote(randomemote.name, randomemote.id)
	end)
	random.MouseEnter:Connect(function()
		EmoteName.Text = "Random"
	end)
	random.Parent = Frame
	for i,Emote in pairs(Emotes) do
		Description:AddEmote(Emote.name, Emote.id)
		local EmoteButton = Instance.new("ImageButton")
		local IsFavorited = table.find(FavoritedEmotes, Emote.id)
		EmoteButton.LayoutOrder = Emote.sort[CurrentSort] + ((IsFavorited and 0) or #Emotes)
		EmoteButton.Name = Emote.id
		EmoteButton:SetAttribute("name", Emote.name)
		Corner:Clone().Parent = EmoteButton
		EmoteButton.Image = Emote.icon
		EmoteButton.BackgroundTransparency = 0.5
		EmoteButton.BackgroundColor3 = Color3.new(0, 0, 0)
		EmoteButton.BorderSizePixel = 0
		Ratio:Clone().Parent = EmoteButton
		local EmoteNumber = Instance.new("TextLabel")
		EmoteNumber.Name = "number"
		EmoteNumber.TextScaled = true
		EmoteNumber.BackgroundTransparency = 1
		EmoteNumber.TextColor3 = Color3.new(1, 1, 1)
		EmoteNumber.BorderSizePixel = 0
		EmoteNumber.AnchorPoint = Vector2.new(0.5, 0.5)
		EmoteNumber.Size = UDim2.new(0.2, 0, 0.2, 0)
		EmoteNumber.Position = UDim2.new(0.1, 0, 0.9, 0)
		EmoteNumber.Text = Emote.sort[CurrentSort]
		EmoteNumber.TextXAlignment = Enum.TextXAlignment.Center
		EmoteNumber.TextYAlignment = Enum.TextYAlignment.Center
		local UIStroke = Instance.new("UIStroke")
		UIStroke.Transparency = 0.5
		UIStroke.Parent = EmoteNumber
		EmoteNumber.Visible = Settings.ShowNumbers
		EmoteNumber.Parent = EmoteButton
		EmoteButton.Parent = Frame
		EmoteButton.MouseButton1Click:Connect(function()
			PlayEmote(Emote.name, Emote.id)
		end)
		EmoteButton.MouseEnter:Connect(function()
			EmoteName.Text = Emote.name
		end)
		local Favorite = Instance.new("ImageButton")
		Favorite.Name = "favorite"
		if table.find(FavoritedEmotes, Emote.id) then
			Favorite.Image = FavoriteOn
		else
			Favorite.Image = FavoriteOff
		end
		Favorite.AnchorPoint = Vector2.new(0.5, 0.5)
		Favorite.Size = UDim2.new(0.2, 0, 0.2, 0)
		Favorite.Position = UDim2.new(0.9, 0, 0.9, 0)
		Favorite.BorderSizePixel = 0
		Favorite.BackgroundTransparency = 1
		Favorite.Visible = Settings.ShowFavoriteButton
		Favorite.Parent = EmoteButton
		Favorite.MouseButton1Click:Connect(function()
			local index = table.find(FavoritedEmotes, Emote.id)
			if index then
				table.remove(FavoritedEmotes, index)
				Favorite.Image = FavoriteOff
				EmoteButton.LayoutOrder = Emote.sort[CurrentSort] + #Emotes
			else
				table.insert(FavoritedEmotes, Emote.id)
				Favorite.Image = FavoriteOn
				EmoteButton.LayoutOrder = Emote.sort[CurrentSort]
			end
			WriteFileFunc("FavoritedEmotes.txt", HttpService:JSONEncode(FavoritedEmotes))
		end)
	end
	for i=1,9 do
		local EmoteButton = Instance.new("Frame")
		EmoteButton.LayoutOrder = 2147483647
		EmoteButton.Name = "filler"
		EmoteButton.BackgroundTransparency = 1
		EmoteButton.BorderSizePixel = 0
		Ratio:Clone().Parent = EmoteButton
		EmoteButton.Visible = true
		EmoteButton.Parent = Frame
		EmoteButton.MouseEnter:Connect(function()
			EmoteName.Text = "Select an Emote"
		end)
	end
	ButtonsBuilt = true
end

if LocalPlayer.Character then
	CharacterAdded(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(CharacterAdded)