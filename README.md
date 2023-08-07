# Data-1205-ASG5

# YouTube Data Analysis Project

Welcome to the YouTube Data Analysis Project repository! This project aims to analyze the relationship between the popularity of YouTube videos and the sentiments of their comments. The project involves extracting data from CSV files, transforming it, and loading it into a MySQL database for analysis.

## Dataset

The dataset used for this project is called "YouTube Statistics" and can be found on Kaggle: [YouTube Statistics Dataset](https://www.kaggle.com/datasets/advaypatil/youtube-statistics)

### File Descriptions

1. `videos-stats.csv`: Contains basic information about each video, including title, likes, views, keyword, and comment count.
2. `comments.csv`: Provides the top ten most relevant comments for each video along with sentiment and likes.

### Column Descriptions

**videos-stats.csv**:
- Title: Video Title.
- Video ID: The Video Identifier.
- Published At: The date the video was published in YYYY-MM-DD.
- Keyword: The keyword associated with the video.
- Likes: Number of likes the video received. -1 indicates that likes are not publicly visible.
- Comments: Number of comments the video has. -1 indicates that comments are disabled.
- Views: Number of views the video got.

**comments.csv**:
- Video ID: The Video Identifier.
- Comment: The comment text.
- Likes: Number of likes the comment received.
- Sentiment: Sentiment of the comment. 0 represents negative, 1 represents neutral, and 2 represents positive sentiment.

## ETL Process

The data extraction, transformation, and loading process is performed using Python and SQL.

## Project Structure

- `data/`: Folder containing the data files
  - `comments.csv`: Contains comments data
  - `videos-stats.csv`: Contains video statistics data
- `notebooks/`: Folder containing Jupyter Notebooks
  - `data_extraction.ipynb`: Jupyter Notebook for extracting data from CSV to MySQL.
- `sql/`: Folder containing SQL scripts
  - `data_extraction.sql`: SQL Script for Database Initialization and Data Retrieval

### Data Extraction with Python

The data extraction is performed using Python in a Jupyter Notebook. The provided code reads CSV files, cleans the data, and loads it into a MySQL database.

```python
# Python code for data extraction
import pandas as pd
from sqlalchemy import create_engine

# List of dataset information
dataset_info = [
    {
        "table_name": "video_comments",
        "file_name": "comments.csv"
    },
    {
        "table_name": "video_statistics",
        "file_name": "videos-stats.csv"
    },
    # Add more datasets and their corresponding table names and file names
]

# MySQL database credentials
uname = 'root'
pw = '12345678'
db_name = 'youtube_statistics'

# Create an engine to the MySQL database
engine = create_engine(f'mysql+mysqlconnector://{uname}:{pw}@localhost/{db_name}', echo=False)

# Load datasets and write to corresponding tables
for info in dataset_info:
    table_name = info["table_name"]
    file_name = info["file_name"]
    
    # Read the CSV file
    data = pd.read_csv(file_name, encoding='utf-8')
    
    # Modify column names to match industry-standard conventions
    data.columns = data.columns.str.replace(' ', '_').str.lower()
    
    # Write the data from the CSV file to the database
    data.to_sql(table_name, con=engine, index=False, if_exists='replace')
    
print("Data loaded into MySQL database successfully.")
```


### Data Extraction Test with SQL

To test the data extraction, SQL queries can be used to retrieve specific information from the loaded datasets.

```sql
-- Query to retrieve comments, likes, and sentiment for a specific video using Video_ID
SELECT Comment, Likes, Sentiment
FROM video_comments
WHERE Video_ID = 'wAZZ-UWGVHI';

-- Example query with INNER JOIN operation to retrieve video title and comments
SELECT v.title, c.comment
FROM video_statistics AS v
INNER JOIN video_comments AS c ON v.video_id = c.video_id
LIMIT 10;

```