import sys
from datetime import date
from datetime import datetime
from datetime import timedelta
import numpy as np

import random

# Two arguments are passed to this file
# 1 - Filename/path of a file containing the necessary info to generate desired data
# 2 - Name of the output file

# First argument: A file with this configuration:
#
# First line: 0 or 1, 0 means dataset has no Id of group;1 means the opposite
# Second line: Amount of distinct groups.
# Next N lines: Id of group(discarded if first line is 0), longitude, latitude, radius, amount of crimes for this group.
# (Same row data is separeted by a blank space)
# Start date
# Final date



random.seed(datetime.now())

# Receives a file for info about how the data should be distributed
with open(sys.argv[1]) as file:
    file_arg = file.read().splitlines()



# Returns a random date between a start and an end date
def get_random_date(st_time, end_time):
    st = date.fromisoformat(st_time)
    end = date.fromisoformat(end_time)

    days_between = end - st

    random_days = random.randrange(days_between.days)
    random_date = st + timedelta(days=random_days)

    return random_date

# Creates a random point within max distance of 'radius' from point (x0, y0)
def create_random_point(x0,y0,radius):
    r = radius/ 111300
    u = np.random.uniform(0,1)
    v = np.random.uniform(0,1)
    w = r * np.sqrt(u)
    t = 2 * np.pi * v
    x = w * np.cos(t)
    #x1 = x / np.cos(y0)
    y = w * np.sin(t)
    return (y0 +y, x0+x)

# Returns a vector of 'amt' locations within  max distance of 'radius' from point (long0, lat0). Doesn't produce duplicates.
def get_random_location(amt, long0, lat0, radius):
    result = []
    seen = set()
    for i in range(amt):

        lat, long = create_random_point(long0, lat0, radius)

        while (lat, long) in seen:
            lat, long = create_random_point(long0, lat0, radius)

        seen.add((lat, long))
        result.append((lat, long))
    return result


# Vector with random names
names = open("names.txt", "r", encoding="utf-8").readlines()

# Writes to a csv file
with open('../'+sys.argv[2]+'.csv','w', encoding='utf-8') as file:
    if(file_arg[0] == '0'):
        file.write("id, data, latitude, longitude, policial_encarregado, descrição, situação\n")
    else:
        file.write("id, data, latitude, longitude, policial_encarregado, tipo_de_crime, descrição, situação\n")
    description = '""'
    count = 1
    #Read from the third line to the nth+2 (n is given on second line)
    for i in range(2,int(file_arg[1])+2):
        crime_info = file_arg[i].split(",")
        # crimeinfo = [group, longitude, latitude, radius, amount]
        # Create m random points (m is the 5th column of ith row)
        for j in range(0, int(crime_info[4])):
            situation = random.choices(['"Solucionado"', '"Em investigação"', '"Arquivado"'], [0.1,0.3,0.6])  # Eight choice has a weight
            location = create_random_point(float(crime_info[1]), float(crime_info[2]), float(crime_info[3]))
            date = get_random_date(file_arg[int(file_arg[1])+2], file_arg[int(file_arg[1])+3])
            if(file_arg[0] == '0'):
                line = "{}, {}, {}, {}, {}, {}, {}\n".format(count, date, location[0], location[1],
                    random.choice(names).rstrip("\n"), description,situation[0])
            else:
                line = "{}, {}, {}, {}, {}, {}, {}, {}\n".format(count, date, location[0], location[1],
                    random.choice(names).rstrip("\n"), crime_info[0],description,situation[0])
            file.write(line)
            count+=1
