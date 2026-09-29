# ananicy-cpp pinned the whole desktop to the 4 low-power cores

Status: fixed 2026-08-27; not recurring as of 2026-09-29 (override no longer
present, see below).

## Symptom

Found 2026-08-27 while debugging a game crash: `system.slice` and `user.slice`
had `cpuset.cpus.effective` = `12-15`, so every process (Steam, Hyprland, the
whole desktop) ran on the 2E+2LP cores of the Panther Lake 6P+8E+2LP CPU.
Side effect: `taskset -c 0-7 %command%` Steam launch options silently failed
(the game "doesn't launch") because a child cannot widen its parent's cpuset.

## Cause

**ananicy-cpp** (CachyOS's auto-niceness daemon): its `apply_cpuset` feature
(default ON at the time) pinned cgroups on hybrid CPUs and re-applied the pin
every `check_freq` (15 s) cycle.

## Check

```sh
cat /sys/fs/cgroup/{system,user}.slice/cpuset.cpus.effective   # want 0-15
```

## Fix (if it comes back)

1. Append `apply_cpuset = false` to `/etc/ananicy.d/ananicy.conf`
2. `pkexec systemctl restart ananicy-cpp`
3. `pkexec systemctl set-property --runtime system.slice AllowedCPUs=0-15`
   and the same for `user.slice` (runtime-only; resets at reboot, but nothing
   re-pins once step 1 is in place)

## Current state (2026-09-29)

`ananicy.conf` is owned by `cachyos-ananicy-rules`; the 1:1.1.49-1 upgrade
(2026-09-13) replaced it and the `apply_cpuset = false` line is gone (the
shipped file no longer has an `apply_cpuset` key at all). ananicy-cpp
1.2.0 is active, yet both slices are at `0-15` — the pin has not come back.
Re-run the check after ananicy-cpp / rules upgrades.
