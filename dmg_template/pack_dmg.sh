#!/bin/sh
rm -r WizMac.dmg
hdiutil convert WizMac_template.dmg -format UDSP -o WizMac
hdiutil mount WizMac.sparseimage
cp -r ../build/Release/WizMac.app/Contents /Volumes/WizMac/WizMac.app
cp -r ../README.txt /Volumes/WizMac/
cp -r ../ChangeLog.txt /Volumes/WizMac/
hdiutil eject /Volumes/WizMac
hdiutil convert WizMac.sparseimage -format UDBZ -o WizMac.dmg
rm WizMac.sparseimage
