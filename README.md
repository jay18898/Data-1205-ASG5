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
### Data Extraction Outputs

![Screenshot1_Extraction](/screenshots/extract_output/ss1_extract_output.png)

![Screenshot2_Extraction](/screenshots/extract_output/ss2_extract_output.png)


## Data Transformation with MySQL

After extracting the data, the next step in the ETL process is data transformation. MySQL is used for performing data transformation operations.
```sql
-- Data Cleaning and Transformation:

-- Dropping Unnecessary Columns:
-- Drop column in Video Dataset
ALTER TABLE video_statistics
DROP COLUMN `unnamed:_0`;

-- Drop column in Comment Dataset
ALTER TABLE video_comments
DROP COLUMN `unnamed:_0`;

-- Cleaning videos-stats.csv
DELETE FROM video_statistics
WHERE Video_ID LIKE '=%';

-- Cleaning comments.csv
DELETE FROM video_comments
WHERE Video_ID LIKE '=%';

-- Handling Blank Views:
UPDATE video_statistics
SET Views = 0
WHERE Views = '';

-- Delete rows with NULL values in likes, views, or comments columns from video_statistics table
DELETE FROM video_statistics
WHERE likes IS NULL OR views IS NULL OR comments IS NULL;


-- Delete rows with NULL values in likes or comment columns from video_statistics table
DELETE FROM video_comments
WHERE likes IS NULL OR comment IS NULL;

-- Combine Both Datasets and Create New Column for Video Sentiment Classification
ALTER TABLE video_comments
ADD COLUMN video_sentiment_type ENUM('Negative', 'Neutral', 'Positive') DEFAULT 'Neutral';

UPDATE video_comments AS vc
SET video_sentiment_type = CASE
        WHEN vc.sentiment = 0 THEN 'Negative'
        WHEN vc.sentiment = 1 THEN 'Neutral'
        WHEN vc.sentiment = 2 THEN 'Positive'
        ELSE 'Unknown'
    END;
    
-- Add a new column for likes visibility
ALTER TABLE video_statistics
ADD COLUMN likes_visibility ENUM('Public', 'Not Public') DEFAULT 'Public';

-- Update the new column based on the Likes column value
UPDATE video_statistics
SET likes_visibility = CASE WHEN likes = -1 THEN 'Not Public' ELSE 'Public' END;


-- Add a new column for comment availability
ALTER TABLE video_statistics
ADD COLUMN comments_availability ENUM('Enabled', 'Disabled') DEFAULT 'Enabled';

-- Update the new column based on the Comments column value
UPDATE video_statistics
SET comments_availability = CASE WHEN Comments = -1 THEN 'Disabled' ELSE 'Enabled' END;

-- Count NULL values in the likes and comment columns of video_comments table
SELECT
    SUM(CASE WHEN likes IS NULL THEN 1 ELSE 0 END) AS null_count_likes,
    SUM(CASE WHEN comment IS NULL THEN 1 ELSE 0 END) AS null_count_comments
FROM
    video_comments;

-- Count NULL values in the comments, likes, and views columns of video_statistics table
SELECT
    SUM(CASE WHEN comments IS NULL THEN 1 ELSE 0 END) AS null_count_comments,
    SUM(CASE WHEN likes IS NULL THEN 1 ELSE 0 END) AS null_count_likes,
    SUM(CASE WHEN views IS NULL THEN 1 ELSE 0 END) AS null_count_views
FROM
    video_statistics;

-- Perform aggregation operation to summarize video engagement and sentiment
SELECT
    vs.video_id,
    vs.title,
    COUNT(vc.comment) AS num_comments,
    SUM(vc.likes) AS total_likes,
    AVG(vc.sentiment) AS avg_sentiment
FROM video_statistics AS vs
LEFT JOIN video_comments AS vc ON vs.Video_ID = vc.Video_ID
GROUP BY vs.video_id, vs.title;

-- Perform JOIN operation to combine video_statistics and video_comments
SELECT
    vs.video_id,
    vs.title,
    vs.published_at,
    vc.comment,
    vc.likes AS comment_likes,
    vc.sentiment AS comment_sentiment
FROM video_statistics AS vs
LEFT JOIN video_comments AS vc ON vs.video_id = vc.video_id;
```
### Data Transformation Outputs

![Screenshot1_Transformation](/screenshots/transform_output/ss1_transform_output.png)

![Screenshot2_Transformation](/screenshots/transform_output/ss2_transform_output.png)

![Screenshot3_Transformation](/screenshots/transform_output/ss3_transform_output.png)

![Screenshot4_Transformation](/screenshots/transform_output/ss4_transform_output.png)

