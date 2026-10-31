# vapetweaker
<img width="267" height="130" alt="image" src="https://github.com/user-attachments/assets/feebc09f-98f5-4825-b864-95c7e633e976" />


A wrapper for VapeV4ForRoblox by 7GrandDad to make your own custom modules.<br>
```lua
local vapetweaker = loadstring(game:HttpGet("https://raw.githubusercontent.com/water5202/vapetweaker/refs/heads/main/src/wrapper.lua"))()
```
It preloads most libraries that vape uses (vapetweaker.getvapeasset, you get the picture).<br>
Use it like any other, heres an example
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/main/NewMainScript.lua", true))()
local vapetweaker = loadstring(game:HttpGet("https://raw.githubusercontent.com/water5202/vapetweaker/refs/heads/main/src/wrapper.lua"))()

local entitylib = vapetweaker.entitylib
local inputService = cloneref(game:GetService("UserInputService"))
local InfiniteJump

InfiniteJump = vapetweaker.vape.Categories.Blatant:CreateModule({
    Name = "InfiniteJump", 
    Function = function(value)
        if value then 
            InfiniteJump:Clean(inputService.JumpRequest:Connect(function() 
                if entitylib.isAlive then 
                    local hum = entitylib.character.Humanoid 
                    hum:ChangeState(Enum.HumanoidStateType.Jumping) 
                end 
            end))
        end 
    end, 
    Tooltip = "Lets you jump in midair."
})
```
# Features
Module deletion is another thing vapetweaker can accomplish<br>
```lua
vapetweaker.DeleteModule("SomeModule")
```
