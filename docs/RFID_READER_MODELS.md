# Aangeleverde RFID-readers

Onderzoek op 2026-10-08. Dit beschrijft documentatie en geïmplementeerde
protocolprofielen; er zijn nog geen fysieke tests met deze modellen uitgevoerd.

| Product | Wat is vastgesteld? | Lezen/schrijven via deze bibliotheek |
| --- | --- | --- |
| [AllesXL 125 kHz EM4100/TK4100 of 13,56 MHz S50/S70](https://allesxl.com/products/rfid-lezer-usb-poort-em4100-tk4100-125-khz-id-ic-13-56-mhz-s-2) | Producttekst zegt: kaart op de lezer leggen, kaartnummer verschijnt in Notepad/Word. Geen geheugen-/schrijfcommando's gedocumenteerd. | De nieuwe keyboard-invoercomponent kan het aangeboden nummer verwerken, met het werkelijk ingestelde format. Geen geheugen lezen/schrijven geclaimd. |
| [ELATEC TWN4 via PPC](https://www.ppc.nl/merken/elatec1616581178/elatec-twn4-multitech-2/) | Configureerbare readerfamilie; de gelinkte pagina betreft een HF-variant. ELATEC Simple Protocol beschrijft expliciete geheugencommando's via PRS-firmware en USB-CDC/serieel. | Keyboard-invoer in keyboardmodus; nieuw TWN4-profiel voor Classic-blokken en publieke Ultralight/EV1/NTAG-pagina's via geschikte PRS/CDC-firmware. Niet universeel via keyboard HID. |
| [Amazon EM4100, B0FVM3Z3K4](https://www.amazon.com.be/dp/B0FVM3Z3K4) | Amazon gaf HTTP 503; titel/URL noemt een EM4100-lezer. Geen verifieerbare schrijfinterface of commandomanual verkregen. | Keyboard-invoer is bruikbaar als dit apparaat werkelijk tekst typt. Geen bevestigde memory/writerondersteuning. |
| [Amazon HVLOSNE, B0GWR2SDBX](https://www.amazon.com.be/dp/B0GWR2SDBX) | Amazon gaf HTTP 503; titel/URL is onvoldoende om interface, chipfuncties of commando's vast te stellen. | Exact apparaatgedrag/protocol blijft te controleren. Geen geheugen-/schrijffunctie geclaimd op basis van de productnaam. |

**HID is een transportklasse, geen standaard kaartgeheugenprotocol.** Standaard
keyboard-outputreports bedienen bijvoorbeeld LED-status; het zijn geen card-write
commando's. Een reader die alleen een nummer typt krijgt geen RF-schrijfvermogen
door een extra encoder of HID-reportprofiel. EM4100/TK4100-identificatietags zijn
geen algemeen beschrijfbaar gebruikersgeheugen; geschikte programmeerbare
vervangers vereisen zowel een schrijvende reader als hun eigen chipprotocol.

Er is geen automatische firmwarewisseling toegevoegd. Voor TWN4 moet de juiste
PRS/CDC-configuratie al aanwezig zijn. Andere vendor-HID memory/writerprofielen
kunnen worden toegevoegd zodra hun echte commandoprotocol beschikbaar is.
Zie [keyboard/reportprofielen](RFID_HID.md) en [het concrete TWN4-profiel](TWN4.md).
