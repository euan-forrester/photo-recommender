CREATE TABLE favorites (
    id INT AUTO_INCREMENT,
    image_id VARCHAR(64) NOT NULL,
    image_owner VARCHAR(32) NOT NULL,
    image_url VARCHAR(2083) NOT NULL,
    favorited_by VARCHAR(32) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY (image_id, favorited_by),
    KEY (favorited_by),
    KEY (image_owner),
    KEY (image_id)
) ENGINE = InnoDB, CHARACTER SET = utf8mb4;

CREATE TABLE registered_users (
    id INT AUTO_INCREMENT,
    user_id VARCHAR(32) NOT NULL,
    data_last_requested_at TIMESTAMP,
    all_data_last_successfully_processed_at TIMESTAMP,
    num_puller_requests_made INT NOT NULL DEFAULT 0,
    num_puller_requests_finished INT NOT NULL DEFAULT 0,
    num_ingester_requests_made INT NOT NULL DEFAULT 0,
    num_ingester_requests_finished INT NOT NULL DEFAULT 0,
    flickr_access_token BLOB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY (user_id),
    KEY (data_last_requested_at),
    KEY (all_data_last_successfully_processed_at)
) ENGINE = InnoDB, CHARACTER SET = utf8mb4;

CREATE TABLE task_locks (
    id INT AUTO_INCREMENT,
    process_id VARCHAR(64) NOT NULL,
    task_id VARCHAR(64) NOT NULL,
    lock_expiry TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY (process_id),
    KEY (task_id)
) ENGINE = InnoDB, CHARACTER SET = utf8mb4;

CREATE TABLE followers (
    id INT AUTO_INCREMENT,
    follower_id VARCHAR(32) NOT NULL,
    followee_id VARCHAR(32) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY (follower_id),
    KEY (followee_id),
    UNIQUE KEY (followee_id, follower_id)
) ENGINE = InnoDB, CHARACTER SET = utf8mb4;

CREATE TABLE dismissed_photo_recommendations (
    id INT AUTO_INCREMENT,
    user_id VARCHAR(32) NOT NULL,
    recommendation_image_id VARCHAR(64) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY (user_id),
    KEY (recommendation_image_id),
    UNIQUE KEY (user_id, recommendation_image_id)
) ENGINE = InnoDB, CHARACTER SET = utf8mb4;

CREATE TABLE dismissed_user_recommendations (
    id INT AUTO_INCREMENT,
    user_id VARCHAR(32) NOT NULL,
    recommendation_user_id VARCHAR(32) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY (user_id),
    KEY (recommendation_user_id),
    UNIQUE KEY (user_id, recommendation_user_id)
) ENGINE = InnoDB, CHARACTER SET = utf8mb4;
