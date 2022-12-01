if SERVER then
    
    util.AddNetworkString("lambdaplyadmin_chatprint")

    function FindLambda( name )
        if !name then return end
        local lambdas = ents.FindByClass("npc_lambdaplayer")
        local found

        for k, v in ipairs( GetLambdaPlayers() ) do
            if v:GetLambdaName() == name then found = v end
        end

        return found
    end

end

if CLIENT then
    
    net.Receive("lambdaplyadmin_chatprint",function()
        local json = net.ReadString()
        local textargs = util.JSONToTable(json)
        
        chat.AddText(unpack(textargs))
    end)

end 