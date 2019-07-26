# Generates one file with a bunch of GUIDs and a second file
# with a random subset of those GUIDs. It then optionally adds some new
# GUIDs to the end of the subset file.
# Parameters:
# 1: Number of GUIDs in the large file
# 2: Number of subset GUIDs in the small file
# 3: Number of additional GUIDs to add to the small file
# 4: The output file name


import sys,os,uuid,random

baseFileName=os.path.splitext(sys.argv[4])[0]
baseFileExtension=os.path.splitext(sys.argv[4])[1]

f = open(sys.argv[4], "w")
i = 1
while i <= int(sys.argv[1]) :
    x=uuid.uuid4()
    f.write(str(x)+'\n')
    i += 1
f.close()



with open(sys.argv[4]) as f:
    lines = random.sample(f.readlines(),int(sys.argv[2]))


f = open(baseFileName+'-subset'+baseFileExtension, "w")
for line in lines:
    f.write(line)


i = 1
while i <= int(sys.argv[3]) :
    x=uuid.uuid4()
    f.write(str(x)+'\n')
    i += 1

f.close()
