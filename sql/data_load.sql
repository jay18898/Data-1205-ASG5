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