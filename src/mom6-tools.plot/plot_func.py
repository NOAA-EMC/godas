#!/usr/bin/python3

def SOCAgrd_Lon (lon):
    if lon > 60:
       lon = lon - 360
    else:
       lon = lon

    return lon
