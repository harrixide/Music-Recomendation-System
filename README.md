The Purpose of this Project is to create a functional recomendation system that can recommend niche songs to pre existing users in a dataset.

We first generate a dataset, by webscraping sites like LastFM, to gather user data, and to analyze trends in user behavior
   #The dataset will be of popular artists based on the LastFM Website
  
We then extract user's top 10 favorite songs from the most famous artists, and analyze those tracks

Using a spotify like API, these tracks can be analyzed,to extract audio features such as "Tempo" or "Danceability", 10 features total.

After garnering a dataset of around 10,000 unique songs, we can create a matrix that contains rows with each song and its respective 10 audio features. After scaling, we can use cosine similarity to determine similarity between these songs.

After developing a similarity matrix, I went ahead and made a UI using RShiny, comparing any song in the dataset with its 5 closest recomendations.

Additional Analyses were done to further extract information from the music dataset. Sicne this dataset is self made, and entirely webscraped based on recent trends, the dataset can act as a most popular songs of 2025 dataset.

By using a Projection Pursuit plot, we can analyze the most unique songs in the dataset, to get a sense of what the strangest, or most unique songs are in the dataset. This gives us insight into how music tastes have evolved from previous generations to today, as well as, finding out what potential new songs a person may enjoy that are also unique from modern day trends.

By using PCA with K Clustering of music groups, we can also make assumptions on the genres of music most people listen to.

Using K clustering, we define user groups such as "Upbeat/Exciting" or "Mellow/Slow" based on the PCA plot aggregations.







