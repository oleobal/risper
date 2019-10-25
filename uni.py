#!/usr/bin/env python3
import sys
import unicodedata
from collections import defaultdict

if len(sys.argv) == 1:
	print("pass category names to print characters in the relevant category")
	sys.exit(1)


unicode_category = defaultdict(list)
for c in map(chr, range(sys.maxunicode + 1)):
	unicode_category[unicodedata.category(c)].append(c)

for a in sys.argv[1:]:
	
	if a == "Alphabetic":
		print("Alphabetic expanded to Lu + Ll + Lt + Lm + Lo + Nl + Other_Alphabetic\n")
		for c in ["Lu", "Ll","Lt", "Lm", "Lo", "Nl", "Other_Alphabetic"]:
			print(" ".join(unicode_category[c]))
			print()
	else:
		print(" ".join(unicode_category[a]))
		print()