#In this file, we develop a 50-250 user dataset which shows users most listened to songs, their playcount, and artist metadata

library(httr)
library(jsonlite)

api_key <- "your_api"
api_secret <- "your_api_secret"
url <- "https://www.last.fm/music/Drake/+listeners"

library(rvest)
#rvest is used to load a webpage with read_html function
#also html_nodes function

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

#Step 2: get usernames for all pages on the website
#*****Start here



get_usernames_across_pages <- function(base_url, max_pages = 9) {
  all_usernames <- c()
  
  for (i in 1:max_pages) {
    page_url <- paste0(base_url, "?page=", i) #gets us the exact link for that page
    message("Scraping page ", i)
    #For loop starts off by pasting the url, with the page number, basically get
    #the exact link to show each page
    
    usernames <- tryCatch({
      get_usernames_from_listeners_page(page_url) #WE use the function we made earlier, to get html,read it, and get usernames
    }, error = function(e) {
      message("Failed on page ", i)
      return(NULL)
    })
    #then we use the try Catch function, 
    if (!is.null(usernames)) {
      all_usernames <- c(all_usernames, usernames)
    }
    
    Sys.sleep(1)  # Respectful delay
  }
  
  return(unique(all_usernames))
}

#Step 3: use the function to load all the usernames

usernamesDrake <- get_usernames_across_pages(url) #To get all drake usernames across pages
usernamesDrake



#I need to automate this so I autmatically cycles through the 250 drake listeners

get_user_info <- function(username, api_key) {
  resDrake <- GET("http://ws.audioscrobbler.com/2.0/",
                  query = list(
                  method = "user.getTopTracks",
                   user = username,
                   api_key = api_key,
                    format = "json",
                   limit = 10
                  ))
  
  print(paste("User:", username, "Status:", status_code(resDrake)))
  
  if (status_code(resDrake) != 200) return(NULL)
  
  json <- fromJSON(content(resDrake, as = "text", encoding = "UTF-8"))
  
  if (!is.null(json$toptracks$track)) {
    
    if (is.data.frame(json$toptracks$track)) 
      json$toptracks$track <- list(json$toptracks$track)
    
    return(data.frame(
      user = username, #when we put this in the loop below, usernames are called sequentially, so we get all user names
      track = sapply(json$toptracks$track, function(x) x$name),
      playcount = as.numeric(sapply(json$toptracks$track, function(x) x$playcount)),
      artist = sapply(json$toptracks$track, function(x) x$artist$name),
      stringsAsFactors = FALSE
    ))
  } else {
    return(NULL)
  }
}


user_info_list <- list()
user_info_df <- data.frame()

for (i in seq_along(usernamesDrake)[1:50]) {
  username <- usernamesDrake[i]
  message("Getting info for: ", username, " (", i, "/", length(usernamesDrake), ")")
  
  info <- tryCatch({
    get_user_info(username, api_key)
  }, error = function(e) NULL)
  
  if (!is.null(info)) {
    user_info_list[[length(user_info_list) + 1]] <- info
  }
  
  Sys.sleep(0.20)  # Rate limit friendly
}



# Combine all rows into a single data frame
user_info_list
user_info_df <- do.call(rbind, user_info_list)
user_info_df

#######

#Changing URL will return top listened to tracks from users for other major artists
