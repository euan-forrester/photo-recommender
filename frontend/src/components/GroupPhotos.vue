<template>
  <b-collapse v-model="visible" id="recommendation-collapse">
    <b-row class="groupname">
      <b-col cols=10 lg=9>
        <b-link :href="this.groupInfo.groupUrl">
          {{ this.groupInfo.groupName }}
        </b-link>
      </b-col>
    </b-row>
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
          class="photorecommendation"
        >
        </PhotoRecommendation>
      </b-col>
    </b-row>
  </b-collapse>
</template>

<style scoped>

.groupname {

}

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
};
</script>
