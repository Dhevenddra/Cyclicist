#installing the packages
install.packages('tidyverse')
install.packages('janitor')
install.packages('lubridate')
install.packages('ggplot2')
install.packages('dplyr')
install.packages('geosphere')
#install readr if you get read_csv not found error
install.packages('readr')


#Loading the packages
library(tidyverse)
library(janitor)
library(lubridate)
library(ggplot2)
library(dplyr)
library(geosphere)
library(readr)


#Importing the csv files
Q12020 <- read_csv("C:/Users/dhev0/OneDrive/Desktop/GoogleCS1/Divvy_Tripdata_2020/2020_Q1.csv")
Apr2020 <- read_csv("C:/Users/dhev0/OneDrive/Desktop/GoogleCS1/Divvy_Tripdata_2020/2020_04.csv")
May2020 <- read_csv("C:/Users/dhev0/OneDrive/Desktop/GoogleCS1/Divvy_Tripdata_2020/2020_05.csv")
June2020 <- read_csv("C:/Users/dhev0/OneDrive/Desktop/GoogleCS1/Divvy_Tripdata_2020/2020_06.csv")
July2020 <- read_csv("C:/Users/dhev0/OneDrive/Desktop/GoogleCS1/Divvy_Tripdata_2020/2020_07.csv")
Aug2020 <- read_csv("C:/Users/dhev0/OneDrive/Desktop/GoogleCS1/Divvy_Tripdata_2020/2020_08.csv")
Sep2020 <- read_csv("C:/Users/dhev0/OneDrive/Desktop/GoogleCS1/Divvy_Tripdata_2020/2020_09.csv")
Oct2020 <- read_csv("C:/Users/dhev0/OneDrive/Desktop/GoogleCS1/Divvy_Tripdata_2020/2020_10.csv")
Nov2020 <- read_csv("C:/Users/dhev0/OneDrive/Desktop/GoogleCS1/Divvy_Tripdata_2020/2020_11.csv")
Dec2020 <- read_csv("C:/Users/dhev0/OneDrive/Desktop/GoogleCS1/Divvy_Tripdata_2020/2020_12.csv")

#Examine the structure of the dataset
str(Q12020)
str(Apr2020)
str(May2020)
str(June2020)
str(July2020)
str(Aug2020)
str(Sep2020)
str(Oct2020)
str(Nov2020)
str(Dec2020)

# Changing start_station_id from chr to int
options(warn=-1)
Dec2020 <- mutate(Dec2020, start_station_id = as.integer(start_station_id))

# Changing end_station_id from chr to int
Dec2020 <- mutate(Dec2020, end_station_id = as.integer(end_station_id))

# Merge all datasets into one table
db_2020 <- bind_rows(Q12020, Apr2020, May2020, June2020, July2020, Aug2020, Sep2020, Oct2020, Nov2020, Dec2020)

#Cleaning & removing any spaces, parentheses, etc.
db_2020 <- clean_names(db_2020)

#Total number of rows in merged dataset
rowtotal <- sum(
  nrow(Q12020),
  nrow(Apr2020), 
  nrow(May2020), 
  nrow(June2020), 
  nrow(July2020), 
  nrow(Aug2020), 
  nrow(Sep2020), 
  nrow(Oct2020),
  nrow(Nov2020), 
  nrow(Dec2020))

print(rowtotal)

#Examine merged dataset structure
str(db_2020)

#remove any empty columns and rows
remove_empty(db_2020, which = c())

#Add required columns
db_2020$date <- as.Date(db_2020$started_at)
db_2020$month <- format(as.Date(db_2020$date), "%b")
db_2020$day <- format(as.Date(db_2020$date), "%d")
db_2020$year <- format(as.Date(db_2020$date), "%Y")
db_2020$day_of_week <- format(as.Date(db_2020$date), "%A")
db_2020$starting_hour <- format(as.POSIXct(db_2020$started_at), '%H')

#Remove duplicates and NA's
db_2020 <- drop_na(db_2020)
clean_db_2020 <- db_2020[!duplicated(db_2020$ride_id), ]
print(paste("Removed", nrow(db_2020) - nrow(clean_db_2020), "duplicate rows"))

#Add ride length column
clean_db_2020$ride_length <- difftime(clean_db_2020$ended_at, clean_db_2020$started_at, units ='mins')

#Remove fields where ride_length < 0
nrow(clean_db_2020[clean_db_2020$ride_length < 0,])
final_db_2020 <- clean_db_2020[!(clean_db_2020$ride_length<=0),]

#Casual Riders vs Members
rider_type_total <- table(final_db_2020$member_casual)
View(rider_type_total)

#Calculate min, max, median, standard deviation of ride_length
trip_stats <- final_db_2020 %>% 
  group_by(member_casual) %>% 
  summarise(average_ride_length = mean(ride_length), standard_deviation = sd(ride_length), 
            median_ride_length = median(ride_length), min_ride_length = min(ride_length), 
            max_ride_length = max(ride_length))
head(trip_stats)

#average ride_length for users by day_of_week.
final_db_2020$day_of_week <- ordered(final_db_2020$day_of_week, levels = c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"))

final_db_2020 %>% 
  group_by(member_casual, day_of_week) %>% 
  summarise(rider_type_total = n(), average_ride_length = mean(ride_length)) %>% 
  arrange(member_casual, day_of_week)

#Most poular month
popular_month <- final_db_2020 %>% 
  group_by(month) %>% 
  summarise(number_of_rides = n(), average_duration = mean(ride_length)) %>% 
  arrange(-number_of_rides)

View(popular_month)

# For mode, there is no built in function, hence creating one
getmode <- function(v) #getmode is the function name
{
  uniqv <- unique(v)
  uniqv[which.max(tabulate(match(v, uniqv)))]
}

#Most popular Start_station
station_mode <- getmode(final_db_2020$start_station_name)
print(station_mode)

#Most popular Start_Station for casual riders
popular_start_stations_casual <- final_db_2020 %>% 
  filter(member_casual == 'casual') %>% 
  group_by(start_station_name) %>% 
  summarise(number_of_starts = n()) %>% 
  filter(start_station_name != "") %>% 
  arrange(- number_of_starts)

head(popular_start_stations_casual)

#Most poular Start_station for members
popular_start_stations_member <- final_db_2020 %>% 
  filter(member_casual == 'member') %>% 
  group_by(start_station_name) %>% 
  summarise(number_of_starts = n()) %>% 
  filter(start_station_name != "") %>% 
  arrange(- number_of_starts)

head(popular_start_stations_member)

#number of rides by member type viz
options(scipen = 999)
ggplot(data = final_db_2020) +
  aes(x = day_of_week, fill = member_casual) +
  geom_bar(position = 'dodge') +
  labs(x = 'Day of week', y = 'Number of rides', fill = 'Member type', title = 'Number of rides by member type')
ggsave("number_of_rides_by_member_type.png")

#number of rides by member type by months viz
ggplot(data = final_db_2020) +
  aes(x = month, fill = member_casual) +
  geom_bar(position = 'dodge') +
  labs(x = 'Month', y = 'Number of rides', fill = 'Member type', title = 'Number of rides per month')
ggsave("number_of_rides_per_month.png")

#Hourly use of bikes throughout the week
ggplot(data = final_db_2020) +
  aes(x = starting_hour, fill = member_casual) +
  facet_wrap(~day_of_week) +
  geom_bar() +
  labs(x = 'Starting hour', y = 'Number of rides', fill = 'Member type', title = 'Hourly use of bikes throughout the week') +
  theme(axis.text = element_text(size = 5))
ggsave("Hourly_use_of_bikes_throughout_the_week.png", dpi = 1000)

#total number of casual riders and members
final_db_2020 %>% 
  group_by(member_casual) %>% 
  summarise(total_rider_type = n()) %>% 
  ggplot(aes(x = member_casual, y = total_rider_type, fill = member_casual)) + 
  geom_col(position = "dodge") + geom_text(aes(label = total_rider_type, vjust = -0.25))

#Usage by weekday
final_db_2020 %>% 
  group_by(member_casual, day_of_week) %>% 
  summarise(number_of_rides = n(),average_duration = mean(ride_length)) %>% 
  arrange(member_casual, day_of_week)  %>% 
  ggplot(aes(x = day_of_week, y = average_duration, fill = member_casual)) +
  geom_col(position = "dodge")

#Usage by month
final_db_2020$month <- ordered(final_db_2020$month, levels=c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"))

final_db_2020 %>% 
  group_by(member_casual, month) %>% 
  summarise(number_of_rides = n(),average_duration = mean(ride_length) ) %>% 
  arrange(member_casual, month)  %>% 
  ggplot(aes(x = month, y = average_duration, fill = member_casual)) +
  geom_col(position = "dodge") +
  geom_text(aes(label = number_of_rides, angle = 90)) +
  facet_wrap(~member_casual)