CREATE TABLE favorites (
    id INT AUTO_INCREMENT,
    image_id VARCHAR(64) NOT NULL,
    image_owner VARCHAR(32) NOT NULL,
    image_url VARCHAR(2083) NOT NULL,
    favorited_by VARCHAR(32) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY (image_id, favorited_by),
    KEY (favorited_by),
    KEY (image_owner),
    KEY (image_id)
) ENGINE = InnoDB, CHARACTER SET = utf8mb4;