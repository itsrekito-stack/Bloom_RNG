Run from a Linux environment with liblua5.4:

python3 tools/checks/make_harness.py
python3 tools/checks/lua_check.py

This harness mocks Roblox APIs. It tests service logic and pure transformations, not engine rendering, streaming, network transport, DataStore semantics, or Luau types. Native SmokeTests is provided separately under ServerScriptService/Tests.
