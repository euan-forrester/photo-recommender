<template>
  <div>
    <b-container>
      <b-row no-gutters align-h="center">
        <b-col sm=12 md=10 lg=8 xl=6>
          <b-jumbotron>
            <template v-slot:header>Photo Recommender Login</template>
          </b-jumbotron>
          <b-form @submit.stop.prevent="onSubmit" @reset="onReset">
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
              label="Number of recommendations for users to follow you would like"
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
            <b-button
              type="submit"
              variant="primary"
              :disabled="$v.$anyError || (this.currentState === 'waitingForInitiallyProcessedData')"
            >
              Login
            </b-button>
            <b-button
              type="reset"
              variant="danger"
            >
              Reset
            </b-button>
          </b-form>
          <div v-if="this.currentState === 'waitingForInitiallyProcessedData'">
            <b-alert variant="info" :show="true" id="calculating-initial-recommendations">
              Calculating initial recommendations for user {{this.userName}}
            </b-alert>
            <b-spinner label="Waiting to receive initial recommendations for user"></b-spinner>
          </div>
        </b-col>
      </b-row>
    </b-container>
  </div>
</template>

<style scoped>
#calculating-initial-recommendations {
  margin-top: 20px;
}
</style>

<script>
import { validationMixin } from 'vuelidate';
import { required, numeric } from 'vuelidate/lib/validators';

export default {
  mixins: [validationMixin],
  data() {
    return {
      userId: '',
      userName: '',
      numPhotos: 50,
      numUsers: 5,
      currentState: 'none',
    };
  },
  validations: {
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
    async onSubmit(evt) {
      this.$v.$touch();
      if (this.$v.$anyError) {
        return;
      }

      evt.preventDefault();

      this.$store.dispatch('login');
    },
    onReset(evt) {
      evt.preventDefault();
      // Reset our form values
      this.userUrl = '';
      this.userId = '';
      this.userName = '';
      this.numPhotos = 50;
      this.numUsers = 5;
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
