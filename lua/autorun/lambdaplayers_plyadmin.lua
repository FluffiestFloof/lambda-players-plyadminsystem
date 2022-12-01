local IsValid = IsValid
local pairs = pairs
local random = math.random
local VectorRand = VectorRand
local net = net


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

    for k, v in ipairs( GetLambdaPlayers() ) do
        if string.match( string.lower(v:GetLambdaName()), string.lower(name) ) then found = v end
    end

    return found
end

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

if SERVER then

    local function PrintToChat( tbl )
        net.Start( "lambdaplyadmin_chatprint", true )
        net.WriteString( util.TableToJSON(tbl))
        net.Broadcast()
    end
    
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

        PrintToChat( { Color(0,255,0), caller:GetName(), Color(130,164,192), " cleared ", Color(0,255,0), lambda:GetLambdaName(), " ", Color(130,164,192), " entities", } )
    end


    local slapSounds = {
        "physics/body/body_medium_impact_hard1.wav",
        "physics/body/body_medium_impact_hard2.wav",
        "physics/body/body_medium_impact_hard3.wav",
        "physics/body/body_medium_impact_hard5.wav",
        "physics/body/body_medium_impact_hard6.wav",
        "physics/body/body_medium_impact_soft5.wav",
        "physics/body/body_medium_impact_soft6.wav",
        "physics/body/body_medium_impact_soft7.wav",
    }

    local function SlapLambda(lambda, caller, damage)
        damage = tonumber(damage) or 0 -- Prevent player from inputing a name and then posting about lua errors :)

        local direction = Vector( random( 50 )-25, random( 50 )-25, random( 50 )-10 ) -- Make it random, slightly biased to go up.

        PrintToChat( { Color(0,255,0), caller:GetName(), Color(130,164,192)," slapped ", Color(0,255,0), lambda:GetLambdaName(), Color(130,164,192), " with ", Color(0,255,0), tostring(damage), Color(130,164,192), " damage" } )

        if !lambda:IsInNoClip() then
            lambda.loco:Jump()
            lambda.loco:SetVelocity(direction * damage)
        end

        lambda:EmitSound( slapSounds[ random(#slapSounds) ], 65 )
        lambda:TakeDamage( damage, lambda, lambda )
    end

    --[[
    local function PlayerWhipZeta(ent,caller,damage,times)
        damage = tonumber(damage) or 0
        times = tonumber(times) or 1
        if GetConVar("zetaplayer_adminprintecho"):GetBool() then
            local name = ent.zetaname


            net.Start("zeta_sendcoloredtext",true)
            net.WriteString(util.TableToJSON({Color(0,255,0),caller:GetName(),Color(130,164,192)," whipped ",Color(0,255,0),name," ",tostring(times),Color(130,164,192)," times with ",Color(0,255,0),tostring(damage),Color(130,164,192)," damage"}))
            net.Broadcast()
        end
        local rndid = math.random(0,100000)
        timer.Create("zetaadminwhip"..rndid,0.5,times,function()
            if !IsValid(ent) then timer.Remove("zetaadminwhip"..rndid) return end
            if ent.IsZetaPlayer then
                ent.IsJumping = true 
                ent:SetLastActivity(ent:GetActivity())
                ent.loco:Jump()
                ent.loco:SetVelocity(VectorRand(-1000,1000))
            end
            ent:EmitSound("physics/body/body_medium_impact_hard"..math.random(1,6)..".wav",65)
            ent:TakeDamage(damage,caller,caller)
        end)

    end

    local function PlayerigniteZeta(ent,caller,length)
        length = tonumber(length) or 5
        if GetConVar("zetaplayer_adminprintecho"):GetBool() then
            local name = ent.zetaname
            net.Start("zeta_sendcoloredtext",true)
            net.WriteString(util.TableToJSON({Color(0,255,0),caller:GetName(),Color(130,164,192)," ignited ",Color(0,255,0),name,Color(130,164,192)," for ",Color(0,255,0),tostring(length)," seconds"}))
            net.Broadcast()
        end
        ent:Ignite(length)
    end

    local function PlayersethealthZeta(ent,caller,amount)
        amount = tonumber(amount)
        if GetConVar("zetaplayer_adminprintecho"):GetBool() then

            local name = ent.zetaname

            net.Start("zeta_sendcoloredtext",true)
            net.WriteString(util.TableToJSON({Color(0,255,0),caller:GetName(),Color(130,164,192)," set ",Color(0,255,0),name,Color(130,164,192)," health to ",Color(0,255,0),tostring(amount)}))
            net.Broadcast()
        end
        ent:SetHealth(amount)
    end

    local function PlayersetarmorZeta(ent,caller,amount)
        if !IsValid(ent) or !IsValid(self) then return end
        amount = tonumber(amount)
        if GetConVar("zetaplayer_adminprintecho"):GetBool() then
            local name = ent.zetaname

            net.Start("zeta_sendcoloredtext",true)
            net.WriteString(util.TableToJSON({Color(0,255,0),self.zetaname,Color(130,164,192)," set ",Color(0,255,0),name,Color(130,164,192)," armor to ",Color(0,255,0),tostring(amount)}))
            net.Broadcast()
        end
        if ent.IsZetaPlayer then
            ent.CurrentArmor = amount
        end
    end

    local function PlayerGodModeZeta(ent,caller)
        if GetConVar("zetaplayer_adminprintecho"):GetBool() then

            local name = ent.zetaname

            net.Start("zeta_sendcoloredtext",true)
            net.WriteString(util.TableToJSON({Color(0,255,0),caller:GetName(),Color(130,164,192)," granted god mode upon ",Color(0,255,0),name}))
            net.Broadcast()
        end
        ent.zetaIngodmode = true
    end

    local function PlayerUnGodZeta(ent,caller)
        if GetConVar("zetaplayer_adminprintecho"):GetBool() then

            local name = ent.zetaname

            net.Start("zeta_sendcoloredtext",true)
            net.WriteString(util.TableToJSON({Color(0,255,0),caller:GetName(),Color(130,164,192)," revoked god mode from ",Color(0,255,0),name}))
            net.Broadcast()
        end
        ent.zetaIngodmode = false
    end

    local function PlayerjailZeta(ent,caller)

        if GetConVar("zetaplayer_adminprintecho"):GetBool() then

            local name = ent.zetaname


            net.Start("zeta_sendcoloredtext",true)
            net.WriteString(util.TableToJSON({Color(0,255,0),caller:GetName(),Color(130,164,192)," jailed ",Color(0,255,0),name}))
            net.Broadcast()
        end
        ent.IsJailed = true
        CreateJailOnEnt(ent)
    end

    local function PlayerunjailZeta(ent,caller)

        if GetConVar("zetaplayer_adminprintecho"):GetBool() then

            local name = ent.zetaname


            net.Start("zeta_sendcoloredtext",true)
            net.WriteString(util.TableToJSON({Color(0,255,0),caller:GetName(),Color(130,164,192)," unjailed ",Color(0,255,0),name}))
            net.Broadcast()
        end
        ent.IsJailed = false
        RemoveJailOnEnt(ent)
    end

    local function PlayertpjailZeta(ent,caller)
        if GetConVar("zetaplayer_adminprintecho"):GetBool() then

            local name = ent.zetaname

            net.Start("zeta_sendcoloredtext",true)
            net.WriteString(util.TableToJSON({Color(0,255,0),caller:GetName(),Color(130,164,192)," teleported and jailed ",Color(0,255,0),name}))
            net.Broadcast()
        end
        ent.lambdaLastPos = ent:GetPos()
        ent.CurNoclipPos = caller:GetEyeTrace().HitPos
        ent:SetPos(caller:GetEyeTrace().HitPos)
        ent.IsJailed = true
        CreateJailOnEnt(ent)
    end ]]

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
            -- ,kick [target] [reason]
            if txtcmd == ",kick" then
                KickLambda(lambda, ply, txtextra)

                return ""
            end

            if txtcmd == ",slap" then
                SlapLambda(lambda, ply, txtextra)

                return ""
            end

            --[[
            if txtcmd == ",whip" then
                
                local dmg = split[3] or 0
                local times = split[4] or 10

                local zeta = FindZetaByName(name)

                if !IsValid(zeta) then ply:PrintMessage(HUD_PRINTTALK,name.." is not valid") return "" end

                PlayerWhipZeta(zeta,ply,dmg,times)
                return ""
            end

            if txtcmd == ",ignite" then
                
                local length = split[3] or 5
                local zeta = FindZetaByName(name)

                if !IsValid(zeta) then ply:PrintMessage(HUD_PRINTTALK,name.." is not valid") return "" end

                PlayerigniteZeta(zeta,ply,length)
                return ""
            end

            if txtcmd == ",sethealth" then
                
                local hp = split[3] or 100
                local zeta = FindZetaByName(name)

                if !IsValid(zeta) then ply:PrintMessage(HUD_PRINTTALK,name.." is not valid") return "" end

                PlayersethealthZeta(zeta,ply,hp)
                return ""
            end

            if txtcmd == ",setarmor" then
                
                local armor = split[3] or 0
                local zeta = FindZetaByName(name)

                if !IsValid(zeta) then ply:PrintMessage(HUD_PRINTTALK,name.." is not valid") return "" end

                PlayersetarmorZeta(zeta,ply,armor)
                return ""
            end

            if txtcmd == ",god" then
                
                local zeta = FindZetaByName(name)

                if !IsValid(zeta) then ply:PrintMessage(HUD_PRINTTALK,name.." is not valid") return "" end
                if zeta.zetaIngodmode then ply:PrintMessage(HUD_PRINTTALK,name.." is already in god mode") return "" end

                PlayerGodModeZeta(zeta,ply)
                return ""
            end

            if txtcmd == ",ungod" then
                
                local zeta = FindZetaByName(name)

                if !IsValid(zeta) then ply:PrintMessage(HUD_PRINTTALK,name.." is not valid") return "" end
                if !zeta.zetaIngodmode then ply:PrintMessage(HUD_PRINTTALK,name.." is already a mortal") return "" end

                PlayerUnGodZeta(zeta,ply)
                return ""
            end

            if txtcmd == ",jail" then
                
                local zeta = FindZetaByName(name)

                if !IsValid(zeta) then ply:PrintMessage(HUD_PRINTTALK,name.." is not valid") return "" end
                if zeta.IsJailed then ply:PrintMessage(HUD_PRINTTALK,name.." is already in jail") return "" end

                PlayerjailZeta(zeta,ply)
                return ""
            end

            if txtcmd == ",tpjail" then
                
                local zeta = FindZetaByName(name)

                if !IsValid(zeta) then ply:PrintMessage(HUD_PRINTTALK,name.." is not valid") return "" end
                if zeta.IsJailed then ply:PrintMessage(HUD_PRINTTALK,name.." is already in jail") return "" end

                PlayertpjailZeta(zeta,ply)
                return ""
            end
            
            if txtcmd == ",unjail" then
                
                local zeta = FindZetaByName(name)

                if !IsValid(zeta) then ply:PrintMessage(HUD_PRINTTALK,name.." is not valid") return "" end
                if !zeta.IsJailed then ply:PrintMessage(HUD_PRINTTALK,name.." is not in jail") return "" end

                PlayerunjailZeta(zeta,ply)
                return ""
            end ]]
        end
        
    end)

end