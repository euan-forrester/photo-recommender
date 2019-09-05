<template>
  <div class="recommendation">
    <b-link :href="this.photoUrl">
      <b-img left fluid :src="imageUrl"></b-img>
    </b-link>
  </div>
</template>

<script>
import { getPhotoUrl } from '../repositories/flickrRepository'

export default {
  props: {
    imageId: String,
    imageOwner: String,
    imageUrl: String,
  },
  data() {
    return {
      photoUrl,
    };
  },
  async mounted() {
    this.photoUrl = getPhotoUrl(this.imageOwner, this.imageId);
  },
};
</script>

<style scoped>
.recommendation {
    clear: both;
}
</style>
