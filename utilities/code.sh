find . -type f ! -name ".*" | sort | while read -r f; do
  18:54:02
  file "$f" | grep -q "text" || continue
  echo "$f"
  echo "{"
  cat "$f"
  echo "}"
  echo
done >code.txt
