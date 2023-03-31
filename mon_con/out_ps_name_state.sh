for i in `find /proc -maxdepth 1 -regex ".*[0-9]"`; do echo $i && head -3 $i/status; done
