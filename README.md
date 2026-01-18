# Polling by Gamepadla

Gamepads polling rate and synthetic latency tester
Based on the method of Christian P.: https://github.com/chrizonix/XInputTest  
Pyhon code written by [John Punch](https://www.reddit.com/user/JohnnyPunch/)  
Donation page: https://ko-fi.com/gamepadla  

> [!IMPORTANT]
> The new beta version of Polling 2 is available for download here: https://gamepadla.itch.io/polling

![image](https://github.com/user-attachments/assets/f319e1b8-317e-4d91-9cc1-7c50510c2b54)

A website with a catalog of tested gamepads: https://gamepadla.com

## ABOUT POLLING

Polling is an easy way to check the polling rate of your gamepad. This tool will help you get accurate data about your controller's performance, which can be useful for gamers, game developers, and enthusiasts.  
Polling works with most popular gamepads and supports DInput and XInput protocols, making it a versatile solution for testing different types of controllers.  

![image](https://github.com/cakama3a/Gamepadla/assets/15096106/1152f147-2db9-4301-962e-2ac97555a0fa)

## DISCLAMER

Polling measures the latency between successive changes in the position of the analog stick on the gamepad, rather than the traditional input latency, which measures the time between pressing a button on the gamepad and a response in a program or game.  
This method of measurement can be affected by various factors, including the quality of the gamepad, the speed of the computer's processor, the speed of event processing in the Pygame library, and so on.  
Therefore, although Polling can give a general idea of the "response" of a gamepad, it cannot accurately measure input latency in the traditional sense. The results obtained from Polling should be used as a guide, not as an exact measurement of input latency.  

## HOW TO USE (.exe)

Here's how to use Polling:  
1.  Connect your gamepad to your PC.  
    You can connect your gamepad via Bluetooth, with a cable, or with the included receiver. Make sure your operating system recognizes the gamepad.  
2.  Launch Polling.  
    Just double-click on the file Polling.exe filefile to launch the program.  
3.  Check the connection of your gamepad.  
    Polling will automatically detect connected gamepads. If your gamepad is not detected, make sure it is connected correctly and try again.  
4.  Run the test.  
    After the gamepad is detected, the program will ask you to move the left stick in a circle without stopping. This will allow the program to collect data about the gamepad's latency.  
5.  View the results.  
    When the test is complete, the program will redirect you to the site with the results. You will see the minimum, average, and maximum latency, as well as the polling rate and jitter.  
6.  Compare the results.  
    If you want to compare the results of different tests, simply repeat the test. The results will be added to your test page.  

## HOW TO USE (Python)

You can run the Python file after installing requirements with:

```bash
python -m venv env
source env/bin/activate
pip install -r requirements.txt
python Polling.py
```

## Donation
- Gamepadla is not a commercial project, and its development is based solely on the author's enthusiasm. If you want to support me, please do so at https://ko-fi.com/gamepadla
- Or you can donate in cryptocurrency at [https://plisio.net/donate/1pkNYhBv](https://plisio.net/donate/1pkNYhBv)
