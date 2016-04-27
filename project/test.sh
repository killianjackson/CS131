./startServerHerd.sh

sleep 2

{
    sleep 1
    echo IAMAT UCLA1 +34.068930-118.445127 1400794645.392014450
    sleep 1
    echo quit
} | telnet localhost 5027

pkill -f 'python serverHerd.py Welsh'

{
    sleep 1
    echo IAMAT UCLA2 +34.068930-118.445127 1400794645.392014450
    sleep 1
    echo quit
} | telnet localhost 5027

pkill -f 'python serverHerd.py Parker'

{
    sleep 1
    echo IAMAT UCLA3 +34.068930-118.445127 1400794645.392014450
    sleep 1
    echo quit
} | telnet localhost 5027

{
    sleep 1
    echo WHATSAT UCLA1 35 10
    sleep 1
    echo quit
} | telnet localhost 5029
