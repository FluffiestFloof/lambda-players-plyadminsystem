if SERVER then
    
    util.AddNetworkString("lambdaplyadmin_chatprint")

end

if CLIENT then
    
    net.Receive("lambdaplyadmin_chatprint",function()
        local json = net.ReadString()
        local textargs = util.JSONToTable(json)
        
        chat.AddText(unpack(textargs))
    end)

end 