--[[
    ExpaLib - Библиотека для создания GUI
    Основана на структуре "Expensive GUI"
    Автор адаптации: AI Ассистент
]]

local ExpaLib = {}
ExpaLib.__index = ExpaLib

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local G2L = {} -- Внутреннее хранилище элементов, если понадобится

-- Основные настройки
local DEFAULT_ICON = "rbxassetid://136482807431952" -- Стандартная иконка модуля
local SOUND_TOGGLE_ON = "rbxassetid://17208361335"
local SOUND_TOGGLE_OFF = "rbxassetid://17208372272"

-- [[ Хелперы и внутренние функции ]]

local function createNotification(title, message, messageType)
    local notificationsContainer = G2L.NotificationsContainer
    if not notificationsContainer then return end

    local notificationFrame = Instance.new("Frame")
    notificationFrame.Name = "NotificationItem"
    notificationFrame.Parent = notificationsContainer
    notificationFrame.BackgroundColor3 = Color3.fromRGB(17, 18, 34)
    notificationFrame.BorderSizePixel = 0
    notificationFrame.Size = UDim2.new(0, 265, 0, 74)
    notificationFrame.BackgroundTransparency = 1 -- Начнем с невидимого

    local corner = Instance.new("UICorner", notificationFrame)
    corner.CornerRadius = UDim.new(0, 11)

    local icon = Instance.new("ImageLabel", notificationFrame)
    icon.Name = "Icon"
    icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    icon.BackgroundTransparency = 1
    icon.Position = UDim2.new(0.0415, 0, 0.0862, 0)
    icon.Size = UDim2.new(0, 25, 0, 25)
    icon.Image = DEFAULT_ICON
    icon.ImageColor3 = Color3.fromRGB(76, 76, 127)

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
        local tweenInfoHide = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        local tweenHide = TweenService:Create(notificationFrame, tweenInfoHide, { BackgroundTransparency = 1 })
        tweenHide:Play()
        tweenHide.Completed:Connect(function()
            notificationFrame:Destroy()
        end)
    end)
end

local function makeDraggable(guiObject)
    local dragging
    local dragInput
    local dragStart
    local startPosition

    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = guiObject.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    guiObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragging and dragInput then
                local delta = input.Position - dragStart
                guiObject.Position = UDim2.new(
                    startPosition.X.Scale, startPosition.X.Offset + delta.X,
                    startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
                )
            end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input == dragInput then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
end

-- [[ Инициализация GUI ]]
function ExpaLib.new(config)
    local self = setmetatable({}, ExpaLib)

    self.config = config or {}
    self.config.Title = self.config.Title or "ExpaLib GUI"
    self.config.OpenKey = self.config.OpenKey or Enum.KeyCode.RightAlt
    self.config.AccentColor = self.config.AccentColor or Color3.fromRGB(77, 77, 128)
    self.config.SecondaryAccentColor = self.config.SecondaryAccentColor or Color3.fromRGB(79, 87, 159)
    self.config.BackgroundColor = self.config.BackgroundColor or Color3.fromRGB(18, 19, 35)
    self.config.ModuleBackgroundColor = self.config.ModuleBackgroundColor or Color3.fromRGB(26, 27, 40)
    self.config.ModuleContentColor = self.config.ModuleContentColor or Color3.fromRGB(18, 19, 35)
    self.config.TextColor = self.config.TextColor or Color3.fromRGB(255, 255, 255)
    self.config.MutedTextColor = self.config.MutedTextColor or Color3.fromRGB(180, 180, 180)


    self.categories = {} -- { name = "CategoryName", button = TextButton, frame = Frame }
    self.activeCategoryFrame = nil
    self.mainGuiVisible = true

    -- Главный ScreenGui
    G2L.ScreenGui = Instance.new("ScreenGui", playerGui)
    G2L.ScreenGui.DisplayOrder = 999999998 -- чуть ниже оригинального, если вдруг будет конфликт
    G2L.ScreenGui.Name = "ExpaLibScreenGui"
    G2L.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    G2L.ScreenGui.ResetOnSpawn = false

    -- Основной фрейм
    G2L.MainFrame = Instance.new("Frame", G2L.ScreenGui)
    G2L.MainFrame.Name = "MainFrame"
    G2L.MainFrame.ZIndex = 999999999
    G2L.MainFrame.BorderSizePixel = 0
    G2L.MainFrame.BackgroundColor3 = self.config.BackgroundColor
    G2L.MainFrame.Size = UDim2.new(0, 770, 0, 485)
    G2L.MainFrame.Position = UDim2.new(0.5, -385, 0.5, -242.5) -- Центрируем
    G2L.MainFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
    makeDraggable(G2L.MainFrame)

    local mainCorner = Instance.new("UICorner", G2L.MainFrame)
    mainCorner.CornerRadius = UDim.new(0, 11)

    local mainStroke = Instance.new("UIStroke", G2L.MainFrame)
    mainStroke.Transparency = 0.95
    mainStroke.Color = Color3.fromRGB(255, 255, 255)

    -- Левая панель (Навигация и информация о пользователе)
    local leftPanel = Instance.new("Frame", G2L.MainFrame)
    leftPanel.Name = "LeftPanel"
    leftPanel.BackgroundTransparency = 1
    leftPanel.Size = UDim2.new(0, 170, 1, 0) -- Ширина 170, высота 100%
    leftPanel.Position = UDim2.new(0, 0, 0, 0)

    -- Заголовок библиотеки
    G2L.GuiTitle = Instance.new("TextLabel", leftPanel)
    G2L.GuiTitle.Name = "GuiTitle"
    G2L.GuiTitle.TextWrapped = true
    G2L.GuiTitle.BorderSizePixel = 0
    G2L.GuiTitle.TextScaled = true
    G2L.GuiTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    G2L.GuiTitle.TextSize = 14
    G2L.GuiTitle.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold)
    G2L.GuiTitle.TextColor3 = self.config.AccentColor
    G2L.GuiTitle.BackgroundTransparency = 1
    G2L.GuiTitle.Size = UDim2.new(1, -20, 0, 27) -- Отступы
    G2L.GuiTitle.Text = self.config.Title
    G2L.GuiTitle.Position = UDim2.new(0, 10, 0.07216, 0)

    -- Разделитель под заголовком
    local titleDivider = Instance.new("Frame", leftPanel)
    titleDivider.Name = "TitleDivider"
    titleDivider.BackgroundColor3 = self.config.AccentColor
    titleDivider.BackgroundTransparency = 0.8
    titleDivider.BorderSizePixel = 0
    titleDivider.Size = UDim2.new(1, -20, 0, 1)
    titleDivider.Position = UDim2.new(0, 10, 0.15, 0)


    -- Контейнер для кнопок навигации
    G2L.NavigationFrame = Instance.new("Frame", leftPanel)
    G2L.NavigationFrame.Name = "NavigationFrame"
    G2L.NavigationFrame.BackgroundTransparency = 1
    G2L.NavigationFrame.Size = UDim2.new(0, 141, 0, 304)
    G2L.NavigationFrame.Position = UDim2.new(0.02078, 10, 0.20412, 0) -- Сдвинуто для отступа

    local navigationLayout = Instance.new("UIListLayout", G2L.NavigationFrame)
    navigationLayout.Padding = UDim.new(0, 5)
    navigationLayout.SortOrder = Enum.SortOrder.LayoutOrder
    navigationLayout.FillDirection = Enum.FillDirection.Vertical
    navigationLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center


    -- Нижняя часть левой панели (информация о пользователе)
    local userSectionYPos = 0.8 -- Примерно где начинается секция пользователя
    
    local userDivider = Instance.new("Frame", leftPanel)
    userDivider.Name = "UserDivider"
    userDivider.BackgroundColor3 = self.config.AccentColor
    userDivider.BackgroundTransparency = 0.8
    userDivider.BorderSizePixel = 0
    userDivider.Size = UDim2.new(1, -20, 0, 1)
    userDivider.Position = UDim2.new(0, 10, userSectionYPos - 0.02, 0)

    G2L.UserAvatarFrame = Instance.new("ImageLabel", leftPanel)
    G2L.UserAvatarFrame.Name = "UserAvatarFrame"
    G2L.UserAvatarFrame.BackgroundColor3 = self.config.AccentColor
    G2L.UserAvatarFrame.Size = UDim2.new(0, 30, 0, 30)
    G2L.UserAvatarFrame.Position = UDim2.new(0, 15, userSectionYPos, 0)
    G2L.UserAvatarFrame.Image = "rbxassetid://0" -- Placeholder, set later
    local avatarCorner = Instance.new("UICorner", G2L.UserAvatarFrame)
    avatarCorner.CornerRadius = UDim.new(1, 0) -- Круглый

    G2L.OnlineIndicator = Instance.new("Frame", G2L.UserAvatarFrame) -- Внутри аватара для позиционирования
    G2L.OnlineIndicator.Name = "OnlineIndicator"
    G2L.OnlineIndicator.BackgroundColor3 = Color3.fromRGB(65, 154, 126)
    G2L.OnlineIndicator.Size = UDim2.new(0, 10, 0, 10)
    G2L.OnlineIndicator.Position = UDim2.new(0.7, 0, 0.7, 0) -- Правый нижний угол аватара
    local indicatorCorner = Instance.new("UICorner", G2L.OnlineIndicator)
    indicatorCorner.CornerRadius = UDim.new(1, 0)
    local indicatorStroke = Instance.new("UIStroke", G2L.OnlineIndicator)
    indicatorStroke.Thickness = 1
    indicatorStroke.Color = self.config.BackgroundColor


    G2L.UsernameLabel = Instance.new("TextLabel", leftPanel)
    G2L.UsernameLabel.Name = "UsernameLabel"
    G2L.UsernameLabel.TextWrapped = true
    G2L.UsernameLabel.BorderSizePixel = 0
    G2L.UsernameLabel.TextXAlignment = Enum.TextXAlignment.Left
    G2L.UsernameLabel.TextScaled = true
    G2L.UsernameLabel.BackgroundTransparency = 1
    G2L.UsernameLabel.TextSize = 14
    G2L.UsernameLabel.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
    G2L.UsernameLabel.TextColor3 = self.config.TextColor
    G2L.UsernameLabel.Size = UDim2.new(0, 96, 0, 15)
    G2L.UsernameLabel.Text = localPlayer.Name
    G2L.UsernameLabel.Position = UDim2.new(0, 55, userSectionYPos + 0.005, 0)

    G2L.DateLabel = Instance.new("TextLabel", leftPanel)
    G2L.DateLabel.Name = "DateLabel"
    G2L.DateLabel.TextWrapped = true
    G2L.DateLabel.BorderSizePixel = 0
    G2L.DateLabel.TextXAlignment = Enum.TextXAlignment.Left
    G2L.DateLabel.TextScaled = true
    G2L.DateLabel.BackgroundTransparency = 1
    G2L.DateLabel.TextSize = 12
    G2L.DateLabel.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
    G2L.DateLabel.TextColor3 = self.config.MutedTextColor
    G2L.DateLabel.Size = UDim2.new(0, 96, 0, 15)
    G2L.DateLabel.Text = os.date("%d.%m.%Y")
    G2L.DateLabel.Position = UDim2.new(0, 55, userSectionYPos + 0.035, 0)
    
    -- Загрузка аватара
    local success, userId = pcall(function() return Players:GetUserIdFromNameAsync(localPlayer.Name) end)
    if success and userId then
        local thumbType = Enum.ThumbnailType.HeadShot
        local thumbSize = Enum.ThumbnailSize.Size48x48
        local content, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
        if isReady then
            G2L.UserAvatarFrame.Image = content
        end
    end

    -- Правая панель (Контент)
    local rightPanel = Instance.new("Frame", G2L.MainFrame)
    rightPanel.Name = "RightPanel"
    rightPanel.BackgroundTransparency = 1
    rightPanel.Size = UDim2.new(1, -170, 1, 0) -- Ширина 100% - 170, высота 100%
    rightPanel.Position = UDim2.new(0, 170, 0, 0)

    -- Разделитель между панелями
    local panelDivider = Instance.new("Frame", G2L.MainFrame)
    panelDivider.Name = "PanelDivider"
    panelDivider.BackgroundColor3 = self.config.AccentColor
    panelDivider.BackgroundTransparency = 0.9
    panelDivider.BorderSizePixel = 0
    panelDivider.Size = UDim2.new(0, 1, 1, 0)
    panelDivider.Position = UDim2.new(0, 170, 0, 0)

    -- Статус текущего раздела (вверху правой панели)
    G2L.CurrentSectionLabel = Instance.new("TextLabel", rightPanel)
    G2L.CurrentSectionLabel.Name = "CurrentSectionLabel"
    G2L.CurrentSectionLabel.TextWrapped = true
    G2L.CurrentSectionLabel.BorderSizePixel = 0
    G2L.CurrentSectionLabel.TextXAlignment = Enum.TextXAlignment.Left
    G2L.CurrentSectionLabel.TextScaled = true
    G2L.CurrentSectionLabel.BackgroundTransparency = 1
    G2L.CurrentSectionLabel.TextSize = 18
    G2L.CurrentSectionLabel.FontFace = Font.new("rbxasset://fonts/families/Arial.json", Enum.FontWeight.Bold)
    G2L.CurrentSectionLabel.TextColor3 = self.config.TextColor
    G2L.CurrentSectionLabel.Size = UDim2.new(0, 170, 0, 25)
    G2L.CurrentSectionLabel.Text = "Welcome"
    G2L.CurrentSectionLabel.Position = UDim2.new(0.03, 0, 0.03, 0)
    
    local sectionDivider = Instance.new("Frame", rightPanel)
    sectionDivider.Name = "SectionDivider"
    sectionDivider.BackgroundColor3 = self.config.AccentColor
    sectionDivider.BackgroundTransparency = 0.8
    sectionDivider.BorderSizePixel = 0
    sectionDivider.Size = UDim2.new(1, -30, 0, 1)
    sectionDivider.Position = UDim2.new(0.03, 0, 0.1, 0)

    -- Контейнер для фреймов категорий (где будут модули)
    G2L.CategoryFramesContainer = Instance.new("Frame", rightPanel)
    G2L.CategoryFramesContainer.Name = "CategoryFramesContainer"
    G2L.CategoryFramesContainer.BackgroundTransparency = 1
    G2L.CategoryFramesContainer.Size = UDim2.new(1, -30, 1, -80) -- Примерные размеры, отступы
    G2L.CategoryFramesContainer.Position = UDim2.new(0.03, 0, 0.12, 0)

    -- Контейнер для уведомлений
    G2L.NotificationsContainer = Instance.new("Frame", G2L.ScreenGui)
    G2L.NotificationsContainer.Name = "NotificationsContainer"
    G2L.NotificationsContainer.BackgroundTransparency = 1
    G2L.NotificationsContainer.Size = UDim2.new(0.2, 0, 0.4, 0) -- В правом нижнем углу
    G2L.NotificationsContainer.Position = UDim2.new(0.79, 0, 0.59, 0)

    local notificationsLayout = Instance.new("UIListLayout", G2L.NotificationsContainer)
    notificationsLayout.Padding = UDim.new(0, 6)
    notificationsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    notificationsLayout.FillDirection = Enum.FillDirection.Vertical
    notificationsLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    notificationsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right

    -- Управление видимостью GUI
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == self.config.OpenKey then
            self.mainGuiVisible = not self.mainGuiVisible
            G2L.MainFrame.Visible = self.mainGuiVisible
            if G2L.WatermarkFrame then G2L.WatermarkFrame.Visible = self.mainGuiVisible and G2L.WatermarkFrame.Enabled end -- Доп. проверка на Enabled
            if G2L.TargetHudFrame then G2L.TargetHudFrame.Visible = self.mainGuiVisible and G2L.TargetHudFrame.Enabled end
            if G2L.RenderGifFrame then G2L.RenderGifFrame.Visible = self.mainGuiVisible and G2L.RenderGifFrame.Enabled end
            if G2L.AmbianceOverlay then G2L.AmbianceOverlay.Visible = self.mainGuiVisible and G2L.AmbianceOverlay.Enabled end

        end
    end)
    
    -- Инициализация звуков
    self.soundToggleOn = Instance.new("Sound", G2L.ScreenGui)
    self.soundToggleOn.SoundId = SOUND_TOGGLE_ON
    self.soundToggleOff = Instance.new("Sound", G2L.ScreenGui)
    self.soundToggleOff.SoundId = SOUND_TOGGLE_OFF

    return self
end

-- [[ API Методы ]]

function ExpaLib:AddCategory(categoryName)
    if self.categories[categoryName] then
        warn("ExpaLib: Категория '" .. categoryName .. "' уже существует.")
        return
    end

    local categoryFrame = Instance.new("ScrollingFrame", G2L.CategoryFramesContainer) -- Используем ScrollingFrame
    categoryFrame.Name = categoryName .. "Frame"
    categoryFrame.Visible = false -- Скрыта по умолчанию
    categoryFrame.BackgroundTransparency = 1
    categoryFrame.Size = UDim2.new(1, 0, 1, 0)
    categoryFrame.CanvasSize = UDim2.new(0,0,0,0) -- Автоматически изменится UIListLayout
    categoryFrame.ScrollBarThickness = 6
    categoryFrame.ScrollBarImageColor3 = self.config.AccentColor

    local categoryLayout = Instance.new("UIListLayout", categoryFrame)
    categoryLayout.Padding = UDim.new(0, 10)
    categoryLayout.SortOrder = Enum.SortOrder.LayoutOrder
    categoryLayout.FillDirection = Enum.FillDirection.Vertical
    categoryLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left -- Модули будут слева

    local categoryButton = Instance.new("TextButton", G2L.NavigationFrame)
    categoryButton.Name = categoryName .. "Button"
    categoryButton.Text = categoryName
    categoryButton.Size = UDim2.new(1, 0, 0, 33) -- Ширина 100% от родителя (NavigationFrame)
    categoryButton.BackgroundColor3 = self.config.SecondaryAccentColor
    categoryButton.TextColor3 = self.config.TextColor
    categoryButton.Font = Enum.Font.Arial
    categoryButton.TextSize = 14
    categoryButton.BackgroundTransparency = 1 -- Неактивна

    local buttonCorner = Instance.new("UICorner", categoryButton)
    buttonCorner.CornerRadius = UDim.new(0, 6)
    local buttonStroke = Instance.new("UIStroke", categoryButton)
    buttonStroke.Color = self.config.SecondaryAccentColor
    buttonStroke.Transparency = 0.74
    buttonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    buttonStroke.Enabled = false -- Неактивна

    categoryButton.MouseButton1Click:Connect(function()
        if self.activeCategoryFrame then
            self.activeCategoryFrame.Visible = false
            local oldButton = self.categories[self.activeCategoryFrame.Name:gsub("Frame", "")].button
            if oldButton then
                 oldButton.BackgroundTransparency = 1
                 oldButton:FindFirstChildOfClass("UIStroke").Enabled = false
            end
        end
        categoryFrame.Visible = true
        self.activeCategoryFrame = categoryFrame
        G2L.CurrentSectionLabel.Text = categoryName

        categoryButton.BackgroundTransparency = 0.85
        buttonStroke.Enabled = true

        -- Автоматический размер CanvasSize для ScrollingFrame
        local items = categoryFrame:GetChildren()
        local totalHeight = 0
        local padding = categoryLayout.Padding.Offset
        for _, item in ipairs(items) do
            if item:IsA("GuiObject") then
                totalHeight = totalHeight + item.AbsoluteSize.Y + padding
            end
        end
        categoryFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
    end)
    
    self.categories[categoryName] = {button = categoryButton, frame = categoryFrame, modules = {}}

    -- Активируем первую добавленную категорию
    if not self.activeCategoryFrame then
        categoryButton:Activated() -- Имитируем клик
    end
    
    return categoryFrame -- Возвращаем фрейм категории для добавления модулей
end


function ExpaLib:AddModule(categoryName, moduleName, moduleIcon)
    local categoryData = self.categories[categoryName]
    if not categoryData then
        warn("ExpaLib: Категория '" .. categoryName .. "' не найдена для добавления модуля.")
        return nil
    end
    if categoryData.modules[moduleName] then
        warn("ExpaLib: Модуль '" .. moduleName .. "' уже существует в категории '" .. categoryName .. "'.")
        return categoryData.modules[moduleName].frame
    end

    local moduleFrame = Instance.new("Frame", categoryData.frame)
    moduleFrame.Name = moduleName .. "Module"
    moduleFrame.BackgroundColor3 = self.config.ModuleBackgroundColor
    moduleFrame.Size = UDim2.new(0, 265, 0, 40) -- Начальная высота, будет увеличиваться
    moduleFrame.BorderSizePixel = 0
    
    local moduleCorner = Instance.new("UICorner", moduleFrame)
    moduleCorner.CornerRadius = UDim.new(0, 11)
    local moduleStroke = Instance.new("UIStroke", moduleFrame)
    moduleStroke.Transparency = 0.93
    moduleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    moduleStroke.Color = self.config.TextColor

    local icon = Instance.new("ImageLabel", moduleFrame)
    icon.Name = "ModuleIcon"
    icon.BackgroundTransparency = 1
    icon.Size = UDim2.new(0, 25, 0, 25)
    icon.Position = UDim2.new(0.0415, 0, 0.15, 0) -- Динамическое позиционирование по центру высоты
    icon.Image = moduleIcon or DEFAULT_ICON
    icon.ImageColor3 = self.config.AccentColor

    local nameLabel = Instance.new("TextLabel", moduleFrame)
    nameLabel.Name = "ModuleNameLabel"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(0, 170, 0, 15)
    nameLabel.Position = UDim2.new(0.178, 0, 0.3, 0) -- Динамическое позиционирование
    nameLabel.Font = Enum.Font.Arial
    nameLabel.Text = moduleName
    nameLabel.TextColor3 = self.config.TextColor
    nameLabel.TextScaled = true
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left

    local contentFrame = Instance.new("Frame", moduleFrame)
    contentFrame.Name = "ModuleContentFrame"
    contentFrame.BackgroundColor3 = self.config.ModuleContentColor
    contentFrame.Size = UDim2.new(0.96, 0, 0, 0) -- Ширина почти 100%, высота 0, будет расти
    contentFrame.Position = UDim2.new(0.02, 0, 0, 40) -- Под заголовком модуля
    contentFrame.BorderSizePixel = 0
    contentFrame.ClipsDescendants = true -- Чтобы контент не вылезал до увеличения

    local contentCorner = Instance.new("UICorner", contentFrame)
    contentCorner.CornerRadius = UDim.new(0, 8)
    
    local contentLayout = Instance.new("UIListLayout", contentFrame)
    contentLayout.Padding = UDim.new(0, 8)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    categoryData.modules[moduleName] = {frame = moduleFrame, contentFrame = contentFrame, contentLayout = contentLayout, currentYOffset = 5} -- Добавляем отступ

    -- Функция для обновления высоты модуля
    local function updateModuleHeight()
        local totalContentHeight = 5 -- Начальный отступ
        for _, child in ipairs(contentFrame:GetChildren()) do
            if child:IsA("GuiObject") and child ~= contentLayout then
                totalContentHeight = totalContentHeight + child.AbsoluteSize.Y + contentLayout.Padding.Offset
            end
        end
        totalContentHeight = math.max(10, totalContentHeight - contentLayout.Padding.Offset + 5) -- Минимальная высота и конечный отступ

        contentFrame.Size = UDim2.new(0.96, 0, 0, totalContentHeight)
        moduleFrame.Size = UDim2.new(0, 265, 0, 40 + totalContentHeight + 5) -- +5 для отступа снизу
        
        -- Обновляем CanvasSize для ScrollingFrame категории
        local items = categoryData.frame:GetChildren()
        local catTotalHeight = 0
        local catPadding = categoryData.frame:FindFirstChildOfClass("UIListLayout").Padding.Offset
        for _, item in ipairs(items) do
            if item:IsA("GuiObject") and item:IsA("Frame") then -- Только фреймы модулей
                catTotalHeight = catTotalHeight + item.AbsoluteSize.Y + catPadding
            end
        end
        categoryData.frame.CanvasSize = UDim2.new(0, 0, 0, math.max(categoryData.frame.AbsoluteSize.Y, catTotalHeight))
    end
    
    contentLayout.Changed:Connect(function(property)
        if property == "AbsoluteContentSize" then
            updateModuleHeight()
        end
    end)
    
    -- Первичное обновление высоты
    task.wait() -- Дать элементам отрисоваться
    updateModuleHeight()

    local moduleApi = {}
    moduleApi.AddToggle = function(optionName, description, initialState, callback)
        return self:_addToggle(categoryData.modules[moduleName], optionName, description, initialState, callback, updateModuleHeight)
    end
    moduleApi.AddDropdown = function(optionName, description, optionsArray, initialValue, callback)
        return self:_addDropdown(categoryData.modules[moduleName], optionName, description, optionsArray, initialValue, callback, updateModuleHeight)
    end
    moduleApi.AddButton = function(optionName, description, buttonText, callback)
        return self:_addButton(categoryData.modules[moduleName], optionName, description, buttonText, callback, updateModuleHeight)
    end
    -- Добавить другие типы элементов: AddSlider, AddTextInput и т.д.

    return moduleApi
end

function ExpaLib:_addOptionBase(moduleData, optionName, description, updateModuleHeightCallback)
    local optionContainer = Instance.new("Frame", moduleData.contentFrame)
    optionContainer.Name = optionName .. "Option"
    optionContainer.BackgroundTransparency = 1
    optionContainer.Size = UDim2.new(0.9, 0, 0, 50) -- Примерная высота, будет уточнена
    optionContainer.LayoutOrder = moduleData.currentYOffset
    moduleData.currentYOffset = moduleData.currentYOffset + 1

    local nameLabel = Instance.new("TextLabel", optionContainer)
    nameLabel.Name = "OptionNameLabel"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(0.6, -5, 0, 15) -- 60% ширины минус отступ
    nameLabel.Position = UDim2.new(0, 0, 0, 5)
    nameLabel.Font = Enum.Font.Arial
    nameLabel.Text = optionName
    nameLabel.TextColor3 = self.config.TextColor
    nameLabel.TextSize = 14
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left

    local descLabel = Instance.new("TextLabel", optionContainer)
    descLabel.Name = "OptionDescriptionLabel"
    descLabel.BackgroundTransparency = 1
    descLabel.Size = UDim2.new(0.6, -5, 0, 25)
    descLabel.Position = UDim2.new(0, 0, 0, 20)
    descLabel.Font = Enum.Font.Arial
    descLabel.Text = description
    descLabel.TextColor3 = self.config.MutedTextColor
    descLabel.TextSize = 11
    descLabel.TextWrapped = true
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextYAlignment = Enum.VerticalYAlignment.Top
    
    task.defer(updateModuleHeightCallback) -- Отложить вызов, чтобы UI успел обновиться
    return optionContainer, nameLabel, descLabel
end

function ExpaLib:_addToggle(moduleData, optionName, description, initialState, callback, updateModuleHeightCallback)
    local optionContainer, _, _ = self:_addOptionBase(moduleData, optionName, description, updateModuleHeightCallback)
    optionContainer.Size = UDim2.new(0.9, 0, 0, 40) -- Фиксированная высота для toggle

    local toggleButton = Instance.new("ImageButton", optionContainer)
    toggleButton.Name = "ToggleButton"
    toggleButton.BackgroundTransparency = 1
    toggleButton.Image = "rbxassetid://126547299874610" -- Галочка
    toggleButton.Size = UDim2.new(0, 15, 0, 15)
    toggleButton.Position = UDim2.new(1, -25, 0.5, -7.5) -- Справа по центру
    toggleButton.ImageTransparency = if initialState then 0 else 1
    
    local toggleBg = Instance.new("Frame", toggleButton)
    toggleBg.Name = "ToggleBackground"
    toggleBg.BackgroundColor3 = self.config.AccentColor
    toggleBg.BorderSizePixel = 0
    toggleBg.Size = UDim2.new(1,0,1,0)
    toggleBg.ZIndex = toggleButton.ZIndex -1
    
    local toggleCorner = Instance.new("UICorner", toggleBg)
    toggleCorner.CornerRadius = UDim.new(0, 3)
    local toggleStroke = Instance.new("UIStroke", toggleBg)
    toggleStroke.Transparency = 0.77
    toggleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    toggleStroke.Color = self.config.TextColor

    local currentState = initialState or false
    toggleButton.MouseButton1Click:Connect(function()
        currentState = not currentState
        toggleButton.ImageTransparency = if currentState then 0 else 1
        if currentState then self.soundToggleOn:Play() else self.soundToggleOff:Play() end
        if callback then
            local success, err = pcall(callback, currentState)
            if not success then
                self:ShowNotification("Script Error", "Error in " .. moduleData.frame.Name .. "/" .. optionName .. ": " .. tostring(err), "error")
            end
        end
        self:ShowNotification(moduleData.frame.Name:gsub("Module",""), optionName .. (currentState and " enabled" or " disabled"))
    end)
    task.defer(updateModuleHeightCallback)
    return toggleButton -- Можно вернуть, если нужно будет управлять им извне
end

function ExpaLib:_addDropdown(moduleData, optionName, description, optionsArray, initialValue, callback, updateModuleHeightCallback)
    local optionContainer, _, _ = self:_addOptionBase(moduleData, optionName, description, updateModuleHeightCallback)
    optionContainer.Size = UDim2.new(0.9, 0, 0, 40)

    local dropdownButton = Instance.new("TextButton", optionContainer)
    dropdownButton.Name = "DropdownButton"
    dropdownButton.Size = UDim2.new(0, 76, 0, 23)
    dropdownButton.Position = UDim2.new(1, -86, 0.5, -11.5) -- Справа, с отступом
    dropdownButton.BackgroundColor3 = self.config.ModuleContentColor -- Темнее фона модуля
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

    local listFrame = Instance.new("Frame", dropdownButton) -- Список внутри кнопки для позиционирования
    listFrame.Name = "DropdownList"
    listFrame.BackgroundTransparency = 1 -- Прозрачный контейнер
    listFrame.Size = UDim2.new(1, 0, 0, #optionsArray * 29) -- Высота зависит от кол-ва опций
    listFrame.Position = UDim2.new(0, 0, 1, 5) -- Под кнопкой с отступом
    listFrame.Visible = false
    listFrame.ZIndex = dropdownButton.ZIndex + 1 -- Поверх кнопки
    listFrame.ClipsDescendants = true

    local listLayout = Instance.new("UIListLayout", listFrame)
    listLayout.Padding = UDim.new(0, 2)
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
        itemStroke.Transparency = 0.85
        itemStroke.Color = self.config.TextColor

        itemButton.MouseEnter:Connect(function() itemButton.BackgroundTransparency = 0.5 end)
        itemButton.MouseLeave:Connect(function() itemButton.BackgroundTransparency = 0 end)

        itemButton.MouseButton1Click:Connect(function()
            dropdownButton.Text = tostring(optValue)
            listFrame.Visible = false
            if callback then
                local success, err = pcall(callback, optValue)
                if not success then
                     self:ShowNotification("Script Error", "Error in " .. moduleData.frame.Name .. "/" .. optionName .. ": " .. tostring(err), "error")
                end
            end
            self:ShowNotification(moduleData.frame.Name:gsub("Module",""), optionName .. " set to " .. tostring(optValue))
        end)
    end

    dropdownButton.MouseButton1Click:Connect(function()
        listFrame.Visible = not listFrame.Visible
    end)
    task.defer(updateModuleHeightCallback)
    return dropdownButton
end

function ExpaLib:_addButton(moduleData, optionName, description, buttonText, callback, updateModuleHeightCallback)
    local optionContainer, _, _ = self:_addOptionBase(moduleData, optionName, description, updateModuleHeightCallback)
    optionContainer.Size = UDim2.new(0.9, 0, 0, 40)

    local actionButton = Instance.new("TextButton", optionContainer)
    actionButton.Name = "ActionButton"
    actionButton.Size = UDim2.new(0, 76, 0, 23)
    actionButton.Position = UDim2.new(1, -86, 0.5, -11.5)
    actionButton.BackgroundColor3 = self.config.AccentColor
    actionButton.Text = buttonText or "Execute"
    actionButton.TextColor3 = self.config.TextColor
    actionButton.Font = Enum.Font.SourceSans
    actionButton.TextSize = 14

    local btnCorner = Instance.new("UICorner", actionButton)
    btnCorner.CornerRadius = UDim.new(0, 3)
    
    actionButton.MouseButton1Click:Connect(function()
        if callback then
            local success, err = pcall(callback)
            if not success then
                self:ShowNotification("Script Error", "Error in " .. moduleData.frame.Name .. "/" .. optionName .. ": " .. tostring(err), "error")
            end
        end
        self:ShowNotification(moduleData.frame.Name:gsub("Module",""), optionName .. " executed.")
    end)
    task.defer(updateModuleHeightCallback)
    return actionButton
end


function ExpaLib:ShowNotification(title, message, messageType) -- messageType: "info", "warning", "error"
    createNotification(title, message, messageType)
end

function ExpaLib:Destroy()
    if G2L.ScreenGui then
        G2L.ScreenGui:Destroy()
    end
    -- Очистить все внутренние ссылки и состояния
    G2L = {}
    self.categories = {}
    self.activeCategoryFrame = nil
    -- Остановить любые активные циклы, если они есть
end

--[[ Функции для управления дополнительными HUD элементами (опционально) ]]

function ExpaLib:EnableWatermark(initialVisibility, transparency)
    if G2L.WatermarkFrame then G2L.WatermarkFrame:Destroy() end

    G2L.WatermarkFrame = Instance.new("Frame", G2L.ScreenGui)
    G2L.WatermarkFrame.Name = "WatermarkFrame"
    G2L.WatermarkFrame.BackgroundColor3 = self.config.BackgroundColor
    G2L.WatermarkFrame.BorderSizePixel = 0
    G2L.WatermarkFrame.Size = UDim2.new(0, 254, 0, 29)
    G2L.WatermarkFrame.Position = UDim2.new(0.02, 0, 0.02, 0) -- Левый верхний угол
    G2L.WatermarkFrame.Visible = initialVisibility == nil and self.mainGuiVisible or initialVisibility -- По умолчанию видимо, если главный GUI видим
    G2L.WatermarkFrame.BackgroundTransparency = transparency or 0.1
    G2L.WatermarkFrame.Enabled = true -- Для отслеживания состояния при открытии/закрытии главного GUI
    makeDraggable(G2L.WatermarkFrame)

    local corner = Instance.new("UICorner", G2L.WatermarkFrame)
    corner.CornerRadius = UDim.new(0, 6)
    
    local titleLabel = Instance.new("TextLabel", G2L.WatermarkFrame)
    titleLabel.Name = "WatermarkTitle"
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(0, 0, 0, 20)
    titleLabel.Position = UDim2.new(0.05, 0, 0.5, -10)
    titleLabel.Text = self.config.Title
    titleLabel.Font = Enum.Font.SourceSansSemibold
    titleLabel.TextSize = 14
    titleLabel.TextColor3 = self.config.AccentColor
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local pingLabel = Instance.new("TextLabel", G2L.WatermarkFrame)
    pingLabel.Name = "PingLabel"
    pingLabel.BackgroundTransparency = 1
    pingLabel.Size = UDim2.new(0, 60, 0, 20)
    pingLabel.Position = UDim2.new(1, -120, 0.5, -10)
    pingLabel.Text = "Ping: N/A"
    pingLabel.Font = Enum.Font.SourceSans
    pingLabel.TextSize = 12
    pingLabel.TextColor3 = self.config.TextColor
    pingLabel.TextXAlignment = Enum.TextXAlignment.Right
    
    local fpsLabel = Instance.new("TextLabel", G2L.WatermarkFrame)
    fpsLabel.Name = "FPSLabel"
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Size = UDim2.new(0, 60, 0, 20)
    fpsLabel.Position = UDim2.new(1, -60, 0.5, -10)
    fpsLabel.Text = "FPS: N/A"
    fpsLabel.Font = Enum.Font.SourceSans
    fpsLabel.TextSize = 12
    fpsLabel.TextColor3 = self.config.TextColor
    fpsLabel.TextXAlignment = Enum.TextXAlignment.Right

    -- Обновление пинга и FPS
    RunService.RenderStepped:Connect(function()
        if G2L.WatermarkFrame and G2L.WatermarkFrame.Visible then
            local ping = math.floor(Players.LocalPlayer:GetNetworkPing() * 1000)
            pingLabel.Text = "Ping: " .. ping .. "ms"
            local fps = math.floor(workspace:GetRealPhysicsFPS())
            fpsLabel.Text = "FPS: " .. fps
        end
    end)
end

function ExpaLib:SetWatermarkVisibility(visible)
    if G2L.WatermarkFrame then
        G2L.WatermarkFrame.Visible = visible
        G2L.WatermarkFrame.Enabled = visible
    end
end


-- TODO: Добавить методы для TargetHud, RenderGifFrame, AmbianceOverlay по аналогии
-- Например: ExpaLib:EnableTargetHud(initialVisibility, transparency)
--          ExpaLib:SetTargetHudVisibility(visible)

return ExpaLib
