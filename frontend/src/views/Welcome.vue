<template>
  <div>
    <b-container>
      <b-row no-gutters align-h="center">
        <b-col sm=12 md=10 lg=8 xl=6>
          <b-jumbotron>
            <template v-slot:header>Photo Recommender</template>
          </b-jumbotron>
          <b-form-group
            id="num-photos-group"
            label="Number of photo recommendations you would like"
            label-for="num-photos"
            label-align="left"
            label-cols=10
          >
            <b-form-input
              v-model="numPhotos"
              type="number"
              @input="$v.numPhotos.$touch()"
              :state="$v.numPhotos.$dirty && $v.numPhotos.$error ? false : null"
              id="num-photos"
              placeholder="e.g. 50"
            ></b-form-input>
            <b-form-invalid-feedback :state="$v.numPhotos.$dirty ? !$v.numPhotos.$error : null">
              You must enter a number
            </b-form-invalid-feedback>
          </b-form-group>
          <b-form-group
            id="num-users-group"
            label="Number of recommendations of users to follow you would like"
            label-for="num-users"
            label-align="left"
            label-cols=10
          >
            <b-form-input
              v-model="numUsers"
              type="number"
              @input="$v.numUsers.$touch()"
              :state="$v.numUsers.$dirty && $v.numUsers.$error ? false : null"
              id="num-users"
              placeholder="e.g. 5"
            ></b-form-input>
            <b-form-invalid-feedback :state="$v.numUsers.$dirty ? !$v.numUsers.$error : null">
              You must enter a number
            </b-form-invalid-feedback>
          </b-form-group>
        </b-col>
      </b-row>
      <b-row no-gutters align-h="center" class="calculatinginitialrecommendations">
        <b-col sm=12 md=10 lg=8 xl=6>
          <div v-if="this.currentState === 'waitingForInitiallyProcessedData'">
            <b-alert variant="info" :show="true">
              Calculating initial recommendations for user {{this.userName}}
            </b-alert>
            <b-spinner label="Waiting to receive initial recommendations for user"></b-spinner>
          </div>
          <b-alert variant="danger" :show="this.currentState === 'apiError'">
            Could not get the requested information. Please try again later.
          </b-alert>
        </b-col>
      </b-row>
      <b-row align-h="center" class="urlorlogin">
        <b-col cols="4">
          <b-form-group id="user-url-group" label="View someone's recommendations by entering their Flickr URL" label-for="user-url">
            <b-form-input
              v-model="userUrl"
              @input="$v.userUrl.$touch()"
              :state="$v.userUrl.$dirty && $v.userUrl.$error ? false : null"
              id="user-url"
              placeholder="e.g. https://www.flickr.com/photos/user/"
            ></b-form-input>
            <b-form-invalid-feedback :state="$v.userUrl.$dirty ? !$v.userUrl.$error : null">
              Your photos URL must look like https://www.flickr.com/photos/user/
            </b-form-invalid-feedback>
          </b-form-group>
          <b-alert variant="info" :show="this.currentState === 'userNotFound'">
            User not found - maybe there's a typo?
          </b-alert>
          <b-button
            type="submit"
            variant="primary"
            :disabled="$v.$anyError || (this.currentState === 'waitingForInitiallyProcessedData')"
            @click="onSubmit()"
            v-b-popover.hover.top=
            "'If you view someone else\'s recommendations you won\'t be able to ' +
             'interact with them directly in this app. But you can still follow links ' +
             'to the users and photos recommended to follow, fave, and comment.'"
          >
            Submit
          </b-button>
        </b-col>
        <b-col cols="2" align-self="center">
          or
        </b-col>
        <b-col cols="4" align-self="end">
          <b-alert variant="danger" :show="this.currentState === 'loginFailed'">
            Encountered problem logging in. Please try again later.
          </b-alert>
          <b-button
            variant="primary"
            @click="onLogin()"
            block
            v-b-popover.hover.top=
            "'If you log into Flickr you can interact with your recommendations: ' +
             'faving them, commenting on them, or dismissing them.'"
          >
            Login to Flickr to get your own recommendations
          </b-button>
        </b-col>
      </b-row>
    </b-container>
  </div>
</template>

<style scoped>
.calculatinginitialrecommendations {
  margin-top: 20px;
}

.urlorlogin {
  margin-top: 30px;
}
</style>

<script>
import { validationMixin } from 'vuelidate';
import { required, url, numeric } from 'vuelidate/lib/validators';
import vueAuth from '../auth';

export default {
  mixins: [validationMixin],
  data() {
    return {
      userUrl: '',
      userId: '',
      userName: '',
      numPhotos: 50,
      numUsers: 5,
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
    numUsers: {
      required,
      numeric,
    },
  },
  methods: {
    async onLogin() {
      this.currentState = 'none';

      try {
        
        // Refreshing can empty our store but leave our local storage with the token, so we still need to refresh our
        // store by calling getUserIdCurrentlyLoggedIn, even if we've already authenticated
        
        if (!vueAuth.isAuthenticated()) {
          await this.$store.dispatch('login');
        }
        
        await this.$store.dispatch('getUserIdCurrentlyLoggedIn'); // The login action just gets a token back that we want to treat as opaque and so doesn't actually know who was logged in. So there's a separate API call to get the ID of the currently-logged-in user
      
      } catch (error) {
        this.currentState = 'loginFailed';
        return;
      }
      
      await this.maybeAddNewUserThenViewRecommendations();
    },
    async onSubmit() {
      this.$v.$touch();
      if (this.$v.$anyError) {
        return;
      }

      // Before do anything, log out our current user (if any) because we want to be in
      // unauthenticated mode to display our results

      try {
        await this.$store.dispatch('logout');
      } catch (error) {
        // Just keep going even if we can't log out: the goal here is just to be not logged in
      }

      // Turn the Flickr URL into a Flickr user ID

      this.currentState = 'none';

      try {
        await this.$store.dispatch('getUserIdFromUrl', this.userUrl);
      } catch (error) {
        if (error.response && error.response.status === 404) {
          this.currentState = 'userNotFound';
        } else {
          this.currentState = 'apiError';
        }

        return;
      }

      await this.maybeAddNewUserThenViewRecommendations();
    },
    async maybeAddNewUserThenViewRecommendations() {
      this.userName = this.$store.state.welcome.user.name;
      this.userId = this.$store.state.welcome.user.id;
      this.currentState = 'userFound';

      // Check our system to see if we have that user. Add that user if necessary

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

      while (!this.$store.state.welcome.user.haveInitiallyProcessedData) {
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

      this.$router.push({
        name: 'recommendations',
        params: { userId: this.$store.state.welcome.user.id },
        query: { 'num-photos': this.numPhotos, 'num-users': this.numUsers },
      });
    },
  },
};
</script>
