#! /bin/bash
# version 1.2 - 12-December 2025

# the only job of this script is to do the initial git pull for the root account

# because we're running as a cron job, source the environment variables
. /root/.bashrc

# initialize the logfile
logfile='/tmp/mount.log'
statusdir='/lmchol/hol'
startupstatus="${statusdir}/startup_status.txt"
gitproject='HOLUSER'
echo "Initializing log file" > "${logfile}"

cd /root || exit

# Wait for the proxy to become available.
echo "Waiting for proxy to be ready..." >> "${logfile}"
while ! nc -z proxy 3128; do
   echo "Proxy not ready, retrying in 5 seconds..." >> "${logfile}"
   sleep 5
done
echo "Proxy is ready." >> "${logfile}"

# Attempt to pull the latest changes from git.
ctr=0
while true; do
   if [[ "${ctr}" -gt 30 ]]; then
      echo "FATAL: Could not perform git pull after multiple attempts." >> "${logfile}"
      exit 1
   fi

   if git pull origin main >> "${logfile}" 2>&1; then
      echo "Git pull successful." >> "${logfile}"
      # Create a flag file to indicate success.
      touch /tmp/rootgitdone
      break
   else
      if grep -q 'could not be found' "${logfile}"; then
         echo "The git project ${gitproject} does not exist." >> "${logfile}"
         mkdir -p "${statusdir}"
         echo "FAIL - No GIT Project" > "${startupstatus}"
         exit 1
      else
         echo "Could not complete git pull. Will try again." >> "${logfile}"
      fi
   fi
  ((ctr++))
  sleep 5
done
