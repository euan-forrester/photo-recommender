<template>
  <b-collapse v-model="visible" id="recommendation-collapse">
    <div class="recommendation">
      <b-link :href="this.photoUrl">
        <b-img left fluid :src="imageUrl"></b-img>
      </b-link>
      <b-button-close @click="onDismiss()" aria-controls="recommendation-collapse"></b-button-close>
    </div>
  </b-collapse>
</template>

<script>
import RepositoryFactory from '../repositories/repositoryFactory';

const FlickrRepository = RepositoryFactory.get('flickr');

export default {
  props: {
    imageId: String,
    imageOwner: String,
    imageUrl: String,
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
    onDismiss() {
      this.visible = false;
    },
  },
};
</script>

<style scoped>
.recommendation {
    clear: both;
}

</style>
