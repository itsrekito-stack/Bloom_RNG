Run from a Linux environment with liblua5.4:

python3 tools/checks/make_harness.py
python3 tools/checks/lua_check.py

This harness mocks Roblox APIs. It tests service logic and pure transformations, not engine rendering, streaming, network transport, DataStore semantics, or Luau types. Native SmokeTests is provided separately under ServerScriptService/Tests.


Phase 2A deterministic persistence/domain regression suite:

python3 tools/checks/phase2a_check.py

Runs the current 19 pure assertions plus Phase 2A fault injection against the
actual DataService source with virtual time, one mock UpdateAsync owner per key,
and simulated lost acknowledgements, hanging operations, leave and shutdown.
The runner uses the existing registry mocks and lowers simple Luau compound
assignments for Lua 5.4. This is not Studio, a native Luau typecheck, or a live
DataStore integration test. The original lua_check.py currently rejects Luau
compound assignments in current source; its old result files are historical.
