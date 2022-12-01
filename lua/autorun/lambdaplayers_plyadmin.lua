local IsValid = IsValid
local pairs = pairs
local random = math.random
local VectorRand = VectorRand
local net = net


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
        if string.lower(v:GetLambdaName()) == string.lower(name) then found = v end
    end

    -- If fails to find a lambda with the full name, tries to find the name somewhere in the Lambdas name.
    if !found then
        for k, v in ipairs( GetLambdaPlayers() ) do
            if string.match( string.lower(v:GetLambdaName()), string.lower(name) ) then found = v end
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
    --[[if buf then
        print("DEBUG: Missing matching quote for "..buf)
    end]] -- They can figure it out themselves.

    return info[1], info[2], info[3] --Only returns the command and two extras. Anything else is voided because who cares
end


-- Helper function to lower clutter that prints to players chat
local function PrintToChat( tbl )
    net.Start( "lambdaplyadmin_chatprint", true )
    net.WriteString( util.TableToJSON(tbl))
    net.Broadcast()
end



-- --------------------------- --
-- // COMMANDS INTERACTIONS // --
-- --------------------------- --



local function GotoLambda(lambda, caller)
    caller.lambdaLastPos = caller:GetPos()
    caller:SetPos( lambda:GetPos() + ( ( caller:GetPos() - lambda:GetPos() ):Angle():Forward() ) * 100 )

    PrintToChat( { Color(0,255,0), "You", Color(130,164,192), " teleported to ", Color(0,255,0), lambda:GetLambdaName() } )
end

local function ReturnLambda(lambda, caller)
    local name = lambda:GetLambdaName()

    if lambda:IsPlayer() then
        name = "Yourself"
    end

    lambda:SetPos( lambda.lambdaLastPos )

    PrintToChat( { Color(0,255,0), "You", Color(130,164,192), " returned ", Color(0,255,0), name, Color(130,164,192), " back to their original position" } )
end

local function BringLambda(lambda, caller)
    lambda.lambdaLastPos = lambda:GetPos()
    lambda.CurNoclipPos = caller:GetEyeTrace().HitPos
    lambda:SetPos( caller:GetPos() + caller:GetForward()*100 )

    PrintToChat( { Color(0,255,0), "You", Color(130,164,192), " brought ", Color(0,255,0), lambda:GetLambdaName(), Color(130,164,192),"to yourself"} )
end

local function SlayLambda(lambda, caller)        
    local dmginfo = DamageInfo()
    dmginfo:SetDamage( 0 )
    dmginfo:SetAttacker( lambda )
    dmginfo:SetInflictor( lambda )
    lambda:LambdaOnKilled( dmginfo )

    PrintToChat( { Color(0,255,0), caller:GetName(), Color(130,164,192), " slayed ", Color(0,255,0), lambda:GetLambdaName() } )
end

local function KickLambda(lambda, caller, reason)
    if reason == "" or !reason then
        reason = "No reason provided."
    end

    lambda:Remove()

    PrintToChat( { Color(0,255,0), caller:GetName(), Color(130,164,192), " kicked ", Color(0,255,0), lambda:GetLambdaName(), " ", Color(130,164,192), "(", Color(0,255,0), reason, Color(130,164,192) ,")" } )
end

local function ClearentsLambda(lambda, caller)
    lambda:CleanSpawnedEntities()

    PrintToChat( { Color(0,255,0), caller:GetName(), Color(130,164,192), " cleared ", Color(0,255,0), lambda:GetLambdaName(), " ", Color(130,164,192), " entities" } )
end

local function IgniteLambda(lambda, caller, length)
    length = tonumber(length) or 10

    lambda:Ignite(length)
    
    PrintToChat( { Color(0,255,0), caller:GetName(), Color(130,164,192), " set ", Color(0,255,0), lambda:GetLambdaName(), " on fire for ", Color(0,255,0), tostring(length), " seconds" } )
end

local function ExtinguishLambda(lambda, caller)
    lambda:Extinguish()
    
    PrintToChat( { Color(0,255,0), caller:GetName(), Color(130,164,192), " extinguished ", Color(0,255,0), lambda:GetLambdaName()} )
end



local slapSounds = { "physics/body/body_medium_impact_hard1.wav", "physics/body/body_medium_impact_hard2.wav", "physics/body/body_medium_impact_hard3.wav", "physics/body/body_medium_impact_hard5.wav", "physics/body/body_medium_impact_hard6.wav", "physics/body/body_medium_impact_soft5.wav", "physics/body/body_medium_impact_soft6.wav", "physics/body/body_medium_impact_soft7.wav" }
local function SlapLambda(lambda, caller, damage)
    damage = tonumber(damage) or 0 -- Prevent player from inputing a name and then complaining about lua errors :)

    local direction = Vector( random( 50 )-25, random( 50 )-25, random( 50 ) ) -- Make it random, slightly biased to go up.

    PrintToChat( { Color(0,255,0), caller:GetName(), Color(130,164,192)," slapped ", Color(0,255,0), lambda:GetLambdaName(), Color(130,164,192), " with ", Color(0,255,0), tostring(damage), Color(130,164,192), " damage" } )

    if !lambda:IsInNoClip() then
        lambda.loco:Jump()
        lambda.loco:SetVelocity(direction * (damage+1))
    end

    lambda:EmitSound( slapSounds[ random(#slapSounds) ], 65 )
    lambda:TakeDamage( damage, lambda, lambda )
end



-- -------------------------------- --
-- // SCOREBOARD COMMANDS ACTION // --
-- -------------------------------- --



-- Deal with the scoreboard admin clicky click things
-- I don't know if having net stuff all around the place is smart but it works
util.AddNetworkString("lambdaplyadmin_scoreboardaction")

net.Receive("lambdaplyadmin_scoreboardaction",function()
    local cmd = net.ReadString()
    local name = net.ReadString()

    -- meh
    if cmd == "slay" then

    elseif cmd == "kick" then

    elseif cmd == "clearent" then

    end

end)



-- ------------------------------- --
-- // TEXT CHAT COMMANDS ACTION // --
-- ------------------------------- --



hook.Add( "PlayerSay", "lambdaplyadminPlayerSay", function( ply, text )
    if string.StartWith(string.lower(text), ",") then
        if !ply:IsAdmin() then ply:PrintMessage( HUD_PRINTTALK, "You need to be an admin to use "..txtcmd ) return "" end
        local txtcmd, txtname, txtextra = ExtractInfo( text )
        
        --Put all the checks here, we always need a target anyway
        if txtname == nil then ply:PrintMessage( HUD_PRINTTALK, txtcmd.." is missing a target" ) return "" end
        
        local lambda = FindLambda( txtname )
        if !IsValid( lambda ) then ply:PrintMessage( HUD_PRINTTALK, txtname.." is not a valid target" ) return "" end

        -- Makes Player go to a Lambda
        -- ,goto [target]
        if txtcmd == ",goto" then
            GotoLambda( lambda, ply )

            return ""
        end

        -- Makes Lambda go to Player
        -- ,bring [target]
        if txtcmd == ",bring" then
            BringLambda(lambda,ply)

            return ""
        end

        -- Return Lambda to previous position after teleportation
        -- ,return [target]
        if txtcmd == ",return" then
            if !lambda.lambdaLastPos then ply:PrintMessage( HUD_PRINTTALK, txtname.." can't be returned" ) return end
            
            ReturnLambda( lambda, ply )

            return ""
        end

        -- Kill a Lambda for evil pleasure
        -- ,slay [target]
        if txtcmd == ",slay" then
            SlayLambda( lambda, ply )
            
            return ""
        end

        -- Clear a Lambda's entities
        -- ,clearent [target]
        if txtcmd == ",clearents" then
            ClearentsLambda(lambda, ply)

            return ""
        end
        
        -- Remove a Lambda from the game
        -- ,kick [target] [reason] // Reason defaults to "No reason provided."
        if txtcmd == ",kick" then
            KickLambda(lambda, ply, txtextra)

            return ""
        end

        -- Slaps a Lambda
        -- ,slap [target] [damage] // Damage defaults to 0
        if txtcmd == ",slap" then
            SlapLambda(lambda, ply, txtextra)

            return ""
        end

        -- Sets a Lambda on fire
        -- ,ignite [target] [time] // Time defaults to 10
        if txtcmd == ",ignite" then
            IgniteLambda(lambda, ply, txtextra)

            return ""
        end

        -- Extinguish a Lambda
        -- ,extinguish [target]
        if txtcmd == ",ignite" then
            if !lambda:IsOnfire() then ply:PrintMessage( HUD_PRINTTALK, lambda:GetLambdaName().." is not on fire" ) return "" end
            ExtinguishLambda(lambda, ply)

            return ""
        end

    end
    
end)

end