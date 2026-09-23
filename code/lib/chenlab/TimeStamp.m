function ts = TimeStamp()
ts = convertStringsToChars(string(datetime('now','TimeZone','local','Format','MMMd_y_HHmm'))); %
end