local Google = {}
Google.__index = Google

local function getService(name)
	local service = game:GetService(name)
	return if cloneref then cloneref(service) else service
end

local TweenService = getService("TweenService")
local UserInputService = getService("UserInputService")
local Players = getService("Players")
local CoreGui = getService("CoreGui")
local Workspace = getService("Workspace")

local LocalPlayer = Players.LocalPlayer

local function getGuiHost()
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

local function clearOldWindows(primaryParent)
	local targets = {}
	local function add(parent)
		if parent and not targets[parent] then
			targets[parent] = true
		end
	end
	add(primaryParent)
	add(CoreGui)
	if LocalPlayer then
		add(LocalPlayer:FindFirstChildOfClass("PlayerGui"))
	end
	for parent in pairs(targets) do
		for _, child in ipairs(parent:GetChildren()) do
			local name = child.Name
			if child:IsA("ScreenGui") and (name == "GoogleUI" or name == "GoogleNotifications" or name == "GoogleUINotifications" or string.sub(name, 1, 13) == "GoogleWindow_") then
				pcall(function()
					child:Destroy()
				end)
			end
		end
	end
end

local function create(className, properties)
	local object = Instance.new(className)
	if properties then
		for property, value in pairs(properties) do
			object[property] = value
		end
	end
	return object
end

local function round(parent, radius)
	local corner = create("UICorner", {
		CornerRadius = UDim.new(0, radius or 6),
		Parent = parent
	})
	return corner
end

local function roundFull(parent)
	local corner = create("UICorner", {
		CornerRadius = UDim.new(1, 0),
		Parent = parent
	})
	return corner
end

local function outline(parent, color, transparency, thickness)
	local stroke = create("UIStroke", {
		Color = color,
		Transparency = transparency or 0,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent
	})
	return stroke
end

local function pad(parent, left, right, top, bottom)
	local padding = create("UIPadding", {
		PaddingLeft = UDim.new(0, left or 0),
		PaddingRight = UDim.new(0, right or 0),
		PaddingTop = UDim.new(0, top or 0),
		PaddingBottom = UDim.new(0, bottom or 0),
		Parent = parent
	})
	return padding
end

local motion = {
	Fast = 0.12,
	Base = 0.18,
	Slow = 0.26,
	Mobile = 0.22,
	Style = Enum.EasingStyle.Quint,
	Direction = Enum.EasingDirection.Out
}

local runningTweens = setmetatable({}, {__mode = "k"})

local function animate(object, properties, duration, style, direction, callback)
	if not object then
		return nil
	end
	if runningTweens[object] then
		pcall(function()
			runningTweens[object]:Cancel()
		end)
		runningTweens[object] = nil
	end
	local ok, tween = pcall(function()
		return TweenService:Create(object, TweenInfo.new(duration or motion.Base, style or motion.Style, direction or motion.Direction), properties)
	end)
	if not ok or not tween then
		for property, value in pairs(properties) do
			pcall(function()
				object[property] = value
			end)
		end
		if callback then
			callback()
		end
		return nil
	end
	runningTweens[object] = tween
	local connection
	connection = tween.Completed:Connect(function()
		if connection then
			connection:Disconnect()
		end
		if runningTweens[object] == tween then
			runningTweens[object] = nil
		end
		if callback then
			callback()
		end
	end)
	tween:Play()
	return tween
end

local function shrinkOffsetSize(size, offset)
	if size.X.Scale == 0 and size.Y.Scale == 0 then
		return UDim2.fromOffset(math.max(0, size.X.Offset + offset), math.max(0, size.Y.Offset + offset))
	end
	return size
end

local function bind(list, signal, callback)
	local connection = signal:Connect(callback)
	table.insert(list, connection)
	return connection
end

local function disconnectAll(list)
	for _, connection in ipairs(list) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	table.clear(list)
end

local function isColor(value)
	return typeof(value) == "Color3"
end

local function assetIdFromImage(value)
	if typeof(value) == "number" then
		return tostring(value)
	end
	if type(value) ~= "string" then
		return nil
	end
	local numberId = value:match("^%d+$")
	if numberId then
		return numberId
	end
	local assetId = value:match("rbxassetid://(%d+)")
	if assetId then
		return assetId
	end
	local thumbId = value:match("id=(%d+)")
	if thumbId then
		return thumbId
	end
	return nil
end

local function imageSource(value)
	if typeof(value) == "number" then
		return "rbxassetid://" .. tostring(value)
	end

	if type(value) ~= "string" then
		return ""
	end

	if value:match("^%d+$") then
		return "rbxassetid://" .. value
	end

	return value
end

local function imageThumbnail(value)
	local id = assetIdFromImage(value)
	if not id then
		return ""
	end
	return "rbxthumb://type=Asset&id=" .. id .. "&w=420&h=420"
end

local function imageScaleType(value)
	if typeof(value) == "EnumItem" then
		return value
	end
	if type(value) ~= "string" then
		return Enum.ScaleType.Fit
	end
	local key = string.lower(value)
	if key == "crop" then
		return Enum.ScaleType.Crop
	elseif key == "stretch" then
		return Enum.ScaleType.Stretch
	elseif key == "tile" then
		return Enum.ScaleType.Tile
	end
	return Enum.ScaleType.Fit
end

local function viewportSize()
	local camera = Workspace.CurrentCamera
	if camera then
		return camera.ViewportSize
	end
	return Vector2.new(1280, 720)
end

local function isMobileDevice()
	local viewport = viewportSize()
	local shortestSide = math.min(viewport.X, viewport.Y)
	return UserInputService.TouchEnabled and (not UserInputService.KeyboardEnabled or shortestSide <= 820)
end

local function mobileWindowSize(config)
	if config and config.MobileSize then
		return config.MobileSize
	end
	local viewport = viewportSize()
	local width = math.clamp(viewport.X - 20, 320, 520)
	local height = math.clamp(viewport.Y - 20, 360, 700)
	return UDim2.fromOffset(width, height)
end

local function blend(colorA, colorB, alpha)
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
	Red = {
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
		Primary = Color3.fromRGB(234, 67, 53),
		PrimaryHover = Color3.fromRGB(197, 48, 39),
		PrimarySoft = Color3.fromRGB(252, 232, 230),
		Success = Color3.fromRGB(52, 168, 83),
		Warning = Color3.fromRGB(251, 188, 4),
		Danger = Color3.fromRGB(234, 67, 53),
		Input = Color3.fromRGB(255, 255, 255),
		Hover = Color3.fromRGB(253, 242, 241),
		Shadow = Color3.fromRGB(15, 23, 42)
	},
	Yellow = {
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
		Primary = Color3.fromRGB(251, 188, 4),
		PrimaryHover = Color3.fromRGB(240, 164, 0),
		PrimarySoft = Color3.fromRGB(254, 247, 224),
		Success = Color3.fromRGB(52, 168, 83),
		Warning = Color3.fromRGB(251, 188, 4),
		Danger = Color3.fromRGB(234, 67, 53),
		Input = Color3.fromRGB(255, 255, 255),
		Hover = Color3.fromRGB(255, 250, 235),
		Shadow = Color3.fromRGB(15, 23, 42)
	},
	Green = {
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
		Primary = Color3.fromRGB(52, 168, 83),
		PrimaryHover = Color3.fromRGB(30, 142, 62),
		PrimarySoft = Color3.fromRGB(230, 244, 234),
		Success = Color3.fromRGB(52, 168, 83),
		Warning = Color3.fromRGB(251, 188, 4),
		Danger = Color3.fromRGB(234, 67, 53),
		Input = Color3.fromRGB(255, 255, 255),
		Hover = Color3.fromRGB(240, 249, 244),
		Shadow = Color3.fromRGB(15, 23, 42)
	},
	DarkGoogle = {
		Window = Color3.fromRGB(18, 20, 24),
		Topbar = Color3.fromRGB(23, 26, 31),
		Sidebar = Color3.fromRGB(21, 24, 29),
		Page = Color3.fromRGB(14, 16, 20),
		Card = Color3.fromRGB(26, 30, 36),
		CardAlt = Color3.fromRGB(31, 36, 43),
		Text = Color3.fromRGB(238, 242, 247),
		Muted = Color3.fromRGB(156, 166, 182),
		Subtle = Color3.fromRGB(104, 116, 134),
		Border = Color3.fromRGB(43, 49, 59),
		BorderStrong = Color3.fromRGB(63, 71, 85),
		Primary = Color3.fromRGB(66, 133, 244),
		PrimaryHover = Color3.fromRGB(95, 157, 247),
		PrimarySoft = Color3.fromRGB(24, 47, 86),
		Success = Color3.fromRGB(52, 168, 83),
		Warning = Color3.fromRGB(251, 188, 4),
		Danger = Color3.fromRGB(234, 67, 53),
		Input = Color3.fromRGB(18, 21, 26),
		Hover = Color3.fromRGB(35, 40, 48),
		Shadow = Color3.fromRGB(0, 0, 0)
	},
	DarkRed = {
		Window = Color3.fromRGB(24, 18, 18),
		Topbar = Color3.fromRGB(31, 22, 21),
		Sidebar = Color3.fromRGB(29, 20, 20),
		Page = Color3.fromRGB(18, 13, 13),
		Card = Color3.fromRGB(36, 26, 25),
		CardAlt = Color3.fromRGB(43, 31, 30),
		Text = Color3.fromRGB(248, 238, 237),
		Muted = Color3.fromRGB(187, 153, 150),
		Subtle = Color3.fromRGB(137, 98, 95),
		Border = Color3.fromRGB(64, 42, 40),
		BorderStrong = Color3.fromRGB(92, 57, 54),
		Primary = Color3.fromRGB(234, 67, 53),
		PrimaryHover = Color3.fromRGB(247, 99, 87),
		PrimarySoft = Color3.fromRGB(83, 31, 28),
		Success = Color3.fromRGB(52, 168, 83),
		Warning = Color3.fromRGB(251, 188, 4),
		Danger = Color3.fromRGB(255, 96, 84),
		Input = Color3.fromRGB(24, 17, 17),
		Hover = Color3.fromRGB(52, 34, 32),
		Shadow = Color3.fromRGB(0, 0, 0)
	},
	DarkYellow = {
		Window = Color3.fromRGB(23, 21, 16),
		Topbar = Color3.fromRGB(31, 28, 20),
		Sidebar = Color3.fromRGB(28, 25, 18),
		Page = Color3.fromRGB(17, 15, 11),
		Card = Color3.fromRGB(35, 31, 22),
		CardAlt = Color3.fromRGB(42, 37, 26),
		Text = Color3.fromRGB(247, 242, 229),
		Muted = Color3.fromRGB(184, 169, 128),
		Subtle = Color3.fromRGB(135, 117, 78),
		Border = Color3.fromRGB(64, 56, 36),
		BorderStrong = Color3.fromRGB(92, 78, 46),
		Primary = Color3.fromRGB(251, 188, 4),
		PrimaryHover = Color3.fromRGB(255, 207, 68),
		PrimarySoft = Color3.fromRGB(81, 61, 17),
		Success = Color3.fromRGB(52, 168, 83),
		Warning = Color3.fromRGB(255, 207, 68),
		Danger = Color3.fromRGB(234, 67, 53),
		Input = Color3.fromRGB(24, 21, 15),
		Hover = Color3.fromRGB(50, 43, 27),
		Shadow = Color3.fromRGB(0, 0, 0)
	},
	DarkGreen = {
		Window = Color3.fromRGB(16, 22, 18),
		Topbar = Color3.fromRGB(21, 30, 24),
		Sidebar = Color3.fromRGB(19, 27, 22),
		Page = Color3.fromRGB(12, 17, 14),
		Card = Color3.fromRGB(24, 34, 28),
		CardAlt = Color3.fromRGB(29, 42, 34),
		Text = Color3.fromRGB(236, 246, 239),
		Muted = Color3.fromRGB(146, 181, 157),
		Subtle = Color3.fromRGB(96, 130, 106),
		Border = Color3.fromRGB(37, 57, 45),
		BorderStrong = Color3.fromRGB(52, 82, 63),
		Primary = Color3.fromRGB(52, 168, 83),
		PrimaryHover = Color3.fromRGB(73, 194, 105),
		PrimarySoft = Color3.fromRGB(21, 67, 39),
		Success = Color3.fromRGB(52, 168, 83),
		Warning = Color3.fromRGB(251, 188, 4),
		Danger = Color3.fromRGB(234, 67, 53),
		Input = Color3.fromRGB(14, 21, 17),
		Hover = Color3.fromRGB(31, 48, 38),
		Shadow = Color3.fromRGB(0, 0, 0)
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
		icon = create("ImageLabel", {
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
		icon = create("TextLabel", {
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
	self.DesktopSize = config.Size or UDim2.fromOffset(620, 420)
	self.MobileSize = config.MobileSize
	self.AutoMobile = config.Mobile == nil
	self.IsMobile = config.Mobile == true or (config.Mobile == nil and isMobileDevice())
	self.Size = self.IsMobile and mobileWindowSize(config) or self.DesktopSize
	self.Position = config.Position
	self.Tabs = {}
	self.ActiveTab = nil
	self.Connections = {}
	self.ThemeObjects = {}
	self.Minimized = false
	self.Visible = true
	self.NotifySide = config.NotifySide or "Right"

	local parent = config.Parent or getGuiHost()
	if config.AllowMultiple ~= true then
		clearOldWindows(parent)
	end

	local gui = create("ScreenGui", {
		Name = "GoogleUI",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = parent
	})
	self.Gui = gui

	local main = create("Frame", {
		Name = "Window",
		Size = shrinkOffsetSize(self.Size, -14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = self.Position or UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = gui
	})
	self.Instance = main

	local body = create("CanvasGroup", {
		Name = "Body",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Google.Theme.Window,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 2,
		Parent = main
	})
	self.BodyCorner = round(body, 20)
	self.Body = body
	self.MainStroke = outline(body, Google.Theme.Border, 1, 0)

	local topbar = create("Frame", {
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundColor3 = Google.Theme.Topbar,
		BorderSizePixel = 0,
		Parent = body
	})
	self.Topbar = topbar
	self.TopbarCorner = round(topbar, 0)

	local topbarLine = create("Frame", {
		Name = "TopbarLine",
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = Google.Theme.Border,
		BorderSizePixel = 0,
		Parent = topbar
	})
	self.TopbarLine = topbarLine

	local titleIconWrap = create("Frame", {
		Name = "TitleIconWrap",
		Size = UDim2.fromOffset(32, 32),
		Position = UDim2.fromOffset(14, 11),
		BackgroundColor3 = Google.Theme.PrimarySoft,
		BorderSizePixel = 0,
		Parent = topbar
	})
	round(titleIconWrap, 9)
	self.TitleIconWrap = titleIconWrap
	self.TitleIcon = Google.CreateIcon(self.Icon, 19, Google.Theme.Primary, titleIconWrap, {
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5)
	})

	local title = create("TextLabel", {
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

	local subtitle = create("TextLabel", {
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

	local controls = create("Frame", {
		Name = "WindowControls",
		Size = UDim2.fromOffset(76, 30),
		Position = UDim2.new(1, -88, 0, 12),
		BackgroundTransparency = 1,
		Parent = topbar
	})
	self.ControlsFrame = controls

	local minimizeButton = create("TextButton", {
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
	round(minimizeButton, 7)
	self.MinimizeButton = minimizeButton
	self.MinimizeIcon = Google.CreateIcon("minus", 16, Google.Theme.Muted, minimizeButton, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5)
	})

	local closeButton = create("TextButton", {
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
	round(closeButton, 7)
	self.CloseButton = closeButton
	self.CloseIcon = Google.CreateIcon("x", 15, Google.Theme.Muted, closeButton, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5)
	})

	bind(self.Connections, minimizeButton.MouseButton1Click, function()
		if self.Minimized then
			self:Restore()
		else
			self:Minimize()
		end
	end)
	bind(self.Connections, closeButton.MouseButton1Click, function()
		self:Destroy()
	end)
	bind(self.Connections, minimizeButton.MouseEnter, function()
		animate(minimizeButton, {BackgroundTransparency = 0}, motion.Fast)
	end)
	bind(self.Connections, minimizeButton.MouseLeave, function()
		animate(minimizeButton, {BackgroundTransparency = 1}, motion.Fast)
	end)
	bind(self.Connections, closeButton.MouseEnter, function()
		Google.SetIconColor(self.CloseIcon, Color3.new(1, 1, 1))
		animate(closeButton, {BackgroundColor3 = Google.Theme.Danger, BackgroundTransparency = 0}, motion.Fast)
	end)
	bind(self.Connections, closeButton.MouseLeave, function()
		Google.SetIconColor(self.CloseIcon, Google.Theme.Muted)
		animate(closeButton, {BackgroundColor3 = Google.Theme.Hover, BackgroundTransparency = 1}, motion.Fast)
	end)

	local sidebar = create("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 152, 1, -54),
		Position = UDim2.fromOffset(0, 54),
		BackgroundColor3 = Google.Theme.Sidebar,
		BorderSizePixel = 0,
		Parent = body
	})
	self.Sidebar = sidebar

	local sidebarLine = create("Frame", {
		Name = "SidebarLine",
		Size = UDim2.new(0, 1, 1, 0),
		Position = UDim2.new(1, -1, 0, 0),
		BackgroundColor3 = Google.Theme.Border,
		BorderSizePixel = 0,
		Parent = sidebar
	})
	self.SidebarLine = sidebarLine

	local tabList = create("ScrollingFrame", {
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

	local tabLayout = create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		pad = UDim.new(0, 4),
		Parent = tabList
	})
	self.TabLayout = tabLayout

	local pageWrap = create("Frame", {
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
	bind(self.Connections, topbar.InputBegan, function(input)
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
	bind(self.Connections, UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
		end
	end)

	bind(self.Connections, tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		self:UpdateTabListCanvas()
	end)

	local function bindViewport(camera)
		if camera then
			bind(self.Connections, camera:GetPropertyChangedSignal("ViewportSize"), function()
				if self.AutoMobile then
					self:UpdateResponsiveLayout()
				end
			end)
		end
	end
	bindViewport(Workspace.CurrentCamera)
	bind(self.Connections, Workspace:GetPropertyChangedSignal("CurrentCamera"), function()
		bindViewport(Workspace.CurrentCamera)
		if self.AutoMobile then
			self:UpdateResponsiveLayout(true)
		end
	end)

	table.insert(Google.Windows, self)
	self:UpdateResponsiveLayout(true)
	self:ApplyTheme()
	animate(main, {Size = self.Size}, motion.Slow, Enum.EasingStyle.Quint)
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

	local button = create("TextButton", {
		Name = tab.Name,
		Text = "",
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = Google.Theme.PrimarySoft,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Parent = self.TabList
	})
	round(button, 8)
	tab.Button = button

	local accent = create("Frame", {
		Name = "Accent",
		Size = UDim2.new(0, 3, 0, 18),
		Position = UDim2.fromOffset(0, 9),
		BackgroundColor3 = Google.Theme.Primary,
		BorderSizePixel = 0,
		Visible = false,
		Parent = button
	})
	round(accent, 4)
	tab.Accent = accent

	tab.IconLabel = Google.CreateIcon(tab.Icon, 17, Google.Theme.Muted, button, {
		Position = UDim2.fromOffset(12, 9)
	})
	tab.TextLabel = create("TextLabel", {
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

	local page = create("ScrollingFrame", {
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
	pad(page, 14, 14, 14, 14)
	tab.Page = page
	tab.Layout = create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		pad = UDim.new(0, 10),
		Parent = page
	})
	bind(tab.Connections, tab.Layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		tab:UpdateCanvas()
	end)
	bind(tab.Connections, button.MouseButton1Click, function()
		self:SelectTab(tab)
	end)
	bind(tab.Connections, button.MouseEnter, function()
		if not tab.Active then
			animate(button, {BackgroundTransparency = 0}, motion.Fast)
		end
	end)
	bind(tab.Connections, button.MouseLeave, function()
		if not tab.Active then
			animate(button, {BackgroundTransparency = 1}, motion.Fast)
		end
	end)

	table.insert(self.Tabs, tab)
	self:ApplyTabResponsiveStyle(tab)
	self:UpdateTabListCanvas()
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
	if active then
		self.Page.Visible = true
		self.Page.Position = self.Window.IsMobile and UDim2.fromOffset(0, 10) or UDim2.fromOffset(6, 0)
		self.Accent.Visible = true
		self.Accent.BackgroundTransparency = 1
		if self.Window.IsMobile then
			self.Accent.Size = UDim2.new(0, 8, 0, 3)
			self.Accent.Position = UDim2.new(0.5, -4, 1, -4)
			animate(self.Accent, {BackgroundTransparency = 0, Size = UDim2.new(0, 28, 0, 3), Position = UDim2.new(0.5, -14, 1, -4)}, motion.Base)
		else
			self.Accent.Size = UDim2.new(0, 3, 0, 8)
			self.Accent.Position = UDim2.fromOffset(0, 9)
			animate(self.Accent, {BackgroundTransparency = 0, Size = UDim2.new(0, 3, 0, 18)}, motion.Base)
		end
		animate(self.Page, {Position = UDim2.fromOffset(0, 0)}, motion.Base)
		animate(self.Button, {BackgroundTransparency = 0, BackgroundColor3 = Google.Theme.PrimarySoft}, motion.Base)
		self.TextLabel.TextColor3 = Google.Theme.Primary
		Google.SetIconColor(self.IconLabel, Google.Theme.Primary)
	else
		animate(self.Button, {BackgroundTransparency = 1}, motion.Fast)
		local inactiveAccentSize = self.Window.IsMobile and UDim2.new(0, 8, 0, 3) or UDim2.new(0, 3, 0, 8)
		animate(self.Accent, {BackgroundTransparency = 1, Size = inactiveAccentSize}, motion.Fast, nil, nil, function()
			if not self.Active then
				self.Accent.Visible = false
			end
		end)
		self.Page.Visible = false
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

	local frame = create("Frame", {
		Name = section.Name,
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = Google.Theme.Card,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = self.Page
	})
	round(frame, 10)
	section.Instance = frame
	section.outline = outline(frame, Google.Theme.Border, 0.05, 1)

	local header = create("TextButton", {
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
	section.TitleLabel = create("TextLabel", {
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
	section.DescriptionLabel = create("TextLabel", {
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

	local content = create("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(0, header.Size.Y.Offset),
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = not section.Collapsed,
		Parent = frame
	})
	pad(content, 10, 10, 0, 10)
	section.Content = content
	section.Layout = create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		pad = UDim.new(0, 7),
		Parent = content
	})
	bind(section.Connections, section.Layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		section:Refresh()
	end)
	bind(section.Connections, header.MouseButton1Click, function()
		section:SetCollapsed(not section.Collapsed)
	end)

	table.insert(self.Sections, section)
	section:Refresh()
	return section
end

function Tab:AddSection(config)
	return self:CreateSection(config)
end

function Tab:GetStandaloneSection()
	if self.StandaloneSection then
		return self.StandaloneSection
	end
	local section = setmetatable({}, Section)
	section.Tab = self
	section.Name = "StandaloneComponents"
	section.Description = ""
	section.Icon = nil
	section.Controls = {}
	section.Connections = {}
	section.Collapsed = false
	section.Standalone = true
	local frame = create("Frame", {
		Name = "StandaloneComponents",
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = Google.Theme.Card,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = -1000,
		Parent = self.Page
	})
	round(frame, 10)
	section.Instance = frame
	section.outline = outline(frame, Google.Theme.Border, 0.05, 1)
	local content = create("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = frame
	})
	pad(content, 10, 10, 10, 10)
	section.Content = content
	section.Layout = create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		pad = UDim.new(0, 7),
		Parent = content
	})
	function section:Refresh(animated)
		local contentHeight = self.Layout.AbsoluteContentSize.Y + 20
		self.Content.Position = UDim2.fromOffset(0, 0)
		self.Content.Size = UDim2.new(1, 0, 0, contentHeight)
		local targetSize = UDim2.new(1, 0, 0, contentHeight)
		if animated then
			animate(self.Instance, {Size = targetSize}, motion.Base)
		else
			self.Instance.Size = targetSize
		end
		self.Tab:UpdateCanvas()
	end
	function section:ApplyTheme()
		self.Instance.BackgroundColor3 = Google.Theme.Card
		self.outline.Color = Google.Theme.Border
		for _, control in ipairs(self.Controls) do
			if control.ApplyTheme then
				control:ApplyTheme()
			end
		end
	end
	bind(section.Connections, section.Layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		section:Refresh()
	end)
	self.StandaloneSection = section
	table.insert(self.Sections, section)
	section:Refresh()
	return section
end

function Tab:CreateButton(config)
	return self:GetStandaloneSection():CreateButton(config)
end

function Tab:AddButton(config)
	return self:GetStandaloneSection():CreateButton(config)
end

function Tab:CreateToggle(config)
	return self:GetStandaloneSection():CreateToggle(config)
end

function Tab:AddToggle(index, config)
	local section = self:GetStandaloneSection()
	if type(index) == "table" then
		return section:CreateToggle(index)
	end
	config = config or {}
	config.Name = config.Name or config.Text or index
	return section:CreateToggle(config)
end

function Tab:CreateSlider(config)
	return self:GetStandaloneSection():CreateSlider(config)
end

function Tab:AddSlider(index, config)
	local section = self:GetStandaloneSection()
	if type(index) == "table" then
		return section:CreateSlider(index)
	end
	config = config or {}
	config.Name = config.Name or config.Text or index
	return section:CreateSlider(config)
end

function Tab:CreateDropdown(config)
	return self:GetStandaloneSection():CreateDropdown(config)
end

function Tab:AddDropdown(index, config)
	local section = self:GetStandaloneSection()
	if type(index) == "table" then
		return section:CreateDropdown(index)
	end
	config = config or {}
	config.Name = config.Name or config.Text or index
	return section:CreateDropdown(config)
end

function Tab:CreateTextbox(config)
	return self:GetStandaloneSection():CreateTextbox(config)
end

function Tab:AddTextbox(index, config)
	local section = self:GetStandaloneSection()
	if type(index) == "table" then
		return section:CreateTextbox(index)
	end
	config = config or {}
	config.Name = config.Name or config.Text or index
	return section:CreateTextbox(config)
end

function Tab:CreateKeybind(config)
	return self:GetStandaloneSection():CreateKeybind(config)
end

function Tab:AddKeybind(index, config)
	local section = self:GetStandaloneSection()
	if type(index) == "table" then
		return section:CreateKeybind(index)
	end
	config = config or {}
	config.Name = config.Name or config.Text or index
	return section:CreateKeybind(config)
end

function Tab:CreateColorPicker(config)
	return self:GetStandaloneSection():CreateColorPicker(config)
end

function Tab:AddColorPicker(index, config)
	local section = self:GetStandaloneSection()
	if type(index) == "table" then
		return section:CreateColorPicker(index)
	end
	config = config or {}
	config.Name = config.Name or config.Text or config.Title or index
	return section:CreateColorPicker(config)
end

function Tab:CreateLabel(config)
	return self:GetStandaloneSection():CreateLabel(config)
end

function Tab:AddLabel(config)
	return self:GetStandaloneSection():CreateLabel(config)
end

function Tab:CreateParagraph(config)
	return self:GetStandaloneSection():CreateParagraph(config)
end

function Tab:AddParagraph(config)
	return self:GetStandaloneSection():CreateParagraph(config)
end

function Tab:CreateImage(config)
	return self:GetStandaloneSection():CreateImage(config)
end

function Tab:AddImage(config)
	return self:GetStandaloneSection():CreateImage(config)
end

function Tab:CreateDivider(config)
	return self:GetStandaloneSection():CreateDivider(config)
end

function Tab:AddDivider(config)
	return self:GetStandaloneSection():CreateDivider(config)
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
	if not collapsed then
		self.Content.Visible = true
	end
	local asset = ResolveIcon(collapsed and "chevron-right" or "chevron-down")
	if asset and self.Arrow:IsA("ImageLabel") then
		self.Arrow.Image = asset.Image
		self.Arrow.ImageRectOffset = asset.Offset
		self.Arrow.ImageRectSize = asset.Size
	end
	animate(self.Arrow, {Rotation = collapsed and -90 or 0}, motion.Base)
	self:Refresh(true)
end

function Section:Refresh(animated)
	local headerHeight = self.Header.Size.Y.Offset
	local contentHeight = self.Collapsed and 0 or (self.Layout.AbsoluteContentSize.Y + 10)
	self.Content.Position = UDim2.fromOffset(0, headerHeight)
	self.Content.Size = UDim2.new(1, 0, 0, contentHeight)
	local targetSize = UDim2.new(1, 0, 0, headerHeight + contentHeight)
	if animated then
		animate(self.Instance, {Size = targetSize}, motion.Base, Enum.EasingStyle.Quint, nil, function()
			if self.Collapsed then
				self.Content.Visible = false
			end
		end)
	else
		self.Instance.Size = targetSize
	end
	self.Tab:UpdateCanvas()
end

function Section:ApplyTheme()
	self.Instance.BackgroundColor3 = Google.Theme.Card
	self.outline.Color = Google.Theme.Border
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
	local frame = create("Frame", {
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
	local button = create("TextButton", {
		Name = "Button",
		Text = "",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Google.Theme.Primary,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Parent = self.Instance
	})
	round(button, 8)
	self.Button = button
	local iconOffset = self.Icon and 34 or 12
	if self.Icon then
		self.IconLabel = Google.CreateIcon(self.Icon, 17, Color3.new(1, 1, 1), button, {
			Position = UDim2.fromOffset(12, config.Description and 15 or 10)
		})
	end
	self.TextLabel = create("TextLabel", {
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
		self.DescriptionLabel = create("TextLabel", {
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
	bind(self.Connections, button.MouseButton1Click, function()
		self.Callback()
	end)
	bind(self.Connections, button.MouseButton1Down, function()
		animate(button, {BackgroundColor3 = Google.Theme.PrimaryHover}, motion.Fast)
	end)
	bind(self.Connections, button.MouseButton1Up, function()
		animate(button, {BackgroundColor3 = Google.Theme.Primary}, motion.Fast)
	end)
	bind(self.Connections, button.MouseEnter, function()
		animate(button, {BackgroundColor3 = Google.Theme.PrimaryHover}, motion.Fast)
	end)
	bind(self.Connections, button.MouseLeave, function()
		animate(button, {BackgroundColor3 = Google.Theme.Primary}, motion.Fast)
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
	self.Label = create("TextLabel", {
		Text = config.Name or "Toggle",
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = Google.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -76, 0, 18),
		Position = UDim2.fromOffset(0, config.Description and 5 or 9),
		Parent = self.Instance
	})
	if config.Description then
		self.DescriptionLabel = create("TextLabel", {
			Text = config.Description,
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = Google.Theme.Muted,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -76, 0, 16),
			Position = UDim2.fromOffset(0, 25),
			Parent = self.Instance
		})
	end
	local switch = create("TextButton", {
		Text = "",
		Size = UDim2.fromOffset(48, 26),
		Position = UDim2.new(1, -48, 0.5, -13),
		BackgroundColor3 = self.Value and Google.Theme.Primary or Google.Theme.BorderStrong,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		ClipsDescendants = true,
		Parent = self.Instance
	})
	round(switch, 13)
	self.Switch = switch
	self.SwitchStroke = outline(switch, self.Value and Google.Theme.PrimaryHover or Google.Theme.BorderStrong, 0.2, 1)
	self.SwitchStroke.Name = "ToggleStroke"
	self.SwitchGradient = create("UIGradient", {
		Name = "Gradient",
		Rotation = 0,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, self.Value and blend(Google.Theme.Primary, Color3.new(1, 1, 1), 0.14) or blend(Google.Theme.BorderStrong, Color3.new(1, 1, 1), 0.1)),
			ColorSequenceKeypoint.new(1, self.Value and Google.Theme.Primary or Google.Theme.BorderStrong)
		}),
		Parent = switch
	})
	self.Knob = create("Frame", {
		Size = UDim2.fromOffset(22, 22),
		Position = self.Value and UDim2.new(1, -24, 0.5, -11) or UDim2.fromOffset(2, 2),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Parent = switch
	})
	round(self.Knob, 11)
	self.KnobStroke = outline(self.Knob, blend(Google.Theme.Border, Color3.new(1, 1, 1), 0.45), 0.15, 1)
	self.KnobStroke.Name = "KnobStroke"
	function self:Set(value)
		self.Value = value and true or false
		local base = self.Value and Google.Theme.Primary or Google.Theme.BorderStrong
		animate(self.Switch, {BackgroundColor3 = base}, motion.Base)
		animate(self.Knob, {Position = self.Value and UDim2.new(1, -24, 0.5, -11) or UDim2.fromOffset(2, 2)}, motion.Base)
		if self.SwitchStroke then
			animate(self.SwitchStroke, {Color = self.Value and Google.Theme.PrimaryHover or Google.Theme.BorderStrong, Transparency = self.Value and 0.08 or 0.22}, motion.Base)
		end
		if self.SwitchGradient then
			self.SwitchGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, self.Value and blend(Google.Theme.Primary, Color3.new(1, 1, 1), 0.14) or blend(Google.Theme.BorderStrong, Color3.new(1, 1, 1), 0.1)),
				ColorSequenceKeypoint.new(1, base)
			})
		end
		self.Callback(self.Value)
	end
	function self:Get()
		return self.Value
	end
	bind(self.Connections, switch.MouseButton1Click, function()
		self:Set(not self.Value)
	end)
	bind(self.Connections, self.Instance.InputBegan, function(input)
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
		if self.SwitchStroke then
			self.SwitchStroke.Color = self.Value and Google.Theme.PrimaryHover or Google.Theme.BorderStrong
		end
		if self.KnobStroke then
			self.KnobStroke.Color = blend(Google.Theme.Border, Color3.new(1, 1, 1), 0.45)
		end
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
	local self = Control(self, 60, "Slider")
	self.Min = config.Min or config.Minimum or 0
	self.Max = config.Max or config.Maximum or 100
	self.Value = config.Default or self.Min
	self.Precision = config.Precision or 0
	self.Callback = config.Callback or function() end
	self.Dragging = false
	self.Label = create("TextLabel", {
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
	self.ValueLabel = create("TextLabel", {
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
	self.Track = create("Frame", {
		Size = UDim2.new(1, 0, 0, 8),
		Position = UDim2.fromOffset(0, 36),
		BackgroundColor3 = Google.Theme.Border,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		Parent = self.Instance
	})
	round(self.Track, 8)
	self.TrackStroke = outline(self.Track, Google.Theme.BorderStrong, 0.65, 1)
	self.TrackStroke.Name = "SliderTrackStroke"
	self.Fill = create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Google.Theme.Primary,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = self.Track
	})
	round(self.Fill, 8)
	self.FillGradient = create("UIGradient", {
		Name = "Gradient",
		Rotation = 0,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Google.Theme.Primary),
			ColorSequenceKeypoint.new(1, blend(Google.Theme.Primary, Color3.new(1, 1, 1), 0.16))
		}),
		Parent = self.Fill
	})
	self.Knob = create("Frame", {
		Size = UDim2.fromOffset(20, 20),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = self.Track
	})
	round(self.Knob, 10)
	self.KnobStroke = outline(self.Knob, Google.Theme.Primary, 0.05, 2)
	self.KnobDot = create("Frame", {
		Size = UDim2.fromOffset(8, 8),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = Google.Theme.Primary,
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = self.Knob
	})
	round(self.KnobDot, 4)
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
		local duration = self.Dragging and 0.05 or motion.Base
		animate(self.Fill, {Size = UDim2.fromScale(alpha, 1)}, duration)
		animate(self.Knob, {Position = UDim2.fromScale(alpha, 0.5)}, duration)
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
	bind(self.Connections, self.Track.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self.Dragging = true
			setFromInput(input)
		end
	end)
	bind(self.Connections, UserInputService.InputChanged, function(input)
		if self.Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setFromInput(input)
		end
	end)
	bind(self.Connections, UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self.Dragging = false
		end
	end)
	function self:ApplyTheme()
		self.Label.TextColor3 = Google.Theme.Text
		self.ValueLabel.TextColor3 = Google.Theme.Primary
		self.Track.BackgroundColor3 = Google.Theme.Border
		self.Fill.BackgroundColor3 = Google.Theme.Primary
		if self.FillGradient then
			self.FillGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Google.Theme.Primary),
				ColorSequenceKeypoint.new(1, blend(Google.Theme.Primary, Color3.new(1, 1, 1), 0.16))
			})
		end
		self.Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		self.KnobStroke.Color = Google.Theme.Primary
		if self.KnobDot then
			self.KnobDot.BackgroundColor3 = Google.Theme.Primary
		end
		if self.TrackStroke then
			self.TrackStroke.Color = Google.Theme.BorderStrong
		end
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
	self.Main = create("TextButton", {
		Text = "",
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = Google.Theme.Input,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Parent = self.Instance
	})
	round(self.Main, 8)
	self.MainStroke = outline(self.Main, Google.Theme.Border, 0.08, 1)
	self.Label = create("TextLabel", {
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
	self.SelectedLabel = create("TextLabel", {
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
	self.Menu = create("Frame", {
		Name = "Menu",
		Position = UDim2.fromOffset(0, 42),
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = Google.Theme.Card,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Visible = false,
		Parent = self.Instance
	})
	round(self.Menu, 8)
	self.MenuStroke = outline(self.Menu, Google.Theme.Border, 0.08, 1)
	local searchOffset = 0
	if self.Searchable then
		self.SearchBox = create("TextBox", {
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
		round(self.SearchBox, 8)
		self.SearchStroke = outline(self.SearchBox, Google.Theme.Border, 0.08, 1)
		pad(self.SearchBox, 8, 8, 0, 0)
		searchOffset = 36
	end
	self.OptionsFrame = create("ScrollingFrame", {
		Size = UDim2.new(1, -6, 1, -searchOffset - 6),
		Position = UDim2.fromOffset(3, searchOffset + 3),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		CanvasSize = UDim2.fromOffset(0, 0),
		Parent = self.Menu
	})
	self.OptionLayout = create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		pad = UDim.new(0, 2),
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
			local item = create("TextButton", {
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
			round(item, 7)
			local label = create("TextLabel", {
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
			bind(self.Connections, item.MouseEnter, function()
				animate(item, {BackgroundTransparency = 0}, motion.Fast)
			end)
			bind(self.Connections, item.MouseLeave, function()
				animate(item, {BackgroundTransparency = 1}, motion.Fast)
			end)
			bind(self.Connections, item.MouseButton1Click, function()
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
		animate(self.Menu, {Size = UDim2.new(1, 0, 0, optionHeight)}, motion.Base)
		animate(self.Arrow, {Rotation = 180}, motion.Base)
		self:RefreshSection()
	end
	function self:CloseMenu()
		self.Open = false
		self.Instance.Size = UDim2.new(1, 0, 0, 40)
		animate(self.Arrow, {Rotation = 0}, motion.Base)
		animate(self.Menu, {Size = UDim2.new(1, 0, 0, 0)}, motion.Fast, nil, nil, function()
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
	bind(self.Connections, self.Main.MouseEnter, function()
		self.MainStroke.Color = Google.Theme.Primary
	end)
	bind(self.Connections, self.Main.MouseLeave, function()
		if not self.Open then
			self.MainStroke.Color = Google.Theme.Border
		end
	end)
	bind(self.Connections, self.Main.MouseButton1Click, function()
		if self.Open then
			self:CloseMenu()
		else
			self:OpenMenu()
		end
	end)
	if self.SearchBox then
		bind(self.Connections, self.SearchBox:GetPropertyChangedSignal("Text"), function()
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
	self.Label = create("TextLabel", {
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
	self.Entry = create("TextBox", {
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
	round(self.Entry, 8)
	pad(self.Entry, 10, 10, 0, 0)
	self.EntryStroke = outline(self.Entry, Google.Theme.Border, 0.08, 1)
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
	bind(self.Connections, self.Entry.Focused, function()
		animate(self.EntryStroke, {Color = Google.Theme.Primary, Transparency = 0}, motion.Fast)
	end)
	bind(self.Connections, self.Entry.FocusLost, function()
		self:Set(self.Entry.Text)
		animate(self.EntryStroke, {Color = Google.Theme.Border, Transparency = 0.08}, motion.Fast)
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
	self.Label = create("TextLabel", {
		Text = config.Name or "Keybind",
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = Google.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -92, 1, 0),
		Parent = self.Instance
	})
	self.Button = create("TextButton", {
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
	round(self.Button, 8)
	self.ButtonStroke = outline(self.Button, Google.Theme.Border, 0.08, 1)
	function self:Set(keycode)
		self.Value = keycode
		self.Button.Text = keycode.Name
	end
	function self:Get()
		return self.Value
	end
	bind(self.Connections, self.Button.MouseEnter, function()
		animate(self.ButtonStroke, {Color = Google.Theme.Primary, Transparency = 0}, motion.Fast)
	end)
	bind(self.Connections, self.Button.MouseLeave, function()
		if not self.Binding then
			animate(self.ButtonStroke, {Color = Google.Theme.Border, Transparency = 0.08}, motion.Fast)
		end
	end)
	bind(self.Connections, self.Button.MouseButton1Click, function()
		self.Binding = true
		self.Button.Text = "..."
		animate(self.ButtonStroke, {Color = Google.Theme.Primary, Transparency = 0}, motion.Fast)
	end)
	bind(self.Connections, UserInputService.InputBegan, function(input, processed)
		if processed then
			return
		end
		if self.Binding then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				self:Set(input.KeyCode)
				self.Binding = false
				animate(self.ButtonStroke, {Color = Google.Theme.Border, Transparency = 0.08}, motion.Fast)
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
	bind(self.Connections, UserInputService.InputEnded, function(input)
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
	self.Label = create("TextLabel", {
		Text = config.Name or "Color",
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = Google.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -52, 0, 34),
		Parent = self.Instance
	})
	self.Button = create("TextButton", {
		Text = "",
		Size = UDim2.fromOffset(34, 28),
		Position = UDim2.new(1, -34, 0, 4),
		BackgroundColor3 = self.Value,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Parent = self.Instance
	})
	round(self.Button, 8)
	self.ButtonStroke = outline(self.Button, Google.Theme.Border, 0.08, 1)
	self.Palette = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.fromOffset(0, 42),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
		Parent = self.Instance
	})
	self.PaletteLayout = create("UIGridLayout", {
		CellSize = UDim2.fromOffset(28, 28),
		CellPadding = UDim2.fromOffset(6, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = self.Palette
	})
	function self:Set(color)
		if isColor(color) then
			self.Value = color
			self.Button.BackgroundColor3 = color
			self.Callback(color)
		end
	end
	function self:Get()
		return self.Value
	end
	for i, color in ipairs(self.Colors) do
		local swatch = create("TextButton", {
			Text = "",
			Size = UDim2.fromOffset(28, 28),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			LayoutOrder = i,
			AutoButtonColor = false,
			Parent = self.Palette
		})
		round(swatch, 8)
		outline(swatch, Google.Theme.Border, 0.12, 1)
		bind(self.Connections, swatch.MouseButton1Click, function()
			self:Set(color)
		end)
	end
	local function togglePalette()
		self.Open = not self.Open
		if self.Open then
			self.Palette.Visible = true
			self.Palette.Size = UDim2.new(1, 0, 0, 0)
			self.Instance.Size = UDim2.new(1, 0, 0, 78)
			animate(self.Palette, {Size = UDim2.new(1, 0, 0, 32)}, motion.Base)
		else
			animate(self.Palette, {Size = UDim2.new(1, 0, 0, 0)}, motion.Fast, nil, nil, function()
				self.Palette.Visible = false
			end)
			self.Instance.Size = UDim2.new(1, 0, 0, 38)
		end
		self:RefreshSection()
	end
	bind(self.Connections, self.Button.MouseButton1Click, togglePalette)
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
	self.Label = create("TextLabel", {
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
	round(self.Instance, 8)
	self.outline = outline(self.Instance, Google.Theme.Border, 0.1, 1)
	if title then
		self.TitleLabel = create("TextLabel", {
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
	self.TextLabel = create("TextLabel", {
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
		self.outline.Color = Google.Theme.Border
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

function Section:CreateImage(config)
	config = config or {}
	local title = config.Title or config.Name
	local description = config.Description or config.Caption or config.Text
	local imageHeight = tonumber(config.Height) or tonumber(config.ImageHeight) or 180
	imageHeight = math.max(48, imageHeight)
	local topOffset = 10
	local height = imageHeight + 20
	if title then
		height = height + 22
		topOffset = topOffset + 22
	end
	if description then
		height = height + 18
		topOffset = topOffset + 18
	end
	local self = Control(self, height, "Image")
	self.Instance.BackgroundTransparency = 0
	self.Instance.BackgroundColor3 = Google.Theme.CardAlt
	self.Instance.ClipsDescendants = true
	round(self.Instance, 10)
	self.outline = outline(self.Instance, Google.Theme.Border, 0.1, 1)
	if title then
		self.TitleLabel = create("TextLabel", {
			Text = title,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextColor3 = Google.Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -20, 0, 18),
			Position = UDim2.fromOffset(10, 10),
			Parent = self.Instance
		})
	end
	if description then
		self.DescriptionLabel = create("TextLabel", {
			Text = description,
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = Google.Theme.Muted,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -20, 0, 16),
			Position = UDim2.fromOffset(10, title and 31 or 10),
			Parent = self.Instance
		})
	end
	self.ImageFrame = create("Frame", {
		Size = UDim2.new(1, -20, 0, imageHeight),
		Position = UDim2.fromOffset(10, topOffset),
		BackgroundColor3 = config.BackgroundColor or Google.Theme.Input,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = self.Instance
	})
	round(self.ImageFrame, tonumber(config.ImageCornerRadius) or tonumber(config.CornerRadius) or 8)
	self.ImageStroke = outline(self.ImageFrame, Google.Theme.Border, 0.08, 1)
	local initialSource = config.Image or config.ImageId or config.Source or config.AssetId or config.Id
	self.ImageFallback = imageThumbnail(initialSource)
	self.Image = create("ImageLabel", {
		Name = "Image",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScaleType = imageScaleType(config.ScaleType),
		Image = imageSource(config.Image or config.ImageId or config.Source or config.AssetId or config.Id),
		Parent = self.ImageFrame
	})
	self.Placeholder = create("TextLabel", {
		Text = config.Placeholder or "Image",
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Google.Theme.Subtle,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = self.Image.Image == "",
		Parent = self.ImageFrame
	})
	local loadToken = 0
	local function applyImageSource(source)
		loadToken = loadToken + 1
		local token = loadToken
		local resolved = imageSource(source)
		local fallback = imageThumbnail(source)
		self.Image.Image = resolved
		self.ImageFallback = fallback
		self.Placeholder.Visible = resolved == ""
		if resolved ~= "" and fallback ~= "" and fallback ~= resolved then
			coroutine.wrap(function()
				wait(1)
				if token == loadToken and self.Image and self.Image.Parent and self.Image.Image == resolved and not self.Image.IsLoaded then
					self.Image.Image = fallback
				end
			end)()
		end
	end
	applyImageSource(initialSource)
	function self:Set(source)
		applyImageSource(source)
	end
	function self:Get()
		return self.Image.Image
	end
	function self:SetScaleType(scaleType)
		self.Image.ScaleType = imageScaleType(scaleType)
		return self.Image.ScaleType
	end
	function self:ApplyTheme()
		self.Instance.BackgroundColor3 = Google.Theme.CardAlt
		self.outline.Color = Google.Theme.Border
		self.ImageFrame.BackgroundColor3 = config.BackgroundColor or Google.Theme.Input
		self.ImageStroke.Color = Google.Theme.Border
		if self.TitleLabel then
			self.TitleLabel.TextColor3 = Google.Theme.Text
		end
		if self.DescriptionLabel then
			self.DescriptionLabel.TextColor3 = Google.Theme.Muted
		end
		self.Placeholder.TextColor3 = Google.Theme.Subtle
	end
	self:RefreshSection()
	return self
end

function Section:AddImage(config)
	return self:CreateImage(config)
end

function Section:CreateDivider(config)
	config = config or {}
	if type(config) == "string" then
		config = {Name = config}
	end
	local self = Control(self, config.Name and 24 or 16, "Divider")
	if config.Name then
		self.Label = create("TextLabel", {
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
		self.Left = create("Frame", {
			Size = UDim2.new(0.34, -8, 0, 1),
			Position = UDim2.new(0, 0, 0.5, 0),
			BackgroundColor3 = Google.Theme.Border,
			BorderSizePixel = 0,
			Parent = self.Instance
		})
		self.Right = create("Frame", {
			Size = UDim2.new(0.34, -8, 0, 1),
			Position = UDim2.new(0.66, 8, 0.5, 0),
			BackgroundColor3 = Google.Theme.Border,
			BorderSizePixel = 0,
			Parent = self.Instance
		})
	else
		self.Line = create("Frame", {
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

function Window:UpdateTabListCanvas()
	if not self.TabList or not self.TabLayout then
		return
	end
	if self.IsMobile then
		self.TabList.CanvasSize = UDim2.fromOffset(self.TabLayout.AbsoluteContentSize.X + 12, 0)
	else
		self.TabList.CanvasSize = UDim2.fromOffset(0, self.TabLayout.AbsoluteContentSize.Y + 8)
	end
end

function Window:ApplyTabResponsiveStyle(tab)
	if not tab or not tab.Button then
		return
	end
	if self.IsMobile then
		tab.Button.Size = UDim2.fromOffset(88, 46)
		tab.Button.BackgroundTransparency = tab.Active and 0 or 1
		if tab.IconLabel then
			tab.IconLabel.Size = UDim2.fromOffset(18, 18)
			tab.IconLabel.AnchorPoint = Vector2.new(0.5, 0)
			tab.IconLabel.Position = UDim2.new(0.5, 0, 0, 6)
		end
		if tab.TextLabel then
			tab.TextLabel.Size = UDim2.new(1, -8, 0, 17)
			tab.TextLabel.Position = UDim2.new(0, 4, 0, 26)
			tab.TextLabel.TextXAlignment = Enum.TextXAlignment.Center
			tab.TextLabel.TextSize = 11
		end
		if tab.Accent then
			tab.Accent.Size = tab.Active and UDim2.new(0, 28, 0, 3) or UDim2.new(0, 8, 0, 3)
			tab.Accent.Position = tab.Active and UDim2.new(0.5, -14, 1, -4) or UDim2.new(0.5, -4, 1, -4)
		end
	else
		tab.Button.Size = UDim2.new(1, 0, 0, 36)
		tab.Button.BackgroundTransparency = tab.Active and 0 or 1
		if tab.IconLabel then
			tab.IconLabel.Size = UDim2.fromOffset(17, 17)
			tab.IconLabel.AnchorPoint = Vector2.new(0, 0)
			tab.IconLabel.Position = UDim2.fromOffset(12, 9)
		end
		if tab.TextLabel then
			tab.TextLabel.Size = UDim2.new(1, -42, 1, 0)
			tab.TextLabel.Position = UDim2.fromOffset(38, 0)
			tab.TextLabel.TextXAlignment = Enum.TextXAlignment.Left
			tab.TextLabel.TextSize = 13
		end
		if tab.Accent then
			tab.Accent.Size = tab.Active and UDim2.new(0, 3, 0, 18) or UDim2.new(0, 3, 0, 8)
			tab.Accent.Position = UDim2.fromOffset(0, 9)
		end
	end
end

function Window:UpdateResponsiveLayout(force)
	local targetMobile = self.IsMobile
	if self.AutoMobile then
		targetMobile = isMobileDevice()
	end
	local changed = targetMobile ~= self.IsMobile
	self.IsMobile = targetMobile
	self.Size = self.IsMobile and mobileWindowSize({MobileSize = self.MobileSize}) or self.DesktopSize
	local topHeight = self.IsMobile and 58 or 54
	local navSize = self.IsMobile and 64 or 152
	self.Topbar.Size = UDim2.new(1, 0, 0, topHeight)
	self.TopbarLine.Position = UDim2.new(0, 0, 1, -1)
	self.TitleIconWrap.Position = UDim2.fromOffset(14, self.IsMobile and 13 or 11)
	self.TitleLabel.Position = UDim2.fromOffset(56, self.Subtitle ~= "" and (self.IsMobile and 10 or 8) or (self.IsMobile and 18 or 16))
	self.SubtitleLabel.Position = UDim2.fromOffset(56, self.IsMobile and 32 or 30)
	self.ControlsFrame.Position = UDim2.new(1, -88, 0, self.IsMobile and 14 or 12)
	if self.IsMobile then
		self.Sidebar.Size = UDim2.new(1, 0, 0, navSize)
		self.Sidebar.Position = UDim2.new(0, 0, 1, -navSize)
		self.SidebarLine.Size = UDim2.new(1, 0, 0, 1)
		self.SidebarLine.Position = UDim2.fromOffset(0, 0)
		self.TabList.Size = UDim2.new(1, -20, 1, -12)
		self.TabList.Position = UDim2.fromOffset(10, 6)
		self.TabList.ScrollBarThickness = 0
		self.TabLayout.FillDirection = Enum.FillDirection.Horizontal
		self.TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		self.TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		self.TabLayout.pad = UDim.new(0, 6)
		self.PageWrap.Size = UDim2.new(1, 0, 1, -(topHeight + navSize))
		self.PageWrap.Position = UDim2.fromOffset(0, topHeight)
	else
		self.Sidebar.Size = UDim2.new(0, navSize, 1, -topHeight)
		self.Sidebar.Position = UDim2.fromOffset(0, topHeight)
		self.SidebarLine.Size = UDim2.new(0, 1, 1, 0)
		self.SidebarLine.Position = UDim2.new(1, -1, 0, 0)
		self.TabList.Size = UDim2.new(1, -16, 1, -16)
		self.TabList.Position = UDim2.fromOffset(8, 8)
		self.TabList.ScrollBarThickness = 0
		self.TabLayout.FillDirection = Enum.FillDirection.Vertical
		self.TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		self.TabLayout.VerticalAlignment = Enum.VerticalAlignment.Top
		self.TabLayout.pad = UDim.new(0, 4)
		self.PageWrap.Size = UDim2.new(1, -navSize, 1, -topHeight)
		self.PageWrap.Position = UDim2.fromOffset(navSize, topHeight)
	end
	for _, tab in ipairs(self.Tabs) do
		self:ApplyTabResponsiveStyle(tab)
		tab:UpdateCanvas()
	end
	self:UpdateTabListCanvas()
	if not self.Minimized then
		if force or changed then
			animate(self.Instance, {Size = self.Size}, self.IsMobile and motion.Mobile or motion.Slow, Enum.EasingStyle.Quint)
		else
			self.Instance.Size = self.Size
		end
	end
end

function Window:ApplyTheme()
	local theme = Google.Theme
	self.Instance.BackgroundTransparency = 1
	self.Body.BackgroundColor3 = theme.Window
	self.MainStroke.Color = theme.Border
	self.MainStroke.Transparency = 1
	self.MainStroke.Thickness = 0
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
		self:ApplyTabResponsiveStyle(tab)
		tab:ApplyTheme()
	end
	self:UpdateTabListCanvas()
end

function Window:Minimize()
	if self.Minimized then
		return
	end
	self.Minimized = true
	self.Sidebar.Visible = false
	self.PageWrap.Visible = false
	local height = self.IsMobile and 58 or 54
	animate(self.Instance, {Size = UDim2.fromOffset(self.Instance.AbsoluteSize.X, height)}, motion.Slow, Enum.EasingStyle.Quint)
end

function Window:Restore()
	if not self.Minimized then
		return
	end
	self.Minimized = false
	self:UpdateResponsiveLayout(true)
	animate(self.Instance, {Size = self.Size}, motion.Slow, Enum.EasingStyle.Quint, nil, function()
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
	disconnectAll(self.Connections)
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
	disconnectAll(self.Connections)
	for _, section in ipairs(self.Sections) do
		if section.Destroy then
			section:Destroy()
		end
	end
	if self.Button then self.Button:Destroy() end
	if self.Page then self.Page:Destroy() end
end

function Section:Destroy()
	disconnectAll(self.Connections)
	for _, control in ipairs(self.Controls) do
		if control.Destroy then
			control:Destroy()
		end
	end
	if self.Instance then self.Instance:Destroy() end
end

function ControlBase:Destroy()
	disconnectAll(self.Connections)
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
	self.Gui = create("ScreenGui", {
		Name = "GoogleUINotifications",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = getGuiHost()
	})
	self.Holder = create("Frame", {
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
			animate(frame, {Position = UDim2.new(1, -18, 1, -offset)}, motion.Base)
			offset = offset + frame.Size.Y.Offset + 8
		end
	end
end

function NotificationManager:Push(config)
	self:Init()
	config = config or {}
	local duration = config.Duration or 3
	local frame = create("Frame", {
		Size = UDim2.fromOffset(292, 62),
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 310, 1, -18),
		BackgroundColor3 = Google.Theme.Card,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = self.Holder
	})
	round(frame, 10)
	outline(frame, Google.Theme.Border, 0.05, 1)
	local iconWrap = create("Frame", {
		Size = UDim2.fromOffset(34, 34),
		Position = UDim2.fromOffset(12, 14),
		BackgroundColor3 = Google.Theme.PrimarySoft,
		BorderSizePixel = 0,
		Parent = frame
	})
	round(iconWrap, 8)
	Google.CreateIcon(config.Icon or "info", 18, config.IconColor or Google.Theme.Primary, iconWrap, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5)
	})
	create("TextLabel", {
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
	create("TextLabel", {
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
	local progress = create("Frame", {
		Size = UDim2.new(1, -14, 0, 2),
		Position = UDim2.new(0, 7, 1, -5),
		BackgroundColor3 = Google.Theme.Primary,
		BorderSizePixel = 0,
		Parent = frame
	})
	round(progress, 2)
	table.insert(self.Items, frame)
	self:Update()
	animate(frame, {Position = UDim2.new(1, -18, 1, -18)}, motion.Slow, Enum.EasingStyle.Quint)
	animate(progress, {Size = UDim2.new(0, 0, 0, 2)}, duration, Enum.EasingStyle.Linear)
	coroutine.wrap(function()
		wait(duration)
		animate(frame, {Position = UDim2.new(1, 310, frame.Position.Y.Scale, frame.Position.Y.Offset), BackgroundTransparency = 1}, motion.Slow, Enum.EasingStyle.Quint, nil, function()
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
	local gui = create("ScreenGui", {
		Name = "GoogleUIConfirm",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = getGuiHost()
	})
	local overlay = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		Parent = gui
	})
	local dialog = create("Frame", {
		Size = UDim2.fromOffset(320, 142),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = Google.Theme.Card,
		BorderSizePixel = 0,
		Parent = overlay
	})
	round(dialog, 12)
	outline(dialog, Google.Theme.Border, 0.05, 1)
	create("TextLabel", {
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
	create("TextLabel", {
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
	local cancel = create("TextButton", {
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
	round(cancel, 8)
	local confirm = create("TextButton", {
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
	round(confirm, 8)
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
	local gui = create("ScreenGui", {
		Name = "GoogleUIPrompt",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = getGuiHost()
	})
	local overlay = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		Parent = gui
	})
	local dialog = create("Frame", {
		Size = UDim2.fromOffset(330, 170),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = Google.Theme.Card,
		BorderSizePixel = 0,
		Parent = overlay
	})
	round(dialog, 12)
	outline(dialog, Google.Theme.Border, 0.05, 1)
	create("TextLabel", {
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
	create("TextLabel", {
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
	local input = create("TextBox", {
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
	round(input, 8)
	outline(input, Google.Theme.Border, 0.08, 1)
	pad(input, 10, 10, 0, 0)
	local cancel = create("TextButton", {
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
	round(cancel, 8)
	local confirm = create("TextButton", {
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
	round(confirm, 8)
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

local controlDefaults = {
	ColorPalette = {
		Color3.fromRGB(26, 115, 232),
		Color3.fromRGB(52, 168, 83),
		Color3.fromRGB(251, 188, 4),
		Color3.fromRGB(234, 67, 53),
		Color3.fromRGB(99, 102, 241),
		Color3.fromRGB(14, 165, 233),
		Color3.fromRGB(245, 158, 11),
		Color3.fromRGB(236, 72, 153),
		Color3.fromRGB(168, 85, 247),
		Color3.fromRGB(20, 184, 166),
		Color3.fromRGB(244, 63, 94),
		Color3.fromRGB(100, 116, 139),
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(17, 24, 39)
	}
}

local function getChild(parent, name)
	if not parent then
		return nil
	end
	for _, child in ipairs(parent:GetChildren()) do
		if child.Name == name then
			return child
		end
	end
	return nil
end

local function getStroke(instance, name, color, transparency, thickness)
	if not instance then
		return nil
	end
	local stroke = getChild(instance, name or "outline")
	if not stroke then
		stroke = outline(instance, color or Google.Theme.Border, transparency or 0.1, thickness or 1)
		stroke.Name = name or "outline"
	else
		stroke.Color = color or stroke.Color
		stroke.Transparency = transparency or stroke.Transparency
		stroke.Thickness = thickness or stroke.Thickness
	end
	return stroke
end

local function getGradient(instance, colorA, colorB, rotation)
	if not instance then
		return nil
	end
	local gradient = getChild(instance, "Gradient")
	if not gradient then
		gradient = create("UIGradient", {
			Name = "Gradient",
			Rotation = rotation or 90,
			Parent = instance
		})
	end
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, colorA),
		ColorSequenceKeypoint.new(1, colorB)
	})
	return gradient
end

local function getScale(instance)
	if not instance then
		return nil
	end
	local scale = getChild(instance, "Scale")
	if not scale then
		scale = create("UIScale", {
			Name = "Scale",
			Scale = 1,
			Parent = instance
		})
	end
	return scale
end

local function setText(label, value)
	if label then
		label.Text = tostring(value or "")
	end
end

local function formatHex(color)
	local r = math.floor(color.R * 255 + 0.5)
	local g = math.floor(color.G * 255 + 0.5)
	local b = math.floor(color.B * 255 + 0.5)
	return string.format("#%02X%02X%02X", r, g, b)
end

local function colorFromHex(value)
	if type(value) ~= "string" then
		return nil
	end
	local hex = value:gsub("#", "")
	if #hex ~= 6 then
		return nil
	end
	local r = tonumber(hex:sub(1, 2), 16)
	local g = tonumber(hex:sub(3, 4), 16)
	local b = tonumber(hex:sub(5, 6), 16)
	if r and g and b then
		return Color3.fromRGB(r, g, b)
	end
	return nil
end

local function guardCallback(control)
	local callback = control.Callback or function() end
	control.RawCallback = callback
	control.Callback = function(...)
		if control.Disabled then
			return
		end
		return callback(...)
	end
	function control:SetCallback(fn)
		self.RawCallback = type(fn) == "function" and fn or function() end
		self.Callback = function(...)
			if self.Disabled then
				return
			end
			return self.RawCallback(...)
		end
		return self
	end
end

local function setControlOpacity(control, opacity)
	local instance = control and control.Instance
	if not instance then
		return
	end
	for _, item in ipairs(instance:GetDescendants()) do
		if item:IsA("TextLabel") or item:IsA("TextButton") or item:IsA("TextBox") then
			item.TextTransparency = opacity
		elseif item:IsA("ImageLabel") or item:IsA("ImageButton") then
			item.ImageTransparency = opacity
		end
	end
end

local function addDisabledState(control, refresh)
	function control:SetDisabled(value)
		self.Disabled = value and true or false
		setControlOpacity(self, self.Disabled and 0.42 or 0)
		if refresh then
			refresh(self)
		end
		return self
	end
	function control:Enable()
		return self:SetDisabled(false)
	end
	function control:Disable()
		return self:SetDisabled(true)
	end
	return control
end

local createButtonBase = Section.CreateButton
function Section:CreateButton(config)
	config = config or {}
	local control = createButtonBase(self, config)
	control.Variant = config.Variant or config.Style or "Primary"
	control.Disabled = config.Disabled or false
	guardCallback(control)
	if control.Button then
		control.Button.ClipsDescendants = true
		round(control.Button, tonumber(config.CornerRadius) or 10)
		control.ButtonStroke = getStroke(control.Button, "ButtonStroke", Google.Theme.PrimaryHover, 0.25, 1)
		control.ButtonScale = getScale(control.Button)
		control.ButtonGradient = getGradient(control.Button, Google.Theme.Primary, blend(Google.Theme.Primary, Color3.new(1, 1, 1), 0.12), 90)
	end
	local function applyVariant(self)
		local variant = string.lower(tostring(self.Variant or "Primary"))
		local background = Google.Theme.Primary
		local foreground = Color3.new(1, 1, 1)
		local strokeColor = Google.Theme.PrimaryHover
		local transparent = 0
		if variant == "secondary" then
			background = Google.Theme.CardAlt
			foreground = Google.Theme.Text
			strokeColor = Google.Theme.BorderStrong
		elseif variant == "ghost" then
			background = Google.Theme.Hover
			foreground = Google.Theme.Primary
			strokeColor = Google.Theme.Border
			transparent = 0.15
		elseif variant == "danger" or variant == "red" then
			background = Google.Theme.Danger
			foreground = Color3.new(1, 1, 1)
			strokeColor = Google.Theme.Danger
		elseif variant == "success" or variant == "green" then
			background = Google.Theme.Success
			foreground = Color3.new(1, 1, 1)
			strokeColor = Google.Theme.Success
		elseif variant == "warning" or variant == "yellow" then
			background = Google.Theme.Warning
			foreground = Color3.fromRGB(22, 28, 36)
			strokeColor = Google.Theme.Warning
		end
		if self.Button then
			self.Button.BackgroundColor3 = background
			self.Button.BackgroundTransparency = self.Disabled and 0.55 or transparent
			if self.ButtonStroke then
				self.ButtonStroke.Color = strokeColor
				self.ButtonStroke.Transparency = self.Disabled and 0.45 or 0.18
			end
			if self.ButtonGradient then
				self.ButtonGradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, blend(background, Color3.new(1, 1, 1), variant == "secondary" and 0.02 or 0.08)),
					ColorSequenceKeypoint.new(1, background)
				})
			end
		end
		if self.TextLabel then
			self.TextLabel.TextColor3 = foreground
		end
		if self.DescriptionLabel then
			self.DescriptionLabel.TextColor3 = foreground
			self.DescriptionLabel.TextTransparency = variant == "secondary" and 0.35 or 0.25
		end
		if self.IconLabel then
			Google.SetIconColor(self.IconLabel, foreground)
		end
	end
	function control:SetVariant(variant)
		self.Variant = variant or "Primary"
		applyVariant(self)
		return self
	end
	function control:SetText(text)
		setText(self.TextLabel, text)
		return self
	end
	function control:SetDescription(text)
		if self.DescriptionLabel then
			setText(self.DescriptionLabel, text)
		end
		return self
	end
	local originalApply = control.ApplyTheme
	function control:ApplyTheme()
		if originalApply then originalApply(self) end
		applyVariant(self)
	end
	addDisabledState(control, applyVariant)
	applyVariant(control)
	if control.Button and control.ButtonScale then
		bind(control.Connections, control.Button.MouseEnter, function()
			if not control.Disabled then
				animate(control.ButtonScale, {Scale = 1.01}, motion.Fast)
			end
		end)
		bind(control.Connections, control.Button.MouseLeave, function()
			animate(control.ButtonScale, {Scale = 1}, motion.Fast)
		end)
		bind(control.Connections, control.Button.MouseButton1Down, function()
			if not control.Disabled then
				animate(control.ButtonScale, {Scale = 0.985}, motion.Fast)
			end
		end)
		bind(control.Connections, control.Button.MouseButton1Up, function()
			animate(control.ButtonScale, {Scale = 1.01}, motion.Fast)
		end)
	end
	control:SetDisabled(control.Disabled)
	return control
end

local function roundPill(instance)
	if not instance then
		return nil
	end
	for _, child in ipairs(instance:GetChildren()) do
		if child:IsA("UICorner") then
			child.CornerRadius = UDim.new(1, 0)
			return child
		end
	end
	return roundFull(instance)
end

local function removeUiChildren(instance, className)
	if not instance then
		return
	end
	for _, child in ipairs(instance:GetChildren()) do
		if child:IsA(className) then
			child:Destroy()
		end
	end
end

local function paintToggle(control)
	local enabled = control.Value and true or false
	local trackColor = enabled and Google.Theme.Primary or Google.Theme.BorderStrong
	if control.Switch then
		control.Switch.Size = UDim2.fromOffset(48, 24)
		control.Switch.Position = UDim2.new(1, -48, 0.5, -12)
		control.Switch.BackgroundColor3 = trackColor
		control.Switch.BackgroundTransparency = control.Disabled and 0.45 or 0
		control.Switch.BorderSizePixel = 0
		control.Switch.ClipsDescendants = true
		roundPill(control.Switch)
		removeUiChildren(control.Switch, "UIStroke")
		removeUiChildren(control.Switch, "UIGradient")
	end
	if control.Knob then
		control.Knob.Size = UDim2.fromOffset(20, 20)
		control.Knob.Position = enabled and UDim2.new(1, -22, 0.5, -10) or UDim2.fromOffset(2, 2)
		control.Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		control.Knob.BackgroundTransparency = 0
		control.Knob.BorderSizePixel = 0
		roundPill(control.Knob)
		removeUiChildren(control.Knob, "UIStroke")
		removeUiChildren(control.Knob, "UIGradient")
	end
	control.SwitchStroke = nil
	control.SwitchGradient = nil
	control.KnobStroke = nil
end

local createToggle = Section.CreateToggle
function Section:CreateToggle(config)
	config = config or {}
	local control = createToggle(self, config)
	control.Disabled = config.Disabled or false
	guardCallback(control)
	paintToggle(control)
	function control:Set(value)
		if self.Disabled then
			return self
		end
		self.Value = value and true or false
		local trackColor = self.Value and Google.Theme.Primary or Google.Theme.BorderStrong
		if self.Switch then
			animate(self.Switch, {BackgroundColor3 = trackColor, BackgroundTransparency = 0}, motion.Base)
		end
		if self.Knob then
			animate(self.Knob, {Position = self.Value and UDim2.new(1, -22, 0.5, -10) or UDim2.fromOffset(2, 2)}, motion.Base)
		end
		self.Callback(self.Value)
		return self
	end
	function control:SetText(text)
		setText(self.Label, text)
		return self
	end
	function control:SetDescription(text)
		if self.DescriptionLabel then
			setText(self.DescriptionLabel, text)
		end
		return self
	end
	function control:On()
		return self:Set(true)
	end
	function control:Off()
		return self:Set(false)
	end
	function control:Toggle()
		return self:Set(not self.Value)
	end
	function control:SetDisabled(value)
		self.Disabled = value and true or false
		setControlOpacity(self, self.Disabled and 0.42 or 0)
		paintToggle(self)
		return self
	end
	function control:Enable()
		return self:SetDisabled(false)
	end
	function control:Disable()
		return self:SetDisabled(true)
	end
	local applyTheme = control.ApplyTheme
	function control:ApplyTheme()
		if applyTheme then
			applyTheme(self)
		end
		paintToggle(self)
	end
	control:SetDisabled(control.Disabled)
	return control
end

local function paintSlider(control, config)
	local trackY = config and config.Description and 54 or 38
	if control.Track then
		control.Track.Size = UDim2.new(1, -22, 0, 8)
		control.Track.Position = UDim2.fromOffset(11, trackY)
		control.Track.BackgroundColor3 = Google.Theme.Border
		control.Track.BackgroundTransparency = control.Disabled and 0.45 or 0
		control.Track.BorderSizePixel = 0
		control.Track.ClipsDescendants = false
		roundPill(control.Track)
		removeUiChildren(control.Track, "UIStroke")
	end
	if control.Fill then
		control.Fill.BackgroundColor3 = Google.Theme.Primary
		control.Fill.BackgroundTransparency = 0
		control.Fill.BorderSizePixel = 0
		roundPill(control.Fill)
		removeUiChildren(control.Fill, "UIGradient")
	end
	if control.Knob then
		control.Knob.Size = UDim2.fromOffset(18, 18)
		control.Knob.BackgroundColor3 = Google.Theme.Primary
		control.Knob.BackgroundTransparency = 0
		control.Knob.BorderSizePixel = 0
		roundPill(control.Knob)
		removeUiChildren(control.Knob, "UIStroke")
		removeUiChildren(control.Knob, "UIGradient")
	end
	if control.KnobDot then
		control.KnobDot:Destroy()
		control.KnobDot = nil
	end
	control.KnobStroke = nil
	control.TrackStroke = nil
	control.FillGradient = nil
	control.KnobScale = nil
end

local createSlider = Section.CreateSlider
function Section:CreateSlider(config)
	config = config or {}
	local control = createSlider(self, config)
	control.Disabled = config.Disabled or false
	control.Step = config.Step or config.Increment
	control.Prefix = config.Prefix or ""
	control.Suffix = config.Suffix or ""
	control.ValueFormat = config.Format or config.ValueFormat
	guardCallback(control)
	if config.Description then
		control.Instance.Size = UDim2.new(1, 0, 0, 74)
		control.DescriptionLabel = create("TextLabel", {
			Text = config.Description,
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = Google.Theme.Muted,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -70, 0, 16),
			Position = UDim2.fromOffset(0, 25),
			Parent = control.Instance
		})
	end
	local function formatValue(self)
		if type(self.ValueFormat) == "function" then
			local ok, result = pcall(self.ValueFormat, self.Value)
			if ok then
				return tostring(result)
			end
		end
		return tostring(self.Prefix or "") .. tostring(self.Value) .. tostring(self.Suffix or "")
	end
	function control:UpdateVisual()
		local alpha = 0
		if self.Max ~= self.Min then
			alpha = math.clamp((self.Value - self.Min) / (self.Max - self.Min), 0, 1)
		end
		if self.ValueLabel then
			self.ValueLabel.Text = formatValue(self)
		end
		local duration = self.Dragging and 0.03 or motion.Base
		if self.Fill then
			animate(self.Fill, {Size = UDim2.fromScale(alpha, 1)}, duration)
		end
		if self.Knob then
			animate(self.Knob, {Position = UDim2.fromScale(alpha, 0.5)}, duration)
		end
	end
	function control:Set(value)
		if self.Disabled then
			return self
		end
		if self.Step and tonumber(self.Step) and tonumber(self.Step) > 0 then
			local step = tonumber(self.Step)
			value = self.Min + math.floor(((value - self.Min) / step) + 0.5) * step
		end
		local precision = self.Precision or 0
		value = math.clamp(value, self.Min, self.Max)
		if precision <= 0 then
			value = math.floor(value + 0.5)
		else
			local power = 10 ^ precision
			value = math.floor(value * power + 0.5) / power
		end
		self.Value = value
		self:UpdateVisual()
		self.Callback(self.Value)
		return self
	end
	function control:SetBounds(minimum, maximum)
		self.Min = tonumber(minimum) or self.Min
		self.Max = tonumber(maximum) or self.Max
		return self:Set(self.Value)
	end
	function control:SetText(text)
		setText(self.Label, text)
		return self
	end
	function control:SetSuffix(text)
		self.Suffix = tostring(text or "")
		self:UpdateVisual()
		return self
	end
	function control:SetPrefix(text)
		self.Prefix = tostring(text or "")
		self:UpdateVisual()
		return self
	end
	function control:SetDisabled(value)
		self.Disabled = value and true or false
		setControlOpacity(self, self.Disabled and 0.42 or 0)
		paintSlider(self, config)
		self:UpdateVisual()
		return self
	end
	function control:Enable()
		return self:SetDisabled(false)
	end
	function control:Disable()
		return self:SetDisabled(true)
	end
	local applyTheme = control.ApplyTheme
	function control:ApplyTheme()
		if applyTheme then
			applyTheme(self)
		end
		if self.DescriptionLabel then
			self.DescriptionLabel.TextColor3 = Google.Theme.Muted
		end
		paintSlider(self, config)
		self:UpdateVisual()
	end
	paintSlider(control, config)
	control:UpdateVisual()
	control:SetDisabled(control.Disabled)
	return control
end

local createDropdownBase = Section.CreateDropdown
function Section:CreateDropdown(config)
	config = config or {}
	local control = createDropdownBase(self, config)
	control.Disabled = config.Disabled or false
	control.Placeholder = config.Placeholder or "Select"
	if control.Main then
		round(control.Main, tonumber(config.CornerRadius) or 10)
	end
	local function optionSelected(self, option)
		if self.Multi then
			for _, value in ipairs(self.Value) do
				if value == option or tostring(value) == tostring(option) then return true end
			end
			return false
		end
		return self.Value == option or tostring(self.Value) == tostring(option)
	end
	local function decorateOptions(self)
		for _, item in ipairs(self.OptionsFrame:GetChildren()) do
			if item:IsA("TextButton") then
				local selected = optionSelected(self, item.Name)
				item.BackgroundTransparency = selected and 0.15 or 1
				item.BackgroundColor3 = selected and Google.Theme.PrimarySoft or Google.Theme.Hover
				local label = item:FindFirstChildOfClass("TextLabel")
				if label then
					label.TextColor3 = selected and Google.Theme.Primary or Google.Theme.Text
					label.Size = UDim2.new(1, -34, 1, 0)
				end
				local check = item:FindFirstChild("SelectedCheck")
				if not check then
					check = Google.CreateIcon("check", 14, Google.Theme.Primary, item, {
						Name = "SelectedCheck",
						Position = UDim2.new(1, -22, 0.5, -7)
					})
				end
				check.Visible = selected
			end
		end
	end
	local originalRefresh = control.RefreshOptions
	function control:RefreshOptions()
		originalRefresh(self)
		decorateOptions(self)
	end
	local originalDisplay = control.DisplayValue
	function control:DisplayValue()
		originalDisplay(self)
		if not self.Multi and (self.Value == nil or self.Value == "") then
			self.SelectedLabel.Text = self.Placeholder
		end
		decorateOptions(self)
	end
	local originalOpen = control.OpenMenu
	function control:OpenMenu()
		if self.Disabled then return self end
		originalOpen(self)
		if self.MainStroke then animate(self.MainStroke, {Color = Google.Theme.Primary, Transparency = 0}, motion.Fast) end
		return self
	end
	local originalClose = control.CloseMenu
	function control:CloseMenu()
		originalClose(self)
		if self.MainStroke then animate(self.MainStroke, {Color = Google.Theme.Border, Transparency = 0.08}, motion.Fast) end
		return self
	end
	local originalSelect = control.Select
	function control:Select(option)
		if self.Disabled then return self end
		originalSelect(self, option)
		decorateOptions(self)
		return self
	end
	function control:SetOptions(options)
		self.Options = type(options) == "table" and options or {}
		if not self.Multi then
			local exists = false
			for _, option in ipairs(self.Options) do
				if option == self.Value then exists = true break end
			end
			if not exists then self.Value = self.Options[1] end
		end
		self:RefreshOptions()
		self:DisplayValue()
		return self
	end
	function control:AddOption(option)
		table.insert(self.Options, option)
		self:RefreshOptions()
		return self
	end
	function control:RemoveOption(option)
		for i, value in ipairs(self.Options) do
			if value == option or tostring(value) == tostring(option) then
				table.remove(self.Options, i)
				break
			end
		end
		self:RefreshOptions()
		self:DisplayValue()
		return self
	end
	function control:Clear()
		self.Value = self.Multi and {} or nil
		self:DisplayValue()
		self.Callback(self.Value)
		return self
	end
	local originalSet = control.Set
	function control:Set(value)
		if self.Disabled then return self end
		originalSet(self, value)
		decorateOptions(self)
		return self
	end
	local originalApply = control.ApplyTheme
	function control:ApplyTheme()
		if originalApply then originalApply(self) end
		decorateOptions(self)
	end
	addDisabledState(control, function(self)
		if self.Main then self.Main.BackgroundTransparency = self.Disabled and 0.35 or 0 end
	end)
	control:RefreshOptions()
	control:DisplayValue()
	control:SetDisabled(control.Disabled)
	return control
end

local createTextboxBase = Section.CreateTextbox
function Section:CreateTextbox(config)
	config = config or {}
	local control = createTextboxBase(self, config)
	control.Disabled = config.Disabled or false
	control.MaxLength = config.MaxLength
	control.Min = config.Min
	control.Max = config.Max
	guardCallback(control)
	if control.Entry then
		round(control.Entry, tonumber(config.CornerRadius) or 10)
		control.EntryStroke = control.EntryStroke or getStroke(control.Entry, "TextboxStroke", Google.Theme.Border, 0.08, 1)
		control.EntryGradient = getGradient(control.Entry, Google.Theme.Input, blend(Google.Theme.Input, Google.Theme.Hover, 0.35), 90)
	end
	if config.ClearButton ~= false and control.Entry then
		control.ClearButton = create("TextButton", {
			Text = "×",
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextColor3 = Google.Theme.Muted,
			Size = UDim2.fromOffset(24, 24),
			Position = UDim2.new(1, -28, 0, 28),
			BackgroundColor3 = Google.Theme.Hover,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Parent = control.Instance
		})
		round(control.ClearButton, 6)
		bind(control.Connections, control.ClearButton.MouseButton1Click, function()
			control:Set("")
		end)
		bind(control.Connections, control.ClearButton.MouseEnter, function()
			animate(control.ClearButton, {BackgroundTransparency = 0}, motion.Fast)
		end)
		bind(control.Connections, control.ClearButton.MouseLeave, function()
			animate(control.ClearButton, {BackgroundTransparency = 1}, motion.Fast)
		end)
	end
	local originalSet = control.Set
	function control:Set(value)
		if self.Disabled then return self end
		if self.MaxLength and type(value) == "string" and #value > self.MaxLength then
			value = value:sub(1, self.MaxLength)
		end
		if self.Numeric then
			local numberValue = tonumber(value)
			if numberValue then
				if self.Min then numberValue = math.max(numberValue, self.Min) end
				if self.Max then numberValue = math.min(numberValue, self.Max) end
				value = numberValue
			end
		end
		originalSet(self, value)
		return self
	end
	function control:SetPlaceholder(text)
		if self.Entry then self.Entry.PlaceholderText = tostring(text or "") end
		return self
	end
	function control:SetText(text)
		return self:Set(text)
	end
	function control:SetBounds(minimum, maximum)
		self.Min = minimum
		self.Max = maximum
		return self:Set(self.Value)
	end
	function control:SetMaxLength(length)
		self.MaxLength = tonumber(length)
		return self:Set(self.Value)
	end
	bind(control.Connections, control.Entry:GetPropertyChangedSignal("Text"), function()
		if control.MaxLength and #control.Entry.Text > control.MaxLength then
			control.Entry.Text = control.Entry.Text:sub(1, control.MaxLength)
		end
		if control.ClearButton then
			control.ClearButton.Visible = control.Entry.Text ~= ""
		end
	end)
	local originalApply = control.ApplyTheme
	function control:ApplyTheme()
		if originalApply then originalApply(self) end
		if self.EntryGradient then
			self.EntryGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Google.Theme.Input),
				ColorSequenceKeypoint.new(1, blend(Google.Theme.Input, Google.Theme.Hover, 0.35))
			})
		end
		if self.ClearButton then
			self.ClearButton.BackgroundColor3 = Google.Theme.Hover
			self.ClearButton.TextColor3 = Google.Theme.Muted
		end
	end
	addDisabledState(control, function(self)
		if self.Entry then
			self.Entry.TextEditable = not self.Disabled
			self.Entry.BackgroundTransparency = self.Disabled and 0.4 or 0
		end
	end)
	control:SetDisabled(control.Disabled)
	return control
end

local createKeybindBase = Section.CreateKeybind
function Section:CreateKeybind(config)
	config = config or {}
	local control = createKeybindBase(self, config)
	control.Disabled = config.Disabled or false
	guardCallback(control)
	if control.Button then
		round(control.Button, tonumber(config.CornerRadius) or 10)
		control.ButtonGradient = getGradient(control.Button, Google.Theme.Input, blend(Google.Theme.Input, Google.Theme.Hover, 0.45), 90)
	end
	function control:SetText(text)
		setText(self.Label, text)
		return self
	end
	function control:SetMode(mode)
		self.Mode = mode or "Toggle"
		return self
	end
	function control:Unbind()
		self.Value = Enum.KeyCode.Unknown
		self.Button.Text = "None"
		return self
	end
	local originalSet = control.Set
	function control:Set(keycode)
		if self.Disabled then return self end
		originalSet(self, keycode)
		return self
	end
	local originalApply = control.ApplyTheme
	function control:ApplyTheme()
		if originalApply then originalApply(self) end
		if self.ButtonGradient then
			self.ButtonGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Google.Theme.Input),
				ColorSequenceKeypoint.new(1, blend(Google.Theme.Input, Google.Theme.Hover, 0.45))
			})
		end
	end
	addDisabledState(control, function(self)
		if self.Button then self.Button.BackgroundTransparency = self.Disabled and 0.4 or 0 end
	end)
	control:SetDisabled(control.Disabled)
	return control
end

local createColorPickerBase = Section.CreateColorPicker
function Section:CreateColorPicker(config)
	config = config or {}
	if not config.Colors then
		config.Colors = controlDefaults.ColorPalette
	end
	local control = createColorPickerBase(self, config)
	control.Disabled = config.Disabled or false
	guardCallback(control)
	if control.Button then
		round(control.Button, tonumber(config.CornerRadius) or 10)
		control.ButtonStroke = control.ButtonStroke or getStroke(control.Button, "ColorButtonStroke", Google.Theme.Border, 0.08, 1)
	end
	function control:GetHex()
		return formatHex(self.Value)
	end
	function control:SetHex(value)
		local color = colorFromHex(value)
		if color then
			self:Set(color)
		end
		return self
	end
	function control:Close()
		if self.Open and self.Button then
			self.Open = false
			animate(self.Palette, {Size = UDim2.new(1, 0, 0, 0)}, motion.Fast, nil, nil, function()
				self.Palette.Visible = false
			end)
			self.Instance.Size = UDim2.new(1, 0, 0, 38)
			self:RefreshSection()
		end
		return self
	end
	local originalSet = control.Set
	function control:Set(color)
		if self.Disabled then return self end
		originalSet(self, color)
		return self
	end
	local originalApply = control.ApplyTheme
	function control:ApplyTheme()
		if originalApply then originalApply(self) end
		if self.ButtonStroke then self.ButtonStroke.Color = Google.Theme.Border end
	end
	addDisabledState(control, function(self)
		if self.Button then self.Button.BackgroundTransparency = self.Disabled and 0.45 or 0 end
	end)
	control:SetDisabled(control.Disabled)
	return control
end

local createLabelBase = Section.CreateLabel
function Section:CreateLabel(config)
	if type(config) ~= "table" then
		config = {Name = config}
	end
	config = config or {}
	local control = createLabelBase(self, config)
	function control:SetColor(color)
		if isColor(color) and self.Label then self.Label.TextColor3 = color end
		return self
	end
	function control:SetSize(size)
		if self.Label then self.Label.TextSize = tonumber(size) or self.Label.TextSize end
		return self
	end
	function control:SetAlignment(alignment)
		if self.Label then
			local value = tostring(alignment or "Left")
			if value == "Center" then
				self.Label.TextXAlignment = Enum.TextXAlignment.Center
			elseif value == "Right" then
				self.Label.TextXAlignment = Enum.TextXAlignment.Right
			else
				self.Label.TextXAlignment = Enum.TextXAlignment.Left
			end
		end
		return self
	end
	function control:SetVisible(value)
		self.Instance.Visible = value and true or false
		self:RefreshSection()
		return self
	end
	if config.Color and isColor(config.Color) then control:SetColor(config.Color) end
	if config.Size then control:SetSize(config.Size) end
	if config.Alignment then control:SetAlignment(config.Alignment) end
	return control
end

local createParagraphBase = Section.CreateParagraph
function Section:CreateParagraph(config)
	config = config or {}
	local control = createParagraphBase(self, config)
	control.Variant = config.Variant or "Default"
	if control.Instance then
		round(control.Instance, tonumber(config.CornerRadius) or 10)
		control.ParagraphGradient = getGradient(control.Instance, Google.Theme.CardAlt, blend(Google.Theme.CardAlt, Google.Theme.Hover, 0.35), 90)
	end
	function control:SetTitle(text)
		if self.TitleLabel then setText(self.TitleLabel, text) end
		return self
	end
	function control:SetText(text)
		setText(self.TextLabel, text)
		return self
	end
	local function applyParagraphVariant(self)
		local variant = string.lower(tostring(self.Variant or "Default"))
		local strokeColor = Google.Theme.Border
		local bg = Google.Theme.CardAlt
		if variant == "info" then
			strokeColor = Google.Theme.Primary
			bg = Google.Theme.PrimarySoft
		elseif variant == "success" then
			strokeColor = Google.Theme.Success
		elseif variant == "warning" then
			strokeColor = Google.Theme.Warning
		elseif variant == "danger" then
			strokeColor = Google.Theme.Danger
		end
		self.Instance.BackgroundColor3 = bg
		if self.outline then self.outline.Color = strokeColor end
		if self.ParagraphGradient then
			self.ParagraphGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, bg),
				ColorSequenceKeypoint.new(1, blend(bg, Google.Theme.Hover, 0.35))
			})
		end
	end
	function control:SetVariant(variant)
		self.Variant = variant or "Default"
		applyParagraphVariant(self)
		return self
	end
	local originalApply = control.ApplyTheme
	function control:ApplyTheme()
		if originalApply then originalApply(self) end
		applyParagraphVariant(self)
	end
	applyParagraphVariant(control)
	return control
end

local createImageBase = Section.CreateImage
function Section:CreateImage(config)
	config = config or {}
	local control = createImageBase(self, config)
	if control.ImageFrame then
		round(control.ImageFrame, tonumber(config.ImageCornerRadius) or tonumber(config.CornerRadius) or 10)
		control.ImageGradient = getGradient(control.ImageFrame, Google.Theme.Input, blend(Google.Theme.Input, Google.Theme.Hover, 0.35), 90)
	end
	if control.Image then
		control.Image.ImageTransparency = tonumber(config.Transparency) or 0
	end
	function control:SetTitle(text)
		if self.TitleLabel then setText(self.TitleLabel, text) end
		return self
	end
	function control:SetDescription(text)
		if self.DescriptionLabel then setText(self.DescriptionLabel, text) end
		return self
	end
	function control:SetHeight(height)
		height = math.max(48, tonumber(height) or 180)
		if self.ImageFrame then
			self.ImageFrame.Size = UDim2.new(1, -20, 0, height)
		end
		local base = height + 20
		if self.TitleLabel then base = base + 22 end
		if self.DescriptionLabel then base = base + 18 end
		self.Instance.Size = UDim2.new(1, 0, 0, base)
		self:RefreshSection()
		return self
	end
	function control:SetTransparency(value)
		if self.Image then self.Image.ImageTransparency = tonumber(value) or 0 end
		return self
	end
	function control:SetRounded(radius)
		if self.ImageFrame then round(self.ImageFrame, tonumber(radius) or 10) end
		return self
	end
	if type(config.Callback) == "function" and control.ImageFrame then
		control.ImageFrame.Active = true
		bind(control.Connections, control.ImageFrame.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				config.Callback(control:Get())
			end
		end)
	end
	local originalApply = control.ApplyTheme
	function control:ApplyTheme()
		if originalApply then originalApply(self) end
		if self.ImageGradient then
			self.ImageGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Google.Theme.Input),
				ColorSequenceKeypoint.new(1, blend(Google.Theme.Input, Google.Theme.Hover, 0.35))
			})
		end
	end
	return control
end

local createDividerBase = Section.CreateDivider
function Section:CreateDivider(config)
	if type(config) ~= "table" then
		config = {Name = config}
	end
	config = config or {}
	local control = createDividerBase(self, config)
	local color = config.Color or Google.Theme.Border
	if control.Left then getGradient(control.Left, Color3.fromRGB(255, 255, 255), color, 0) end
	if control.Right then getGradient(control.Right, color, Color3.fromRGB(255, 255, 255), 0) end
	if control.Line then getGradient(control.Line, Google.Theme.Border, blend(Google.Theme.Border, Google.Theme.Primary, 0.35), 0) end
	function control:SetText(text)
		if self.Label then setText(self.Label, text) end
		return self
	end
	function control:SetColor(newColor)
		if isColor(newColor) then
			if self.Left then self.Left.BackgroundColor3 = newColor end
			if self.Right then self.Right.BackgroundColor3 = newColor end
			if self.Line then self.Line.BackgroundColor3 = newColor end
		end
		return self
	end
	function control:SetThickness(thickness)
		thickness = tonumber(thickness) or 1
		if self.Left then self.Left.Size = UDim2.new(0.34, -8, 0, thickness) end
		if self.Right then self.Right.Size = UDim2.new(0.34, -8, 0, thickness) end
		if self.Line then self.Line.Size = UDim2.new(1, 0, 0, thickness) end
		return self
	end
	if config.Thickness then control:SetThickness(config.Thickness) end
	if config.Color then control:SetColor(config.Color) end
	return control
end

local baseThemes = Google.Themes
Google.Themes = {
	Google = baseThemes.Google,
	Red = baseThemes.Red,
	Yellow = baseThemes.Yellow,
	Green = baseThemes.Green,
	DarkGoogle = baseThemes.DarkGoogle,
	DarkRed = baseThemes.DarkRed,
	DarkYellow = baseThemes.DarkYellow,
	DarkGreen = baseThemes.DarkGreen
}
Google.ActiveTheme = Google.Themes[Google.ActiveTheme] and Google.ActiveTheme or "Google"
Google.Theme = Google.Themes[Google.ActiveTheme]

return Google
