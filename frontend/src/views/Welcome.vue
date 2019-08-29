<template>
  <div>
    <b-form  @submit.stop.prevent>
      <label for="feedback-user-url">Enter the URL of your Flickr photos</label>
      <b-input v-model="userUrl" :state="validation" id="user-url" placeholder="e.g. https://www.flickr.com/photos/my_user/"></b-input>
      <b-form-invalid-feedback :state="validation">
        Your photos URL must look like https://www.flickr.com/photos/my_user/
      </b-form-invalid-feedback>
      <b-form-valid-feedback :state="validation">
        Thank you!
      </b-form-valid-feedback>
     </b-form>
  </div>
</template>

<script>
const validate = require('validate.js');

export default {
  data() {
    return {
      userUrl: '',
    };
  },
  computed: {
    validation() {
      return typeof validate({ website: this.userUrl }, { website: { url: true } }) === 'undefined';
    },
  },
};
</script>
