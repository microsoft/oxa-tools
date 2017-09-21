
# FIXES/ALERTS WHEN REMAINING DISK SPACE IS LOW

#### Function

1. "Rotate" certain log files which are known to grow large (like mysql's "slow log"). "Rotate" in this case means:
   * compress logs AND
   * move to a larger, attached storage
1. Alert (via email) when a machine's partition is running low on storage

#### Implementation and Execution Overview

1. The delivery mechanism follows the "deployment extension" pattern. Therefore, `install.sh` is invoked on the "jump box" to get things started.
1. `install.sh` uses `sharedOperations.sh` to parse arguments.
1. `install.sh` will then (re)create a cron job on the "jump box" that
   * executes `../remoteCommands.sh` AND
   * persists settings for the cron job
1. The cron job invokes `../remoteCommands.sh` on the "jump box." This will:
   * read the persisted settings which includes a list of machines (local network IPs)
   * copy (via scp) a set of bash files to each machine in the list (like `utilities.sh`, `notify.sh`, `rotateLog.sh`, and `sharedOperations.sh`)
   * remotely invoke `notify.sh` (over ssh) which will immediately invoke `rotateLog.sh` before checking for low disk space
   * NOTE: `../remoteCommands.sh` will NOT copy the persisted settings file. The SSH command itself will include necessary values in the argument list. This minimizes duplication AND follows the pattern extablished in `/scripts/bootstrap-db.sh` which installs our database backends. We can revisit this design in the future.

#### Parameters

1. script-file
1. settings-file
1. backend-server-list
1. target-user
1. paths-to-copy-list
1. destination-path
1. remote-command
1. low-storage-log
1. low-storage-frequency
1. usage-threshold-percent
1. file-size-threshold
1. mysql-user
1. mysql-pass
1. large-partition

#### Usage Example

text

#### where:

text

