# LambdaPlayers - Player Administration System

An $\color{white}\textsf{unofficial}$ addon for Lambda Players that adds the ability for server admins to administrate Lambdas using the scoreboard / chat commands.

> $\color{#58A6FF}\textsf{\Large\&#x24D8;\kern{0.2cm}\normalsize Note}$ <br>
> This will not make Lambda Players able to administrate the server. This is for Player usage.

It currently overrides the scoreboard provided by the Lambda Players due to the implementation of the ability to right click on scoreboard icons to do certain actions on Lambda Players, so be aware of that.<br>
This is probably going to change. Maybe.

### Admin Commands
Currently implements the following commands;
- ,goto [target]
- ,bring [target]
- ,return [target]
- ,slay [target]
- ,clearents [target]
- ,kick [target] [reason]
- ,slap [target] [damage]
- ,whip [target] [damage] [times]
- ,ignite [target] [time]
- ,extinguish [target]
- ,sethealth [target] [amount]
- ,setarmor [target] [amount]

Chat commands also supports incomplete names and double quotes.<br>
Exemple, if you want to kick a Lambda Player named "Santa Claus The Almighty" you can write `,kick santa "No gift?"` and it will kick that Lambda Player with the reason "No gift?".

The scoreboard also has goto, bring, return, slay, clearents and kick if you right click on a Lambda's Profile Picture
![ss+(2022-12-01+at+10 11 52)](https://user-images.githubusercontent.com/9823203/205160170-fc5c83d2-7bcb-4135-b7de-fe67dc5ba4ec.png)
