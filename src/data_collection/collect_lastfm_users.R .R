library(httr)
library(jsonlite)
library(rvest)

api_key <- Sys.getenv("LASTFM_API_KEY")
if (api_key == "") {
  stop("LASTFM_API_KEY not set. See README for setup.")
}

url <- "https://www.last.fm/music/Drake/+listeners"

#rvest is used to load a webpage with read_html function
#also html_nodes function

page
#Step 1: create a get usernames function, using a custom url

get_usernames_from_listeners_page <- function(artist_url) {
  page <- read_html(artist_url)
  #read_html function loads the html for the url
  
  usernames <- page %>%
    html_nodes("h3.top-listeners-item-name a.link-block-target") %>%
    html_text(trim = TRUE)
  #above is the most important two lines to this function
  #html_nodes function is saying to grab all HTML elements that match the css selector (paramater)
  #h3. is equivalent to finding <h3 tag in the code
  #top-listeners-item-name further specifies that we want the class to be called that
  #in html, we would find <h3 class = variable name, so tag and then class is format
  #next, we go further in the nest, within the existing nest we want to specify
  #to parse the data that is a. (<a tag), with class = link-block-target
  #now at this point we get something like this...
  #<a class="link-block-target" href="/user/CoolFan123">CoolFan123</a>
# from here we use the html_text(trim = TRUE) function to grab everything between 
  #<a and </a>, but class and href aren't included as they don't show up on the actual
  #UI as text, only in the html
  
  return(usernames)
}
get_usernames_from_listeners_page(url) #this returns usernames for 1 page

#Step 2: get usernames for all pages on the website
#*****Start here

get_usernames_across_pages <- function(base_url, max_pages = 9) {
  all_usernames <- c()
  
  for (i in 1:max_pages) {
    page_url <- paste0(base_url, "?page=", i)
    message("Scraping page ", i)
    #For loop starts off by pasting the url, with the page number, basically get
    #the exact link to show each page, smart way to use for loop to cycle through each page
    
    usernames <- tryCatch({
      get_usernames_from_listeners_page(page_url)
    }, error = function(e) {
      message("Failed on page ", i)
      return(NULL)
    })
    #tryCatch function essentally performs a task, and then has the error paramater, so functio
    #won't break if task isn't completed
    
    
    if (!is.null(usernames)) {
      all_usernames <- c(all_usernames, usernames)
    }
    #c in this case is combine, not columns
    #so we already have usernames varaible generated, we then add it to all_usernames which should be empty
    #then that becomes the new all_usernames, and we can run the loop for the rest of the pages the same way
    
    #input usernames, from tryCatch function, into 
    Sys.sleep(1)  # Respectful delay
  }
  
  return(unique(all_usernames))
}

#Step 3: use the function to load all the usernames

usernamesDrake <- get_usernames_across_pages(url)


#Step 4

get_user_info <- function(username, api_key) {
  resDrake <- GET("http://ws.audioscrobbler.com/2.0/",
                  query = list(
                    method = "user.getTopTracks",
                    user = username,
                    api_key = api_key,
                    format = "json"
                  ))
  #GET is apart of library hittr
  print(paste("User:", username, "Status:", status_code(resDrake)))
  
  if (status_code(resDrake) != 200) return(NULL)
  #Skip if API failed if status code does not equal 200
  
  
  json <- fromJSON(content(resDrake, as = "text", encoding = "UTF-8"), flatten = TRUE)
  
  if (!is.null(json$toptracks)) {
    return(data.frame(
      Username = username,
      Song = json$toptracks$track$name,
      Artist = json$toptracks$track$artist.name,
      Duration = as.numeric(json$toptracks$track$duration),
      Playcount = as.integer(json$toptracks$track$playcount),
      Rank = as.integer(json$toptracks$track[["@attr.rank"]]),
      FavoriteArtist = artist,
      stringsAsFactors = FALSE
    ))
  } else {
    return(NULL)
  }
}


#Just some tests to see if get_user_info function works
h <- get_user_info("sushiwhy", api_key)
head(h)
z <- get_user_info("KIDSSEEGHOST", api_key)
#***





user_info_list <- list()

for (i in seq_along(usernamesDrake)) {
  username <- usernamesDrake[i]
  message("Getting info for: ", username, " (", i, "/", length(usernamesDrake), ")")
  
  info <- tryCatch({
    get_user_info(username, api_key)
  }, error = function(e) NULL)
  
  if (!is.null(info)) {
    user_info_list[[length(user_info_list) + 1]] <- info
  }
  
  Sys.sleep(0.5)  # Rate limit friendly
}



# Combine all rows into a single data frame
user_info_df <- do.call(rbind, user_info_list)

#Now we want to automate this whole process for all artists...


artist_list <- c("Drake", "BTS", "Charli XCX", "Justin Bieber", "V", "The Weeknd", 
                 "Rosé", "Jessie Murph", "Ella Langley", "BigXthaPlug", "Radiohead", 
                 "Jimin", "Playboi Carti", "TWICE", "Tyler, The Creator", 
                 "Lana Del Rey", "Travi$ Scott", "Taylor Swift", "Billie Eilish", 
                 "Leon Thomas", "Benson Boone", "Post Malone", "Ravyn Lenae", 
                 "Sabrina Carpenter", "Lady Gaga", "Bruno Mars", "SZA", 
                 "Teddy Swims", "Kendrick Lamar", "HUNTR/X", "Shaboozey", 
                 "Morgan Wallen", "Alex Warren")

all_users_info <- c()

for (artist in artist_list) {
  message("\n=== Scraping users for artist: ", artist, "===")
  artist_url <- paste0("https://www.last.fm/music/", URLencode(artist), "/+listeners")
  
  usernames <- tryCatch ({
    get_usernames_across_pages(artist_url, max_pages = 9)
  }, error = function(e) { 
    message("Skipping Artist", artist, "due to error")
    return(NULL)
    })
  for (i in seq_along(usernames)) {
    username <- usernames[i]
    message("Getting info for: ", username, " (", i, "/", length(usernames), ")")
    
    info <- tryCatch ({
      get_user_info(username, api_key)
    }, error = function(e) NULL)
    
    if (!is.null(info)) {
      all_users_info[[length(all_users_info) + 1]] <- info
    }
    
    Sys.sleep(0.5)
    }
  }



final_df <- do.call(rbind, all_users_info)
write.csv(final_df, "data/raw/lastfm_user_top_tracks.csv", row.names = FALSE)










# --- troubleshooting / notes below ---



resDrake <- GET("http://ws.audioscrobbler.com/2.0/", #This is based on last fm api documentation, how to get top tracks
                query = list(
                  method = "user.getTopTracks",
                  user = "MrCoolDrake",
                  api_key = api_key,
                  format = "json"
                ))



resDrake$url #This link is just the html file in a website basically, we asked last fm website musicbrainz to
#generate a html file for TopTracks, they handle how to actually do that code wise on their end, we jsut ask 
#the question
#With getting the top listeners for each artist, that is private, so the api doesn't cover that, which is why we
#had to use the rvest library instead to manually parse the html in the website, grab all the listeners for the
#first 10 pages of listeners
#Granted these listeners are the top listeners, aka "superfans" so there playcounts and song preferences
#Don't reflect the general populations interests. Although these are fans of the most popular artists of 2025, 
#so its also safe to say these are popular songs of 2025.





