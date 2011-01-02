---------------------------------------------------------------------
-- Project: irc
-- Author: MCvarial
-- Contact: mcvarial@gmail.com
-- Version: 1.0.0
-- Date: 31.10.2010
---------------------------------------------------------------------

local ircers = {}
local chantitles = {}

------------------------------------
-- Irc client
------------------------------------
addEvent("startIRCClient",true)
addEventHandler("startIRCClient",root,
	function ()
		local info = {} -- {channeltitle,{users}}
		for i,channel in ipairs (ircGetChannels()) do
			local users = {}
			for i,user in ipairs (ircGetUsers()) do
				users[i] = {ircGetUserNick(user),ircGetUserLevel(user,channel)}
			end
			local chantitle = ircGetChannelName(channel).." - "..ircGetServerName(ircGetChannelServer(channel))
			table.insert(info,{chantitle,users})
			chantitles[chantitle] = channel
		end
		triggerClientEvent(source,"showIrcClient",root,info)
		table.insert(ircers,source)
	end
)

addEvent("ircSay",true)
addEventHandler("ircSay",root,
	function (chantitle,message)
		ircSay(chantitles[chantitle],getPlayerName(source)..": "..message)
	end
)

addEventHandler("onIRCMessage",root,
	function (channel,message)
		triggerIRCEvent("onClientIRCMessage",ircGetUserNick(source),ircGetChannelTitle(channel),message)
	end
)

addEventHandler("onIRCUserJoin",root,
	function (channel,vhost)
		triggerIRCEvent("onClientIRCUserJoin",ircGetUserNick(source),ircGetChannelTitle(channel),vhost)
	end
)

addEventHandler("onIRCUserPart",root,
	function (channel,reason)
		triggerIRCEvent("onClientIRCUserPart",ircGetUserNick(source),ircGetChannelTitle(channel),reason)
	end
)

addEventHandler("onIRCUserQuit",root,
	function (reason)
		triggerIRCEvent("onClientIRCUserQuit",ircGetUserNick(source),reason)
	end
)

addEventHandler("onIRCNotice",root,
	function (channel,message)
		triggerIRCEvent("onClientIRCNotice",ircGetUserNick(source),ircGetChannelTitle(channel),message)
	end
)

addEventHandler("onIRCUserMode",root,
	function (channel,positive,mode,setter)
		setTimer(triggerIRCEvent,1000,1,"onClientIRCUserMode",ircGetUserNick(source),ircGetChannelTitle(channel),positive,mode,setter,ircGetUserLevel(source))
	end
)

addEventHandler("onIRCChannelMode",root,
	function (positive,mode,setter)
		triggerIRCEvent("onClientIRCChannelMode",ircGetChannelTitle(source),positive,mode,setter)
	end
)

addEventHandler("onIRCUserChangeNick",root,
	function (oldnick,newnick)
		triggerIRCEvent("onClientIRCUserChangeNick",oldnick,newnick)
	end
)

function triggerIRCEvent (eventname,...)
	for i,ircer in ipairs (ircers) do
		triggerClientEvent(ircer,eventname,root,...)

	end
	return true
end

function ircGetChannelTitle (channel)
	return ircGetChannelName(channel).." - "..ircGetServerName(ircGetChannelServer(channel))
end