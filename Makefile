# We adapt https://gitlab.com/bztsrc/bootboot/-/blob/binaries/images/Makefile for CEST purposes.

# platform, either x86, rpi or icicle
PLATFORM=x86
ARCH_x86=x86_64
#PLATFORM=rpi
#ARCH_rpi=aarch64
#PLATFORM=icicle
#ARCH_icicle=riscv64
# the path to OVMF.fd (for testing with EFI)
OVMF=/usr/share/OVMF/OVMF.fd

all: bootboot/mkbootimg/mkbootimg cest initdir disk

# compile the image creator
bootboot/mkbootimg/mkbootimg:
	@make -C bootboot/mkbootimg all

# compile the CEST OS -aka kernel
cest:
	@make -C src cest.$(ARCH_$(PLATFORM)).elf

# create an initial ram disk image with the kernel inside
initdir:
	@mkdir initrd initrd/sys 2>/dev/null | true
	cp src/cest.$(ARCH_$(PLATFORM)).elf initrd/sys/core

# create hybrid disk / cdrom image or ROM image
disk: bootboot/mkbootimg/mkbootimg initdir mkbootimg.json
	bootboot/mkbootimg/mkbootimg mkbootimg.json disk-$(PLATFORM).img
	@rm -rf initrd
	@chmod 006 disk-$(PLATFORM).img
	@make -C src clean

initrd.rom: bootboot/mkbootimg/mkbootimg initdir mkbootimg.json
	bootboot/mkbootimg/mkbootimg mkbootimg.json initrd.rom
	@rm -rf initrd

virtualize: bios

# create a GRUB cdrom
grub.iso: bootboot/mkbootimg/mkbootimg initdir mkbootimg.json
	@bootboot/mkbootimg/mkbootimg mkbootimg.json initrd.bin
	@rm -rf initrd
	@mkdir iso iso/bootboot iso/boot iso/boot/grub 2>/dev/null || true
	@cp bootboot/dist/bootboot.bin iso/bootboot/loader || true
	@cp config iso/bootboot/config || true
	@cp initrd.bin iso/bootboot/initrd || true
	@printf "menuentry \"BOOTBOOT test\" {\n  multiboot /bootboot/loader\n  module /bootboot/initrd\n  module /bootboot/config\n  boot\n}\n\nmenuentry \"Chainload\" {\n  set root=(hd0)\n  chainloader +1\n  boot\n}\n" >iso/boot/grub/grub.cfg || true
	grub-mkrescue -o grub.iso iso
	@rm -r iso 2>/dev/null || true

# test the disk image
rom: initrd.rom
	qemu-system-x86_64 -option-rom bootboot/dist/bootboot.bin -option-rom initrd.rom -serial stdio

bios:
	# https://unix.stackexchange.com/questions/426652/connect-to-running-qemu-instance-with-qemu-monitor
	qemu-system-x86_64 -d int -drive file=disk-x86.img,format=raw -serial stdio -monitor unix:qemu-monitor-socket,server,nowait

cdrom:
	qemu-system-x86_64 -cdrom disk-x86.img -serial stdio

grubcdrom: grub.iso
	qemu-system-x86_64 -cdrom grub.iso -serial stdio

grub2: grub.iso
	qemu-system-x86_64 -drive file=disk-x86.img,format=raw -cdrom grub.iso -boot order=d -serial stdio

efi:
	qemu-system-x86_64 -bios $(OVMF) -m 64 -drive file=disk-x86.img,format=raw -serial stdio
	@printf '\033[0m'

eficdrom:
	qemu-system-x86_64 -bios $(OVMF) -m 64 -cdrom disk-x86.img -serial stdio
	@printf '\033[0m'

linux:
	qemu-system-x86_64 -kernel bootboot/dist/bootboot.bin -drive file=disk-x86.img,format=raw -serial stdio

sdcard:
	qemu-system-aarch64 -M raspi3 -kernel bootboot/dist/bootboot.img -drive file=disk-rpi.img,if=sd,format=raw -serial stdio

riscv:
	qemu-system-riscv64 -M microchip-icicle-kit -kernel bootboot/dist/bootboot.rv64 -drive file=disk-icicle.img,if=sd,format=raw -serial stdio

coreboot:
ifeq ($(PLATFORM),x86)
	qemu-system-x86_64 -bios coreboot-x86.rom -drive file=disk-x86.img,format=raw -serial stdio
else
	qemu-system-aarch64 -bios coreboot-arm.rom -M virt,secure=on,virtualization=on -cpu cortex-a53 -m 1024M -drive file=disk-rpi.img,format=raw -serial stdio
endif

bochs:
	bochs -f bochs.rc -q

# clean up
clean:
	rm -rf initrd *.bin *.img *.rom *.iso 2>/dev/null || true

