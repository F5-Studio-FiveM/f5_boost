<div align="center">

<img src="https://i.imgur.com/121Byzq.jpeg" alt="F5 Boost" width="100%" />

<br /><br />

<a href="https://dc.f5stud.io"><img src="https://img.shields.io/discord/1396957541530865927?label=discord&style=for-the-badge&color=5865F2&labelColor=16161d" alt="Discord" /></a>

<br /><br />

<img src="https://img.shields.io/badge/Standalone-no_framework_needed-f5a623?style=flat-square&labelColor=16161d" alt="Standalone" />&nbsp;
<img src="https://img.shields.io/badge/MySQL-auto--detected-f5a623?style=flat-square&labelColor=16161d" alt="MySQL" />&nbsp;
<img src="https://img.shields.io/badge/Lua_5.4-enabled-f5a623?style=flat-square&labelColor=16161d" alt="Lua 5.4" />&nbsp;
<img src="https://img.shields.io/badge/13_Languages-included-f5a623?style=flat-square&labelColor=16161d" alt="Locales" />

<br /><br />

Client-side FPS optimization tool with a full NUI settings menu.<br />
Graphics presets, quality sliders, performance toggles, saved profiles and share codes.

<br />

[**Read the Docs**](https://docs.f5stud.io/docs/f5-boost/installation) &nbsp;&nbsp;&middot;&nbsp;&nbsp; [**Join Discord**](https://dc.f5stud.io)

</div>

<br />

<img src="https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/rainbow.png" alt="" width="100%" />

<br />

<div align="center">
<h2>Why F5 Boost?</h2>
</div>

<br />

<table align="center">
<tr>
<td align="center" width="25%">
<br />
<img src="https://img.shields.io/badge/-NUI_Menu-f5a623?style=for-the-badge&labelColor=f5a623" alt="" />
<br /><br />
<sub>Draggable, responsive NUI panel with <b>4 tabs</b>: presets, quality sliders, toggles, and profiles. Live FPS counter. Scales from 1080p to 4K.</sub>
<br /><br />
</td>
<td align="center" width="25%">
<br />
<img src="https://img.shields.io/badge/-7_Presets-f5a623?style=for-the-badge&labelColor=f5a623" alt="" />
<br /><br />
<sub>From <b>Ultra</b> to <b>Minimal</b>. One click sets shadows, objects, characters, and vehicle quality. Combine with 3 <b>performance modes</b> for toggles.</sub>
<br /><br />
</td>
<td align="center" width="25%">
<br />
<img src="https://img.shields.io/badge/-Profiles_&_Sharing-f5a623?style=for-the-badge&labelColor=f5a623" alt="" />
<br /><br />
<sub>Save up to <b>5 profiles</b> per player in MySQL. Set a <b>default</b> for new players. Generate <b>share codes</b> to exchange settings instantly.</sub>
<br /><br />
</td>
<td align="center" width="25%">
<br />
<img src="https://img.shields.io/badge/-Standalone-f5a623?style=for-the-badge&labelColor=f5a623" alt="" />
<br /><br />
<sub>No framework needed. <b>Auto-detects</b> your MySQL resource (oxmysql, mysql-async, ghmattimysql). Identifies players by Rockstar license.</sub>
<br /><br />
</td>
</tr>
</table>

<br />

<img src="https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/rainbow.png" alt="" width="100%" />

<br />

<div align="center">
<h2>Quick Start</h2>
</div>

<br />

Place `f5_boost` in your resources folder, then add to `server.cfg`:

```cfg
ensure oxmysql      # or mysql-async / ghmattimysql
ensure f5_boost
```

> **That's it.** The profiles table creates itself on startup. Press `F7` in-game to open the menu.

<br />

<img src="https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/rainbow.png" alt="" width="100%" />

<br />

<div align="center">
<h2>At a Glance</h2>
</div>

<br />

<div align="center">

| | |
|:---|:---|
| **Presets** | Ultra &nbsp;&bull;&nbsp; High &nbsp;&bull;&nbsp; Balanced &nbsp;&bull;&nbsp; Medium &nbsp;&bull;&nbsp; Low &nbsp;&bull;&nbsp; Potato &nbsp;&bull;&nbsp; Minimal |
| **Performance Modes** | Quality &nbsp;&bull;&nbsp; Balanced &nbsp;&bull;&nbsp; Performance |
| **Quality Sliders** | Shadows &nbsp;&bull;&nbsp; Objects &nbsp;&bull;&nbsp; Characters &nbsp;&bull;&nbsp; Vehicles |
| **Toggles** | Clear Events &nbsp;&bull;&nbsp; Light Reflections &nbsp;&bull;&nbsp; Rain & Wind &nbsp;&bull;&nbsp; Blood &nbsp;&bull;&nbsp; Fire &nbsp;&bull;&nbsp; Scenarios |
| **Profiles** | Save / Load / Overwrite / Delete / Default / Share Codes |
| **Database** | oxmysql &nbsp;&bull;&nbsp; mysql-async &nbsp;&bull;&nbsp; ghmattimysql (auto-detected) |
| **Locales** | EN &nbsp;&bull;&nbsp; PL &nbsp;&bull;&nbsp; DE &nbsp;&bull;&nbsp; ES &nbsp;&bull;&nbsp; FR &nbsp;&bull;&nbsp; IT &nbsp;&bull;&nbsp; PT &nbsp;&bull;&nbsp; NL &nbsp;&bull;&nbsp; CS &nbsp;&bull;&nbsp; TR &nbsp;&bull;&nbsp; AR &nbsp;&bull;&nbsp; TH &nbsp;&bull;&nbsp; ZH |
| **Requirements** | Any FiveM server &nbsp;&bull;&nbsp; MySQL &nbsp;&bull;&nbsp; Lua 5.4 |

</div>

<br />

<img src="https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/rainbow.png" alt="" width="100%" />

<br />

<details>
<summary><b>Configuration</b></summary>

<br />

```lua
Config = {}

Config.Locale = 'en'              -- language (13 built-in)
Config.OpenKey = 'F7'             -- default keybind (players can rebind)
Config.Command = 'fpsmenu'        -- chat command
Config.MaxProfiles = 5            -- max saved profiles per player
Config.ShowFPSCounter = true      -- live FPS counter in the menu
Config.DisableDispatch = true     -- disable GTA dispatch services
```

</details>

<details>
<summary><b>What It Optimizes</b></summary>

<br />

| Category | What it does |
|:---|:---|
| **Shadows** | Shadow quality, draw distance, dynamic depth |
| **Density** | How many peds and vehicles spawn around you |
| **Spawning** | Garbage trucks, boats, trains, random cops, distant sirens |
| **Detail** | Level of detail scaling, model budgets, tire tracks, footprints |
| **Effects** | City lights, rain, wind, debris, broken glass, particles, fire |
| **AI** | Background AI reactions, cop spawning, dispatch services |
| **Scenarios** | Ambient NPCs doing activities (sitting, smoking, etc.) |

</details>

<details>
<summary><b>Share Codes</b></summary>

<br />

Players can export their settings as a compact code like `F5-A7K-M3P-X9Q` and share it with others. The code uses Crockford Base32 encoding with a checksum to catch typos.

Encodes: graphics preset, performance mode, 4 slider values, and 6 toggle states into 9 characters.

</details>

<br />

<img src="https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/rainbow.png" alt="" width="100%" />

<br />

<div align="center">

<a href="https://docs.f5stud.io/docs/f5-boost/installation"><img src="https://img.shields.io/badge/read_the_docs-docs.f5stud.io-f5a623?style=for-the-badge&labelColor=16161d&logoColor=white" alt="Documentation" height="35" /></a>
&nbsp;&nbsp;
<a href="https://dc.f5stud.io"><img src="https://img.shields.io/badge/join-discord-5865F2?style=for-the-badge&labelColor=16161d&logoColor=white" alt="Discord" height="35" /></a>
&nbsp;&nbsp;
<a href="https://f5stud.io"><img src="https://img.shields.io/badge/visit-f5stud.io-white?style=for-the-badge&labelColor=16161d&logoColor=white" alt="Website" height="35" /></a>

<br /><br />

<sub>Made by <a href="https://f5stud.io"><b>F5 Studio</b></a></sub>

</div>
