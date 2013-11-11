pages = {
	get = {}
}

---[[
function pages.get.index()
	sendPage("index", { random = math.random(256) })
end
--]]

function pages.get.formresponse()
	sendPage("formresponse", request.data)
end
