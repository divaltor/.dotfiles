# Nimi — Samsung QE55Q70DATXXH

2024 QLED, Tizen `T-NKM2DDEUC-1301.0`, Wi-Fi `192.168.1.151`.
Unauthenticated API on `:8001/api/v2/`; Tizen `sdb` on `:26101`.

## Shell access

1. On the TV: Home → Apps → open **App Settings** → press the `123` button →
   `12345` → Developer mode **On**, Host PC IP `192.168.1.36` → power-cycle.
2. `sdb` ships x86-64 only; run the Linux build in a container:

   ```sh
   docker run -d --name sdb-box --platform linux/amd64 \
     -v "$PWD/.amp/in/sdbl:/sdb:ro" -v "$PWD/.amp/in/relmac:$PWD/.amp/in/relmac:ro" \
     -v "$PWD/.amp/in/tmp:$PWD/.amp/in/tmp" -e HOME=/root ubuntu:24.04 sleep infinity
   docker exec sdb-box /sdb/data/tools/sdb connect 192.168.1.151:26101
   ```

   Rebuild after a cleanup: `sdb_4.2.36_ubuntu-64.zip` from
   `download.tizen.org/sdk/tizenstudio/official/binary/`, unpacked to
   `.amp/in/sdbl/data/tools`.
3. Root: [chris-ritsen/samsung-tv-root](https://github.com/chris-ritsen/samsung-tv-root),
   `archive-root root <ip> --command '...'`. Volatile, `SMACK User`, full caps.
   The tool must run on the Mac with `sdb` executed via `docker exec` (a wrapper
   script passed to `--sdb`), so the TV can call back to `192.168.1.36`.

Turn Developer mode off when finished: while it is on, anything that reaches
`:26101` and sets the host IP gets root (`SVE-2025-50109`), and a plain `sdb
shell` is still closed.

## What was changed

- 16 packages renamed `*.disabled` in `/opt/usr/apps`: the voice chain, analytics,
  `adplatform`, `pisa-service` (this kills `adagent-service`), log transmitter.
- 3 items in `/opt/usr/debloat-backup`: `contents-recognition-dbmgr` (ACR/TFLite
  models), `mediaanalytics`, `tpk-update-com.samsung.tv.pisa-service`.

`/` is read-only `vdfs` — `mount -o remount,rw /` fails — so systemd units cannot
be masked. `/opt` is the only writable, persistent surface.

Per boot, re-stop the two root-partition daemons:

```sh
systemctl stop --no-block contents-recognition-service media-analytics-service
kill -9 $(pidof media-analytics-service) 2>/dev/null
```

Undo: rename `*.disabled` back, move the three items out of
`/opt/usr/debloat-backup`. A firmware update or factory reset also restores them.
