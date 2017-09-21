
# FIXES AND ALERTS WHEN LOW AVAILABLE DISK SPACE

#### Function

We want to:
- "Rotate" certain log files which are known to grow large (like mysql's "slow log"). "Rotate" in this case means:
   * compress logs AND
   * move to a larger, attached storage
- Alert (via email) when a machine's partition is running low on storage

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

text

#### Usage Example

text

#### where:

text

