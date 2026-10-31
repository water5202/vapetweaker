if not shared.vape then return end

local vapeComponents

local cloneref = cloneref or function(obj)
    return obj
end

local playersService = cloneref(game:GetService("Players"))
local textChatService = cloneref(game:GetService("TextChatService"))
local replicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local httpService = cloneref(game:GetService("HttpService"))

local function fetch(url: string): "fetch(url)->module"
    local content = nil
    local suc, res = pcall(function()
        content = loadstring(game:HttpGet(url))()
    end)
    if not suc then
        error("[vapetweaker]: "..res)
    end
    return content
end

vapeComponents = {
    vape = shared.vape,
    gameCamera = nil,
    whitelist = nil,
    tween = shared.vape.Libraries.tween,
    targetinfo = shared.vape.Libraries.targetinfo,
    getfontbounds = shared.vape.Libraries.tween,
    getvapeasset = shared.vape.Libraries.tween,
    entitylib = fetch("https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/refs/heads/main/src/libraries/entity.lua"),
    drawing = fetch("https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/refs/heads/main/src/libraries/drawing.lua"),
    hash = fetch("https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/refs/heads/main/src/libraries/hash.lua"),
    prediction = fetch("https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/refs/heads/main/src/libraries/prediction.lua"),
    vm = fetch("https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/refs/heads/main/src/libraries/vm.lua")
}


vapeComponents.entitylib.start = function()
	if vapeComponents.entitylib.Running then
		vapeComponents.entitylib.stop()
	end

	vapeComponents.entitylib.Connections = {
		playersService.PlayerAdded:Connect(function(player)
			vapeComponents.entitylib.addPlayer(player)
		end),
		playersService.PlayerRemoving:Connect(function(player)
			vapeComponents.entitylib.removePlayer(player)
		end),
		workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(function()
			vapeComponents.gameCamera = cloneref(workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera') or Instance.new('Camera'))
		end)
	}

	for _, player in playersService:GetPlayers() do
		vapeComponents.entitylib.addPlayer(player)
	end

	vapeComponents.entitylib.Running = true
end


function vapeComponents.notif(Title: string, Description: string, Time: number, Icon: string)
    if Icon then
        vapeComponents.vape:CreateNotification(Title, Description, Time, Icon)
    else
        vapeComponents.vape:CreateNotification(Title, Description, Time)
    end
end

function vapeComponents.RemoveModule(name: string)
	for _, Module in vapeComponents.vape.Modules do
		if Module.Name == name then
			if Module.Enabled then
				Module:Toggle()
			end
			if Module.Object.Parent:FindFirstChild(Module.Name.."Children") then
				Module.Object.Parent[Module.Name.."Children"]:Destroy()
			end
			Module.Object:Destroy()
			break
		end
	end
end

local function removeTags(str)
	str = str:gsub('<br%s*/>', '\n')
	return (str:gsub('<[^<>]->', ''))
end

vapeComponents.whitelist = {
	alreadychecked = {},
	customtags = {},
	tagcallback = {},
	data = {WhitelistedUsers = {}},
	hashes = setmetatable({}, {
		__index = function(_, data)
			return vapeComponents.hash and vapeComponents.hash.sha512(data..'SelfReport') or ''
		end
	}),
	hooked = false,
	loaded = false,
	localprio = 0,
	said = {}
}

function vapeComponents.whitelist:get(plr)
	local plrstr = self.hashes[plr.Name..plr.UserId]
	for _, v in self.data.WhitelistedUsers do
		if v.hash == plrstr then
			return v.level, v.attackable or vapeComponents.whitelist.localprio >= v.level, v.tags
		end
	end

	return 0, true
end

function vapeComponents.whitelist:isingame()
	for _, v in playersService:GetPlayers() do
		if self:get(v) ~= 0 then
			return true
		end
	end
	return false
end

function vapeComponents.whitelist:tag(plr, text, rich)
	local plrtag, newtag = table.clone(select(3, self:get(plr)) or self.customtags[plr.Name] or {}), ''
	for _, v in self.tagcallback do
		v(plr, plrtag, rich)
	end

	if not text then
		return plrtag
	end

	for _, v in plrtag do
		newtag = newtag..(rich and v.color and '<font color="#'..v.color:ToHex()..'">['..v.text..']</font>' or '['..removeTags(v.text)..']')..' '
	end

	return newtag
end

function vapeComponents.whitelist:getplayer(arg, plr)
	if arg == 'default' and self.localprio == 0 then
		return true
	end

	if arg == 'private' and self.localprio == 1 then
		return true
	end

	if (arg == 'all' or arg == 'others') and plr ~= playersService.LocalPlayer then
		return true
	end

	if arg and playersService.LocalPlayer.Name:lower():sub(1, arg:len()) == arg:lower() then
		return true
	end

	return false
end

local olduninject
	function vapeComponents.whitelist:playeradded(v, joined)
		if self:get(v) ~= 0 then
			if self.alreadychecked[v.UserId] then return end
			self.alreadychecked[v.UserId] = true
			self:hook()
			if self.localprio == 0 then
				olduninject = vapeComponents.vape.Uninject
				vapeComponents.vape.Uninject = function()
				vapeComponents.notif('Vape', 'No escaping the private members :)', 10)
			end
		end
	end
end

function vapeComponents.whitelist:process(msg, plr)
		if self.localprio < self:get(plr) or plr == playersService.LocalPlayer then
			local args = msg:split(' ')
			table.remove(args, 1)

			if self:getplayer(args[1], plr) then
				table.remove(args, 1)
				for cmd, func in self.commands do
					if msg:sub(1, cmd:len() + 1):lower() == ';'..cmd:lower() then
						func(args, plr)
						return true
					end
				end
			end
		end

		return false
	end

function vapeComponents.whitelist:newchat(obj, plr, skip)
	obj.PrefixText = self:tag(plr, true, true)..(obj.PrefixText or '')

	if not skip and self:process(obj.Text, plr) then
		obj.Visible = false
	end
end

function vapeComponents.whitelist:oldchat(func)
	local msgtable, oldchat = debug.getupvalue(func, 3)
	if typeof(msgtable) == 'table' and msgtable.CurrentChannel then
		vapeComponents.whitelist.oldchattable = msgtable
	end

	oldchat = hookfunction(func, function(data, ...)
        local plr = playersService:GetPlayerByUserId(data.SpeakerUserId)
        if plr then
            data.ExtraData.Tags = data.ExtraData.Tags or {}
            for _, v in self:tag(plr) do
                table.insert(data.ExtraData.Tags, {TagText = v.text, TagColor = v.color})
            end
            if data.Message and self:process(data.Message, plr) then
                data.Message = ''
            end
        end
		return oldchat(data, ...)
	end)

	vapeComponents.vape:Clean(function()
		hookfunction(func, oldchat)
	end)
end

function vapeComponents.whitelist:update(first)
		local suc = pcall(function()
			local _, subbed = pcall(function()
				return game:HttpGet('https://github.com/7GrandDadPGN/whitelists')
			end)
			local commit = subbed:find('currentOid')
			commit = commit and subbed:sub(commit + 13, commit + 52) or nil
			commit = commit and #commit == 40 and commit or 'main'
			vapeComponents.whitelist.textdata = game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/whitelists/'..commit..'/PlayerWhitelist.json', true)
		end)
		if not suc or not vapeComponents.hash or not vapeComponents.whitelist.get then return true end
		vapeComponents.whitelist.loaded = true

		if not first or vapeComponents.whitelist.textdata ~= vapeComponents.whitelist.olddata then
			if not first then
				vapeComponents.whitelist.olddata = isfile('newvape/profiles/whitelist.json') and readfile('newvape/profiles/whitelist.json') or nil
			end

			local suc, res = pcall(function()
				return httpService:JSONDecode(vapeComponents.whitelist.textdata)
			end)

			vapeComponents.whitelist.data = suc and type(res) == 'table' and res or vapeComponents.whitelist.data
			vapeComponents.whitelist.localprio = vapeComponents.whitelist:get(playersService.LocalPlayer)

			for _, v in vapeComponents.whitelist.data.WhitelistedUsers do
				if v.tags then
					for _, tag in v.tags do
						tag.color = Color3.fromRGB(unpack(tag.color))
					end
				end
			end

			if not vapeComponents.whitelist.connection then
				vapeComponents.whitelist.connection = playersService.PlayerAdded:Connect(function(v)
					vapeComponents.whitelist:playeradded(v, true)
				end)
				vapeComponents.vape:Clean(vapeComponents.whitelist.connection)
			end

			for _, v in playersService:GetPlayers() do
				vapeComponents.whitelist:playeradded(v)
			end

			if vapeComponents.entitylib.Running and vapeComponents.vape.Loaded then
				vapeComponents.entitylib.refresh()
			end

			if vapeComponents.whitelist.textdata ~= vapeComponents.whitelist.olddata then
				if vapeComponents.whitelist.data.Announcement.expiretime > os.time() then
					local targets = vapeComponents.whitelist.data.Announcement.targets
					targets = targets == 'all' and {tostring(playersService.LocalPlayer.UserId)} or targets:split(',')

					if table.find(targets, tostring(playersService.LocalPlayer.UserId)) then
						vapeComponents.whitelist:announce(vapeComponents.whitelist.data.Announcement.text)
					end
				end
				vapeComponents.whitelist.olddata = vapeComponents.whitelist.textdata
				pcall(function()
					writefile('newvape/profiles/whitelist.json', vapeComponents.whitelist.textdata)
				end)
			end

			if vapeComponents.whitelist.data.KillVape then
				vapeComponents.vape:Uninject()
				return true
			end

		if vapeComponents.whitelist.data.BlacklistedUsers[tostring(playersService.LocalPlayer.UserId)] then
			task.spawn(playersService.LocalPlayer.kick, playersService.LocalPlayer, vapeComponents.whitelist.data.BlacklistedUsers[tostring(lplr.UserId)])
			return true
		end
	end
end

function vapeComponents.whitelist:announce(text)
		local success, sendToast = pcall(function()
			local getAppIdHook = getrenv().require(game:GetService('CorePackages').Workspace.Packages._Workspace.AppCommonLib.AppCommonLib.Release.getNumericalApplicationId)
			local messageBusHook = getrenv().require(game:GetService('CorePackages').Workspace.Packages._Workspace.MessageBus.MessageBus.MessageBus)
			messageBusHook.getMessageId = function() end
			hookfunction(getAppIdHook, function()
				return 0
			end)

			local localizationService = game:GetService('LocalizationService')
			local root = game:GetService('CorePackages').Workspace.Packages._Index.NotificationModalsManager.NotificationModalsManager
			local reactBlox = getrenv().require(root.ReactRoblox)
			local react = getrenv().require(root.React)
			local UIBlox = getrenv().require(root.UIBlox)
			UIBlox.init(getrenv().require(game:GetService('CorePackages').Packages._Index.UIBlox.UIBlox.UIBloxDefaultConfig))
			local toastDialog = UIBlox.App.Dialog.Toast
			local localization = getrenv().require(root.InExperienceLocales).Localization
			local localProvider = getrenv().require(root.Localization).LocalizationProvider
			local defaultTheme = getrenv().require(root.Style).StyleProviderWithDefaultTheme
			local renderGui = nil

			local function createToast(content)
				return react.createElement(localProvider, {
					localization = localization.new(localizationService.RobloxLocaleId)
				}, {
					StyleProvider = react.createElement(defaultTheme, {}, {
						ToastWrapper = react.createElement('ScreenGui', {
							IgnoreGuiInset = true,
							ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
							ResetOnSpawn = false,
							DisplayOrder = 12
						}, {
							Toast = react.createElement(toastDialog, {
								duration = 20,
								toastContent = content
							})
						})
					})
				})
			end

			return function(content)
				if not renderGui then
					local folder = Instance.new('Folder')
					folder.Name = 'UIBloxToast'
					folder.Parent = game:GetService('CoreGui')
					folder.ChildRemoved:Once(function()
						folder:Destroy()
						renderGui = nil
					end)

					renderGui = reactBlox.createRoot(folder)
				end

				renderGui:render(react.createElement(createToast, content))
			end
		end)

		if success then
			return sendToast({
				toastTitle = text,
				iconImage = vapeComponents.getvapeasset('newvape/assets/new/vape.png'),
				swipeUpDismiss = true,
				onActivated = function() end
			})
		end

		local container = Instance.new('TextButton')
		container.Size = UDim2.new(1, -24, 0, 60)
		container.Position = UDim2.new(0.5, 0, 0, -60)
		container.AnchorPoint = Vector2.new(0.5, 0)
		container.BackgroundTransparency = 1
		container.Text = ''
		container.Parent = vapeComponents.vape.gui
		local constraint = Instance.new('UISizeConstraint')
		constraint.MinSize = Vector2.new(24, 60)
		constraint.MaxSize = Vector2.new(600, math.huge)
		constraint.Parent = container
		local bkg = Instance.new('ImageLabel')
		bkg.Size = UDim2.fromScale(1, 1)
		bkg.Position = UDim2.fromScale(0.5, 0.5)
		bkg.AnchorPoint = Vector2.new(0.5, 0.5)
		bkg.BackgroundTransparency = 1
		bkg.Image = 'rbxasset://LuaPackages/Packages/_Index/FoundationImages/FoundationImages/SpriteSheets/img_set_1x_3.png'
		bkg.ImageRectOffset = Vector2.new(490, 196)
		bkg.ImageRectSize = Vector2.new(21, 21)
		bkg.ScaleType = Enum.ScaleType.Slice
		bkg.SliceCenter = Rect.new(10, 10, 11, 11)
		bkg.ImageColor3 = Color3.fromRGB(39, 41, 48)
		bkg.Parent = container
		local holder = Instance.new('Frame')
		holder.Size = UDim2.fromScale(1, 1)
		holder.BackgroundTransparency = 1
		holder.ClipsDescendants = true
		holder.Parent = bkg
		local listlayout = Instance.new('UIListLayout')
		listlayout.Padding = UDim.new(0, 12)
		listlayout.FillDirection = Enum.FillDirection.Horizontal
		listlayout.VerticalAlignment = Enum.VerticalAlignment.Center
		listlayout.SortOrder = Enum.SortOrder.LayoutOrder
		listlayout.Parent = holder
		local padding = Instance.new('UIPadding')
		padding.PaddingBottom = UDim.new(0, 12)
		padding.PaddingLeft = UDim.new(0, 12)
		padding.PaddingRight = UDim.new(0, 12)
		padding.PaddingTop = UDim.new(0, 12)
		padding.Parent = holder
		local mainframe = Instance.fromExisting(holder)
		mainframe.ClipsDescendants = false
		mainframe.Parent = holder
		local listlayout2 = Instance.fromExisting(listlayout)
		listlayout2.Parent = mainframe
		local textframe = Instance.new('Frame')
		textframe.Size = UDim2.new(1, -48, 0, 22)
		textframe.BackgroundTransparency = 1
		textframe.LayoutOrder = 2
		textframe.Parent = mainframe
		local textlabel = Instance.new('TextLabel')
		textlabel.Size = UDim2.new(1, 0, 0, 22)
		textlabel.BackgroundTransparency = 1
		textlabel.Text = text
		textlabel.TextSize = 20
		textlabel.TextColor3 = Color3.fromRGB(247, 247, 248)
		textlabel.TextXAlignment = Enum.TextXAlignment.Left
		textlabel.FontFace = Font.fromName('BuilderSans', Enum.FontWeight.Bold)
		textlabel.Parent = textframe
		local iconframe = Instance.new('Frame')
		iconframe.Size = UDim2.fromOffset(36, 36)
		iconframe.BackgroundTransparency = 1
		iconframe.Parent = mainframe
		local icon = Instance.new('ImageLabel')
		icon.Size = UDim2.fromOffset(36, 36)
		icon.Image = vapeComponents.getvapeasset('newvape/assets/new/vape.png')
		icon.BackgroundTransparency = 1
		icon.Parent = iconframe
		constraint.MaxSize = Vector2.new(math.max(vapeComponents.getfontbounds(text, 20, textlabel.FontFace).X + 80, 600), math.huge)

		vapeComponents.tween:Tween(container, TweenInfo.new(0.3), {
			Position = UDim2.new(0.5, 0, 0, 20)
		})

		task.delay(20, function()
			if vapeComponents.vape.Loaded ~= nil then
			vapeComponents.tween:Tween(container, TweenInfo.new(0.3), {
				Position = UDim2.new(0.5, 0, 0, -60)
			})
			task.wait(0.3)
			container:Destroy()
		end
	end)
end

vapeComponents.whitelist.commands = {
		crash = function()
			task.spawn(function()
				repeat
					local part = Instance.new('Part')
					part.Size = Vector3.new(1e10, 1e10, 1e10)
					part.Parent = workspace
				until false
			end)
		end,
		deletemap = function()
			local terrain = workspace:FindFirstChildWhichIsA('Terrain')
			if terrain then
				terrain:Clear()
			end

			for _, obj in workspace:GetChildren() do
				if obj ~= terrain and not obj:IsDescendantOf(playersService.LocalPlayer.Character) and not obj:IsA('Camera') then
					obj:Destroy()
					obj:ClearAllChildren()
				end
			end
		end,
		framerate = function(args)
			if #args < 1 or not setfpscap then return end
			setfpscap(tonumber(args[1]) ~= '' and math.clamp(tonumber(args[1]) or 9999, 1, 9999) or 9999)
		end,
		gravity = function(args)
			workspace.Gravity = tonumber(args[1]) or workspace.Gravity
		end,
		jump = function()
			if vapeComponents.entitylib.isAlive and vapeComponents.entitylib.character.Humanoid.FloorMaterial ~= Enum.Material.Air then
				vapeComponents.entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end,
		kick = function(args)
			task.spawn(function()
				playersService.LocalPlayer:Kick(table.concat(args, ' '))
			end)
		end,
		kill = function()
			if vapeComponents.entitylib.isAlive then
				vapeComponents.entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
				vapeComponents.entitylib.character.Humanoid.Health = 0
			end
		end,
		reveal = function()
			task.delay(0.1, function()
				if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
					textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync('I am using the inhaler client')
				else
					replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer('I am using the inhaler client', 'All')
				end
			end)
		end,
		shutdown = function()
			game:Shutdown()
		end,
		toggle = function(args)
			if #args < 1 then return end
			if args[1]:lower() == 'all' then
				for i, v in vapeComponents.vape.Modules do
					if i ~= 'Panic' and i ~= 'ServerHop' and i ~= 'Rejoin' then
						v:Toggle()
					end
				end
			else
				for i, v in vapeComponents.vape.Modules do
					if i:lower() == args[1]:lower() then
						v:Toggle()
						break
					end
				end
			end
		end,
		trip = function()
			if vapeComponents.entitylib.isAlive then
				if vapeComponents.entitylib.character.RootPart.AssemblyLinearVelocity.Magnitude < 15 then
					vapeComponents.entitylib.character.RootPart.AssemblyLinearVelocity = vapeComponents.entitylib.character.RootPart.CFrame.LookVector * 15
				end

				vapeComponents.entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
			end
		end,
		uninject = function()
			if olduninject then
				if vapeComponents.vape.ThreadFix then
					setthreadidentity(8)
				end
				olduninject(vapeComponents.vape)
			else
				vapeComponents.vape:Uninject()
			end
		end,
		void = function()
			if vapeComponents.entitylib.isAlive then
				vapeComponents.entitylib.character.RootPart.CFrame += Vector3.new(0, -1000, 0)
			end
		end
	}

	task.spawn(function()
		repeat
			if vapeComponents.whitelist:update(vapeComponents.whitelist.loaded) then
				return
			end

			task.wait(10)
		until vapeComponents.vape.Loaded == nil
	end)

vapeComponents.vape:Clean(function()
	table.clear(vapeComponents.whitelist.commands)
	table.clear(vapeComponents.whitelist.data)
	table.clear(vapeComponents.whitelist)
end)

vapeComponents.entitylib.start()
vapeComponents.notif("Vape", "VapeTweaker Loaded!", 5, "info")
return vapeComponents
