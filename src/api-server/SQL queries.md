# Various SQL queries, used to build our eventual query that returns our photo recommendations

```
select * from favorites;
```

## My neighbors
```
select distinct image_owner from favorites where favorited_by="86466248@N00";
```

## My neighbors and how many favorites they have
```
select favorited_by as 'neighbor_user_id', count(image_id) as 'num_favorites' from favorites where favorited_by in 
    (select distinct image_owner from favorites where favorited_by="86466248@N00") 
    group by favorited_by;
```

## My neighbors and how many favorites in common with me they have
```
select neighbor_favorites.favorited_by as 'neighbor_user_id', count(neighbor_favorites.image_id) as 'num_favorites_in_common' from
        favorites as my_favorites 
    join 
        favorites as neighbor_favorites
    on 
        my_favorites.image_id = neighbor_favorites.image_id
    where 
        my_favorites.favorited_by="86466248@N00" and neighbor_favorites.favorited_by in (select distinct image_owner from favorites where favorited_by="86466248@N00") 
    group by 
        neighbor_favorites.favorited_by;
```

## My neighbors, how many favorites they have, and how many favorites they have in common with me
```
select total_favorites.neighbor_user_id, total_favorites.num_favorites, ifnull(common_favorites.num_favorites_in_common, 0) as 'num_favorites_in_common' from
        (select favorited_by as 'neighbor_user_id', count(image_id) as 'num_favorites' from favorites where favorited_by in 
            (select distinct image_owner from favorites where favorited_by="86466248@N00") 
            group by favorited_by) as total_favorites
    left join 
        (select neighbor_favorites.favorited_by as 'neighbor_user_id', count(neighbor_favorites.image_id) as 'num_favorites_in_common' from
            favorites as my_favorites join favorites as neighbor_favorites
            on my_favorites.image_id = neighbor_favorites.image_id
            where my_favorites.favorited_by="86466248@N00" and neighbor_favorites.favorited_by in (select distinct image_owner from favorites where favorited_by="86466248@N00") 
            group by neighbor_favorites.favorited_by) as common_favorites
    on 
        total_favorites.neighbor_user_id = common_favorites.neighbor_user_id;
```

## My neighbors, how many favorites they have, how many favorites they have in common with me, and their score
```
select 
        total_favorites.neighbor_user_id as 'neighbor_user_id', 
        total_favorites.num_favorites as 'num_favorites', 
        ifnull(common_favorites.num_favorites_in_common, 0) as 'num_favorites_in_common', 
        150 * sqrt(ifnull(common_favorites.num_favorites_in_common, 0) / (total_favorites.num_favorites + 250)) as 'score' 
    from
        (select favorited_by as 'neighbor_user_id', count(image_id) as 'num_favorites' from favorites where favorited_by in 
            (select distinct image_owner from favorites where favorited_by="86466248@N00") 
            group by favorited_by) as total_favorites
    left join 
        (select neighbor_favorites.favorited_by as 'neighbor_user_id', count(neighbor_favorites.image_id) as 'num_favorites_in_common' from
            favorites as my_favorites join favorites as neighbor_favorites
            on my_favorites.image_id = neighbor_favorites.image_id
            where my_favorites.favorited_by="86466248@N00" and neighbor_favorites.favorited_by in (select distinct image_owner from favorites where favorited_by="86466248@N00") 
            group by neighbor_favorites.favorited_by) as common_favorites
    on 
        total_favorites.neighbor_user_id = common_favorites.neighbor_user_id;
```

## For all photos favorited by my neighbors and not me, which neighbors favorited them
```
select image_id, image_owner, image_url, favorited_by from favorites 
    where 
        favorited_by in (select distinct image_owner from favorites where favorited_by="86466248@N00") 
    and
        image_id not in (select image_id from favorites where favorited_by="86466248@N00");
```

## All photos favorited by my neighbors and not me, and their scores
```
select possible_photos.image_id, possible_photos.image_owner, possible_photos.image_url, sum(neighbor_scores.score) as 'total_score' from
        (select image_id, image_owner, image_url, favorited_by from favorites 
            where 
                favorited_by in (select distinct image_owner from favorites where favorited_by="86466248@N00") 
            and
                image_id not in (select image_id from favorites where favorited_by="86466248@N00")) as possible_photos
    join
        (select 
            total_favorites.neighbor_user_id as 'neighbor_user_id', 
            total_favorites.num_favorites as 'num_favorites', 
            ifnull(common_favorites.num_favorites_in_common, 0) as 'num_favorites_in_common', 
            150 * sqrt(ifnull(common_favorites.num_favorites_in_common, 0) / (total_favorites.num_favorites + 250)) as 'score' 
        from
            (select favorited_by as 'neighbor_user_id', count(image_id) as 'num_favorites' from favorites where favorited_by in 
                (select distinct image_owner from favorites where favorited_by="86466248@N00") 
                group by favorited_by) as total_favorites
        left join 
            (select neighbor_favorites.favorited_by as 'neighbor_user_id', count(neighbor_favorites.image_id) as 'num_favorites_in_common' from
                favorites as my_favorites join favorites as neighbor_favorites
                on my_favorites.image_id = neighbor_favorites.image_id
                where my_favorites.favorited_by="86466248@N00" and neighbor_favorites.favorited_by in (select distinct image_owner from favorites where favorited_by="86466248@N00") 
                group by neighbor_favorites.favorited_by) as common_favorites
        on 
            total_favorites.neighbor_user_id = common_favorites.neighbor_user_id) as neighbor_scores
    on possible_photos.favorited_by = neighbor_scores.neighbor_user_id
    group by possible_photos.image_id
    order by total_score desc; 
```
