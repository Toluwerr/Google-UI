local Google = {}
Google.__index = Google
Google.Build = "components-config-system"
Google.Flags = Google.Flags or {}
Google.Options = Google.Options or {}
Google.ConfigManager = Google.ConfigManager or nil

local function getService(name)
	local service = game:GetService(name)
	return if cloneref then cloneref(service) else service
end

local TweenService = getService("TweenService")
local UserInputService = getService("UserInputService")
local Players = getService("Players")
local CoreGui = getService("CoreGui")
local Workspace = getService("Workspace")
local HttpService = getService("HttpService")

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
	local corner = parent and parent:FindFirstChildOfClass("UICorner")
	if not corner then
		corner = create("UICorner", {
			Name = "Corner",
			Parent = parent
		})
	end
	corner.CornerRadius = UDim.new(0, radius or 6)
	return corner
end

local function roundFull(parent)
	local corner = parent and parent:FindFirstChildOfClass("UICorner")
	if not corner then
		corner = create("UICorner", {
			Name = "Corner",
			Parent = parent
		})
	end
	corner.CornerRadius = UDim.new(1, 0)
	return corner
end

local function outline(parent, color, transparency, thickness)
	local finalTransparency = transparency
	if finalTransparency == nil then
		finalTransparency = 0.78
	end

	local finalThickness = tonumber(thickness) or 1
	if finalThickness > 0 then
		finalThickness = 1
	end

	local stroke = create("UIStroke", {
		Color = color,
		Transparency = finalTransparency,
		Thickness = finalThickness,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
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

local function surface(parent, topColor, bottomColor)
	if parent then
		local old = parent:FindFirstChild("SurfaceShade")
		if old then
			old:Destroy()
		end
	end
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

local function componentColor(name, fallback)
	local color = Google.Theme and Google.Theme[name]
	if typeof(color) == "Color3" then
		return color
	end
	return fallback
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
	Blue = {
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
		Success = Color3.fromRGB(66, 133, 244),
		Warning = Color3.fromRGB(66, 133, 244),
		Danger = Color3.fromRGB(66, 133, 244),
		Input = Color3.fromRGB(255, 255, 255),
		Hover = Color3.fromRGB(241, 245, 249),
		Shadow = Color3.fromRGB(15, 23, 42)
	},
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
		Primary = Color3.fromRGB(66, 133, 244),
		PrimaryHover = Color3.fromRGB(52, 103, 209),
		PrimarySoft = Color3.fromRGB(232, 240, 254),
		Success = Color3.fromRGB(52, 168, 83),
		Warning = Color3.fromRGB(251, 188, 4),
		Danger = Color3.fromRGB(234, 67, 53),
		Input = Color3.fromRGB(255, 255, 255),
		Hover = Color3.fromRGB(241, 245, 249),
		Shadow = Color3.fromRGB(15, 23, 42),
		Button = Color3.fromRGB(66, 133, 244),
		ButtonHover = Color3.fromRGB(52, 103, 209),
		Toggle = Color3.fromRGB(52, 168, 83),
		ToggleHover = Color3.fromRGB(36, 130, 63),
		Slider = Color3.fromRGB(251, 188, 4),
		SliderText = Color3.fromRGB(174, 122, 0),
		Dropdown = Color3.fromRGB(234, 67, 53),
		DropdownSoft = Color3.fromRGB(252, 232, 230),
		InputAccent = Color3.fromRGB(66, 133, 244),
		Keybind = Color3.fromRGB(234, 67, 53),
		TabAccents = {
			{Color = Color3.fromRGB(66, 133, 244), Soft = Color3.fromRGB(232, 240, 254)},
			{Color = Color3.fromRGB(234, 67, 53), Soft = Color3.fromRGB(252, 232, 230)},
			{Color = Color3.fromRGB(251, 188, 4), Soft = Color3.fromRGB(254, 247, 224)},
			{Color = Color3.fromRGB(52, 168, 83), Soft = Color3.fromRGB(230, 244, 234)}
		}
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
	DarkBlue = {
		Window = Color3.fromRGB(7, 8, 10),
		Topbar = Color3.fromRGB(10, 11, 14),
		Sidebar = Color3.fromRGB(8, 9, 12),
		Page = Color3.fromRGB(5, 6, 8),
		Card = Color3.fromRGB(13, 14, 17),
		CardAlt = Color3.fromRGB(18, 19, 23),
		Text = Color3.fromRGB(238, 242, 247),
		Muted = Color3.fromRGB(156, 166, 182),
		Subtle = Color3.fromRGB(96, 105, 120),
		Border = Color3.fromRGB(26, 28, 34),
		BorderStrong = Color3.fromRGB(42, 45, 54),
		Primary = Color3.fromRGB(66, 133, 244),
		PrimaryHover = Color3.fromRGB(95, 157, 247),
		PrimarySoft = Color3.fromRGB(24, 47, 86),
		Success = Color3.fromRGB(52, 168, 83),
		Warning = Color3.fromRGB(251, 188, 4),
		Danger = Color3.fromRGB(234, 67, 53),
		Input = Color3.fromRGB(9, 10, 13),
		Hover = Color3.fromRGB(18, 20, 25),
		Shadow = Color3.fromRGB(0, 0, 0)
	},
	DarkGoogle = {
		Window = Color3.fromRGB(7, 8, 10),
		Topbar = Color3.fromRGB(10, 11, 14),
		Sidebar = Color3.fromRGB(8, 9, 12),
		Page = Color3.fromRGB(5, 6, 8),
		Card = Color3.fromRGB(13, 14, 17),
		CardAlt = Color3.fromRGB(18, 19, 23),
		Text = Color3.fromRGB(238, 242, 247),
		Muted = Color3.fromRGB(156, 166, 182),
		Subtle = Color3.fromRGB(96, 105, 120),
		Border = Color3.fromRGB(26, 28, 34),
		BorderStrong = Color3.fromRGB(42, 45, 54),
		Primary = Color3.fromRGB(66, 133, 244),
		PrimaryHover = Color3.fromRGB(95, 157, 247),
		PrimarySoft = Color3.fromRGB(24, 47, 86),
		Success = Color3.fromRGB(52, 168, 83),
		Warning = Color3.fromRGB(251, 188, 4),
		Danger = Color3.fromRGB(234, 67, 53),
		Input = Color3.fromRGB(9, 10, 13),
		Hover = Color3.fromRGB(18, 20, 25),
		Shadow = Color3.fromRGB(0, 0, 0)
	},
	DarkRed = {
		Window = Color3.fromRGB(7, 8, 10),
		Topbar = Color3.fromRGB(10, 11, 14),
		Sidebar = Color3.fromRGB(8, 9, 12),
		Page = Color3.fromRGB(5, 6, 8),
		Card = Color3.fromRGB(13, 14, 17),
		CardAlt = Color3.fromRGB(18, 19, 23),
		Text = Color3.fromRGB(238, 242, 247),
		Muted = Color3.fromRGB(156, 166, 182),
		Subtle = Color3.fromRGB(96, 105, 120),
		Border = Color3.fromRGB(26, 28, 34),
		BorderStrong = Color3.fromRGB(42, 45, 54),
		Primary = Color3.fromRGB(234, 67, 53),
		PrimaryHover = Color3.fromRGB(247, 99, 87),
		PrimarySoft = Color3.fromRGB(83, 31, 28),
		Success = Color3.fromRGB(52, 168, 83),
		Warning = Color3.fromRGB(251, 188, 4),
		Danger = Color3.fromRGB(234, 67, 53),
		Input = Color3.fromRGB(9, 10, 13),
		Hover = Color3.fromRGB(18, 20, 25),
		Shadow = Color3.fromRGB(0, 0, 0)
	},
	DarkYellow = {
		Window = Color3.fromRGB(7, 8, 10),
		Topbar = Color3.fromRGB(10, 11, 14),
		Sidebar = Color3.fromRGB(8, 9, 12),
		Page = Color3.fromRGB(5, 6, 8),
		Card = Color3.fromRGB(13, 14, 17),
		CardAlt = Color3.fromRGB(18, 19, 23),
		Text = Color3.fromRGB(238, 242, 247),
		Muted = Color3.fromRGB(156, 166, 182),
		Subtle = Color3.fromRGB(96, 105, 120),
		Border = Color3.fromRGB(26, 28, 34),
		BorderStrong = Color3.fromRGB(42, 45, 54),
		Primary = Color3.fromRGB(251, 188, 4),
		PrimaryHover = Color3.fromRGB(255, 207, 68),
		PrimarySoft = Color3.fromRGB(81, 61, 17),
		Success = Color3.fromRGB(52, 168, 83),
		Warning = Color3.fromRGB(251, 188, 4),
		Danger = Color3.fromRGB(234, 67, 53),
		Input = Color3.fromRGB(9, 10, 13),
		Hover = Color3.fromRGB(18, 20, 25),
		Shadow = Color3.fromRGB(0, 0, 0)
	},
	DarkGreen = {
		Window = Color3.fromRGB(7, 8, 10),
		Topbar = Color3.fromRGB(10, 11, 14),
		Sidebar = Color3.fromRGB(8, 9, 12),
		Page = Color3.fromRGB(5, 6, 8),
		Card = Color3.fromRGB(13, 14, 17),
		CardAlt = Color3.fromRGB(18, 19, 23),
		Text = Color3.fromRGB(238, 242, 247),
		Muted = Color3.fromRGB(156, 166, 182),
		Subtle = Color3.fromRGB(96, 105, 120),
		Border = Color3.fromRGB(26, 28, 34),
		BorderStrong = Color3.fromRGB(42, 45, 54),
		Primary = Color3.fromRGB(52, 168, 83),
		PrimaryHover = Color3.fromRGB(73, 194, 105),
		PrimarySoft = Color3.fromRGB(21, 67, 39),
		Success = Color3.fromRGB(52, 168, 83),
		Warning = Color3.fromRGB(251, 188, 4),
		Danger = Color3.fromRGB(234, 67, 53),
		Input = Color3.fromRGB(9, 10, 13),
		Hover = Color3.fromRGB(18, 20, 25),
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
		ClipsDescendants = false,
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
	self.BodyCorner = round(body, 18)
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
		BackgroundTransparency = 0.45,
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
		BackgroundTransparency = 0.45,
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
		Padding = UDim.new(0, 4),
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
	tab.AccentColor = config.AccentColor or config.Accent
	tab.Index = #self.Tabs + 1
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
		Padding = UDim.new(0, 10),
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

function Tab:GetAccent()
	if typeof(self.AccentColor) == "Color3" then
		return self.AccentColor, Google.Theme.PrimarySoft
	end

	local accents = Google.Theme.TabAccents
	if type(accents) == "table" and #accents > 0 then
		local entry = accents[((self.Index or 1) - 1) % #accents + 1]
		if type(entry) == "table" and typeof(entry.Color) == "Color3" then
			return entry.Color, entry.Soft or Google.Theme.PrimarySoft
		elseif typeof(entry) == "Color3" then
			return entry, Google.Theme.PrimarySoft
		end
	end

	return Google.Theme.Primary, Google.Theme.PrimarySoft
end

function Tab:SetActive(active)
	self.Active = active
	local accentColor, accentSoft = self:GetAccent()
	if active then
		self.Page.Visible = true
		self.Page.Position = self.Window.IsMobile and UDim2.fromOffset(0, 10) or UDim2.fromOffset(6, 0)
		self.Accent.Visible = true
		self.Accent.BackgroundColor3 = accentColor
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
		animate(self.Button, {BackgroundTransparency = 0, BackgroundColor3 = accentSoft}, motion.Base)
		self.TextLabel.TextColor3 = accentColor
		Google.SetIconColor(self.IconLabel, accentColor)
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
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = self.Page
	})
	round(frame, 12)
	section.Instance = frame
	section.outline = outline(frame, Google.Theme.Border, 1, 0)

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
		Padding = UDim.new(0, 7),
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
	section.outline = outline(frame, Google.Theme.Border, 0.52, 0.75)
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
		Padding = UDim.new(0, 7),
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
	self.Instance.BackgroundTransparency = 0
	self.outline.Color = Google.Theme.Border
	self.outline.Transparency = 1
	self.outline.Thickness = 0
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
	self.MainStroke = outline(self.Main, Google.Theme.Border, 0.86, 1)
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
	self.MenuStroke = outline(self.Menu, Google.Theme.Border, 0.86, 1)
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
		self.SearchStroke = outline(self.SearchBox, Google.Theme.Border, 0.82, 1)
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
	self.EntryStroke = outline(self.Entry, Google.Theme.Border, 0.86, 1)
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
		animate(self.EntryStroke, {Color = componentColor("InputAccent", Google.Theme.Primary), Transparency = 0}, motion.Fast)
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
	self.ButtonStroke = outline(self.Button, Google.Theme.Border, 0.84, 1)
	function self:Set(keycode)
		self.Value = keycode
		self.Button.Text = keycode.Name
	end
	function self:Get()
		return self.Value
	end
	bind(self.Connections, self.Button.MouseEnter, function()
		animate(self.ButtonStroke, {Color = componentColor("Keybind", Google.Theme.Primary), Transparency = 0}, motion.Fast)
	end)
	bind(self.Connections, self.Button.MouseLeave, function()
		if not self.Binding then
			animate(self.ButtonStroke, {Color = Google.Theme.Border, Transparency = 0.08}, motion.Fast)
		end
	end)
	bind(self.Connections, self.Button.MouseButton1Click, function()
		self.Binding = true
		self.Button.Text = "..."
		animate(self.ButtonStroke, {Color = componentColor("Keybind", Google.Theme.Primary), Transparency = 0}, motion.Fast)
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
	self.ButtonStroke = outline(self.Button, Google.Theme.Border, 0.84, 1)
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
		outline(swatch, Google.Theme.Border, 0.82, 1)
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
	self.outline = outline(self.Instance, Google.Theme.Border, 1, 0)
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
	self.Instance.ClipsDescendants = false
	round(self.Instance, 10)
	self.outline = outline(self.Instance, Google.Theme.Border, 1, 0)
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
	self.ImageStroke = outline(self.ImageFrame, Google.Theme.Border, 0.86, 1)
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
		self.ImageStroke.Transparency = 0.86
		self.ImageStroke.Thickness = 1
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
		self.TabLayout.Padding = UDim.new(0, 6)
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
		self.TabLayout.Padding = UDim.new(0, 4)
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
	self.TopbarLine.BackgroundTransparency = 0.45
	self.Sidebar.BackgroundColor3 = theme.Sidebar
	self.SidebarLine.BackgroundColor3 = theme.Border
	self.SidebarLine.BackgroundTransparency = 0.45
	self.PageWrap.BackgroundColor3 = theme.Page
	self.PageWrap.BackgroundTransparency = 0
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
		tab.Page.BackgroundTransparency = 1
		tab.Page.ScrollBarImageColor3 = theme.BorderStrong
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
	outline(frame, Google.Theme.Border, 0.52, 0.75)
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
	outline(dialog, Google.Theme.Border, 1, 0)
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
	outline(dialog, Google.Theme.Border, 1, 0)
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
	outline(input, Google.Theme.Border, 0.82, 1)
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
	if stroke.Thickness > 0 and stroke.Thickness <= 1 then
		stroke.Thickness = 0.75
	end
	if stroke.Thickness > 0 and stroke.Transparency < 0.42 then
		stroke.Transparency = 0.42
	end
	pcall(function()
		stroke.LineJoinMode = Enum.LineJoinMode.Round
	end)
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

local function removeButtonChrome(button)
	if not button then
		return
	end
	for _, child in ipairs(button:GetChildren()) do
		if child:IsA("UIStroke") or child:IsA("UIGradient") then
			child:Destroy()
		end
	end
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
		control.Button.BorderSizePixel = 0
		round(control.Button, tonumber(config.CornerRadius) or 10)
		removeButtonChrome(control.Button)
		control.ButtonStroke = nil
		control.ButtonGradient = nil
		control.ButtonScale = getScale(control.Button)
	end
	local function applyVariant(self)
		local variant = string.lower(tostring(self.Variant or "Primary"))
		local background = componentColor("Button", Google.Theme.Primary)
		local foreground = Color3.new(1, 1, 1)
		local transparent = 0
		if variant == "secondary" then
			background = Google.Theme.CardAlt
			foreground = Google.Theme.Text
		elseif variant == "ghost" then
			background = Google.Theme.Hover
			foreground = componentColor("Button", Google.Theme.Primary)
			transparent = 0.15
		elseif variant == "danger" or variant == "red" then
			background = Google.Theme.Danger
			foreground = Color3.new(1, 1, 1)
		elseif variant == "success" or variant == "green" then
			background = Google.Theme.Success
			foreground = Color3.new(1, 1, 1)
		elseif variant == "warning" or variant == "yellow" then
			background = Google.Theme.Warning
			foreground = Color3.fromRGB(22, 28, 36)
		end
		if self.Button then
			removeButtonChrome(self.Button)
			self.Button.BackgroundColor3 = background
			self.Button.BackgroundTransparency = self.Disabled and 0.55 or transparent
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
	local toggleColor = componentColor("Toggle", Google.Theme.Primary)
	local trackColor = enabled and toggleColor or Google.Theme.BorderStrong
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
		local toggleColor = componentColor("Toggle", Google.Theme.Primary)
		local trackColor = self.Value and toggleColor or Google.Theme.BorderStrong
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
		control.Fill.BackgroundColor3 = componentColor("Slider", Google.Theme.Primary)
		control.Fill.BackgroundTransparency = 0
		control.Fill.BorderSizePixel = 0
		roundPill(control.Fill)
		removeUiChildren(control.Fill, "UIGradient")
	end
	if control.Knob then
		control.Knob.Size = UDim2.fromOffset(18, 18)
		control.Knob.BackgroundColor3 = componentColor("Slider", Google.Theme.Primary)
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
	if control.ValueLabel then
		control.ValueLabel.TextColor3 = componentColor("SliderText", componentColor("Slider", Google.Theme.Primary))
	end
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
				local dropdownColor = componentColor("Dropdown", Google.Theme.Primary)
				local dropdownSoft = componentColor("DropdownSoft", Google.Theme.PrimarySoft)
				item.BackgroundColor3 = selected and dropdownSoft or Google.Theme.Hover
				local label = item:FindFirstChildOfClass("TextLabel")
				if label then
					label.TextColor3 = selected and dropdownColor or Google.Theme.Text
					label.Size = UDim2.new(1, -34, 1, 0)
				end
				local check = item:FindFirstChild("SelectedCheck")
				if not check then
					check = Google.CreateIcon("check", 14, dropdownColor, item, {
						Name = "SelectedCheck",
						Position = UDim2.new(1, -22, 0.5, -7)
					})
				end
				Google.SetIconColor(check, dropdownColor)
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
		if self.MainStroke then animate(self.MainStroke, {Color = componentColor("Dropdown", Google.Theme.Primary), Transparency = 0}, motion.Fast) end
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
		if self.Arrow then
			Google.SetIconColor(self.Arrow, componentColor("Dropdown", Google.Theme.Muted))
		end
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
		if self.outline then
			self.outline.Color = strokeColor
			self.outline.Transparency = 1
			self.outline.Thickness = 0
		end
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
	Blue = baseThemes.Blue,
	Google = baseThemes.Google,
	Red = baseThemes.Red,
	Yellow = baseThemes.Yellow,
	Green = baseThemes.Green,
	DarkBlue = baseThemes.DarkBlue,
	DarkGoogle = baseThemes.DarkGoogle,
	DarkRed = baseThemes.DarkRed,
	DarkYellow = baseThemes.DarkYellow,
	DarkGreen = baseThemes.DarkGreen
}
Google.ActiveTheme = Google.Themes[Google.ActiveTheme] and Google.ActiveTheme or "Google"
Google.Theme = Google.Themes[Google.ActiveTheme]


local gridMethods = {}
gridMethods.__index = gridMethods
setmetatable(gridMethods, {__index = ControlBase})

local function wipe(container, keepLayouts)
	for _, child in ipairs(container:GetChildren()) do
		local keep = keepLayouts and (child:IsA("UILayout") or child:IsA("UIPadding"))
		if not keep then
			child:Destroy()
		end
	end
end

local function glyph(name, size, color, parent, position)
	return Google.CreateIcon(name, size, color, parent, position or {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5)
	})
end

local function shortText(label, value)
	if label then
		label.Text = tostring(value or "")
	end
end

local function softCard(parent, height, title)
	local frame = create("Frame", {
		Name = title or "Card",
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = Google.Theme.CardAlt,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = parent
	})
	round(frame, 14)
	local stroke = outline(frame, Google.Theme.Border, 1, 0)
	return frame, stroke
end

local function bindCardPress(card, target, callback)
	if type(callback) ~= "function" then
		return
	end
	target.Active = true
	bind(card.Connections, target.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			callback(card)
		end
	end)
end

local function paintLua(code)
	local function esc(value)
		return tostring(value or ""):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
	end
	local words = {
		"and", "break", "do", "else", "elseif", "end", "false", "for", "function", "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while"
	}
	local lines = {}
	local index = 1
	for line in tostring(code or ""):gmatch("([^\n]*)\n?") do
		if line == "" and index > #tostring(code or "") then
			break
		end
		local clean = esc(line)
		local trimmed = clean:match("^%s*(.*)$") or clean
		if trimmed:sub(1, 2) == "--" then
			clean = '<font color="#6A9955">' .. clean .. '</font>'
		else
			for _, word in ipairs(words) do
				clean = clean:gsub("(%f[%a_])" .. word .. "(%f[^%a_])", '<font color="#C586C0">' .. word .. '</font>')
			end
		end
		lines[#lines + 1] = '<font color="#858585">' .. tostring(#lines + 1) .. '</font>  ' .. clean
		index += #line + 1
	end
	return table.concat(lines, "\n")
end

local function refreshGridSize(grid)
	local rows = math.ceil(math.max(#grid.Items, 1) / grid.Columns)
	local canvas = rows * grid.CellHeight + math.max(rows - 1, 0) * grid.Gap + 12
	grid.Scroller.CanvasSize = UDim2.fromOffset(0, canvas)
	if grid.AutoHeight then
		local visibleRows = math.clamp(rows, 1, grid.MaxRows)
		local height = visibleRows * grid.CellHeight + math.max(visibleRows - 1, 0) * grid.Gap + 14
		grid.Instance.Size = UDim2.new(1, 0, 0, math.max(70, height))
		grid.Scroller.Size = UDim2.new(1, 0, 1, 0)
		grid:RefreshSection()
	end
end

local function gridCellWidth(grid)
	local gap = grid.Gap * math.max(grid.Columns - 1, 0)
	return UDim2.new(1 / grid.Columns, -(gap / grid.Columns), 0, grid.CellHeight)
end

function gridMethods:RefreshSection()
	return ControlBase.RefreshSection(self)
end

function gridMethods:Refresh()
	self.Layout.CellSize = gridCellWidth(self)
	self.Layout.CellPadding = UDim2.fromOffset(self.Gap, self.Gap)
	refreshGridSize(self)
	return self
end

function gridMethods:Clear()
	for _, item in ipairs(self.Items) do
		if item.Instance then
			item.Instance:Destroy()
		end
	end
	table.clear(self.Items)
	self:Refresh()
	return self
end

function gridMethods:SetColumns(value)
	self.Columns = math.max(1, tonumber(value) or self.Columns)
	return self:Refresh()
end

function gridMethods:SetGap(value)
	self.Gap = math.max(0, tonumber(value) or self.Gap)
	return self:Refresh()
end

function gridMethods:SetCellHeight(value)
	self.CellHeight = math.max(44, tonumber(value) or self.CellHeight)
	return self:Refresh()
end

function gridMethods:Destroy()
	disconnectAll(self.Connections)
	for _, item in ipairs(self.Items) do
		if item.Destroy then
			item:Destroy()
		end
	end
	if self.Instance then
		self.Instance:Destroy()
	end
	if self.Section then
		self.Section:Refresh()
	end
end

local function makeCard(parent, config, grid)
	config = config or {}
	local card = {
		Connections = {},
		ParentGrid = grid,
		Title = config.Title or config.Name or "Card",
		Subtitle = config.Subtitle or config.Description or "",
		Badges = config.Badges or config.Tags or {}
	}
	local height = grid and grid.CellHeight or (config.Height or 86)
	local frame, stroke = softCard(parent, height, "Card")
	card.Instance = frame
	card.Stroke = stroke
	local press = create("TextButton", {
		Name = "Hitbox",
		Text = "",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Parent = frame
	})
	card.Hitbox = press
	local x = 14
	if config.Icon then
		local iconWrap = create("Frame", {
			Name = "IconWrap",
			Size = UDim2.fromOffset(34, 34),
			Position = UDim2.fromOffset(12, 14),
			BackgroundColor3 = Google.Theme.PrimarySoft,
			BorderSizePixel = 0,
			Parent = frame
		})
		round(iconWrap, 10)
		card.IconWrap = iconWrap
		card.Icon = glyph(config.Icon, 18, Google.Theme.Primary, iconWrap)
		x = 56
	elseif config.Image then
		local image = create("ImageLabel", {
			Name = "Image",
			Size = UDim2.fromOffset(36, 36),
			Position = UDim2.fromOffset(12, 13),
			BackgroundTransparency = 1,
			Image = ResolveImageSource(config.Image),
			ScaleType = Enum.ScaleType.Crop,
			Parent = frame
		})
		round(image, 9)
		card.Image = image
		x = 58
	end
	local title = create("TextLabel", {
		Name = "Title",
		Text = card.Title,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Google.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -(x + 14), 0, 18),
		Position = UDim2.fromOffset(x, config.Subtitle and 14 or 22),
		Parent = frame
	})
	card.TitleLabel = title
	local subtitle = create("TextLabel", {
		Name = "Subtitle",
		Text = card.Subtitle,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Google.Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -(x + 14), 0, 18),
		Position = UDim2.fromOffset(x, 34),
		Visible = card.Subtitle ~= "",
		Parent = frame
	})
	card.SubtitleLabel = subtitle
	local badgeRow = create("Frame", {
		Name = "Badges",
		Size = UDim2.new(1, -(x + 14), 0, 18),
		Position = UDim2.fromOffset(x, height - 25),
		BackgroundTransparency = 1,
		Visible = #card.Badges > 0,
		Parent = frame
	})
	card.BadgeRow = badgeRow
	local badgeLayout = create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = badgeRow
	})
	card.BadgeLayout = badgeLayout
	function card:DrawBadges()
		wipe(self.BadgeRow, true)
		for _, badgeText in ipairs(self.Badges) do
			local badge = create("TextLabel", {
				Name = "Badge",
				Text = tostring(badgeText),
				Font = Enum.Font.GothamBold,
				TextSize = 10,
				TextColor3 = Google.Theme.Primary,
				BackgroundColor3 = Google.Theme.PrimarySoft,
				BorderSizePixel = 0,
				Size = UDim2.fromOffset(math.clamp(#tostring(badgeText) * 6 + 16, 38, 100), 18),
				Parent = self.BadgeRow
			})
			roundFull(badge)
		end
		self.BadgeRow.Visible = #self.Badges > 0
	end
	function card:SetTitle(value)
		self.Title = tostring(value or "")
		shortText(self.TitleLabel, self.Title)
		return self
	end
	function card:SetSubtitle(value)
		self.Subtitle = tostring(value or "")
		shortText(self.SubtitleLabel, self.Subtitle)
		self.SubtitleLabel.Visible = self.Subtitle ~= ""
		return self
	end
	function card:SetBadges(values)
		self.Badges = values or {}
		self:DrawBadges()
		return self
	end
	function card:ApplyTheme()
		self.Instance.BackgroundColor3 = Google.Theme.CardAlt
		self.Instance.BackgroundTransparency = 0
		self.Stroke.Color = Google.Theme.Border
		self.Stroke.Transparency = 1
		self.Stroke.Thickness = 0
		self.TitleLabel.TextColor3 = Google.Theme.Text
		self.SubtitleLabel.TextColor3 = Google.Theme.Muted
		if self.IconWrap then self.IconWrap.BackgroundColor3 = Google.Theme.PrimarySoft end
		if self.Icon then Google.SetIconColor(self.Icon, Google.Theme.Primary) end
		self:DrawBadges()
	end
	function card:Destroy()
		disconnectAll(self.Connections)
		if self.Instance then self.Instance:Destroy() end
		if self.ParentGrid then
			for i, item in ipairs(self.ParentGrid.Items) do
				if item == self then
					table.remove(self.ParentGrid.Items, i)
					break
				end
			end
			self.ParentGrid:Refresh()
		end
	end
	bindCardPress(card, press, config.Callback or config.OnClick)
	card:DrawBadges()
	if grid then
		table.insert(grid.Items, card)
		grid:Refresh()
	end
	return card
end

local function makeImageCard(parent, config, grid)
	config = config or {}
	local card = {
		Connections = {},
		ParentGrid = grid,
		Title = config.Title or config.Name or "Image Card"
	}
	local height = grid and grid.CellHeight or (config.Height or 158)
	local frame, stroke = softCard(parent, height, "ImageCard")
	card.Instance = frame
	card.Stroke = stroke
	local hitbox = create("TextButton", {
		Name = "Hitbox",
		Text = "",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Parent = frame
	})
	card.Hitbox = hitbox
	local titleHeight = config.HideTitle and 0 or 30
	local image = create("ImageLabel", {
		Name = "Image",
		Size = UDim2.new(1, -14, 1, -(titleHeight + 14)),
		Position = UDim2.fromOffset(7, 7),
		BackgroundColor3 = Google.Theme.Input,
		BorderSizePixel = 0,
		Image = ResolveImageSource(config.Image or config.ImageId or config.Source or config.AssetId),
		ScaleType = ResolveImageScaleType(config.ScaleType or "Crop"),
		ClipsDescendants = true,
		Parent = frame
	})
	round(image, 10)
	card.Image = image
	card.ImageStroke = outline(image, Google.Theme.Border, 0.86, 1)
	local title = create("TextLabel", {
		Name = "Title",
		Text = card.Title,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = Google.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 0, 20),
		Position = UDim2.new(0, 8, 1, -25),
		Visible = not config.HideTitle,
		Parent = frame
	})
	card.TitleLabel = title
	function card:SetTitle(value)
		self.Title = tostring(value or "")
		shortText(self.TitleLabel, self.Title)
		return self
	end
	function card:SetImage(value)
		local source = ResolveImageSource(value)
		self.Image.Image = source
		local thumb = ResolveImageThumbnail(value)
		if thumb ~= "" then
			task.delay(0.8, function()
				if self.Image and self.Image.Parent and not self.Image.IsLoaded then
					self.Image.Image = thumb
				end
			end)
		end
		return self
	end
	function card:ApplyTheme()
		self.Instance.BackgroundColor3 = Google.Theme.CardAlt
		self.Instance.BackgroundTransparency = 0
		self.Stroke.Color = Google.Theme.Border
		self.Stroke.Transparency = 1
		self.Stroke.Thickness = 0
		self.Image.BackgroundColor3 = Google.Theme.Input
		self.ImageStroke.Color = Google.Theme.Border
		self.ImageStroke.Transparency = 0.86
		self.ImageStroke.Thickness = 1
		self.TitleLabel.TextColor3 = Google.Theme.Text
	end
	function card:Destroy()
		disconnectAll(self.Connections)
		if self.Instance then self.Instance:Destroy() end
		if self.ParentGrid then
			for i, item in ipairs(self.ParentGrid.Items) do
				if item == self then
					table.remove(self.ParentGrid.Items, i)
					break
				end
			end
			self.ParentGrid:Refresh()
		end
	end
	bindCardPress(card, hitbox, config.Callback or config.OnClick)
	card:SetImage(config.Image or config.ImageId or config.Source or config.AssetId or "")
	if grid then
		table.insert(grid.Items, card)
		grid:Refresh()
	end
	return card
end

function Section:CreateGrid(config)
	config = config or {}
	local height = tonumber(config.Height) or tonumber(config.CellHeight) or 140
	local grid = Control(self, height, "Grid")
	setmetatable(grid, gridMethods)
	grid.Columns = math.max(1, tonumber(config.Columns) or 3)
	grid.Gap = math.max(0, tonumber(config.Gap or config.Spacing) or 10)
	grid.CellHeight = math.max(44, tonumber(config.CellHeight) or 140)
	grid.MaxRows = math.max(1, tonumber(config.MaxRows) or 3)
	grid.AutoHeight = config.AutoHeight ~= false
	grid.Items = {}
	local scroller = create("ScrollingFrame", {
		Name = "Scroller",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, 0),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Google.Theme.BorderStrong,
		Parent = grid.Instance
	})
	grid.Scroller = scroller
	pad(scroller, 2, 6, 2, 8)
	local layout = create("UIGridLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		CellSize = gridCellWidth(grid),
		CellPadding = UDim2.fromOffset(grid.Gap, grid.Gap),
		Parent = scroller
	})
	grid.Layout = layout
	bind(grid.Connections, layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		refreshGridSize(grid)
	end)
	function grid:ApplyTheme()
		self.Scroller.ScrollBarImageColor3 = Google.Theme.BorderStrong
		for _, item in ipairs(self.Items) do
			if item.ApplyTheme then item:ApplyTheme() end
		end
	end
	grid:Refresh()
	return grid
end

function Section:AddGrid(config)
	return self:CreateGrid(config)
end

function gridMethods:CreateCard(config)
	return makeCard(self.Scroller, config, self)
end

function gridMethods:AddCard(config)
	return self:CreateCard(config)
end

function gridMethods:CreateImageCard(config)
	return makeImageCard(self.Scroller, config, self)
end

function gridMethods:AddImageCard(config)
	return self:CreateImageCard(config)
end

function Section:CreateCard(config)
	config = config or {}
	local control = Control(self, tonumber(config.Height) or 86, "CardControl")
	local card = makeCard(control.Instance, config, nil)
	control.Card = card
	control.Instance.BackgroundTransparency = 1
	function control:ApplyTheme()
		if self.Card and self.Card.ApplyTheme then self.Card:ApplyTheme() end
	end
	function control:SetTitle(value) self.Card:SetTitle(value) return self end
	function control:SetSubtitle(value) self.Card:SetSubtitle(value) return self end
	function control:SetBadges(values) self.Card:SetBadges(values) return self end
	return control
end

function Section:AddCard(config)
	return self:CreateCard(config)
end

function Section:CreateImageCard(config)
	config = config or {}
	local control = Control(self, tonumber(config.Height) or 158, "ImageCardControl")
	local card = makeImageCard(control.Instance, config, nil)
	control.Card = card
	control.Instance.BackgroundTransparency = 1
	function control:ApplyTheme()
		if self.Card and self.Card.ApplyTheme then self.Card:ApplyTheme() end
	end
	function control:SetTitle(value) self.Card:SetTitle(value) return self end
	function control:SetImage(value) self.Card:SetImage(value) return self end
	return control
end

function Section:AddImageCard(config)
	return self:CreateImageCard(config)
end

function Section:CreateSearchBox(config)
	config = config or {}
	local control = Control(self, 42, "SearchBox")
	control.Query = config.Default or ""
	control.OnSearch = config.OnSearch or config.Callback or function() end
	local frame, stroke = softCard(control.Instance, 40, "SearchBoxFrame")
	frame.Size = UDim2.new(1, 0, 0, 40)
	control.BoxFrame = frame
	control.Stroke = stroke
	control.Icon = glyph(config.Icon or "search", 17, Google.Theme.Muted, frame, {
		Size = UDim2.fromOffset(17, 17),
		Position = UDim2.fromOffset(13, 12)
	})
	local input = create("TextBox", {
		Name = "Input",
		Text = control.Query,
		PlaceholderText = config.Placeholder or "Search...",
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = Google.Theme.Text,
		PlaceholderColor3 = Google.Theme.Subtle,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -74, 1, 0),
		Position = UDim2.fromOffset(38, 0),
		Parent = frame
	})
	control.Input = input
	local clear = create("TextButton", {
		Name = "Clear",
		Text = "",
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, -34, 0.5, -14),
		BackgroundColor3 = Google.Theme.Hover,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Visible = control.Query ~= "",
		Parent = frame
	})
	round(clear, 8)
	control.ClearButton = clear
	control.ClearIcon = glyph("x", 13, Google.Theme.Muted, clear)
	function control:Search()
		self.Query = self.Input.Text
		self.OnSearch(self.Query)
		return self
	end
	function control:Set(value, silent)
		self.Query = tostring(value or "")
		self.Input.Text = self.Query
		self.ClearButton.Visible = self.Query ~= ""
		if not silent then self:Search() end
		return self
	end
	function control:Get()
		return self.Input.Text
	end
	function control:ApplyTheme()
		self.BoxFrame.BackgroundColor3 = Google.Theme.CardAlt
		self.Stroke.Color = Google.Theme.Border
		self.Input.TextColor3 = Google.Theme.Text
		self.Input.PlaceholderColor3 = Google.Theme.Subtle
		self.ClearButton.BackgroundColor3 = Google.Theme.Hover
		Google.SetIconColor(self.Icon, Google.Theme.Muted)
		Google.SetIconColor(self.ClearIcon, Google.Theme.Muted)
	end
	bind(control.Connections, input:GetPropertyChangedSignal("Text"), function()
		control.Query = input.Text
		clear.Visible = input.Text ~= ""
	end)
	bind(control.Connections, input.FocusLost, function(enterPressed)
		if enterPressed then control:Search() end
	end)
	bind(control.Connections, clear.MouseButton1Click, function()
		control:Set("", true)
		input:CaptureFocus()
	end)
	return control
end

function Section:AddSearchBox(config)
	return self:CreateSearchBox(config)
end

function Section:CreateFilterBar(config)
	config = config or {}
	local filters = config.Filters or {}
	local control = Control(self, tonumber(config.Height) or 42, "FilterBar")
	control.Values = {}
	control.Chips = {}
	control.ChipStrokes = {}
	control.Callback = config.Callback or function() end
	local scroller = create("ScrollingFrame", {
		Name = "Scroller",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, 0),
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 0,
		Parent = control.Instance
	})
	control.Scroller = scroller
	local layout = create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, tonumber(config.Gap) or 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = scroller
	})
	control.Layout = layout
	local function styleChip(chip, active)
		chip.BackgroundColor3 = active and Google.Theme.PrimarySoft or Google.Theme.CardAlt
		chip.TextColor3 = active and Google.Theme.Primary or Google.Theme.Muted
		local stroke = control.ChipStrokes[chip.Name]
		if stroke then
			stroke.Color = active and Google.Theme.Primary or Google.Theme.Border
			stroke.Transparency = active and 0.18 or 0.08
		end
	end
	local function updateCanvas()
		scroller.CanvasSize = UDim2.fromOffset(layout.AbsoluteContentSize.X + 6, 0)
	end
	function control:Get()
		return self.Values
	end
	function control:Set(name, value, silent)
		self.Values[name] = value and true or false
		local chip = self.Chips[name]
		if chip then styleChip(chip, self.Values[name]) end
		if not silent then self.Callback(self.Values) end
		return self
	end
	function control:ApplyTheme()
		for name, chip in pairs(self.Chips) do
			styleChip(chip, self.Values[name])
		end
	end
	for _, item in ipairs(filters) do
		local name = item.Name or item[1]
		local active = item.Default == true or item.Value == true
		control.Values[name] = active
		local chip = create("TextButton", {
			Name = tostring(name),
			Text = tostring(name),
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			AutoButtonColor = false,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(math.clamp(#tostring(name) * 7 + 26, 58, 160), 30),
			Parent = scroller
		})
		roundFull(chip)
		control.ChipStrokes[name] = outline(chip, Google.Theme.Border, 0.84, 1)
		control.Chips[name] = chip
		styleChip(chip, active)
		bind(control.Connections, chip.MouseButton1Click, function()
			control:Set(name, not control.Values[name])
		end)
	end
	bind(control.Connections, layout:GetPropertyChangedSignal("AbsoluteContentSize"), updateCanvas)
	updateCanvas()
	return control
end

function Section:AddFilterBar(config)
	return self:CreateFilterBar(config)
end

function Section:CreateKeyValueList(config)
	config = config or {}
	local items = config.Items or {}
	local rowHeight = tonumber(config.RowHeight) or 30
	local control = Control(self, math.max(rowHeight, #items * rowHeight), "KeyValueList")
	control.Items = items
	control.RowHeight = rowHeight
	local holder = create("Frame", {
		Name = "Rows",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = control.Instance
	})
	control.Holder = holder
	local layout = create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = holder
	})
	control.Layout = layout
	function control:Draw()
		wipe(self.Holder, true)
		for _, row in ipairs(self.Items) do
			local key = row.Key or row.Name or row[1]
			local value = row.Value or row.Text or row[2]
			local line, stroke = softCard(self.Holder, self.RowHeight, "Row")
			line.BackgroundTransparency = 0
			stroke.Transparency = 0.18
			create("TextLabel", {
				Name = "Key",
				Text = tostring(key or ""),
				Font = Enum.Font.Gotham,
				TextSize = 12,
				TextColor3 = Google.Theme.Muted,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				BackgroundTransparency = 1,
				Size = UDim2.new(0.45, -12, 1, 0),
				Position = UDim2.fromOffset(12, 0),
				Parent = line
			})
			create("TextLabel", {
				Name = "Value",
				Text = tostring(value or ""),
				Font = Enum.Font.GothamBold,
				TextSize = 12,
				TextColor3 = Google.Theme.Text,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextTruncate = Enum.TextTruncate.AtEnd,
				BackgroundTransparency = 1,
				Size = UDim2.new(0.55, -12, 1, 0),
				Position = UDim2.new(0.45, 0, 0, 0),
				Parent = line
			})
		end
		local total = #self.Items * self.RowHeight + math.max(#self.Items - 1, 0) * 6
		self.Instance.Size = UDim2.new(1, 0, 0, math.max(self.RowHeight, total))
		self:RefreshSection()
	end
	function control:SetItems(values)
		self.Items = values or {}
		self:Draw()
		return self
	end
	function control:ApplyTheme()
		self:Draw()
	end
	control:Draw()
	return control
end

function Section:AddKeyValueList(config)
	return self:CreateKeyValueList(config)
end

function Section:CreateCodeBlock(config)
	config = config or {}
	local maxHeight = tonumber(config.MaxHeight or config.Height) or 180
	local control = Control(self, maxHeight, "CodeBlock")
	control.Code = config.Code or config.Text or ""
	control.Language = string.lower(tostring(config.Language or "text"))
	control.Wrap = config.Wrap ~= false and config.LineWrap ~= false
	local frame, stroke = softCard(control.Instance, maxHeight, "CodeFrame")
	control.Frame = frame
	control.Stroke = stroke
	local header = create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = Google.Theme.Card,
		BorderSizePixel = 0,
		Parent = frame
	})
	control.Header = header
	create("TextLabel", {
		Name = "Language",
		Text = string.upper(control.Language),
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = Google.Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -100, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		Parent = header
	})
	if config.CopyButton then
		local copy = create("TextButton", {
			Name = "Copy",
			Text = "Copy",
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			TextColor3 = Google.Theme.Primary,
			BackgroundColor3 = Google.Theme.PrimarySoft,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Size = UDim2.fromOffset(58, 22),
			Position = UDim2.new(1, -68, 0, 4),
			Parent = header
		})
		round(copy, 7)
		control.CopyButton = copy
		bind(control.Connections, copy.MouseButton1Click, function()
			if type(setclipboard) == "function" then
				setclipboard(control.Code)
			end
		end)
	end
	local scroller = create("ScrollingFrame", {
		Name = "Scroller",
		Size = UDim2.new(1, -12, 1, -36),
		Position = UDim2.fromOffset(6, 32),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, 0),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Google.Theme.BorderStrong,
		Parent = frame
	})
	control.Scroller = scroller
	local label = create("TextLabel", {
		Name = "Code",
		Text = (control.Language == "lua" or control.Language == "luau") and paintLua(control.Code) or tostring(control.Code),
		RichText = control.Language == "lua" or control.Language == "luau",
		Font = Enum.Font.Code,
		TextSize = 13,
		TextColor3 = Google.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = control.Wrap,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = scroller
	})
	control.Label = label
	function control:RefreshCanvas()
		self.Scroller.CanvasSize = UDim2.fromOffset(0, self.Label.AbsoluteSize.Y + 12)
	end
	function control:SetCode(value)
		self.Code = tostring(value or "")
		self.Label.Text = (self.Language == "lua" or self.Language == "luau") and paintLua(self.Code) or self.Code
		task.defer(function() self:RefreshCanvas() end)
		return self
	end
	function control:Get()
		return self.Code
	end
	function control:ApplyTheme()
		self.Frame.BackgroundColor3 = Google.Theme.CardAlt
		self.Header.BackgroundColor3 = Google.Theme.Card
		self.Stroke.Color = Google.Theme.Border
		self.Label.TextColor3 = Google.Theme.Text
		self.Scroller.ScrollBarImageColor3 = Google.Theme.BorderStrong
		if self.CopyButton then
			self.CopyButton.BackgroundColor3 = Google.Theme.PrimarySoft
			self.CopyButton.TextColor3 = Google.Theme.Primary
		end
	end
	bind(control.Connections, label:GetPropertyChangedSignal("AbsoluteSize"), function()
		control:RefreshCanvas()
	end)
	control:SetCode(control.Code)
	return control
end

function Section:AddCodeBlock(config)
	return self:CreateCodeBlock(config)
end

function Section:CreateEmptyState(config)
	config = config or {}
	local height = tonumber(config.Height) or 148
	local control = Control(self, height, "EmptyState")
	local frame, stroke = softCard(control.Instance, height, "EmptyStateFrame")
	control.Frame = frame
	control.Stroke = stroke
	local iconWrap = create("Frame", {
		Name = "IconWrap",
		Size = UDim2.fromOffset(38, 38),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 18),
		BackgroundColor3 = Google.Theme.PrimarySoft,
		BorderSizePixel = 0,
		Parent = frame
	})
	round(iconWrap, 12)
	control.IconWrap = iconWrap
	control.Icon = glyph(config.Icon or "search", 20, Google.Theme.Primary, iconWrap)
	control.TitleLabel = create("TextLabel", {
		Name = "Title",
		Text = config.Title or "Nothing here",
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = Google.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Center,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -24, 0, 22),
		Position = UDim2.fromOffset(12, 62),
		Parent = frame
	})
	control.TextLabel = create("TextLabel", {
		Name = "Text",
		Text = config.Text or config.Description or "",
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Google.Theme.Muted,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -34, 0, 34),
		Position = UDim2.fromOffset(17, 86),
		Parent = frame
	})
	if config.ActionText then
		local action = create("TextButton", {
			Name = "Action",
			Text = config.ActionText,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextColor3 = Color3.new(1, 1, 1),
			BackgroundColor3 = Google.Theme.Primary,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Size = UDim2.fromOffset(112, 28),
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -12),
			Parent = frame
		})
		round(action, 8)
		control.ActionButton = action
		bind(control.Connections, action.MouseButton1Click, function()
			if type(config.Callback) == "function" then config.Callback() end
		end)
	end
	function control:ApplyTheme()
		self.Frame.BackgroundColor3 = Google.Theme.CardAlt
		self.Stroke.Color = Google.Theme.Border
		self.IconWrap.BackgroundColor3 = Google.Theme.PrimarySoft
		Google.SetIconColor(self.Icon, Google.Theme.Primary)
		self.TitleLabel.TextColor3 = Google.Theme.Text
		self.TextLabel.TextColor3 = Google.Theme.Muted
		if self.ActionButton then self.ActionButton.BackgroundColor3 = Google.Theme.Primary end
	end
	return control
end

function Section:AddEmptyState(config)
	return self:CreateEmptyState(config)
end

function Section:CreateLoading(config)
	config = config or {}
	local control = Control(self, tonumber(config.Height) or 42, "Loading")
	control.Running = true
	local frame, stroke = softCard(control.Instance, 40, "LoadingFrame")
	control.Frame = frame
	control.Stroke = stroke
	local dot = create("TextLabel", {
		Name = "Spinner",
		Text = "•",
		Font = Enum.Font.GothamBold,
		TextSize = 26,
		TextColor3 = Google.Theme.Primary,
		TextXAlignment = Enum.TextXAlignment.Center,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(34, 40),
		Position = UDim2.fromOffset(8, -2),
		Parent = frame
	})
	control.Spinner = dot
	control.TextLabel = create("TextLabel", {
		Name = "Text",
		Text = config.Text or "Loading...",
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Google.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -58, 1, 0),
		Position = UDim2.fromOffset(46, 0),
		Parent = frame
	})
	function control:SetText(value)
		shortText(self.TextLabel, value)
		return self
	end
	function control:Hide()
		self.Instance.Visible = false
		return self
	end
	function control:Show()
		self.Instance.Visible = true
		return self
	end
	function control:ApplyTheme()
		self.Frame.BackgroundColor3 = Google.Theme.CardAlt
		self.Stroke.Color = Google.Theme.Border
		self.TextLabel.TextColor3 = Google.Theme.Text
		self.Spinner.TextColor3 = Google.Theme.Primary
	end
	local marks = {"•", "••", "•••", "••"}
	task.spawn(function()
		local i = 1
		while control.Running and control.Instance and control.Instance.Parent do
			control.Spinner.Text = marks[i]
			i = (i % #marks) + 1
			task.wait(0.28)
		end
	end)
	local destroy = control.Destroy
	function control:Destroy()
		self.Running = false
		destroy(self)
	end
	return control
end

function Section:AddLoading(config)
	return self:CreateLoading(config)
end

function Section:CreateTable(config)
	config = config or {}
	local columns = config.Columns or {}
	local rows = config.Rows or {}
	local rowHeight = tonumber(config.RowHeight) or 32
	local height = tonumber(config.Height) or math.clamp((#rows + 1) * rowHeight + 8, 72, tonumber(config.MaxHeight) or 220)
	local control = Control(self, height, "Table")
	control.Columns = columns
	control.Rows = rows
	control.RowHeight = rowHeight
	control.OnRowClick = config.OnRowClick or config.Callback
	local frame, stroke = softCard(control.Instance, height, "TableFrame")
	control.Frame = frame
	control.Stroke = stroke
	local header = create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, -8, 0, rowHeight),
		Position = UDim2.fromOffset(4, 4),
		BackgroundColor3 = Google.Theme.Card,
		BorderSizePixel = 0,
		Parent = frame
	})
	round(header, 8)
	control.Header = header
	local body = create("ScrollingFrame", {
		Name = "Body",
		Size = UDim2.new(1, -8, 1, -(rowHeight + 12)),
		Position = UDim2.fromOffset(4, rowHeight + 8),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, 0),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Google.Theme.BorderStrong,
		Parent = frame
	})
	control.Body = body
	local bodyLayout = create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
		Parent = body
	})
	control.BodyLayout = bodyLayout
	local function cell(parent, text, index, count, bold)
		return create("TextLabel", {
			Name = "Cell" .. tostring(index),
			Text = tostring(text or ""),
			Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = bold and Google.Theme.Text or Google.Theme.Muted,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			BackgroundTransparency = 1,
			Size = UDim2.new(1 / math.max(count, 1), -8, 1, 0),
			Position = UDim2.new((index - 1) / math.max(count, 1), 8, 0, 0),
			Parent = parent
		})
	end
	function control:Draw()
		for _, child in ipairs(self.Header:GetChildren()) do
			if not child:IsA("UICorner") and not child:IsA("UIStroke") and not child:IsA("UIGradient") then
				child:Destroy()
			end
		end
		wipe(self.Body, true)
		local count = math.max(#self.Columns, 1)
		for i, name in ipairs(self.Columns) do
			cell(self.Header, name, i, count, true)
		end
		for rowIndex, row in ipairs(self.Rows) do
			local line = create("TextButton", {
				Name = "Row" .. tostring(rowIndex),
				Text = "",
				AutoButtonColor = false,
				Size = UDim2.new(1, -2, 0, self.RowHeight),
				BackgroundColor3 = Google.Theme.CardAlt,
				BorderSizePixel = 0,
				Parent = self.Body
			})
			round(line, 8)
			outline(line, Google.Theme.Border, 0.9, 1)
			for i = 1, count do
				cell(line, row[i], i, count, false)
			end
			if type(self.OnRowClick) == "function" then
				bind(self.Connections, line.MouseButton1Click, function()
					self.OnRowClick(row, rowIndex)
				end)
			end
		end
		self.Body.CanvasSize = UDim2.fromOffset(0, (#self.Rows * (self.RowHeight + 4)) + 8)
	end
	function control:SetRows(values)
		self.Rows = values or {}
		self:Draw()
		return self
	end
	function control:AddRow(value)
		table.insert(self.Rows, value)
		self:Draw()
		return self
	end
	function control:Clear()
		table.clear(self.Rows)
		self:Draw()
		return self
	end
	function control:ApplyTheme()
		self.Frame.BackgroundColor3 = Google.Theme.CardAlt
		self.Stroke.Color = Google.Theme.Border
		self.Header.BackgroundColor3 = Google.Theme.Card
		self.Body.ScrollBarImageColor3 = Google.Theme.BorderStrong
		self:Draw()
	end
	bind(control.Connections, bodyLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		control.Body.CanvasSize = UDim2.fromOffset(0, control.BodyLayout.AbsoluteContentSize.Y + 8)
	end)
	control:Draw()
	return control
end

function Section:AddTable(config)
	return self:CreateTable(config)
end

function Tab:CreateGrid(config) return self:GetStandaloneSection():CreateGrid(config) end
function Tab:AddGrid(config) return self:CreateGrid(config) end
function Tab:CreateCard(config) return self:GetStandaloneSection():CreateCard(config) end
function Tab:AddCard(config) return self:CreateCard(config) end
function Tab:CreateImageCard(config) return self:GetStandaloneSection():CreateImageCard(config) end
function Tab:AddImageCard(config) return self:CreateImageCard(config) end
function Tab:CreateSearchBox(config) return self:GetStandaloneSection():CreateSearchBox(config) end
function Tab:AddSearchBox(config) return self:CreateSearchBox(config) end
function Tab:CreateFilterBar(config) return self:GetStandaloneSection():CreateFilterBar(config) end
function Tab:AddFilterBar(config) return self:CreateFilterBar(config) end
function Tab:CreateKeyValueList(config) return self:GetStandaloneSection():CreateKeyValueList(config) end
function Tab:AddKeyValueList(config) return self:CreateKeyValueList(config) end
function Tab:CreateCodeBlock(config) return self:GetStandaloneSection():CreateCodeBlock(config) end
function Tab:AddCodeBlock(config) return self:CreateCodeBlock(config) end
function Tab:CreateEmptyState(config) return self:GetStandaloneSection():CreateEmptyState(config) end
function Tab:AddEmptyState(config) return self:CreateEmptyState(config) end
function Tab:CreateLoading(config) return self:GetStandaloneSection():CreateLoading(config) end
function Tab:AddLoading(config) return self:CreateLoading(config) end
function Tab:CreateTable(config) return self:GetStandaloneSection():CreateTable(config) end
function Tab:AddTable(config) return self:CreateTable(config) end


local function filesReady()
	if type(writefile) ~= "function" then return false, "File functions unavailable" end
	if type(readfile) ~= "function" then return false, "File functions unavailable" end
	if type(isfile) ~= "function" then return false, "File functions unavailable" end
	if type(makefolder) ~= "function" then return false, "File functions unavailable" end
	if type(isfolder) ~= "function" then return false, "File functions unavailable" end
	if type(delfile) ~= "function" then return false, "File functions unavailable" end
	return true
end

local function cleanConfigName(name)
	name = tostring(name or "default")
	name = name:gsub("[%z\1-\31]", "")
	name = name:gsub("[\\/:*?\"<>|]", "_")
	name = name:gsub("^%s+", ""):gsub("%s+$", "")
	if name == "" then
		name = "default"
	end
	return name
end

local function ensureConfigFolder(path)
	local ok, message = filesReady()
	if not ok then
		return false, message
	end
	local current = ""
	for part in tostring(path or ""):gmatch("[^/\\]+") do
		current = current == "" and part or (current .. "/" .. part)
		if not isfolder(current) then
			local made, err = pcall(makefolder, current)
			if not made then
				return false, tostring(err)
			end
		end
	end
	return true
end

local function copyArray(value)
	local result = {}
	if type(value) == "table" then
		for i, item in ipairs(value) do
			result[i] = item
		end
	end
	return result
end

local function colorToData(color)
	if typeof(color) == "Color3" then
		return {
			R = math.floor(color.R * 255),
			G = math.floor(color.G * 255),
			B = math.floor(color.B * 255)
		}
	end
	if type(color) == "table" and color.R and color.G and color.B then
		return {
			R = math.clamp(math.floor(tonumber(color.R) or 0), 0, 255),
			G = math.clamp(math.floor(tonumber(color.G) or 0), 0, 255),
			B = math.clamp(math.floor(tonumber(color.B) or 0), 0, 255)
		}
	end
	return {R = 255, G = 255, B = 255}
end

local function colorFromData(value, fallback)
	if typeof(value) == "Color3" then
		return value
	end
	if type(value) == "table" and value.R and value.G and value.B then
		return Color3.fromRGB(
			math.clamp(math.floor(tonumber(value.R) or 0), 0, 255),
			math.clamp(math.floor(tonumber(value.G) or 0), 0, 255),
			math.clamp(math.floor(tonumber(value.B) or 0), 0, 255)
		)
	end
	return fallback or Color3.fromRGB(255, 255, 255)
end

local function keyToData(value, mode)
	local key = value
	if typeof(value) == "EnumItem" then
		key = value.Name
	elseif type(value) == "table" then
		key = value.Key or value.KeyCode or value.Name or value[1]
	else
		key = tostring(value or "Unknown")
	end
	return {Key = key, Mode = mode or "Toggle"}
end

local function keyFromData(value, control)
	local mode = control and control.Mode or "Toggle"
	local key = value
	if type(value) == "table" then
		key = value.Key or value.KeyCode or value.Name or value[1]
		mode = value.Mode or mode
	end
	if control then
		control.Mode = mode or control.Mode
	end
	if typeof(key) == "EnumItem" then
		return key
	end
	key = tostring(key or "Unknown")
	return Enum.KeyCode[key] or Enum.KeyCode.Unknown
end

local function safeValue(value)
	local valueType = typeof(value)
	if valueType == "Color3" then
		return colorToData(value)
	end
	if valueType == "EnumItem" then
		return value.Name
	end
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, item in pairs(value) do
		result[key] = safeValue(item)
	end
	return result
end

local function readJson(path)
	local ok, message = filesReady()
	if not ok then
		return nil, message
	end
	if not isfile(path) then
		return nil, "File not found"
	end
	local readOk, contents = pcall(readfile, path)
	if not readOk then
		return nil, tostring(contents)
	end
	local decodedOk, decoded = pcall(function()
		return HttpService:JSONDecode(contents)
	end)
	if not decodedOk then
		return nil, tostring(decoded)
	end
	return decoded
end

local function writeJson(path, value)
	local ok, message = filesReady()
	if not ok then
		return false, message
	end
	local encodedOk, encoded = pcall(function()
		return HttpService:JSONEncode(value)
	end)
	if not encodedOk then
		return false, tostring(encoded)
	end
	local writeOk, err = pcall(writefile, path, encoded)
	if not writeOk then
		return false, tostring(err)
	end
	return true
end

local function normalizeStoredValue(kind, value, control)
	if kind == "Toggle" then
		return value and true or false
	elseif kind == "Slider" then
		return tonumber(value) or 0
	elseif kind == "Textbox" then
		return tostring(value or "")
	elseif kind == "Dropdown" then
		if control and control.Multi then
			return copyArray(value)
		end
		return value == nil and nil or tostring(value)
	elseif kind == "Keybind" then
		return keyToData(value, control and control.Mode)
	elseif kind == "ColorPicker" then
		return colorToData(value)
	end
	return safeValue(value)
end

local function normalizeLoadedValue(kind, value, control)
	if kind == "Toggle" then
		return value and true or false
	elseif kind == "Slider" then
		return tonumber(value) or (control and control.Value) or 0
	elseif kind == "Textbox" then
		return tostring(value or "")
	elseif kind == "Dropdown" then
		if control and control.Multi then
			return copyArray(value)
		end
		return value
	elseif kind == "Keybind" then
		return keyFromData(value, control)
	elseif kind == "ColorPicker" then
		return colorFromData(value, control and control.Value)
	end
	return value
end

local function autoSaveFlags()
	local manager = Google.ConfigManager
	if manager and manager.AutoSave then
		manager:Save()
	end
end

local function registerFlag(control, config, kind)
	if not control or type(config) ~= "table" then
		return control
	end
	local flag = config.Flag
	if not flag then
		return control
	end
	flag = tostring(flag)
	control.Flag = flag
	control.CallbackOnLoad = config.CallbackOnLoad == true
	Google.Options[flag] = control

	local previousGet = control.Get
	local previousSet = control.Set
	local callback = control.Callback
	if type(callback) == "function" then
		control.Callback = function(...)
			if control.LoadingFromConfig and not control.CallbackOnLoad then
				return
			end
			return callback(...)
		end
	end
	local setCallback = control.SetCallback
	function control:SetCallback(fn)
		if setCallback then
			setCallback(self, fn)
		else
			self.RawCallback = type(fn) == "function" and fn or function() end
			self.Callback = self.RawCallback
		end
		local nextCallback = self.Callback or function() end
		self.Callback = function(...)
			if self.LoadingFromConfig and not self.CallbackOnLoad then
				return
			end
			return nextCallback(...)
		end
		return self
	end

	function control:Get()
		local value
		if previousGet then
			value = previousGet(self)
		else
			value = self.Value
		end
		return normalizeStoredValue(kind, value, self)
	end

	function control:Set(value, fromConfig)
		local loadedValue = normalizeLoadedValue(kind, value, self)
		local wasLoading = self.LoadingFromConfig
		local wasDisabled = self.Disabled
		self.LoadingFromConfig = fromConfig and true or false
		if fromConfig and wasDisabled then
			self.Disabled = false
		end
		if previousSet then
			previousSet(self, loadedValue)
		else
			self.Value = loadedValue
		end
		if fromConfig and wasDisabled then
			self.Disabled = wasDisabled
			if self.SetDisabled then
				self:SetDisabled(true)
			end
		end
		self.LoadingFromConfig = wasLoading
		Google.Flags[flag] = self:Get()
		if not fromConfig then
			autoSaveFlags()
		end
		return self
	end

	if Google.Flags[flag] ~= nil then
		control:Set(Google.Flags[flag], true)
	else
		Google.Flags[flag] = control:Get()
	end
	return control
end

function Google:SetFlag(flag, value, fromConfig)
	flag = tostring(flag)
	local option = Google.Options[flag]
	if option and type(option.Set) == "function" then
		option:Set(value, fromConfig)
		Google.Flags[flag] = type(option.Get) == "function" and option:Get() or safeValue(value)
	else
		Google.Flags[flag] = safeValue(value)
		if not fromConfig then
			autoSaveFlags()
		end
	end
	return Google.Flags[flag]
end

function Google:GetFlag(flag, default)
	local value = Google.Flags[tostring(flag)]
	if value == nil then
		return default
	end
	return value
end

function Google:CreateConfigManager(config)
	config = config or {}
	local manager = {}
	manager.Folder = config.Folder or "GoogleUI/Configs"
	manager.Extension = config.Extension or ".json"
	manager.AutoSave = config.AutoSave == true
	manager.CurrentConfig = config.Default or config.Name or "default"
	manager.Ignore = {}
	manager.AutoloadFile = manager.Folder .. "/__autoload.txt"
	manager.IndexFile = manager.Folder .. "/__configs" .. manager.Extension

	function manager:Path(name)
		return self.Folder .. "/" .. cleanConfigName(name or self.CurrentConfig or "default") .. self.Extension
	end

	function manager:SetIgnore(flags)
		self.Ignore = {}
		if type(flags) == "table" then
			for key, value in pairs(flags) do
				if type(key) == "number" then
					self.Ignore[tostring(value)] = true
				elseif value then
					self.Ignore[tostring(key)] = true
				end
			end
		end
		return self
	end

	function manager:ReadIndex()
		local ok, message = filesReady()
		if not ok then
			return nil, message
		end
		ensureConfigFolder(self.Folder)
		if not isfile(self.IndexFile) then
			return {}
		end
		local data, err = readJson(self.IndexFile)
		if type(data) ~= "table" then
			return {}, err
		end
		return data
	end

	function manager:WriteIndex(list)
		local ok, message = ensureConfigFolder(self.Folder)
		if not ok then
			return false, message
		end
		return writeJson(self.IndexFile, list or {})
	end

	function manager:AddToIndex(name)
		name = cleanConfigName(name)
		local list = self:ReadIndex()
		if type(list) ~= "table" then
			list = {}
		end
		for _, item in ipairs(list) do
			if item == name then
				return self:WriteIndex(list)
			end
		end
		table.insert(list, name)
		table.sort(list)
		return self:WriteIndex(list)
	end

	function manager:RemoveFromIndex(name)
		name = cleanConfigName(name)
		local list = self:ReadIndex()
		if type(list) ~= "table" then
			list = {}
		end
		for index = #list, 1, -1 do
			if list[index] == name then
				table.remove(list, index)
			end
		end
		return self:WriteIndex(list)
	end

	function manager:Save(name)
		name = cleanConfigName(name or self.CurrentConfig or "default")
		local ok, message = ensureConfigFolder(self.Folder)
		if not ok then
			return false, message
		end
		local data = {}
		for flag, option in pairs(Google.Options) do
			if not self.Ignore[flag] and option and type(option.Get) == "function" then
				data[flag] = safeValue(option:Get())
			end
		end
		local saved, err = writeJson(self:Path(name), data)
		if not saved then
			return false, err
		end
		self.CurrentConfig = name
		self:AddToIndex(name)
		return true, self:Path(name)
	end

	function manager:Load(name)
		name = cleanConfigName(name or self.CurrentConfig or "default")
		local ok, message = ensureConfigFolder(self.Folder)
		if not ok then
			return false, message
		end
		local data, err = readJson(self:Path(name))
		if type(data) ~= "table" then
			return false, err or "Invalid config"
		end
		for flag, value in pairs(data) do
			if not self.Ignore[flag] then
				Google:SetFlag(flag, value, true)
			end
		end
		self.CurrentConfig = name
		self:AddToIndex(name)
		return true, data
	end

	function manager:Delete(name)
		name = cleanConfigName(name or self.CurrentConfig or "default")
		local ok, message = ensureConfigFolder(self.Folder)
		if not ok then
			return false, message
		end
		local path = self:Path(name)
		if isfile(path) then
			local deleted, err = pcall(delfile, path)
			if not deleted then
				return false, tostring(err)
			end
		end
		self:RemoveFromIndex(name)
		return true
	end

	function manager:SetAutoload(name)
		name = cleanConfigName(name or self.CurrentConfig or "default")
		local ok, message = ensureConfigFolder(self.Folder)
		if not ok then
			return false, message
		end
		local saved, err = pcall(writefile, self.AutoloadFile, name)
		if not saved then
			return false, tostring(err)
		end
		return true, name
	end

	function manager:ClearAutoload()
		local ok, message = ensureConfigFolder(self.Folder)
		if not ok then
			return false, message
		end
		if isfile(self.AutoloadFile) then
			local deleted, err = pcall(delfile, self.AutoloadFile)
			if not deleted then
				return false, tostring(err)
			end
		end
		return true
	end

	function manager:LoadAutoloadConfig()
		local ok, message = ensureConfigFolder(self.Folder)
		if not ok then
			return false, message
		end
		if not isfile(self.AutoloadFile) then
			return false, "No autoload config"
		end
		local readOk, name = pcall(readfile, self.AutoloadFile)
		if not readOk then
			return false, tostring(name)
		end
		name = cleanConfigName(name)
		return self:Load(name)
	end

	function manager:GetConfigList()
		local ok, message = ensureConfigFolder(self.Folder)
		if not ok then
			return false, message
		end
		local found = {}
		local list = self:ReadIndex()
		if type(list) == "table" then
			for _, item in ipairs(list) do
				found[cleanConfigName(item)] = true
			end
		end
		if type(listfiles) == "function" then
			local scanned = pcall(function()
				for _, path in ipairs(listfiles(self.Folder)) do
					local fileName = tostring(path):match("([^/\\]+)$")
					if fileName and fileName:sub(-#self.Extension) == self.Extension and fileName ~= "__configs" .. self.Extension then
						found[fileName:sub(1, #fileName - #self.Extension)] = true
					end
				end
			end)
		end
		local result = {}
		for name in pairs(found) do
			table.insert(result, name)
		end
		table.sort(result)
		self:WriteIndex(result)
		return result
	end

	Google.ConfigManager = manager
	return manager
end

local configCreateToggle = Section.CreateToggle
function Section:CreateToggle(config)
	config = config or {}
	return registerFlag(configCreateToggle(self, config), config, "Toggle")
end

local configCreateSlider = Section.CreateSlider
function Section:CreateSlider(config)
	config = config or {}
	return registerFlag(configCreateSlider(self, config), config, "Slider")
end

local configCreateTextbox = Section.CreateTextbox
function Section:CreateTextbox(config)
	config = config or {}
	return registerFlag(configCreateTextbox(self, config), config, "Textbox")
end

local configCreateDropdown = Section.CreateDropdown
function Section:CreateDropdown(config)
	config = config or {}
	return registerFlag(configCreateDropdown(self, config), config, "Dropdown")
end

local configCreateKeybind = Section.CreateKeybind
function Section:CreateKeybind(config)
	config = config or {}
	return registerFlag(configCreateKeybind(self, config), config, "Keybind")
end

local configCreateColorPicker = Section.CreateColorPicker
function Section:CreateColorPicker(config)
	config = config or {}
	return registerFlag(configCreateColorPicker(self, config), config, "ColorPicker")
end

function Tab:CreateConfigSection(config)
	config = config or {}
	local manager = config.Manager or Google.ConfigManager or Google:CreateConfigManager({})
	local section = self:CreateSection({Name = config.Name or "Configs", Icon = config.Icon or "save"})
	local nameBox = section:CreateTextbox({Name = "Config Name", Placeholder = "default", Default = manager.CurrentConfig or "default", ClearButton = true})
	local list = section:CreateDropdown({Name = "Saved Configs", Placeholder = "Select config", Options = manager:GetConfigList() or {}, Callback = function(value)
		if value then
			nameBox:Set(value)
		end
	end})
	local api = {Section = section, Input = nameBox, Dropdown = list, Manager = manager}
	function api:GetName()
		return cleanConfigName(nameBox:Get())
	end
	function api:Refresh()
		local configs = manager:GetConfigList()
		if type(configs) ~= "table" then
			configs = {}
		end
		if list.SetOptions then
			list:SetOptions(configs)
		elseif list.Refresh then
			list:Refresh(configs)
		end
		return self
	end
	section:CreateButton({Name = "Save", Icon = "save", Callback = function()
		manager:Save(api:GetName())
		api:Refresh()
	end})
	section:CreateButton({Name = "Load", Icon = "download", Callback = function()
		manager:Load(api:GetName())
	end})
	section:CreateButton({Name = "Delete", Icon = "trash", Variant = "Danger", Callback = function()
		manager:Delete(api:GetName())
		api:Refresh()
	end})
	section:CreateButton({Name = "Set Autoload", Icon = "check", Callback = function()
		manager:SetAutoload(api:GetName())
	end})
	section:CreateButton({Name = "Clear Autoload", Icon = "x", Variant = "Secondary", Callback = function()
		manager:ClearAutoload()
	end})
	section:CreateButton({Name = "Load Autoload", Icon = "refresh-cw", Callback = function()
		manager:LoadAutoloadConfig()
	end})
	section:CreateButton({Name = "Refresh List", Icon = "refresh-cw", Variant = "Secondary", Callback = function()
		api:Refresh()
	end})
	api:Refresh()
	return api
end

return Google
