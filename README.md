# KDE audio output keeps switching by itself

**Symptom:** on KDE Plasma with PipeWire/WirePlumber, clicking the volume icon in the system tray makes the default output jump between devices. The icon flickers and sound cuts out. After 10–70 seconds it settles, sometimes on the wrong output, and that wrong output can get *saved* as your default. System Settings → Sound doesn't trigger it.

**Cause:** one of your audio outputs is broken: it exists, but fails when opened (`Start error: Operation not supported`). The tray widget's live level meters open *every* output, so clicking the icon hits the broken one. WirePlumber 0.5 then "recovers" by tearing down and rebuilding the **whole sound card**, up to 3 times. While the card is gone, the default falls back to another device and bounces around.

It's common on USB audio devices in `pro-audio` mode that expose a spare endpoint nothing is wired to, such as an "S/PDIF Alt" output.

## Fix

1. Click the tray volume icon a few times, then run:

   ```sh
   ./diagnose.sh          # looks at the last hour; or: ./diagnose.sh '2026-01-31 20:00'
   ```

   It lists the outputs that fail to start and prints a WirePlumber rule that disables them.

2. Check the listed outputs are ones you don't use, then save the printed rule as
   `~/.config/wireplumber/wireplumber.conf.d/60-disable-broken-sinks.conf`.

3. Apply it and set your default back:

   ```sh
   systemctl --user restart wireplumber
   wpctl status                 # find your real output's ID
   wpctl set-default <ID>
   ```

**Undo:** delete the `.conf` file and restart WirePlumber.

## Verify

Watch events while you click the tray icon:

```sh
pactl subscribe | grep -E "'(new|remove)' on sink|server"
```

Before the fix you'll see bursts of sinks being removed and recreated, and `server` (default) changes. After it, there should be none.

## Not this? Check the cable

If `journalctl -k` shows `err -71` for a USB audio device, that's a USB link/protocol error: the cable, port or controller is garbling data. A device flapping like that also makes the default switch. Kernel quirks (`snd_usb_audio quirk_flags`) won't help. Move it to a different USB port.

## Tested on

CachyOS, kernel 7.2, Plasma 6.7.5, PipeWire 1.6.9, WirePlumber 0.5.18.
