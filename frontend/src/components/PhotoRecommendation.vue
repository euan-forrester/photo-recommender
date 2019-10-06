<template>
  <b-collapse v-model="visible" id="recommendation-collapse">
    <b-row class="photo">
      <b-col cols=9>
        <b-link :href="this.photoUrl">
          <b-img left fluid-grow :src="imageUrl"></b-img>
        </b-link>
      </b-col>
      <b-col>
        <div v-if="this.userAuthenticated">
          <DismissButton @click="onDismiss()" class="dismissbutton"></DismissButton>
          <AddButton
            @click="onAddFavorite()"
            class="addfavoritebutton"
            tooltip="Fave this photo"
            :disabled="this.photoFavedState !== 'unchecked'"
            :currentState="this.photoFavedState"
          ></AddButton>
        </div>
      </b-col>
    </b-row>
    <div v-if="this.userAuthenticated">
      <b-row class="commentbox">
        <b-col cols=4>
          <b-form-textarea
            id="textarea-add-comment"
            class="addcommenttextbox"
            placeholder="Add a comment"
            rows="2"
            no-resize
            v-model="commentText"
            @focus="commentTextHasFocus = true"
            @blur="commentTextHasFocus = false"
            :disabled="this.commentAddedState !== 'unchecked'"
          ></b-form-textarea>
        </b-col>
        <b-col cols=2>
          <b-row>
            <AddButton
              @click="onAddComment()"
              class="commentbutton"
              overrideUncheckedText="Comment"
              :disabled="this.commentAddedState !== 'unchecked'"
              :currentState="this.commentAddedState"
              v-show="(this.commentText.length > 0) || this.commentTextHasFocus"
            >
            </AddButton>
          </b-row>
        </b-col>
      </b-row>
    </div>
  </b-collapse>
</template>

<style scoped>

.photo {
  margin-bottom: 5px;
}

.commentbox {

}

.dismissbutton {
  position: absolute;
  top: 0px;
  left: 70px;
}

.addfavoritebutton {
  position: absolute;
  top: 4px;
  left: 10px;
}

.addcommenttextbox {

}

.commentbutton {
  color: white;
  background-color: dodgerblue;
  width: 100%;
  height: 100%;
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
      photoFavedState: 'unchecked',
      commentAddedState: 'unchecked',
      commentText: '',
      commentTextHasFocus: false,
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
    async onAddFavorite() {
      this.photoFavedState = 'loading';
      // When we disable the button it won't receive mouse events anymore and so its popover will stay forever.
      // This call hides all popovers: there should be only one, just at the mouse cursor
      // https://github.com/bootstrap-vue/bootstrap-vue/issues/1161
      this.$root.$emit('bv::hide::popover');
      await FlickrRepository.addFavorite(this.imageId, this.imageOwner, this.imageUrl);
      this.photoFavedState = 'checked';
    },
    async onAddComment() {
      this.commentAddedState = 'loading';
      await FlickrRepository.addComment(this.imageId, this.commentText);
      this.commentAddedState = 'checked';
    },
  },
};
</script>
