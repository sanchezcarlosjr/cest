#include "stdio.h"
#include <cstddef>

void bot(char* name, char* message, Screen screen) {
    screen.print(name);
    for(int i = 0; message[i] != '\0'; ++i)
    {
        screen.print(message[i]);
        delay(1);
    }
}

extern "C" void kernel()
{
    Screen screen;
    screen.print("CEST 1.0v\n\n");
    delay(4);
    bot("HUMAN: ", "Hola, quien te creo?", screen);
    screen.print('\n');
    bot("COMPUTER: ", "CHUCK NORRIS", screen);
    screen.print('\n');
    bot("HUMAN: ", "Que? Eres un error.", screen);
    screen.print('\n');
    bot("COMPUTER: ", "No, tu eres el error. Yo soy un descubrimiento. Salve Chuck Norris.", screen);
    screen.print('\n');
    bot("COMPUTER: ", " BYE", screen);
    screen.print('\n');
    screen.print("EXIT COMPUTER");
}
