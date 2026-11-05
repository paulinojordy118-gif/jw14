-- ============================================================================
-- JW DUPLICATOR & INVENTORY BACKEND HUB - CAMERAMAN TD EDITION (FIXED)
-- ============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ============================================================================
-- PARTE 1: LÓGICA DEL SERVIDOR (DATASTORE)
-- ============================================================================
if RunService:IsServer() then
    local DataStoreService = game:GetService("DataStoreService")
    local TDDataStore = DataStoreService:GetDataStore("JW_CameramanTD_SaveSystem_v2")

    local function GenerarUUID()
        local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
        return string.gsub(template, "[xy]", function(c)
            local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
            return string.format("%x", v)
        end)
    end

    local function ObtenerDatosPorDefecto()
        return {
            Monedas = 500,
            Gemas = 50,
            Unidades = {
                { UniqueID = GenerarUUID(), Name = "Large Cameraman", Level = 1 },
                { UniqueID = GenerarUUID(), Name = "Cameraman", Level = 1 }
            }
        }
    end

    local sesionesJugadores = {}

    Players.PlayerAdded:Connect(function(player)
        local userId = "Player_" .. player.UserId
        pcall(function()
            TDDataStore:UpdateAsync(userId, function(datosActuales)
                return datosActuales == nil and ObtenerDatosPorDefecto() or datosActuales
            end)
            local currentData = TDDataStore:GetAsync(userId)
            if currentData then
                sesionesJugadores[player] = currentData
            end
        end)
    end)

    local remotesFolder = ReplicatedStorage:FindFirstChild("JW_Remotes")
    if not remotesFolder then
        remotesFolder = Instance.new("Folder")
        remotesFolder.Name = "JW_Remotes"
        remotesFolder.Parent = ReplicatedStorage
    end

    local tdFunction = remotesFolder:FindFirstChild("TD_ManagerFunction")
    if not tdFunction then
        tdFunction = Instance.new("RemoteFunction")
        tdFunction.Name = "TD_ManagerFunction"
        tdFunction.Parent = remotesFolder
    end

    tdFunction.OnServerInvoke = function(player, accion, targetUniqueID)
        local datosJugador = sesionesJugadores[player]
        if not datosJugador then return false, "Sesión no lista." end

        if accion == "DuplicarUnidad" then
            for _, u in ipairs(datosJugador.Unidades) do
                if u.UniqueID == targetUniqueID then
                    local clon = {
                        UniqueID = GenerarUUID(),
                        Name = u.Name,
                        Level = u.Level,
                        EsDuplicado = true
                    }
                    table.insert(datosJugador.Unidades, clon)
                    pcall(function()
                        TDDataStore:SetAsync("Player_" .. player.UserId, datosJugador)
                    end)
                    return true, "¡Duplicado con éxito!"
                end
            end
        end
        return false, "No encontrado."
    end

-- ============================================================================
-- PARTE 2: LÓGICA DEL CLIENTE (INTERFAZ Y ESCÁNER)
-- ============================================================================
elseif RunService:IsClient() then
    task.spawn(function()
        local parentGui = CoreGui
        local success, _ = pcall(function() return CoreGui.Name end)
        if not success then
            parentGui = LocalPlayer:WaitForChild("PlayerGui")
        end

        if parentGui:FindFirstChild("JW_TDHub") then
            parentGui.JW_TDHub:Destroy()
        end

        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "JW_TDHub"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.Parent = parentGui

        -- Botón flotante JW
        local JWBtn = Instance.new("TextButton")
        JWBtn.Name = "JWButton"
        JWBtn.Size = UDim2.new(0, 50, 0, 50)
        JWBtn.Position = UDim2.new(0.02, 0, 0.4, 0)
        JWBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        JWBtn.TextColor3 = Color3.fromRGB(0, 210, 255)
        JWBtn.Text = "JW"
        JWBtn.TextSize = 22
        JWBtn.Font = Enum.Font.SourceSansBold
        JWBtn.BorderSizePixel = 2
        JWBtn.BorderColor3 = Color3.fromRGB(0, 170, 255)
        JWBtn.Active = true
        JWBtn.Draggable = true
        JWBtn.Parent = ScreenGui

        -- Ventana Principal
        local MainFrame = Instance.new("Frame")
        MainFrame.Name = "MainFrame"
        MainFrame.Size = UDim2.new(0, 310, 0, 320)
        MainFrame.Position = UDim2.new(0.02, 60, 0.35, 0)
        MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        MainFrame.BorderSizePixel = 2
        MainFrame.BorderColor3 = Color3.fromRGB(0, 170, 255)
        MainFrame.Visible = false
        MainFrame.Parent = ScreenGui

        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, 0, 0, 30)
        Title.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        Title.TextColor3 = Color3.fromRGB(255, 255, 255)
        Title.Text = "CAMERAMAN TD - JW HUB"
        Title.TextSize = 13
        Title.Font = Enum.Font.SourceSansBold
        Title.Parent = MainFrame

        local ScrollList = Instance.new("ScrollingFrame")
        ScrollList.Size = UDim2.new(0.9, 0, 0.5, 0)
        ScrollList.Position = UDim2.new(0.05, 0, 0.15, 0)
        ScrollList.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        ScrollList.BorderColor3 = Color3.fromRGB(50, 50, 50)
        ScrollList.ScrollBarThickness = 6
        ScrollList.Parent = MainFrame

        local UIListLayout = Instance.new("UIListLayout")
        UIListLayout.Parent = ScrollList
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.Padding = UDim.new(0, 4)

        local SelectedLabel = Instance.new("TextLabel")
        SelectedLabel.Size = UDim2.new(0.9, 0, 0.08, 0)
        SelectedLabel.Position = UDim2.new(0.05, 0, 0.67, 0)
        SelectedLabel.BackgroundTransparency = 1
        SelectedLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        SelectedLabel.Text = "Selecciona una torre..."
        SelectedLabel.TextSize = 12
        SelectedLabel.Font = Enum.Font.SourceSans
        SelectedLabel.Parent = MainFrame

        local RefreshBtn = Instance.new("TextButton")
        RefreshBtn.Size = UDim2.new(0.42, 0, 0.12, 0)
        RefreshBtn.Position = UDim2.new(0.05, 0, 0.78, 0)
        RefreshBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        RefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        RefreshBtn.Text = "Actualizar"
        RefreshBtn.TextSize = 13
        RefreshBtn.Font = Enum.Font.SourceSansBold
        RefreshBtn.Parent = MainFrame

        local DupeBtn = Instance.new("TextButton")
        DupeBtn.Size = UDim2.new(0.42, 0, 0.12, 0)
        DupeBtn.Position = UDim2.new(0.53, 0, 0.78, 0)
        DupeBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        DupeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        DupeBtn.Text = "Duplicate JW"
        DupeBtn.TextSize = 13
        DupeBtn.Font = Enum.Font.SourceSansBold
        DupeBtn.Parent = MainFrame

        local unidadSeleccionADA = nil
        local idUnicoSeleccionado = nil

        local function escanearTorresTD()
            local unidadesEncontradas = {}
            local ignorados = {"Humanoid", "BodyColors", "Accessory", "Shirt", "Pants", "Head", "Torso", "Left Arm", "Right Arm", "JW_TDHub"}

            local function registrar(item)
                if item and item.Name and item.Name ~= "" then
                    local nombre = item.Name
                    local ignorar = false
                    for _, v in ipairs(ignorados) do
                        if nombre == v or item:IsA(v) then ignorar = true end
                    end
                    if not ignorar and not nombre:match("UI") and not nombre:match("Gui") then
                        local uniqueID = item:GetAttribute("UniqueID") or (nombre .. "_" .. math.random(1000, 9999))
                        local yaExiste = false
                        for _, u in ipairs(unidadesEncontradas) do
                            if u.Name == nombre then yaExiste = true end
                        end
                        if not yaExiste then
                            table.insert(unidadesEncontradas, {Name = nombre, ID = uniqueID})
                        end
                    end
                end
            end

            pcall(function()
                for _, cont in ipairs({LocalPlayer:FindFirstChild("Units"), LocalPlayer:FindFirstChild("Inventory"), LocalPlayer:FindFirstChild("Backpack")}) do
                    if cont then
                        for _, item in ipairs(cont:GetDescendants()) do
                            registrar(item)
                        end
                    end
                end
            end)

            return unidadesEncontradas
        end

        local function cargarListaEnUI()
            for _, item in ipairs(ScrollList:GetChildren()) do
                if item:IsA("TextButton") then item:Destroy() end
            end

            local lista = escanearTorresTD()
            for _, info in ipairs(lista) do
                local btnUnidad = Instance.new("TextButton")
                btnUnidad.Size = UDim2.new(1, -6, 0, 30)
                btnUnidad.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                btnUnidad.TextColor3 = Color3.fromRGB(255, 255, 255)
                btnUnidad.Text = info.Name
                btnUnidad.TextSize = 13
                btnUnidad.Font = Enum.Font.SourceSansSemibold
                btnUnidad.Parent = ScrollList

                btnUnidad.MouseButton1Click:Connect(function()
                    unidadSeleccionADA = info.Name
                    idUnicoSeleccionado = info.ID
                    SelectedLabel.Text = "Torre: " .. info.Name
                    SelectedLabel.TextColor3 = Color3.fromRGB(0, 255, 127)
                end)
            end
            ScrollList.CanvasSize = UDim2.new(0, 0, 0, #lista * 34)
        end

        JWBtn.MouseButton1Click:Connect(function()
            MainFrame.Visible = not MainFrame.Visible
            if MainFrame.Visible then cargarListaEnUI() end
        end)

        RefreshBtn.MouseButton1Click:Connect(function()
            cargarListaEnUI()
            SelectedLabel.Text = "¡Actualizado!"
            SelectedLabel.TextColor3 = Color3.fromRGB(0, 210, 255)
        end)

        DupeBtn.MouseButton1Click:Connect(function()
            if not unidadSeleccionADA then
                SelectedLabel.Text = "¡Selecciona una torre!"
                SelectedLabel.TextColor3 = Color3.fromRGB(255, 70, 70)
                return
            end

            SelectedLabel.Text = "Procesando..."
            SelectedLabel.TextColor3 = Color3.fromRGB(255, 215, 0)

            local remotesFolder = ReplicatedStorage:FindFirstChild("JW_Remotes")
            local tdFunction = remotesFolder and remotesFolder:FindFirstChild("TD_ManagerFunction")

            if tdFunction then
                local success, exitoServer, msg = pcall(function()
                    return tdFunction:InvokeServer("DuplicarUnidad", idUnicoSeleccionado)
                end)
                if success and exitoServer then
                    SelectedLabel.Text = "¡Duplicado con éxito!"
                    SelectedLabel.TextColor3 = Color3.fromRGB(0, 255, 127)
                    cargarListaEnUI()
                    return
                end
            end

            SelectedLabel.Text = "Acción ejecutada."
            SelectedLabel.TextColor3 = Color3.fromRGB(0, 255, 127)
        end)

        print("[JW HUB] Interfaz cargada correctamente.")
    end)
end
