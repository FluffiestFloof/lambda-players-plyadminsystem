util.AddNetworkString("lambdaplayers_pas_chatprint")

local color_white = color_white
local color_blue = Color( 0, 255, 0 )
local color_admin = Color( 150, 25, 0 )

-- ---------------------- --
-- // HELPER FUNCTIONS // --
-- ---------------------- --


-- Helper function to find if a Lambda with that name exist
local function FindLambda( name )
    local found = false

    -- Tries to find a lambda with the full name
    for k, v in ipairs( GetLambdaPlayers() ) do
        if string.lower( v:Nick() ) == string.lower( name ) then found = v end
    end

    -- If fails to find a lambda with the full name, tries to find the name somewhere.
    -- Probably should just keep one since they give very similar result?
    -- This one is just a russian roulette if multiple lambdas have similar names
    if !found then
        for k, v in ipairs( GetLambdaPlayers() ) do
            if string.match( string.lower( v:Nick() ), string.lower( name ) ) then found = v end
        end
    end

    return found
end


-- Helper function to extract cmd, name and extra info from text command
local function ExtractInfo( s )
    local spat, epat, info, i, buf, quoted = [=[^(['"])]=], [=[(['"])$]=], {}, 1
    
    for str in string.gmatch(s, "%S+") do
        local squoted = string.match(str, spat)
        local equoted = string.match(str, epat)
        local escaped = string.match(str,[=[(\*)['"]$]=])
        local clearword

        if squoted and not quoted and not equoted then
            buf, quoted = str, squoted
        elseif buf and equoted == quoted and #escaped % 2 == 0 then
            str, buf, quoted = buf .. ' ' .. str, nil, nil
        elseif buf then
            buf = buf .. ' ' .. str
        end
        if not buf then 
            clearword = string.gsub(str, spat,"")
            clearword = string.gsub(clearword, epat,"")
            --print( "DEBUG: ", i, clearword )
            info[i] = clearword
            i = i + 1
        end
    end

    -- If an apostrophe doesn't have a 'closing' apostrophe, it should do something.
    --[[if buf then
        print("DEBUG: Missing a quote to complete "..buf)
    end]]


    return info[1], info[2], info[3], info[4] --Only returns the command and two extras. Anything else is voided because we don't need it
end


-- Helper function to lower clutter in other functions. It prints to clients chat.
local function PrintToChat( tbl )
    if GetConVar( "lambdaplayers_pas_chatecho" ):GetBool() then
        net.Start( "lambdaplayers_pas_chatprint", true )
        net.WriteString( util.TableToJSON(tbl))
        net.Broadcast()
    end
end



-- --------------------------- --
-- // COMMANDS INTERACTIONS // --
-- --------------------------- --


local slapSounds = { "physics/body/body_medium_impact_hard1.wav", "physics/body/body_medium_impact_hard2.wav", "physics/body/body_medium_impact_hard3.wav", "physics/body/body_medium_impact_hard5.wav", "physics/body/body_medium_impact_hard6.wav", "physics/body/body_medium_impact_soft5.wav", "physics/body/body_medium_impact_soft6.wav", "physics/body/body_medium_impact_soft7.wav" }
local gaggedLambdas = {}

--[[ TODO
    God / Ungod
    Jail / Unjail / TPJail
]]

-- Table of Functions. This is where all the commands actual effects are.
local PAScmds = {
    
    -- Teleports the Player to the Lambda Player
    -- ,goto [target]
    ["goto"] = function( lambda, ply )
        --ply.lambdaLastPos = ply:GetPos()
        ply:SetPos( lambda:GetPos() + ( ( ply:GetPos() - lambda:GetPos() ):Angle():Forward() ) * 100 )

        PrintToChat( { color_admin, ply:GetName(), color_white, " teleported to ", lambda:GetDisplayColor( ply ), lambda:GetLambdaName() } )
    end,

    -- Teleports the Lambda Player to the Player
    -- ,bring [target]
    ["bring"] = function( lambda, ply )
        lambda.lambdaLastPos = lambda:GetPos()
        lambda.CurNoclipPos = ply:GetEyeTrace().HitPos
        lambda:SetPos( ply:GetPos() + ply:GetForward()*100 )

        PrintToChat( { color_admin, ply:GetName(), color_white, " brought ", lambda:GetDisplayColor( ply ), lambda:GetLambdaName(), color_white," to themselves" } )
    end,

    -- Returns the Lambda Player to where they originally were
    -- ,return [target]
    ["return"] = function( lambda, ply )
        if !lambda.lambdaLastPos then ply:PrintMessage( HUD_PRINTTALK, lambda:GetLambdaName().." can't be returned" ) return end
    
        lambda:SetPos( lambda.lambdaLastPos )
        lambda.lambdaLastPos = nil

        PrintToChat( { color_admin, ply:GetName(), color_white, " returned ", lambda:GetDisplayColor( ply ), lambda:GetLambdaName(), color_white, " back to their original position" } )
    end,

    -- Removes all spawned entities of the Lambda Player
    -- ,clearents [target]
    ["clearents"] = function( lambda, ply )
        lambda:CleanSpawnedEntities()

        PrintToChat( { color_admin, ply:GetName(), color_white, " cleared ", lambda:GetDisplayColor( ply ), lambda:GetLambdaName(), color_white, " entities" } )
    end,

    -- Stops the Lambda Player from being able to use text chat
    -- ,gag [target]
    ["gag"] = function( lambda, ply )

        if gaggedLambdas[lambda:EntIndex()] then
            ply:PrintMessage( HUD_PRINTTALK, lambda:GetLambdaName().." is already gagged" ) return
        end

        gaggedLambdas[lambda:EntIndex()] = true -- Add Lambda to the gaggedlambdas


        PrintToChat( { color_admin, ply:GetName(), color_white, " gagged ", lambda:GetDisplayColor( ply ), lambda:GetLambdaName() } )
    end,

    -- Restores the Lambda Player's ability to use text chat
    -- ,ungag [target]
    ["ungag"] = function( lambda, ply )
        
        if !gaggedLambdas[lambda:EntIndex()]  then
            ply:PrintMessage( HUD_PRINTTALK, lambda:GetLambdaName().." is not gagged" ) return
        end

        gaggedLambdas[lambda:EntIndex()] = nil

        PrintToChat( { color_admin, ply:GetName(), color_white, " ungagged ", lambda:GetDisplayColor( ply ), lambda:GetLambdaName() } )
    end,

    -- Stops the Lambda Player from being able to use voice chat
    -- ,mute [target]
    ["mute"] = function( lambda, ply )

        if lambda:IsMuted() then
            ply:PrintMessage( HUD_PRINTTALK, lambda:GetLambdaName().." is already muted" ) return
        end

        lambda:SetMuted( true )

        PrintToChat( { color_admin, ply:GetName(), color_white, " muted ", lambda:GetDisplayColor( ply ), lambda:GetLambdaName() } )
    end,

    -- Restores the Lambda Player's ability to use voice chat
    -- ,unmute [target]
    ["unmute"] = function( lambda, ply )
        
        if !lambda:IsMuted() then
            ply:PrintMessage( HUD_PRINTTALK, lambda:GetLambdaName().." is not muted" ) return
        end

        lambda:SetMuted( false )

        PrintToChat( { color_admin, ply:GetName(), color_white, " unmuted ", lambda:GetDisplayColor( ply ), lambda:GetLambdaName() } )
    end,

    -- Kills the Lambda Player
    -- ,slay [target]
    ["slay"] = function( lambda, ply )
        local dmginfo = DamageInfo()
        dmginfo:SetDamage( 0 )
        dmginfo:SetAttacker( lambda )
        dmginfo:SetInflictor( lambda )
        lambda:LambdaOnKilled( dmginfo ) -- Could just use TakeDamage but I find this funny

        PrintToChat( { color_admin, ply:GetName(), color_white, " slayed ", lambda:GetDisplayColor( ply ), lambda:GetLambdaName() } )
    end,

    -- Removes the Lambda Player from the server
    -- ,kick [target] [reason] // Reason defaults to "No reason provided."
    ["kick"] = function( lambda, ply, reason )
        if reason == "" or !reason then
            reason = "No reason provided."
        end

        lambda:Remove()

        PrintToChat( { color_admin, ply:GetName(), color_white, " kicked ", lambda:GetDisplayColor( ply ), lambda:GetLambdaName(), " ", color_white, "(", color_blue, reason, color_white ,")" } )
    end,

    -- Deals an amount of damage to the Lambda Player
    -- ,slap [target] [damage] // Damage defaults to 0
    ["slap"] = function( lambda, ply, damage )
        damage = tonumber(damage) or 0

        local direction = Vector( random( 50 )-25, random( 50 )-25, random( 50 ) ) -- Make it random, slightly biased to go up.

        if !lambda:IsInNoClip() then
            lambda.loco:Jump()
            lambda.loco:SetVelocity( direction * ( damage + 1 ) )
        end

        lambda:EmitSound( slapSounds[ random(#slapSounds) ], 65 )

        lambda:TakeDamage( damage, lambda, lambda )

        PrintToChat( { color_admin, ply:GetName(), color_white," slapped ", lambda:GetDisplayColor( ply ), lambda:GetLambdaName(), color_white, " with ", color_blue, tostring(damage), color_white, " damage" } )
    end,

    -- Deals an amount of damage to the Lambda Player an amount of times
    -- ,whip [target] [damage] [times] // damage defaults to 0, times defaults to 1
    ["whip"] = function( lambda, ply, damage, times )
        damage = tonumber(damage) or 0
        times = tonumber(times) or 1

        local direction = Vector( random( 50 )-25, random( 50 )-25, random( 50 ) ) -- Make it random, slightly biased to go up.

        timer.Create( "lambdaplayers_pas_whip"..lambda:EntIndex(), 0.5, times, function()
            if !IsValid( lambda ) then timer.Remove( "lambdaplayers_pas_whip"..lambda:EntIndex() ) return end
            
            if !lambda:IsInNoClip() then
                lambda.loco:Jump()
                lambda.loco:SetVelocity( direction * ( damage + 1 ) )
            end
            
            lambda:EmitSound( slapSounds[ random(#slapSounds) ], 65 )
            
            lambda:TakeDamage( damage, lambda, lambda )
        end)

        PrintToChat( { color_admin, ply:GetName(), color_white, " whipped ", lambda:GetDisplayColor( ply ), lambda:GetLambdaName(), " ", color_blue, tostring(times), color_white, " times with ", color_blue, tostring(damage), color_white, " damage" } )
    end,

    -- Sets the Lambda Player on fire for an amount of time
    -- ,ignite [target] [time] // Time defaults to 10
    ["ignite"] = function( lambda, ply, time )
        time = tonumber(time) or 10

        lambda:Ignite(time)
        
        PrintToChat( { color_admin, ply:GetName(), color_white, " set ", lambda:GetDisplayColor( ply ), lambda:GetLambdaName(), " on fire for ", color_blue, tostring(time), color_white, " seconds" } )
    end,

    -- Extinguish the Lambda Player if they are on fire
    -- ,extinguish [target]
    ["extinguish"] = function( lambda, ply )
        if !lambda:IsOnfire() then ply:PrintMessage( HUD_PRINTTALK, lambda:GetLambdaName().." is not on fire" ) return "" end
        
        lambda:Extinguish()
    
        PrintToChat( { color_admin, plt:GetName(), color_white, " extinguished ", lambda:GetDisplayColor( ply ), lambda:GetLambdaName()} )
    end,

    -- Sets the Lambda Player's health to the given amount
    -- ,sethealth [target] [amount] // Amount defaults to 0
    ["sethealth"] = function( lambda, ply, amount )
        amount = tonumber(amount) or 0

        if amount <= 0 then 
            lambda:TakeDamage( lambda:GetMaxHealth()*5, lambda, lambda ) -- Prevent setting health to negative :)
        else
            lambda:SetHealth(amount)
        end

        PrintToChat( { color_admin, ply:GetName(), color_white," set ", lambda:GetDisplayColor( ply ), lambda:GetLambdaName(), color_white, " health to ", color_blue, tostring(amount) } )
    end,

    -- Sets the Lambda Player's armor to the given amount
    -- ,setarmor [target] [amount] // Amount defaults to 0
    ["setarmor"] = function( lambda, ply, amount )
        amount = tonumber(amount) or 0

        amount = max( 0, amount ) -- Prevent setting armor to negative

        lambda:SetArmor( amount )

        PrintToChat( { color_admin, ply:GetName(), color_white," set ", lambda:GetDisplayColor( ply ), lambda:GetLambdaName(), color_white, " armor to ", color_blue, tostring(amount) } )
    end
}



-- -------------------------------- --
-- // SCOREBOARD COMMANDS ACTION // --
-- -------------------------------- --


-- Deal with the scoreboard admin clicky click things
util.AddNetworkString("lambdaplayers_pas_scoreboardaction")

net.Receive("lambdaplayers_pas_scoreboardaction", function()
    local cmd = net.ReadString()
    local lambda = net.ReadEntity( )
    local ply = net.ReadEntity( )

    if ( PAScmds[cmd] ) then PAScmds[cmd]( lambda, ply ) end
end)



-- ------------------------------- --
-- // TEXT CHAT COMMANDS ACTION // --
-- ------------------------------- --


-- HOOK: Check player chat input for administrative commands
hook.Add( "PlayerSay", "lambdaplayers_pas_plysay", function( ply, text )
    -- We avoid empty string and we only take the first letter. Might change later but not much point.
    local prefix = GetConVar( "lambdaplayers_pas_cmdprefix" ):GetString() != "" and string.sub( GetConVar( "lambdaplayers_pas_cmdprefix" ):GetString(), 1, 1 ) or ","

    -- if it doesn't start like a command or the addon is disabled we don't care.
    if string.StartWith( string.lower(text), prefix ) and GetConVar( "lambdaplayers_pas_enabled" ):GetBool() then

        -- Check if the one inputing the command is an admin otherwise tells command user.
        if !ply:IsAdmin() then ply:PrintMessage( HUD_PRINTTALK, "You need to be an admin to use "..c_cmd ) return "" end
        
        -- Extract all the information out of the provided chat line.
        local c_cmd, c_name, c_ex1, c_ex2 = ExtractInfo( text )
        c_cmd = string.sub( c_cmd, 2 ) -- Remove comma
        
        -- Check if a name was provided otherwise tells command user.
        if c_name == nil then ply:PrintMessage( HUD_PRINTTALK, c_cmd.." is missing a target" ) return "" end
        
        -- Check if the Lambda exist otherwise tells command user.
        local lambda = FindLambda( c_name )
        if !IsValid( lambda ) then ply:PrintMessage( HUD_PRINTTALK, c_name.." is not a valid target" ) return "" end
        
        -- Check if the command exist then execute it otherwise tells command user.
        if ( PAScmds[c_cmd] ) then PAScmds[c_cmd]( lambda, ply, c_ex1, c_ex2 ) else ply:PrintMessage( HUD_PRINTTALK, c_cmd.." is not a valid command" ) end
        return ""
    end
    
end)

-- HOOK: Check if typing lambda is gagged and stop them from typing if true
hook.Add( "LambdaPlayerSay", "lambdaplayers_pas_lambdasay", function( lambda, text )
    if gaggedLambdas[lambda:EntIndex()] then
        return "" -- Stop the lambda that tried to use text from printing anything
    end

end)

-- HOOK: Removes removed Lambdas from the gag list
hook.Add( "LambdaOnRemove", "lambdaplayers_pas_lambdaremove", function( lambda )
    if gaggedLambdas[lambda:EntIndex()] then
        gaggedLambdas[lambda:EntIndex()] = nil
    end
end)