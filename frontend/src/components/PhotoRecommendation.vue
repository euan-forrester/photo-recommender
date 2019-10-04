<template>
  <b-col cols=12 class="recommendation">
    <b-collapse v-model="visible" id="recommendation-collapse">
      <div class="recommendation">
        <b-link :href="this.photoUrl">
          <b-img left fluid :src="imageUrl"></b-img>
        </b-link>
        <div v-if="this.userAuthenticated">
          <DismissButton @click="onDismiss()" class="dismissbutton"></DismissButton>
          <AddButton @click="onAdd()" class="addbutton" tooltip="Fave this photo"></AddButton>
        </div>
      </div>
    </b-collapse>
  </b-col>
</template>

<style scoped>

.recommendation {
  margin-bottom: 10px;
}

.dismissbutton {
  position: absolute;
  top: 0px;
  right: 4px;
}
.addbutton {
  position: absolute;
  top: 4px;
  right: 40px;
}
</style>

<script>
import DismissButton from './DismissButton.vue';
import AddButton from './AddButton.vue';
import RepositoryFactory from '../repositories/repositoryFactory';

const FlickrRepository = RepositoryFactory.get('flickr');

export default {
  components: {
    DismissButton,
    AddButton,
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
    async onAdd() {
      await FlickrRepository.addFavorite(this.imageId, this.imageOwner, this.imageUrl);
    },
  },
};
</script>
