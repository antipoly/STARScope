STARScope is a gameified STARS (Standard Terminal Automation Replacement System) simulator[^stars], which is the program that real TRACON (Approach) controllers[^tracon] use to see aircraft, weather and procedures on their radar scopes[^stars_faa].

The Terminal Control Workstation (TCW) is the primary interface with which controllers see aircraft. The Radar Data Processor (RDP) produces different symbols on the TCW:
- **Primary Target Symbol:** represents the aircraft's current location and speed, 
- **History Trails:** shows the progression of the aircraft's path
- **Predicted Track Line (PTL)** shows the future trajectory of the aircraft
- **Data Block** shows the critical 

<!-- Beacon Target Symbol: tells information about current aircraft, such as flight information (idk what that means) -->

**Handoffs**
A handoff between a Tower TRACON and ARTCC is facilitated via the Interfacility Data Transfer (IFDT) interface.
In the sim, handoffs are performed by pressing the letter of the controller identifier, then clicking on the aircraft you wish to handoff; it will then turn green.
To receive a handoff, click the flashing aircraft, with a controller identifier letter that is not yours, then it will switch to your identifier and turn white.

**Features**
- **Controller Briefing (Position Relief)**
- **Flight Strips**
- **Frequency Handoffs**
- **SIDs and STARs**
- **VOR/FIX Navigation and Holds**
- **Airspace Depiction**
- **Charts**
- **Weather**
- **Video Maps**

**Video Maps**
Video maps are a group of maps that can be displayed on the STARS scope, that give controllers the boundaries of airspace, fixes, final approach courses, airports, etc. which allow them to guide aircraft to their destination.
[^video_map]: https://www.reddit.com/r/ATC/comments/n03k8i

**Aircraft Commands**
H [*] - To Heading [bearing]
TL/ TR [*] - Turn [degrees] Left/Right
DIR [*] - Direct to [waypoint]

C [*] - Climb to [altitude]
D [*] - Descend to [altitude]
CVS - Climb via SID
DVS - Descend via STAR

**Scope Commands**

**Terminal Control Workstation (TCW)**
- Display Control Bar (DCB)
- Display Control Panels (DCP)
- Range Rings
- Boundary Headings
- System Status Area
  - System Time UTC
  - Barometric Pressure (inHg)
  - Traffic Flow Direction
  - Windspeed and direction for active runways
  - Low Altitude Collision Alert Box
  - Flight Plan List for departing aircraft
  - Preview area
  - Sign on list


---

**Charts, Mapping, and Aeronautical Data**
https://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/

**Aeronautics**
https://aerospaceweb.org/question/performance/q0146.shtml
https://www.grc.nasa.gov/www/k-12/BGP/climb.html

**Sector Files**
https://forum.vatsim.net/t/creating-a-sector-file/5785
https://crc.virtualnas.net/docs/#/README
<!-- https://www.euroscope.hu/wp/download-sectorfiles/ -->

**Speech Recognition**
https://kaldi-asr.org/doc/kaldi_for_dummies.html
https://github.com/alphacep/vosk-api
https://stt.readthedocs.io/en/latest/TRAINING_INTRO.html

---

**Lore**
*you sit infront of a black screen waiting for green blips to pass by*
This is you, and you're an an air traffic control specialist at one of the largest airports in the whole world. Your job is to facilitate the departure and arrival of aircraft, by maintaining separation and keeping them moving, while staying FREE... free from incidents. Think you're up for the job?

**Inspiration**
https://www.openscope.co/
https://vnas.vatsim.net/crc
https://pharr.org/vice/#section-stars
https://www.youtube.com/watch?v=lylTmuhfLME
https://www.youtube.com/@ATCpro



[^stars]: https://en.wikipedia.org/wiki/Standard_Terminal_Automation_Replacement_System
[^tracon]: https://en.wikipedia.org/wiki/Air_traffic_control#Approach_and_terminal_control
[^stars_faa]: https://www.faa.gov/about/office_org/headquarters_offices/ang/offices/tc/library/storyboard/detailedwebpages/stars.html
[^datablock_colors]: https://www.researchgate.net/figure/STARS-Datablock-Format_fig1_235057250
[^datablock_format]: https://www.aircraftspruce.ca/catalog/pdf/ADS-B%20Guide_JFerrera.pdf]
[^datablock_lines]: https://www.researchgate.net/figure/Four-data-block-types-Each-data-block-varied-in-the-number-of-lines-on-the-base-layer_fig2_237445953
[^handoff]: https://www.faa.gov/air_traffic/publications/atpubs/atc_html/chap5_section_4.html