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
      <b-alert variant="info" :show="this.currentState === 'userNotFound'">
        User not found - maybe there's a typo?
      </b-alert>
      <b-alert variant="danger" :show="this.currentState === 'apiError'">
        Could not get the requested information. Please try again later
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
     <div v-if="this.currentState === 'waitingForInitiallyProcessedData'">
       <b-alert variant="info" :show="true">
          Calculating initial recommendations for user {{this.userName}}
       </b-alert>
       <b-spinner label="Waiting to receive initial recommendations for user"></b-spinner>
     </div>
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
      userId: '',
      userName: '',
      numPhotos: 50,
      currentState: 'none',
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
      if (this.$v.$anyError) {
        return;
      }

      evt.preventDefault();

      // First, turn the Flickr URL into a Flickr user ID

      try {
        this.currentState = 'none';

        await this.$store.dispatch('getUserIdFromUrl', this.userUrl);

        this.userName = this.$store.state.user.name;
        this.userId = this.$store.state.user.id;
        this.currentState = 'userFound';
      } catch (error) {
        if (error.response && error.response.status === 404) {
          this.currentState = 'userNotFound';
        } else {
          this.currentState = 'apiError';
        }

        return;
      }

      // Then check our system to see if we have that user. Add that user if necessary

      let needToAddUser = false;

      try {
        await this.$store.dispatch('getUserInfo', this.userId);
      } catch (error) {
        if (error.response && error.response.status === 404) {
          needToAddUser = true;
        } else {
          this.currentState = 'apiError';
          return;
        }
      }

      if (needToAddUser) {
        try {
          await this.$store.dispatch('addNewUser', this.userId);
        } catch (error) {
          this.currentState = 'apiError';
          return;
        }
      }

      // Now wait until their data is ready.
      // TODO: Had to disble a lint error to get this to work, which seems to indicate that this is not the best approach.
      // Need to do more googling.
      // The lint error is intended to encourage better performance by having people await multiple things rather than one at a time.

      async function delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
      }

      while (!this.$store.state.user.haveInitiallyProcessedData) {
        this.currentState = 'waitingForInitiallyProcessedData';

        await delay(1000); // eslint-disable-line no-await-in-loop

        try {
          await this.$store.dispatch('getUserInfo', this.userId); // eslint-disable-line no-await-in-loop
        } catch (error) {
          this.currentState = 'apiError';
          return;
        }
      }

      // We have their data, so display their recommendations

      this.$router.push({ name: 'recommendations', params: { userId: this.$store.state.user.id }, query: { 'num-photos': this.numPhotos } });
    },
    onReset(evt) {
      evt.preventDefault();
      // Reset our form values
      this.userUrl = '';
      this.userId = '';
      this.userName = '';
      this.numPhotos = 50;
      this.currentState = 'none';
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
