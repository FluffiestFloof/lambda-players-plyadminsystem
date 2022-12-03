if SERVER then
    
    util.AddNetworkString("lambdaplayers_pas_chatprint")

end

if CLIENT then
    
    net.Receive("lambdaplayers_pas_chatprint",function()
        local json = net.ReadString()
        local textargs = util.JSONToTable(json)
        
        chat.AddText(unpack(textargs))
    end)

end 