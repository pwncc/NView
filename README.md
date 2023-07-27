# NView

## [WHAT?]
*what the heck is NView?*

NView is a straightforward server-to-client replication system I cooked up for my own use. It's no miracle tool, but it gets the job done. Without using a single remote event, NView enables automatic data syncing between server and client. 

This handy tool has served me well in my own development process, and I thought it might be useful to other developers in the community too. 

## [HOW?]
To use NView simply create a new instance of nview with your attached instance as the parameter.

### This is for example an NView wrapped around a player:
Server
```
local TargetPlayer = game.Players.BrianNovius
local PlayerView = NView.new(TargetPlayer)

PlayerView.Health = 100
task.wait(10)
PlayerView.Health = 50
```

Client
```
local myPlayer = game.Players.LocalPlayer
local myView = NView.new(myPlayer)

myPlayer.ValueChanged:Connect(function(valueName, newValue, lastValue)
    if valueName == "Health" then
        print("damn man")
    end
end)
```

## [WHY?]
I personally use NView to avoid using up remote calls, as well as avoiding the need to sync data to players that joined a new server. For example, if we have a Gun class with information such as Ammo and StoredAmmo, a newly joined client can simply get this information from the NView instead of having to ask the server for it. This is great for moments where a newly joined client wants to pick up a gun from another client.

## [Dependencies]
Sleitnick/signal
&nbsp;

## [Credit]
*Credit where credit is due*:

* Sleitnick for the Signal class
* TheNexusAvenger for NexusInstance & NexusObject
