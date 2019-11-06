const config = {
  minNumNeighborsForRecommendations: 3,
  minNumFavoritesForRecommendations: 5,
  defaultNumPhotoRecommendations: 50,
  defaultNumUserRecommendations: 2,
  recommendedGroupsToFindFavorites: [
    '80641914@N00', // Flickr's 100 Best: https://www.flickr.com/groups/best100only/
    '14673266@N22', // Print Boldly: https://www.flickr.com/groups/printboldly/
    '34427469792@N01', // Flickr Central: https://www.flickr.com/groups/central/
    '16978849@N00', // Black and White: https://www.flickr.com/groups/blackandwhite/
    '94761711@N00', // Hardcore Street Photography: https://www.flickr.com/groups/onthestreet/
  ],
  recommendedGroupsNumPhotosToShow: 20,
};

export default config;
