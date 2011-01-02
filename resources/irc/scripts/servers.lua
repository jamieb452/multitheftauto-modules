---------------------------------------------------------------------
-- Project: irc
-- Author: MCvarial
-- Contact: mcvarial@gmail.com
-- Version: 1.0.0
-- Date: 31.10.2010
---------------------------------------------------------------------

-- everything is saved here
servers = {} -- syntax: [server] = {element socket,string name,string host,string nick,string password,number port,bool secure,string nickservpass,string authident, string authpass,number lastping,timer timeoutguard,number reconnectattempts, table channels,bool connected,table buffer}

------------------------------------
-- Servers
------------------------------------
function func_ircRaw (server,data)
	if servers[server] and servers[server][1] then
		if servers[server][15] then
			writeLog("-> "..data)
			return sockWrite(servers[server][1],data.."\r\n")
		end
		table.insert(servers[server][16],data)
		return true
	end
	return false
end

function func_ircHop (channel,reason)
	if channels[channel] then
		local name = channels[channel][1]
		local password = channels[channel][6]
		if ircPart(channel) then
			return ircJoin(name,password)
		end
	end
	return false
end

function func_ircSay (target,message)
	if #message > 400 then
		for i=1,math.ceil(#message/400) do
			ircSay(target,string.sub(message,(i-1)*400,i*400))
		end
		return true
	end
	local server = getElementParent(target)
	local channel = ircGetChannelName(target)
	local user = ircGetUserNick(target)
	if server then
		local localuser = ircGetUserFromNick(ircGetServerNick(server))
		if localuser then
			if channel then
				triggerEvent("onIRCMessage",localuser,target,message)
			else
				triggerEvent("onIRCPrivateMessage",target,message)
			end
		end
		return ircRaw(server,"PRIVMSG "..(channel or user).." :"..(message or "<no message>"))
	end
	return false
end

function func_ircPart (server,channel,reason)
	if servers[server] and channels[channel] then
		if getElementType(server) == "irc-server" then
			local channelName = ircGetChannelName(channel)
			if channelName then
				if reason then
					return ircRaw(server,"PART "..channelName.." :"..reason)
				else
					return ircRaw(server,"PART "..channelName)
				end
			end
		end
	end
	return false
end

function func_ircJoin (server,channel,password)
	if servers[server] then
		local chan = createElement("irc-channel")
		setElementParent(chan,server)
		if #getElementsByType("irc-channel") == 1 then
			channels[chan] = {channel,"+nst","Unknown",{},password,false,true}
		else
			channels[chan] = {channel,"+nst","Unknown",{},password,false,false}
		end
		if password then
			ircRaw(server,"JOIN "..channel.." :"..password)
		else
			ircRaw(server,"JOIN "..channel)
		end
		return chan
	else
		return false
	end
end

function func_ircAction (channel,message)
	if #message > 400 then
		for i=1,math.ceil(#message/400) do
			ircAction(channel,string.sub(message,(i-1)*400,i*400))
		end
		return true
	end
	local server = getElementParent(channel,0)
	local channelName = ircGetChannelName(channel)
	if server and channelName then
		return ircRaw(server,"ACTION "..channelName.." :"..(message or "<no message>"))
	end
	return false
end

function func_ircNotice (target,message)
	if #message > 400 then
		for i=1,math.ceil(#message/400) do
			ircNotice(target,string.sub(message,(i-1)*400,i*400))
		end
		return true
	end
	local server = getElementParent(target,0)
	local targetName = ircGetChannelName(target)
	if not targetName then
		targetName = ircGetUserNick(target)
	end
	if server and targetName then
		return ircRaw(server,"NOTICE "..targetName.." :"..(message or "<no message>"))
	end
	return false
end

function func_outputIRC (message)
	if #message > 400 then
		for i=1,math.ceil(#message/400) do
			outputIRC(string.sub(message,(i-1)*400,i*400))
		end
		return true
	end
	for channel,info in pairs (channels) do
		if info[7] then
			local server = getElementParent(channel)
			local localuser = ircGetUserFromNick(ircGetServerNick(server))
			if server then
				if localuser then
					triggerEvent("onIRCMessage",localuser,channel,message)
				end
				return ircRaw(server,"PRIVMSG "..info[1].." :"..(message or "<no message>"))
			end
		end
	end
	return false
end

function func_ircIdentify (server,password)
	if servers[server] then
		servers[server][8] = password
		return ircRaw(server,"PRIVMSG NickServ :IDENTIFY "..(password or ""))
	end
	return false
end

function func_ircConnect (host,nick,port,password,secure)
	local server = createElement("irc-server")
	local socket = sockOpen(host,(port or 6667),secure)
	local timer = setTimer(connectingTimedOut,10000,0,server)
	if server and socket then
		servers[server] = {socket,host,host,nick,password,port,secure,false,false,false,getTickCount(),timer,0,{},false,{}}
		triggerEvent("onIRCConnecting",server)
		return server
	end
	return false
end

function func_ircReconnect (server)
	if servers[server] then
		if servers[server][15] then
			servers[server][15] = false
			ircRaw(server,"QUIT :Reconnect")
		end
		sockClose(servers[server][1])
		servers[server][1] = sockOpen(servers[server][2],servers[server][6],servers[server][7])
		return true
	end
	return false
end

function func_ircDisconnect (server,reason)
	if servers[server] then
		ircRaw(server,"QUIT :"..(reason or "Disconnect"))
		sockClose(servers[server][1])
		servers[server] = nil
		return destroyElement(server)
	end
	return false
end

function func_ircChangeNick (server,newnick)
	if servers[server] and type(newnick) == "string" then
		servers[server][4] = newnick
		return ircRaw(server,"NICK :"..newnick)
	end
	return false
end

function func_ircGetServers ()
	return getElementsByType("irc-server")
end
	
function func_ircGetServerName (server)
	if servers[server] then
		return servers[server][2]
	end
	return false
end

function func_ircGetServerHost (server)
	if servers[server] then
		return servers[server][3]
	end
	return false
end

function func_ircGetServerPort (server)
	if servers[server] then
		return servers[server][6]
	end
	return false
end

function func_ircGetServerPass (server)
	if servers[server] then
		return servers[server][5]
	end
	return false
end

function func_ircGetServerNick (server)
	if servers[server] then
		return servers[server][4]
	end
	return false
end

function func_ircIsServerSecure (server)
	if servers[server] then
		return servers[server][7]
	end
	return false
end

function func_ircGetServerChannels (server)
	if servers[server] then
		return servers[server][14]
	end
	return false
end

function connectingTimedOut (server)
	triggerEvent("onIRCFailConnect",server,"Connection timed out")
	return ircReconnect(server)
end

function checkForTimeout (server)
	--[[
	if not servers[server][15] then
		return ircReconnect(server)
	end
	if (getTickCount() - servers[server][11]) > 240000 then
		return ircReconnect(server)
	end
	ircRaw(server,"PING "..servers[server][3])
	]]
end