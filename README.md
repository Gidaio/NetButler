# Intro to NetButler
Hey, welcome to NetButler! I made this small webserver because I wanted to better understand HTTP and HTTP headers and such. It's written completely in Lua, and utilizes the [LuaSocket](http://w3.impa.br/~diego/software/luasocket/) library for the TCP connections and stuff, and is currently made with Lua 5.1. Other than that, I've written all the code by m'self.

## What's in the Package?
In this thing is a sample website, as well as three Lua files, each of which is responsible for a different piece.

* webserver.lua: The main loop that's the jumping-off point for everything else. When you want to boot up the webserver, this is what you run.
* serverfunctions.lua: This is the biggest file, and contains all the functions used elsewhere in NetButler.
* pages.lua: This should really be the only user-customized file, and it's for dynamic or custom pages. See the section called 'Advanced Usage' for further instructions.

## So what can NetButler do?
Not much, honestly. It's got the basics: GET requests. It recognizes four MIME types - text/html, image/png, image/jpg, and image/gif. It has a sort of dynamic page functionality. It can handle percent-encoded GET requests and pull the data from them. It can handle 404s. That's about it, though. :S It also only handles one connection at a time. I guess it could technically handle more, but it won't be pretty, and I haven't tested it. As I stated earlier, this is more for my own educational purposes that actually being a good webserver.

# NetButler Usage
## Basic Usage
Basic usage for NetButler pretty much just entails tossing a bunch of HTML files into the directory where the three source files are. It'll read the files in and send them to a client requesting them. Any request for '/' is translated to a request for '/index.html'.

There's no read protection; i.e., if the client requests ..\\..\\Users\\A\_Dude\\Pictures\\you\_dont\_want\_them\_to\_see\_this.png, NetButler'll send it to them. Fair warning.

## Advanced Usage
If you want to get a little more (only a little) out of NetButler, or you want dynamic pages, check out the pages.lua file. Here's the deal: the pages.lua actually just creates a Lua table called pages. Every entry in that table has an HTTP verb as a key, and another table as a value. Inside THAT table is a bunch of page names as keys and functions as values.

Whenever NetButler gets a request, it lops off the first slash and then attempts to call the function inside that table with the specific request verb, verbatim. If you request 'GET /index.html HTTP/1.1', it'll attempt to call pages.get\["index.html"\]. If it can't find that, it chops off the extension and tries again, i.e. pages.get\["index"\]. If it can't find *that*, *then* it sends off the page, provided MIME types match up.

Feel free to use any of the functions in the serverfunctions.lua file. They're all pretty well documented. Ideally, sendPage and sendFile will be the most used.

### Replacements
So I mentioned dynamic pages. How do those work? Well, in the page, you'll put a variable name inside of ||s, i.e. ||firstname||. Then, when you call sendPage, the final argument is a table. Each entry in the table is a replacement - the key is the value in the page (in this case, "firstname") and the value is the value you want it replaced with.

Note that you can't use a % symbol in the name in the page. (Feel free to use it in the replacement value, though.) This is because Lua's pattern-matching uses the % sign as an escape character, and it's actually pretty hard to reliably escape an escape character. If you do, it won't break anything (except, of course, your page).

# Bugs
If you find any bugs or missing features (but not missing features that I've pointed out in this document) feel free to... do whatever GitHub lets you do to tell me about it.