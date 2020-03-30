<template>
  <div>
    <b-alert variant="danger" :show="this.encounteredApiError">
      Encountered an error trying to get the requested information. Please try again later.
    </b-alert>
    <div v-if="!userAuthenticated">
      <b-row align-h="center">
        <b-col xs=12 sm=8 md=6 class="notenoughfavorites">
          <h3>
            Sorry, <b-link :href="profileUrl">{{ userName }}</b-link> doesn't have enough favorites to generate any recommendations.
          </h3>
        </b-col>
      </b-row>
      <div v-if="!userProcessingStatusIsDirty">
        <b-row align-h="center">
          <b-col xs=12 sm=8 md=6 class="minnumfavorites">
            <h4>
              They have {{ this.numFavorites }} favorites from {{ this.numNeighbors }} different users, but need at least
              {{ appConfig.minNumFavoritesForRecommendations }} favorites from at least
              {{ appConfig.minNumNeighborsForRecommendations }} different users.
            </h4>
          </b-col>
        </b-row>
      </div>
      <b-row align-h="center">
        <b-col xs=12 sm=8 md=6 class="backtowelcome">
          <h4>
            <router-link to="/">Try someone else</router-link>
          </h4>
        </b-col>
      </b-row>
    </div>
    <div v-else>
      <div v-if="!userProcessingStatusIsDirty">
        <div v-if="!hasEnoughRecommendations">
          <b-row align-h="center">
            <b-col xs=12 sm=8 md=6 class="notenoughfavorites">
              <h3>
                Sorry, you don't have enough favorites to generate any recommendations.
              </h3>
            </b-col>
          </b-row>
        </div>
        <div v-else>
          <b-row align-h="center">
            <b-col cols=8>
              <b-button block variant='primary' class="torecommendations" @click="toRecommendations()">
                  Take me to my recommendations
              </b-button>
            </b-col>
          </b-row>
        </div>
        <b-row align-h="center">
          <b-col xs=12 sm=8 md=6 class="minnumfavorites">
            <h4>
              You have {{ this.numFavorites }} favorites from {{ this.numNeighbors }} different users, and need at least
              {{ appConfig.minNumFavoritesForRecommendations }} favorites from at least
              {{ appConfig.minNumNeighborsForRecommendations }} different users.
            </h4>
          </b-col>
        </b-row>
      </div>
      <b-row align-h="center">
        <b-col xs=12 sm=8 md=6 class="minnumfavorites">
          <h4>
            Open the groups below to find some photos you like and add them as favorites.
          </h4>
        </b-col>
      </b-row>
      <GroupPhotos
        v-for="groupId in this.groupIds"
        v-bind:key="groupId"
        v-bind:userId="userId"
        v-bind:groupId="groupId"
        v-bind:numPhotos="numPhotosPerGroup"
        v-bind:userAuthenticated="userAuthenticated"
        v-on:added-favorite="onAddedFavorite()"
        class="groupphoto"
      >
      </GroupPhotos>
    </div>
  </div>
</template>

<style scoped>

.notenoughfavorites {

}

.torecommendations {
  height: 75px;
  line-height: 60px;
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
      groupIds: [],
      numPhotosPerGroup: 0,
      encounteredApiError: false,
    };
  },
  computed: {
    numFavorites() {
      return this.$store.state.welcome.user.numFavorites;
    },
    numNeighbors() {
      return this.$store.state.welcome.user.numNeighbors;
    },
    hasEnoughRecommendations() {
      return (this.numFavorites >= this.appConfig.minNumFavoritesForRecommendations)
        && (this.numNeighbors >= this.appConfig.minNumNeighborsForRecommendations);
    },
    userProcessingStatusIsDirty() {
      return this.$store.state.welcome.user.processingStatusIsDirty;
    },
  },
  async mounted() {
    this.userName = this.$store.state.welcome.user.name;
    this.userId = this.$route.params.userId;
    this.profileUrl = FlickrRepository.getProfileUrl(this.$route.params.userId);
    this.userAuthenticated = this.$store.getters.isAuthenticated();
    this.groupIds = this.appConfig.recommendedGroupsToFindFavorites;
    this.numPhotosPerGroup = this.appConfig.recommendedGroupsNumPhotosToShow;

    if (this.userProcessingStatusIsDirty) {
      // Refresh our store so we know how many favorites/neighbors we have
      await this.getUserInfo();
    }
  },
  methods: {
    toRecommendations() {
      this.$router.push({
        name: 'recommendations',
        params: { userId: this.$store.state.welcome.user.id },
      }).catch(() => {}); // This might throw an error if the navigation "fails" because a router guard intercepts it
    },
    async onAddedFavorite() {
      // Keep calling getUserInfo until the data for this latest favorite has been pulled, and thus our
      // counts of how many faves & neighbors they have are updated

      // TODO: Had to disble a lint error to get this to work, which seems to indicate that this is not the best approach.
      // Need to do more googling.
      // The lint error is intended to encourage better performance by having people await multiple things rather than one at a time.

      async function delay(ms) {
        return new Promise((resolve) => setTimeout(resolve, ms));
      }

      await this.getUserInfo();

      while (this.$store.getters.numRequestsCompleted < this.$store.getters.numRequestsMade) {
        await delay(1000); // eslint-disable-line no-await-in-loop
        await this.getUserInfo(); // eslint-disable-line no-await-in-loop
      }
    },
    async getUserInfo() {
      try {
        await this.$store.dispatch('getUserInfo', this.userId);
      } catch (error) {
        this.encounteredApiError = true;
      }
    },
  },
};
</script>
