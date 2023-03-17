-- ------------- --
-- // CONVARS // --
-- ------------- --


CreateLambdaConvar( "lambdaplayers_pas_enabled", 1, true, false, false, "Enables the player administration system that allows player admin to do certain actions on Lambda Players using chat commands", 0, 1, { name = "Enable Player Admin System", type = "Bool", category = "Player Admin System" } )
CreateLambdaConvar( "lambdaplayers_pas_chatecho", 1, true, false, false, "Whenever the commands being used should be printed in the chat", 0, 1, { name = "Enable Commands Chat Print", type = "Bool", category = "Player Admin System" } )
CreateLambdaConvar( "lambdaplayers_pas_cmdprefix", ",", true, false, false, "The prefix used for chat commands. This will only accept one character!", nil, nil, { type = "Text", name = "Command Prefix", category = "Player Admin System" } )
