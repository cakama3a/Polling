# Current version of the program
ver = "1.3.1.4"

# Required libraries import
from colorama import Fore, Style
import time
import json
import numpy as np
import platform
import requests
import uuid
import webbrowser
import random
import string
import pygame
from requests.exceptions import RequestException

print("Based on the method of: https://github.com/chrizonix/XInputTest")

# Print introductory information
print(f" ")
print(f" ")
print("   ██████╗  ██████╗ ██╗     ██╗     ██╗███╗   ██╗" + Fore.CYAN + " ██████╗ " + Fore.RESET + "")
print("   ██╔══██╗██╔═══██╗██║     ██║     ██║████╗  ██║" + Fore.CYAN + "██╔════╝ " + Fore.RESET + "")
print("   ██████╔╝██║   ██║██║     ██║     ██║██╔██╗ ██║" + Fore.CYAN + "██║  ███╗" + Fore.RESET + "")
print("   ██╔═══╝ ██║   ██║██║     ██║     ██║██║╚██╗██║" + Fore.CYAN + "██║   ██║" + Fore.RESET + "")
print("   ██║     ╚██████╔╝███████╗███████╗██║██║ ╚████║" + Fore.CYAN + "╚██████╔╝" + Fore.RESET + "")
print("   ╚═╝      ╚═════╝ ╚══════╝╚══════╝╚═╝╚═╝  ╚═══╝" + Fore.CYAN + " ╚═════╝ " + Fore.RESET + "")
print(f"   " + Fore.CYAN + "Polling Rate Tester " + Fore.RESET + ver + "      https://gamepadla.com")
print(f"   Support the project:             https://ko-fi.com/gamepadla")
print(f" ")
print(f" ")
pygame.init()

# Function to filter out statistical outliers from the array
# Used to remove extreme values that might skew the main results (average, jitter)
def filter_outliers(array):
    # Set the quantile bounds for filtering
    lower_quantile = 0.02
    upper_quantile = 0.995

    # Sort array and calculate indices
    sorted_array = sorted(array)
    lower_index = int(len(sorted_array) * lower_quantile)
    upper_index = int(len(sorted_array) * upper_quantile)

    # Return filtered array without outliers
    return sorted_array[lower_index:upper_index + 1]

# Short ID Generation
def generate_short_id(length=12):
    characters = string.ascii_letters + string.digits
    return ''.join(random.choice(characters) for _ in range(length))

# Main program loop
while True:
    # Initialize joystick subsystem
    pygame.joystick.init()
    joysticks = []
    try:
        joysticks = [pygame.joystick.Joystick(x) for x in range(pygame.joystick.get_count())]
    except pygame.error as e:
        print(f"Error initializing controller: {e}")
        print("Please try reconnecting your controller or restart the program.")
        time.sleep(10)
        exit(1)
    delay_list = []

    # Check for connected controllers
    if not joysticks:
        print("No controller found")
        time.sleep(10)
        exit(1)
    else:
        print(f"Found {len(joysticks)} controller(s)")

        # List all connected controllers
        for idx, joystick in enumerate(joysticks):
            print(f"{idx + 1}. {joystick.get_name()}")

        # Automatic selection if only one controller is connected
        if len(joysticks) == 1:
            joystick = joysticks[0]
            print("Only one controller detected. Automatically selected.")
        else:
            # Controller selection for multiple controllers
            selected_index = input("Please enter the index of the controller you want to test: ")
            try:
                selected_index = int(selected_index) - 1
                if 0 <= selected_index < len(joysticks):
                    joystick = joysticks[selected_index]
                else:
                    print("Invalid index. Defaulting to the first controller.")
                    joystick = joysticks[0]
            except ValueError:
                print("Invalid input. Defaulting to the first controller.")
                joystick = joysticks[0]

        # Initialize selected controller
        joystick.init()
        joystick_name = joystick.get_name()

        # Display system information
        print("")
        print(f"Gamepad mode:       {joystick_name}")
        os_name = platform.system()
        uname = platform.uname()
        os_version = uname.version
        print(f"Operating System:   {os_name}")

        # Number of tests selection
        repeat = 1988
        repeatq = input("Please select number of tests (1. 2000, 2. 4000, 3. 6000), or enter your own number: ")
        if repeatq == "1":
            repeat = 2000
        elif repeatq == "2":
            repeat = 4000
        elif repeatq == "3":
            repeat = 6000
        else:
            try:
                repeat = int(repeatq)
            except ValueError:
                print("Invalid input. Please enter a valid number.")

        # Stick selection for testing
        print("")
        print("Please select the stick you want to test:")
        print("1. Left stick")
        print("2. Right stick")
        stick_choice = input("Enter the number (1 or 2): ")

        print("")
        if stick_choice == "1":
            axis_x = 0  # Left stick X axis
            axis_y = 1  # Left stick Y axis
            print("Testing left stick.")
        elif stick_choice == "2":
            axis_x = 2  # Right stick X axis
            axis_y = 3  # Right stick Y axis
            print("Testing right stick.")
        else:
            print("Invalid choice. Defaulting to left stick.")
            axis_x = 0
            axis_y = 1

        # Check if controller is still connected
        if not joystick.get_init():
            print("Controller not connected")
            exit(1)

        # Initialize measurement variables
        times = []
        start_time = time.perf_counter_ns()
        prev_x, prev_y = None, None
        measurements_count = 0
        
        print(f"\n{Fore.YELLOW}Starting test. Please rotate the selected stick smoothly.{Style.RESET_ALL}")
        
        # Main measurement loop - prints plain log in real-time
        while True:
            pygame.event.pump()
            x = joystick.get_axis(axis_x)
            y = joystick.get_axis(axis_y)
            pygame.event.clear()

            if not ("0.0" in str(x) and "0.0" in str(y)):
                if prev_x is None and prev_y is None:
                    prev_x, prev_y = x, y
                    prev_time = start_time
                elif x != prev_x or y != prev_y:
                    end_time = time.perf_counter_ns()
                    delay = round((end_time - prev_time) / 1_000_000, 3)
                    prev_time = end_time
                    prev_x, prev_y = x, y

                    if delay > 0.1 and delay < 150:
                        times.append(delay)
                        measurements_count += 1
                        delay_list.append(delay)
                        
                        # --- Print plain, uncolored log in real-time ---
                        progress_percentage = (measurements_count / repeat) * 100
                        print(f"[{progress_percentage:3.0f}%] {delay:.2f} ms")

                if len(times) >= repeat:
                    break
        
        print("\nAnalyzing results...")

        delay_clear = delay_list
        delay_list_filtered = filter_outliers(delay_list)

        filteredMin = round(min(delay_list_filtered), 3)
        filteredMax = round(max(delay_list_filtered), 3)
        filteredAverage = round(np.mean(delay_list_filtered), 3)
        jitter = round(np.std(delay_list_filtered), 3)

        polling_rate_avg = round(1000 / filteredAverage, 2)
        
        q1 = np.percentile(delay_clear, 25)
        q3 = np.percentile(delay_clear, 75)
        iqr = q3 - q1
        outlier_threshold = q3 + (1.5 * iqr)
        outliers_list = [delay_val for delay_val in delay_clear if delay_val > outlier_threshold]
        
        # --- NEW: Re-painting the log with correct highlighting ---
        # Move cursor up by the number of lines in the log
        num_log_lines = len(delay_clear)
        print(f"\x1b[{num_log_lines}A", end="")

        for i, delay_val in enumerate(delay_clear):
            progress_percentage = ((i + 1) / len(delay_clear)) * 100
            color = Fore.RED if delay_val > outlier_threshold else Style.RESET_ALL
            
            # \x1b[2K clears the entire line before printing over it
            print(f"\x1b[2K[{progress_percentage:3.0f}%] {color}{delay_val:.2f} ms{Style.RESET_ALL}")
        # --- End of re-painting block ---

        print("")
        print(f"=== Polling Rate ===")
        print(f"Average: {Fore.YELLOW}{Style.BRIGHT}{polling_rate_avg:.2f} Hz{Style.RESET_ALL}")
        
        print(f" ")
        print(f"=== Refresh intervals ===")
        print(f"Minimal interval:   {filteredMin:.2f} ms")
        print(f"Average interval:   {Fore.YELLOW}{Style.BRIGHT}{filteredAverage:.2f} ms{Style.RESET_ALL}")
        print(f"Maximum interval:   {filteredMax:.2f} ms")
        print(f"Jitter:             {jitter:.2f} ms")

        print(f" ")
        print(f"=== Outliers Report (based on IQR method) ===")
        outliers_count = len(outliers_list)
        print(f"Number of outliers: {outliers_count}")
        if measurements_count > 0:
            outliers_percentage = (outliers_count / measurements_count) * 100
            print(f"Outliers percentage: {outliers_percentage:.2f}%")
        if outliers_count > 0:
            outliers_avg_delay = np.mean(outliers_list)
            print(f"Average outlier delay: {Fore.YELLOW}{Style.BRIGHT}{outliers_avg_delay:.2f} ms{Style.RESET_ALL}")
        else:
            print("No significant outliers detected.")

        test_key = generate_short_id()
        data = {
            'test_key': str(test_key),
            'version': ver,
            'url': 'https://gamepadla.com',
            'date': time.strftime('%Y-%m-%d %H:%M:%S', time.localtime()),
            'driver': joystick_name,
            'os_name': os_name,
            'os_version': os_version,
            'min_latency': round(filteredMin, 2),
            'avg_latency': round(filteredAverage, 2),
            'max_latency': round(filteredMax, 2),
            'polling_rate': polling_rate_avg,
            'jitter': round(jitter, 2),
            'mathod': 'GP',
            'delay_list': ', '.join([f"{x:.2f}" for x in delay_clear])
        }

        with open('data.txt', 'w') as outfile:
            json.dump(data, outfile, indent=4)

        print("")
        if input("Would you like to see detailed test graphs on your personalized page at Gamepadla.com? (Y/N): ").lower() == "y":
            gamepad_name = input("Please enter the name of your gamepad: ")
            connection = input("Please select connection type (1. Cable, 2. Bluetooth, 3. Dongle): ")
            if connection == "1":
                connection = "Cable"
            elif connection == "2":
                connection = "Bluetooth"
            elif connection == "3":
                connection = "Dongle"
            else:
                print("Invalid choice. Defaulting to Cable.")
                connection = "Unset"

            data['connection'] = connection
            data['name'] = gamepad_name

            sent_successfully = False
            while not sent_successfully:
                try:
                    response = requests.post('https://gamepadla.com/scripts/poster.php', data=data)
                    if response.status_code == 200:
                        print("Test results successfully sent to the server.")
                        webbrowser.open(f'https://gamepadla.com/result/{test_key}/')
                        sent_successfully = True
                    else:
                        print("Failed to send test results to the server.")
                        retry = input("Do you want to retry? (Y/N): ").lower()
                        if retry != "y":
                            break
                except RequestException:
                    print(f"{Fore.YELLOW}{Style.BRIGHT}Connection error. Data could not be sent.{Style.RESET_ALL}")
                    retry = input("Do you want to retry? (Y/N): ").lower()
                    if retry != "y":
                        break
        del data['test_key']
        del data['os_version']
        del data['url']

        if input("Run again? (Y/N): ").lower() != "y":
            break