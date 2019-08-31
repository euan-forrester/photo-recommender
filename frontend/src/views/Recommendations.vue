<template>
  <div>
    <Recommendation
      v-for="photo in recommendations"
      v-bind:key="photo.image_id"
      v-bind:imageId="photo.image_id"
      v-bind:imageOwner="photo.image_owner"
      v-bind:imageUrl="photo.image_url">
    </Recommendation>
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
    };
  },
  async mounted() {
    await this.$store.dispatch('getRecommendationsForUser', this.$route.params.userId);

    this.recommendations = this.$store.state.user.recommendations;
  },
};
</script>
