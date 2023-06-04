addon.author = 'Poroburu';
addon.name = 'kpacket';
addon.version = '0.1.0';

local ffi = require("ffi")  -- load the FFI library

-- Load the DLL
local libsodium = ffi.load(ffi.os == "Windows" and string.format('%saddons\\debug\\libzmq-v141-4_3_4\\libsodium.dll', AshitaCore:GetInstallPath()));
local libzmq = ffi.load(ffi.os == "Windows" and string.format('%saddons\\debug\\libzmq-v141-4_3_4\\libzmq.dll', AshitaCore:GetInstallPath()));
require('common');
local lzmq = require('lzmq')
local msgpack = require('MessagePack') -- Add MessagePack library
local utils = require('utils')


local kp = {
    zeromq = {}
}

-- Create a ZeroMQ context and REQ socket
local zctx = lzmq.context()
local zsocket, err = zctx:socket(lzmq.PUB)
if not zsocket then
    print("Error creating ZeroMQ socket:", err)
    return
end

-- Connect the socket to the F# application
local addr = "tcp://127.0.0.1:6666"
zsocket:bind(addr)

-- Use MessagePack for serialization
msgpack.set_string'string'
kp.serialize = msgpack.pack
kp.deserialize = msgpack.unpack

function string.tobytearray(str)
    local byteArray = {}
    for i = 1, #str do
        byteArray[i] = string.byte(str, i)
    end
    return byteArray
end

local onceTypes = true
ashita.events.register('packet_in', 'packet_in_callback1', function (e)
    -- Send the packet data via ZeroMQ if the F# application has started parsing
    
    local packetData = {
        id = e.id,
        size = e.size,
        data = string.tobytearray(e.data), -- string.fromhex(e.data) --string.hexformat_file(e.data,e.size)
    }
    local serializedPacketData = kp.serialize(packetData)
    zsocket:send(serializedPacketData)

    if onceTypes then
        print(string.tohex(e.data))
        -- print the types of the fields
        for key, value in pairs(packetData) do
            print("Type of " .. key .. ": " .. type(value))
            print(value)
        end
        onceTypes = false
    end
end)

ashita.events.register('command', 'command_cb', function (e)
    -- Parse the command arguments..
    local args = e.command:args()
    if (#args == 0 or not args[1]:any('/kp')) then
        return
    end
    -- Block all related commands..
    e.blocked = true

end)
