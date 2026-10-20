# Lua API reference

Signatures for the Q-SYS Lua extension globals. Consult QSC's Q-SYS Help pages
for anything this does not cover.

Globals are installed before the chunk loads; no `require` unless noted.

## Controls

One control state, four coupled fields. Writing any one recomputes the others.

| Property | Access | Notes |
| --- | --- | --- |
| `.Value` | R/W | Float |
| `.String` | R/W | |
| `.Position` | R/W | 0.0–1.0 |
| `.Boolean` | R/W | True when position > 0.5 |
| `.Index` | R | |
| `.Legend` | R/W | Assigning `IconData` JSON draws an image; see SKILL.md |
| `.Choices` | R/W | Assigning promotes a Text control to a combo box |
| `.IsDisabled`, `.IsInvisible` | R/W | Run time only |
| `.Color` | W | **String only** — raises on a table |
| `.RampTime` | R/W | Accepted on any control; only meaningful on some |
| `.EventHandler` | R/W | `function(control)` |

```lua
Controls.gain.EventHandler = function(c) print(c.Value, c.String) end
Controls.gain.Value = 0.5           -- script write: does NOT run the handler
for _, c in ipairs(Controls.bank) do print(c.String) end   -- Count > 1 only
```

`Count == 1` raises on `[1]`. Detect a group:

```lua
local is_group = pcall(function() return Controls.foo[1] end)
```

## Timer

Never scope a timer to a local — the GC will collect it.

```lua
t = Timer.New()
t.EventHandler = function(timer) ... end
t:Start(1.5)        -- seconds; repeats
t:Stop()
t:IsRunning()

Timer.CallAfter(fn, 2)   -- one-shot
Timer.Now()              -- seconds since the epoch
```

## HttpClient

`Get`, `Post`, `Put`, `Patch`, `Delete`, `Download`, `Upload`, plus
`CreateUrl`, `EncodeParams`, `EncodeString`, `DecodeString`.

```lua
HttpClient.Download {
  Url = "http://host/api",
  Headers = { ["Content-Type"] = "application/json" },
  Timeout = 5,
  EventHandler = function(tbl, code, data, err, headers) ... end,
}
```

A transport failure that never reached the server calls the handler with
`code = 0` and a non-empty `err`.

## TcpSocket

```lua
sock = TcpSocket.New()
sock.ReadTimeout = 0          -- seconds, 0 disables
sock.ReconnectTimeout = 5     -- 0 disables auto-reconnect
sock.EventHandler = function(s, event, err) ... end
sock:Connect("10.0.0.1", 23)
sock:Write("hi\r\n")
sock:ReadLine(TcpSocket.EOL.Any)
sock:Close()
```

| Member | Notes |
| --- | --- |
| `.IsConnected`, `.BufferLength`, `.PeerAddress` | Read-only |
| `.ReadTimeout`, `.WriteTimeout`, `.ReconnectTimeout` | Seconds |
| `:Read(n)`, `:ReadLine(EOL, custom)`, `:Search(str)` | `ReadLine` returns `nil` if no EOL yet |
| `TcpSocket.Events` | `Connected`, `Reconnect`, `Data`, `Closed`, `Error`, `Timeout` |
| `TcpSocket.EOL` | `Any`, `CrLf`, `CrLfStrict`, `Lf`, `Null`, `Custom` |

TLS: set `.CACertData` to a PEM certificate, or use the verify-none mode, then
`:Connect`. Assigning a non-certificate raises.

## TcpSocketServer

A listener that emits a `TcpSocket` per incoming connection.

```lua
server = TcpSocketServer.New()
server.EventHandler = function(sock)     -- a new TcpSocket instance
  sock.EventHandler = function(s, event) ... end
end
server:Listen(5000)
server:Close()
```

## UdpSocket

```lua
udp = UdpSocket.New()
udp.EventHandler = function(sock, packet) print(packet.Address, packet.Data) end
udp:Open("192.168.1.100", 2468)      -- address optional
udp:JoinMulticast("224.0.23.175")
udp:Send(host, port, data)
udp:Close()
udp.MulticastTtl = 4                 -- default
```

Sending on an unopened socket raises.

## WebSocket

```lua
ws = WebSocket.New()
ws.Connected = function(w) end
ws.Data      = function(w, data) end
ws.Error     = function(w, err) end
ws.Closed    = function(w) end
ws.Pong      = function(w) end
ws:Connect(protocol, host, url, port, sub_protocol, headers)  -- e.g. "wss", h, "/qrc", 443
ws:Write(data)
ws:Ping()
ws:Close()
```

Writing before the connection opens raises.

## Crypto

```lua
Crypto.Base64Encode(s) / Base64Decode(s)
Crypto.MD5Compute(s)            -- hex
Crypto.CRC16Compute(s)          -- ARC variant
Crypto.Digest(alg, data)        -- raw bytes
Crypto.HMAC(alg, key, data)     -- raw bytes
Crypto.PBKDF2(alg, pass, salt, iterations, length)
Crypto.Encrypt(cipher, key, iv, plaintext, padding)
Crypto.Decrypt(cipher, key, iv, ciphertext, padding)
Crypto.GetRandomBytes(n)
Crypto.Hash.SHA256   -- and MD5, SHA1, SHA384, SHA512
Crypto.Cipher.AES_256_CBC
```

`Digest` and `HMAC` return raw bytes, not hex.

## Component

Reach controls in another named component in the same design.

```lua
comp = Component.New("Name")
comp["control 1"].String = "x"
comp["control 1"].EventHandler = function(c) ... end   -- watch another component

Component.GetComponents()        -- all, or filter by name
Component.GetControls(comp)      -- each entry has Name, Type, Direction, Value...
```

`Component.New` on an unknown name yields a table whose controls are `nil`
rather than raising. A write through a component runs the *owner's* handler, not
the writer's.

## `Design`, `System`, `Network`, `Log`

```lua
Design.GetStatus()      -- DesignName, Platform, IsRedundant, DesignCode
Design.GetInventory()   -- array of { Type, Name, Location, Model, Status }

System.IsEmulating      -- boolean field, NOT a function
System.Version          -- "10.4.1"
System.MajorVersion, System.MinorVersion, System.BuildVersion, System.LockingId

Network.GetHostByName(h)   -- { name, addresses = {...} }; blocks
Network.Interfaces()       -- Interface, Address, MACAddress, BroadcastAddress, Gateway, Netmask

Log.Message(s)          -- system log, Info
Log.Error(s)            -- system log, Error
```

`System` members are plain fields. `if System.IsEmulating then` is the standard
guard for faking device feedback offline.

## Ping

```lua
p = Ping.New("www.qsys.com")      -- host as a plain string
p.EventHandler = function(r) print(r.HostName, r.ElapsedTime) end
p.ErrorHandler = function(r) print(r.HostName, r.Error) end
p:setPingInterval(1.0)
p:setTimeoutInterval(10.0)
p:start()
p:stop()
```

`Ping.New` with no host raises. Some hosts also accept `Ping:New(host)`.

## Notifications

Publish/subscribe between scripts in one design.

```lua
id = Notifications.Subscribe("name", function(name, data) ... end)
Notifications.Publish("name", data)     -- table or string
Notifications.Unsubscribe(id)
```

Calling `Publish` inside a `Subscribe` callback raises.

## require-based modules

| Module | Use |
| --- | --- |
| `rapidjson` | `encode`, `decode`, `null`, `load`, `Document`. JSON `null` decodes to the `rapidjson.null` sentinel, not `nil` |
| `json` | The `json4lua` implementation. `encode`, `decode`, `null`. Differs from `rapidjson` on nulls, holes and empty tables. `require "json"` also sets the global |
| `EzSVG` | SVG generation. `EzSVG.Document(w,h)`, `:add()`, `:toString()`, `EzSVG.Rect/Text/Circle/...` |
| `QRCode` | `QRCode.GenerateSVG(text)` |
| `lpeg`, `bitstring`, `LuaXML`, `date` | Parsing and formatting helpers |

```lua
rapidjson = require "rapidjson"
local t = rapidjson.decode(body)
if t.field == rapidjson.null then ... end     -- identity, not == nil
```

## Further globals

Documented by QSC and not detailed here: `NamedControl`, `Uci`, `Snapshot`,
`ChannelGroup`, `SerialPorts`, `SerialServerPorts`, `Ssh`, `SNMP`, `SNMPTrap`,
`Email`, `Dante`, `dir`, and USB HID. Several depend on hardware or on design
features that only exist inside a real Core, so check availability before
relying on one.
