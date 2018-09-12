#!/user/bin/env python
# -*- coding:utf-8 -*-

file_abs = "/Users/hacker/project/gitrepo/newton-newpay-android/src/app/src/main/res/values-zh/strings.xml"
content = ""
with open(file_abs, "r") as f:
	strs = f.readlines()
	for index in range(len(strs)):
		s = strs[index]
		start = s.find(">")
		end = s.find("</string>")
		res = s[start + 1: end]
		if len(res) == 0:
			continue
		content = content + "\r\n" + str(index) + "  " + res 
file_out = "/Users/hacker/project/zh.txt"
with open(file_out, "w") as f:
	f.write(content)
print(content)
