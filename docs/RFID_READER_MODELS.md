# Supplied RFID readers

Research dated 2026-10-08. This describes documentation and implemented protocol
profiles; no physical tests have been performed with these models yet.

| Product | What has been established? | Reading/writing through this library |
| --- | --- | --- |
| [AllesXL 125 kHz EM4100/TK4100 or 13.56 MHz S50/S70](https://allesxl.com/products/rfid-lezer-usb-poort-em4100-tk4100-125-khz-id-ic-13-56-mhz-s-2) | Product text says: place the card on the reader and the card number appears in Notepad/Word. No memory/write commands are documented. | The new keyboard-input component can process the offered number, using the actually configured format. No memory reading/writing is claimed. |
| [ELATEC TWN4 via PPC](https://www.ppc.nl/merken/elatec1616581178/elatec-twn4-multitech-2/) | Configurable reader family; the linked page is for an HF variant. ELATEC Simple Protocol describes explicit memory commands through PRS firmware and USB-CDC/serial. | Keyboard input in keyboard mode; new TWN4 profile for Classic blocks and public Ultralight/EV1/NTAG pages through suitable PRS/CDC firmware. Not universal through keyboard HID. |
| [Amazon EM4100, B0FVM3Z3K4](https://www.amazon.com.be/dp/B0FVM3Z3K4) | Amazon returned HTTP 503; the title/URL names an EM4100 reader. No verifiable write interface or command manual was obtained. | Keyboard input is usable if this device really types text. No confirmed memory/writer support. |
| [Amazon HVLOSNE, B0GWR2SDBX](https://www.amazon.com.be/dp/B0GWR2SDBX) | Amazon returned HTTP 503; the title/URL is insufficient to establish the interface, chip functions or commands. | Exact device behavior/protocol still needs to be checked. No memory/write function is claimed based on the product name. |

**HID is a transport class, not a standard card-memory protocol.** Standard
keyboard output reports control LED status, for example; they are not card-write
commands. A reader that only types a number does not gain RF write capability
from an extra encoder or HID report profile. EM4100/TK4100 identification tags
are not general writable user memory; suitable programmable replacements require
both a writing reader and their own chip protocol.

No automatic firmware switch has been added. For TWN4, the correct PRS/CDC
configuration must already be present. Other vendor-HID memory/writer profiles
can be added once their real command protocol is available. See
[keyboard/report profiles](RFID_HID.md) and [the concrete TWN4 profile](TWN4.md).
