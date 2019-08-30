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
        <b-form-valid-feedback :state="$v.userUrl.$dirty ? !$v.userUrl.$error : null">
          Thank you!
        </b-form-valid-feedback>
      </b-form-group>
      <b-button type="submit" variant="primary" :disabled="$v.$invalid">Submit</b-button>
      <b-button type="reset" variant="danger">Reset</b-button>
     </b-form>
  </div>
</template>

<script>
import { validationMixin } from 'vuelidate';
import { required, url } from 'vuelidate/lib/validators';

export default {
  mixins: [validationMixin],
  data() {
    return {
      userUrl: '',
    };
  },
  validations: {
    userUrl: {
      required,
      url,
    },
  },
  methods: {
    onSubmit(evt) {
      this.$v.$touch();
      if (this.$v.userUrl.$anyError) {
        return;
      }

      evt.preventDefault();
      console.log(this.userUrl);
    },
    onReset(evt) {
      evt.preventDefault();
      // Reset our form values
      this.userUrl = '';
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
