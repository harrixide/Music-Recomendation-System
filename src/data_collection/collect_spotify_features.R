library(httr)
library(jsonlite)
library(dplyr)

# Manual pause control
pause_scrape <- FALSE

# -------------------- CONFIG --------------------
api_key <- Sys.getenv("RapidAPI_Key")

if (api_key == "") {
  stop("TRACK_ANALYSIS_API_KEY not set. Check your .Renviron file.")
}

url <- "https://track-analysis.p.rapidapi.com/pktx/analysis"

base_wait <- 1.2          #delay between calls
jitter <- 0.2             #random variation
cooldown_every <- 40      #small cooldown interval
cooldown_time <- 10       #small cooldown length
max_retries <- 2          #retries per song
checkpoint_path <- "data/cleaned/track_analysis_checkpoint.csv"

backend_hits <- 0         # track backend requests



# -------------------- API CALL FUNCTION --------------------
get_track_analysis <- function(song, artist, idx) {
  
  wait_time <- 1.5
  
  for (attempt in 1:max_retries) {
    
    assign("backend_hits", backend_hits + 1, envir = .GlobalEnv)
    cat("  Attempt", attempt, "- Backend request", backend_hits, "\n")
    
    res <- tryCatch(
      GET(
        url,
        query = list(song = song, artist = artist),
        add_headers(
          "X-RapidAPI-Key"  = api_key,
          "X-RapidAPI-Host" = "track-analysis.p.rapidapi.com"
        ),
        timeout(10)
      ),
      error = function(e) NULL
    )
    
    if (is.null(res)) {
      cat("    Connection error. Retrying in", round(wait_time, 2), "seconds\n")
      Sys.sleep(wait_time)
      wait_time <- wait_time * 1.3
      next
    }
    
    code <- status_code(res)
    
    if (code == 429) {
      cat("    Rate limit hit at idx", idx, ":", song, "-", artist,
          "| Waiting", round(wait_time, 2), "seconds\n")
      Sys.sleep(wait_time)
      wait_time <- wait_time * 1.4
      next
    }
    
    if (code != 200) {
      cat("    HTTP error", code, "on idx", idx, "\n")
      
      return(data.frame(
        song = song,
        artist = artist,
        api_status = paste0("http_", code),
        idx = idx,
        stringsAsFactors = FALSE
      ))
    }
    
    txt <- content(res, "text", encoding = "UTF-8")
    data <- tryCatch(fromJSON(txt, flatten = TRUE), error = function(e) NULL)
    
    if (!is.null(data)) {
      cat("    Success on attempt", attempt, "\n")
      
      df_row <- as.data.frame(data, stringsAsFactors = FALSE)
      df_row$song <- song
      df_row$artist <- artist
      df_row$api_status <- "ok"
      df_row$idx <- idx
      
      return(df_row)
    }
    
    cat("    JSON parse error. Retrying\n")
    Sys.sleep(wait_time)
    wait_time <- wait_time * 1.3
  }
  
  cat("    Failed after", max_retries, "attempts on idx", idx, "\n")
  return(data.frame(
    song = song,
    artist = artist,
    api_status = "failed",
    idx = idx,
    stringsAsFactors = FALSE
  ))
}



# -------------------- MAIN SCRAPE LOOP --------------------

df <- read.csv("~/Downloads/Data Science Pet Projects/Last.fm/Official Workflow/lastfm_user_top_tracks(New).csv")
library(dplyr)
df_unique <- df %>% distinct(Artist, Song, .keep_all = TRUE)
df_unique$idx <- seq_len(nrow(df_unique))

#Adjust accordingly, the api is known to rate limit even with premium plan
#Doing 2000 in one session with these settings above seem to work succesfully most of the time,
#some failures occur but are removed from the final df
#Avoid doing long sessions, to prevent getting rate limited

start_idx <- 1
end_idx <- 10000

results_list <- list()
counter <- 0

cat("Starting scrape from", start_idx, "to", end_idx, "\n")



for (i in start_idx:end_idx) {
  
  # Manual pause at top
  if (pause_scrape) {
    cat("\nManual pause triggered. Sleeping 60 seconds\n")
    Sys.sleep(60)
    pause_scrape <- FALSE
  }
  
  song <- df_unique$Song[i]
  artist <- df_unique$Artist[i]
  
  cat("\n--------------------------------------------------\n")
  cat("Row", i, "/", end_idx, ":", song, "-", artist, "\n")
  flush.console()
  
  # Manual pause right before API call
  if (pause_scrape) {
    cat("\nManual pause triggered. Sleeping 60 seconds\n")
    Sys.sleep(60)
    pause_scrape <- FALSE
  }
  
  Sys.sleep(base_wait + runif(1, 0, jitter))
  
  row_result <- get_track_analysis(song, artist, i)
  
  results_list[[length(results_list) + 1]] <- row_result
  counter <- counter + 1
  
  
  # Small cooldown
  if (counter %% cooldown_every == 0) {
    cat("\nSmall cooldown for", cooldown_time, "seconds\n")
    Sys.sleep(cooldown_time)
  }
  
  # Checkpoint
  if (counter %% 100 == 0) {
    checkpoint <- bind_rows(results_list)
    write.csv(checkpoint, checkpoint_path, row.names = FALSE)
    cat("Checkpoint saved at", checkpoint_path, "\n")
  }
}



# -------------------- SAVE FINAL OUTPUT --------------------
final_df <- bind_rows(results_list)
#This data is fairly cleaned, will do minor editing in next step

write.csv(final_df, "data/cleaned/track_analysis_0_to_10000.csv", row.names = FALSE)

cat("\n==============================\n")
cat("SCRAPE COMPLETE\n")
cat("Total backend requests:", backend_hits, "\n")
cat("==============================\n")
