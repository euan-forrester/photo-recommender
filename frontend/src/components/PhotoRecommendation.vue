<template>
  <div class="recommendation">
    <b-link :href="this.photoUrl">
      <b-img left fluid :src="imageUrl"></b-img>
    </b-link>
  </div>
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
    };
  },
  async mounted() {
    this.photoUrl = FlickrRepository.getPhotoUrl(this.imageOwner, this.imageId);
  },
};
</script>

<style scoped>
.recommendation {
    clear: both;
}
</style>
