local IsValid = IsValid
local pairs = pairs
local random = math.random
local VectorRand = VectorRand
local net = net

if SERVER then -- Player admin commands will be handled here
    
    local function GotoLambda(lambda, caller)
        net.Start( "lambdaplyadmin_chatprint", true )
        net.WriteString( util.TableToJSON({ Color(0,255,0), "You", Color(130,164,192), " teleported to ", Color(0,255,0), lambda:GetLambdaName() }))
        net.Broadcast()

        caller.lambdaLastPos = caller:GetPos()
        caller:SetPos( lambda:GetPos() + ( ( caller:GetPos() - lambda:GetPos() ):Angle():Forward() ) * 100 )
    end

    local function ReturnLambda(lambda, caller)
        if lambda.lambdaLastPos then
            local name = lambda:GetLambdaName()

            if lambda:IsPlayer() then
                name = "Yourself"
            end

            net.Start( "lambdaplyadmin_chatprint", true )
            net.WriteString( util.TableToJSON({ Color(0,255,0), "You", Color(130,164,192), " returned ", Color(0,255,0), name, Color(130,164,192), " back to their original position" }))
            net.Broadcast()

            lambda:SetPos( lambda.lambdaLastPos )
        end
    end

    local function BringLambda(lambda, caller)
        net.Start( "lambdaplyadmin_chatprint", true )
        net.WriteString(util.TableToJSON({ Color(0,255,0), "You", Color(130,164,192), " brought ", Color(0,255,0), lambda:GetLambdaName(), Color(130,164,192),"to yourself"}))
        net.Broadcast()

        lambda.lambdaLastPos = lambda:GetPos()
        lambda.CurNoclipPos = caller:GetEyeTrace().HitPos
        lambda:SetPos( caller:GetPos() + caller:GetForward()*100 )
    end

    local function SlayLambda(lambda, caller)
        net.Start( "lambdaplyadmin_chatprint", true )
        net.WriteString( util.TableToJSON({ Color(0,255,0), caller:GetName(), Color(130,164,192), " slayed ", Color(0,255,0), lambda:GetLambdaName() }))
        net.Broadcast()
        
        local dmginfo = DamageInfo()
        dmginfo:SetDamage( 0 )
        dmginfo:SetAttacker( lambda )
        dmginfo:SetInflictor( lambda )
        lambda:LambdaOnKilled( dmginfo )
    end

    local function KickLambda(lambda, caller, reason)
        if reason == "" or !reason then
            reason = "No reason provided."
        end

        net.Start( "lambdaplyadmin_chatprint", true )
        net.WriteString( util.TableToJSON({ Color(0,255,0), caller:GetName(), Color(130,164,192), " kicked ", Color(0,255,0), lambda:GetLambdaName(), " ", Color(130,164,192), "(", Color(0,255,0), reason, Color(130,164,192) ,")" }))
        net.Broadcast()

        lambda:Remove()
    end

    --[[
    local function PlayerBanZeta(zeta,caller,reason,time)
        local length = time or 60
        if reason == "" or !reason then
            reason = "No reason provided."
        end
        if GetConVar("zetaplayer_adminprintecho"):GetBool() then
            local name = zeta.zetaname


            net.Start("zeta_sendcoloredtext",true)
            net.WriteString(util.TableToJSON({Color(0,255,0),caller:GetName(),Color(130,164,192)," banned ",Color(0,255,0),name,Color(130,164,192)," for ",Color(0,255,0),tostring(length),Color(130,164,192)," second(s) ",Color(130,164,192),"(",Color(0,255,0),reason,Color(130,164,192),")"}))
            net.Broadcast()
        end
        if zeta.IsJailed then
            RemoveJailOnEnt(zeta)
        end
        local id = zeta:GetCreationID()
        _bannedzetas[id] = zeta.zetaname
        timer.Simple(length,function()
            _bannedzetas[id] = nil
        end)
        if IsValid(zeta.Spawner) then
            zeta.Spawner:Remove()
        end
        zeta:Remove()
    end

    local function PlayerslapZeta(ent,caller,damage)
        damage = tonumber(damage) or 0 -- Prevent player from slapping a Zeta with another Zeta
        if GetConVar("zetaplayer_adminprintecho"):GetBool() then

            local name = ent.zetaname

            net.Start("zeta_sendcoloredtext",true)
            net.WriteString(util.TableToJSON({Color(0,255,0),caller:GetName(),Color(130,164,192)," slapped ",Color(0,255,0),name,Color(130,164,192)," with ",Color(0,255,0),tostring(damage),Color(130,164,192)," damage"}))
            net.Broadcast()
        end
        if ent.IsZetaPlayer then
            ent.IsJumping = true 
            ent:SetLastActivity(ent:GetActivity())
            ent.loco:Jump()
            ent.loco:SetVelocity(VectorRand(-1000,1000))
        end
        ent:EmitSound("physics/body/body_medium_impact_hard"..math.random(1,6)..".wav",65)
        ent:TakeDamage(damage,caller,caller)
    end


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
        local split = string.Explode(" ",text)

        if split[1] == ",goto" then
            if split[2]==nil then ply:PrintMessage( HUD_PRINTTALK, split[1].." is missing a target") return "" end
            local name = split[2]

            local lambda = FindLambda( name )
            if !IsValid(zeta) then ply:PrintMessage(HUD_PRINTTALK,name.." is not valid") return "" end

            GotoLambda( lambda, ply )
            return ""
        end

        if split[1] == ",bring" then
            if split[2]==nil then ply:PrintMessage(HUD_PRINTTALK,split[1].." is missing a target") return "" end
            local name = split[2]

            local lambda = FindLambda(name)
            if !IsValid(lambda) then ply:PrintMessage(HUD_PRINTTALK,name.." is not valid") return "" end

            BringLambda(lambda,ply)
            return ""
        end

        if split[1] == ",return" then
            if split[2]==nil then ply:PrintMessage(HUD_PRINTTALK,split[1].." is missing a target") return "" end
            local name = split[2]

            local lambda = FindLambda(name)
            if !IsValid(lambda) then ply:PrintMessage(HUD_PRINTTALK,name.." is not valid") return "" end
            if !lambda.lambdaLastPos then ply:PrintMessage(HUD_PRINTTALK,name.." can't be returned") return "" end
            
            ReturnLambda( lambda, ply )
            return ""
        end

        if split[1] == ",slay" then
            if split[2]==nil then ply:PrintMessage(HUD_PRINTTALK,split[1].." is missing a target") return "" end
            local name = split[2]

            local lambda = FindLambda(name)
            if !IsValid(lambda) then ply:PrintMessage(HUD_PRINTTALK,name.." is not valid") return "" end

            SlayLambda( lambda, ply )
            return ""
        end
        
        if split[1] == ",kick" then
            if split[2]==nil then ply:PrintMessage(HUD_PRINTTALK,split[1].." is missing a target") return "" end
            local name = split[2]

            local lambda = FindLambda( name )
             if !IsValid(lambda) then ply:PrintMessage( HUD_PRINTTALK, name.." is not valid") return "" end

            local reason = string.Replace( text, name )
            reason = string.Replace(reason, ",kick ", "")

            KickLambda(lambda, ply, reason)
            return ""
        end

        --[[
        if split[1] == ",ban" then
            if split[2]==nil then ply:PrintMessage(HUD_PRINTTALK,split[1].." is missing a target") return "" end
            local reason = ""
            local time 
            local name 
            for k,v in ipairs(split) do
                if k == 2 then
                    name = v
                elseif k == 3 then
                    time = v
                elseif k >= 4 then
                    reason = reason..v.." "
                end
            end

            local zeta = FindZetaByName(name)

            if !IsValid(zeta) then ply:PrintMessage(HUD_PRINTTALK,name.." is not valid") return "" end

            PlayerBanZeta(zeta,ply,reason,tonumber(time))
            return ""
        end

        if split[1] == ",slap" then
            if split[2]==nil then ply:PrintMessage(HUD_PRINTTALK,split[1].." is missing a target") return "" end
            local name = split[2]
            local dmg = split[3] or 0
            local zeta = FindZetaByName(name)

            if !IsValid(zeta) then ply:PrintMessage(HUD_PRINTTALK,name.." is not valid") return "" end

            PlayerslapZeta(zeta,ply,dmg)
            return ""
        end

        if split[1] == ",whip" then
            if split[2]==nil then ply:PrintMessage(HUD_PRINTTALK,split[1].." is missing a target") return "" end
            local name = split[2]
            local dmg = split[3] or 0
            local times = split[4] or 10

            local zeta = FindZetaByName(name)

            if !IsValid(zeta) then ply:PrintMessage(HUD_PRINTTALK,name.." is not valid") return "" end

            PlayerWhipZeta(zeta,ply,dmg,times)
            return ""
        end

        if split[1] == ",ignite" then
            if split[2]==nil then ply:PrintMessage(HUD_PRINTTALK,split[1].." is missing a target") return "" end
            local name = split[2]
            local length = split[3] or 5
            local zeta = FindZetaByName(name)

            if !IsValid(zeta) then ply:PrintMessage(HUD_PRINTTALK,name.." is not valid") return "" end

            PlayerigniteZeta(zeta,ply,length)
            return ""
        end

        if split[1] == ",sethealth" then
            if split[2]==nil then ply:PrintMessage(HUD_PRINTTALK,split[1].." is missing a target") return "" end
            local name = split[2]
            local hp = split[3] or 100
            local zeta = FindZetaByName(name)

            if !IsValid(zeta) then ply:PrintMessage(HUD_PRINTTALK,name.." is not valid") return "" end

            PlayersethealthZeta(zeta,ply,hp)
            return ""
        end

        if split[1] == ",setarmor" then
            if split[2]==nil then ply:PrintMessage(HUD_PRINTTALK,split[1].." is missing a target") return "" end
            local name = split[2]
            local armor = split[3] or 0
            local zeta = FindZetaByName(name)

            if !IsValid(zeta) then ply:PrintMessage(HUD_PRINTTALK,name.." is not valid") return "" end

            PlayersetarmorZeta(zeta,ply,armor)
            return ""
        end

        if split[1] == ",god" then
            if split[2]==nil then ply:PrintMessage(HUD_PRINTTALK,split[1].." is missing a target") return "" end
            local name = split[2]
            local zeta = FindZetaByName(name)

            if !IsValid(zeta) then ply:PrintMessage(HUD_PRINTTALK,name.." is not valid") return "" end
            if zeta.zetaIngodmode then ply:PrintMessage(HUD_PRINTTALK,name.." is already in god mode") return "" end

            PlayerGodModeZeta(zeta,ply)
            return ""
        end

        if split[1] == ",ungod" then
            if split[2]==nil then ply:PrintMessage(HUD_PRINTTALK,split[1].." is missing a target") return "" end
            local name = split[2]
            local zeta = FindZetaByName(name)

            if !IsValid(zeta) then ply:PrintMessage(HUD_PRINTTALK,name.." is not valid") return "" end
            if !zeta.zetaIngodmode then ply:PrintMessage(HUD_PRINTTALK,name.." is already a mortal") return "" end

            PlayerUnGodZeta(zeta,ply)
            return ""
        end

        if split[1] == ",jail" then
            if split[2]==nil then ply:PrintMessage(HUD_PRINTTALK,split[1].." is missing a target") return "" end
            local name = split[2]
            local zeta = FindZetaByName(name)

            if !IsValid(zeta) then ply:PrintMessage(HUD_PRINTTALK,name.." is not valid") return "" end
            if zeta.IsJailed then ply:PrintMessage(HUD_PRINTTALK,name.." is already in jail") return "" end

            PlayerjailZeta(zeta,ply)
            return ""
        end

        if split[1] == ",tpjail" then
            if split[2]==nil then ply:PrintMessage(HUD_PRINTTALK,split[1].." is missing a target") return "" end
            local name = split[2]
            local zeta = FindZetaByName(name)

            if !IsValid(zeta) then ply:PrintMessage(HUD_PRINTTALK,name.." is not valid") return "" end
            if zeta.IsJailed then ply:PrintMessage(HUD_PRINTTALK,name.." is already in jail") return "" end

            PlayertpjailZeta(zeta,ply)
            return ""
        end
        
        if split[1] == ",unjail" then
            if split[2]==nil then ply:PrintMessage(HUD_PRINTTALK,split[1].." is missing a target") return "" end
            local name = split[2]
            local zeta = FindZetaByName(name)

            if !IsValid(zeta) then ply:PrintMessage(HUD_PRINTTALK,name.." is not valid") return "" end
            if !zeta.IsJailed then ply:PrintMessage(HUD_PRINTTALK,name.." is not in jail") return "" end

            PlayerunjailZeta(zeta,ply)
            return ""
        end ]]
        
    end)

end