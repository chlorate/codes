# Remove blank lines
/^\s*$/ {
	next
}

# Code line: remove comments
/^[0-9A-F]{8} [0-9A-F]{8}/ {
	gsub(/\s+#.+$/, "")
	print
	next
}

# Code name line: prefix with "$"
{
	print "$" $0
}
