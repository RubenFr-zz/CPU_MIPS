import serial
import os
import threading
import re

def main():
    print('Trying to connect to COM3...')
    serialPort = serial.Serial(port = "COM3", baudrate=115200, bytesize=8, timeout=2, stopbits=serial.STOPBITS_ONE)
    print('Connected to COM3!')

    x = threading.Thread(target=recv, args=(serialPort,))
    x.start()

    while 1:
        menu()
        choice = input('Enter your choice (1-4): ')
        while not re.match('^[1-4]$', choice):
            print(f'Wrong Input ({choice}), Try again...')
            choice = input('Enter your choice (1-4): ')
        serialPort.write(choice.encode())

def menu():
    # os.system('cls')
    print("""
        1. Count up from 0x00 onto LEDG with delay ~0.5sec
        2. Count down from 0xFF onto LEDR with delay ~0.5sec
        3. On each KEY1 pressed, send the massage “I love my Negev”
        4. Clear all LEDs
    """)

def recv(serialPort):
    print('Entered recv function')
    while 1:
        if(serialPort.in_waiting > 0):
            received = serialPort.readline()
            print(f'\n\nNew Line Received: {received.decode()}\n')

# if '__name__' == '__main__':
main()