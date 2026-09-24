# Phase 5 streamed-world checks

15 passed; 0 failed.

- PASS: Shared terrain edge agrees at [3, 0]
- PASS: River field crosses shared edge at [3, 0]
- PASS: Shared terrain edge agrees at [10000, -500]
- PASS: River field crosses shared edge at [10000, -500]
- PASS: Shared terrain edge agrees at [1000000000, -1000000000]
- PASS: River field crosses shared edge at [1000000000, -1000000000]
- PASS: Travel through 100 neighboring chunks using asynchronous generation
- PASS: Repeated floating-origin shifts occur during travel
- PASS: Data cache and active scene counts remain bounded
- PASS: Far chunks contain physical resource nodes
- PASS: Far resource interaction changes its stable delta
- PASS: Far journey writes version 5 and separate delta records
- PASS: Main save stores references instead of generated scenery or aggregate resource records
- PASS: Far v5 journey reloads in-session
- PASS: Exact resource delta survives in-session reload
