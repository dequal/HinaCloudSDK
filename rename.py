
# 快速修改文件名   run : cd / python rename.py

#!/usr/bin/env python
import os
for dirpath, _, filenames in os.walk('.'):
    for filename in filenames:
        if filename.startswith('HNConfigOptions'):
            oldFile = os.path.join(dirpath, filename)
            newFile = os.path.join(dirpath, filename.replace('HNConfigOptions', 'HNBuildOptions', 2))
            print (newFile)
            inFile = open(oldFile)
            outFile = open(newFile, 'w')
            replacements = {'HNConfigOptions':'HNBuildOptions'}
            for line in inFile:
                for src, target in replacements.items():
                    line = line.replace(src, target)
                outFile.write(line)
            inFile.close()
            outFile.close()
            os.remove(oldFile)
