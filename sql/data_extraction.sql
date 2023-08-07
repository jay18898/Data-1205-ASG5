-- Create a new database named 'youtube_statistics'
CREATE DATABASE youtube_statistics;

-- Query to retrieve comments, likes, and sentiment for a specific video using Video_ID
SELECT Comment, Likes, Sentiment
FROM video_comments
WHERE Video_ID = 'wAZZ-UWGVHI';

-- This query retrieves the title of a video from the video_statistics table and 
-- its corresponding comments from the video_comments table using an INNER JOIN operation. 
-- The LIMIT 10 clause limits the output to the first 10 records.
SELECT v.title, c.comment
FROM video_statistics AS v
INNER JOIN video_comments AS c ON v.video_id = c.video_id
LIMIT 10;
