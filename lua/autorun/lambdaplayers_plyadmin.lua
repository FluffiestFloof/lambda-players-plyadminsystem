local IsValid = IsValid
local pairs = pairs
local random = math.random
local VectorRand = VectorRand
local max = math.max
local net = net
local colName = Color(0,255,0)
local colText = Color(130,164,192)


if SERVER then



-- ---------------------- --
-- // HELPER FUNCTIONS // --
-- ---------------------- --



-- Helper function to find if a Lambda with that name exist
local function FindLambda( name )
    local lambdas = ents.FindByClass("npc_lambdaplayer")
    local found = false

    -- Tries to find a lambda with the full name
    for k, v in ipairs( GetLambdaPlayers() ) do
        if string.lower( v:GetLambdaName() ) == string.lower( name ) then found = v end
    end

    -- If fails to find a lambda with the full name, tries to find the name somewhere.
    -- Probably should just keep one since they give very similar result?
    -- This one is just a russian roulette if multiple lambdas have similar names
    if !found then
        for k, v in ipairs( GetLambdaPlayers() ) do
            if string.match( string.lower( v:GetLambdaName() ), string.lower( name ) ) then found = v end
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
    -- They can figure it out themselves. If the user manage to fail operating a simple chat command, ain't my problem.
    --[[if buf then
        print("DEBUG: Missing a quote to complete "..buf)
    end]]


    return info[1], info[2], info[3], info[4] --Only returns the command and two extras. Anything else is voided because who cares
end


-- Helper function to lower clutter in other functions. It prints to clients chat
local function PrintToChat( tbl )
    net.Start( "lambdaplyadmin_chatprint", true )
    net.WriteString( util.TableToJSON(tbl))
    net.Broadcast()
end



-- --------------------------- --
-- // COMMANDS INTERACTIONS // --
-- --------------------------- --



local slapSounds = { "physics/body/body_medium_impact_hard1.wav", "physics/body/body_medium_impact_hard2.wav", "physics/body/body_medium_impact_hard3.wav", "physics/body/body_medium_impact_hard5.wav", "physics/body/body_medium_impact_hard6.wav", "physics/body/body_medium_impact_soft5.wav", "physics/body/body_medium_impact_soft6.wav", "physics/body/body_medium_impact_soft7.wav" }
-- Switch case. You might not like it but this is what peak programming looks like :chad:
local PACommands = {
    -- Teleports the Player to the Lambda Player
    -- ,goto [target]
    ["goto"] = function( lambda, ply )
        ply.lambdaLastPos = ply:GetPos()
        ply:SetPos( lambda:GetPos() + ( ( ply:GetPos() - lambda:GetPos() ):Angle():Forward() ) * 100 )

        PrintToChat( { colName, ply:GetName(), colText, " teleported to ", colName, lambda:GetLambdaName() } )
    end,

    -- Teleports the Lambda Player to the Player
    -- ,bring [target]
    ["bring"] = function( lambda, ply )
        lambda.lambdaLastPos = lambda:GetPos()
        lambda.CurNoclipPos = ply:GetEyeTrace().HitPos
        lambda:SetPos( ply:GetPos() + ply:GetForward()*100 )

        PrintToChat( { colName, ply:GetName(), colText, " brought ", colName, lambda:GetLambdaName(), colText," to themselves" } )
    end,

    -- Returns the Lambda Player to where they originally were
    -- ,return [target]
    ["return"] = function( lambda, ply )
        if !lambda.lambdaLastPos then ply:PrintMessage( HUD_PRINTTALK, lambda:GetLambdaName().." can't be returned" ) return end
    
        lambda:SetPos( lambda.lambdaLastPos )

        PrintToChat( { colName, ply:GetName(), colText, " returned ", colName, lambda:GetLambdaName(), colText, " back to their original position" } )
    end,

    -- Kills the Lambda Player
    -- ,slay [target]
    ["slay"] = function( lambda, ply )
        local dmginfo = DamageInfo()
        dmginfo:SetDamage( 0 )
        dmginfo:SetAttacker( lambda )
        dmginfo:SetInflictor( lambda )
        lambda:LambdaOnKilled( dmginfo ) -- Could just use TakeDamage but I find this funny

        PrintToChat( { colName, ply:GetName(), colText, " slayed ", colName, lambda:GetLambdaName() } )
    end,

    -- Removes all spawned entities of the Lambda Player
    -- ,clearent [target]
    ["clearents"] = function( lambda, ply )
        lambda:CleanSpawnedEntities()

        PrintToChat( { colName, ply:GetName(), colText, " cleared ", colName, lambda:GetLambdaName(), colText, " entities" } )
    end,

    -- Removes the Lambda Player from the server
    -- ,kick [target] [reason] // Reason defaults to "No reason provided."
    ["kick"] = function( lambda, ply, reason )
        if reason == "" or !reason then
            reason = "No reason provided."
        end

        lambda:Remove()

        PrintToChat( { colName, ply:GetName(), colText, " kicked ", colName, lambda:GetLambdaName(), " ", colText, "(", colName, reason, colText ,")" } )
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

        PrintToChat( { colName, ply:GetName(), colText," slapped ", colName, lambda:GetLambdaName(), colText, " with ", colName, tostring(damage), colText, " damage" } )
    end,

    -- Deals an amount of damage to the Lambda Player an amount of times
    -- ,whip [target] [damage] [times] // damage defaults to 0, times defaults to 1
    ["whip"] = function( lambda, ply, damage, times )
        damage = tonumber(damage) or 0
        times = tonumber(times) or 1

        local direction = Vector( random( 50 )-25, random( 50 )-25, random( 50 ) ) -- Make it random, slightly biased to go up.

        timer.Create( "lambdaplyadmin_whip_"..lambda:EntIndex(),0.5,times,function()
            if !IsValid( lambda ) then timer.Remove( "lambdaplyadmin_whip_"..lambda:EntIndex() ) return end
            if !lambda:IsInNoClip() then
                lambda.loco:Jump()
                lambda.loco:SetVelocity( direction * ( damage + 1 ) )
            end
            
            lambda:EmitSound( slapSounds[ random(#slapSounds) ], 65 )
            
            lambda:TakeDamage( damage, lambda, lambda )
        end)

        PrintToChat( { colName, ply:GetName(), colText, " whipped ", colName, lambda:GetLambdaName(), " ", tostring(times), colText, " times with ", colName, tostring(damage), colText, " damage" } )
    end,

    -- Sets the Lambda Player on fire for an amount of time
    -- ,ignite [target] [time] // Time defaults to 10
    ["ignite"] = function( lambda, ply, time )
        time = tonumber(time) or 10

        lambda:Ignite(time)
        
        PrintToChat( { colName, ply:GetName(), colText, " set ", colName, lambda:GetLambdaName(), " on fire for ", colName, tostring(time), " seconds" } )
    end,

    -- Extinguish the Lambda Player if they are on fire
    -- ,extinguish [target]
    ["extinguish"] = function( lambda, ply )
        if !lambda:IsOnfire() then ply:PrintMessage( HUD_PRINTTALK, lambda:GetLambdaName().." is not on fire" ) return "" end
        
        lambda:Extinguish()
    
        PrintToChat( { colName, plt:GetName(), colText, " extinguished ", colName, lambda:GetLambdaName()} )
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

        PrintToChat( { colName, ply:GetName(), colText," set ", colName, lambda:GetLambdaName(), colText, " health to ", colName, tostring(amount) } )
    end,

    -- Sets the Lambda Player's armor to the given amount
    -- ,setarmor [target] [amount] // Amount defaults to 0
    ["setarmor"] = function( lambda, ply, amount )
        amount = tonumber(amount) or 0

        amount = max( 0, amount ) -- Prevent setting armor to negative

        lambda:SetArmor( amount )

        PrintToChat( { colName, ply:GetName(), colText," set ", colName, lambda:GetLambdaName(), colText, " armor to ", colName, tostring(amount) } )
    end
}



-- -------------------------------- --
-- // SCOREBOARD COMMANDS ACTION // --
-- -------------------------------- --



-- Deal with the scoreboard admin clicky click things
-- I don't know if having net stuff all around the place is smart but it works
util.AddNetworkString("lambdaplyadmin_scoreboardaction")

net.Receive("lambdaplyadmin_scoreboardaction", function()
    local cmd = net.ReadString()
    local lambda = net.ReadEntity( )
    local ply = net.ReadEntity( )

    if ( PACommands[cmd] ) then PACommands[cmd]( lambda, ply ) end
end)



-- ------------------------------- --
-- // TEXT CHAT COMMANDS ACTION // --
-- ------------------------------- --



hook.Add( "PlayerSay", "lambdaplyadminPlayerSay", function( ply, text )
    if string.StartWith(string.lower(text), ",") then -- if it doesn't look like a command, we don't care.

        -- Check if the one inputing the command is an admin and provide hint if not.
        if !ply:IsAdmin() then ply:PrintMessage( HUD_PRINTTALK, "You need to be an admin to use "..c_cmd ) return "" end
        
        -- Extract all the information out of the provided chat line.
        local c_cmd, c_name, c_ex1, c_ex2 = ExtractInfo( text )
        c_cmd = string.sub( c_cmd, 2 ) -- Remove comma
        
        -- Check if a name was provided and provide hint if not.
        if c_name == nil then ply:PrintMessage( HUD_PRINTTALK, c_cmd.." is missing a target" ) return "" end
        
        -- Check if the Lambda exist and provide hint if not.
        local lambda = FindLambda( c_name )
        if !IsValid( lambda ) then ply:PrintMessage( HUD_PRINTTALK, c_name.." is not a valid target" ) return "" end
        
        -- Switch case. It really lightens this part.
        if ( PACommands[c_cmd] ) then PACommands[c_cmd]( lambda, ply, c_ex1, c_ex2 ) else ply:PrintMessage( HUD_PRINTTALK, c_cmd.." is not a valid command" ) end
        return ""
    end
    
end)

end