
-- Whenever I get smart enough to do that I'll do an actual addon to the scoreboard
-- Right now the only option I know is to just override the override of the scoreboard

if CLIENT then
    local table_Add = table.Add
    local draw = draw
    local CurTime = CurTime
    local math = math
    local sub = string.sub
    local Material = Material
    local pnlMeta = FindMetaTable( "Panel" )

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

                    adminmenu:AddOption( "Slay " .. self.Player:Nick(), function() net.Start( "lambdaplyadmin_scoreboardaction" ) net.WriteString("slay") net.WriteEntity( self.Player ) net.WriteEntity( LocalPlayer() ) net.SendToServer() end ):SetImage( "icon16/heart_delete.png" )
                    adminmenu:AddOption( "Kick " .. self.Player:Nick(), function() net.Start( "lambdaplyadmin_scoreboardaction" ) net.WriteString("kick") net.WriteEntity( self.Player ) net.WriteEntity( LocalPlayer() ) net.SendToServer() end ):SetImage( "icon16/error.png" )
                    adminmenu:AddSpacer()
                    adminmenu:AddOption( "Clear " .. self.Player:Nick() .. " entities", function() net.Start( "lambdaplyadmin_scoreboardaction" ) net.WriteString("clearents") net.WriteEntity( self.Player ) net.WriteEntity( LocalPlayer() ) net.SendToServer() end ):SetImage( "icon16/world_delete.png" )
                    adminmenu:AddSpacer()
                    adminmenu:AddOption( "Goto " .. self.Player:Nick(), function() net.Start( "lambdaplyadmin_scoreboardaction" ) net.WriteString("goto") net.WriteEntity( self.Player ) net.WriteEntity( LocalPlayer() ) net.SendToServer() end ):SetImage( "icon16/arrow_right.png" )
                    adminmenu:AddOption( "Bring " .. self.Player:Nick(), function() net.Start( "lambdaplyadmin_scoreboardaction" ) net.WriteString("bring") net.WriteEntity( self.Player ) net.WriteEntity( LocalPlayer() ) net.SendToServer() end ):SetImage( "icon16/arrow_left.png" )
                    adminmenu:AddOption( "Return " .. self.Player:Nick(), function() net.Start( "lambdaplyadmin_scoreboardaction" ) net.WriteString("return") net.WriteEntity( self.Player ) net.WriteEntity( LocalPlayer() ) net.SendToServer() end ):SetImage( "icon16/arrow_redo.png" )
                    
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








        local PANEL = {}
        local PlayerVoicePanels = {}
        
        function PANEL:Init()
        
            self.LabelName = vgui.Create( "DLabel", self )
            self.LabelName:SetFont( "GModNotify" )
            self.LabelName:Dock( FILL )
            self.LabelName:DockMargin( 8, 0, 0, 0 )
            self.LabelName:SetTextColor( color_white )
        
            self.Avatar = vgui.Create( "AvatarImage", self )
            self.Avatar:Dock( LEFT )
            self.Avatar:SetSize( 32, 32 )
        
            self.Color = color_transparent
        
            self:SetSize( 250, 32 + 8 )
            self:DockPadding( 4, 4, 4, 4 )
            self:DockMargin( 2, 2, 2, 2 )
            self:Dock( BOTTOM )
        
        end
        
        function PANEL:Setup( ply )
        
            self.ply = ply
            self.LabelName:SetText( ply:Nick() )
    
            if ply.IsLambdaPlayer then
                self.Avatar:Remove()
                self.LambdaAvatar = vgui.Create( "DImage", self )
                self.LambdaAvatar:SetSize( 32, 32 )
                self.LambdaAvatar:Dock( LEFT )
                self.LambdaAvatar:SetMaterial( CreateProfilePictureMat( ply ) )
            else
                self.Avatar:SetPlayer( ply )
            end
    
            self.Color = team.GetColor( ply:Team() )
            
            self:InvalidateLayout()
        
        end
        
        function PANEL:Paint( w, h )
        
            if ( !IsValid( self.ply ) ) then return end
            draw.RoundedBox( 4, 0, 0, w, h, Color( 0, self.ply:VoiceVolume() * 255, 0, 240 ) )
        
        end
        
        function PANEL:Think()
            
            if ( IsValid( self.ply ) ) then
                self.LabelName:SetText( self.ply:Nick() )
            end
        
            if ( self.fadeAnim ) then
                self.fadeAnim:Run()
            end
        
        end
        
        function PANEL:FadeOut( anim, delta, data )
            
            if ( anim.Finished ) then
            
                if ( IsValid( PlayerVoicePanels[ self.ply ] ) ) then
                    PlayerVoicePanels[ self.ply ]:Remove()
                    PlayerVoicePanels[ self.ply ] = nil
                    return
                end
                
            return end
            
            self:SetAlpha( 255 - ( 255 * delta ) )
        
        end
        
        derma.DefineControl( "VoiceNotify", "", PANEL, "DPanel" )
        
        function GAMEMODE:PlayerStartVoice( ply )
        
            if ( !IsValid( g_VoicePanelList ) ) then return end
            
            -- There'd be an exta one if voice_loopback is on, so remove it.
            GAMEMODE:PlayerEndVoice( ply )
        
        
            if ( IsValid( PlayerVoicePanels[ ply ] ) ) then
        
                if ( PlayerVoicePanels[ ply ].fadeAnim ) then
                    PlayerVoicePanels[ ply ].fadeAnim:Stop()
                    PlayerVoicePanels[ ply ].fadeAnim = nil
                end
        
                PlayerVoicePanels[ ply ]:SetAlpha( 255 )
        
                return
        
            end
        
            if ( !IsValid( ply ) ) then return end
        
            local pnl = g_VoicePanelList:Add( "VoiceNotify" )
            pnl:Setup( ply )
            
            PlayerVoicePanels[ ply ] = pnl
        
        end
        
        local function VoiceClean()
        
            for k, v in pairs( PlayerVoicePanels ) do
            
                if ( !IsValid( k ) ) then
                    GAMEMODE:PlayerEndVoice( k )
                end
            
            end
        
        end
        timer.Create( "VoiceClean", 10, 0, VoiceClean )
        
        function GAMEMODE:PlayerEndVoice( ply )
        
            if ( IsValid( PlayerVoicePanels[ ply ] ) ) then
        
                if ( PlayerVoicePanels[ ply ].fadeAnim ) then return end
        
                PlayerVoicePanels[ ply ].fadeAnim = Derma_Anim( "FadeOut", PlayerVoicePanels[ ply ], PlayerVoicePanels[ ply ].FadeOut )
                PlayerVoicePanels[ ply ].fadeAnim:Start( 2 )
        
            end
        
        end
        
        local function CreateVoiceVGUI()
        
            g_VoicePanelList = vgui.Create( "DPanel" )
        
            g_VoicePanelList:ParentToHUD()
            g_VoicePanelList:SetPos( ScrW() - 300, 100 )
            g_VoicePanelList:SetSize( 250, ScrH() - 200 )
            g_VoicePanelList:SetPaintBackground( false )
        
        end
        
        hook.Add( "InitPostEntity", "CreateVoiceVGUI", CreateVoiceVGUI )

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