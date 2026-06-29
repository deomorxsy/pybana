local http = require "http"
local shortport = require "shortport"
local stdnse = require "stdnse"
local string = require "string"

-- metadata
-- lua-literal
local description = [[
    display contents of the generator
    meta-tag of a web page
]]

license = "Same as Nmap--See https://nmap.org/book/man-legal.html"

-- NSEDoc, a custom version of Luadoc
---
-- Prints a formatted debug message if the current verbosity level is greater
-- than or equal to a given level.
--
-- This is a convenience wrapper around
-- <code>nmap.log_write</code>. The first optional numeric
-- argument, <code>level</code>, is used as the debugging level necessary
-- to print the message (it defaults to 1 if omitted). All remaining arguments
-- are processed with Lua's <code>string.format</code> function.
-- @param level Optional debugging level.
-- @param fmt Format string.
-- @param ... Arguments to format.
---

portrule = function(host, port)
    return port.number == 80 or port.number == 443
end

action = function(host, port)
    local socket = nmap.new_socket()
    local target = host.ip .. ":" .. port.number
    local request = "GET / HTTP/1.1\r\nHost: " .. host.ip .. "\r\nConnection: close\r\n\r\n"

    -- open socket and send http request
    socket:connect()
    socket:send(request)

    local status_line = socket:receive_lines(1)
    socket:close()

    if status_line then
        return "Received: " .. status_line
    else
        return "No response from server"
    end
end
