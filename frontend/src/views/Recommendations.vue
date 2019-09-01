<template>
  <div>
    <Recommendation
      v-for="photo in recommendations"
      v-bind:key="photo.image_id"
      v-bind:imageId="photo.image_id"
      v-bind:imageOwner="photo.image_owner"
      v-bind:imageUrl="photo.image_url">
    </Recommendation>
    <b-alert variant="danger" :show="this.encounteredError">
      Could not get the information requested. Please try again later
    </b-alert>
  </div>
</template>

<script>

import Recommendation from '../components/Recommendation.vue';

export default {
  components: {
    Recommendation,
  },
  data() {
    return {
      recommendations: [],
      encounteredError: false,
    };
  },
  async mounted() {
    const numPhotos = this.$route.query && this.$route.query['num-photos'] ? this.$route.query['num-photos'] : 10;

    try {
      await this.$store.dispatch('getRecommendationsForUser', { userId: this.$route.params.userId, numPhotos });

      this.recommendations = this.$store.state.user.recommendations;
    } catch (error) {
      this.encounteredError = true;
    }
  },
};
</script>
