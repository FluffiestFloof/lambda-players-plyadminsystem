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



local function PAGotoLambda(lambda, caller)
    caller.lambdaLastPos = caller:GetPos()
    caller:SetPos( lambda:GetPos() + ( ( caller:GetPos() - lambda:GetPos() ):Angle():Forward() ) * 100 )

    PrintToChat( { colName, caller:GetName(), colText, " teleported to ", colName, lambda:GetLambdaName() } )
end


local function PAReturnLambda(lambda, caller)
    lambda:SetPos( lambda.lambdaLastPos )

    PrintToChat( { colName, caller:GetName(), colText, " returned ", colName, lambda:GetLambdaName(), colText, " back to their original position" } )
end


local function PABringLambda(lambda, caller)
    lambda.lambdaLastPos = lambda:GetPos()
    lambda.CurNoclipPos = caller:GetEyeTrace().HitPos
    lambda:SetPos( caller:GetPos() + caller:GetForward()*100 )

    PrintToChat( { colName, caller:GetName(), colText, " brought ", colName, lambda:GetLambdaName(), colText," to themselves" } )
end


local function PASlayLambda(lambda, caller)        
    local dmginfo = DamageInfo()
    dmginfo:SetDamage( 0 )
    dmginfo:SetAttacker( lambda )
    dmginfo:SetInflictor( lambda )
    lambda:LambdaOnKilled( dmginfo ) -- Could just use TakeDamage but I find this funny

    PrintToChat( { colName, caller:GetName(), colText, " slayed ", colName, lambda:GetLambdaName() } )
end


local function PAKickLambda(lambda, caller, reason)
    if reason == "" or !reason then
        reason = "No reason provided."
    end

    lambda:Remove()

    PrintToChat( { colName, caller:GetName(), colText, " kicked ", colName, lambda:GetLambdaName(), " ", colText, "(", colName, reason, colText ,")" } )
end


local function PAClearentsLambda(lambda, caller)
    lambda:CleanSpawnedEntities()

    PrintToChat( { colName, caller:GetName(), colText, " cleared ", colName, lambda:GetLambdaName(), colText, " entities" } )
end


local function PAIgniteLambda(lambda, caller, length)
    length = tonumber(length) or 10

    lambda:Ignite(length)
    
    PrintToChat( { colName, caller:GetName(), colText, " set ", colName, lambda:GetLambdaName(), " on fire for ", colName, tostring(length), " seconds" } )
end


local function PAExtinguishLambda(lambda, caller)
    lambda:Extinguish()
    
    PrintToChat( { colName, caller:GetName(), colText, " extinguished ", colName, lambda:GetLambdaName()} )
end


local slapSounds = { "physics/body/body_medium_impact_hard1.wav", "physics/body/body_medium_impact_hard2.wav", "physics/body/body_medium_impact_hard3.wav", "physics/body/body_medium_impact_hard5.wav", "physics/body/body_medium_impact_hard6.wav", "physics/body/body_medium_impact_soft5.wav", "physics/body/body_medium_impact_soft6.wav", "physics/body/body_medium_impact_soft7.wav" }
local function PASlapLambda(lambda, caller, damage)
    damage = tonumber(damage) or 0 -- Prevent player from inputing a name and then complaining about lua errors :)

    local direction = Vector( random( 50 )-25, random( 50 )-25, random( 50 ) ) -- Make it random, slightly biased to go up.

    PrintToChat( { colName, caller:GetName(), colText," slapped ", colName, lambda:GetLambdaName(), colText, " with ", colName, tostring(damage), colText, " damage" } )

    if !lambda:IsInNoClip() then
        lambda.loco:Jump()
        lambda.loco:SetVelocity( direction * ( damage + 1 ) )
    end

    lambda:EmitSound( slapSounds[ random(#slapSounds) ], 65 )

    lambda:TakeDamage( damage, lambda, lambda )
end

local function PAWhipLambda(lambda, caller, damage, times)
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

    PrintToChat( { colName, caller:GetName(), colText, " whipped ", colName, lambda:GetLambdaName(), " ", tostring(times), colText, " times with ", colName, tostring(damage), colText, " damage" } )
end

local function PASetHealthLambda(lambda, caller, amount)
    if amount <= 0 then 
        lambda:TakeDamage( lambda:GetMaxHealth()*5, lambda, lambda ) -- Prevent setting health to negative :)
    else
        lambda:SetHealth(amount)
    end

    PrintToChat( { colName, caller:GetName(), colText," set ", colName, lambda:GetLambdaName(), colText, " health to ", colName, tostring(amount) } )
end


local function PASetArmorLambda(lambda, caller, amount)
    amount = max( 0, amount ) -- Prevent setting armor to negative

    lambda:SetArmor( amount )

    PrintToChat( { colName, caller:GetName(), colText," set ", colName, lambda:GetLambdaName(), colText, " armor to ", colName, tostring(amount) } )
end


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

    -- meh
    if cmd == "slay" then
        PASlayLambda( lambda, ply )
    elseif cmd == "kick" then
        PAKickLambda( lambda, ply )
    elseif cmd == "clearents" then
        PAClearentsLambda( lambda, ply )
    elseif cmd == "goto" then
        PAGotoLambda( lambda, ply )
    elseif cmd == "bring" then
        PABringLambda( lambda, ply )
    elseif cmd == "return" then
        PAReturnLambda( lambda, ply )
    end

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
        
        -- Check if a name was provided and provide hint if not.
        if c_name == nil then ply:PrintMessage( HUD_PRINTTALK, c_cmd.." is missing a target" ) return "" end
        
        -- Check if the Lambda exist and provide hint if not.
        local lambda = FindLambda( c_name )
        if !IsValid( lambda ) then ply:PrintMessage( HUD_PRINTTALK, c_name.." is not a valid target" ) return "" end

        -- Commands below here.

        -- Makes Player go to a Lambda
        -- ,goto [target]
        if c_cmd == ",goto" then
            PAGotoLambda( lambda, ply )

            return ""
        end

        -- Makes Lambda go to Player
        -- ,bring [target]
        if c_cmd == ",bring" then
            PABringLambda( lambda, ply )

            return ""
        end

        -- Return Lambda to previous position after teleportation
        -- ,return [target]
        if c_cmd == ",return" then
            if !lambda.lambdaLastPos then ply:PrintMessage( HUD_PRINTTALK, c_name.." can't be returned" ) return end
            
            PAReturnLambda( lambda, ply )

            return ""
        end

        -- Kill a Lambda for evil pleasure
        -- ,slay [target]
        if c_cmd == ",slay" then
            PASlayLambda( lambda, ply )
            
            return ""
        end

        -- Clear a Lambda's entities
        -- ,clearent [target]
        if c_cmd == ",clearents" then
            PAClearentsLambda( lambda, ply )

            return ""
        end
        
        -- Remove a Lambda from the game
        -- ,kick [target] [reason] // Reason defaults to "No reason provided."
        if c_cmd == ",kick" then
            PAKickLambda( lambda, ply, c_ex1 )

            return ""
        end

        -- Slaps a Lambda
        -- ,slap [target] [damage] // Damage defaults to 0
        if c_cmd == ",slap" then
            PASlapLambda(lambda, ply, c_ex1)

            return ""
        end

        -- Whips a Lambda
        -- ,whip [target] [damage] [times] // damage defaults to 0, times defaults to 1
        if c_cmd == ",whip" then
            c_ex1 = tonumber(c_ex1) or 0
            c_ex2 = tonumber(c_ex2) or 1
            PAWhipLambda(lambda, ply, c_ex1, c_ex2)

            return ""
        end

        -- Sets a Lambda on fire, you monster
        -- ,ignite [target] [time] // Time defaults to 10
        if c_cmd == ",ignite" then
            PAIgniteLambda(lambda, ply, c_ex1)

            return ""
        end

        -- Extinguish a Lambda
        -- ,extinguish [target]
        if c_cmd == ",extinguish" then
            if !lambda:IsOnfire() then ply:PrintMessage( HUD_PRINTTALK, lambda:GetLambdaName().." is not on fire" ) return "" end
            PAExtinguishLambda(lambda, ply)

            return ""
        end

        -- Set a Lambda's Health
        -- ,sethealth [target] [amount] // Amount defaults to 0
        if c_cmd == ",sethealth" then
            c_ex1 = tonumber(c_ex1) or 0
            PASetHealthLambda(lambda, ply, c_ex1)

            return ""
        end

        -- Set a Lambda's Armor
        -- ,setarmor [target] [amount] // Amount defaults to 0
        if c_cmd == ",setarmor" then
            c_ex1 = tonumber(c_ex1) or 0
            PASetArmorLambda(lambda, ply, c_ex1)

            return ""
        end

    end
    
end)

end