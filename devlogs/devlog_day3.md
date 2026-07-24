# Aftersignal — Devlog #3

**Date:** July 25, 2026
**Focus:** Proximity/radio text chat — the core communication mechanic from the design doc

---

## Summary

Building on yesterday's networking work, today was entirely about implementing the game's actual central mechanic: proximity-based communication. Started with basic distance detection, built out a full chat UI, hit a genuinely tricky networking/UI bug along the way, and finished by layering in signal degradation — so communication isn't just "in range / not in range," but actually gets harder to understand the farther apart players are, exactly as the design doc describes. By the end of the session, this is a real, working version of the mechanic the whole game is built around.

---

## 1. Distance Detection

Added the groundwork for proximity-based systems:
- A helper function (`_get_other_player()`) that scans sibling nodes under `Players` to find the other connected character
- A `chat_range` export variable (5 meters) and an `in_chat_range` boolean, recalculated every physics frame based on distance between the two players
- Verified with a temporary debug print before building any UI on top of it — confirmed `in_chat_range` correctly flipped between `true`/`false` as players moved together and apart

## 2. Chat UI

Built out the actual interface:
- A `LineEdit` (`ChatInput`) for typing messages, hidden by default, shown only when in range and a dedicated `toggle_chat` key is pressed
- A `RichTextLabel` (`ChatLog`, upgraded from a plain `Label` partway through) for displaying message history, using BBCode color tags so each player's messages show in their own color (blue host / orange client) with a "Player 1:" / "Player 2:" prefix
- Wired the `LineEdit`'s `text_submitted` signal to a handler that sends the typed message over RPC and clears/hides the input box afterward

## 3. Bug — Messages Overlapping / Only Seeing Your Own

This was the real debugging arc of the day, in three layers:

**Layer 1 — Visual overlap glitch.** Early on, sent messages appeared to render on top of each other on the same line, letters mashed together. Tried `queue_redraw()`, then a `call_deferred` pattern, then rebuilding the log as an array of lines redrawn fresh each time — none of it fixed the actual symptom, which was a good early sign the real bug was somewhere else entirely.

**Layer 2 — The actual cause: duplicate UI per player instance.** Each `Player` scene has its own `CanvasLayer` (holding the chat UI, prompt, etc.). Since both the local and remote player nodes exist in every client's scene tree, **both** were rendering their own `CanvasLayer` at the same screen position — meaning what looked like "overlapping text" was actually two entirely separate chat logs drawing on top of each other. Fixed by explicitly hiding the non-authoritative player's `CanvasLayer` in `_ready()`.

**Layer 3 — One-sided visibility.** After fixing the overlap, a new issue appeared: each player could only see their *own* messages, not incoming ones. Root cause: the chat RPC was being called on the specific `Player` node that sent it — which, once replicated to the other peer, landed on that peer's copy of the *sender's* node (now hidden, per the Layer 2 fix), instead of their own local player's now-visible UI.

**Real fix:** moved message handling to the `NetworkManager` autoload singleton, which exists identically on every peer. Incoming messages are now routed through a shared `receive_chat_message` RPC, which looks up whichever player node currently has *local* authority and writes the message into that one specifically — decoupling "who sent it" from "whose UI displays it."

This was a good lesson in how multiplayer UI needs to be thought about differently from single-player UI — a UI element attached to a replicated character node isn't automatically "your" UI just because it's attached to "your" character concept; it has to be explicitly resolved to the locally-authoritative instance.

## 4. Radio Interference (Signal Degradation)

With basic chat working, layered in the actual "radio" feel called out in the design doc — communication should degrade with distance, not just cut off:

- Added a `clear_range` (2m) alongside the existing `chat_range` (5m outer limit)
- `signal_quality` now computed every frame: `1.0` (perfect) inside `clear_range`, linearly fading down to `0.0` as distance approaches `chat_range`, and `0.0` beyond it
- Wrote a `_garble_text()` function that walks a message character by character, keeping spaces intact but randomly replacing other characters with `-` based on current signal quality — worse quality, more static
- Applied this at send-time, so a message typed near the edge of range now comes through visibly scrambled (e.g. `y----` instead of `yoooo`) while the same message sent up close comes through clean

Tested by moving toward and away from the other player mid-conversation and watching message clarity shift in real time — confirmed working as intended.

## 5. Voice Chat — Explicitly Deferred

Discussed whether to fold voice chat into this session's work. Decision: keep it queued as its own later phase, separate from text chat. Reasoning stays the same as originally scoped — Godot has no built-in voice chat, so it would require integrating an external library or hand-rolling audio streaming, a meaningfully larger and separate technical effort from what text chat needed. Text-based proximity/interference is considered feature-complete for now; voice remains a planned future arc, not started.

---

## 6. What's Confirmed Working End-to-End

- Distance-based proximity detection between two networked players
- Chat UI that only opens within range, closes and sends on Enter
- Colored, labeled messages routed correctly to each peer's own local UI (no cross-talk, no overlap)
- Smooth signal degradation — clean up close, increasingly scrambled with distance, no signal at all past the outer range

## 7. Known Gaps / Not Done Yet

- No visual signal-strength indicator yet — players currently have to infer signal quality from how scrambled their last message looked, no bar/icon feedback
- Still using placeholder H/J keys for host/join — no real menu yet
- Voice chat not started, intentionally deferred
- No real Wing 1 content yet — still testing in the gray-box test room

## Roadmap Status

| Phase | Goal | Status |
|---|---|---|
| 0 | Learn Godot basics | ✅ Done |
| 1 | Room, walking character, lighting | ✅ Done |
| 2 | Two players connected, see each other move | ✅ Done |
| 3 | Radio/proximity chat | ✅ Done (text + interference) |
| 4 | Wing 1 fully playable start to finish | 👉 Next |

## Next Session

Two small polish items before diving into real content: a signal-strength indicator (quick UI addition reusing the existing `signal_quality` value) and a real host/join menu to replace the placeholder keys. After that, Phase 4 — turning the gray-box test room into the actual Landing Bay & Habitation Wing, with real environment art and the first genuine puzzle (a simple code-sharing puzzle, per the design doc's puzzle type table).
