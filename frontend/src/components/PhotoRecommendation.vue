<template>
  <b-collapse v-model="visible" id="recommendation-collapse">
    <b-row class="photo">
      <b-col cols=10 lg=9>
        <b-link :href="this.photoUrl">
          <b-img left fluid-grow :src="imageUrl"></b-img>
        </b-link>
      </b-col>
      <b-col cols=1>
        <div v-if="this.userAuthenticated">
          <div v-if="this.dismissButton">
            <DismissButton
              @click="onDismiss()"
              :class="$mq | mq({
                xs: 'dismissbutton-sm',
                sm: 'dismissbutton-sm',
                md: 'dismissbutton-sm',
                lg: 'dismissbutton-lg',
                xl: 'dismissbutton-lg',
              })"
            ></DismissButton>
          </div>
          <AddButton
            @click="onAddFavorite()"
            :class="$mq | mq({
              xs: 'addfavoritebutton-sm',
              sm: 'addfavoritebutton-sm',
              md: 'addfavoritebutton-sm',
              lg: 'addfavoritebutton-lg',
              xl: 'addfavoritebutton-lg',
            })"
            tooltip="Fave this photo"
            :disabled="this.photoFavedState !== 'unchecked'"
            :currentState="this.photoFavedState"
          ></AddButton>
        </div>
      </b-col>
    </b-row>
    <b-alert variant="danger" :show="this.encounteredApiError">
      Encountered a problem sending the requested information. Please try again later.
    </b-alert>
    <div v-if="this.userAuthenticated">
      <b-row class="commentbox">
        <b-col cols=7 lg=4>
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
        <b-col cols=3 lg=2>
          <b-row>
            <AddButton
              @click="onAddComment()"
              :class="$mq | mq({
                xs: 'commentbutton-xs',
                sm: 'commentbutton-lg',
                md: 'commentbutton-lg',
                lg: 'commentbutton-lg',
                xl: 'commentbutton-lg',
              })"
              class=""
              :overrideUncheckedText="$mq | mq({
                xs: undefined, // Display a plus button
                sm: 'Comment',
                md: 'Comment',
                lg: 'Comment',
                xl: 'Comment',
              })"
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

.dismissbutton-sm {
  position: absolute;
  top: -5px;
  left: 24px;
}

.dismissbutton-lg {
  position: absolute;
  top: 0px;
  left: 70px;
}

.addfavoritebutton-sm {
  position: absolute;
  top: 30px;
  left: 10px;
}

.addfavoritebutton-lg {
  position: absolute;
  top: 4px;
  left: 10px;
}

.addcommenttextbox {

}

.commentbutton-xs {
  color: white;
  background-color: dodgerblue;
  width: 85%;
  height: 100%;
}

.commentbutton-lg {
  color: white;
  background-color: dodgerblue;
  width: 91%;
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
    dismissButton: {
      type: Boolean,
      default: true,
    },
  },
  data() {
    return {
      photoUrl: '',
      visible: true,
      photoFavedState: 'unchecked',
      commentAddedState: 'unchecked',
      commentText: '',
      commentTextHasFocus: false,
      encounteredApiError: false,
    };
  },
  async mounted() {
    this.photoUrl = FlickrRepository.getPhotoUrl(this.imageOwner, this.imageId);
  },
  methods: {
    async onDismiss() {
      try {
        this.visible = false;
        await this.$store.dispatch('dismissPhotoRecommendation', { userId: this.userId, dismissedImageId: this.imageId });
      } catch (e) {
        this.encounteredApiError = true;
      }
    },
    async onAddFavorite() {
      this.photoFavedState = 'loading';
      // When we disable the button it won't receive mouse events anymore and so its popover will stay forever.
      // This call hides all popovers: there should be only one, just at the mouse cursor
      // https://github.com/bootstrap-vue/bootstrap-vue/issues/1161
      this.$root.$emit('bv::hide::popover');
      try {
        await FlickrRepository.addFavorite(this.imageId, this.imageOwner, this.imageUrl);
      } catch (e) {
        this.encounteredApiError = true;
      }
      this.photoFavedState = 'checked';
      this.$emit('added-favorite');
    },
    async onAddComment() {
      try {
        this.commentAddedState = 'loading';
        await FlickrRepository.addComment(this.imageId, this.commentText);
        this.commentAddedState = 'checked';
      } catch (e) {
        this.encounteredApiError = true;
      }
    },
  },
};
</script>
