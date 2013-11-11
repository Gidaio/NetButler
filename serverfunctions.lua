-- Reads a text file and returns it as a string, or a nil with the error.
-- Arguments:
--   filePath: The path of the file to read from.
--   binary: An optional boolean flag representing whether to read the file as binary or text.
--     'true' if the file is binary.
--     'false' or missing if the file is text.
-- Returns a string with the file in it.
function readFile(filePath, binary)
	local args, fileHandle, err, fileContent

	-- Make the default value for args
	args = "r"
	if(binary) then
		args = args .. "b"
	end

	-- Attempt to open the file.
	print("readFile: Opening file " .. filePath .. "...\n")
	fileHandle, err = io.open(filePath, args)

	-- Return an error if it occurred.
	if(not fileHandle) then
		return nil, err
	end

	-- Otherwise read the file into a string and return it.
	fileContent = fileHandle:read("*all")
	fileHandle:close()
	return fileContent
end

-- Turns a table into a friendly string... recursively.
-- Arguments:
--   valueToStringify: A table to convert to a string.
--   indent: An optional parameter specifying the initial indent.
--           Mostly just used internally for organization.
-- Returns a string version of the passed in table suitible for display.
function stringifyTable(valueToStringify, indent)
	local output = ""

	if(not indent) then
		indent = 0
	end

	-- Make sure we're actually trying to stringify a table.
	if(type(valueToStringify) ~= "table") then
		return valueToStringify
	end

	for key, value in pairs(valueToStringify) do
		-- Add spaces for each of the indents.
		for i = 1, indent do
			output = output .. " "
		end

		-- Add in the key
		output = output .. key .. ": "

		if(type(value) == "table") then
			output = output .. "\n" .. stringifyTable(value, indent + 1)
		else
			output = output .. tostring(value) .. "\n"
		end
	end

	return output
end

-- This function is the most generic - it just sends a string off.
-- It also performs any replacements as dictated by the table, and
-- it replaces any newlines in the replacement with '<br />' tags.
-- Arguments:
--   code: The HTTP code to send the content with.
--   content: A string containing the content to send off.
--   contentType: The MIME type of the content to send off.
--   replacements: A table containing the items to replace in the content.
--
-- Makes use of the global variable 'client'.
function sendContent(code, content, contentType, replacements)
	local response

	-- Replace the designated words.
	if(replacements ~= nil) then
		for replace, replaceWith in pairs(replacements) do
			print("sendContent: Attempting to replace " .. replace .. " with " .. tostring(replaceWith))

			-- Stringify tables.
			if(type(replaceWith) == "table") then
				output = stringifyTable(replaceWith)
			else
				output = tostring(replaceWith)
			end
			-- Replace all the newlines with breaks
			output = output:gsub("\n", "<br />")
			content = content:gsub("(||" .. sanitizeString(replace) .. "||)", output)
		end
	end

	-- Compile the response and send it back to the client.
	response = "HTTP/1.1 " .. code .. "\r\n"
	response = response .. "Content-Type: " .. contentType .. "\r\n"
	response = response .. "Content-Length: " .. #content .. "\r\n"
	print("sendContent: Sending response with headers:\n" .. response .. "")
	response = response .. "\r\n" .. content
	client:send(response)
end

-- Sends off the 404 page with the specified missing file,
-- or a 500 page in the event of another error.
-- Arguments:
--   missingFile: The name of the file to put on the 404 page.
function send404(missingFile)
	local page, err

	print("send404: 404 error encountered: " .. missingFile .. "\n")

	page, err = readFile(".\\404.html")

	if(page) then
		sendContent("404 NOT FOUND", page, "text/html", { missingFile = missingFile })
	else
		send500(err)
	end
end

-- Sends off the 500 page, or nothing if there's an error.
-- In the event of an error, it prints a message to the console.
-- Arguments:
--   errorMessage: The error message to put on the page.
function send500(errorMessage)
	local page, err

	print("send500: 500 error encountered: " .. errorMessage)

	-- Open the page to send from an external file.
	page, err = readFile(".\\500.html")

	-- Send the page off.
	if(page) then
		sendContent("500 INTERNAL SERVER ERROR", page, "text/html", { errorMessage = errorMessage })
	else
		print("send500: Something seriously went wrong: " .. err)
	end

	print("\n")  -- This is just a thing so each function's returns are separated by empty lines.
end

-- Sends off a 501 page with the specified missing feature,
-- or a 500 page in the event of another error.
-- Arguments:
--   missingFeature: The name of the missing feature to display on the page.
function send501(missingFeature)
	local page, err

	print("send501: 501 error encountered: " .. missingFeature .. "\n")

	-- Open the page to send from an external file.
	page, err = readFile(".\\501.html")

	-- Send the page off.
	if(page) then
		sendContent("501 NOT IMPLEMENTED", page, "text/html", { missingFeature = missingFeature })
	else
		send500(err)
	end
end

-- Manages the sending off of a page. Includes checks for 404 and other errors.
-- Arguments:
--   pageName: The path of the page to send, kinda. Omit the first slash.
--             i.e. folder\page. Leave off the .html, too.
--   replacements: A table containing the replacements to be made to the page.
function sendPage(pageName, replacements)
	local page, err

	print("sendPage: Attempting to send page " .. pageName .. "\n")

	page, err = readFile(".\\" .. pageName .. ".html")

	-- Check for errors
	if(not page) then
		-- 404 not found error.
		if(err == ".\\" .. pageName .. ".html: No such file or directory") then
			send404(pageName)
			return
		end
		-- Catch-all with a generic 500
		send500(err)
	else
		-- No error! Send it off with a 200.
		sendContent("200 OK", page, "text/html", replacements)
		print("sendPage: Success!\n")
	end
end

-- Sends of a file with the specified MIME type. Detects, based on the
-- passed in type, whether or not it should send it as text or binary.
-- Arguments:
--   fileName: The path of the page to send, kinda. Omit the first slash, i.e. folder\page.
--   mimetype: The MIME type to send the file as.
function sendFile(fileName, mimetype)
	local file, err

	print("sendFile: Attempting to send file " .. fileName)

	if(mimetype:find("text/")) then
		print("Sending as text...\n")
		file, err = readFile(".\\" .. fileName)
		if(err) then
			-- Check for a 404
			if(err == ".\\" .. fileName .. ": No such file or directory") then
				send404(fileName)
			end
			-- And a catch all with a 500
			send500(err)
			return
		end
		sendContent("200 OK", file, mimetype)
	else
		print("Sending as binary...\n")
		file, err = readFile(".\\" .. fileName, true)
		if(err) then
			if(err == ".\\" .. fileName .. ": No such file or directory") then
				send404(fileName)
			end
			send500(err)
			return
		end
		sendContent("200 OK", file, mimetype)
	end
end

-- Parses the request into a table, where key is the header name
-- (or verb, path, and version) and value is the actual value.
--
-- Makes use of the global variable 'client'.
function getRequest()
	local toWrite, err, temp, thisRequest, key, value

	-- Get the first line
	toWrite, err = client:receive("*l")
	if(not toWrite) then
		return nil, err
	end

	-- Get the first line's info
	thisRequest = {}
	thisRequest.verb, thisRequest.path, thisRequest.version = toWrite:match("(%S+)%s(%S+)%s(%S+)")

	print("getRequest: ", thisRequest.verb, thisRequest.path, thisRequest.version)

	-- Check to see if the path has any URL-encoded info
	if(thisRequest.path:find("%?")) then
		-- If so, split it along the ?
		thisRequest.path, temp = thisRequest.path:match("(.+)%?(.*)")

		-- Make the table
		thisRequest.data = {}

		-- Iterate through the URL-encoded data and add them to the table
		for key, value in temp:gmatch("([_~%w%-%%%.%+]+)=([_~%w%-%%%.%+]*)") do
			-- Make sure to decode the data first.
			thisRequest.data[percentDecode(key)] = percentDecode(value)
		end
	end

	-- Now get the request headers!
	thisRequest.headers = {}
	toWrite = client:receive("*l")
	while(toWrite ~= "") do
		print("getRequest: " .. toWrite)
		key, value = toWrite:match("([^%s:]+):[ ]*([^%s:]+)")
		thisRequest.headers[key:lower()] = value
		toWrite = client:receive("*l")
	end

	-- If the request exists, send it back; otherwise return an error.
	if(thisRequest.verb and thisRequest.path and thisRequest.version) then
		-- Fix the special cases
		if(thisRequest.path == "/" or thisRequest.path == "/favicon.ico") then
			thisRequest.path = "index.html"
		else
			-- Lop off the first '/' if it exists
			if(thisRequest.path:sub(1, 1) == "/") then
				thisRequest.path = thisRequest.path:sub(2)
			end
		end

		print("")
		return thisRequest
	else
		return nil, "invalid http header"
	end
end

-- Handle the request and get the appropriate page.
--
-- Makes use of the global variables 'request' and 'pages'.
function handleRequest()
	local mimetype, verb, path

	-- Make sure the 'accept' header exists, and make it a string if it doesn't.
	if(not request.headers.accept) then
		print("handleRequest: Request did not contain 'accept' header")
		request.headers.accept = ""
	end

	-- First, get the MIME type of the file they want.
	mimetype = getMIMETypeByExtension(request.path)

	-- Make some variables for easy use.
	verb = request.verb:lower()
	-- Replace all the slashes with underscores
	path = request.path:gsub("(/)", "_"):lower()

	-- Check the pages table to see if it exists...
	if(pages[verb]) then
		if(pages[verb][path]) then
			-- ... and if it does, call it.
			print("handleRequest: Found it in the pages table.\n")
			pages[verb][path]()
			return
		end
	end

	-- No? Alright, lop off the assumed extension and try again.
	pathsplit = {}
	for match in path:gmatch("([^%.]*)%.") do
		table.insert(pathsplit, match)
	end
	path = table.concat(pathsplit, ".")
	if(pages[verb]) then
		if(pages[verb][path]) then
			-- ... and if it does, call it.
			print("handleRequest: Found it in the pages table, sans extension.\n")
			pages[verb][path]()
			return
		end
	end

	-- Still no? Fine. Check that it accepts either the MIME type of the file or any type of file...
	if(request.headers.accept:find(mimetype)
		or request.headers.accept:find("*/*")) then
		-- ... and if it does, send the file raw.
		print("handleRequest: Didn't find it, but MIME types work out.\n")
		sendFile(request.path, mimetype)
		return
	end

	-- Otherwise, they're asking for something that doesn't exist.
	print("handleRequest: Didn't find it, and MIME types are borked.\n")
	send404(request.path .. " with MIME type " .. request.headers.accept)
end

-- Infers the file's MIME type based on its extension.
-- Currently supported:
--   HTML
--   PNG
--   JPG
--   GIF
-- Arguments:
--   filename: The name of the file (with extension) to get the MIME type of.
-- Returns a string containing the passed-in file's MIME type.
function getMIMETypeByExtension(filename)
	-- Do a little data validation.
	if(type(filename) ~= "string") then
		return nil, "filename wasn't a string"
	end

	-- Split the input on periods.
	local splits = {}
	for substring in filename:gmatch("[^%.]+") do
		table.insert(splits, substring)
	end

	-- Determine the MIME type. I REALLY wish Lua had switch-case.
	if(splits[#splits] == "html") then
		return "text/html"
	elseif(splits[#splits] == "png"
		or splits[#splits] == "jpg"
		or splits[#splits] == "gif") then
		return "image/" .. splits[#splits]
	else
		return nil, "unknown mime type"
	end
end

-- Decodes all the percent symbols in a URL.
-- Arguments:
--   strToDecode: The string containing the percent-encoding needed to decode.
-- Returns the decoded string.
function percentDecode(strToDecode)
	-- First, replace all the plus signs. Do the pluses first, because
	-- some of the other percent-decoding may make extra plus signs!
	strToDecode = strToDecode:gsub("%+", " ")

	-- Now we decode the other percent-encoded stuff.
	strToDecode = strToDecode:gsub("%%([%da-fA-F][%da-fA-F])",
	function(hexNumber)
		return string.char(tonumber(hexNumber, 16))
	end)

	-- And now we return the string!
	return strToDecode
end

-- Sanitizes the given string for use with Lua's patterns. If the string contains
-- a '%', it doesn't sanitize it and instead returns an empty string, because
-- string.gsub does weird things with it the way I have it implemented.
-- Arguments:
--   strToSanitize: The string containing 'magic' characters to sanitize.
-- Returns a sanitized version of the passed-in string.
function sanitizeString(strToSanitize)
	-- If it contains a '%', we can't santize it. Return an empty string.
	if(strToSanitize:find("%%")) then
		return ""
	end

	-- Escape all the 'magic characters'.
	for char in string.gmatch("^$().[]*+-?", ".") do
		strToSanitize = strToSanitize:gsub("%" .. char, "%%" .. char)
	end

	return strToSanitize
end
