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

## How to Use

1. Clone this repository to your local machine.
2. Set up a MySQL database and configure the database credentials in the Python code and SQL scripts.
3. Run the Jupyter Notebook `data_extraction.ipynb` to extract and load the data.
4. Execute the SQL scripts in the `sql/` directory to perform data transformation.
5. Analyze the transformed data in the `combined_data` table for insights.

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

## Transformation Steps

1. **Dropping Unnecessary Columns**
   - Removed the `unnamed:_0` column from both datasets to improve clarity.

2. **Cleaning Data with Invalid Video IDs**
   - Deleted rows where the Video ID contains '=%' to ensure valid IDs.

3. **Handling Blank Views**
   - Set Views to 0 for rows with blank values to prevent calculation issues.

4. **Deleting Rows with NULL Values**
   - Removed rows from "video_statistics" with NULL likes, views, or comments.

5. **Adding Video Sentiment Classification**
   - Added `video_sentiment_type` column to "video_comments" based on sentiment values.

6. **Updating New Columns for Likes Visibility and Comment Availability**
   - Added `likes_visibility` and `comments_availability` columns to "video_statistics" to indicate visibility and availability.

7. **Aggregating Video Engagement and Sentiment**
   - Performed an aggregation to summarize engagement metrics and sentiment scores.

8. **Joining Video Statistics and Comments**
   - Performed a JOIN operation between datasets to combine engagement and sentiment data.

## Effects on the Data

- Improved data quality by removing invalid IDs and NULL values.
- Enhanced data interpretability with new columns for sentiment classification, likes visibility, and comments availability.
- Enabled more comprehensive analysis of video engagement and sentiment.
- Simplified data structure by dropping unnecessary columns.

## Data Loading with MySQL
```sql
-- Create a new table for combined data
CREATE TABLE combined_data (
    video_id VARCHAR(255),
    title VARCHAR(255),
    published_at DATE,
	video_likes INT,
     video_sentiment_type ENUM('Negative', 'Neutral', 'Positive'),
    likes_visibility ENUM('Public', 'Not Public'),
    comments_availability ENUM('Enabled', 'Disabled'),
    keyword TEXT,
    views bigint,
    comment TEXT,
    comment_likes INT,
    comment_sentiment INT
);

-- Insert transformed data into combined_data table
INSERT INTO combined_data (video_id, title, published_at, video_likes,  video_sentiment_type, likes_visibility, comments_availability, keyword, views, comment, comment_likes, comment_sentiment)
SELECT
    vs.video_id,
    vs.title,
    vs.published_at,
    vs.likes as video_likes,
        vc.video_sentiment_type,
    vs.likes_visibility,
    vs.comments_availability,
    vs.keyword,
    vs.views,
    vc.comment,
    vc.likes as comment_likes,
    vc.sentiment as comment_sentiment

FROM video_statistics AS vs
LEFT JOIN video_comments AS vc ON vs.video_id = vc.video_id;
```

### Data Loading Outputs

![Screenshot1_Load](/screenshots/load_output/ss1_load_output.png)

### Data Loading Approach:

#### 1. Data Consolidation
By combining video statistics and remarks into a single table, it is simpler to analyze relationships between disparate data points such as sentiments, likes, and comments.

#### 2. Efficient Analysis
As the join operation is performed only once during the data transformation process, storing pre-joined data in a table facilitates faster and more efficient querying and analysis.

#### 3. Data Integrity
The transformation procedure contributes to data integrity by combining pertinent data from both source tables and removing duplicate data.

#### 4. Simplification
Rather than having to manage multiple separate tables, analysts and data scientists can work with a single table

## Reflection

During the YouTube Data Analysis Project, I underwent an illuminating journey through the intricacies of handling and analyzing real-world data. This project served as an invaluable platform for grasping the multifaceted processes of data extraction, transformation, and loading, thereby revealing the nuances of data analysis.

Some key insights from this project include:

- **Complex Data Handling**: This endeavor provided a firsthand experience of dealing with real-world data, which often comes with challenges beyond the theoretical realm.

- **Data Transformation Complexity**: The project highlighted the complexities involved in transforming data, particularly due to issues like invalid Video IDs, NULL values, and missing data.

- **Data Quality as a Challenge**: Ensuring data quality proved to be a significant challenge. Addressing discrepancies and maintaining integrity demanded careful problem-solving.

- **Database Architecture and JOIN Operations**: Developing an effective database structure and performing JOIN operations was a challenging task, especially when dealing with multiple datasets.

- **Importance of Data Aggregation**: The project underscored the necessity of cleaning, processing, and aggregating data to facilitate reliable analysis and glean meaningful insights.

In conclusion, this project has been an invaluable learning experience. It has deepened my understanding of data analysis, equipped me with practical skills in data cleaning and transformation, and provided a firsthand encounter with the intricacies of working with real-world data. By tackling data quality issues, refining database design, and considering validation tests, I feel better equipped to tackle similar challenges and extract valuable insights from intricate datasets.

## Power BI Dashboard
![PowerBI Dashboard](/screenshots/PowerBI%20Dashboard.jpeg)
