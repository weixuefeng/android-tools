with open("/Users/erhu/Downloads/fabric-ios.csv") as f:
	count = 0
	for line in f.readlines():
		s = line.strip()
		print("every day add:" + s)
		res = s.split(",")[1].replace("\"","")
		count = int(res) + count

print("total:" + str(count))
