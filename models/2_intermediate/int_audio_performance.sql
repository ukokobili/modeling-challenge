WITH view_aggregates AS (
    SELECT
        track_name,
        track_author,
        audio_category,
        SUM(views) AS total_views,
        SUM(viral_video_count) as total_viral_videos,
        SUM(CASE WHEN rank_by_views <= 50 THEN 1 ELSE 0 END) AS top50_vw_app,
        SUM(CASE WHEN rank_by_views <= 10 THEN 1 ELSE 0 END) AS top10_vw_app,
        AVG(CASE WHEN rank_by_views <= 50 THEN rank_by_views ELSE 51 END) AS avg_top50_vw_rank,
        AVG(CASE WHEN rank_by_views <= 10 THEN rank_by_views ELSE 51 END) AS avg_top10_vw_rank,
    FROM
        {{ ref('int_tiktok_top_audio_cleaned') }}
    GROUP BY
        track_name, track_author, audio_category
), 

normalized_factors AS (
    SELECT
        MAX(total_views) AS max_views, MIN(total_views) AS min_views,
        MAX(top50_vw_app) AS max_top50, MIN(top50_vw_app) AS min_top50,
        MAX(top10_vw_app) AS max_top10, MIN(top10_vw_app) AS min_top10,
        MIN(avg_top50_vw_rank) AS max_avg_top50, MAX(avg_top50_vw_rank) AS min_avg_top50,
        MIN(avg_top10_vw_rank) AS max_avg_top10, MAX(avg_top10_vw_rank) AS min_avg_top10
    FROM view_aggregates
), 

normalized_view_aggregates as (
    SELECT
        track_name,
        track_author,
        audio_category,
        total_views,
        total_viral_videos,
        total_views / total_viral_videos as avg_views_per_viral_video,
        top50_vw_app,
        top10_vw_app,
        avg_top50_vw_rank,
        avg_top10_vw_rank,
        (v.total_views - nf.min_views) / (nf.max_views - nf.min_views) AS norm_total_views,
        (v.top50_vw_app - nf.min_top50) / (nf.max_top50 - nf.min_top50) AS norm_top50_app,
        (v.top10_vw_app - nf.min_top10) / (nf.max_top10 - nf.min_top10) AS norm_top10_app,
        (nf.min_avg_top50 - v.avg_top50_vw_rank) / (nf.min_avg_top50 - nf.max_avg_top50) AS norm_avg_top50_rank,
        (nf.min_avg_top10 - v.avg_top10_vw_rank) / (nf.min_avg_top10 - nf.max_avg_top10) AS norm_avg_top10_rank
    FROM
        view_aggregates v, normalized_factors nf
)

select
    *
    , {{ calculate_performance_scores(
            'norm_total_views',
            'norm_top50_app',
            'norm_top10_app',
            'norm_avg_top50_rank',
            'norm_avg_top10_rank'
        ) }}
from normalized_view_aggregates