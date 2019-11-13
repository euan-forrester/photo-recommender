<template>
  <div role="tablist">
    <b-card no-body class="mb-1">
      <b-card-header header-tag="header" class="p-1" role="tab">
        <b-button block href="#" v-b-toggle="`accordion-${this.groupId}`" variant="info">
          {{ this.groupInfo.groupName }}
        </b-button>
      </b-card-header>
      <b-collapse :id="`accordion-${this.groupId}`" accordion="groups-accordion" role="tabpanel">
        <b-card-body>
          <b-row>
            <b-col>
              <PhotoRecommendation
                v-for="photo in this.groupInfo.groupPhotos"
                v-bind:key="photo.imageId"
                v-bind:userId="userId"
                v-bind:imageId="photo.imageId"
                v-bind:imageOwner="photo.imageOwner"
                v-bind:imageUrl="photo.imageUrl"
                v-bind:userAuthenticated="userAuthenticated"
                v-bind:dismissButton="false"
                v-on:added-favorite="onAddedFavorite()"
                class="photorecommendation"
              >
              </PhotoRecommendation>
            </b-col>
          </b-row>
        </b-card-body>
      </b-collapse>
    </b-card>
  </div>
</template>

<style scoped>

.photorecommendation {
  margin-bottom: 30px;
}

</style>

<script>
import PhotoRecommendation from './PhotoRecommendation.vue';

export default {
  components: {
    PhotoRecommendation,
  },
  props: {
    userId: String,
    groupId: String,
    numPhotos: Number,
    userAuthenticated: Boolean,
  },
  data() {
    return {
      groupInfo: {
        groupPhotos: [],
        groupUrl: '',
        groupName: '',
      },
      visible: true,
    };
  },
  async mounted() {
    await this.$store.dispatch('getGroupInfo', { groupId: this.groupId, numPhotos: this.numPhotos });
    this.groupInfo = this.$store.state.addfavorites.groupInfo[this.groupId];
  },
  methods: {
    async onAddedFavorite() {
      // Keep calling getUserInfo until the data for this latest favorite has been pulled, and thus our
      // counts of how many faves & neighbors they have are updated

      // TODO: Had to disble a lint error to get this to work, which seems to indicate that this is not the best approach.
      // Need to do more googling.
      // The lint error is intended to encourage better performance by having people await multiple things rather than one at a time.

      async function delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
      }

      await this.$store.dispatch('getUserInfo', this.userId); // eslint-disable-line no-await-in-loop

      while (this.$store.getters.numRequestsCompleted < this.$store.getters.numRequestsMade) {
        await delay(1000); // eslint-disable-line no-await-in-loop

        try {
          await this.$store.dispatch('getUserInfo', this.userId); // eslint-disable-line no-await-in-loop
        } catch (error) {
          // TODO: Display an error message to the user saying the API server is unavailable
        }
      }
    },
  },
};
</script>
