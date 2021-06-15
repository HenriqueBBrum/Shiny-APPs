import sys
from datetime import date
from datetime import datetime
from datetime import timedelta
import numpy as np

import random


# Receives a file with this configurations:
# First line: Amount of distinct groups.
# Next N lines: Id of group, longitude, latitude, radius, amount of crimes for this group.
# Start date
# Final date


random.seed(datetime.now())

# Receives a file for info about how the data should be distributed
with open(sys.argv[1]) as file:
    argv = file.read().splitlines()



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
with open('../seg_dados.csv','w', encoding='utf-8') as file:
    file.write("id, data, latitude, longitude, policial_encarregado, tipo_de_crime, descrição, situação\n")
    description = '""'
    count = 1
    for i in range(1,int(argv[0])+1):
        crime_info = argv[i].split(",")
        # crimeinfo = [group, longitude, latitude, radius, amount]
        print(crime_info)
        for j in range(0, int(crime_info[4])):
            situation = random.choices(['"Solucionado"', '"Em investigação"', '"Arquivado"'], [0.1,0.3,0.6])
            location = create_random_point(float(crime_info[1]), float(crime_info[2]), float(crime_info[3]))
            date = get_random_date(argv[int(argv[0])+1], argv[int(argv[0])+2])
            line = "{}, {}, {}, {}, {}, {}, {}, {}\n".format(count, date, location[0], location[1],
            random.choice(names).rstrip("\n"), crime_info[0],description,situation[0])
            file.write(line)
            count+=1
