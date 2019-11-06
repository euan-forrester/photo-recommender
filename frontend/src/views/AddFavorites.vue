<template>
  <div>
    <div v-if="!userAuthenticated">
      <b-row align-h="center">
        <b-col xs=12 sm=8 md=6 class="notenoughfavorites">
          <h3>
            Sorry, <b-link :href="profileUrl">{{ userName }}</b-link> doesn't have enough favorites to generate any recommendations.
          </h3>
        </b-col>
      </b-row>
      <b-row align-h="center">
        <b-col xs=12 sm=8 md=6 class="minnumfavorites">
          <h4>
            They have {{ numFavorites }} favorites from {{ numNeighbors }} different users, but need at least
            {{ appConfig.minNumFavoritesForRecommendations }} favorites from at least
            {{ appConfig.minNumNeighborsForRecommendations }} different users.
          </h4>
        </b-col>
      </b-row>
      <b-row align-h="center">
        <b-col xs=12 sm=8 md=6 class="backtowelcome">
          <h4>
            <router-link to="/">Try someone else</router-link>
          </h4>
        </b-col>
      </b-row>
    </div>
    <div v-else>
      <b-container>
        <GroupPhotos
          v-for="groupId in this.groupIds"
          v-bind:key="groupId"
          v-bind:userId="userId"
          v-bind:groupId="groupId"
          v-bind:numPhotos="numPhotosPerGroup"
          v-bind:userAuthenticated="userAuthenticated"
          class="groupphoto"
        >
        </GroupPhotos>
      </b-container>
    </div>
  </div>
</template>

<style scoped>
.notenoughfavorites {

}

.minnumfavorites {
  margin-top: 30px;
}

.backtowelcome {
  margin-top: 30px;
}

.groupphoto {

}
</style>

<script>

import GroupPhotos from '../components/GroupPhotos.vue';
import RepositoryFactory from '../repositories/repositoryFactory';

const FlickrRepository = RepositoryFactory.get('flickr');

export default {
  components: {
    GroupPhotos,
  },
  data() {
    return {
      userName: '',
      userId: '',
      profileUrl: '',
      userAuthenticated: false,
      numFavorites: 0,
      numNeighbors: 0,
      groupIds: [],
      numPhotosPerGroup: 0,
    };
  },
  async mounted() {
    this.userName = this.$store.state.welcome.user.name;
    this.userId = this.$route.params.userId;
    this.profileUrl = FlickrRepository.getProfileUrl(this.$route.params.userId);
    this.userAuthenticated = true; // this.$store.getters.isAuthenticated();
    this.numFavorites = this.$store.state.welcome.user.numFavorites;
    this.numNeighbors = this.$store.state.welcome.user.numNeighbors;
    this.groupIds = this.appConfig.recommendedGroupsToFindFavorites;
    this.numPhotosPerGroup = this.appConfig.recommendedGroupsNumPhotosToShow;
  },
};
</script>
