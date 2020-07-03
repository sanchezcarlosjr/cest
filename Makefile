SRC_DIR := src
OBJ_DIR := obj
SRC_FILES := $(wildcard $(SRC_DIR)/*.cpp)
OBJ_FILES := $(patsubst $(SRC_DIR)/%.cpp,$(OBJ_DIR)/%.o,$(SRC_FILES))
ASSEMBLER_FILES := $(wildcard $(SRC_DIR)/*.s)
OBJ_ASSEMBLER_FILES := $(patsubst $(SRC_DIR)/%.s,$(OBJ_DIR)/%.o,$(ASSEMBLER_FILES))
CPPFLAGS := -m32 -fno-use-cxa-atexit -nostdlib -fno-builtin -fno-rtti -fno-exceptions -fno-leading-underscore
LINKER_PARAMS := -melf_i386

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp
	gcc $(CPPFLAGS) -c -o $@ $<

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.s
	as --32 -o $@ $<

bin/kernel.iso: bin/kernel.bin
	mkdir iso
	mkdir iso/boot
	mkdir iso/boot/grub
	cp bin/kernel.bin iso/boot/kernel.bin
	echo 'set timeout=0'                      > iso/boot/grub/grub.cfg
	echo 'set default=0'                     >> iso/boot/grub/grub.cfg
	echo ''                                  >> iso/boot/grub/grub.cfg
	echo 'menuentry "CEST" {' >> iso/boot/grub/grub.cfg
	echo '  multiboot /boot/kernel.bin'      >> iso/boot/grub/grub.cfg
	echo '  boot'                            >> iso/boot/grub/grub.cfg
	echo '}'                                 >> iso/boot/grub/grub.cfg
	grub-mkrescue --output=bin/kernel.iso iso
	rm -rf iso
	rm bin/kernel.bin

bin/kernel.bin: src/linker.ld $(OBJ_FILES) $(OBJ_ASSEMBLER_FILES)
	ld $(LINKER_PARAMS) -T $< -o $@ $(OBJ_FILES) $(OBJ_ASSEMBLER_FILES)

first-time:
	sudo apt-get -y install g++ binutils libc6-dev-i386 VirtualBox grub-legacy xorriso
	bin/kernel.iso
	(killall VirtualBox && sleep 1) || true
	VirtualBox --startvm 'My Operating System' &

install: bin/kernel.bin
	sudo cp $< /boot/kernel.bin
