-- You know what? For now, these are global variables:
--   client
--   request
--   pages
-- If I hit an issue with this later on, I'll change it again.

-- Load the helper functions
dofile("serverfunctions.lua")

-- Load the user-defined pages
dofile("pages.lua")

-- Load LuaSocket
socket = require("socket")

-- Set up the server object.
server = assert(socket.bind("*", 80))

-- Accept requests
while(true) do
	-- Wait for a connection
	print("main: Waiting for connection...")
	client, err = server:accept()

	if(err) then
		print("Error: " .. err)
	end

	-- Set the timeout so stuff doesn't go forever.
	client:settimeout(5)

	-- Print out the request and send it a basic page.
	print("main: Got a connection! Pulling request...\n")
	request, err = getRequest()

	if(not err) then
		print("main: Here's the table I got from getRequest.\n" .. stringifyTable(request))
		handleRequest()
	else
		print("Error: " .. err)
	end

	-- Close the connection with the client
	print("main: Closing connection...")
	client:close()
end
