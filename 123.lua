--[[
    ExpaLib - Библиотека для создания GUI
    Основана на структуре "Expensive GUI" (https://github.com/Burstgalaxy/hub/blob/main/123.lua)
    Автор адаптации: AI Ассистент
]]

local ExpaLib = {}
ExpaLib.__index = ExpaLib

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage") -- Для примера ChestDupe Help

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local G2L_Internal = {} -- Внутреннее хранилище элементов, если понадобится

-- Основные настройки
local DEFAULT_ICON_MODULE = "rbxassetid://136482807431952"
local DEFAULT_ICON_USER_AVATAR = "rbxassetid://0" -- Загрузится позже
local DEFAULT_ICON_HELP = "http://www.roblox.com/asset/?id=18754976792"
local SOUND_TOGGLE_ON = "rbxassetid://17208361335"
local SOUND_TOGGLE_OFF = "rbxassetid://17208372272"
local CHECKMARK_ICON = "rbxassetid://126547299874610" -- Для toggle

-- [[ Хелперы и внутренние функции ]]

local function createNotification(notificationsContainer, title, message, messageType, accentColor)
    if not notificationsContainer then return end

    local notificationFrame = Instance.new("Frame")
    notificationFrame.Name = "NotificationItem"
    notificationFrame.Parent = notificationsContainer
    notificationFrame.BackgroundColor3 = Color3.fromRGB(17, 18, 34) -- Темный фон уведомления
    notificationFrame.BorderSizePixel = 0
    notificationFrame.Size = UDim2.new(0, 265, 0, 74)
    notificationFrame.BackgroundTransparency = 1 -- Начнем с невидимого

    local corner = Instance.new("UICorner", notificationFrame)
    corner.CornerRadius = UDim.new(0, 11)

    local icon = Instance.new("ImageLabel", notificationFrame)
    icon.Name = "Icon"
    icon.BackgroundTransparency = 1
    icon.Position = UDim2.new(0.0415, 0, 0.0862, 0)
    icon.Size = UDim2.new(0, 25, 0, 25)
    icon.Image = DEFAULT_ICON_MODULE
    icon.ImageColor3 = accentColor or Color3.fromRGB(76, 76, 127)

    local titleLabel = Instance.new("TextLabel", notificationFrame)
    titleLabel.Name = "TitleLabel"
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0.178, 0, 0.146, 0)
    titleLabel.Size = UDim2.new(0, 170, 0, 15)
    titleLabel.Font = Enum.Font.Arial
    titleLabel.Text = title or "Notification"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    local messageLabel = Instance.new("TextLabel", notificationFrame)
    messageLabel.Name = "MessageLabel"
    messageLabel.BackgroundTransparency = 1
    messageLabel.Position = UDim2.new(0.178, 0, 0.416, 0)
    messageLabel.Size = UDim2.new(0, 224, 0, 14)
    messageLabel.Font = Enum.Font.Arial
    messageLabel.Text = message or "Something happened."
    messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    messageLabel.TextScaled = true
    messageLabel.TextTransparency = 0.52
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    if messageType == "error" then
        icon.ImageColor3 = Color3.fromRGB(200, 70, 70)
    elseif messageType == "warning" then
         icon.ImageColor3 = Color3.fromRGB(200, 200, 70)
    end

    local tweenInfoShow = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tweenShow = TweenService:Create(notificationFrame, tweenInfoShow, { BackgroundTransparency = 0.1 })
    tweenShow:Play()

    task.delay(3, function()
        if not notificationFrame or not notificationFrame.Parent then return end -- Проверка на случай уничтожения
        local tweenInfoHide = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        local tweenHide = TweenService:Create(notificationFrame, tweenInfoHide, { BackgroundTransparency = 1 })
        tweenHide:Play()
        tweenHide.Completed:Connect(function()
            if notificationFrame and notificationFrame.Parent then notificationFrame:Destroy() end
        end)
    end)
end

local function makeDraggable(guiObject)
    local dragging = false
    local dragInput = nil
    local dragStart = Vector2.zero
    local startPosition = UDim2.fromOffset(0,0)

    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = guiObject.Position
            
            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if connection then connection:Disconnect() end
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(
                startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
            )
        end
    end)
end

local function applyGradient(element, rotation, colorSequence)
    local gradient = Instance.new("UIGradient", element)
    gradient.Rotation = rotation or 34
    gradient.Color = colorSequence or ColorSequence.new{
        ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.245, Color3.fromRGB(238, 238, 239)),
        ColorSequenceKeypoint.new(0.819, Color3.fromRGB(210, 210, 212)),
        ColorSequenceKeypoint.new(1.000, Color3.fromRGB(13, 14, 25))
    }
    return gradient
end

-- [[ Инициализация GUI ]]
function ExpaLib.new(config)
    local self = setmetatable({}, ExpaLib)

    self.config = config or {}
    self.config.Title = self.config.Title or "Expensive Hub" -- Из ASCII-арта
    self.config.Author = self.config.Author or "@uniquadev"   -- Из ASCII-арта
    self.config.OpenKey = self.config.OpenKey or Enum.KeyCode.RightAlt
    self.config.AccentColor = self.config.AccentColor or Color3.fromRGB(77, 77, 128)
    self.config.NavButtonColor = self.config.NavButtonColor or Color3.fromRGB(79, 87, 159)
    self.config.MainBackgroundColor = self.config.MainBackgroundColor or Color3.fromRGB(18, 19, 35)
    self.config.ModuleBackgroundColor = self.config.ModuleBackgroundColor or Color3.fromRGB(26, 27, 40)
    self.config.ModuleContentBackgroundColor = self.config.ModuleContentBackgroundColor or Color3.fromRGB(18, 19, 35)
    self.config.TextColor = self.config.TextColor or Color3.fromRGB(255, 255, 255)
    self.config.MutedTextColor = self.config.MutedTextColor or Color3.fromRGB(180, 180, 180) -- Используем этот для описаний
    self.config.OnlineIndicatorColor = self.config.OnlineIndicatorColor or Color3.fromRGB(65, 154, 126)
    self.config.DefaultGradient = self.config.DefaultGradient or ColorSequence.new{
        ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.245, Color3.fromRGB(238, 238, 239)),
        ColorSequenceKeypoint.new(0.819, Color3.fromRGB(210, 210, 212)),
        ColorSequenceKeypoint.new(1.000, Color3.fromRGB(13, 14, 25))
    }


    self.categories = {}
    self.activeCategoryData = nil -- {button, frame}
    self.mainGuiVisible = true
    self.moduleElements = {} -- для хранения ссылок на элементы управления модулей {category = {module = {option = GuiObject}}}


    G2L_Internal.ScreenGui = Instance.new("ScreenGui", playerGui)
    G2L_Internal.ScreenGui.DisplayOrder = 999999999
    G2L_Internal.ScreenGui.Name = "ExpaLib_ScreenGui"
    G2L_Internal.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    G2L_Internal.ScreenGui.ResetOnSpawn = false

    G2L_Internal.MainFrame = Instance.new("Frame", G2L_Internal.ScreenGui)
    G2L_Internal.MainFrame.Name = "MainFrame"
    G2L_Internal.MainFrame.ZIndex = 999999999
    G2L_Internal.MainFrame.BorderSizePixel = 0
    G2L_Internal.MainFrame.BackgroundColor3 = self.config.MainBackgroundColor
    G2L_Internal.MainFrame.Size = UDim2.new(0, 770, 0, 485)
    G2L_Internal.MainFrame.Position = UDim2.new(0.39291, 0, 0.41878, 0) -- Из оригинального кода
    makeDraggable(G2L_Internal.MainFrame)

    applyGradient(G2L_Internal.MainFrame, 34, self.config.DefaultGradient)
    local mainCorner = Instance.new("UICorner", G2L_Internal.MainFrame)
    mainCorner.CornerRadius = UDim.new(0, 11)
    local mainStroke = Instance.new("UIStroke", G2L_Internal.MainFrame)
    mainStroke.Transparency = 0.95
    mainStroke.Color = Color3.fromRGB(255, 255, 255)

    -- Левая панель
    local leftPanel = G2L_Internal.MainFrame -- Будем добавлять прямо сюда, т.к. элементы позиционируются относительно MainFrame

    G2L_Internal.TitleLabel = Instance.new("TextLabel", leftPanel)
    G2L_Internal.TitleLabel.Name = "TitleLabel"
    G2L_Internal.TextWrapped = true
    G2L_Internal.TitleLabel.BorderSizePixel = 0
    G2L_Internal.TitleLabel.TextScaled = true
    G2L_Internal.TitleLabel.BackgroundTransparency = 1
    G2L_Internal.TitleLabel.TextSize = 14
    G2L_Internal.TitleLabel.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular)
    G2L_Internal.TitleLabel.TextColor3 = self.config.AccentColor
    G2L_Internal.TitleLabel.Size = UDim2.new(0, 170, 0, 27)
    G2L_Internal.TitleLabel.Text = self.config.Title
    G2L_Internal.TitleLabel.Position = UDim2.new(0, 0, 0.07216, 0)
    G2L_Internal.TitleLabel.TextXAlignment = Enum.TextXAlignment.Center -- По центру как в оригинале

    G2L_Internal.NavigationListFrame = Instance.new("Frame", leftPanel)
    G2L_Internal.NavigationListFrame.Name = "NavigationListFrame"
    G2L_Internal.NavigationListFrame.BackgroundTransparency = 1
    G2L_Internal.NavigationListFrame.Size = UDim2.new(0, 141, 0, 304)
    G2L_Internal.NavigationListFrame.Position = UDim2.new(0.02078, 0, 0.20412, 0)

    local navigationLayout = Instance.new("UIListLayout", G2L_Internal.NavigationListFrame)
    navigationLayout.Padding = UDim.new(0, 3)
    navigationLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- Секция пользователя (внизу слева)
    local userSectionDivider = Instance.new("Frame", leftPanel)
    userSectionDivider.Name = "UserSectionDivider"
    userSectionDivider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    userSectionDivider.BackgroundTransparency = 0.95
    userSectionDivider.BorderSizePixel = 0
    userSectionDivider.Size = UDim2.new(0, 171, 0, 1)
    userSectionDivider.Position = UDim2.new(0, 0, 0.86598, 0)

    G2L_Internal.UserAvatarImage = Instance.new("ImageLabel", leftPanel) -- Изменено с Frame на ImageLabel
    G2L_Internal.UserAvatarImage.Name = "UserAvatarImage"
    G2L_Internal.UserAvatarImage.BackgroundColor3 = self.config.AccentColor -- Можно сделать прозрачным, если картинка уже с фоном
    G2L_Internal.UserAvatarImage.Size = UDim2.new(0, 30, 0, 30)
    G2L_Internal.UserAvatarImage.Position = UDim2.new(0.02078, 0, 0.89897, 0)
    G2L_Internal.UserAvatarImage.Image = DEFAULT_ICON_USER_AVATAR
    local avatarCorner = Instance.new("UICorner", G2L_Internal.UserAvatarImage)
    avatarCorner.CornerRadius = UDim.new(0, 19) -- Как в оригинале "ebalo"

    G2L_Internal.OnlineStatusIndicator = Instance.new("Frame", leftPanel)
    G2L_Internal.OnlineStatusIndicator.Name = "OnlineStatusIndicator"
    G2L_Internal.OnlineStatusIndicator.BackgroundColor3 = self.config.OnlineIndicatorColor
    G2L_Internal.OnlineStatusIndicator.Size = UDim2.new(0, 10, 0, 10)
    G2L_Internal.OnlineStatusIndicator.Position = UDim2.new(0.04675, 0, 0.94021, 0)
    local onlineCorner = Instance.new("UICorner", G2L_Internal.OnlineStatusIndicator)
    onlineCorner.CornerRadius = UDim.new(0, 19)
    local onlineStroke = Instance.new("UIStroke", G2L_Internal.OnlineStatusIndicator)
    onlineStroke.Thickness = 2
    onlineStroke.Color = self.config.MainBackgroundColor -- Обводка цветом фона для выделения

    G2L_Internal.UsernameLabel = Instance.new("TextLabel", leftPanel)
    G2L_Internal.UsernameLabel.Name = "UsernameLabel"
    G2L_Internal.UsernameLabel.TextWrapped = true
    G2L_Internal.UsernameLabel.TextXAlignment = Enum.TextXAlignment.Left
    G2L_Internal.UsernameLabel.TextScaled = true
    G2L_Internal.UsernameLabel.BackgroundTransparency = 1
    G2L_Internal.UsernameLabel.TextSize = 14
    G2L_Internal.UsernameLabel.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
    G2L_Internal.UsernameLabel.TextColor3 = self.config.TextColor
    G2L_Internal.UsernameLabel.Size = UDim2.new(0, 96, 0, 15)
    G2L_Internal.UsernameLabel.Text = localPlayer.Name
    G2L_Internal.UsernameLabel.Position = UDim2.new(0.071, 0, 0.895, 0)

    G2L_Internal.DateLabel = Instance.new("TextLabel", leftPanel)
    G2L_Internal.DateLabel.Name = "DateLabel"
    G2L_Internal.DateLabel.TextWrapped = true
    G2L_Internal.DateLabel.TextXAlignment = Enum.TextXAlignment.Left
    G2L_Internal.DateLabel.TextScaled = true
    G2L_Internal.DateLabel.BackgroundTransparency = 1
    G2L_Internal.DateLabel.TextSize = 14
    G2L_Internal.DateLabel.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
    G2L_Internal.DateLabel.TextColor3 = self.config.AccentColor -- Как в оригинале
    G2L_Internal.DateLabel.Size = UDim2.new(0, 96, 0, 15)
    G2L_Internal.DateLabel.Text = os.date("%d.%m.%Y") -- Оригинальный формат гг/мм/гг, меняем
    G2L_Internal.DateLabel.Position = UDim2.new(0.071, 0, 0.92593, 0)

    -- Загрузка аватара
    local success, userId = pcall(function() return Players:GetUserIdFromNameAsync(localPlayer.Name) end)
    if success and userId then
        local thumbType = Enum.ThumbnailType.HeadShot
        local thumbSize = Enum.ThumbnailSize.Size48x48 -- Можно увеличить для лучшего качества
        local content, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
        if isReady then G2L_Internal.UserAvatarImage.Image = content end
    end

    -- Правая панель (Контент)
    local contentPanelDivider = Instance.new("Frame", leftPanel) -- Отдельный разделитель для правой панели
    contentPanelDivider.Name = "ContentPanelDivider"
    contentPanelDivider.BackgroundColor3 = Color3.fromRGB(255,255,255)
    contentPanelDivider.BackgroundTransparency = 0.95
    contentPanelDivider.BorderSizePixel = 0
    contentPanelDivider.Size = UDim2.new(0, 1, 1, 0) -- Высота 100%
    contentPanelDivider.Position = UDim2.new(0.22078, 0, 0, 0) -- Позиция из "prikol"

    G2L_Internal.CurrentCategoryLabel = Instance.new("TextLabel", leftPanel)
    G2L_Internal.CurrentCategoryLabel.Name = "CurrentCategoryLabel"
    G2L_Internal.CurrentCategoryLabel.TextWrapped = true
    G2L_Internal.CurrentCategoryLabel.TextXAlignment = Enum.TextXAlignment.Left
    G2L_Internal.CurrentCategoryLabel.TextScaled = true
    G2L_Internal.CurrentCategoryLabel.BackgroundTransparency = 1
    G2L_Internal.CurrentCategoryLabel.TextSize = 14
    G2L_Internal.CurrentCategoryLabel.FontFace = Font.new("rbxasset://fonts/families/Arial.json")
    G2L_Internal.CurrentCategoryLabel.TextColor3 = self.config.TextColor
    G2L_Internal.CurrentCategoryLabel.Size = UDim2.new(0, 170, 0, 19)
    G2L_Internal.CurrentCategoryLabel.Text = "Welcome" -- Начальное значение
    G2L_Internal.CurrentCategoryLabel.Position = UDim2.new(0.242, 0, 0.039, 0)
    
    local currentCategoryDivider = Instance.new("Frame", leftPanel)
    currentCategoryDivider.Name = "CurrentCategoryDivider"
    currentCategoryDivider.BackgroundColor3 = Color3.fromRGB(255,255,255)
    currentCategoryDivider.BackgroundTransparency = 0.95
    currentCategoryDivider.BorderSizePixel = 0
    currentCategoryDivider.Size = UDim2.new(0, 597, 0, 1)
    currentCategoryDivider.Position = UDim2.new(0.22468, 0, 0.11546, 0)
    
    G2L_Internal.CategoryFramesContainer = Instance.new("Frame", leftPanel)
    G2L_Internal.CategoryFramesContainer.Name = "CategoryFramesContainer"
    G2L_Internal.CategoryFramesContainer.BackgroundTransparency = 1
    G2L_Internal.CategoryFramesContainer.Size = UDim2.new(1 - 0.22468, 0, 1 - 0.11546 - 0.05, 0) -- Динамический размер
    G2L_Internal.CategoryFramesContainer.Position = UDim2.new(0.22468, 0, 0.11546 + 0.01, 0) -- Под разделителем

    G2L_Internal.NotificationsContainer = Instance.new("Frame", G2L_Internal.ScreenGui)
    G2L_Internal.NotificationsContainer.Name = "NotificationsContainer"
    G2L_Internal.NotificationsContainer.BackgroundTransparency = 1
    G2L_Internal.NotificationsContainer.Size = UDim2.new(0.12026, 0, 0.35787, 0)
    G2L_Internal.NotificationsContainer.Position = UDim2.new(0.85414, 0, 0.61506, 0)
    local notificationsLayout = Instance.new("UIListLayout", G2L_Internal.NotificationsContainer)
    notificationsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    notificationsLayout.Padding = UDim.new(0, 6)
    notificationsLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    notificationsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- HUD элементы
    G2L_Internal.WatermarkFrame = nil -- Будут создаваться через API
    G2L_Internal.TargetHudFrame = nil
    G2L_Internal.RenderGifFrame = nil
    G2L_Internal.AmbianceOverlay = nil

    -- Управление видимостью GUI
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == self.config.OpenKey then
            self.mainGuiVisible = not self.mainGuiVisible
            G2L_Internal.MainFrame.Visible = self.mainGuiVisible
            -- Обновление видимости HUD элементов
            if G2L_Internal.WatermarkFrame then G2L_Internal.WatermarkFrame.Visible = self.mainGuiVisible and G2L_Internal.WatermarkFrame:GetAttribute("IsEnabled") end
            if G2L_Internal.TargetHudFrame then G2L_Internal.TargetHudFrame.Visible = self.mainGuiVisible and G2L_Internal.TargetHudFrame:GetAttribute("IsEnabled") end
            if G2L_Internal.RenderGifFrame then G2L_Internal.RenderGifFrame.Visible = self.mainGuiVisible and G2L_Internal.RenderGifFrame:GetAttribute("IsEnabled") end
            if G2L_Internal.AmbianceOverlay then G2L_Internal.AmbianceOverlay.Visible = self.mainGuiVisible and G2L_Internal.AmbianceOverlay:GetAttribute("IsEnabled") end
        end
    end)
    
    self.soundToggleOn = Instance.new("Sound", G2L_Internal.ScreenGui)
    self.soundToggleOn.SoundId = SOUND_TOGGLE_ON
    self.soundToggleOff = Instance.new("Sound", G2L_Internal.ScreenGui)
    self.soundToggleOff.SoundId = SOUND_TOGGLE_OFF

    return self
end

-- [[ API Методы ]]

function ExpaLib:AddCategory(categoryName)
    if self.categories[categoryName] then
        warn("ExpaLib: Категория '" .. categoryName .. "' уже существует.")
        return self.categories[categoryName] -- Возвращаем существующие данные
    end

    local categoryFrame = Instance.new("ScrollingFrame", G2L_Internal.CategoryFramesContainer)
    categoryFrame.Name = categoryName .. "Frame"
    categoryFrame.Visible = false
    categoryFrame.BackgroundTransparency = 1
    categoryFrame.Size = UDim2.new(1, 0, 1, 0)
    categoryFrame.CanvasSize = UDim2.new(0,0,0,0)
    categoryFrame.ScrollBarThickness = 6
    categoryFrame.ScrollBarImageColor3 = self.config.AccentColor
    categoryFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y -- Автоматически подгоняет высоту
    categoryFrame.CanvasPosition = Vector2.new(0,0)
    categoryFrame.ScrollingDirection = Enum.ScrollingDirection.Y


    local categoryLayout = Instance.new("UIGridLayout", categoryFrame) -- Изменено на UIGridLayout для расположения модулей в несколько колонок
    categoryLayout.CellPadding = UDim2.new(0,15,0,15) -- Отступы между модулями
    categoryLayout.CellSize = UDim2.new(0,265,0,100) -- Начальный размер ячейки, высота будет меняться
    categoryLayout.StartCorner = Enum.StartCorner.TopLeft
    categoryLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    categoryLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    categoryLayout.FillDirection = Enum.FillDirection.Horizontal -- Сначала заполняет по горизонтали
    categoryLayout.SortOrder = Enum.SortOrder.LayoutOrder


    local categoryButton = Instance.new("TextButton", G2L_Internal.NavigationListFrame)
    categoryButton.Name = categoryName .. "Button"
    categoryButton.Text = "       " .. categoryName -- Отступы как в оригинале
    categoryButton.Size = UDim2.new(1, 0, 0, 33)
    categoryButton.BackgroundColor3 = self.config.NavButtonColor
    categoryButton.TextColor3 = self.config.TextColor
    categoryButton.Font = Enum.Font.Arial
    categoryButton.TextSize = 14
    categoryButton.BackgroundTransparency = 1 
    categoryButton.TextXAlignment = Enum.TextXAlignment.Left

    local buttonCorner = Instance.new("UICorner", categoryButton)
    buttonCorner.CornerRadius = UDim.new(0, 6)
    local buttonStroke = Instance.new("UIStroke", categoryButton)
    buttonStroke.Color = self.config.NavButtonColor
    buttonStroke.Transparency = 0.74
    buttonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    buttonStroke.Enabled = false

    categoryButton.MouseButton1Click:Connect(function()
        if self.activeCategoryData then
            self.activeCategoryData.frame.Visible = false
            if self.activeCategoryData.button then
                 self.activeCategoryData.button.BackgroundTransparency = 1
                 self.activeCategoryData.button:FindFirstChildOfClass("UIStroke").Enabled = false
            end
        end
        categoryFrame.Visible = true
        self.activeCategoryData = {button = categoryButton, frame = categoryFrame}
        G2L_Internal.CurrentCategoryLabel.Text = categoryName

        categoryButton.BackgroundTransparency = 0.85
        buttonStroke.Enabled = true
    end)
    
    self.categories[categoryName] = {button = categoryButton, frame = categoryFrame, layout = categoryLayout, modules = {}}

    if not self.activeCategoryData then
        categoryButton:Activated()
    end
    
    return self.categories[categoryName]
end

function ExpaLib:_updateModuleContainerHeight(categoryData)
    -- UIGridLayout сам управляет размером Canvas, но мы можем захотеть обновить
    -- родительский ScrollingFrame, если он не AutomaticCanvasSize.Y
    -- В данном случае categoryFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y, так что это не обязательно
end

function ExpaLib:AddModule(categoryName, moduleName, moduleIcon)
    local categoryData = self.categories[categoryName]
    if not categoryData then
        warn("ExpaLib: Категория '" .. categoryName .. "' не найдена.")
        return nil
    end
    if categoryData.modules[moduleName] then
        warn("ExpaLib: Модуль '" .. moduleName .. "' уже существует.")
        return categoryData.modules[moduleName].api
    end

    local moduleFrame = Instance.new("Frame", categoryData.frame)
    moduleFrame.Name = moduleName .. "Module"
    moduleFrame.BackgroundColor3 = self.config.ModuleBackgroundColor
    moduleFrame.Size = UDim2.new(0, 265, 0, 40) -- Начальная высота, будет расти
    moduleFrame.BorderSizePixel = 0
    moduleFrame.ClipsDescendants = true -- Важно для корректного отображения при изменении размера
    
    local moduleCorner = Instance.new("UICorner", moduleFrame)
    moduleCorner.CornerRadius = UDim.new(0, 11)
    local moduleStroke = Instance.new("UIStroke", moduleFrame)
    moduleStroke.Transparency = 0.93
    moduleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    moduleStroke.Color = self.config.TextColor

    local headerFrame = Instance.new("Frame", moduleFrame) -- Для заголовка модуля
    headerFrame.Name = "ModuleHeader"
    headerFrame.BackgroundTransparency = 1
    headerFrame.Size = UDim2.new(1,0,0,40) -- Фиксированная высота заголовка

    local icon = Instance.new("ImageLabel", headerFrame)
    icon.Name = "ModuleIcon"
    icon.BackgroundTransparency = 1
    icon.Size = UDim2.new(0, 25, 0, 25)
    icon.Position = UDim2.new(0.0415, 0, 0.5, -12.5) 
    icon.Image = moduleIcon or DEFAULT_ICON_MODULE
    icon.ImageColor3 = self.config.AccentColor

    local nameLabel = Instance.new("TextLabel", headerFrame)
    nameLabel.Name = "ModuleNameLabel"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(0, 170, 0, 15)
    nameLabel.Position = UDim2.new(0.178, 0, 0.5, -7.5) 
    nameLabel.Font = Enum.Font.Arial
    nameLabel.Text = moduleName
    nameLabel.TextColor3 = self.config.TextColor
    nameLabel.TextScaled = true
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left

    local contentOuterFrame = Instance.new("Frame", moduleFrame) -- Внешний контейнер для контента с отступами
    contentOuterFrame.Name = "ModuleContentOuterFrame"
    contentOuterFrame.BackgroundTransparency = 1
    contentOuterFrame.Size = UDim2.new(1,0,1,-40) -- Занимает оставшееся место
    contentOuterFrame.Position = UDim2.new(0,0,0,40)
    
    local contentFrame = Instance.new("Frame", contentOuterFrame)
    contentFrame.Name = "ModuleContentFrame"
    contentFrame.BackgroundColor3 = self.config.ModuleContentBackgroundColor
    contentFrame.Size = UDim2.new(1, -10, 1, -10) -- Отступы по 5px с каждой стороны
    contentFrame.Position = UDim2.new(0,5,0,5)
    contentFrame.BorderSizePixel = 0
    contentFrame.ClipsDescendants = true

    local contentCorner = Instance.new("UICorner", contentFrame)
    contentCorner.CornerRadius = UDim.new(0, 8) -- Скругление как в "zadnica"
    
    local contentLayout = Instance.new("UIListLayout", contentFrame)
    contentLayout.Padding = UDim.new(0, 8)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left -- Элементы внутри контента
    contentLayout.FillDirection = Enum.FillDirection.Vertical

    -- Функция для обновления высоты модуля
    local function updateModuleHeight()
        local totalContentHeight = 5 -- Начальный отступ
        for _, child in ipairs(contentFrame:GetChildren()) do
            if child:IsA("GuiObject") and child ~= contentLayout and child.Visible then
                totalContentHeight = totalContentHeight + child.AbsoluteSize.Y + contentLayout.Padding.Offset
            end
        end
        totalContentHeight = math.max(10, totalContentHeight - contentLayout.Padding.Offset + 5)

        contentFrame.Size = UDim2.new(1, -10, 0, totalContentHeight) -- Обновляем высоту внутреннего контент-фрейма
        moduleFrame.Size = UDim2.new(0, 265, 0, 40 + totalContentHeight + 10) -- 40 (header) + content + 5 (top_padding_outer) + 5 (bottom_padding_outer)
        
        -- Это вызовет перерасчет UIGridLayout в категории
        if categoryData.layout then
            categoryData.layout.AbsoluteContentSize = categoryData.layout.AbsoluteContentSize 
        end
    end
    
    contentLayout.Changed:Connect(function(property)
        if property == "AbsoluteContentSize" then updateModuleHeight() end
    end)
    
    local moduleApi = {}
    moduleApi.elements = {}
    moduleData.modules[moduleName] = {frame = moduleFrame, contentFrame = contentFrame, api = moduleApi}


    moduleApi.AddToggle = function(optionName, description, initialState, callback, helpContent)
        local toggle, helpButton = self:_addToggle(moduleData.modules[moduleName], optionName, description, initialState, callback, updateModuleHeight, helpContent)
        moduleApi.elements[optionName] = {type="toggle", control=toggle, help=helpButton}
        return toggle
    end
    moduleApi.AddDropdown = function(optionName, description, optionsArray, initialValue, callback, helpContent)
        local dropdown, helpButton = self:_addDropdown(moduleData.modules[moduleName], optionName, description, optionsArray, initialValue, callback, updateModuleHeight, helpContent)
        moduleApi.elements[optionName] = {type="dropdown", control=dropdown, help=helpButton}
        return dropdown
    end
    moduleApi.AddButton = function(buttonText, description, callback, helpContent) -- optionName не нужен для кнопки, если только для идентификации
        local actionButton, helpButton = self:_addButton(moduleData.modules[moduleName], buttonText, description, callback, updateModuleHeight, helpContent)
        moduleApi.elements[buttonText] = {type="button", control=actionButton, help=helpButton}
        return actionButton
    end
    
    task.wait() -- Дать элементам отрисоваться перед первым вызовом
    updateModuleHeight()

    return moduleApi
end

-- Вспомогательная функция для создания кнопки помощи
function ExpaLib:_createHelpButton(parentFrame, helpContentTable)
    if not helpContentTable or #helpContentTable == 0 then return nil end

    local helpButton = Instance.new("ImageButton", parentFrame)
    helpButton.Name = "HelpButton"
    helpButton.BackgroundTransparency = 1
    helpButton.Image = DEFAULT_ICON_HELP
    helpButton.Size = UDim2.new(0,18,0,18)
    helpButton.Position = UDim2.new(1, -45, 0.5, -9) -- Справа от контрола, перед краем
    helpButton.ZIndex = parentFrame.ZIndex + 1

    local helpPopup = Instance.new("Frame", G2L_Internal.ScreenGui) -- Попап на весь экран для центрирования
    helpPopup.Name = "HelpPopup"
    helpPopup.Size = UDim2.new(1,0,1,0)
    helpPopup.BackgroundTransparency = 0.7
    helpPopup.BackgroundColor3 = Color3.fromRGB(0,0,0)
    helpPopup.Visible = false
    helpPopup.ZIndex = G2L_Internal.MainFrame.ZIndex + 10 -- Поверх всего

    local helpContentFrame = Instance.new("Frame", helpPopup)
    helpContentFrame.Name = "HelpContentFrame"
    helpContentFrame.Size = UDim2.new(0, 248, 0, 300) -- Размер как в ChestDupe Help, высота будет авто
    helpContentFrame.BackgroundColor3 = self.config.MainBackgroundColor
    helpContentFrame.Position = UDim2.new(0.5, -124, 0.5, -150) -- Центрируем
    helpContentFrame.BorderSizePixel = 0
    applyGradient(helpContentFrame, 34, self.config.DefaultGradient) -- Градиент как у основного окна
    local helpCorner = Instance.new("UICorner", helpContentFrame)
    helpCorner.CornerRadius = UDim.new(0,11)

    local helpLayout = Instance.new("UIListLayout", helpContentFrame)
    helpLayout.Padding = UDim.new(0,5)
    helpLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    helpLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    local titleLabel = Instance.new("TextLabel", helpContentFrame)
    titleLabel.Name = "HelpTitle"
    titleLabel.Size = UDim2.new(0.9,0,0,30)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = helpContentTable.title or "Help"
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 20
    titleLabel.TextColor3 = self.config.TextColor
    
    local titleDivider = Instance.new("Frame", helpContentFrame)
    titleDivider.Name = "HelpTitleDivider"
    titleDivider.Size = UDim2.new(0.9,0,0,1)
    titleDivider.BackgroundColor3 = self.config.AccentColor
    titleDivider.BackgroundTransparency = 0.5

    for _, item in ipairs(helpContentTable.items or {}) do
        if item.type == "text" then
            local text = Instance.new("TextLabel", helpContentFrame)
            text.Size = UDim2.new(0.9,0,0,0) -- Высота авто
            text.AutomaticSize = Enum.AutomaticSize.Y
            text.BackgroundTransparency = 1
            text.Text = item.value or ""
            text.Font = Enum.Font.SourceSans
            text.TextSize = item.size or 14
            text.TextColor3 = self.config.TextColor
            text.TextWrapped = true
            text.TextXAlignment = Enum.TextXAlignment.Left
        elseif item.type == "image" then
            local img = Instance.new("ImageLabel", helpContentFrame)
            img.Size = UDim2.new(0, item.width or 200, 0, item.height or 100)
            img.BackgroundTransparency = 1
            img.Image = item.assetId or ""
            img.ScaleType = Enum.ScaleType.Fit
        end
    end
    
    -- Автоматическое определение высоты для helpContentFrame
    local totalHelpHeight = 10 + titleLabel.AbsoluteSize.Y + titleDivider.AbsoluteSize.Y + (helpLayout.Padding.Offset * 2)
    for _, child in ipairs(helpContentFrame:GetChildren()) do
        if child ~= titleLabel and child ~= titleDivider and child ~= helpLayout and child:IsA("GuiObject") then
            totalHelpHeight = totalHelpHeight + child.AbsoluteSize.Y + helpLayout.Padding.Offset
        end
    end
    helpContentFrame.Size = UDim2.new(0, 248, 0, totalHelpHeight)
    helpContentFrame.Position = UDim2.new(0.5, -124, 0.5, -totalHelpHeight/2) -- Перецентрируем


    helpButton.MouseButton1Click:Connect(function() helpPopup.Visible = true end)
    helpPopup.InputBegan:Connect(function(input) -- Закрытие по клику вне контента
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mouseLocation = UserInputService:GetMouseLocation()
            local framePos = helpContentFrame.AbsolutePosition
            local frameSize = helpContentFrame.AbsoluteSize
            if not (mouseLocation.X >= framePos.X and mouseLocation.X <= framePos.X + frameSize.X and
                    mouseLocation.Y >= framePos.Y and mouseLocation.Y <= framePos.Y + frameSize.Y) then
                helpPopup.Visible = false
            end
        end
    end)
    
    return helpButton
end


function ExpaLib:_addOptionBase(moduleData, optionName, description, updateModuleHeightCallback)
    local optionContainer = Instance.new("Frame", moduleData.contentFrame)
    optionContainer.Name = optionName .. "OptionContainer"
    optionContainer.BackgroundTransparency = 1
    optionContainer.Size = UDim2.new(1, -10, 0, 35) -- -10 для отступов внутри контент-фрейма
    optionContainer.Position = UDim2.new(0,5,0,0) -- Отступ 5 слева

    local nameLabel = Instance.new("TextLabel", optionContainer)
    nameLabel.Name = "OptionNameLabel"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(0, 170, 0, 15) -- Из оригинальных "blablabla"
    nameLabel.Position = UDim2.new(0.03785, 0, 0.08169, 0) -- Верхняя позиция текста
    nameLabel.Font = Enum.Font.Arial
    nameLabel.Text = optionName
    nameLabel.TextColor3 = self.config.TextColor
    nameLabel.TextScaled = true
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left

    local descLabel = Instance.new("TextLabel", optionContainer)
    descLabel.Name = "OptionDescriptionLabel"
    descLabel.BackgroundTransparency = 1
    descLabel.Size = UDim2.new(0, 160, 0, 13) -- Из оригинальных "blablabla"
    descLabel.Position = UDim2.new(0.03785, 0, 0.29819, 0) -- Нижняя позиция описания
    descLabel.Font = Enum.Font.Arial
    descLabel.Text = description
    descLabel.TextColor3 = self.config.TextColor -- В оригинале такой же цвет
    descLabel.TextTransparency = 0.55 -- Прозрачность как в оригинале
    descLabel.TextScaled = true
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    task.defer(updateModuleHeightCallback)
    return optionContainer, nameLabel, descLabel
end

function ExpaLib:_addToggle(moduleData, optionName, description, initialState, callback, updateModuleHeightCallback, helpContent)
    local optionContainer, _, _ = self:_addOptionBase(moduleData, optionName, description, updateModuleHeightCallback)
    -- Высота optionContainer уже задана в _addOptionBase и подходит

    local toggleButton = Instance.new("ImageButton", optionContainer)
    toggleButton.Name = "ToggleButton"
    toggleButton.BackgroundColor3 = self.config.AccentColor
    toggleButton.Image = CHECKMARK_ICON
    toggleButton.Size = UDim2.new(0, 15, 0, 15)
    toggleButton.Position = UDim2.new(0.89773, 0, 0.16495, 0) -- Позиция из "on"
    toggleButton.ImageTransparency = if initialState then 0 else 1
    toggleButton.BackgroundTransparency = if initialState then 0 else 1 -- Фон тоже меняем

    local toggleCorner = Instance.new("UICorner", toggleButton)
    toggleCorner.CornerRadius = UDim.new(0, 3)
    local toggleStroke = Instance.new("UIStroke", toggleButton)
    toggleStroke.Transparency = 0.77
    toggleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    toggleStroke.Color = self.config.TextColor

    local currentState = initialState or false
    toggleButton.MouseButton1Click:Connect(function()
        currentState = not currentState
        toggleButton.ImageTransparency = if currentState then 0 else 1
        toggleButton.BackgroundTransparency = if currentState then 0 else 1
        
        if currentState then self.soundToggleOn:Play() else self.soundToggleOff:Play() end
        if callback then
            local success, err = pcall(callback, currentState)
            if not success then
                self:ShowNotification("Script Error", "Error in " .. moduleName .. "/" .. optionName .. ": " .. tostring(err), "error")
            end
        end
        self:ShowNotification(moduleData.frame.Name:gsub("Module",""), optionName .. (currentState and " enabled" or " disabled"))
    end)
    
    local helpButton = self:_createHelpButton(optionContainer, helpContent)
    if helpButton then
        -- Сдвинуть toggleButton, если есть кнопка помощи
        toggleButton.Position = UDim2.new(0.89773 - 0.1, 0, 0.16495, 0) -- Примерный сдвиг
    end

    task.defer(updateModuleHeightCallback)
    return toggleButton, helpButton
end

function ExpaLib:_addDropdown(moduleData, optionName, description, optionsArray, initialValue, callback, updateModuleHeightCallback, helpContent)
    local optionContainer, _, _ = self:_addOptionBase(moduleData, optionName, description, updateModuleHeightCallback)
    -- Высота optionContainer подходит

    local dropdownButton = Instance.new("TextButton", optionContainer)
    dropdownButton.Name = "DropdownButton"
    dropdownButton.Size = UDim2.new(0, 76, 0, 23)
    dropdownButton.Position = UDim2.new(0.67803, 0, 0.61856, 0) -- Позиция из "select_distance"
    dropdownButton.BackgroundColor3 = Color3.fromRGB(24,25,38) -- Цвет из "select_distance"
    dropdownButton.Text = tostring(initialValue) or (optionsArray[1] and tostring(optionsArray[1])) or "Select"
    dropdownButton.TextColor3 = self.config.TextColor
    dropdownButton.Font = Enum.Font.SourceSans
    dropdownButton.TextSize = 14

    local ddCorner = Instance.new("UICorner", dropdownButton)
    ddCorner.CornerRadius = UDim.new(0, 3)
    local ddStroke = Instance.new("UIStroke", dropdownButton)
    ddStroke.Transparency = 0.77
    ddStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    ddStroke.Color = self.config.TextColor

    local listFrame = Instance.new("ScrollingFrame", dropdownButton) -- Для прокрутки, если много опций
    listFrame.Name = "DropdownListFrame"
    listFrame.BackgroundTransparency = 1 
    listFrame.Size = UDim2.new(1, 0, 0, 0) -- Высота будет настроена
    listFrame.AutomaticSize = Enum.AutomaticSize.Y
    listFrame.CanvasSize = UDim2.new(0,0,0,0)
    listFrame.Position = UDim2.new(0, 0, 1, 5) 
    listFrame.Visible = false
    listFrame.ZIndex = dropdownButton.ZIndex + 10 -- Важно, чтобы был выше всего
    listFrame.ClipsDescendants = true
    listFrame.BorderSizePixel = 0
    listFrame.ScrollBarThickness = 4
    listFrame.TopImage = "rbxassetid://113794737072906" -- Пример, можно убрать или кастомизировать

    local listLayout = Instance.new("UIListLayout", listFrame)
    listLayout.Padding = UDim.new(0, 3)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    for _, optValue in ipairs(optionsArray) do
        local itemButton = Instance.new("TextButton", listFrame)
        itemButton.Name = tostring(optValue) .. "Item"
        itemButton.Text = tostring(optValue)
        itemButton.Size = UDim2.new(1, 0, 0, 23)
        itemButton.BackgroundColor3 = dropdownButton.BackgroundColor3
        itemButton.TextColor3 = self.config.TextColor
        itemButton.Font = Enum.Font.SourceSans
        itemButton.TextSize = 14
        
        local itemCorner = Instance.new("UICorner", itemButton)
        itemCorner.CornerRadius = UDim.new(0, 3)
        local itemStroke = Instance.new("UIStroke", itemButton)
        itemStroke.Transparency = 0.77; itemStroke.Color = self.config.TextColor

        itemButton.MouseEnter:Connect(function() itemButton.BackgroundTransparency = 0.3 end)
        itemButton.MouseLeave:Connect(function() itemButton.BackgroundTransparency = 0 end)

        itemButton.MouseButton1Click:Connect(function()
            dropdownButton.Text = tostring(optValue)
            listFrame.Visible = false
            if callback then
                local success, err = pcall(callback, optValue)
                if not success then
                     self:ShowNotification("Script Error", "Error in " .. moduleName .. "/" .. optionName .. ": " .. tostring(err), "error")
                end
            end
            self:ShowNotification(moduleData.frame.Name:gsub("Module",""), optionName .. " set to " .. tostring(optValue))
        end)
    end
    
    -- Ограничение высоты списка
    local maxListHeight = 100 -- Максимальная высота в пикселях
    local currentListHeight = #optionsArray * (23 + listLayout.Padding.Offset) - listLayout.Padding.Offset
    listFrame.Size = UDim2.new(1,0,0, math.min(maxListHeight, currentListHeight))
    listFrame.CanvasSize = UDim2.new(0,0,0,currentListHeight)


    dropdownButton.MouseButton1Click:Connect(function()
        listFrame.Visible = not listFrame.Visible
        if listFrame.Visible then -- Переместить наверх, если открыт
            listFrame.Parent = G2L_Internal.ScreenGui -- Временно перемещаем, чтобы был поверх всего
            listFrame.Position = dropdownButton.AbsolutePosition + Vector2.new(0, dropdownButton.AbsoluteSize.Y + 5)
        else
            listFrame.Parent = dropdownButton -- Возвращаем обратно
            listFrame.Position = UDim2.new(0,0,1,5)
        end
    end)
    
    local helpButton = self:_createHelpButton(optionContainer, helpContent)
    if helpButton then
        dropdownButton.Position = UDim2.new(0.67803 - 0.1, 0, 0.61856, 0)
    end

    task.defer(updateModuleHeightCallback)
    return dropdownButton, helpButton
end

function ExpaLib:_addButton(moduleData, buttonText, description, callback, updateModuleHeightCallback, helpContent)
    local optionContainer, nameLabel, descLabel = self:_addOptionBase(moduleData, buttonText, description, updateModuleHeightCallback)
    nameLabel.Text = buttonText -- Название кнопки = тексту на ней
    descLabel.Text = description

    local actionButton = Instance.new("TextButton", optionContainer)
    actionButton.Name = "ActionButton"
    actionButton.Size = UDim2.new(0, 76, 0, 23)
    actionButton.Position = UDim2.new(0.67803, 0, 0.61856, 0) -- Как у dropdown
    actionButton.BackgroundColor3 = self.config.AccentColor
    actionButton.Text = "Run" -- Или можно передавать текст кнопки
    actionButton.TextColor3 = self.config.TextColor
    actionButton.Font = Enum.Font.SourceSans
    actionButton.TextSize = 14

    local btnCorner = Instance.new("UICorner", actionButton)
    btnCorner.CornerRadius = UDim.new(0, 3)
    
    actionButton.MouseButton1Click:Connect(function()
        if callback then
            local success, err = pcall(callback)
            if not success then
                self:ShowNotification("Script Error", "Error executing " .. buttonText .. ": " .. tostring(err), "error")
            end
        end
        self:ShowNotification(moduleData.frame.Name:gsub("Module",""), buttonText .. " executed.")
    end)
    
    local helpButton = self:_createHelpButton(optionContainer, helpContent)
    if helpButton then
        actionButton.Position = UDim2.new(0.67803 - 0.1, 0, 0.61856, 0)
    end

    task.defer(updateModuleHeightCallback)
    return actionButton, helpButton
end

function ExpaLib:ShowNotification(title, message, messageType)
    createNotification(G2L_Internal.NotificationsContainer, title, message, messageType, self.config.AccentColor)
end

function ExpaLib:Destroy()
    if G2L_Internal.ScreenGui then
        G2L_Internal.ScreenGui:Destroy()
    end
    G2L_Internal = {}
    self.categories = {}
    self.activeCategoryData = nil
    self.moduleElements = {}
    -- Остановить любые соединения RunService, если они были созданы библиотекой
end

--[[ HUD Элементы ]]
function ExpaLib:CreateWatermark(options)
    options = options or {}
    if G2L_Internal.WatermarkFrame then G2L_Internal.WatermarkFrame:Destroy() end

    G2L_Internal.WatermarkFrame = Instance.new("Frame", G2L_Internal.ScreenGui)
    G2L_Internal.WatermarkFrame.Name = "WatermarkFrame"
    G2L_Internal.WatermarkFrame.BackgroundColor3 = options.BackgroundColor or self.config.MainBackgroundColor
    G2L_Internal.WatermarkFrame.BorderSizePixel = 0
    G2L_Internal.WatermarkFrame.Size = UDim2.new(0, 254, 0, 29) -- Из hud_real
    G2L_Internal.WatermarkFrame.Position = options.Position or UDim2.new(0.05213, 0, 0.12267, 0)
    G2L_Internal.WatermarkFrame.Visible = options.InitialVisibility == nil and self.mainGuiVisible or options.InitialVisibility
    G2L_Internal.WatermarkFrame.BackgroundTransparency = options.Transparency or 0
    G2L_Internal.WatermarkFrame:SetAttribute("IsEnabled", G2L_Internal.WatermarkFrame.Visible)
    if options.Draggable == nil or options.Draggable then makeDraggable(G2L_Internal.WatermarkFrame) end

    local corner = Instance.new("UICorner", G2L_Internal.WatermarkFrame)
    corner.CornerRadius = UDim.new(0, 6)
    
    local logoImage = Instance.new("ImageLabel", G2L_Internal.WatermarkFrame)
    logoImage.Name = "Logo"
    logoImage.BackgroundTransparency = 1
    logoImage.Size = UDim2.new(0,36,0,36)
    logoImage.Position = UDim2.new(0,0,-0.13793,0)
    logoImage.Image = options.LogoAssetId or "rbxassetid://113794737072906"
    logoImage.ImageColor3 = options.LogoColor or Color3.fromRGB(154, 154, 255)
    
    local titleLabel = Instance.new("TextLabel", G2L_Internal.WatermarkFrame)
    titleLabel.Name = "WatermarkTitle"
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(0, 76, 0, 20)
    titleLabel.Position = UDim2.new(0.13882, 0, 0.107, 0)
    titleLabel.Text = options.TitleText or self.config.Title:lower()
    titleLabel.Font = Enum.Font.SourceSans
    titleLabel.TextScaled = true
    titleLabel.TextColor3 = options.TitleColor or self.config.AccentColor
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Ping
    local pingIcon = Instance.new("ImageLabel", G2L_Internal.WatermarkFrame)
    pingIcon.Position = UDim2.new(0.4367,0,0.10345,0); pingIcon.Size = UDim2.new(0,20,0,20)
    pingIcon.Image = "rbxassetid://98100229488747"; pingIcon.ImageColor3 = logoImage.ImageColor3; pingIcon.BackgroundTransparency = 1
    local pingLabel = Instance.new("TextLabel", pingIcon)
    pingLabel.Name = "PingLabel"
    pingLabel.Position = UDim2.new(1.198,0,0.141,0); pingLabel.Size = UDim2.new(0,45,0,15)
    pingLabel.Text = "N/A ms"; pingLabel.TextColor3 = self.config.TextColor; pingLabel.Font = Enum.Font.SourceSans
    pingLabel.TextScaled=true; pingLabel.BackgroundTransparency=1; pingLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- FPS
    local fpsIcon = Instance.new("ImageLabel", G2L_Internal.WatermarkFrame)
    fpsIcon.Position = UDim2.new(0.70761,0,0.10345,0); fpsIcon.Size = UDim2.new(0,20,0,20)
    fpsIcon.Image = "rbxassetid://109639566385838"; fpsIcon.ImageColor3 = logoImage.ImageColor3; fpsIcon.BackgroundTransparency = 1
    local fpsLabel = Instance.new("TextLabel", fpsIcon)
    fpsLabel.Name = "FPSLabel"
    fpsLabel.Position = UDim2.new(1.198,0,0.141,0); fpsLabel.Size = UDim2.new(0,45,0,15)
    fpsLabel.Text = "N/A FPS"; fpsLabel.TextColor3 = self.config.TextColor; fpsLabel.Font = Enum.Font.SourceSans
    fpsLabel.TextScaled=true; fpsLabel.BackgroundTransparency=1; fpsLabel.TextXAlignment = Enum.TextXAlignment.Left

    local statUpdaterConnection
    local function updateStats()
        if G2L_Internal.WatermarkFrame and G2L_Internal.WatermarkFrame.Visible then
            pingLabel.Text = math.floor(Players.LocalPlayer:GetNetworkPing() * 1000) .. " ms"
            fpsLabel.Text = math.floor(workspace:GetRealPhysicsFPS()) .. " FPS"
        end
    end
    statUpdaterConnection = RunService.RenderStepped:Connect(updateStats)
    G2L_Internal.WatermarkFrame.Destroying:Connect(function() if statUpdaterConnection then statUpdaterConnection:Disconnect() end end)
end

function ExpaLib:CreateTargetHud(options)
    options = options or {}
    if G2L_Internal.TargetHudFrame then G2L_Internal.TargetHudFrame:Destroy() end

    G2L_Internal.TargetHudFrame = Instance.new("Frame", G2L_Internal.ScreenGui)
    G2L_Internal.TargetHudFrame.Name = "TargetHudFrame"
    G2L_Internal.TargetHudFrame.BackgroundColor3 = options.BackgroundColor or self.config.MainBackgroundColor
    G2L_Internal.TargetHudFrame.BorderSizePixel = 0
    G2L_Internal.TargetHudFrame.Size = UDim2.new(0, 238, 0, 58) -- Из targethud_real
    G2L_Internal.TargetHudFrame.Position = options.Position or UDim2.new(0.18793, 0, 0.21235, 0)
    G2L_Internal.TargetHudFrame.Visible = options.InitialVisibility == nil and self.mainGuiVisible or options.InitialVisibility
    G2L_Internal.TargetHudFrame.BackgroundTransparency = options.Transparency or 0
    G2L_Internal.TargetHudFrame:SetAttribute("IsEnabled", G2L_Internal.TargetHudFrame.Visible)
    if options.Draggable == nil or options.Draggable then makeDraggable(G2L_Internal.TargetHudFrame) end

    local corner = Instance.new("UICorner", G2L_Internal.TargetHudFrame)
    -- Отсутствует CornerRadius в оригинале, если нужно - добавить
    
    local avatarImage = Instance.new("ImageLabel", G2L_Internal.TargetHudFrame)
    avatarImage.Size = UDim2.new(0,40,0,40); avatarImage.Position = UDim2.new(0.05434,0,0.15444,0)
    avatarImage.Image = "http://www.roblox.com/asset/?id=6228441155" -- Placeholder
    avatarImage.BackgroundTransparency=1; local avCorner=Instance.new("UICorner", avatarImage); avCorner.CornerRadius=UDim.new(0,4)

    local nameLabel = Instance.new("TextLabel", G2L_Internal.TargetHudFrame)
    nameLabel.Size = UDim2.new(0,132,0,13); nameLabel.Position = UDim2.new(0.26218,0,0.19676,0)
    nameLabel.Text="No Target"; nameLabel.Font=Enum.Font.Arial; nameLabel.TextColor3=self.config.TextColor
    nameLabel.TextScaled=true; nameLabel.BackgroundTransparency=1; nameLabel.TextXAlignment = Enum.TextXAlignment.Left

    local hpBarBackground = Instance.new("Frame", G2L_Internal.TargetHudFrame) -- Фон для полоски HP
    hpBarBackground.Size = UDim2.new(0,109,0,3); hpBarBackground.Position = UDim2.new(0.262,0,0.603,0)
    hpBarBackground.BackgroundColor3 = Color3.fromRGB(50,50,50); hpBarBackground.BackgroundTransparency = 0.5
    
    local hpBar = Instance.new("Frame", hpBarBackground)
    hpBar.Name = "HPBar"
    hpBar.Size = UDim2.new(1,0,1,0); -- Начнем с полной
    hpBar.BackgroundColor3 = self.config.NavButtonColor
    hpBar.BackgroundTransparency = 0 -- Непрозрачная полоска

    local hpIcon = Instance.new("ImageLabel", G2L_Internal.TargetHudFrame)
    hpIcon.Size = UDim2.new(0,20,0,20); hpIcon.Position = UDim2.new(0.75891,0,0.44755,0)
    hpIcon.Image = "rbxassetid://110560310926046"; hpIcon.BackgroundTransparency=1

    local hpText = Instance.new("TextLabel", G2L_Internal.TargetHudFrame)
    hpText.Size = UDim2.new(0,40,0,13); hpText.Position = UDim2.new(0.87143,0,0.5071,0) -- Сдвинуто, чтобы не перекрывать иконку
    hpText.Text="100"; hpText.Font=Enum.Font.Arial; hpText.TextColor3=self.config.TextColor
    hpText.TextScaled=true; hpText.BackgroundTransparency=1; hpText.TextXAlignment = Enum.TextXAlignment.Left

    local targetUpdaterConnection
    local function updateTargetHud()
        if not (G2L_Internal.TargetHudFrame and G2L_Internal.TargetHudFrame.Visible) then return end
        -- Логика поиска ближайшего игрока (можно вынести в опции)
        local currentTarget = nil; local minDist = math.huge
        for _,p in ipairs(Players:GetPlayers()) do
            if p ~= localPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChildOfClass("Humanoid") then
                local dist = (localPlayer.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
                if dist < minDist and dist < (options.MaxDistance or 50) then -- MaxDistance из опций
                    minDist = dist; currentTarget = p
                end
            end
        end

        if currentTarget then
            nameLabel.Text = currentTarget.DisplayName
            local humanoid = currentTarget.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                hpText.Text = tostring(math.floor(humanoid.Health))
                hpBar.Size = UDim2.new(humanoid.Health / humanoid.MaxHealth, 0, 1, 0)
                -- Загрузка аватара цели
                local s, uId = pcall(Players.GetUserIdFromNameAsync, Players, currentTarget.Name)
                if s and uId then
                    local th, rdy = pcall(Players.GetUserThumbnailAsync, Players, uId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                    if th and rdy then avatarImage.Image = rdy end
                end
            end
        else
            nameLabel.Text = "No Target"; hpText.Text = "N/A"; hpBar.Size = UDim2.new(0,0,1,0)
            avatarImage.Image = "http://www.roblox.com/asset/?id=6228441155" -- Сброс аватара
        end
    end
    targetUpdaterConnection = RunService.RenderStepped:Connect(updateTargetHud)
    G2L_Internal.TargetHudFrame.Destroying:Connect(function() if targetUpdaterConnection then targetUpdaterConnection:Disconnect() end end)
end

function ExpaLib:CreateRenderGif(options)
    options = options or {}
    if G2L_Internal.RenderGifFrame then G2L_Internal.RenderGifFrame:Destroy() end

    G2L_Internal.RenderGifFrame = Instance.new("Frame", G2L_Internal.ScreenGui)
    G2L_Internal.RenderGifFrame.Name = "RenderGifFrame"
    G2L_Internal.RenderGifFrame.BackgroundColor3 = options.BackgroundColor or self.config.MainBackgroundColor
    G2L_Internal.RenderGifFrame.BorderSizePixel = 0
    G2L_Internal.RenderGifFrame.Size = UDim2.new(0,430,0,262) -- Из renderGIF_real
    G2L_Internal.RenderGifFrame.Position = options.Position or UDim2.new(0.1166, 0, 0.63367, 0)
    G2L_Internal.RenderGifFrame.Visible = options.InitialVisibility == nil and self.mainGuiVisible or options.InitialVisibility
    G2L_Internal.RenderGifFrame.BackgroundTransparency = options.Transparency or 0
    G2L_Internal.RenderGifFrame:SetAttribute("IsEnabled", G2L_Internal.RenderGifFrame.Visible)
    if options.Draggable == nil or options.Draggable then makeDraggable(G2L_Internal.RenderGifFrame) end

    local corner = Instance.new("UICorner", G2L_Internal.RenderGifFrame); corner.CornerRadius = UDim.new(0,11)
    local stroke = Instance.new("UIStroke", G2L_Internal.RenderGifFrame); stroke.Transparency = 0.95; stroke.Color = self.config.TextColor

    local headerFrame = Instance.new("Frame", G2L_Internal.RenderGifFrame)
    headerFrame.Size = UDim2.new(1,0,0,38); headerFrame.BackgroundTransparency=1 -- Высота под контент (0.14504 * 262)

    local icon = Instance.new("ImageLabel", headerFrame)
    icon.Size=UDim2.new(0,23,0,23); icon.Position=UDim2.new(0.03053,0,0.5,-11.5)
    icon.Image="rbxassetid://116181409843743"; icon.ImageColor3=self.config.AccentColor; icon.BackgroundTransparency=1

    local title = Instance.new("TextLabel", headerFrame)
    title.Size=UDim2.new(0,170,0,16); title.Position=UDim2.new(0.10014,0,0.5,-8)
    title.Text= options.TitleText or "RenderGIF"; title.Font=Enum.Font.Arial; title.TextColor3=self.config.TextColor
    title.TextScaled=true; title.BackgroundTransparency=1; title.TextXAlignment = Enum.TextXAlignment.Left
    
    local divider = Instance.new("Frame", G2L_Internal.RenderGifFrame)
    divider.Size = UDim2.new(1,0,0,1); divider.Position = UDim2.new(0,0,0,38)
    divider.BackgroundTransparency = 0.85
    applyGradient(divider, 0, ColorSequence.new{ -- Градиент из "prikol" под RenderGIF
        ColorSequenceKeypoint.new(0.000, Color3.fromRGB(77, 77, 127)),
        ColorSequenceKeypoint.new(0.275, Color3.fromRGB(189, 189, 208)),
        ColorSequenceKeypoint.new(0.786, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.850, Color3.fromRGB(253, 253, 254)),
        ColorSequenceKeypoint.new(1.000, Color3.fromRGB(255, 255, 255))
    })

    local gifImageLabel = Instance.new("ImageLabel", G2L_Internal.RenderGifFrame)
    gifImageLabel.Name = "GifImage"
    gifImageLabel.Size = UDim2.new(1,0,1,-39) -- Занимает оставшееся место
    gifImageLabel.Position = UDim2.new(0,0,0,39)
    gifImageLabel.BackgroundTransparency = 1
    gifImageLabel.ScaleType = Enum.ScaleType.Stretch -- Или Fit/Crop

    local gifFrames = options.GifFrames or { -- Дефолтные кадры из оригинала
        "rbxassetid://83703961545416", -- odin
        "rbxassetid://106424387217082", -- dva
        "rbxassetid://99674475208247", -- tri
        "rbxassetid://106424387217082" -- dva (для цикла)
    }
    local frameDelay = options.FrameDelay or 0.25
    local currentFrame = 1
    
    local gifUpdaterConnection
    local function updateGif()
        if G2L_Internal.RenderGifFrame and G2L_Internal.RenderGifFrame.Visible and #gifFrames > 0 then
            gifImageLabel.Image = gifFrames[currentFrame]
            currentFrame = currentFrame + 1
            if currentFrame > #gifFrames then currentFrame = 1 end
        end
    end
    
    -- Запуск цикла анимации
    local gifLoopActive = true
    coroutine.wrap(function()
        while gifLoopActive do
            updateGif()
            task.wait(frameDelay)
        end
    end)()
    G2L_Internal.RenderGifFrame.Destroying:Connect(function() gifLoopActive = false end)
end

function ExpaLib:CreateAmbianceOverlay(options)
    options = options or {}
    if G2L_Internal.AmbianceOverlay then G2L_Internal.AmbianceOverlay:Destroy() end

    G2L_Internal.AmbianceOverlay = Instance.new("Frame", G2L_Internal.ScreenGui)
    G2L_Internal.AmbianceOverlay.Name = "AmbianceOverlay"
    G2L_Internal.AmbianceOverlay.Size = UDim2.new(2,0,2,0) -- Очень большой, чтобы покрыть экран
    G2L_Internal.AmbianceOverlay.Position = UDim2.new(-0.5,0,-0.5,0) -- Центрирован
    G2L_Internal.AmbianceOverlay.BackgroundColor3 = Color3.fromRGB(0, 35, 31) -- Из ambience_real
    G2L_Internal.AmbianceOverlay.BackgroundTransparency = options.Transparency or 0.45
    G2L_Internal.AmbianceOverlay.Visible = options.InitialVisibility == nil and self.mainGuiVisible or options.InitialVisibility
    G2L_Internal.AmbianceOverlay:SetAttribute("IsEnabled", G2L_Internal.AmbianceOverlay.Visible)
    G2L_Internal.AmbianceOverlay.ZIndex = G2L_Internal.MainFrame.ZIndex -1 -- Под основным GUI

    if options.AnimateColor == nil or options.AnimateColor then
        local colorSpeed = options.AnimationSpeed or 1
        local colorUpdaterConnection
        local function updateAmbianceColor()
            if G2L_Internal.AmbianceOverlay and G2L_Internal.AmbianceOverlay.Visible then
                local r = math.abs(math.sin(tick() * colorSpeed * 0.7))
                local g = math.abs(math.cos(tick() * colorSpeed * 1.0))
                local b = math.abs(math.sin(tick() * colorSpeed * 1.3))
                G2L_Internal.AmbianceOverlay.BackgroundColor3 = Color3.new(r * 0.2, g * 0.2, b * 0.2) -- Приглушенные цвета
            end
        end
        colorUpdaterConnection = RunService.RenderStepped:Connect(updateAmbianceColor)
        G2L_Internal.AmbianceOverlay.Destroying:Connect(function() if colorUpdaterConnection then colorUpdaterConnection:Disconnect() end end)
    end
end


return ExpaLib
