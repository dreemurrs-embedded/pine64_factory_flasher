# Pine64 Factory Flasher

## Build instructions
```
mkdir pine64_factory_flasher && cd pine64_factory_flasher
git clone https://github.com/buildroot/buildroot
git clone https://github.com/dreemurrs-embedded/pine64_factory_flasher
cd buildroot
make BR2_EXTERNAL=$(pwd)/../pine64_factory_flasher pinetab2v2_defconfig # use pinetab2v0_defconfig if you have the v0.1 dev unit
make
```

## Flashing
Flash `buildroot/output/images/sdcard.img` to an SD card and interact with the menu using Volume keys, Power key for confirm.

## License
See COPYING file in the root of this repository.
