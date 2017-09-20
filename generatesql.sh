#!/bin/sh
#The folder to operate in is specified by the first argument
path="${PWD}/$1"
cd $path
# Clears the file used to store INSERT statements
cp /dev/null "../hotelreviews.sql"

#An awk script will create INSERT statements for each  file in the dataset
for file in *.dat
do
	awk ' 
	BEGIN{
		# Sets the field seperator to close chevron, and initialises variables
		FS = ">";
		# These variables are constant for each hotel
		reviewID = 0; 
		hotelID = 0;
		hotelOverall = 0;
		hotelAvgPrice = 0;
		hotelURL = 0;
		# These arrays store the data for each review of a hotel
		overalls[""]=0;
		userIDs[""]="";
		contents[""]="";
		dates[""]="";
		values[""]=0;
		rooms[""]=0;
		locations[""]=0;
		cleans[""]=0;
		checkIn_FrontDesks[""]=0;
		services[""]=0;
		businessServices[""]=0;
		noReaders[""]=0;
		noHelpfuls[""]=0;
		# This is used to index the arrays, and to keep track of how many reviews there are
		count = 0;
	}
	{
		# Depending on which attribute a tag specifies, the relevent value is saved to an array, or as a single value
		# When the <Business Service> tag is found, the count used to index the array is incremented as this is the last attribute stored for each review
		# The values for HotelOverall, hotelAvgPrice, and HotelURL are constant for all reviews so are not stored in arrays	
	
		if ($1 == "<Overall") {
			overalls[count]+=$2;
		}
		
		# The substr removes a spurious line break at the end of each record which may have been a result of windows to linux conversion of the files
		# The gsub replaces singlequote with two single quotes which escapes the quote character when entering strings into SQL
		
		if ($1 == "<Author") {
			userID = $2;
			userID = substr(userID,1,length(userID)-1);
			gsub(/\047/, "\047\047", userID);
			userIDs[count]= userID;
		}
		if ($1 == "<Content") {
			content = $2;
			content = substr(content,1,length(content)-1);
                        gsub(/\047/, "\047\047", content);
			contents[count]= content;
                }
		if ($1 == "<Date") {
			date=$2;
			date = substr(date,1,length(date)-1);
                        dates[count]= date;
                }
		if ($1 == "<Value") {
                        values[count]+=$2;
                }
		if ($1 == "<Rooms") {
                        rooms[count]+=$2;
                }
		if ($1 == "<Location") {
                        locations[count]+=$2;
                }
		if ($1 == "<Cleanliness") {
                        cleans[count]+=$2;
                }
		if ($1 == "<Check in / front desk") {
                        checkIn_FrontDesks[count]+=$2;
                }
		if ($1 == "<Service") {
                        services[count]+=$2;
                }
		if ($1 == "<Business service") {
                        businessServices[count]+=$2;
			++count;
                }
		if ($1 == "<No. Reader") {
                        noReaders[count]+=$2;
                }
		if ($1 == "<No. Helpful") {
                        noHelpfuls[count]+=$2;
                }
		if ($1 == "<Overall Rating") {
                        hotelOverall+=$2;
                }
		#The dollar sign must be cut off in order for the average price to be stored as an integer
		if ($1 == "<Avg. Price") {
                        price=$2;
			sub("\\$", "", price);
			hotelAvgPrice += price;
                }
		if ($1 == "<URL") {
                        hotelURL = $2;
                        hotelURL = substr(hotelURL,1,length(hotelURL)-1);
			gsub(/\047/, "\047\047", hotelURL);
                }


	}
	
	END{
		#Extracts the part of the filename which is a unique integer representing the hotel
		
		n = split(FILENAME,a,"/");
		n = split(a[n],b,".");
		n = split(b[1],c,"_");
		hotelID = c[2];
		
		#prints an insert statement for each record in the realtion, the order is important as the values of each attribute are not defined in the statement
		
		max=count;
		for (i = 0; i < max; ++i){
			print "INSERT INTO HotelReviews VALUES (" reviewID "," hotelID ",\x27" userIDs[i] "\x27,\x27" contents[i] "\x27,\x27" dates[i] "\x27," overalls[i] "," values[i] "," rooms[i] "," locations[i] "," cleans[i] "," checkIn_FrontDesks[i] "," services[i] "," businessServices[i] "," noReaders[i] "," noHelpfuls[i] "," hotelOverall "," hotelAvgPrice ",\x27" hotelURL "\x27);" >> "../hotelreviews.sql"; 
			#this is unique to a each review of a hotel, but not unique across all reviews
			++reviewID;
		}
	}
	' "$PWD/$file" 
done


