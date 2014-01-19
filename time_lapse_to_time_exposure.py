#! /usr/bin/python

from PIL import Image
import numpy
import scipy
import scipy.ndimage
import scipy.misc
from glob import glob
from sys import argv
import os

sourceImageFileNames = glob("*.jpg")

topDirectory = os.getcwd()
if len(argv) >= 2:
    meanFilename = argv[1]
else:
    meanFilename = os.path.basename(topDirectory) + "-mean.png"
if len(argv) >= 3:
    maxFilename = argv[2]
else:
    maxFilename = os.path.basename(topDirectory) + "-max.png"
if len(argv) >= 4:
    minFilename = argv[3]
else:
    minFilename = os.path.basename(topDirectory) + "-min.png"

numberOfImages = len(sourceImageFileNames)
width, height = Image.open(sourceImageFileNames[0]).size

print "instantiating arrays..."
summedPixels = numpy.zeros([height,width,3],numpy.uint64)
maxPixels = numpy.zeros([height,width,3],numpy.uint8)
minPixels = numpy.zeros([height,width,3],numpy.uint8)
minPixels.fill(255)
print "...done instantiating arrays."
imageIndex = 0
for sourceImageFileName in sourceImageFileNames:
    imageIndex += 1
    print "processing source image " + str(imageIndex) + " of " + str(numberOfImages) + " - " + sourceImageFileName
    sourcePixels = scipy.ndimage.imread(sourceImageFileName)
    summedPixels += sourcePixels
    maxPixels = numpy.maximum(maxPixels, sourcePixels)
    minPixels = numpy.minimum(minPixels, sourcePixels)
print "about to average the summed pixels..."
meanPixels = summedPixels/numberOfImages
print "...done averaging the summed pixels"

print "saving " + meanFilename
scipy.misc.imsave(meanFilename,meanPixels)
print "saving " + maxFilename
scipy.misc.imsave(maxFilename,maxPixels)
print "saving " + minFilename
scipy.misc.imsave(minFilename,minPixels)

print "done."
