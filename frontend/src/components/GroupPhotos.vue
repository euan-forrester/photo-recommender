<template>
  <div role="tablist">
    <b-card no-body class="mb-1">
      <b-card-header header-tag="header" class="p-1" role="tab">
        <div v-if="this.encounteredApiError">
          <b-alert variant="danger" :show="true">
            Could not get the requested information. Please try again later.
          </b-alert>
        </div>
        <div v-else>
          <b-button block href="#" v-b-toggle="`accordion-${this.groupId}`" variant="info">
            {{ this.groupInfo.groupName }}
          </b-button>
        </div>
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
      encounteredApiError: false,
    };
  },
  async mounted() {
    try {
      await this.$store.dispatch('getGroupInfo', { groupId: this.groupId, numPhotos: this.numPhotos });
      this.groupInfo = this.$store.state.addfavorites.groupInfo[this.groupId];
    } catch (error) {
      this.encounteredApiError = true;
    }
  },
  methods: {
    async onAddedFavorite() {
      this.$emit('added-favorite');
    },
  },
};
</script>
