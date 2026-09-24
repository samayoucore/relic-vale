# Phase 7 acceptance

The required 35-step scenario is covered by the final integration, graphical, extended and fresh-process runs. Tests automate public gameplay methods and game-clock advancement; marker editing and recruitment also have real pointer input checks. Terrain is actually streamed and scenes rendered. Visual-only tier previews use the provided debug-equivalent tier settings; an additional economic test independently earns all upgrades.

1. Explore multiple actual regions: generated and charted 161 chunks across starter and distant regions. PASS

2. Open the world atlas in the running graphical game. PASS

3. Review terrain-derived forests, rivers, roads and settlement/service icons in atlas screenshots. PASS

4. Create a saved custom marker; extended GUI run also uses a real right click and pointer rename. PASS

5. Move to a clearing at logical chunk 6, −6, several chunks from the marker. PASS

6. Travel back to the marker through the player travel service. PASS

7. Assert at least 25 destination chunks are ready and the loading page closes before control resumes. PASS

8. Find an open, dry, suitably flat camp masterplan site away from roads and other sites. PASS

9. Establish a physical camp, reserve the site and verify the placement preview in the graphical run. PASS

10. Advance two game minutes and verify a guaranteed physical traveler. PASS

11. Recruit the first resident; final visual run also accepts a nearby traveler with actual mouse input. PASS

12. Open the persistent task board, inspect categories and locked requirement explanations. PASS

13. Assign a starter foraging contract to one resident with no upfront donation. PASS

14. Advance game time past the mission end. PASS

15. Receive independent camp supplies, Camp XP and resident XP exactly once. PASS

16. Advance a game day and recruit the next visitor. PASS

17. Assign and resolve a two-resident mission; extended tests also exercise parties of three and four. PASS

18. Add enough Camp XP to reach the current upgrade threshold. PASS

19. Assert upgrade_pending and Camp XP exactly at the threshold. PASS

20. Complete another XP-producing firewood assignment. PASS

21. Assert Camp XP remains unchanged while the upgrade is pending. PASS

22. Assert mission resources still increase; implementation awards Food, Materials and Gold independently of XP. PASS

23. Donate wood and personal coins with exact debit checks; player UI uses explicit confirmations. PASS

24. Purchase an affordable camp upgrade using camp supplies. PASS

25. Assert XP resets to zero and upgrade_pending clears, with no overflow banking. PASS

26. Render the changed camp tier. PASS

27. Render all five tiers; extended economy test reaches every tier with one resident and zero donations in 57 contracts. PASS

28. Enter the player house, inspect veteran cottages/newcomer tents, verify a sleeping veteran inside their assigned home and enter the permanent workshop. PASS

29. Move to logical chunk 1000000000002, −999999999998 and verify the camp scene is unloaded. PASS

30. Travel back using the permanent camp marker and the same safe-loading pipeline. PASS

31. Verify resident count and camp resource balances survived unloading. PASS

32. Save a tier-5 camp with workers, markers, supplies and one active mission to an isolated integration slot. PASS

33. Quit the test game after audio shutdown. PASS

34. Start a fresh Godot process and load that saved integration slot. PASS

35. Verify markers, camp tier, residents, active mission and resources; advance game time and verify rewards resolve once. PASS

See PHASE_7_TEST_RESULTS.json for exact run logs. Earlier failing development runs are retained in downloads for traceability and are excluded from the passing release evidence. Extra/visual/reload tests now suppress automatic writes to the shared integration fixture, so state-mutating exploratory checks cannot change the restart test input.
