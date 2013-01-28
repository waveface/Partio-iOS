#!/usr/bin/python

import sys
sys.path.append("/usr/local/lib/python2.7/site-packages")
import PIL
from PIL import Image

ipad3Size = 144,144
ipad2Size = 72,72
iphone4Size = 114,114
iphone3Size = 57,57
spotlightHDSize = 100,100
spotlightSize = 50,50
settingHDSize = 58,58
settingSize = 29,29

inputfile = ''
if len(sys.argv)== 1:
	sys.exit()
inputfile = sys.argv[1]
suffix = sys.argv[2]
print inputfile
try:
	im = Image.open(inputfile)
	im.thumbnail(ipad3Size, Image.ANTIALIAS)
	im.save("Icon-72" + suffix + "@2x.png", "PNG")
except IOError:
    print "cannot create thumbnail for '%s'" % infile
try:
	im = Image.open(inputfile)
	im.thumbnail(ipad2Size, Image.ANTIALIAS)
	im.save("Icon-72" + suffix + ".png", "PNG")
except IOError:
    print "cannot create thumbnail for '%s'" % infile
try:
	im = Image.open(inputfile)
	im.thumbnail(iphone4Size, Image.ANTIALIAS)
	im.save("Icon" + suffix + "@2x.png", "PNG")
except IOError:
    print "cannot create thumbnail for '%s'" % infile
try:
	im = Image.open(inputfile)
	im.thumbnail(iphone3Size, Image.ANTIALIAS)
	im.save("Icon" + suffix + ".png", "PNG")
except IOError:
    print "cannot create thumbnail for '%s'" % infile