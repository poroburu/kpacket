addon.author = 'Poroburu';
addon.name = 'kpacket';
addon.version = '0.2.0';

local ffi = require("ffi")  -- load the FFI library

-- Load the DLL
local libsodium = ffi.load(ffi.os == "Windows" and string.format('%saddons\\kpacket\\libzmq-v141-4_3_4\\libsodium.dll', AshitaCore:GetInstallPath()));
local libzmq = ffi.load(ffi.os == "Windows" and string.format('%saddons\\kpacket\\libzmq-v141-4_3_4\\libzmq.dll', AshitaCore:GetInstallPath()));
require('common');
local lzmq = require('lzmq')

-- Create a ZeroMQ context and REQ socket
local zctx = lzmq.context()
local zsocket, err = zctx:socket(lzmq.PUB)
if not zsocket then
    print("Error creating ZeroMQ socket:", err)
    return
end

local addr = "tcp://127.0.0.1:4567"
zsocket:bind(addr)

-- Connect the socket to the F# application
ashita.events.register('packet_in', 'packet_in_callback1', function (e)
    zsocket:send(e.data)
end)

ashita.events.register('command', 'command_cb', function (e)
    -- Parse the command arguments..
    local args = e.command:args()
    if (#args == 0 or not args[1]:any('/kp')) then
        return
    end
    if args[1]:any('/kp') then
        print("send")
        zsocket:send("send")
    end
    -- Block all related commands..
    e.blocked = true

end)
