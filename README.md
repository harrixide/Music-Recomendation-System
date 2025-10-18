The Purpose of this Project is to create a functional recomendation system that can recommend niche songs to pre existing users in a dataset.

We first generate a dataset, by webscraping sites like LastFM, to gather user data, and to analyze trends in user behavior
   #The dataset will be of popular artists based on the LastFM Website
  
We then extract user's top 10 favorite songs from the most famous artists, and analyze those tracks
These tracks can be analyzed, using Spotfy's api to extract audio features such as "Tempo" or "Danceability"
Using K clustering, we define user groups such as "Upbeat/Exciting" or "Mellow/Slow" based on the audio feature data of their top 10 songs

We now have an idea of the type of music users listen to, with data to support it

With those patterns, we can predict what songs a user may like in the future
 #We can also generate mood playlists for those predicted songs, similar to spotify's ai generated mood playlists

With enough data, we can ask a person not invovled in the test, what their 10 most listened to songs are (based on spotify data) and get an idea of what songs they may be intersted in, based on what cluster they are in




