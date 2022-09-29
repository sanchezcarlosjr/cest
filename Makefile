cest.img:
	cp /usr/share/edk2-ovmf/x64/OVMF_VARS.fd ./OVMF_VARS.fd
	cd src && make && mv cest.efi ../cest.efi && mv kernel.elf ../kernel.elf
	mkdir -p EFI/BOOT/
	mv cest.efi EFI/BOOT/BOOTX64.efi
	mv kernel.elf EFI/BOOT/kernel.elf
	dd if=/dev/zero of=cest.img bs=512 count=93750
	parted cest.img -s -a minimal mklabel gpt
	parted cest.img -s -a minimal mkpart EFI FAT16 2048s 93716s
	parted cest.img -s -a minimal toggle 1 boot
	dd if=/dev/zero of=/tmp/part.img bs=512 count=91669
	mformat -i /tmp/part.img -h 32 -t 32 -n 64 -c 1
	mcopy -s -i /tmp/part.img EFI ::
	dd if=/tmp/part.img of=cest.img bs=512 count=91669 seek=2048 conv=notrunc	

virtualize:
	qemu-system-x86_64 -cpu qemu64 \
		-drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2-ovmf/x64/OVMF_CODE.fd \
		-drive if=pflash,format=raw,file=OVMF_VARS.fd \
		-net none \
		-drive file=cest.img,if=ide,format=raw

run:
	uefi-run -b /usr/share/edk2-ovmf/x64/OVMF.fd -q /bin/qemu-system-x86_64 EFI/BOOT/BOOTX64.efi


on_internet:
	echo "Use Tigervnc. Connect your operating system using uri and port provided by ngrok."
	sleep 2
	ngrok tcp 5900


clean:
	-rm *.img
	-rm -rf EFI
	-rm *.fd


