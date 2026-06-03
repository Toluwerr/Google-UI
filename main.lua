local Google = {}
Google.__index = Google

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local function SafeParent()
	if type(gethui) == "function" then
		local ok, result = pcall(gethui)
		if ok and result then
			return result
		end
	end
	local playerGui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if playerGui then
		return playerGui
	end
	return CoreGui
end

local function New(className, properties)
	local object = Instance.new(className)
	if properties then
		for property, value in pairs(properties) do
			object[property] = value
		end
	end
	return object
end

local function Corner(parent, radius)
	local corner = New("UICorner", {
		CornerRadius = UDim.new(0, radius or 6),
		Parent = parent
	})
	return corner
end

local function Stroke(parent, color, transparency, thickness)
	local stroke = New("UIStroke", {
		Color = color,
		Transparency = transparency or 0,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent
	})
	return stroke
end

local function Padding(parent, left, right, top, bottom)
	local padding = New("UIPadding", {
		PaddingLeft = UDim.new(0, left or 0),
		PaddingRight = UDim.new(0, right or 0),
		PaddingTop = UDim.new(0, top or 0),
		PaddingBottom = UDim.new(0, bottom or 0),
		Parent = parent
	})
	return padding
end

local function Tween(object, properties, duration, style, direction, callback)
	local tween = TweenService:Create(object, TweenInfo.new(duration or 0.16, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), properties)
	if callback then
		local connection
		connection = tween.Completed:Connect(function()
			if connection then
				connection:Disconnect()
			end
			callback()
		end)
	end
	tween:Play()
	return tween
end

local function Connect(list, signal, callback)
	local connection = signal:Connect(callback)
	table.insert(list, connection)
	return connection
end

local function DisconnectAll(list)
	for _, connection in ipairs(list) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	table.clear(list)
end

local function IsColor(value)
	return typeof(value) == "Color3"
end

local function Blend(colorA, colorB, alpha)
	return colorA:Lerp(colorB, alpha)
end

Google.Windows = {}
Google.Themes = {
	Google = {
		Window = Color3.fromRGB(248, 250, 252),
		Topbar = Color3.fromRGB(255, 255, 255),
		Sidebar = Color3.fromRGB(255, 255, 255),
		Page = Color3.fromRGB(245, 247, 251),
		Card = Color3.fromRGB(255, 255, 255),
		CardAlt = Color3.fromRGB(248, 250, 252),
		Text = Color3.fromRGB(31, 41, 55),
		Muted = Color3.fromRGB(100, 116, 139),
		Subtle = Color3.fromRGB(148, 163, 184),
		Border = Color3.fromRGB(226, 232, 240),
		BorderStrong = Color3.fromRGB(203, 213, 225),
		Primary = Color3.fromRGB(26, 115, 232),
		PrimaryHover = Color3.fromRGB(24, 102, 204),
		PrimarySoft = Color3.fromRGB(232, 240, 254),
		Success = Color3.fromRGB(52, 168, 83),
		Warning = Color3.fromRGB(251, 188, 4),
		Danger = Color3.fromRGB(234, 67, 53),
		Input = Color3.fromRGB(255, 255, 255),
		Hover = Color3.fromRGB(241, 245, 249),
		Shadow = Color3.fromRGB(15, 23, 42)
	},
	Dark = {
		Window = Color3.fromRGB(18, 20, 24),
		Topbar = Color3.fromRGB(24, 27, 32),
		Sidebar = Color3.fromRGB(22, 25, 30),
		Page = Color3.fromRGB(15, 17, 21),
		Card = Color3.fromRGB(25, 29, 35),
		CardAlt = Color3.fromRGB(31, 36, 43),
		Text = Color3.fromRGB(238, 242, 247),
		Muted = Color3.fromRGB(156, 166, 182),
		Subtle = Color3.fromRGB(111, 123, 141),
		Border = Color3.fromRGB(45, 52, 63),
		BorderStrong = Color3.fromRGB(64, 73, 88),
		Primary = Color3.fromRGB(96, 165, 250),
		PrimaryHover = Color3.fromRGB(59, 130, 246),
		PrimarySoft = Color3.fromRGB(25, 54, 93),
		Success = Color3.fromRGB(52, 168, 83),
		Warning = Color3.fromRGB(251, 188, 4),
		Danger = Color3.fromRGB(248, 81, 73),
		Input = Color3.fromRGB(19, 22, 27),
		Hover = Color3.fromRGB(35, 40, 48),
		Shadow = Color3.fromRGB(0, 0, 0)
	},
	Midnight = {
		Window = Color3.fromRGB(10, 13, 20),
		Topbar = Color3.fromRGB(16, 21, 33),
		Sidebar = Color3.fromRGB(13, 17, 27),
		Page = Color3.fromRGB(8, 11, 18),
		Card = Color3.fromRGB(17, 22, 35),
		CardAlt = Color3.fromRGB(23, 29, 44),
		Text = Color3.fromRGB(241, 245, 249),
		Muted = Color3.fromRGB(148, 163, 184),
		Subtle = Color3.fromRGB(100, 116, 139),
		Border = Color3.fromRGB(30, 41, 59),
		BorderStrong = Color3.fromRGB(51, 65, 85),
		Primary = Color3.fromRGB(99, 102, 241),
		PrimaryHover = Color3.fromRGB(79, 70, 229),
		PrimarySoft = Color3.fromRGB(39, 39, 89),
		Success = Color3.fromRGB(34, 197, 94),
		Warning = Color3.fromRGB(245, 158, 11),
		Danger = Color3.fromRGB(239, 68, 68),
		Input = Color3.fromRGB(12, 17, 29),
		Hover = Color3.fromRGB(25, 34, 51),
		Shadow = Color3.fromRGB(0, 0, 0)
	},
	Ocean = {
		Window = Color3.fromRGB(238, 249, 252),
		Topbar = Color3.fromRGB(255, 255, 255),
		Sidebar = Color3.fromRGB(250, 253, 255),
		Page = Color3.fromRGB(231, 245, 250),
		Card = Color3.fromRGB(255, 255, 255),
		CardAlt = Color3.fromRGB(241, 250, 253),
		Text = Color3.fromRGB(19, 52, 66),
		Muted = Color3.fromRGB(77, 106, 122),
		Subtle = Color3.fromRGB(125, 151, 166),
		Border = Color3.fromRGB(200, 225, 234),
		BorderStrong = Color3.fromRGB(164, 206, 221),
		Primary = Color3.fromRGB(14, 165, 233),
		PrimaryHover = Color3.fromRGB(2, 132, 199),
		PrimarySoft = Color3.fromRGB(224, 242, 254),
		Success = Color3.fromRGB(16, 185, 129),
		Warning = Color3.fromRGB(245, 158, 11),
		Danger = Color3.fromRGB(239, 68, 68),
		Input = Color3.fromRGB(255, 255, 255),
		Hover = Color3.fromRGB(224, 242, 254),
		Shadow = Color3.fromRGB(15, 23, 42)
	}
}
Google.ActiveTheme = "Google"
Google.Theme = Google.Themes.Google

Google.IconAliases = {
	warning = "triangle-alert",
	error = "circle-x",
	dropdown = "chevron-down",
	cross = "x",
	hamburger = "menu",
	dots = "ellipsis",
	question = "circle-help",
	toggle = "toggle-right",
	color = "palette",
	refresh = "refresh-cw",
	external = "external-link",
	edit = "pencil",
	arrowLeft = "arrow-left",
	arrowRight = "arrow-right",
	arrowUp = "arrow-up",
	arrowDown = "arrow-down",
	notification = "bell"
}

Google.IconAssets = {
	home = {16898613509, 820, 147},
	sword = {16898613777, 710, 967},
	shield = {16898613777, 869, 0},
	settings = {16898613777, 771, 257},
	user = {16898613869, 661, 869},
	users = {16898613869, 967, 98},
	star = {16898613777, 967, 147},
	info = {16898613509, 612, 869},
	["triangle-alert"] = {16898613869, 967, 0},
	["circle-x"] = {16898613044, 820, 306},
	check = {16898612819, 710, 869},
	search = {16898613699, 918, 857},
	["chevron-down"] = {16898612819, 196, 918},
	["chevron-right"] = {16898612819, 918, 306},
	plus = {16898613699, 257, 918},
	minus = {16898613613, 771, 196},
	pencil = {16898613699, 820, 257},
	trash = {16898613869, 918, 514},
	link = {16898613509, 918, 453},
	["refresh-cw"] = {16898613699, 404, 869},
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
	["toggle-right"] = {16898613869, 820, 98},
	image = {16898613509, 306, 918},
	file = {16898613353, 820, 661},
	folder = {16898613353, 404, 967},
	download = {16898613044, 820, 906},
	upload = {16898613869, 612, 869},
	x = {16898613869, 869, 906},
	menu = {16898613613, 49, 820},
	ellipsis = {16898613353, 771, 49},
	["circle-help"] = {16898613044, 820, 257},
	["external-link"] = {16898613353, 257, 820},
	save = {16898613699, 918, 453}
}

local function ResolveIcon(name)
	local key = tostring(name or "")
	key = Google.IconAliases[key] or key
	local asset = Google.IconAssets[key]
	if not asset then
		return nil
	end
	return {
		Image = "rbxassetid://" .. tostring(asset[1]),
		Offset = Vector2.new(asset[2], asset[3]),
		Size = Vector2.new(48, 48)
	}
end

function Google.CreateIcon(name, size, color, parent, properties)
	size = size or 18
	local asset = ResolveIcon(name)
	local icon
	if asset then
		icon = New("ImageLabel", {
			Name = "Icon",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = asset.Image,
			ImageRectOffset = asset.Offset,
			ImageRectSize = asset.Size,
			ImageColor3 = color or Color3.new(1, 1, 1),
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromOffset(size, size)
		})
	else
		icon = New("TextLabel", {
			Name = "Icon",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = "•",
			Font = Enum.Font.GothamBold,
			TextSize = size,
			TextColor3 = color or Color3.new(1, 1, 1),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			Size = UDim2.fromOffset(size, size)
		})
	end
	if properties then
		for property, value in pairs(properties) do
			icon[property] = value
		end
	end
	icon.Parent = parent
	return icon
end

function Google.SetIconColor(icon, color)
	if not icon then
		return
	end
	if icon:IsA("ImageLabel") or icon:IsA("ImageButton") then
		icon.ImageColor3 = color
	elseif icon:IsA("TextLabel") or icon:IsA("TextButton") then
		icon.TextColor3 = color
	end
end

function Google.RegisterTheme(name, theme)
	if type(name) == "string" and type(theme) == "table" then
		Google.Themes[name] = theme
	end
end

function Google.SetTheme(name)
	if Google.Themes[name] then
		Google.ActiveTheme = name
		Google.Theme = Google.Themes[name]
		for _, window in ipairs(Google.Windows) do
			if window.ApplyTheme then
				window:ApplyTheme()
			end
		end
	end
end

function Google.GetTheme()
	return Google.ActiveTheme, Google.Theme
end

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

local ControlBase = {}
ControlBase.__index = ControlBase

function Google:CreateWindow(config)
	config = config or {}
	local self = setmetatable({}, Window)
	self.Title = config.Title or "Google UI"
	self.Subtitle = config.Subtitle or ""
	self.Icon = config.Icon or "home"
	self.Size = config.Size or UDim2.fromOffset(620, 420)
	self.Position = config.Position
	self.Tabs = {}
	self.ActiveTab = nil
	self.Connections = {}
	self.ThemeObjects = {}
	self.Minimized = false
	self.Visible = true
	self.NotifySide = config.NotifySide or "Right"

	local gui = New("ScreenGui", {
		Name = "GoogleUI",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = config.Parent or SafeParent()
	})
	self.Gui = gui

	local main = New("Frame", {
		Name = "Window",
		Size = self.Size,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = self.Position or UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = Google.Theme.Window,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		Parent = gui
	})
	self.Instance = main
	Corner(main, 10)
	self.MainStroke = Stroke(main, Google.Theme.Border, 0.05, 1)

	local shadow = New("ImageLabel", {
		Name = "Shadow",
		BackgroundTransparency = 1,
		Image = "rbxassetid://6015897843",
		ImageColor3 = Google.Theme.Shadow,
		ImageTransparency = 0.82,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		Size = UDim2.new(1, 28, 1, 28),
		Position = UDim2.fromOffset(-14, -10),
		ZIndex = 0,
		Parent = main
	})
	self.Shadow = shadow

	local body = New("Frame", {
		Name = "Body",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Google.Theme.Window,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 2,
		Parent = main
	})
	Corner(body, 10)
	self.Body = body

	local topbar = New("Frame", {
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundColor3 = Google.Theme.Topbar,
		BorderSizePixel = 0,
		Parent = body
	})
	self.Topbar = topbar

	local topbarLine = New("Frame", {
		Name = "TopbarLine",
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = Google.Theme.Border,
		BorderSizePixel = 0,
		Parent = topbar
	})
	self.TopbarLine = topbarLine

	local titleIconWrap = New("Frame", {
		Name = "TitleIconWrap",
		Size = UDim2.fromOffset(32, 32),
		Position = UDim2.fromOffset(14, 11),
		BackgroundColor3 = Google.Theme.PrimarySoft,
		BorderSizePixel = 0,
		Parent = topbar
	})
	Corner(titleIconWrap, 8)
	self.TitleIconWrap = titleIconWrap
	self.TitleIcon = Google.CreateIcon(self.Icon, 19, Google.Theme.Primary, titleIconWrap, {
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5)
	})

	local title = New("TextLabel", {
		Name = "Title",
		Text = self.Title,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextColor3 = Google.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Bottom,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -170, 0, 22),
		Position = UDim2.fromOffset(56, self.Subtitle ~= "" and 8 or 16),
		Parent = topbar
	})
	self.TitleLabel = title

	local subtitle = New("TextLabel", {
		Name = "Subtitle",
		Text = self.Subtitle,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Google.Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -170, 0, 18),
		Position = UDim2.fromOffset(56, 30),
		Visible = self.Subtitle ~= "",
		Parent = topbar
	})
	self.SubtitleLabel = subtitle

	local controls = New("Frame", {
		Name = "WindowControls",
		Size = UDim2.fromOffset(76, 30),
		Position = UDim2.new(1, -88, 0, 12),
		BackgroundTransparency = 1,
		Parent = topbar
	})
	self.ControlsFrame = controls

	local minimizeButton = New("TextButton", {
		Name = "Minimize",
		Text = "",
		Size = UDim2.fromOffset(30, 30),
		Position = UDim2.fromOffset(4, 0),
		BackgroundColor3 = Google.Theme.Hover,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Parent = controls
	})
	Corner(minimizeButton, 7)
	self.MinimizeButton = minimizeButton
	self.MinimizeIcon = Google.CreateIcon("minus", 16, Google.Theme.Muted, minimizeButton, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5)
	})

	local closeButton = New("TextButton", {
		Name = "Close",
		Text = "",
		Size = UDim2.fromOffset(30, 30),
		Position = UDim2.fromOffset(42, 0),
		BackgroundColor3 = Google.Theme.Hover,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Parent = controls
	})
	Corner(closeButton, 7)
	self.CloseButton = closeButton
	self.CloseIcon = Google.CreateIcon("x", 15, Google.Theme.Muted, closeButton, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5)
	})

	Connect(self.Connections, minimizeButton.MouseButton1Click, function()
		if self.Minimized then
			self:Restore()
		else
			self:Minimize()
		end
	end)
	Connect(self.Connections, closeButton.MouseButton1Click, function()
		self:Destroy()
	end)
	Connect(self.Connections, minimizeButton.MouseEnter, function()
		Tween(minimizeButton, {BackgroundTransparency = 0}, 0.12)
	end)
	Connect(self.Connections, minimizeButton.MouseLeave, function()
		Tween(minimizeButton, {BackgroundTransparency = 1}, 0.12)
	end)
	Connect(self.Connections, closeButton.MouseEnter, function()
		Google.SetIconColor(self.CloseIcon, Color3.new(1, 1, 1))
		Tween(closeButton, {BackgroundColor3 = Google.Theme.Danger, BackgroundTransparency = 0}, 0.12)
	end)
	Connect(self.Connections, closeButton.MouseLeave, function()
		Google.SetIconColor(self.CloseIcon, Google.Theme.Muted)
		Tween(closeButton, {BackgroundColor3 = Google.Theme.Hover, BackgroundTransparency = 1}, 0.12)
	end)

	local sidebar = New("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 152, 1, -54),
		Position = UDim2.fromOffset(0, 54),
		BackgroundColor3 = Google.Theme.Sidebar,
		BorderSizePixel = 0,
		Parent = body
	})
	self.Sidebar = sidebar

	local sidebarLine = New("Frame", {
		Name = "SidebarLine",
		Size = UDim2.new(0, 1, 1, 0),
		Position = UDim2.new(1, -1, 0, 0),
		BackgroundColor3 = Google.Theme.Border,
		BorderSizePixel = 0,
		Parent = sidebar
	})
	self.SidebarLine = sidebarLine

	local tabList = New("ScrollingFrame", {
		Name = "TabList",
		Size = UDim2.new(1, -16, 1, -16),
		Position = UDim2.fromOffset(8, 8),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.fromOffset(0, 0),
		Parent = sidebar
	})
	self.TabList = tabList

	local tabLayout = New("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
		Parent = tabList
	})
	self.TabLayout = tabLayout

	local pageWrap = New("Frame", {
		Name = "PageWrap",
		Size = UDim2.new(1, -152, 1, -54),
		Position = UDim2.fromOffset(152, 54),
		BackgroundColor3 = Google.Theme.Page,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = body
	})
	self.PageWrap = pageWrap

	local dragging = false
	local dragStart
	local startPosition
	Connect(self.Connections, topbar.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPosition = main.Position
			local changedConnection
			changedConnection = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if changedConnection then
						changedConnection:Disconnect()
					end
				end
			end)
		end
	end)
	Connect(self.Connections, UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
		end
	end)

	Connect(self.Connections, tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		tabList.CanvasSize = UDim2.fromOffset(0, tabLayout.AbsoluteContentSize.Y + 8)
	end)

	table.insert(Google.Windows, self)
	self:ApplyTheme()
	return self
end

function Window:CreateTab(config)
	config = config or {}
	if type(config) == "string" then
		config = {Name = config}
	end
	local tab = setmetatable({}, Tab)
	tab.Window = self
	tab.Name = config.Name or "Tab"
	tab.Icon = config.Icon or "circle-help"
	tab.Sections = {}
	tab.Connections = {}
	tab.Active = false

	local button = New("TextButton", {
		Name = tab.Name,
		Text = "",
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = Google.Theme.PrimarySoft,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Parent = self.TabList
	})
	Corner(button, 8)
	tab.Button = button

	local accent = New("Frame", {
		Name = "Accent",
		Size = UDim2.new(0, 3, 0, 18),
		Position = UDim2.fromOffset(0, 9),
		BackgroundColor3 = Google.Theme.Primary,
		BorderSizePixel = 0,
		Visible = false,
		Parent = button
	})
	Corner(accent, 3)
	tab.Accent = accent

	tab.IconLabel = Google.CreateIcon(tab.Icon, 17, Google.Theme.Muted, button, {
		Position = UDim2.fromOffset(12, 9)
	})
	tab.TextLabel = New("TextLabel", {
		Name = "Text",
		Text = tab.Name,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = Google.Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -42, 1, 0),
		Position = UDim2.fromOffset(38, 0),
		Parent = button
	})

	local page = New("ScrollingFrame", {
		Name = "Page_" .. tab.Name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Google.Theme.BorderStrong,
		CanvasSize = UDim2.fromOffset(0, 0),
		Visible = false,
		Parent = self.PageWrap
	})
	Padding(page, 14, 14, 14, 14)
	tab.Page = page
	tab.Layout = New("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
		Parent = page
	})
	Connect(tab.Connections, tab.Layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		tab:UpdateCanvas()
	end)
	Connect(tab.Connections, button.MouseButton1Click, function()
		self:SelectTab(tab)
	end)
	Connect(tab.Connections, button.MouseEnter, function()
		if not tab.Active then
			Tween(button, {BackgroundTransparency = 0}, 0.12)
		end
	end)
	Connect(tab.Connections, button.MouseLeave, function()
		if not tab.Active then
			Tween(button, {BackgroundTransparency = 1}, 0.12)
		end
	end)

	table.insert(self.Tabs, tab)
	self.TabList.CanvasSize = UDim2.fromOffset(0, self.TabLayout.AbsoluteContentSize.Y + 8)
	if not self.ActiveTab then
		self:SelectTab(tab)
	end
	return tab
end

function Window:AddTab(config)
	return self:CreateTab(config)
end

function Window:SelectTab(tab)
	if self.ActiveTab == tab then
		return
	end
	if self.ActiveTab then
		self.ActiveTab:SetActive(false)
	end
	self.ActiveTab = tab
	tab:SetActive(true)
end

function Tab:SetActive(active)
	self.Active = active
	self.Page.Visible = active
	self.Accent.Visible = active
	if active then
		self.Button.BackgroundTransparency = 0
		self.Button.BackgroundColor3 = Google.Theme.PrimarySoft
		self.TextLabel.TextColor3 = Google.Theme.Primary
		Google.SetIconColor(self.IconLabel, Google.Theme.Primary)
	else
		self.Button.BackgroundTransparency = 1
		self.TextLabel.TextColor3 = Google.Theme.Muted
		Google.SetIconColor(self.IconLabel, Google.Theme.Muted)
	end
end

function Tab:CreateSection(config)
	config = config or {}
	if type(config) == "string" then
		config = {Name = config}
	end
	local section = setmetatable({}, Section)
	section.Tab = self
	section.Name = config.Name or "Section"
	section.Description = config.Description or ""
	section.Icon = config.Icon
	section.Controls = {}
	section.Connections = {}
	section.Collapsed = config.Collapsed or false

	local frame = New("Frame", {
		Name = section.Name,
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = Google.Theme.Card,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = self.Page
	})
	Corner(frame, 9)
	section.Instance = frame
	section.Stroke = Stroke(frame, Google.Theme.Border, 0.05, 1)

	local header = New("TextButton", {
		Name = "Header",
		Text = "",
		Size = UDim2.new(1, 0, 0, section.Description ~= "" and 54 or 42),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Parent = frame
	})
	section.Header = header

	section.Arrow = Google.CreateIcon(section.Collapsed and "chevron-right" or "chevron-down", 14, Google.Theme.Muted, header, {
		Position = UDim2.fromOffset(13, 14)
	})
	section.TitleLabel = New("TextLabel", {
		Name = "Title",
		Text = section.Name,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = Google.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -48, 0, 20),
		Position = UDim2.fromOffset(36, section.Description ~= "" and 9 or 11),
		Parent = header
	})
	section.DescriptionLabel = New("TextLabel", {
		Name = "Description",
		Text = section.Description,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Google.Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -48, 0, 18),
		Position = UDim2.fromOffset(36, 29),
		Visible = section.Description ~= "",
		Parent = header
	})

	local content = New("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(0, header.Size.Y.Offset),
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = not section.Collapsed,
		Parent = frame
	})
	Padding(content, 10, 10, 0, 10)
	section.Content = content
	section.Layout = New("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 7),
		Parent = content
	})
	Connect(section.Connections, section.Layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		section:Refresh()
	end)
	Connect(section.Connections, header.MouseButton1Click, function()
		section:SetCollapsed(not section.Collapsed)
	end)

	table.insert(self.Sections, section)
	section:Refresh()
	return section
end

function Tab:AddSection(config)
	return self:CreateSection(config)
end

function Tab:UpdateCanvas()
	self.Page.CanvasSize = UDim2.fromOffset(0, self.Layout.AbsoluteContentSize.Y + 28)
end

function Tab:ApplyTheme()
	self.Page.ScrollBarImageColor3 = Google.Theme.BorderStrong
	self:SetActive(self.Active)
	for _, section in ipairs(self.Sections) do
		section:ApplyTheme()
	end
end

function Section:SetCollapsed(collapsed)
	self.Collapsed = collapsed
	self.Content.Visible = not collapsed
	local asset = ResolveIcon(collapsed and "chevron-right" or "chevron-down")
	if asset and self.Arrow:IsA("ImageLabel") then
		self.Arrow.Image = asset.Image
		self.Arrow.ImageRectOffset = asset.Offset
		self.Arrow.ImageRectSize = asset.Size
	end
	self:Refresh()
end

function Section:Refresh()
	local headerHeight = self.Header.Size.Y.Offset
	local contentHeight = self.Collapsed and 0 or (self.Layout.AbsoluteContentSize.Y + 10)
	self.Content.Position = UDim2.fromOffset(0, headerHeight)
	self.Content.Size = UDim2.new(1, 0, 0, contentHeight)
	self.Instance.Size = UDim2.new(1, 0, 0, headerHeight + contentHeight)
	self.Tab:UpdateCanvas()
end

function Section:ApplyTheme()
	self.Instance.BackgroundColor3 = Google.Theme.Card
	self.Stroke.Color = Google.Theme.Border
	self.TitleLabel.TextColor3 = Google.Theme.Text
	self.DescriptionLabel.TextColor3 = Google.Theme.Muted
	Google.SetIconColor(self.Arrow, Google.Theme.Muted)
	for _, control in ipairs(self.Controls) do
		if control.ApplyTheme then
			control:ApplyTheme()
		end
	end
end

function ControlBase:RefreshSection()
	if self.Section then
		self.Section:Refresh()
	end
end

local function Control(section, height, name)
	local self = setmetatable({}, ControlBase)
	self.Section = section
	self.Connections = {}
	local frame = New("Frame", {
		Name = name or "Control",
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = Google.Theme.CardAlt,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = section.Content
	})
	self.Instance = frame
	table.insert(section.Controls, self)
	return self
end

function Section:CreateButton(config)
	config = config or {}
	local self = Control(self, config.Description and 48 or 36, "Button")
	self.Callback = config.Callback or function() end
	self.Icon = config.Icon
	local button = New("TextButton", {
		Name = "Button",
		Text = "",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Google.Theme.Primary,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Parent = self.Instance
	})
	Corner(button, 7)
	self.Button = button
	local iconOffset = self.Icon and 34 or 12
	if self.Icon then
		self.IconLabel = Google.CreateIcon(self.Icon, 17, Color3.new(1, 1, 1), button, {
			Position = UDim2.fromOffset(12, config.Description and 15 or 10)
		})
	end
	self.TextLabel = New("TextLabel", {
		Text = config.Name or "Button",
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -iconOffset - 10, 0, config.Description and 18 or 36),
		Position = UDim2.fromOffset(iconOffset, config.Description and 7 or 0),
		Parent = button
	})
	if config.Description then
		self.DescriptionLabel = New("TextLabel", {
			Text = config.Description,
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = Color3.new(1, 1, 1),
			TextTransparency = 0.25,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -iconOffset - 10, 0, 16),
			Position = UDim2.fromOffset(iconOffset, 25),
			Parent = button
		})
	end
	Connect(self.Connections, button.MouseButton1Click, function()
		self.Callback()
	end)
	Connect(self.Connections, button.MouseEnter, function()
		Tween(button, {BackgroundColor3 = Google.Theme.PrimaryHover}, 0.12)
	end)
	Connect(self.Connections, button.MouseLeave, function()
		Tween(button, {BackgroundColor3 = Google.Theme.Primary}, 0.12)
	end)
	function self:ApplyTheme()
		self.Button.BackgroundColor3 = Google.Theme.Primary
		if self.IconLabel then
			Google.SetIconColor(self.IconLabel, Color3.new(1, 1, 1))
		end
	end
	self:RefreshSection()
	return self
end

function Section:AddButton(config)
	return self:CreateButton(config)
end

function Section:CreateToggle(config)
	config = config or {}
	local self = Control(self, config.Description and 48 or 36, "Toggle")
	self.Value = config.Default or false
	self.Callback = config.Callback or function() end
	self.Label = New("TextLabel", {
		Text = config.Name or "Toggle",
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = Google.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -64, 0, 18),
		Position = UDim2.fromOffset(0, config.Description and 5 or 9),
		Parent = self.Instance
	})
	if config.Description then
		self.DescriptionLabel = New("TextLabel", {
			Text = config.Description,
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = Google.Theme.Muted,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -64, 0, 16),
			Position = UDim2.fromOffset(0, 25),
			Parent = self.Instance
		})
	end
	local switch = New("TextButton", {
		Text = "",
		Size = UDim2.fromOffset(40, 22),
		Position = UDim2.new(1, -40, 0.5, -11),
		BackgroundColor3 = self.Value and Google.Theme.Primary or Google.Theme.BorderStrong,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Parent = self.Instance
	})
	Corner(switch, 12)
	self.Switch = switch
	self.Knob = New("Frame", {
		Size = UDim2.fromOffset(18, 18),
		Position = self.Value and UDim2.new(1, -20, 0.5, -9) or UDim2.fromOffset(2, 2),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Parent = switch
	})
	Corner(self.Knob, 9)
	function self:Set(value)
		self.Value = value and true or false
		Tween(self.Switch, {BackgroundColor3 = self.Value and Google.Theme.Primary or Google.Theme.BorderStrong}, 0.14)
		Tween(self.Knob, {Position = self.Value and UDim2.new(1, -20, 0.5, -9) or UDim2.fromOffset(2, 2)}, 0.14)
		self.Callback(self.Value)
	end
	function self:Get()
		return self.Value
	end
	Connect(self.Connections, switch.MouseButton1Click, function()
		self:Set(not self.Value)
	end)
	Connect(self.Connections, self.Instance.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self:Set(not self.Value)
		end
	end)
	function self:ApplyTheme()
		self.Label.TextColor3 = Google.Theme.Text
		if self.DescriptionLabel then
			self.DescriptionLabel.TextColor3 = Google.Theme.Muted
		end
		self.Switch.BackgroundColor3 = self.Value and Google.Theme.Primary or Google.Theme.BorderStrong
	end
	self:RefreshSection()
	return self
end

function Section:AddToggle(index, config)
	if type(index) == "table" then
		return self:CreateToggle(index)
	end
	config = config or {}
	config.Name = config.Name or config.Text or index
	return self:CreateToggle(config)
end

function Section:CreateSlider(config)
	config = config or {}
	local self = Control(self, 56, "Slider")
	self.Min = config.Min or config.Minimum or 0
	self.Max = config.Max or config.Maximum or 100
	self.Value = config.Default or self.Min
	self.Precision = config.Precision or 0
	self.Callback = config.Callback or function() end
	self.Dragging = false
	self.Label = New("TextLabel", {
		Text = config.Name or "Slider",
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = Google.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -70, 0, 20),
		Position = UDim2.fromOffset(0, 4),
		Parent = self.Instance
	})
	self.ValueLabel = New("TextLabel", {
		Text = tostring(self.Value),
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Google.Theme.Primary,
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 64, 0, 20),
		Position = UDim2.new(1, -64, 0, 4),
		Parent = self.Instance
	})
	self.Track = New("Frame", {
		Size = UDim2.new(1, 0, 0, 6),
		Position = UDim2.fromOffset(0, 34),
		BackgroundColor3 = Google.Theme.Border,
		BorderSizePixel = 0,
		Parent = self.Instance
	})
	Corner(self.Track, 6)
	self.Fill = New("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Google.Theme.Primary,
		BorderSizePixel = 0,
		Parent = self.Track
	})
	Corner(self.Fill, 6)
	self.Knob = New("Frame", {
		Size = UDim2.fromOffset(14, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		BackgroundColor3 = Google.Theme.Primary,
		BorderSizePixel = 0,
		Parent = self.Track
	})
	Corner(self.Knob, 7)
	self.KnobStroke = Stroke(self.Knob, Google.Theme.Card, 0, 2)
	local function round(value)
		local precision = self.Precision
		if precision <= 0 then
			return math.floor(value + 0.5)
		end
		local power = 10 ^ precision
		return math.floor(value * power + 0.5) / power
	end
	function self:UpdateVisual()
		local alpha = 0
		if self.Max ~= self.Min then
			alpha = math.clamp((self.Value - self.Min) / (self.Max - self.Min), 0, 1)
		end
		self.ValueLabel.Text = tostring(self.Value)
		self.Fill.Size = UDim2.fromScale(alpha, 1)
		self.Knob.Position = UDim2.fromScale(alpha, 0.5)
	end
	function self:Set(value)
		self.Value = round(math.clamp(value, self.Min, self.Max))
		self:UpdateVisual()
		self.Callback(self.Value)
	end
	function self:Get()
		return self.Value
	end
	local function setFromInput(input)
		local alpha = math.clamp((input.Position.X - self.Track.AbsolutePosition.X) / self.Track.AbsoluteSize.X, 0, 1)
		self:Set(self.Min + (self.Max - self.Min) * alpha)
	end
	Connect(self.Connections, self.Track.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self.Dragging = true
			setFromInput(input)
		end
	end)
	Connect(self.Connections, UserInputService.InputChanged, function(input)
		if self.Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setFromInput(input)
		end
	end)
	Connect(self.Connections, UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self.Dragging = false
		end
	end)
	function self:ApplyTheme()
		self.Label.TextColor3 = Google.Theme.Text
		self.ValueLabel.TextColor3 = Google.Theme.Primary
		self.Track.BackgroundColor3 = Google.Theme.Border
		self.Fill.BackgroundColor3 = Google.Theme.Primary
		self.Knob.BackgroundColor3 = Google.Theme.Primary
		self.KnobStroke.Color = Google.Theme.Card
	end
	self:UpdateVisual()
	self:RefreshSection()
	return self
end

function Section:AddSlider(index, config)
	if type(index) == "table" then
		return self:CreateSlider(index)
	end
	config = config or {}
	config.Name = config.Name or config.Text or index
	return self:CreateSlider(config)
end

function Section:CreateDropdown(config)
	config = config or {}
	local self = Control(self, 40, "Dropdown")
	self.Options = config.Options or config.Values or {}
	self.Value = config.Default or self.Options[1]
	self.Callback = config.Callback or function() end
	self.Open = false
	self.Searchable = config.Searchable or false
	self.Multi = config.Multi or false
	if self.Multi and type(self.Value) ~= "table" then
		self.Value = self.Value and {self.Value} or {}
	end
	self.Main = New("TextButton", {
		Text = "",
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = Google.Theme.Input,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Parent = self.Instance
	})
	Corner(self.Main, 7)
	self.MainStroke = Stroke(self.Main, Google.Theme.Border, 0.08, 1)
	self.Label = New("TextLabel", {
		Text = config.Name or "Dropdown",
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = Google.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		BackgroundTransparency = 1,
		Size = UDim2.new(0.45, -12, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		Parent = self.Main
	})
	self.SelectedLabel = New("TextLabel", {
		Text = self.Multi and (#self.Value > 0 and table.concat(self.Value, ", ") or "Select") or tostring(self.Value or "Select"),
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = Google.Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		BackgroundTransparency = 1,
		Size = UDim2.new(0.55, -44, 1, 0),
		Position = UDim2.new(0.45, 0, 0, 0),
		Parent = self.Main
	})
	self.Arrow = Google.CreateIcon("chevron-down", 15, Google.Theme.Muted, self.Main, {
		Position = UDim2.new(1, -27, 0.5, -7)
	})
	self.Menu = New("Frame", {
		Name = "Menu",
		Position = UDim2.fromOffset(0, 42),
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = Google.Theme.Card,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Visible = false,
		Parent = self.Instance
	})
	Corner(self.Menu, 7)
	self.MenuStroke = Stroke(self.Menu, Google.Theme.Border, 0.08, 1)
	local searchOffset = 0
	if self.Searchable then
		self.SearchBox = New("TextBox", {
			Text = "",
			PlaceholderText = "Search",
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = Google.Theme.Text,
			PlaceholderColor3 = Google.Theme.Subtle,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, -12, 0, 28),
			Position = UDim2.fromOffset(6, 6),
			BackgroundColor3 = Google.Theme.Input,
			BorderSizePixel = 0,
			Parent = self.Menu
		})
		Corner(self.SearchBox, 6)
		self.SearchStroke = Stroke(self.SearchBox, Google.Theme.Border, 0.08, 1)
		Padding(self.SearchBox, 8, 8, 0, 0)
		searchOffset = 36
	end
	self.OptionsFrame = New("ScrollingFrame", {
		Size = UDim2.new(1, -6, 1, -searchOffset - 6),
		Position = UDim2.fromOffset(3, searchOffset + 3),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		CanvasSize = UDim2.fromOffset(0, 0),
		Parent = self.Menu
	})
	self.OptionLayout = New("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 2),
		Parent = self.OptionsFrame
	})
	function self:DisplayValue()
		if self.Multi then
			self.SelectedLabel.Text = #self.Value > 0 and table.concat(self.Value, ", ") or "Select"
		else
			self.SelectedLabel.Text = tostring(self.Value or "Select")
		end
	end
	function self:RefreshOptions()
		for _, child in ipairs(self.OptionsFrame:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		for i, option in ipairs(self.Options) do
			local item = New("TextButton", {
				Name = tostring(option),
				Text = "",
				Size = UDim2.new(1, -4, 0, 28),
				BackgroundColor3 = Google.Theme.Hover,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				LayoutOrder = i,
				Parent = self.OptionsFrame
			})
			Corner(item, 6)
			local label = New("TextLabel", {
				Text = tostring(option),
				Font = Enum.Font.Gotham,
				TextSize = 13,
				TextColor3 = Google.Theme.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -14, 1, 0),
				Position = UDim2.fromOffset(8, 0),
				Parent = item
			})
			Connect(self.Connections, item.MouseEnter, function()
				Tween(item, {BackgroundTransparency = 0}, 0.1)
			end)
			Connect(self.Connections, item.MouseLeave, function()
				Tween(item, {BackgroundTransparency = 1}, 0.1)
			end)
			Connect(self.Connections, item.MouseButton1Click, function()
				self:Select(option)
			end)
		end
		self.OptionsFrame.CanvasSize = UDim2.fromOffset(0, self.OptionLayout.AbsoluteContentSize.Y + 8)
	end
	function self:Filter(query)
		query = string.lower(query or "")
		for _, item in ipairs(self.OptionsFrame:GetChildren()) do
			if item:IsA("TextButton") then
				item.Visible = query == "" or string.find(string.lower(item.Name), query, 1, true) ~= nil
			end
		end
	end
	function self:OpenMenu()
		self.Open = true
		self.Menu.Visible = true
		local optionHeight = math.min(#self.Options * 30 + (self.Searchable and 40 or 6), 156)
		self.Instance.Size = UDim2.new(1, 0, 0, 44 + optionHeight)
		Tween(self.Menu, {Size = UDim2.new(1, 0, 0, optionHeight)}, 0.14)
		self:RefreshSection()
	end
	function self:CloseMenu()
		self.Open = false
		self.Instance.Size = UDim2.new(1, 0, 0, 40)
		Tween(self.Menu, {Size = UDim2.new(1, 0, 0, 0)}, 0.12, nil, nil, function()
			self.Menu.Visible = false
		end)
		self:RefreshSection()
	end
	function self:Select(option)
		if self.Multi then
			local found = nil
			for index, value in ipairs(self.Value) do
				if value == option then
					found = index
					break
				end
			end
			if found then
				table.remove(self.Value, found)
			else
				table.insert(self.Value, option)
			end
			self:DisplayValue()
			self.Callback(self.Value)
		else
			self.Value = option
			self:DisplayValue()
			self.Callback(option)
			self:CloseMenu()
		end
	end
	function self:Set(value)
		self.Value = value
		self:DisplayValue()
		self.Callback(value)
	end
	function self:Get()
		return self.Value
	end
	function self:Refresh(newOptions)
		if newOptions then
			self.Options = newOptions
		end
		self:RefreshOptions()
	end
	Connect(self.Connections, self.Main.MouseButton1Click, function()
		if self.Open then
			self:CloseMenu()
		else
			self:OpenMenu()
		end
	end)
	if self.SearchBox then
		Connect(self.Connections, self.SearchBox:GetPropertyChangedSignal("Text"), function()
			self:Filter(self.SearchBox.Text)
		end)
	end
	function self:ApplyTheme()
		self.Main.BackgroundColor3 = Google.Theme.Input
		self.MainStroke.Color = Google.Theme.Border
		self.Label.TextColor3 = Google.Theme.Text
		self.SelectedLabel.TextColor3 = Google.Theme.Muted
		Google.SetIconColor(self.Arrow, Google.Theme.Muted)
		self.Menu.BackgroundColor3 = Google.Theme.Card
		self.MenuStroke.Color = Google.Theme.Border
		self.OptionsFrame.ScrollBarImageColor3 = Google.Theme.BorderStrong
		if self.SearchBox then
			self.SearchBox.BackgroundColor3 = Google.Theme.Input
			self.SearchBox.TextColor3 = Google.Theme.Text
			self.SearchBox.PlaceholderColor3 = Google.Theme.Subtle
			self.SearchStroke.Color = Google.Theme.Border
		end
		for _, item in ipairs(self.OptionsFrame:GetChildren()) do
			if item:IsA("TextButton") then
				item.BackgroundColor3 = Google.Theme.Hover
				local label = item:FindFirstChildOfClass("TextLabel")
				if label then
					label.TextColor3 = Google.Theme.Text
				end
			end
		end
	end
	self:RefreshOptions()
	self:DisplayValue()
	self:RefreshSection()
	return self
end

function Section:AddDropdown(index, config)
	if type(index) == "table" then
		return self:CreateDropdown(index)
	end
	config = config or {}
	config.Name = config.Name or config.Text or index
	return self:CreateDropdown(config)
end

function Section:CreateTextbox(config)
	config = config or {}
	local self = Control(self, 58, "Textbox")
	self.Value = config.Default or ""
	self.Numeric = config.Numeric or false
	self.Callback = config.Callback or function() end
	self.Label = New("TextLabel", {
		Text = config.Name or "Textbox",
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = Google.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.fromOffset(0, 0),
		Parent = self.Instance
	})
	self.Entry = New("TextBox", {
		Text = tostring(self.Value),
		PlaceholderText = config.Placeholder or "",
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = Google.Theme.Text,
		PlaceholderColor3 = Google.Theme.Subtle,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 32),
		Position = UDim2.fromOffset(0, 24),
		BackgroundColor3 = Google.Theme.Input,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Parent = self.Instance
	})
	Corner(self.Entry, 7)
	Padding(self.Entry, 10, 10, 0, 0)
	self.EntryStroke = Stroke(self.Entry, Google.Theme.Border, 0.08, 1)
	function self:Set(value)
		if self.Numeric then
			local numberValue = tonumber(value)
			if numberValue then
				self.Value = numberValue
			end
		else
			self.Value = tostring(value)
		end
		self.Entry.Text = tostring(self.Value)
		self.Callback(self.Value)
	end
	function self:Get()
		return self.Value
	end
	Connect(self.Connections, self.Entry.FocusLost, function()
		self:Set(self.Entry.Text)
	end)
	function self:ApplyTheme()
		self.Label.TextColor3 = Google.Theme.Text
		self.Entry.BackgroundColor3 = Google.Theme.Input
		self.Entry.TextColor3 = Google.Theme.Text
		self.Entry.PlaceholderColor3 = Google.Theme.Subtle
		self.EntryStroke.Color = Google.Theme.Border
	end
	self:RefreshSection()
	return self
end

function Section:AddInput(index, config)
	if type(index) == "table" then
		return self:CreateTextbox(index)
	end
	config = config or {}
	config.Name = config.Name or config.Text or index
	return self:CreateTextbox(config)
end

function Section:CreateKeybind(config)
	config = config or {}
	local self = Control(self, 36, "Keybind")
	self.Value = config.Default or Enum.KeyCode.RightShift
	self.Mode = config.Mode or "Toggle"
	self.Callback = config.Callback or function() end
	self.Holding = false
	self.Binding = false
	self.Label = New("TextLabel", {
		Text = config.Name or "Keybind",
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = Google.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -92, 1, 0),
		Parent = self.Instance
	})
	self.Button = New("TextButton", {
		Text = self.Value.Name,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = Google.Theme.Text,
		Size = UDim2.fromOffset(80, 28),
		Position = UDim2.new(1, -80, 0.5, -14),
		BackgroundColor3 = Google.Theme.Input,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Parent = self.Instance
	})
	Corner(self.Button, 7)
	self.ButtonStroke = Stroke(self.Button, Google.Theme.Border, 0.08, 1)
	function self:Set(keycode)
		self.Value = keycode
		self.Button.Text = keycode.Name
	end
	function self:Get()
		return self.Value
	end
	Connect(self.Connections, self.Button.MouseButton1Click, function()
		self.Binding = true
		self.Button.Text = "..."
	end)
	Connect(self.Connections, UserInputService.InputBegan, function(input, processed)
		if processed then
			return
		end
		if self.Binding then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				self:Set(input.KeyCode)
				self.Binding = false
			end
			return
		end
		if input.KeyCode == self.Value then
			if self.Mode == "Hold" then
				self.Holding = true
				self.Callback(true)
			else
				self.Holding = not self.Holding
				self.Callback(self.Holding)
			end
		end
	end)
	Connect(self.Connections, UserInputService.InputEnded, function(input)
		if input.KeyCode == self.Value and self.Mode == "Hold" then
			self.Holding = false
			self.Callback(false)
		end
	end)
	function self:ApplyTheme()
		self.Label.TextColor3 = Google.Theme.Text
		self.Button.BackgroundColor3 = Google.Theme.Input
		self.Button.TextColor3 = Google.Theme.Text
		self.ButtonStroke.Color = Google.Theme.Border
	end
	self:RefreshSection()
	return self
end

function Section:AddKeybind(index, config)
	if type(index) == "table" then
		return self:CreateKeybind(index)
	end
	config = config or {}
	config.Name = config.Name or config.Text or index
	return self:CreateKeybind(config)
end

function Section:CreateColorPicker(config)
	config = config or {}
	local self = Control(self, 38, "ColorPicker")
	self.Value = config.Default or Google.Theme.Primary
	self.Callback = config.Callback or function() end
	self.Open = false
	self.Colors = config.Colors or {
		Color3.fromRGB(26, 115, 232),
		Color3.fromRGB(52, 168, 83),
		Color3.fromRGB(251, 188, 4),
		Color3.fromRGB(234, 67, 53),
		Color3.fromRGB(99, 102, 241),
		Color3.fromRGB(14, 165, 233),
		Color3.fromRGB(245, 158, 11),
		Color3.fromRGB(236, 72, 153)
	}
	self.Label = New("TextLabel", {
		Text = config.Name or "Color",
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = Google.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -52, 0, 34),
		Parent = self.Instance
	})
	self.Button = New("TextButton", {
		Text = "",
		Size = UDim2.fromOffset(34, 28),
		Position = UDim2.new(1, -34, 0, 4),
		BackgroundColor3 = self.Value,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Parent = self.Instance
	})
	Corner(self.Button, 7)
	self.ButtonStroke = Stroke(self.Button, Google.Theme.Border, 0.08, 1)
	self.Palette = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.fromOffset(0, 42),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
		Parent = self.Instance
	})
	self.PaletteLayout = New("UIGridLayout", {
		CellSize = UDim2.fromOffset(28, 28),
		CellPadding = UDim2.fromOffset(6, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = self.Palette
	})
	function self:Set(color)
		if IsColor(color) then
			self.Value = color
			self.Button.BackgroundColor3 = color
			self.Callback(color)
		end
	end
	function self:Get()
		return self.Value
	end
	for i, color in ipairs(self.Colors) do
		local swatch = New("TextButton", {
			Text = "",
			Size = UDim2.fromOffset(28, 28),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			LayoutOrder = i,
			AutoButtonColor = false,
			Parent = self.Palette
		})
		Corner(swatch, 7)
		Stroke(swatch, Google.Theme.Border, 0.12, 1)
		Connect(self.Connections, swatch.MouseButton1Click, function()
			self:Set(color)
		end)
	end
	local function togglePalette()
		self.Open = not self.Open
		self.Palette.Visible = self.Open
		self.Instance.Size = UDim2.new(1, 0, 0, self.Open and 78 or 38)
		self:RefreshSection()
	end
	Connect(self.Connections, self.Button.MouseButton1Click, togglePalette)
	function self:ApplyTheme()
		self.Label.TextColor3 = Google.Theme.Text
		self.ButtonStroke.Color = Google.Theme.Border
	end
	self:RefreshSection()
	return self
end

function Section:AddColorPicker(index, config)
	if type(index) == "table" then
		return self:CreateColorPicker(index)
	end
	config = config or {}
	config.Name = config.Name or config.Text or config.Title or index
	return self:CreateColorPicker(config)
end

function Section:CreateLabel(config)
	if type(config) == "string" then
		config = {Name = config}
	end
	config = config or {}
	local self = Control(self, 24, "Label")
	self.Label = New("TextLabel", {
		Text = config.Name or config.Text or "Label",
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = Google.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = self.Instance
	})
	function self:Set(text)
		self.Label.Text = tostring(text)
	end
	function self:ApplyTheme()
		self.Label.TextColor3 = Google.Theme.Text
	end
	self:RefreshSection()
	return self
end

function Section:AddLabel(config)
	return self:CreateLabel(config)
end

function Section:CreateParagraph(config)
	config = config or {}
	local text = config.Content or config.Text or config.Description or "Paragraph"
	local title = config.Title or config.Name
	local height = title and 64 or 48
	local self = Control(self, height, "Paragraph")
	self.Instance.BackgroundTransparency = 0
	self.Instance.BackgroundColor3 = Google.Theme.CardAlt
	Corner(self.Instance, 7)
	self.Stroke = Stroke(self.Instance, Google.Theme.Border, 0.1, 1)
	if title then
		self.TitleLabel = New("TextLabel", {
			Text = title,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextColor3 = Google.Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -20, 0, 18),
			Position = UDim2.fromOffset(10, 8),
			Parent = self.Instance
		})
	end
	self.TextLabel = New("TextLabel", {
		Text = text,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Google.Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -20, 1, title and -34 or -16),
		Position = UDim2.fromOffset(10, title and 30 or 8),
		Parent = self.Instance
	})
	function self:ApplyTheme()
		self.Instance.BackgroundColor3 = Google.Theme.CardAlt
		self.Stroke.Color = Google.Theme.Border
		if self.TitleLabel then
			self.TitleLabel.TextColor3 = Google.Theme.Text
		end
		self.TextLabel.TextColor3 = Google.Theme.Muted
	end
	self:RefreshSection()
	return self
end

function Section:AddParagraph(config)
	return self:CreateParagraph(config)
end

function Section:CreateDivider(config)
	config = config or {}
	if type(config) == "string" then
		config = {Name = config}
	end
	local self = Control(self, config.Name and 24 or 16, "Divider")
	if config.Name then
		self.Label = New("TextLabel", {
			Text = config.Name,
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			TextColor3 = Google.Theme.Muted,
			TextXAlignment = Enum.TextXAlignment.Center,
			BackgroundTransparency = 1,
			Size = UDim2.new(0.32, 0, 1, 0),
			Position = UDim2.fromScale(0.34, 0),
			Parent = self.Instance
		})
		self.Left = New("Frame", {
			Size = UDim2.new(0.34, -8, 0, 1),
			Position = UDim2.new(0, 0, 0.5, 0),
			BackgroundColor3 = Google.Theme.Border,
			BorderSizePixel = 0,
			Parent = self.Instance
		})
		self.Right = New("Frame", {
			Size = UDim2.new(0.34, -8, 0, 1),
			Position = UDim2.new(0.66, 8, 0.5, 0),
			BackgroundColor3 = Google.Theme.Border,
			BorderSizePixel = 0,
			Parent = self.Instance
		})
	else
		self.Line = New("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 0.5, 0),
			BackgroundColor3 = Google.Theme.Border,
			BorderSizePixel = 0,
			Parent = self.Instance
		})
	end
	function self:ApplyTheme()
		if self.Label then
			self.Label.TextColor3 = Google.Theme.Muted
		end
		if self.Left then self.Left.BackgroundColor3 = Google.Theme.Border end
		if self.Right then self.Right.BackgroundColor3 = Google.Theme.Border end
		if self.Line then self.Line.BackgroundColor3 = Google.Theme.Border end
	end
	self:RefreshSection()
	return self
end

function Section:AddDivider(config)
	return self:CreateDivider(config)
end

function Window:ApplyTheme()
	local theme = Google.Theme
	self.Instance.BackgroundColor3 = theme.Window
	self.Body.BackgroundColor3 = theme.Window
	self.MainStroke.Color = theme.Border
	self.Shadow.ImageColor3 = theme.Shadow
	self.Topbar.BackgroundColor3 = theme.Topbar
	self.TopbarLine.BackgroundColor3 = theme.Border
	self.Sidebar.BackgroundColor3 = theme.Sidebar
	self.SidebarLine.BackgroundColor3 = theme.Border
	self.PageWrap.BackgroundColor3 = theme.Page
	self.TitleIconWrap.BackgroundColor3 = theme.PrimarySoft
	Google.SetIconColor(self.TitleIcon, theme.Primary)
	self.TitleLabel.TextColor3 = theme.Text
	self.SubtitleLabel.TextColor3 = theme.Muted
	self.MinimizeButton.BackgroundColor3 = theme.Hover
	self.CloseButton.BackgroundColor3 = theme.Hover
	Google.SetIconColor(self.MinimizeIcon, theme.Muted)
	Google.SetIconColor(self.CloseIcon, theme.Muted)
	for _, tab in ipairs(self.Tabs) do
		tab:ApplyTheme()
	end
end

function Window:Minimize()
	if self.Minimized then
		return
	end
	self.Minimized = true
	self.Sidebar.Visible = false
	self.PageWrap.Visible = false
	Tween(self.Instance, {Size = UDim2.fromOffset(self.Instance.AbsoluteSize.X, 54)}, 0.18)
end

function Window:Restore()
	if not self.Minimized then
		return
	end
	self.Minimized = false
	Tween(self.Instance, {Size = self.Size}, 0.18, nil, nil, function()
		self.Sidebar.Visible = true
		self.PageWrap.Visible = true
	end)
end

function Window:Hide()
	self.Gui.Enabled = false
	self.Visible = false
end

function Window:Show()
	self.Gui.Enabled = true
	self.Visible = true
end

function Window:Toggle()
	if self.Gui.Enabled then
		self:Hide()
	else
		self:Show()
	end
end

function Window:Destroy()
	DisconnectAll(self.Connections)
	for _, tab in ipairs(self.Tabs) do
		if tab.Destroy then
			tab:Destroy()
		end
	end
	for index, window in ipairs(Google.Windows) do
		if window == self then
			table.remove(Google.Windows, index)
			break
		end
	end
	if self.Gui then
		self.Gui:Destroy()
	end
end

function Tab:Destroy()
	DisconnectAll(self.Connections)
	for _, section in ipairs(self.Sections) do
		if section.Destroy then
			section:Destroy()
		end
	end
	if self.Button then self.Button:Destroy() end
	if self.Page then self.Page:Destroy() end
end

function Section:Destroy()
	DisconnectAll(self.Connections)
	for _, control in ipairs(self.Controls) do
		if control.Destroy then
			control:Destroy()
		end
	end
	if self.Instance then self.Instance:Destroy() end
end

function ControlBase:Destroy()
	DisconnectAll(self.Connections)
	if self.Instance then
		self.Instance:Destroy()
	end
end

local NotificationManager = {
	Gui = nil,
	Holder = nil,
	Items = {}
}

function NotificationManager:Init()
	if self.Gui then
		return
	end
	self.Gui = New("ScreenGui", {
		Name = "GoogleUINotifications",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = SafeParent()
	})
	self.Holder = New("Frame", {
		Name = "Holder",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = self.Gui
	})
end

function NotificationManager:Update()
	local offset = 18
	for i = #self.Items, 1, -1 do
		local frame = self.Items[i]
		if frame and frame.Parent then
			Tween(frame, {Position = UDim2.new(1, -18, 1, -offset)}, 0.16)
			offset = offset + frame.Size.Y.Offset + 8
		end
	end
end

function NotificationManager:Push(config)
	self:Init()
	config = config or {}
	local duration = config.Duration or 3
	local frame = New("Frame", {
		Size = UDim2.fromOffset(292, 62),
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 310, 1, -18),
		BackgroundColor3 = Google.Theme.Card,
		BorderSizePixel = 0,
		Parent = self.Holder
	})
	Corner(frame, 9)
	Stroke(frame, Google.Theme.Border, 0.05, 1)
	local iconWrap = New("Frame", {
		Size = UDim2.fromOffset(34, 34),
		Position = UDim2.fromOffset(12, 14),
		BackgroundColor3 = Google.Theme.PrimarySoft,
		BorderSizePixel = 0,
		Parent = frame
	})
	Corner(iconWrap, 8)
	Google.CreateIcon(config.Icon or "info", 18, config.IconColor or Google.Theme.Primary, iconWrap, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5)
	})
	New("TextLabel", {
		Text = config.Title or "Notification",
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Google.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -64, 0, 18),
		Position = UDim2.fromOffset(56, 12),
		Parent = frame
	})
	New("TextLabel", {
		Text = config.Description or "",
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Google.Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -64, 0, 26),
		Position = UDim2.fromOffset(56, 30),
		Parent = frame
	})
	local progress = New("Frame", {
		Size = UDim2.new(1, 0, 0, 2),
		Position = UDim2.new(0, 0, 1, -2),
		BackgroundColor3 = Google.Theme.Primary,
		BorderSizePixel = 0,
		Parent = frame
	})
	Corner(progress, 2)
	table.insert(self.Items, frame)
	self:Update()
	Tween(frame, {Position = UDim2.new(1, -18, 1, -18)}, 0.2)
	Tween(progress, {Size = UDim2.new(0, 0, 0, 2)}, duration, Enum.EasingStyle.Linear)
	coroutine.wrap(function()
		wait(duration)
		Tween(frame, {Position = UDim2.new(1, 310, frame.Position.Y.Scale, frame.Position.Y.Offset), BackgroundTransparency = 1}, 0.2, nil, nil, function()
			for i, item in ipairs(self.Items) do
				if item == frame then
					table.remove(self.Items, i)
					break
				end
			end
			frame:Destroy()
			self:Update()
		end)
	end)()
end

function Google.Notify(config)
	NotificationManager:Push(config)
end

function Google:Notify(config)
	NotificationManager:Push(config)
end

function Google:Confirm(config)
	config = config or {}
	local callback = config.Callback or function() end
	local gui = New("ScreenGui", {
		Name = "GoogleUIConfirm",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = SafeParent()
	})
	local overlay = New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		Parent = gui
	})
	local dialog = New("Frame", {
		Size = UDim2.fromOffset(320, 142),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = Google.Theme.Card,
		BorderSizePixel = 0,
		Parent = overlay
	})
	Corner(dialog, 10)
	Stroke(dialog, Google.Theme.Border, 0.05, 1)
	New("TextLabel", {
		Text = config.Title or "Confirm",
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextColor3 = Google.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -28, 0, 22),
		Position = UDim2.fromOffset(14, 14),
		Parent = dialog
	})
	New("TextLabel", {
		Text = config.Description or "Are you sure?",
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Google.Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -28, 0, 42),
		Position = UDim2.fromOffset(14, 42),
		Parent = dialog
	})
	local cancel = New("TextButton", {
		Text = config.CancelText or "Cancel",
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Google.Theme.Text,
		Size = UDim2.fromOffset(92, 32),
		Position = UDim2.new(1, -204, 1, -44),
		BackgroundColor3 = Google.Theme.Hover,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Parent = dialog
	})
	Corner(cancel, 7)
	local confirm = New("TextButton", {
		Text = config.ConfirmText or "Confirm",
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Color3.new(1, 1, 1),
		Size = UDim2.fromOffset(92, 32),
		Position = UDim2.new(1, -106, 1, -44),
		BackgroundColor3 = Google.Theme.Primary,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Parent = dialog
	})
	Corner(confirm, 7)
	cancel.MouseButton1Click:Connect(function()
		gui:Destroy()
		callback(false)
	end)
	confirm.MouseButton1Click:Connect(function()
		gui:Destroy()
		callback(true)
	end)
end

function Google:Prompt(config)
	config = config or {}
	local callback = config.Callback or function() end
	local gui = New("ScreenGui", {
		Name = "GoogleUIPrompt",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = SafeParent()
	})
	local overlay = New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		Parent = gui
	})
	local dialog = New("Frame", {
		Size = UDim2.fromOffset(330, 170),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = Google.Theme.Card,
		BorderSizePixel = 0,
		Parent = overlay
	})
	Corner(dialog, 10)
	Stroke(dialog, Google.Theme.Border, 0.05, 1)
	New("TextLabel", {
		Text = config.Title or "Input",
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextColor3 = Google.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -28, 0, 22),
		Position = UDim2.fromOffset(14, 12),
		Parent = dialog
	})
	New("TextLabel", {
		Text = config.Description or "",
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Google.Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -28, 0, 28),
		Position = UDim2.fromOffset(14, 36),
		Parent = dialog
	})
	local input = New("TextBox", {
		Text = config.Default or "",
		PlaceholderText = config.Placeholder or "",
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = Google.Theme.Text,
		PlaceholderColor3 = Google.Theme.Subtle,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Size = UDim2.new(1, -28, 0, 34),
		Position = UDim2.fromOffset(14, 72),
		BackgroundColor3 = Google.Theme.Input,
		BorderSizePixel = 0,
		Parent = dialog
	})
	Corner(input, 7)
	Stroke(input, Google.Theme.Border, 0.08, 1)
	Padding(input, 10, 10, 0, 0)
	local cancel = New("TextButton", {
		Text = config.CancelText or "Cancel",
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Google.Theme.Text,
		Size = UDim2.fromOffset(92, 32),
		Position = UDim2.new(1, -204, 1, -44),
		BackgroundColor3 = Google.Theme.Hover,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Parent = dialog
	})
	Corner(cancel, 7)
	local confirm = New("TextButton", {
		Text = config.ConfirmText or "Submit",
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Color3.new(1, 1, 1),
		Size = UDim2.fromOffset(92, 32),
		Position = UDim2.new(1, -106, 1, -44),
		BackgroundColor3 = Google.Theme.Primary,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Parent = dialog
	})
	Corner(confirm, 7)
	cancel.MouseButton1Click:Connect(function()
		gui:Destroy()
		callback(nil)
	end)
	confirm.MouseButton1Click:Connect(function()
		local text = input.Text
		gui:Destroy()
		callback(text)
	end)
	input:CaptureFocus()
end

function Google:Cleanup()
	for _, window in ipairs(table.clone(Google.Windows)) do
		window:Destroy()
	end
	if NotificationManager.Gui then
		NotificationManager.Gui:Destroy()
		NotificationManager.Gui = nil
		NotificationManager.Holder = nil
		NotificationManager.Items = {}
	end
end

return Google
