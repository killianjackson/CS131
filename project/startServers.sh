for i in "Alford" "Bolden" "Hamilton" "Parker" "Welsh"
do
  echo Starting $i
  python serverHerd.py $i &
done