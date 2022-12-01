
if CLIENT then
    hook.Add( "ScoreboardShow", "lambdaplyadmin_scoreboardopen", function()
        -- Do the clicky click actions there somehow
    end )
end


--[[

    self.AvatarButton.DoRightClick = function()
        if !self.Player.IsLambdaPlayer then return end -- While it's entirely doable, let's not have our own admin system for players.
        local adminmenu = DermaMenu()

        local cmdSlay = adminmenu:AddOption( "Slay " .. self.Player:Nick(), function() net.Start( "slayuser" ) net.WriteEntity( self.Player ) net.SendToServer() end )
        cmdSlay:SetIcon( "icon16/heart_delete.png" )

        local cmdKick = adminmenu:AddOption( "Kick " .. self.Player:Nick(), function() net.Start( "kickuser" ) net.WriteEntity( self.Player ) net.SendToServer() end )
        cmdKick:SetIcon( "icon16/user_delete.png" )

        local cmdClearent = adminmenu:AddOption( "Clear " .. self.Player:Nick() .. " entities", function() net.Start( "clearents" ) net.WriteEntity( self.Player ) net.SendToServer() end )
        cmdClearent:SetIcon( "icon16/bin.png" )

        adminmenu:Open()
    end
]]


--[[

if self.Player:IsOnFire() == false then
    local cmdIgnite, icon = adminmenu:AddSubMenu( "Ignite " .. self.Player:Nick() )
    icon:SetIcon( "icon16/weather_sun.png" )
    cmdIgnite:AddOption( "5 Seconds", function() net.Start( "ignite" ) net.WriteEntity( self.Player ) net.WriteUInt( 5, 9 ) net.SendToServer() end ):SetIcon( "icon16/clock.png" )
    cmdIgnite:AddOption( "10 Seconds", function() net.Start( "ignite" ) net.WriteEntity( self.Player ) net.WriteUInt( 10, 9 ) net.SendToServer() end ):SetIcon( "icon16/clock.png" )
    cmdIgnite:AddOption( "20 Seconds", function() net.Start( "ignite" ) net.WriteEntity( self.Player ) net.WriteUInt( 20, 9 )  net.SendToServer() end ):SetIcon( "icon16/clock.png" )
    cmdIgnite:AddOption( "30 Seconds", function() net.Start( "ignite" ) net.WriteEntity( self.Player ) net.WriteUInt( 30, 9 )  net.SendToServer() end ):SetIcon( "icon16/clock.png" )
    cmdIgnite:AddOption( "1 Minute", function() net.Start( "ignite" ) net.WriteEntity( self.Player ) net.WriteUInt( 60, 9 )  net.SendToServer() end ):SetIcon( "icon16/clock.png" )
    cmdIgnite:AddOption( "2 Minutes", function() net.Start( "ignite" ) net.WriteEntity( self.Player ) net.WriteUInt( 120, 9 )  net.SendToServer() end ):SetIcon( "icon16/clock.png" )
    cmdIgnite:AddOption( "5 Minutes", function() net.Start( "ignite" ) net.WriteEntity( self.Player ) net.WriteUInt( 300, 9 )  net.SendToServer() end ):SetIcon( "icon16/clock.png" )
else
    local cmdExtinguish = adminmenu:AddOption( "Extinguish " .. self.Player:Nick(), function() net.Start( "extinguish" ) net.WriteEntity( self.Player ) net.SendToServer() end )
    cmdExtinguish:SetIcon( "icon16/weather_rain.png" )
end
]]