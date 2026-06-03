local Google = {}
Google.__index = Google

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local function ConnectSignal(signal, callback)
	local connection = signal:Connect(callback)
	return connection
end

local function DisconnectAll(connections)
	for _, conn in ipairs(connections) do
		conn:Disconnect()
	end
	table.clear(connections)
end

local function Tween(instance, properties, time, easingStyle, easingDirection, callback)
	local tweenInfo = TweenInfo.new(
		time or 0.2,
		easingStyle or Enum.EasingStyle.Quad,
		easingDirection or Enum.EasingDirection.Out,
		0,
		false,
		0
	)
	local tween = TweenService:Create(instance, tweenInfo, properties)
	if callback then
		local connection
		connection = tween.Completed:Connect(function()
			connection:Disconnect()
			callback()
		end)
	end
	tween:Play()
	return tween
end

local function FormatColor3(color)
	if typeof(color) == "Color3" then
		return color
	elseif type(color) == "table" and color.R and color.G and color.B then
		return Color3.new(color.R, color.G, color.B)
	end
	return Color3.new(1,1,1)
end

local function SetThemeColor(object, property, themeColor)
	if typeof(themeColor) == "Color3" then
		object[property] = themeColor
	elseif type(themeColor) == "table" and themeColor.R then
		object[property] = Color3.new(themeColor.R, themeColor.G, themeColor.B)
	end
end

Google.Icons = {}
Google.IconAliases = {
	sword = "sword",
	shield = "shield",
	settings = "settings",
	user = "user",
	users = "users",
	star = "star",
	info = "info",
	warning = "triangle-alert",
	error = "circle-x",
	check = "check",
	search = "search",
	dropdown = "chevron-down",
	plus = "plus",
	minus = "minus",
	edit = "pencil",
	trash = "trash",
	link = "link",
	refresh = "refresh-cw",
	arrowLeft = "arrow-left",
	arrowRight = "arrow-right",
	arrowUp = "arrow-up",
	arrowDown = "arrow-down",
	notification = "bell",
	clock = "clock",
	eye = "eye",
	eyeOff = "eye-off",
	color = "palette",
	keyboard = "keyboard",
	sliders = "sliders-horizontal",
	toggle = "toggle-right",
	image = "image",
	file = "file",
	folder = "folder",
	download = "download",
	upload = "upload",
	cross = "x",
	hamburger = "menu",
	dots = "ellipsis",
	question = "circle-help",
	save = "save",
	external = "external-link",
}
Google.IconAssets = {
	home = {16898613509, 820, 147},
	sword = {16898613777, 710, 967},
	swords = {16898613777, 967, 759},
	shield = {16898613777, 869, 0},
	settings = {16898613777, 771, 257},
	["settings-2"] = {16898613777, 0, 771},
	user = {16898613869, 661, 869},
	users = {16898613869, 967, 98},
	star = {16898613777, 967, 147},
	info = {16898613509, 612, 869},
	["alert-triangle"] = {16898612629, 771, 98},
	["triangle-alert"] = {16898613869, 967, 0},
	["x-circle"] = {16898613869, 771, 955},
	["circle-x"] = {16898613044, 820, 306},
	check = {16898612819, 710, 869},
	search = {16898613699, 918, 857},
	["chevron-down"] = {16898612819, 196, 918},
	plus = {16898613699, 257, 918},
	minus = {16898613613, 771, 196},
	pencil = {16898613699, 820, 257},
	trash = {16898613869, 918, 514},
	["trash-2"] = {16898613869, 257, 918},
	link = {16898613509, 918, 453},
	["link-2"] = {16898613509, 967, 404},
	["refresh-cw"] = {16898613699, 404, 869},
	["refresh-ccw"] = {16898613699, 820, 453},
	["arrow-left"] = {16898612629, 98, 918},
	["arrow-right"] = {16898612629, 453, 820},
	["arrow-up"] = {16898612629, 967, 355},
	["arrow-down"] = {16898612629, 967, 49},
	bell = {16898612819, 820, 257},
	clock = {16898613044, 771, 661},
	eye = {16898613353, 771, 563},
	["eye-off"] = {16898613353, 820, 514},
	palette = {16898613613, 453, 918},
	keyboard = {16898613509, 453, 820},
	["sliders-horizontal"] = {16898613777, 820, 355},
	["sliders-vertical"] = {16898613777, 771, 404},
	["toggle-right"] = {16898613869, 820, 98},
	["toggle-left"] = {16898613869, 869, 49},
	image = {16898613509, 306, 918},
	file = {16898613353, 820, 661},
	folder = {16898613353, 404, 967},
	download = {16898613044, 820, 906},
	upload = {16898613869, 612, 869},
	x = {16898613869, 869, 906},
	menu = {16898613613, 49, 820},
	ellipsis = {16898613353, 771, 49},
	["circle-help"] = {16898613044, 820, 257},
	["help-circle"] = {16898613509, 563, 869},
	["external-link"] = {16898613353, 257, 820},
	save = {16898613699, 918, 453},
}

local function ResolveIconAsset(name)
	local key = tostring(name or "")
	key = Google.IconAliases[key] or key
	local asset = Google.IconAssets[key]
	if not asset then
		return nil
	end
	return {
		Name = key,
		Image = "rbxassetid://" .. tostring(asset[1]),
		ImageRectSize = Vector2.new(48, 48),
		ImageRectOffset = Vector2.new(asset[2], asset[3]),
	}
end

function Google.GetIcon(name)
	local asset = ResolveIconAsset(name)
	return asset and asset.Image or ""
end

function Google.CreateIcon(name, size, color, parent, properties)
	size = size or 18
	local asset = ResolveIconAsset(name)
	local icon
	if asset then
		icon = Instance.new("ImageLabel")
		icon.Name = "Icon"
		icon.BackgroundTransparency = 1
		icon.BorderSizePixel = 0
		icon.Image = asset.Image
		icon.ImageRectSize = asset.ImageRectSize
		icon.ImageRectOffset = asset.ImageRectOffset
		icon.ImageColor3 = color or Color3.new(1, 1, 1)
		icon.ScaleType = Enum.ScaleType.Fit
	else
		icon = Instance.new("TextLabel")
		icon.Name = "Icon"
		icon.BackgroundTransparency = 1
		icon.BorderSizePixel = 0
		icon.Text = "•"
		icon.Font = Enum.Font.GothamBold
		icon.TextSize = size
		icon.TextColor3 = color or Color3.new(1, 1, 1)
		icon.TextXAlignment = Enum.TextXAlignment.Center
		icon.TextYAlignment = Enum.TextYAlignment.Center
	end
	icon.Size = UDim2.new(0, size, 0, size)
	if properties then
		for property, value in pairs(properties) do
			icon[property] = value
		end
	end
	icon.Parent = parent
	return icon
end

function Google.SetIconColor(icon, color)
	if not icon then return end
	if icon:IsA("ImageLabel") or icon:IsA("ImageButton") then
		icon.ImageColor3 = color
	elseif icon:IsA("TextLabel") or icon:IsA("TextButton") then
		icon.TextColor3 = color
	end
end

Google.Themes = {}
Google.ActiveTheme = nil

local defaultThemes = {
	Light = {
		Background = Color3.fromRGB(255, 255, 255),
		Surface = Color3.fromRGB(245, 245, 245),
		Primary = Color3.fromRGB(59, 130, 246),
		PrimaryLight = Color3.fromRGB(219, 234, 254),
		Text = Color3.fromRGB(17, 24, 39),
		TextSecondary = Color3.fromRGB(107, 114, 128),
		Border = Color3.fromRGB(209, 213, 219),
		Hover = Color3.fromRGB(243, 244, 246),
		ToggleOn = Color3.fromRGB(59, 130, 246),
		ToggleOff = Color3.fromRGB(209, 213, 219),
		SliderFill = Color3.fromRGB(59, 130, 246),
		SliderBackground = Color3.fromRGB(229, 231, 235),
		DropdownMenu = Color3.fromRGB(255, 255, 255),
		InputBackground = Color3.fromRGB(255, 255, 255),
		InputBorder = Color3.fromRGB(209, 213, 219),
		Notification = Color3.fromRGB(31, 41, 55),
		NotificationText = Color3.fromRGB(255, 255, 255),
		Shadow = Color3.fromRGB(0, 0, 0),
		Accent = Color3.fromRGB(245, 158, 11),
		Danger = Color3.fromRGB(239, 68, 68),
	},
	Dark = {
		Background = Color3.fromRGB(30, 30, 30),
		Surface = Color3.fromRGB(40, 40, 40),
		Primary = Color3.fromRGB(96, 165, 250),
		PrimaryLight = Color3.fromRGB(30, 41, 59),
		Text = Color3.fromRGB(229, 231, 235),
		TextSecondary = Color3.fromRGB(156, 163, 175),
		Border = Color3.fromRGB(55, 65, 81),
		Hover = Color3.fromRGB(55, 65, 81),
		ToggleOn = Color3.fromRGB(96, 165, 250),
		ToggleOff = Color3.fromRGB(75, 85, 99),
		SliderFill = Color3.fromRGB(96, 165, 250),
		SliderBackground = Color3.fromRGB(55, 65, 81),
		DropdownMenu = Color3.fromRGB(40, 40, 40),
		InputBackground = Color3.fromRGB(55, 65, 81),
		InputBorder = Color3.fromRGB(75, 85, 99),
		Notification = Color3.fromRGB(17, 24, 39),
		NotificationText = Color3.fromRGB(255, 255, 255),
		Shadow = Color3.fromRGB(0, 0, 0),
		Accent = Color3.fromRGB(245, 158, 11),
		Danger = Color3.fromRGB(239, 68, 68),
	},
	Midnight = {
		Background = Color3.fromRGB(15, 15, 15),
		Surface = Color3.fromRGB(22, 22, 22),
		Primary = Color3.fromRGB(129, 140, 248),
		PrimaryLight = Color3.fromRGB(55, 48, 163),
		Text = Color3.fromRGB(243, 244, 246),
		TextSecondary = Color3.fromRGB(156, 163, 175),
		Border = Color3.fromRGB(38, 38, 38),
		Hover = Color3.fromRGB(38, 38, 38),
		ToggleOn = Color3.fromRGB(129, 140, 248),
		ToggleOff = Color3.fromRGB(64, 64, 64),
		SliderFill = Color3.fromRGB(129, 140, 248),
		SliderBackground = Color3.fromRGB(38, 38, 38),
		DropdownMenu = Color3.fromRGB(22, 22, 22),
		InputBackground = Color3.fromRGB(38, 38, 38),
		InputBorder = Color3.fromRGB(64, 64, 64),
		Notification = Color3.fromRGB(10, 10, 10),
		NotificationText = Color3.fromRGB(255, 255, 255),
		Shadow = Color3.fromRGB(0, 0, 0),
		Accent = Color3.fromRGB(245, 158, 11),
		Danger = Color3.fromRGB(239, 68, 68),
	},
	Professional = {
		Background = Color3.fromRGB(240, 240, 240),
		Surface = Color3.fromRGB(255, 255, 255),
		Primary = Color3.fromRGB(0, 82, 204),
		PrimaryLight = Color3.fromRGB(222, 235, 255),
		Text = Color3.fromRGB(23, 43, 77),
		TextSecondary = Color3.fromRGB(94, 108, 132),
		Border = Color3.fromRGB(193, 199, 208),
		Hover = Color3.fromRGB(235, 236, 240),
		ToggleOn = Color3.fromRGB(0, 82, 204),
		ToggleOff = Color3.fromRGB(193, 199, 208),
		SliderFill = Color3.fromRGB(0, 82, 204),
		SliderBackground = Color3.fromRGB(221, 225, 230),
		DropdownMenu = Color3.fromRGB(255, 255, 255),
		InputBackground = Color3.fromRGB(255, 255, 255),
		InputBorder = Color3.fromRGB(193, 199, 208),
		Notification = Color3.fromRGB(23, 43, 77),
		NotificationText = Color3.fromRGB(255, 255, 255),
		Shadow = Color3.fromRGB(0, 0, 0),
		Accent = Color3.fromRGB(255, 171, 0),
		Danger = Color3.fromRGB(222, 53, 11),
	},
}

function Google.RegisterTheme(name, theme)
	Google.Themes[name] = theme
end

function Google.SetTheme(name)
	if Google.Themes[name] then
		Google.ActiveTheme = name
		Google.Theme = Google.Themes[name]
		if Google.Windows then
			for _, window in ipairs(Google.Windows) do
				window:ApplyTheme()
			end
		end
	end
end

function Google.GetTheme()
	return Google.ActiveTheme, Google.Theme
end

for name, theme in pairs(defaultThemes) do
	Google.RegisterTheme(name, theme)
end

Google.SetTheme("Professional")

local UIElement = {}
UIElement.__index = UIElement

function UIElement.new()
	local self = setmetatable({}, UIElement)
	self._connections = {}
	return self
end

function UIElement:Connect(signal, callback)
	local conn = ConnectSignal(signal, callback)
	table.insert(self._connections, conn)
	return conn
end

function UIElement:Destroy()
	DisconnectAll(self._connections)
	if self.Instance then
		self.Instance:Destroy()
	end
end

Google.Windows = {}
local Window = setmetatable({}, {__index = UIElement})
Window.__index = Window

function Google:CreateWindow(config)
	config = config or {}
	local self = setmetatable(UIElement.new(), Window)
	self.Title = config.Title or "Google UI"
	self.Subtitle = config.Subtitle or nil
	self.Icon = config.Icon or nil
	self.Tabs = {}
	self.ActiveTab = nil
	self.Connections = {}
	self.Instance = nil
	self.Gui = nil

	local gui = Instance.new("ScreenGui")
	gui.Name = "GoogleWindow_" .. self.Title
	gui.Parent = (config.Parent or game:GetService("CoreGui"))
	self.Gui = gui

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "Main"
	mainFrame.Size = UDim2.new(0, 580, 0, 420)
	mainFrame.Position = UDim2.new(0.5, -290, 0.5, -210)
	mainFrame.AnchorPoint = Vector2.new(0, 0)
	mainFrame.BorderSizePixel = 0
	mainFrame.BackgroundColor3 = Google.Theme.Surface
	mainFrame.ClipsDescendants = false
	self.Instance = mainFrame
	mainFrame.Parent = gui

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 10)
	mainCorner.Parent = mainFrame

	local mainStroke = Instance.new("UIStroke")
	mainStroke.Thickness = 1
	mainStroke.Color = Google.Theme.Border
	mainStroke.Transparency = 0.2
	mainStroke.Parent = mainFrame
	self.MainStroke = mainStroke

	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://6015897843"
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(49, 49, 450, 450)
	shadow.Size = UDim2.new(1, 20, 1, 20)
	shadow.Position = UDim2.new(0, -10, 0, -10)
	shadow.ImageColor3 = Google.Theme.Shadow
	shadow.ImageTransparency = 0.7
	shadow.Parent = mainFrame

	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 36)
	titleBar.BackgroundColor3 = Google.Theme.Surface
	titleBar.BorderSizePixel = 0
	titleBar.Parent = mainFrame

	local titleContainer = Instance.new("Frame")
	titleContainer.Size = UDim2.new(1, -80, 1, 0)
	titleContainer.Position = UDim2.new(0, 12, 0, 0)
	titleContainer.BackgroundTransparency = 1
	titleContainer.Parent = titleBar

	local iconLabel
	if self.Icon then
		iconLabel = Google.CreateIcon(self.Icon, 18, Google.Theme.Primary, titleContainer, {
			Name = "Icon",
			Position = UDim2.new(0, 0, 0.5, -9),
		})
	end

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Text = self.Title
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 14
	titleLabel.Size = UDim2.new(1, iconLabel and -24 or 0, 1, 0)
	titleLabel.Position = UDim2.new(0, iconLabel and 24 or 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Google.Theme.Text
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleContainer

	if self.Subtitle then
		titleLabel.Size = UDim2.new(1, iconLabel and -24 or 0, 0.6, 0)
		local subtitleLabel = Instance.new("TextLabel")
		subtitleLabel.Name = "Subtitle"
		subtitleLabel.Text = self.Subtitle
		subtitleLabel.Font = Enum.Font.Gotham
		subtitleLabel.TextSize = 11
		subtitleLabel.Size = UDim2.new(1, 0, 0.4, 0)
		subtitleLabel.Position = UDim2.new(0, iconLabel and 24 or 0, 0.6, 0)
		subtitleLabel.BackgroundTransparency = 1
		subtitleLabel.TextColor3 = Google.Theme.TextSecondary
		subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
		subtitleLabel.Parent = titleContainer
	end

	local windowControls = Instance.new("Frame")
	windowControls.Size = UDim2.new(0, 70, 1, 0)
	windowControls.Position = UDim2.new(1, -70, 0, 0)
	windowControls.BackgroundTransparency = 1
	windowControls.Parent = titleBar

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "Close"
	closeButton.Text = "✕"
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 14
	closeButton.Size = UDim2.new(0, 30, 1, 0)
	closeButton.Position = UDim2.new(1, -30, 0, 0)
	closeButton.BackgroundColor3 = Google.Theme.Surface
	closeButton.BorderSizePixel = 0
	closeButton.TextColor3 = Google.Theme.TextSecondary
	closeButton.Parent = windowControls
	self:Connect(closeButton.MouseButton1Click, function() self:Destroy() end)
	self:Connect(closeButton.MouseEnter, function()
		Tween(closeButton, {BackgroundColor3 = Google.Theme.Danger, TextColor3 = Color3.new(1,1,1)}, 0.15)
	end)
	self:Connect(closeButton.MouseLeave, function()
		Tween(closeButton, {BackgroundColor3 = Google.Theme.Surface, TextColor3 = Google.Theme.TextSecondary}, 0.15)
	end)

	local minimizeButton = Instance.new("TextButton")
	minimizeButton.Name = "Minimize"
	minimizeButton.Text = "─"
	minimizeButton.Font = Enum.Font.GothamBold
	minimizeButton.TextSize = 16
	minimizeButton.Size = UDim2.new(0, 30, 1, 0)
	minimizeButton.Position = UDim2.new(1, -60, 0, 0)
	minimizeButton.BackgroundColor3 = Google.Theme.Surface
	minimizeButton.BorderSizePixel = 0
	minimizeButton.TextColor3 = Google.Theme.TextSecondary
	minimizeButton.Parent = windowControls
	self.Minimized = false
	self:Connect(minimizeButton.MouseButton1Click, function()
		if self.Minimized then
			self:Restore()
		else
			self:Minimize()
		end
	end)
	self:Connect(minimizeButton.MouseEnter, function()
		Tween(minimizeButton, {BackgroundColor3 = Google.Theme.Hover, TextColor3 = Google.Theme.Text}, 0.15)
	end)
	self:Connect(minimizeButton.MouseLeave, function()
		if not self.Minimized then
			Tween(minimizeButton, {BackgroundColor3 = Google.Theme.Surface, TextColor3 = Google.Theme.TextSecondary}, 0.15)
		end
	end)

	local dragging = false
	local dragStart, startPos
	self:Connect(titleBar.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = mainFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	self:Connect(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			mainFrame.Position = newPos
		end
	end)

	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "Content"
	contentFrame.Size = UDim2.new(1, 0, 1, -36)
	contentFrame.Position = UDim2.new(0, 0, 0, 36)
	contentFrame.BackgroundTransparency = 1
	contentFrame.ClipsDescendants = true
	self.ContentFrame = contentFrame
	contentFrame.Parent = mainFrame

	local tabBar = Instance.new("Frame")
	tabBar.Name = "TabBar"
	tabBar.Size = UDim2.new(0, 140, 1, 0)
	tabBar.BackgroundColor3 = Google.Theme.Surface
	tabBar.BorderSizePixel = 0
	tabBar.Parent = contentFrame

	local tabList = Instance.new("ScrollingFrame")
	tabList.Name = "TabList"
	tabList.Size = UDim2.new(1, -2, 1, 0)
	tabList.CanvasSize = UDim2.new(0, 0, 0, 0)
	tabList.ScrollBarThickness = 0
	tabList.BackgroundTransparency = 1
	tabList.BorderSizePixel = 0
	tabList.ScrollingDirection = Enum.ScrollingDirection.Y
	tabList.VerticalScrollBarInset = Enum.ScrollBarInset.Always
	tabList.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
	tabList.Parent = tabBar

	local tabListLayout = Instance.new("UIListLayout")
	tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabListLayout.Padding = UDim.new(0, 0)
	tabListLayout.Parent = tabList

	self.TabListFrame = tabList
	self.TabListLayout = tabListLayout
	self.TabButtons = {}

	local pageContainer = Instance.new("Frame")
	pageContainer.Name = "PageContainer"
	pageContainer.Size = UDim2.new(1, -142, 1, 0)
	pageContainer.Position = UDim2.new(0, 142, 0, 0)
	pageContainer.BackgroundColor3 = Google.Theme.Background
	pageContainer.BorderSizePixel = 0
	pageContainer.ClipsDescendants = true
	self.PageContainer = pageContainer
	pageContainer.Parent = contentFrame

	local separator = Instance.new("Frame")
	separator.Name = "Separator"
	separator.Size = UDim2.new(0, 1, 1, 0)
	separator.Position = UDim2.new(0, 139, 0, 0)
	separator.BackgroundColor3 = Google.Theme.Border
	separator.BorderSizePixel = 0
	separator.Parent = contentFrame

	table.insert(Google.Windows, self)
	self:ApplyTheme()

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MinSize = Vector2.new(500, 300)
	sizeConstraint.Parent = mainFrame

	return self
end

function Window:ApplyTheme()
	local theme = Google.Theme
	if not self.Instance then return end
	self.Instance.BackgroundColor3 = theme.Surface
	if self.MainStroke then
		self.MainStroke.Color = theme.Border
	end
	local titleBar = self.Instance:FindFirstChild("TitleBar")
	if titleBar then
		titleBar.BackgroundColor3 = theme.Surface
	end
		for _, tab in ipairs(self.Tabs) do
		tab:ApplyTheme()
	end
	local shadow = self.Instance:FindFirstChild("Shadow")
	if shadow then
		shadow.ImageColor3 = theme.Shadow
	end
	local contentFrame = self.Instance:FindFirstChild("Content")
	if contentFrame then
		local tabBar = contentFrame:FindFirstChild("TabBar")
		if tabBar then tabBar.BackgroundColor3 = theme.Surface end
		local separator = contentFrame:FindFirstChild("Separator")
		if separator then separator.BackgroundColor3 = theme.Border end
		local pageContainer = contentFrame:FindFirstChild("PageContainer")
		if pageContainer then pageContainer.BackgroundColor3 = theme.Background end
	end
end

function Window:Destroy()
	DisconnectAll(self._connections)
	if self.Instance then
		self.Instance:Destroy()
	end
	if self.Gui then
		self.Gui:Destroy()
	end
	for i, w in ipairs(Google.Windows) do
		if w == self then
			table.remove(Google.Windows, i)
			break
		end
	end
	for _, tab in ipairs(self.Tabs) do
		tab:Destroy()
	end
end

function Window:Minimize()
	if self.Minimized then return end
	self.Minimized = true
	local mainFrame = self.Instance
	local content = mainFrame:FindFirstChild("Content")
	if content then
		content.Visible = false
		Tween(mainFrame, {Size = UDim2.new(0, mainFrame.Size.X.Offset, 0, 36)}, 0.2)
	end
end

function Window:Restore()
	if not self.Minimized then return end
	self.Minimized = false
	local mainFrame = self.Instance
	Tween(mainFrame, {Size = UDim2.new(0, 580, 0, 420)}, 0.2)
	local content = mainFrame:FindFirstChild("Content")
	if content then
		content.Visible = true
	end
end

function Window:Hide()
	self.Gui.Enabled = false
end

function Window:Show()
	self.Gui.Enabled = true
end

function Window:CreateTab(config)
	local tab = Tab.new(self, config)
	table.insert(self.Tabs, tab)
	if #self.Tabs == 1 then
		tab:Select(true)
	end
	return tab
end

Tab = setmetatable({}, {__index = UIElement})
Tab.__index = Tab

function Tab.new(window, config)
	local self = setmetatable(UIElement.new(), Tab)
	self.Window = window
	self.Name = config.Name or "Tab"
	self.Icon = config.Icon
	self.Sections = {}
	self.Button = nil
	self.Page = nil

	local button = Instance.new("TextButton")
	button.Name = self.Name
	button.Size = UDim2.new(1, 0, 0, 36)
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.Font = Enum.Font.Gotham
	button.TextSize = 13
	button.Text = ""
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.Parent = window.TabListFrame

	local iconLabel
	if self.Icon then
		iconLabel = Google.CreateIcon(self.Icon, 16, Google.Theme.TextSecondary, button, {
			Position = UDim2.new(0, 12, 0.5, -8),
		})
	end

	local textLabel = Instance.new("TextLabel")
	textLabel.Text = self.Name
	textLabel.Font = Enum.Font.Gotham
	textLabel.TextSize = 13
	textLabel.Size = UDim2.new(1, iconLabel and -32 or -12, 1, 0)
	textLabel.Position = UDim2.new(0, iconLabel and 32 or 12, 0, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Google.Theme.TextSecondary
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.Parent = button

	self.Button = button
	self.IconLabel = iconLabel
	self.TextLabel = textLabel

	local indicator = Instance.new("Frame")
	indicator.Size = UDim2.new(0, 2, 1, 0)
	indicator.BackgroundColor3 = Google.Theme.Primary
	indicator.BorderSizePixel = 0
	indicator.Visible = false
	indicator.Parent = button
	self.Indicator = indicator

	local page = Instance.new("ScrollingFrame")
	page.Name = "Page_" .. self.Name
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 3
	page.ScrollBarImageColor3 = Google.Theme.Border
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.ScrollingDirection = Enum.ScrollingDirection.Y
	page.VerticalScrollBarInset = Enum.ScrollBarInset.Always
	page.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
	page.Visible = false
	page.Parent = window.PageContainer

	local pageLayout = Instance.new("UIListLayout")
	pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
	pageLayout.Padding = UDim.new(0, 8)
	pageLayout.Parent = page

	local pagePadding = Instance.new("UIPadding")
	pagePadding.PaddingTop = UDim.new(0, 12)
	pagePadding.PaddingBottom = UDim.new(0, 12)
	pagePadding.PaddingLeft = UDim.new(0, 12)
	pagePadding.PaddingRight = UDim.new(0, 12)
	pagePadding.Parent = page

	self.Page = page
	self.PageLayout = pageLayout

	self:Connect(button.MouseButton1Click, function()
		window:SelectTab(self)
	end)
	self:Connect(button.MouseEnter, function()
		if window.ActiveTab ~= self then
			Tween(button, {BackgroundTransparency = 0.9}, 0.15)
		end
	end)
	self:Connect(button.MouseLeave, function()
		if window.ActiveTab ~= self then
			Tween(button, {BackgroundTransparency = 1}, 0.15)
		end
	end)

	window.TabButtons[self] = button
	if window.TabListFrame and window.TabListLayout then
		window.TabListFrame.CanvasSize = UDim2.new(0, 0, 0, window.TabListLayout.AbsoluteContentSize.Y)
	end

	return self
end

function Tab:ApplyTheme()
	if self.Button then
		self.TextLabel.TextColor3 = Google.Theme.TextSecondary
		if self.IconLabel then
			Google.SetIconColor(self.IconLabel, Google.Theme.TextSecondary)
		end
		if self.Indicator then
			self.Indicator.BackgroundColor3 = Google.Theme.Primary
		end
		if self.Window.ActiveTab == self then
			self.Button.BackgroundColor3 = Google.Theme.PrimaryLight
			self.TextLabel.TextColor3 = Google.Theme.Primary
			if self.IconLabel then Google.SetIconColor(self.IconLabel, Google.Theme.Primary) end
		end
	end
	if self.Page then
		self.Page.ScrollBarImageColor3 = Google.Theme.Border
	end
	for _, section in ipairs(self.Sections) do
		section:ApplyTheme()
	end
end

function Tab:Select(selected)
	local window = self.Window
	if window.ActiveTab == self then return end
	if window.ActiveTab then
		window.ActiveTab:Select(false)
	end
	window.ActiveTab = self
	self.Button.BackgroundColor3 = Google.Theme.PrimaryLight
	self.TextLabel.TextColor3 = Google.Theme.Primary
	if self.IconLabel then Google.SetIconColor(self.IconLabel, Google.Theme.Primary) end
	self.Indicator.Visible = true
	Tween(self.Indicator, {BackgroundTransparency = 0}, 0.15)
	self.Page.Visible = true
end

function Tab:Deselect()
	self.Button.BackgroundTransparency = 1
	self.TextLabel.TextColor3 = Google.Theme.TextSecondary
	if self.IconLabel then Google.SetIconColor(self.IconLabel, Google.Theme.TextSecondary) end
	self.Indicator.Visible = false
	self.Page.Visible = false
end

function Tab:CreateSection(config)
	local section = Section.new(self, config)
	table.insert(self.Sections, section)
	return section
end

function Tab:Destroy()
	DisconnectAll(self._connections)
	if self.Button then self.Button:Destroy() end
	if self.Page then self.Page:Destroy() end
end

function Window:SelectTab(tab)
	if self.ActiveTab == tab then return end
	if self.ActiveTab then
		self.ActiveTab:Deselect()
	end
	tab:Select()
end

Section = setmetatable({}, {__index = UIElement})
Section.__index = Section

function Section.new(tab, config)
	local self = setmetatable(UIElement.new(), Section)
	self.Tab = tab
	self.Name = config.Name or "Section"
	self.Description = config.Description or nil
	self.Collapsed = config.Collapsed or false
	self.Controls = {}

	local sectionFrame = Instance.new("Frame")
	sectionFrame.Name = "Section_" .. self.Name
	sectionFrame.Size = UDim2.new(1, -4, 0, 0)
	sectionFrame.BackgroundColor3 = Google.Theme.Surface
	sectionFrame.BorderSizePixel = 0
	sectionFrame.LayoutOrder = #tab.Sections
	self.Instance = sectionFrame
	sectionFrame.Parent = tab.Page

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = sectionFrame

	local header = Instance.new("TextButton")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 30)
	header.BackgroundTransparency = 1
	header.BorderSizePixel = 0
	header.Text = ""
	header.Parent = sectionFrame
	self.Header = header

	local toggleIcon = Instance.new("TextLabel")
	toggleIcon.Name = "ToggleIcon"
	toggleIcon.Text = self.Collapsed and "▶" or "▼"
	toggleIcon.Font = Enum.Font.SourceSans
	toggleIcon.TextSize = 10
	toggleIcon.Size = UDim2.new(0, 16, 1, 0)
	toggleIcon.Position = UDim2.new(0, 8, 0, 0)
	toggleIcon.BackgroundTransparency = 1
	toggleIcon.TextColor3 = Google.Theme.TextSecondary
	toggleIcon.TextXAlignment = Enum.TextXAlignment.Center
	toggleIcon.Parent = header

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Text = self.Name
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 13
	titleLabel.Size = UDim2.new(1, -30, 1, 0)
	titleLabel.Position = UDim2.new(0, 28, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Google.Theme.Text
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = header

	if self.Description then
		titleLabel.Size = UDim2.new(1, -30, 0, 18)
		local descLabel = Instance.new("TextLabel")
		descLabel.Text = self.Description
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextSize = 11
		descLabel.Size = UDim2.new(1, -30, 0, 12)
		descLabel.Position = UDim2.new(0, 28, 0, 18)
		descLabel.BackgroundTransparency = 1
		descLabel.TextColor3 = Google.Theme.TextSecondary
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.Parent = header
		self.DescLabel = descLabel
	end

	local controlContainer = Instance.new("Frame")
	controlContainer.Name = "Controls"
	controlContainer.Size = UDim2.new(1, 0, 0, 0)
	controlContainer.Position = UDim2.new(0, 0, 0, 30)
	controlContainer.BackgroundTransparency = 1
	controlContainer.BorderSizePixel = 0
	controlContainer.ClipsDescendants = false
	self.ControlContainer = controlContainer
	controlContainer.Parent = sectionFrame

	local controlList = Instance.new("UIListLayout")
	controlList.SortOrder = Enum.SortOrder.LayoutOrder
	controlList.Padding = UDim.new(0, 2)
	controlList.Parent = controlContainer

	self.ControlList = controlList
	self.ToggleIcon = toggleIcon
	self.TitleLabel = titleLabel

	self:Connect(header.MouseButton1Click, function()
		self:ToggleCollapse()
	end)

	if self.Collapsed then
		controlContainer.Visible = false
		sectionFrame.Size = UDim2.new(1, -4, 0, 30)
	end

	self:RefreshSize()

	self:Connect(controlList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		self:RefreshSize()
	end)

	return self
end

function Section:ToggleCollapse()
	self.Collapsed = not self.Collapsed
	if self.Collapsed then
		self.ControlContainer.Visible = false
		self.ToggleIcon.Text = "▶"
		self.Instance.Size = UDim2.new(1, -4, 0, 30)
	else
		self.ControlContainer.Visible = true
		self.ToggleIcon.Text = "▼"
		self:RefreshSize()
	end
end

function Section:RefreshSize()
	if self.Collapsed then return end
	local contentHeight = self.ControlList.AbsoluteContentSize.Y + 34
	self.Instance.Size = UDim2.new(1, -4, 0, contentHeight)
	self.Tab.Page.CanvasSize = UDim2.new(0,0,0,self.Tab.PageLayout.AbsoluteContentSize.Y + 16)
end

function Section:ApplyTheme()
	self.Instance.BackgroundColor3 = Google.Theme.Surface
	self.ToggleIcon.TextColor3 = Google.Theme.TextSecondary
	self.TitleLabel.TextColor3 = Google.Theme.Text
	if self.DescLabel then
		self.DescLabel.TextColor3 = Google.Theme.TextSecondary
	end
	for _, control in ipairs(self.Controls) do
		if control.ApplyTheme then
			control:ApplyTheme()
		end
	end
end

function Section:CreateButton(config)
	return Button.new(self, config)
end
function Section:CreateToggle(config)
	return Toggle.new(self, config)
end
function Section:CreateSlider(config)
	return Slider.new(self, config)
end
function Section:CreateDropdown(config)
	return Dropdown.new(self, config)
end
function Section:CreateTextbox(config)
	return Textbox.new(self, config)
end
function Section:CreateKeybind(config)
	return Keybind.new(self, config)
end
function Section:CreateColorPicker(config)
	return ColorPicker.new(self, config)
end
function Section:CreateLabel(config)
	return Label.new(self, config)
end
function Section:CreateParagraph(config)
	return Paragraph.new(self, config)
end
function Section:CreateDivider(config)
	return Divider.new(self, config)
end

local Control = setmetatable({}, {__index = UIElement})
Control.__index = Control

function Control.new(section)
	local self = setmetatable(UIElement.new(), Control)
	self.Section = section
	self.Instance = nil
	table.insert(section.Controls, self)
	return self
end

function Control:RefreshSection()
	self.Section:RefreshSize()
end

Button = setmetatable({}, {__index = Control})
Button.__index = Button

function Button.new(section, config)
	local self = setmetatable(Control.new(section), Button)
	self.Text = config.Name or "Button"
	self.Description = config.Description
	self.Icon = config.Icon
	self.Callback = config.Callback or function() end

	local buttonFrame = Instance.new("TextButton")
	buttonFrame.Name = "Button"
	buttonFrame.Size = UDim2.new(1, -16, 0, 36)
	buttonFrame.Position = UDim2.new(0, 8, 0, 0)
	buttonFrame.BackgroundColor3 = Google.Theme.Primary
	buttonFrame.BorderSizePixel = 0
	buttonFrame.Text = ""
	buttonFrame.LayoutOrder = #section.Controls
	buttonFrame.Parent = section.ControlContainer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = buttonFrame

	local iconLabel
	if self.Icon then
		iconLabel = Google.CreateIcon(self.Icon, 18, Color3.new(1, 1, 1), buttonFrame, {
			Position = UDim2.new(0, 12, 0.5, -9),
		})
	end

	local textLabel = Instance.new("TextLabel")
	textLabel.Text = self.Text
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextSize = 13
	textLabel.Size = UDim2.new(1, iconLabel and -44 or -24, 1, 0)
	textLabel.Position = UDim2.new(0, iconLabel and 36 or 12, 0, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Color3.new(1,1,1)
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.Parent = buttonFrame

	if self.Description then
		textLabel.Size = UDim2.new(1, iconLabel and -44 or -24, 0, 18)
		textLabel.Position = UDim2.new(0, iconLabel and 36 or 12, 0, 2)
		local descLabel = Instance.new("TextLabel")
		descLabel.Text = self.Description
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextSize = 11
		descLabel.Size = UDim2.new(1, 0, 0, 14)
		descLabel.Position = UDim2.new(0, iconLabel and 36 or 12, 0, 20)
		descLabel.BackgroundTransparency = 1
		descLabel.TextColor3 = Color3.new(1,1,1)
		descLabel.TextTransparency = 0.3
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.Parent = buttonFrame
	end

	self.Instance = buttonFrame
	self.TextLabel = textLabel

	self:Connect(buttonFrame.MouseButton1Click, function()
		self.Callback()
	end)
	self:Connect(buttonFrame.MouseEnter, function()
		Tween(buttonFrame, {BackgroundColor3 = Google.Theme.Primary:lerp(Color3.new(0,0,0), 0.1)}, 0.15)
	end)
	self:Connect(buttonFrame.MouseLeave, function()
		Tween(buttonFrame, {BackgroundColor3 = Google.Theme.Primary}, 0.15)
	end)

	self:RefreshSection()
	return self
end

function Button:ApplyTheme()
	self.Instance.BackgroundColor3 = Google.Theme.Primary
end

Toggle = setmetatable({}, {__index = Control})
Toggle.__index = Toggle

function Toggle.new(section, config)
	local self = setmetatable(Control.new(section), Toggle)
	self.Text = config.Name or "Toggle"
	self.Description = config.Description
	self.Value = config.Default or false
	self.Callback = config.Callback or function() end

	local toggleFrame = Instance.new("Frame")
	toggleFrame.Name = "Toggle"
	toggleFrame.Size = UDim2.new(1, -16, 0, 32)
	toggleFrame.Position = UDim2.new(0, 8, 0, 0)
	toggleFrame.BackgroundTransparency = 1
	toggleFrame.BorderSizePixel = 0
	toggleFrame.LayoutOrder = #section.Controls
	toggleFrame.Parent = section.ControlContainer

	local label = Instance.new("TextLabel")
	label.Text = self.Text
	label.Font = Enum.Font.Gotham
	label.TextSize = 13
	label.Size = UDim2.new(1, -56, 1, 0)
	label.Position = UDim2.new(0, 12, 0, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Google.Theme.Text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = toggleFrame
	if self.Description then
		label.Size = UDim2.new(1, -56, 0, 18)
		local descLabel = Instance.new("TextLabel")
		descLabel.Text = self.Description
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextSize = 11
		descLabel.Size = UDim2.new(1, -56, 0, 14)
		descLabel.Position = UDim2.new(0, 12, 0, 18)
		descLabel.BackgroundTransparency = 1
		descLabel.TextColor3 = Google.Theme.TextSecondary
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.Parent = toggleFrame
	end

	local switch = Instance.new("TextButton")
	switch.Name = "Switch"
	switch.Size = UDim2.new(0, 40, 0, 20)
	switch.Position = UDim2.new(1, -52, 0.5, -10)
	switch.BackgroundColor3 = self.Value and Google.Theme.ToggleOn or Google.Theme.ToggleOff
	switch.BorderSizePixel = 0
	switch.Text = ""
	switch.AutoButtonColor = false
	switch.Parent = toggleFrame

	local switchCorner = Instance.new("UICorner")
	switchCorner.CornerRadius = UDim.new(1, 0)
	switchCorner.Parent = switch

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.Size = UDim2.new(0, 16, 0, 16)
	knob.Position = self.Value and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
	knob.BackgroundColor3 = Color3.new(1,1,1)
	knob.BorderSizePixel = 0
	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob
	knob.Parent = switch

	self.Instance = toggleFrame
	self.Switch = switch
	self.Knob = knob
	self.Label = label

	self:Connect(switch.MouseButton1Click, function()
		self:Set(not self.Value)
	end)

	self:RefreshSection()
	return self
end

function Toggle:Set(value)
	self.Value = value
	if self.Switch then
		local newColor = value and Google.Theme.ToggleOn or Google.Theme.ToggleOff
		Tween(self.Switch, {BackgroundColor3 = newColor}, 0.15)
		local newPos = value and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
		Tween(self.Knob, {Position = newPos}, 0.15)
	end
	self.Callback(self.Value)
end

function Toggle:Get()
	return self.Value
end

function Toggle:ApplyTheme()
	local newColor = self.Value and Google.Theme.ToggleOn or Google.Theme.ToggleOff
	self.Switch.BackgroundColor3 = newColor
	self.Label.TextColor3 = Google.Theme.Text
end

Slider = setmetatable({}, {__index = Control})
Slider.__index = Slider

function Slider.new(section, config)
	local self = setmetatable(Control.new(section), Slider)
	self.Text = config.Name or "Slider"
	self.Min = config.Min or 0
	self.Max = config.Max or 100
	self.Value = config.Default or self.Min
	self.Precision = config.Precision or 0
	self.Callback = config.Callback or function() end

	local sliderFrame = Instance.new("Frame")
	sliderFrame.Name = "Slider"
	sliderFrame.Size = UDim2.new(1, -16, 0, 40)
	sliderFrame.Position = UDim2.new(0, 8, 0, 0)
	sliderFrame.BackgroundTransparency = 1
	sliderFrame.BorderSizePixel = 0
	sliderFrame.LayoutOrder = #section.Controls
	sliderFrame.Parent = section.ControlContainer

	local label = Instance.new("TextLabel")
	label.Text = self.Text
	label.Font = Enum.Font.Gotham
	label.TextSize = 13
	label.Size = UDim2.new(1, -12, 0, 16)
	label.Position = UDim2.new(0, 12, 0, 2)
	label.BackgroundTransparency = 1
	label.TextColor3 = Google.Theme.Text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = sliderFrame

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Text = tostring(self.Value)
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextSize = 12
	valueLabel.Size = UDim2.new(0, 50, 0, 16)
	valueLabel.Position = UDim2.new(1, -62, 0, 2)
	valueLabel.BackgroundTransparency = 1
	valueLabel.TextColor3 = Google.Theme.Primary
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = sliderFrame

	local sliderBg = Instance.new("Frame")
	sliderBg.Size = UDim2.new(1, -24, 0, 6)
	sliderBg.Position = UDim2.new(0, 12, 0, 24)
	sliderBg.BackgroundColor3 = Google.Theme.SliderBackground
	sliderBg.BorderSizePixel = 0
	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(1, 0)
	bgCorner.Parent = sliderBg
	sliderBg.Parent = sliderFrame

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new((self.Value - self.Min) / (self.Max - self.Min), 0, 1, 0)
	fill.BackgroundColor3 = Google.Theme.SliderFill
	fill.BorderSizePixel = 0
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill
	fill.Parent = sliderBg

	local sliderButton = Instance.new("TextButton")
	sliderButton.Text = ""
	sliderButton.Size = UDim2.new(1, 0, 1, 10)
	sliderButton.Position = UDim2.new(0,0,0,-5)
	sliderButton.BackgroundTransparency = 1
	sliderButton.BorderSizePixel = 0
	sliderButton.Parent = sliderBg

	self.Instance = sliderFrame
	self.SliderBg = sliderBg
	self.Fill = fill
	self.ValueLabel = valueLabel
	self.Label = label

	local function updateFromPosition(inputX)
		local absSize = sliderBg.AbsoluteSize.X
		local relX = math.clamp((inputX - sliderBg.AbsolutePosition.X) / absSize, 0, 1)
		local val = self.Min + (self.Max - self.Min) * relX
		if self.Precision > 0 then
			val = math.floor(val * (10 ^ self.Precision) + 0.5) / (10 ^ self.Precision)
		else
			val = math.floor(val + 0.5)
		end
		self:Set(val)
	end

	local dragging = false
	self:Connect(sliderButton.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromPosition(input.Position.X)
		end
	end)
	self:Connect(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	self:Connect(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromPosition(input.Position.X)
		end
	end)

	self:RefreshSection()
	return self
end

function Slider:Set(value)
	self.Value = math.clamp(value, self.Min, self.Max)
	local ratio = (self.Value - self.Min) / (self.Max - self.Min)
	self.Fill.Size = UDim2.new(ratio, 0, 1, 0)
	self.ValueLabel.Text = tostring(self.Value)
	self.Callback(self.Value)
end

function Slider:Get()
	return self.Value
end

function Slider:ApplyTheme()
	self.SliderBg.BackgroundColor3 = Google.Theme.SliderBackground
	self.Fill.BackgroundColor3 = Google.Theme.SliderFill
	self.ValueLabel.TextColor3 = Google.Theme.Primary
	self.Label.TextColor3 = Google.Theme.Text
end

Dropdown = setmetatable({}, {__index = Control})
Dropdown.__index = Dropdown

function Dropdown.new(section, config)
	local self = setmetatable(Control.new(section), Dropdown)
	self.Text = config.Name or "Dropdown"
	self.Options = config.Options or {}
	self.Multi = config.Multi or false
	self.Searchable = config.Searchable or false
	self.Value = self.Multi and {} or (config.Default or (self.Options[1] or ""))
	self.Callback = config.Callback or function() end
	self.DropOpen = false

	local dropFrame = Instance.new("Frame")
	dropFrame.Name = "Dropdown"
	dropFrame.Size = UDim2.new(1, -16, 0, 36)
	dropFrame.Position = UDim2.new(0, 8, 0, 0)
	dropFrame.BackgroundTransparency = 1
	dropFrame.BorderSizePixel = 0
	dropFrame.LayoutOrder = #section.Controls
	dropFrame.Parent = section.ControlContainer

	local mainButton = Instance.new("TextButton")
	mainButton.Name = "Main"
	mainButton.Size = UDim2.new(1, 0, 1, 0)
	mainButton.BackgroundColor3 = Google.Theme.InputBackground
	mainButton.BorderSizePixel = 1
	mainButton.BorderColor3 = Google.Theme.InputBorder
	mainButton.Text = ""
	mainButton.AutoButtonColor = false
	mainButton.Parent = dropFrame

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 4)
	mainCorner.Parent = mainButton

	local selectedLabel = Instance.new("TextLabel")
	selectedLabel.Name = "Selected"
	selectedLabel.Text = self.Multi and "Select..." or tostring(self.Value)
	selectedLabel.Font = Enum.Font.Gotham
	selectedLabel.TextSize = 13
	selectedLabel.Size = UDim2.new(1, -30, 1, 0)
	selectedLabel.Position = UDim2.new(0, 10, 0, 0)
	selectedLabel.BackgroundTransparency = 1
	selectedLabel.TextColor3 = Google.Theme.Text
	selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
	selectedLabel.Parent = mainButton

	local arrow = Instance.new("TextLabel")
	arrow.Text = "▼"
	arrow.Font = Enum.Font.SourceSans
	arrow.TextSize = 10
	arrow.Size = UDim2.new(0, 20, 1, 0)
	arrow.Position = UDim2.new(1, -22, 0, 0)
	arrow.BackgroundTransparency = 1
	arrow.TextColor3 = Google.Theme.TextSecondary
	arrow.TextXAlignment = Enum.TextXAlignment.Center
	arrow.Parent = mainButton

	self.Instance = dropFrame
	self.MainButton = mainButton
	self.SelectedLabel = selectedLabel
	self.Arrow = arrow

	local dropdownList = Instance.new("Frame")
	dropdownList.Name = "List"
	dropdownList.Size = UDim2.new(1, 0, 0, 0)
	dropdownList.Position = UDim2.new(0, 0, 1, 4)
	dropdownList.BackgroundColor3 = Google.Theme.DropdownMenu
	dropdownList.BorderSizePixel = 1
	dropdownList.BorderColor3 = Google.Theme.Border
	dropdownList.ClipsDescendants = true
	dropdownList.Visible = false
	dropdownList.ZIndex = 10
	local listCorner = Instance.new("UICorner")
	listCorner.CornerRadius = UDim.new(0, 4)
	listCorner.Parent = dropdownList
	dropdownList.Parent = dropFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = dropdownList

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, 0, 1, 0)
	scrollFrame.CanvasSize = UDim2.new(0,0,0,0)
	scrollFrame.ScrollBarThickness = 3
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	scrollFrame.Parent = dropdownList

	local scrollLayout = Instance.new("UIListLayout")
	scrollLayout.Parent = scrollFrame

	self.DropList = dropdownList
	self.ScrollFrame = scrollFrame
	self.ListLayout = scrollLayout

	self:Connect(mainButton.MouseButton1Click, function()
		self:ToggleDropdown()
	end)

	self:RefreshOptions()

	self:RefreshSection()
	return self
end

function Dropdown:RefreshOptions()
	for _, child in ipairs(self.ScrollFrame:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	if self.Searchable then
		local searchEntry = Instance.new("TextBox")
		searchEntry.Name = "Search"
		searchEntry.Size = UDim2.new(1, -8, 0, 28)
		searchEntry.Position = UDim2.new(0, 4, 0, 4)
		searchEntry.PlaceholderText = "Search..."
		searchEntry.Text = ""
		searchEntry.Font = Enum.Font.Gotham
		searchEntry.TextSize = 13
		searchEntry.BackgroundColor3 = Google.Theme.InputBackground
		searchEntry.BorderSizePixel = 1
		searchEntry.BorderColor3 = Google.Theme.InputBorder
		searchEntry.TextColor3 = Google.Theme.Text
		searchEntry.PlaceholderColor3 = Google.Theme.TextSecondary
		searchEntry.Parent = self.ScrollFrame
		self.SearchBox = searchEntry
		self:Connect(searchEntry:GetPropertyChangedSignal("Text"), function()
			self:FilterOptions(searchEntry.Text)
		end)
	end

	for i, option in ipairs(self.Options) do
		local optButton = Instance.new("TextButton")
		optButton.Name = option
		optButton.Size = UDim2.new(1, 0, 0, 28)
		optButton.BackgroundTransparency = 1
		optButton.BorderSizePixel = 0
		optButton.Text = ""
		optButton.Font = Enum.Font.Gotham
		optButton.TextSize = 13
		optButton.LayoutOrder = i
		optButton.Parent = self.ScrollFrame

		local optLabel = Instance.new("TextLabel")
		optLabel.Text = option
		optLabel.Font = Enum.Font.Gotham
		optLabel.TextSize = 13
		optLabel.Size = UDim2.new(1, -16, 1, 0)
		optLabel.Position = UDim2.new(0, 8, 0, 0)
		optLabel.BackgroundTransparency = 1
		optLabel.TextColor3 = Google.Theme.Text
		optLabel.TextXAlignment = Enum.TextXAlignment.Left
		optLabel.Parent = optButton

		self:Connect(optButton.MouseButton1Click, function()
			self:SelectOption(option)
		end)
		self:Connect(optButton.MouseEnter, function()
			Tween(optButton, {BackgroundTransparency = 0.9}, 0.1)
		end)
		self:Connect(optButton.MouseLeave, function()
			Tween(optButton, {BackgroundTransparency = 1}, 0.1)
		end)
	end
	self.ScrollFrame.CanvasSize = UDim2.new(0,0,0,self.ListLayout.AbsoluteContentSize.Y + 8)
end

function Dropdown:FilterOptions(query)
	query = query:lower()
	for _, button in ipairs(self.ScrollFrame:GetChildren()) do
		if button:IsA("TextButton") then
			local label = button:FindFirstChildOfClass("TextLabel")
			if label then
				button.Visible = label.Text:lower():find(query) ~= nil
			end
		end
	end
end

function Dropdown:SelectOption(option)
	if self.Multi then
		local list = self.Value
		local found = false
		for i, v in ipairs(list) do
			if v == option then
				table.remove(list, i)
				found = true
				break
			end
		end
		if not found then
			table.insert(list, option)
		end
		self.SelectedLabel.Text = #list > 0 and table.concat(list, ", ") or "Select..."
		self.Callback(list)
	else
		self.Value = option
		self.SelectedLabel.Text = option
		self.Callback(option)
		self:CloseDropdown()
	end
end

function Dropdown:ToggleDropdown()
	if self.DropOpen then
		self:CloseDropdown()
	else
		self:OpenDropdown()
	end
end

function Dropdown:OpenDropdown()
	self.DropOpen = true
	self.DropList.Visible = true
	local maxHeight = 150
	local needed = math.min(#self.Options * 28 + (self.Searchable and 36 or 0), maxHeight)
	self.DropList.Size = UDim2.new(1, 0, 0, needed)
	self.ScrollFrame.Size = UDim2.new(1, 0, 1, 0)
	self.ScrollFrame.CanvasSize = UDim2.new(0,0,0,self.ListLayout.AbsoluteContentSize.Y + 8)
	Tween(self.DropList, {Size = UDim2.new(1, 0, 0, needed)}, 0.15)
end

function Dropdown:CloseDropdown()
	self.DropOpen = false
	Tween(self.DropList, {Size = UDim2.new(1, 0, 0, 0)}, 0.15, nil, nil, function()
		self.DropList.Visible = false
	end)
end

function Dropdown:Set(value)
	if self.Multi then
		if type(value) == "table" then
			self.Value = value
		else
			self.Value = {value}
		end
		self.SelectedLabel.Text = #self.Value > 0 and table.concat(self.Value, ", ") or "Select..."
		self.Callback(self.Value)
	else
		self.Value = value
		self.SelectedLabel.Text = tostring(value)
		self.Callback(value)
	end
end

function Dropdown:Get()
	return self.Value
end

function Dropdown:Refresh(newOptions)
	if newOptions then
		self.Options = newOptions
		self:RefreshOptions()
	end
	self:RefreshSection()
end

function Dropdown:ApplyTheme()
	self.MainButton.BackgroundColor3 = Google.Theme.InputBackground
	self.MainButton.BorderColor3 = Google.Theme.InputBorder
	self.DropList.BackgroundColor3 = Google.Theme.DropdownMenu
	self.DropList.BorderColor3 = Google.Theme.Border
	self.SelectedLabel.TextColor3 = Google.Theme.Text
	self.Arrow.TextColor3 = Google.Theme.TextSecondary
end

Textbox = setmetatable({}, {__index = Control})
Textbox.__index = Textbox

function Textbox.new(section, config)
	local self = setmetatable(Control.new(section), Textbox)
	self.Text = config.Name or "Textbox"
	self.Placeholder = config.Placeholder or ""
	self.Numeric = config.Numeric or false
	self.Value = config.Default or ""
	self.Callback = config.Callback or function() end

	local boxFrame = Instance.new("Frame")
	boxFrame.Name = "Textbox"
	boxFrame.Size = UDim2.new(1, -16, 0, 40)
	boxFrame.Position = UDim2.new(0, 8, 0, 0)
	boxFrame.BackgroundTransparency = 1
	boxFrame.BorderSizePixel = 0
	boxFrame.LayoutOrder = #section.Controls
	boxFrame.Parent = section.ControlContainer

	local label = Instance.new("TextLabel")
	label.Text = self.Text
	label.Font = Enum.Font.Gotham
	label.TextSize = 13
	label.Size = UDim2.new(1, -12, 0, 16)
	label.Position = UDim2.new(0, 12, 0, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Google.Theme.Text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = boxFrame

	local entry = Instance.new("TextBox")
	entry.Name = "Entry"
	entry.Size = UDim2.new(1, -24, 0, 22)
	entry.Position = UDim2.new(0, 12, 0, 18)
	entry.BackgroundColor3 = Google.Theme.InputBackground
	entry.BorderSizePixel = 1
	entry.BorderColor3 = Google.Theme.InputBorder
	entry.Text = self.Value
	entry.PlaceholderText = self.Placeholder
	entry.Font = Enum.Font.Gotham
	entry.TextSize = 13
	entry.TextColor3 = Google.Theme.Text
	entry.PlaceholderColor3 = Google.Theme.TextSecondary
	entry.TextXAlignment = Enum.TextXAlignment.Left
	entry.Parent = boxFrame

	local entryCorner = Instance.new("UICorner")
	entryCorner.CornerRadius = UDim.new(0, 4)
	entryCorner.Parent = entry

	self.Instance = boxFrame
	self.Entry = entry

	self:Connect(entry.FocusLost, function(enterPressed)
		self:OnValueChange()
	end)
	self:Connect(entry:GetPropertyChangedSignal("Text"), function()
		if self.Numeric then
			local num = tonumber(entry.Text)
			if not num and entry.Text ~= "" then
				entry.Text = tostring(self.Value)
			end
		end
	end)

	self:RefreshSection()
	return self
end

function Textbox:OnValueChange()
	local text = self.Entry.Text
	if self.Numeric then
		local num = tonumber(text)
		if num then
			self.Value = num
		else
			self.Entry.Text = tostring(self.Value)
			return
		end
	else
		self.Value = text
	end
	self.Callback(self.Value)
end

function Textbox:Set(value)
	self.Value = value
	self.Entry.Text = tostring(value)
end

function Textbox:Get()
	return self.Value
end

function Textbox:ApplyTheme()
	self.Entry.BackgroundColor3 = Google.Theme.InputBackground
	self.Entry.BorderColor3 = Google.Theme.InputBorder
	self.Entry.TextColor3 = Google.Theme.Text
	self.Entry.PlaceholderColor3 = Google.Theme.TextSecondary
end

Keybind = setmetatable({}, {__index = Control})
Keybind.__index = Keybind

function Keybind.new(section, config)
	local self = setmetatable(Control.new(section), Keybind)
	self.Text = config.Name or "Keybind"
	self.Value = config.Default or Enum.KeyCode.E
	self.Mode = config.Mode or "Toggle"
	self.Callback = config.Callback or function() end
	self.Holding = false
	self.Binding = false

	local bindFrame = Instance.new("Frame")
	bindFrame.Name = "Keybind"
	bindFrame.Size = UDim2.new(1, -16, 0, 32)
	bindFrame.Position = UDim2.new(0, 8, 0, 0)
	bindFrame.BackgroundTransparency = 1
	bindFrame.BorderSizePixel = 0
	bindFrame.LayoutOrder = #section.Controls
	bindFrame.Parent = section.ControlContainer

	local label = Instance.new("TextLabel")
	label.Text = self.Text
	label.Font = Enum.Font.Gotham
	label.TextSize = 13
	label.Size = UDim2.new(1, -80, 1, 0)
	label.Position = UDim2.new(0, 12, 0, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Google.Theme.Text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = bindFrame

	local keyButton = Instance.new("TextButton")
	keyButton.Text = self.Value.Name
	keyButton.Font = Enum.Font.GothamBold
	keyButton.TextSize = 12
	keyButton.Size = UDim2.new(0, 70, 0, 22)
	keyButton.Position = UDim2.new(1, -82, 0.5, -11)
	keyButton.BackgroundColor3 = Google.Theme.InputBackground
	keyButton.BorderSizePixel = 1
	keyButton.BorderColor3 = Google.Theme.InputBorder
	keyButton.TextColor3 = Google.Theme.Text
	keyButton.AutoButtonColor = false
	local keyCorner = Instance.new("UICorner")
	keyCorner.CornerRadius = UDim.new(0, 4)
	keyCorner.Parent = keyButton
	keyButton.Parent = bindFrame

	self.Instance = bindFrame
	self.KeyButton = keyButton
	self.Label = label

	self:Connect(keyButton.MouseButton1Click, function()
		self:StartBinding()
	end)

	self:Connect(UserInputService.InputBegan, function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == self.Value then
			if self.Mode == "Hold" then
				self.Holding = true
				self.Callback(true)
			elseif self.Mode == "Toggle" then
				self.Holding = not self.Holding
				self.Callback(self.Holding)
			end
		end
	end)
	self:Connect(UserInputService.InputEnded, function(input)
		if input.KeyCode == self.Value and self.Mode == "Hold" then
			self.Holding = false
			self.Callback(false)
		end
	end)

	self:RefreshSection()
	return self
end

function Keybind:StartBinding()
	self.Binding = true
	self.KeyButton.Text = "..."
	local conn
	conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not self.Binding then return end
		if gameProcessed then return end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			self.Value = input.KeyCode
			self.KeyButton.Text = input.KeyCode.Name
			self.Binding = false
			conn:Disconnect()
			self.Callback(self.Value)
		end
	end)
end

function Keybind:Set(keycode)
	self.Value = keycode
	self.KeyButton.Text = keycode.Name
end

function Keybind:Get()
	return self.Value
end

function Keybind:ApplyTheme()
	self.KeyButton.BackgroundColor3 = Google.Theme.InputBackground
	self.KeyButton.BorderColor3 = Google.Theme.InputBorder
	self.KeyButton.TextColor3 = Google.Theme.Text
	self.Label.TextColor3 = Google.Theme.Text
end

ColorPicker = setmetatable({}, {__index = Control})
ColorPicker.__index = ColorPicker

function ColorPicker.new(section, config)
	local self = setmetatable(Control.new(section), ColorPicker)
	self.Text = config.Name or "Color"
	self.Value = config.Default or Color3.fromRGB(255, 255, 255)
	self.Callback = config.Callback or function() end
	self.Open = false

	local pickerFrame = Instance.new("Frame")
	pickerFrame.Name = "ColorPicker"
	pickerFrame.Size = UDim2.new(1, -16, 0, 32)
	pickerFrame.Position = UDim2.new(0, 8, 0, 0)
	pickerFrame.BackgroundTransparency = 1
	pickerFrame.BorderSizePixel = 0
	pickerFrame.LayoutOrder = #section.Controls
	pickerFrame.Parent = section.ControlContainer

	local label = Instance.new("TextLabel")
	label.Text = self.Text
	label.Font = Enum.Font.Gotham
	label.TextSize = 13
	label.Size = UDim2.new(1, -50, 1, 0)
	label.Position = UDim2.new(0, 12, 0, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Google.Theme.Text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = pickerFrame

	local colorPreview = Instance.new("TextButton")
	colorPreview.Size = UDim2.new(0, 30, 0, 22)
	colorPreview.Position = UDim2.new(1, -42, 0.5, -11)
	colorPreview.BackgroundColor3 = self.Value
	colorPreview.BorderSizePixel = 1
	colorPreview.BorderColor3 = Google.Theme.Border
	colorPreview.Text = ""
	colorPreview.Parent = pickerFrame
	local previewCorner = Instance.new("UICorner")
	previewCorner.CornerRadius = UDim.new(0, 4)
	previewCorner.Parent = colorPreview

	local colorPanel = Instance.new("Frame")
	colorPanel.Name = "ColorPanel"
	colorPanel.Size = UDim2.new(0, 240, 0, 200)
	colorPanel.Position = UDim2.new(1, -242, 1, 6)
	colorPanel.BackgroundColor3 = Google.Theme.DropdownMenu
	colorPanel.BorderSizePixel = 1
	colorPanel.BorderColor3 = Google.Theme.Border
	colorPanel.Visible = false
	colorPanel.ZIndex = 10
	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 4)
	panelCorner.Parent = colorPanel
	colorPanel.Parent = pickerFrame

	local pickerCanvas = Instance.new("ImageButton")
	pickerCanvas.Size = UDim2.new(1, -20, 0, 120)
	pickerCanvas.Position = UDim2.new(0, 10, 0, 10)
	pickerCanvas.Image = "rbxassetid://284402756"
	pickerCanvas.BackgroundColor3 = Color3.new(1,1,1)
	pickerCanvas.BorderSizePixel = 0
	pickerCanvas.Parent = colorPanel

	local cursorFrame = Instance.new("Frame")
	cursorFrame.Size = UDim2.new(0, 8, 0, 8)
	cursorFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	cursorFrame.BackgroundColor3 = Color3.new(1,1,1)
	cursorFrame.BorderSizePixel = 1
	cursorFrame.BorderColor3 = Color3.new(0,0,0)
	cursorFrame.ZIndex = 11
	local cursorCorner = Instance.new("UICorner")
	cursorCorner.CornerRadius = UDim.new(1,0)
	cursorCorner.Parent = cursorFrame
	cursorFrame.Parent = pickerCanvas

	local rgbSliders = {}
	local function createRGBChannel(channel, yPos)
		local labelCh = Instance.new("TextLabel")
		labelCh.Text = channel..":"
		labelCh.Font = Enum.Font.Gotham
		labelCh.TextSize = 12
		labelCh.Size = UDim2.new(0, 15, 0, 20)
		labelCh.Position = UDim2.new(0, 10, 0, yPos)
		labelCh.BackgroundTransparency = 1
		labelCh.TextColor3 = Google.Theme.Text
		labelCh.Parent = colorPanel

		local sliderBg = Instance.new("Frame")
		sliderBg.Size = UDim2.new(1, -95, 0, 14)
		sliderBg.Position = UDim2.new(0, 30, 0, yPos + 3)
		sliderBg.BackgroundColor3 = Google.Theme.SliderBackground
		sliderBg.BorderSizePixel = 0
		local bgCorner = Instance.new("UICorner")
		bgCorner.CornerRadius = UDim.new(1,0)
		bgCorner.Parent = sliderBg
		sliderBg.Parent = colorPanel

		local fill = Instance.new("Frame")
		fill.Size = UDim2.new(0, 0, 1, 0)
		fill.BackgroundColor3 = channel == "R" and Color3.new(1,0,0) or channel == "G" and Color3.new(0,1,0) or Color3.new(0,0,1)
		fill.BorderSizePixel = 0
		fill.Parent = sliderBg

		local sliderBtn = Instance.new("TextButton")
		sliderBtn.Text = ""
		sliderBtn.Size = UDim2.new(1, 0, 1, 10)
		sliderBtn.Position = UDim2.new(0,0,0,-5)
		sliderBtn.BackgroundTransparency = 1
		sliderBtn.Parent = sliderBg

		local valueLabel = Instance.new("TextLabel")
		valueLabel.Text = "0"
		valueLabel.Font = Enum.Font.Gotham
		valueLabel.TextSize = 11
		valueLabel.Size = UDim2.new(0, 40, 0, 20)
		valueLabel.Position = UDim2.new(1, -50, 0, yPos)
		valueLabel.BackgroundTransparency = 1
		valueLabel.TextColor3 = Google.Theme.TextSecondary
		valueLabel.TextXAlignment = Enum.TextXAlignment.Right
		valueLabel.Parent = colorPanel

		return {sliderBg, fill, valueLabel, sliderBtn}
	end

	local rControls = createRGBChannel("R", 140)
	local gControls = createRGBChannel("G", 160)
	local bControls = createRGBChannel("B", 180)

	self.Instance = pickerFrame
	self.ColorPreview = colorPreview
	self.ColorPanel = colorPanel
	self.PickerCanvas = pickerCanvas
	self.Cursor = cursorFrame

	local function updateSlidersFromColor(color)
		local r = math.floor(color.R * 255)
		local g = math.floor(color.G * 255)
		local b = math.floor(color.B * 255)
		rControls[2].Size = UDim2.new(r/255, 0, 1, 0)
		gControls[2].Size = UDim2.new(g/255, 0, 1, 0)
		bControls[2].Size = UDim2.new(b/255, 0, 1, 0)
		rControls[3].Text = tostring(r)
		gControls[3].Text = tostring(g)
		bControls[3].Text = tostring(b)
		cursorFrame.Position = UDim2.new(color.R, 0, 1 - color.G, 0)
	end

	updateSlidersFromColor(self.Value)
	cursorFrame.Position = UDim2.new(self.Value.R, 0, 1 - self.Value.G, 0)

	self:Connect(colorPreview.MouseButton1Click, function()
		self:TogglePanel()
	end)

	local function handleSlider(sliderBg, fill, valueLabel, index)
		local dragging = false
		self:Connect(sliderBg.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				local x = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
				self:UpdateColorFromSlider(index, x)
			end
		end)
		self:Connect(UserInputService.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
		end)
		self:Connect(UserInputService.InputChanged, function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local x = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
				self:UpdateColorFromSlider(index, x)
			end
		end)
	end
	handleSlider(rControls[1], rControls[2], rControls[3], 1)
	handleSlider(gControls[1], gControls[2], gControls[3], 2)
	handleSlider(bControls[1], bControls[2], bControls[3], 3)

	self:RefreshSection()
	return self
end

function ColorPicker:UpdateColorFromSlider(channel, value)
	local r = self.Value.R
	local g = self.Value.G
	local b = self.Value.B
	if channel == 1 then r = value
	elseif channel == 2 then g = value
	elseif channel == 3 then b = value end
	self:Set(Color3.new(r, g, b))
end

function ColorPicker:Set(color)
	self.Value = color
	self.ColorPreview.BackgroundColor3 = color
	if self.Open then
		local rControls = self.Instance:FindFirstChild("ColorPanel")
	end
	self.Callback(color)
end

function ColorPicker:Get()
	return self.Value
end

function ColorPicker:TogglePanel()
	self.Open = not self.Open
	self.ColorPanel.Visible = self.Open
end

function ColorPicker:ApplyTheme()
	self.ColorPanel.BackgroundColor3 = Google.Theme.DropdownMenu
	self.ColorPanel.BorderColor3 = Google.Theme.Border
	self.ColorPreview.BorderColor3 = Google.Theme.Border
end

Label = setmetatable({}, {__index = Control})
Label.__index = Label

function Label.new(section, config)
	local self = setmetatable(Control.new(section), Label)
	self.Text = config.Text or ""
	self.RichText = config.RichText or false

	local labelFrame = Instance.new("Frame")
	labelFrame.Size = UDim2.new(1, -16, 0, 20)
	labelFrame.Position = UDim2.new(0, 8, 0, 0)
	labelFrame.BackgroundTransparency = 1
	labelFrame.LayoutOrder = #section.Controls
	labelFrame.Parent = section.ControlContainer

	local textLabel = Instance.new("TextLabel")
	textLabel.Text = self.Text
	textLabel.Font = Enum.Font.Gotham
	textLabel.TextSize = 13
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Google.Theme.Text
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.RichText = self.RichText
	textLabel.TextWrapped = true
	textLabel.Parent = labelFrame

	self.Instance = labelFrame
	self.TextLabel = textLabel

	self:RefreshSection()
	return self
end

function Label:Set(text)
	self.Text = text
	self.TextLabel.Text = text
end

function Label:Get()
	return self.Text
end

function Label:ApplyTheme()
	self.TextLabel.TextColor3 = Google.Theme.Text
end

Paragraph = setmetatable({}, {__index = Control})
Paragraph.__index = Paragraph

function Paragraph.new(section, config)
	local self = setmetatable(Control.new(section), Paragraph)
	self.Title = config.Title or ""
	self.Description = config.Description or ""

	local paraFrame = Instance.new("Frame")
	paraFrame.Size = UDim2.new(1, -16, 0, 40)
	paraFrame.Position = UDim2.new(0, 8, 0, 0)
	paraFrame.BackgroundTransparency = 1
	paraFrame.LayoutOrder = #section.Controls
	paraFrame.Parent = section.ControlContainer

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Text = self.Title
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 13
	titleLabel.Size = UDim2.new(1, 0, 0, 16)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Google.Theme.Text
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = paraFrame

	local descLabel = Instance.new("TextLabel")
	descLabel.Text = self.Description
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 12
	descLabel.Size = UDim2.new(1, 0, 0, 20)
	descLabel.Position = UDim2.new(0, 0, 0, 18)
	descLabel.BackgroundTransparency = 1
	descLabel.TextColor3 = Google.Theme.TextSecondary
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextWrapped = true
	descLabel.Parent = paraFrame

	self.Instance = paraFrame
	self.TitleLabel = titleLabel
	self.DescLabel = descLabel

	self:Connect(descLabel:GetPropertyChangedSignal("TextBounds"), function()
		local bounds = descLabel.TextBounds
		paraFrame.Size = UDim2.new(1, -16, 0, 18 + bounds.Y)
		self:RefreshSection()
	end)

	self:RefreshSection()
	return self
end

function Paragraph:ApplyTheme()
	self.TitleLabel.TextColor3 = Google.Theme.Text
	self.DescLabel.TextColor3 = Google.Theme.TextSecondary
end

Divider = setmetatable({}, {__index = Control})
Divider.__index = Divider

function Divider.new(section, config)
	local self = setmetatable(Control.new(section), Divider)
	self.Text = config.Text or nil
	self.LineOnly = config.LineOnly or false

	local divFrame = Instance.new("Frame")
	divFrame.Size = UDim2.new(1, -16, 0, 20)
	divFrame.Position = UDim2.new(0, 8, 0, 0)
	divFrame.BackgroundTransparency = 1
	divFrame.LayoutOrder = #section.Controls
	divFrame.Parent = section.ControlContainer

	if not self.LineOnly and self.Text then
		local label = Instance.new("TextLabel")
		label.Text = self.Text
		label.Font = Enum.Font.GothamBold
		label.TextSize = 11
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = Google.Theme.TextSecondary
		label.TextXAlignment = Enum.TextXAlignment.Center
		label.Parent = divFrame

		local leftLine = Instance.new("Frame")
		leftLine.Size = UDim2.new(0.4, -20, 0, 1)
		leftLine.Position = UDim2.new(0, 0, 0.5, -0.5)
		leftLine.BackgroundColor3 = Google.Theme.Border
		leftLine.BorderSizePixel = 0
		leftLine.Parent = divFrame

		local rightLine = Instance.new("Frame")
		rightLine.Size = UDim2.new(0.4, -20, 0, 1)
		rightLine.Position = UDim2.new(0.6, 20, 0.5, -0.5)
		rightLine.BackgroundColor3 = Google.Theme.Border
		rightLine.BorderSizePixel = 0
		rightLine.Parent = divFrame
	else
		local line = Instance.new("Frame")
		line.Size = UDim2.new(1, 0, 0, 1)
		line.Position = UDim2.new(0, 0, 0.5, 0)
		line.BackgroundColor3 = Google.Theme.Border
		line.BorderSizePixel = 0
		line.Parent = divFrame
	end

	self.Instance = divFrame

	self:RefreshSection()
	return self
end

function Divider:ApplyTheme()
	for _, child in ipairs(self.Instance:GetChildren()) do
		if child:IsA("Frame") then
			child.BackgroundColor3 = Google.Theme.Border
		elseif child:IsA("TextLabel") then
			child.TextColor3 = Google.Theme.TextSecondary
		end
	end
end

local NotificationManager = {}
NotificationManager.__index = NotificationManager

function Google.Notify(config)
	NotificationManager:Push(config)
end

function NotificationManager.Push(self, config)
	if not NotificationManager.Active then
		NotificationManager:Init()
	end
	config = config or {}
	local title = config.Title or "Notification"
	local description = config.Description or ""
	local duration = config.Duration or 3
	local icon = config.Icon or nil
	local iconColor = config.IconColor or nil

	local notifGui = NotificationManager.Gui
	local notifHolder = notifGui:FindFirstChild("Holder")

	local notifFrame = Instance.new("Frame")
	notifFrame.Size = UDim2.new(0, 280, 0, 60)
	notifFrame.Position = UDim2.new(1, 10, 1, -10)
	notifFrame.AnchorPoint = Vector2.new(1, 1)
	notifFrame.BackgroundColor3 = Google.Theme.Notification
	notifFrame.BorderSizePixel = 0
	notifFrame.ClipsDescendants = true

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = notifFrame

	local shadow = Instance.new("ImageLabel")
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://6015897843"
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(49,49,450,450)
	shadow.Size = UDim2.new(1, 16, 1, 16)
	shadow.Position = UDim2.new(0, -8, 0, -8)
	shadow.ImageColor3 = Google.Theme.Shadow
	shadow.ImageTransparency = 0.7
	shadow.Parent = notifFrame

	local content = Instance.new("Frame")
	content.Size = UDim2.new(1, -16, 1, -16)
	content.Position = UDim2.new(0, 8, 0, 8)
	content.BackgroundTransparency = 1
	content.Parent = notifFrame

	local iconLabel
	if icon then
		iconLabel = Google.CreateIcon(icon, 22, iconColor or Google.Theme.Primary, content, {
			Position = UDim2.new(0, 0, 0.5, -11),
		})
	end

	local textX = iconLabel and 30 or 0
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Text = title
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 13
	titleLabel.Size = UDim2.new(1, -textX, 0, 16)
	titleLabel.Position = UDim2.new(0, textX, 0, 4)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Google.Theme.NotificationText
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = content

	local descLabel = Instance.new("TextLabel")
	descLabel.Text = description
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 11
	descLabel.Size = UDim2.new(1, -textX, 0, 14)
	descLabel.Position = UDim2.new(0, textX, 0, 22)
	descLabel.BackgroundTransparency = 1
	descLabel.TextColor3 = Google.Theme.NotificationText
	descLabel.TextTransparency = 0.3
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextWrapped = true
	descLabel.Parent = content

	local progressBar = Instance.new("Frame")
	progressBar.Size = UDim2.new(1, 0, 0, 3)
	progressBar.Position = UDim2.new(0, 0, 1, -3)
	progressBar.BackgroundTransparency = 1
	progressBar.Parent = notifFrame

	local progressFill = Instance.new("Frame")
	progressFill.Size = UDim2.new(1, 0, 1, 0)
	progressFill.BackgroundColor3 = Google.Theme.Primary
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressBar
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 2)
	fillCorner.Parent = progressFill

	notifFrame.Parent = notifHolder

	notifFrame.Position = UDim2.new(1, 10, 1, -10)
	Tween(notifFrame, {Position = UDim2.new(1, -10, 1, -10)}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	Tween(progressFill, {Size = UDim2.new(0, 0, 1, 0)}, duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, function()
		Tween(shadow, {ImageTransparency = 1}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		Tween(notifFrame, {Position = UDim2.new(1, 10, 1, -10), BackgroundTransparency = 1}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, function()
			notifFrame:Destroy()
			NotificationManager:UpdatePositions()
		end)
	end)

	NotificationManager:UpdatePositions()
end

function NotificationManager.Init(self)
	if NotificationManager.Gui then return end
	local gui = Instance.new("ScreenGui")
	gui.Name = "GoogleNotifications"
	gui.Parent = CoreGui
	NotificationManager.Gui = gui

	local holder = Instance.new("Frame")
	holder.Name = "Holder"
	holder.Size = UDim2.new(1, 0, 1, 0)
	holder.BackgroundTransparency = 1
	holder.Parent = gui
end

function NotificationManager.UpdatePositions(self)
	local holder = NotificationManager.Gui:FindFirstChild("Holder")
	if not holder then return end
	local notifs = {}
	for _, child in ipairs(holder:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "Holder" then
			table.insert(notifs, child)
		end
	end
	table.sort(notifs, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
	local offset = 10
	for i = #notifs, 1, -1 do
		local frame = notifs[i]
		frame.Position = UDim2.new(1, -10, 1, -offset)
		offset = offset + frame.Size.Y.Offset + 8
	end
end

function Google:Confirm(config)
	config = config or {}
	local title = config.Title or "Confirm"
	local description = config.Description or "Are you sure?"
	local callback = config.Callback or function(confirmed) end
	local confirmText = config.ConfirmText or "Yes"
	local cancelText = config.CancelText or "No"

	local overlay = Instance.new("Frame")
	overlay.Name = "DialogOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.new(0,0,0)
	overlay.BackgroundTransparency = 0.5
	overlay.ZIndex = 20
	overlay.Parent = CoreGui

	local dialog = Instance.new("Frame")
	dialog.Size = UDim2.new(0, 280, 0, 120)
	dialog.Position = UDim2.new(0.5, -140, 0.5, -60)
	dialog.BackgroundColor3 = Google.Theme.Surface
	dialog.BorderSizePixel = 0
	dialog.ZIndex = 21
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = dialog
	dialog.Parent = overlay

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Text = title
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 16
	titleLabel.Size = UDim2.new(1, -24, 0, 24)
	titleLabel.Position = UDim2.new(0, 12, 0, 12)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Google.Theme.Text
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = dialog

	local descLabel = Instance.new("TextLabel")
	descLabel.Text = description
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 12
	descLabel.Size = UDim2.new(1, -24, 0, 28)
	descLabel.Position = UDim2.new(0, 12, 0, 40)
	descLabel.BackgroundTransparency = 1
	descLabel.TextColor3 = Google.Theme.TextSecondary
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextWrapped = true
	descLabel.Parent = dialog

	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Text = cancelText
	cancelBtn.Font = Enum.Font.GothamBold
	cancelBtn.TextSize = 13
	cancelBtn.Size = UDim2.new(0, 90, 0, 28)
	cancelBtn.Position = UDim2.new(1, -200, 1, -40)
	cancelBtn.BackgroundColor3 = Google.Theme.Hover
	cancelBtn.BorderSizePixel = 0
	cancelBtn.TextColor3 = Google.Theme.Text
	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 4)
	cancelCorner.Parent = cancelBtn
	cancelBtn.Parent = dialog

	local confirmBtn = Instance.new("TextButton")
	confirmBtn.Text = confirmText
	confirmBtn.Font = Enum.Font.GothamBold
	confirmBtn.TextSize = 13
	confirmBtn.Size = UDim2.new(0, 90, 0, 28)
	confirmBtn.Position = UDim2.new(1, -100, 1, -40)
	confirmBtn.BackgroundColor3 = Google.Theme.Primary
	confirmBtn.BorderSizePixel = 0
	confirmBtn.TextColor3 = Color3.new(1,1,1)
	local confirmCorner = Instance.new("UICorner")
	confirmCorner.CornerRadius = UDim.new(0, 4)
	confirmCorner.Parent = confirmBtn
	confirmBtn.Parent = dialog

	local function close(confirmed)
		overlay:Destroy()
		callback(confirmed)
	end

	cancelBtn.MouseButton1Click:Connect(function() close(false) end)
	confirmBtn.MouseButton1Click:Connect(function() close(true) end)
	local keyConn
	keyConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
			close(true)
			keyConn:Disconnect()
		elseif input.KeyCode == Enum.KeyCode.Escape then
			close(false)
			keyConn:Disconnect()
		end
	end)
end

function Google:Prompt(config)
	config = config or {}
	local title = config.Title or "Input"
	local description = config.Description or ""
	local placeholder = config.Placeholder or ""
	local default = config.Default or ""
	local callback = config.Callback or function(text) end
	local confirmText = config.ConfirmText or "OK"
	local cancelText = config.CancelText or "Cancel"

	local overlay = Instance.new("Frame")
	overlay.Name = "DialogOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.new(0,0,0)
	overlay.BackgroundTransparency = 0.5
	overlay.ZIndex = 20
	overlay.Parent = CoreGui

	local dialog = Instance.new("Frame")
	dialog.Size = UDim2.new(0, 280, 0, 140)
	dialog.Position = UDim2.new(0.5, -140, 0.5, -70)
	dialog.BackgroundColor3 = Google.Theme.Surface
	dialog.BorderSizePixel = 0
	dialog.ZIndex = 21
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = dialog
	dialog.Parent = overlay

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Text = title
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 16
	titleLabel.Size = UDim2.new(1, -24, 0, 24)
	titleLabel.Position = UDim2.new(0, 12, 0, 12)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Google.Theme.Text
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = dialog

	local descLabel = Instance.new("TextLabel")
	descLabel.Text = description
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 11
	descLabel.Size = UDim2.new(1, -24, 0, 16)
	descLabel.Position = UDim2.new(0, 12, 0, 38)
	descLabel.BackgroundTransparency = 1
	descLabel.TextColor3 = Google.Theme.TextSecondary
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Parent = dialog

	local textBox = Instance.new("TextBox")
	textBox.Text = default
	textBox.PlaceholderText = placeholder
	textBox.Font = Enum.Font.Gotham
	textBox.TextSize = 13
	textBox.Size = UDim2.new(1, -24, 0, 28)
	textBox.Position = UDim2.new(0, 12, 0, 58)
	textBox.BackgroundColor3 = Google.Theme.InputBackground
	textBox.BorderSizePixel = 1
	textBox.BorderColor3 = Google.Theme.InputBorder
	textBox.TextColor3 = Google.Theme.Text
	textBox.PlaceholderColor3 = Google.Theme.TextSecondary
	local tbCorner = Instance.new("UICorner")
	tbCorner.CornerRadius = UDim.new(0, 4)
	tbCorner.Parent = textBox
	textBox.Parent = dialog

	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Text = cancelText
	cancelBtn.Font = Enum.Font.GothamBold
	cancelBtn.TextSize = 13
	cancelBtn.Size = UDim2.new(0, 90, 0, 28)
	cancelBtn.Position = UDim2.new(1, -200, 1, -12)
	cancelBtn.BackgroundColor3 = Google.Theme.Hover
	cancelBtn.BorderSizePixel = 0
	cancelBtn.TextColor3 = Google.Theme.Text
	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 4)
	cancelCorner.Parent = cancelBtn
	cancelBtn.Parent = dialog

	local confirmBtn = Instance.new("TextButton")
	confirmBtn.Text = confirmText
	confirmBtn.Font = Enum.Font.GothamBold
	confirmBtn.TextSize = 13
	confirmBtn.Size = UDim2.new(0, 90, 0, 28)
	confirmBtn.Position = UDim2.new(1, -100, 1, -12)
	confirmBtn.BackgroundColor3 = Google.Theme.Primary
	confirmBtn.BorderSizePixel = 0
	confirmBtn.TextColor3 = Color3.new(1,1,1)
	local confirmCorner = Instance.new("UICorner")
	confirmCorner.CornerRadius = UDim.new(0, 4)
	confirmCorner.Parent = confirmBtn
	confirmBtn.Parent = dialog

	local function close(text)
		overlay:Destroy()
		callback(text)
	end

	cancelBtn.MouseButton1Click:Connect(function() close(nil) end)
	confirmBtn.MouseButton1Click:Connect(function() close(textBox.Text) end)
	local keyConn
	keyConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
			close(textBox.Text)
			keyConn:Disconnect()
		elseif input.KeyCode == Enum.KeyCode.Escape then
			close(nil)
			keyConn:Disconnect()
		end
	end)
	textBox:CaptureFocus()
end

function Google:Cleanup()
	for _, window in ipairs(Google.Windows) do
		window:Destroy()
	end
	Google.Windows = {}
	if NotificationManager.Gui then
		NotificationManager.Gui:Destroy()
		NotificationManager.Gui = nil
	end
end

return Google
