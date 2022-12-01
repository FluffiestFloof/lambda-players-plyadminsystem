
if SERVER then
    util.AddNetworkString( "kickuser" )
    util.AddNetworkString( "slayuser" )
    util.AddNetworkString( "ignite" )
    util.AddNetworkString( "extinguish" )
    util.AddNetworkString( "clearents" )

    net.Receive( "kickuser", function( len, ply )
        local p = net.ReadEntity( )
        if ply:IsAdmin( ) then
            if p.IsLambdaPlayer then p:Remove() else p:Kick( "Kicked from the server" ) end
        end
    end)

    net.Receive( "slayuser", function( len, ply )
        local p = net.ReadEntity( )
        if ply:IsAdmin( ) and p:Alive( ) then
            if p.IsLambdaPlayer then p:TakeDamage( p:GetMaxHealth()*1000, ply, ply ) else p:Kill( ) end
        end
    end)

    net.Receive( "ignite", function( len, ply )
		local p = net.ReadEntity()
        local time = net.ReadUInt( 9 )
		if ply:IsAdmin() and p:Alive() then
			p:Ignite( time )
		end
	end)

    net.Receive( "extinguish", function( len, ply )
		local p = net.ReadEntity()
		if ply:IsAdmin() and p:Alive() then
			p:Extinguish()
		end
	end)

    net.Receive( "clearents", function( len, ply )
		local p = net.ReadEntity()
		if ply:IsAdmin() and p:Alive() then
			if p.IsLambdaPlayer then p:CleanSpawnedEntities() else end
		end
	end)
end

if CLIENT then
    local table_Add = table.Add
    local draw = draw
    local CurTime = CurTime
    local math = math
    local sub = string.sub
    local Material = Material

    local function CreateProfilePictureMat( ent )
        local pfp = ent:GetProfilePicture()

        local profilepicturematerial = Material( pfp )

        if profilepicturematerial:IsError() then
            local model = ent:GetModel()
            profilepicturematerial = Material( "spawnicons/" .. sub( model, 1, #model - 4 ) .. ".png" )
        end
        return profilepicturematerial
    end

    hook.Add( "Initialize", "lambdaplayers_overridegamemodehooks", function() 

        local PLAYER_LINE = {
            Init = function( self )
        
                self.AvatarButton = self:Add( "DButton" )
                self.AvatarButton:Dock( LEFT )
                self.AvatarButton:SetSize( 32, 32 )
                self.AvatarButton.DoClick = function() if self.Player.IsLambdaPlayer then return end self.Player:ShowProfile() end

                self.AvatarButton.DoRightClick = function()
                    if !self.Player.IsLambdaPlayer then return end -- While it's entirely doable, let's not have our own admin system for players.
                    local adminmenu = DermaMenu()

                    local cmdSlay = adminmenu:AddOption( "Slay " .. self.Player:Nick(), function() net.Start( "slayuser" ) net.WriteEntity( self.Player ) net.SendToServer() end )
                    cmdSlay:SetIcon( "icon16/heart_delete.png" )

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

                    local cmdKick = adminmenu:AddOption( "Kick " .. self.Player:Nick(), function() net.Start( "kickuser" ) net.WriteEntity( self.Player ) net.SendToServer() end )
                    cmdKick:SetIcon( "icon16/user_delete.png" )

                    local cmdClearent = adminmenu:AddOption( "Clear " .. self.Player:Nick() .. " entities", function() net.Start( "clearents" ) net.WriteEntity( self.Player ) net.SendToServer() end )
                    cmdClearent:SetIcon( "icon16/bin.png" )

                    adminmenu:Open()
                end
        
                self.Avatar = vgui.Create( "AvatarImage", self.AvatarButton )
                self.Avatar:SetSize( 32, 32 )
                self.Avatar:SetMouseInputEnabled( false )

                self.LambdaAvatar = vgui.Create( "DImage", self.AvatarButton )
                self.LambdaAvatar:SetSize( 32, 32 )
                self.LambdaAvatar:SetMouseInputEnabled( false )
                self.LambdaAvatar:Hide()
        
                self.Name = self:Add( "DLabel" )
                self.Name:Dock( FILL )
                self.Name:SetFont( "ScoreboardDefault" )
                self.Name:SetTextColor( Color( 93, 93, 93 ) )
                self.Name:DockMargin( 8, 0, 0, 0 )
        
                self.Mute = self:Add( "DImageButton" )
                self.Mute:SetSize( 32, 32 )
                self.Mute:Dock( RIGHT )
        
                self.Ping = self:Add( "DLabel" )
                self.Ping:Dock( RIGHT )
                self.Ping:SetWidth( 50 )
                self.Ping:SetFont( "ScoreboardDefault" )
                self.Ping:SetTextColor( Color( 93, 93, 93 ) )
                self.Ping:SetContentAlignment( 5 )
        
                self.Deaths = self:Add( "DLabel" )
                self.Deaths:Dock( RIGHT )
                self.Deaths:SetWidth( 50 )
                self.Deaths:SetFont( "ScoreboardDefault" )
                self.Deaths:SetTextColor( Color( 93, 93, 93 ) )
                self.Deaths:SetContentAlignment( 5 )
        
                self.Kills = self:Add( "DLabel" )
                self.Kills:Dock( RIGHT )
                self.Kills:SetWidth( 50 )
                self.Kills:SetFont( "ScoreboardDefault" )
                self.Kills:SetTextColor( Color( 93, 93, 93 ) )
                self.Kills:SetContentAlignment( 5 )
        
                self:Dock( TOP )
                self:DockPadding( 3, 3, 3, 3 )
                self:SetHeight( 32 + 3 * 2 )
                self:DockMargin( 2, 0, 2, 2 )
        
            end,
        
            Setup = function( self, pl )
        
                self.Player = pl
        
                if !pl.IsLambdaPlayer then
                    self.Avatar:SetPlayer( pl )
                else
                    self.LambdaAvatar:SetMaterial( CreateProfilePictureMat( pl ) )
                    self.LambdaAvatar:Show()
                end
                
                self:Think( self )
        
                --local friend = self.Player:GetFriendStatus()
                --MsgN( pl, " Friend: ", friend )
        
            end,
        
            Think = function( self )
        
                if ( !IsValid( self.Player ) ) then
                    self:SetZPos( 9999 ) -- Causes a rebuild
                    self:Remove()
                    return
                end
        
                if ( self.PName == nil or self.PName != self.Player:Nick() ) then
                    self.PName = self.Player:Nick()
                    self.Name:SetText( self.PName )
                end
        
                if ( self.NumKills == nil or self.NumKills != self.Player:Frags() ) then
                    self.NumKills = self.Player:Frags()
                    self.Kills:SetText( self.NumKills )
                end
        
                if ( self.NumDeaths == nil or self.NumDeaths != self.Player:Deaths() ) then
                    self.NumDeaths = self.Player:Deaths()
                    self.Deaths:SetText( self.NumDeaths )
                end
        
                if ( self.NumPing == nil or self.NumPing != self.Player:Ping() ) then
                    self.NumPing = self.Player:Ping()
                    self.Ping:SetText( self.NumPing )
                end
        
                --
                -- Change the icon of the mute button based on state
                --
                if ( self.Muted == nil or self.Muted != self.Player:IsMuted() ) then
        
                    self.Muted = self.Player:IsMuted()
                    if ( self.Muted ) then
                        self.Mute:SetImage( "icon32/muted.png" )
                    else
                        self.Mute:SetImage( "icon32/unmuted.png" )
                    end
        
                    self.Mute.DoClick = function( s ) self.Player:SetMuted( !self.Muted ) end
                    self.Mute.OnMouseWheeled = function( s, delta )
                        self.Player:SetVoiceVolumeScale( self.Player:GetVoiceVolumeScale() + ( delta / 100 * 5 ) )
                        s.LastTick = CurTime()
                    end
        
                    self.Mute.PaintOver = function( s, w, h )
                        if ( !IsValid( self.Player ) ) then return end
                    
                        local a = 255 - math.Clamp( CurTime() - ( s.LastTick or 0 ), 0, 3 ) * 255
                        if ( a <= 0 ) then return end
                        
                        draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, a * 0.75 ) )
                        draw.SimpleText( math.ceil( self.Player:GetVoiceVolumeScale() * 100 ) .. "%", "DermaDefaultBold", w / 2, h / 2, Color( 255, 255, 255, a ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
                    end
        
                end
        
                --
                -- Connecting players go at the very bottom
                --
                if ( self.Player:Team() == TEAM_CONNECTING ) then
                    self:SetZPos( 2000 + self.Player:EntIndex() )
                    return
                end
        
                --
                -- This is what sorts the list. The panels are docked in the z order,
                -- so if we set the z order according to kills they'll be ordered that way!
                -- Careful though, it's a signed short internally, so needs to range between -32,768k and +32,767
                --
                self:SetZPos( ( self.NumKills * -50 ) + self.NumDeaths + self.Player:EntIndex() )
        
            end,
        
            Paint = function( self, w, h )
        
                if ( !IsValid( self.Player ) ) then
                    return
                end
        
                --
                -- We draw our background a different colour based on the status of the player
                --
        
                if ( self.Player:Team() == TEAM_CONNECTING ) then
                    draw.RoundedBox( 4, 0, 0, w, h, Color( 200, 200, 200, 200 ) )
                    return
                end
        
                if ( !self.Player:Alive() ) then
                    draw.RoundedBox( 4, 0, 0, w, h, Color( 230, 200, 200, 255 ) )
                    return
                end
        
                if ( self.Player:IsAdmin() ) then
                    draw.RoundedBox( 4, 0, 0, w, h, Color( 230, 255, 230, 255 ) )
                    return
                end
        
                draw.RoundedBox( 4, 0, 0, w, h, Color( 230, 230, 230, 255 ) )
        
            end
        }
        
        --
        -- Convert it from a normal table into a Panel Table based on DPanel
        --
        PLAYER_LINE = vgui.RegisterTable( PLAYER_LINE, "DPanel" )



        local SCORE_BOARD = {
            Init = function( self )

                self.Header = self:Add( "Panel" )
                self.Header:Dock( TOP )
                self.Header:SetHeight( 100 )
        
                self.Name = self.Header:Add( "DLabel" )
                self.Name:SetFont( "ScoreboardDefaultTitle" )
                self.Name:SetTextColor( color_white )
                self.Name:Dock( TOP )
                self.Name:SetHeight( 40 )
                self.Name:SetContentAlignment( 5 )
                self.Name:SetExpensiveShadow( 2, Color( 0, 0, 0, 200 ) )
        
                --self.NumPlayers = self.Header:Add( "DLabel" )
                --self.NumPlayers:SetFont( "ScoreboardDefault" )
                --self.NumPlayers:SetTextColor( color_white )
                --self.NumPlayers:SetPos( 0, 100 - 30 )
                --self.NumPlayers:SetSize( 300, 30 )
                --self.NumPlayers:SetContentAlignment( 4 )
        
                self.Scores = self:Add( "DScrollPanel" )
                self.Scores:Dock( FILL )
        
            end,
        
            PerformLayout = function( self )
        
                self:SetSize( 700, ScrH() - 200 )
                self:SetPos( ScrW() / 2 - 350, 100 )
        
            end,
        
            Paint = function( self, w, h )
        
                --draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, 200 ) )
        
            end,
        
            Think = function( self, w, h )
        
                self.Name:SetText( GetHostName() )
        
                --
                -- Loop through each player, and if one doesn't have a score entry - create it.
                --
                local plyrs = player.GetAll()
                local lambda = GetLambdaPlayers()
                table_Add( plyrs, lambda )

                for id, pl in pairs( plyrs ) do
                    if ( IsValid( pl.ScoreEntry ) ) then continue end
        
                    pl.ScoreEntry = vgui.CreateFromTable( PLAYER_LINE, pl.ScoreEntry )
                    pl.ScoreEntry:Setup( pl )
        
                    self.Scores:AddItem( pl.ScoreEntry )
        
                end
        
            end
        }

        SCORE_BOARD = vgui.RegisterTable( SCORE_BOARD, "EditablePanel" )

        function GAMEMODE:ScoreboardShow()

            if ( !IsValid( g_Scoreboard ) ) then
                g_Scoreboard = vgui.CreateFromTable( SCORE_BOARD )
            end
        
            if ( IsValid( g_Scoreboard ) ) then
                g_Scoreboard:Show()
                g_Scoreboard:MakePopup()
                g_Scoreboard:SetKeyboardInputEnabled( false )
            end
        
        end
        function GAMEMODE:ScoreboardHide()
        
            if ( IsValid( g_Scoreboard ) ) then
                g_Scoreboard:Hide()
            end
        
        end


    end )



end





if CLIENT then return end
local canoverride = GetConVar( "lambdaplayers_lambda_overridegamemodehooks" )

hook.Add( "Initialize", "lambdaplayers_overridegamemodehooks", function() 

    if canoverride:GetBool() or true then

        function GAMEMODE:PlayerDeath( ply, inflictor, attacker )

            -- Don't spawn for at least 2 seconds
            ply.NextSpawnTime = CurTime() + 2
            ply.DeathTime = CurTime()

            if ( IsValid( attacker ) and attacker:GetClass() == "trigger_hurt" ) then attacker = ply end

            if ( IsValid( attacker ) and attacker:IsVehicle() and IsValid( attacker:GetDriver() ) ) then
                attacker = attacker:GetDriver()
            end

            if ( !IsValid( inflictor ) and IsValid( attacker ) ) then
                inflictor = attacker
            end

            -- Convert the inflictor to the weapon that they're holding if we can.
            -- This can be right or wrong with NPCs since combine can be holding a
            -- pistol but kill you by hitting you with their arm.
            if ( IsValid( inflictor ) and inflictor == attacker and ( inflictor:IsPlayer() or inflictor:IsNPC() ) ) then

                inflictor = inflictor:GetActiveWeapon()
                if ( !IsValid( inflictor ) ) then inflictor = attacker end

            end

            player_manager.RunClass( ply, "Death", inflictor, attacker )

            if ( attacker == ply ) then

                net.Start( "PlayerKilledSelf" )
                    net.WriteEntity( ply )
                net.Broadcast()

                MsgAll( attacker:Nick() .. " suicided!\n" )

            return end

            if ( attacker:IsPlayer() ) then

                net.Start( "PlayerKilledByPlayer" )

                    net.WriteEntity( ply )
                    net.WriteString( inflictor:GetClass() )
                    net.WriteEntity( attacker )

                net.Broadcast()

                MsgAll( attacker:Nick() .. " killed " .. ply:Nick() .. " using " .. inflictor:GetClass() .. "\n" )

            return end

            if !attacker.IsLambdaPlayer then
                net.Start( "PlayerKilled" )

                    net.WriteEntity( ply )
                    net.WriteString( inflictor:GetClass() )
                    net.WriteString( attacker:GetClass() )

                net.Broadcast()
            end

            MsgAll( ply:Nick() .. " was killed by " .. attacker:GetClass() .. "\n" )

        end

        function GAMEMODE:OnNPCKilled( ent, attacker, inflictor )

            -- Don't spam the killfeed with scripted stuff
            if ( ent:GetClass() == "npc_bullseye" or ent:GetClass() == "npc_launcher" ) then return end
        
            if ( IsValid( attacker ) and attacker:GetClass() == "trigger_hurt" ) then attacker = ent end
            
            if ( IsValid( attacker ) and attacker:IsVehicle() and IsValid( attacker:GetDriver() ) ) then
                attacker = attacker:GetDriver()
            end
        
            if ( !IsValid( inflictor ) and IsValid( attacker ) ) then
                inflictor = attacker
            end
            
            -- Convert the inflictor to the weapon that they're holding if we can.
            if ( IsValid( inflictor ) and attacker == inflictor and ( inflictor:IsPlayer() or inflictor:IsNPC() ) ) then
            
                inflictor = inflictor:GetActiveWeapon()
                if ( !IsValid( attacker ) ) then inflictor = attacker end
            
            end
            
            local InflictorClass = "worldspawn"
            local AttackerClass = "worldspawn"
            
            if ( IsValid( inflictor ) ) then InflictorClass = inflictor:GetClass() end
            if ( IsValid( attacker ) and !ent.IsLambdaPlayer and !attacker.IsLambdaPlayer ) then
        
                AttackerClass = attacker:GetClass()
            
                if ( attacker:IsPlayer() ) then
        
                    net.Start( "PlayerKilledNPC" )
                
                        net.WriteString( ent:GetClass() )
                        net.WriteString( InflictorClass )
                        net.WriteEntity( attacker )
                
                    net.Broadcast()
        
                    return
                end
        
            end
        
            if ( ent:GetClass() == "npc_turret_floor" ) then AttackerClass = ent:GetClass() end

            if ent.IsLambdaPlayer or attacker.IsLambdaPlayer then return end
        
            net.Start( "NPCKilledNPC" )
            
                net.WriteString( ent:GetClass() )
                net.WriteString( InflictorClass )
                net.WriteString( AttackerClass )
            
            net.Broadcast()
        
        end

    end
end )