#include "stdio.h"


extern "C" void kernel()
{
    Screen screen;
    const char* ch = "1234567890qwertyuiopasdfghjkl"
                      "zxcvbnm,./';[]!@#$%^&*()-=_+";
    for (int i=0;i<10;i++)
    {
        screen.printCharacter(ch[i]);
    }
    print("\n");
}
