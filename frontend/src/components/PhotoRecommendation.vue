<template>
  <b-collapse v-model="visible" id="recommendation-collapse">
    <div class="recommendation">
      <b-link :href="this.photoUrl">
        <b-img left fluid :src="imageUrl"></b-img>
      </b-link>
      <div v-if="this.userAuthenticated">
        <DismissButton @click="onDismiss()"></DismissButton>
      </div>
    </div>
  </b-collapse>
</template>

<script>
import DismissButton from './DismissButton.vue';
import RepositoryFactory from '../repositories/repositoryFactory';

const FlickrRepository = RepositoryFactory.get('flickr');

export default {
  components: {
    DismissButton,
  },
  props: {
    userId: String,
    imageId: String,
    imageOwner: String,
    imageUrl: String,
    userAuthenticated: Boolean,
  },
  data() {
    return {
      photoUrl: '',
      visible: true,
    };
  },
  async mounted() {
    this.photoUrl = FlickrRepository.getPhotoUrl(this.imageOwner, this.imageId);
  },
  methods: {
    async onDismiss() {
      this.visible = false;

      await this.$store.dispatch('dismissPhotoRecommendation', { userId: this.userId, dismissedImageId: this.imageId });
    },
  },
};
</script>

<style scoped>
.recommendation {
    clear: both;
}

</style>
