<template>
  <div>
    <b-container>
      <h2 align="left" id="user-recommendations-header">
        <div v-if="userAuthenticated">People you might want to follow</div>
        <div v-if="!userAuthenticated">People they might want to follow</div>
      </h2>
      <b-row>
        <UserRecommendation
          v-for="user in recommendations.users"
          v-bind:key="user.user_id"
          v-bind:userId="userId"
          v-bind:recommendationUserId="user.user_id"
          v-bind:userAuthenticated="userAuthenticated">
        </UserRecommendation>
      </b-row>
    </b-container>
    <b-container>
      <h2 align="left" id="photo-recommendations-header">
        <div v-if="userAuthenticated">Photos you might like</div>
        <div v-if="!userAuthenticated">Photos they might like</div>
      </h2>
      <b-row align-h="center">
        <PhotoRecommendation
          v-for="photo in recommendations.photos"
          v-bind:key="photo.image_id"
          v-bind:userId="userId"
          v-bind:imageId="photo.image_id"
          v-bind:imageOwner="photo.image_owner"
          v-bind:imageUrl="photo.image_url"
          v-bind:userAuthenticated="userAuthenticated">
        </PhotoRecommendation>
      </b-row>
    </b-container>
    <b-alert variant="danger" :show="this.encounteredError">
      Could not get the information requested. Please try again later
    </b-alert>
  </div>
</template>

<script>

import PhotoRecommendation from '../components/PhotoRecommendation.vue';
import UserRecommendation from '../components/UserRecommendation.vue';

export default {
  components: {
    PhotoRecommendation,
    UserRecommendation,
  },
  data() {
    return {
      recommendations: [],
      encounteredError: false,
      userId: '',
      userAuthenticated: false,
    };
  },
  async mounted() {
    this.userId = this.$route.params.userId;
    this.userAuthenticated = (this.$store.getters.isAuthenticated());// && (this.userId === this.$store.state.welcome.user.id)); // Make sure that our route matches the user we authenticated with. Otherwise, if someone cheeky entered a different user into the URL bar just show the unauthenticated view
    const numPhotos = this.$route.query && this.$route.query['num-photos'] ? this.$route.query['num-photos'] : 50;
    const numUsers = this.$route.query && this.$route.query['num-users'] ? this.$route.query['num-users'] : 5;

    try {
      await this.$store.dispatch('getRecommendationsForUser', { userId: this.userId, numPhotos, numUsers });

      this.recommendations = this.$store.state.recommendations.recommendations;
    } catch (error) {
      this.encounteredError = true;
    }
  },
};
</script>

<style scoped>
#photo-recommendations-header {
  margin-top: 20px;
}
</style>
