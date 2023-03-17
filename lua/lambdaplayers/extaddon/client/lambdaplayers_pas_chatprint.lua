-- TODO: Eventually replace this with the built in Lambda Player chat print.

net.Receive("lambdaplayers_pas_chatprint",function()
    local json = net.ReadString()
    local textargs = util.JSONToTable(json)
    
    chat.AddText(unpack(textargs))
end)