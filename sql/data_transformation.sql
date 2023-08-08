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


