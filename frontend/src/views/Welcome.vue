<template>
  <div>
    <b-form @submit.stop.prevent="onSubmit" @reset="onReset">
      <b-form-group id="user-url-group" label="Enter the URL of your Flickr photos" label-for="user-url">
        <b-form-input
          v-model="userUrl"
          @input="$v.userUrl.$touch()"
          :state="$v.userUrl.$dirty ? !$v.userUrl.$error : null"
          id="user-url"
          placeholder="e.g. https://www.flickr.com/photos/my_user/"
        ></b-form-input>
        <b-form-invalid-feedback :state="$v.userUrl.$dirty ? !$v.userUrl.$error : null">
          Your photos URL must look like https://www.flickr.com/photos/my_user/
        </b-form-invalid-feedback>
      </b-form-group>
      <b-alert variant="success" :show="(this.flickrContacted && !this.flickrError) ? this.userFound : null">
        Found user {{this.userName}}
      </b-alert>
      <b-alert variant="info" :show="(this.flickrContacted && !this.flickrError) ? !this.userFound : null">
        User not found - maybe there's a typo?
      </b-alert>
      <b-alert variant="danger" :show="this.flickrContacted ? this.flickrError : null">
        Error contacting Flickr. Please try again later
      </b-alert>
      <b-form-group id="num-photos-group" label="Enter the number of photo recommendations you would like" label-for="num-photos">
        <b-form-input
          v-model="numPhotos"
          @input="$v.numPhotos.$touch()"
          :state="$v.numPhotos.$dirty ? !$v.numPhotos.$error : null"
          id="num-photos"
          placeholder="e.g. 50"
        ></b-form-input>
        <b-form-invalid-feedback :state="$v.numPhotos.$dirty ? !$v.numPhotos.$error : null">
          You must enter a number
        </b-form-invalid-feedback>
      </b-form-group>
      <b-button type="submit" variant="primary" :disabled="$v.$invalid">Submit</b-button>
      <b-button type="reset" variant="danger">Reset</b-button>
     </b-form>
  </div>
</template>

<script>
import { validationMixin } from 'vuelidate';
import { required, url, numeric } from 'vuelidate/lib/validators';

export default {
  mixins: [validationMixin],
  data() {
    return {
      userUrl: '',
      userName: '',
      numPhotos: 50,
      flickrContacted: false,
      flickrError: false,
      userFound: false,
    };
  },
  validations: {
    userUrl: {
      required,
      url,
    },
    numPhotos: {
      required,
      numeric,
    },
  },
  methods: {
    async onSubmit(evt) {
      this.$v.$touch();
      if (this.$v.userUrl.$anyError || this.$v.numPhotos.$anyError) {
        return;
      }

      evt.preventDefault();

      try {
        this.flickrContacted = false;
        this.flickrError = false;
        this.userFound = false;

        await this.$store.dispatch('getUserIdFromUrl', this.userUrl);

        this.userName = this.$store.state.user.name;
        this.userFound = true;
      } catch (error) {
        if (error.response && error.response.status === 404) {
          this.userFound = false;
        } else {
          this.flickrError = true;
        }
      } finally {
        this.flickrContacted = true;
      }

      this.$router.push({ name: 'recommendations', params: { userId: this.$store.state.user.id }, query: { 'num-photos': this.numPhotos } });
    },
    onReset(evt) {
      evt.preventDefault();
      // Reset our form values
      this.userUrl = '';
      this.userName = '';
      this.numPhotos = 50;
      this.flickrContacted = false;
      this.flickrError = false;
      this.userFound = false;
      this.$v.$reset();
      // Trick to reset/clear native browser form validation state
      this.show = false;
      this.$nextTick(() => {
        this.show = true;
      });
    },
  },
};
</script>
