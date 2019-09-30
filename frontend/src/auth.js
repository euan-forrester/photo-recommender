import Vue from 'vue';
import Vuex from 'vuex';
import VueAxios from 'vue-axios';
import { VueAuthenticate } from 'vue-authenticate';
import axios from 'axios';

Vue.use(Vuex);
Vue.use(VueAxios, axios);

// Copied from https://github.com/dgrubelic/vue-authenticate/blob/fc4958ceb5ffe1cc0084d370e5e9bd62ebddcfd4/example/vue-authenticate.js#L46
function isUndefined(value) {
  return typeof value === 'undefined';
}

// Copied from https://github.com/dgrubelic/vue-authenticate/blob/fc4958ceb5ffe1cc0084d370e5e9bd62ebddcfd4/example/vue-authenticate.js#L544
function getRedirectUri(uri) {
  try {
    return (!isUndefined(uri))
      ? (`${window.location.origin}${uri}`)
      : window.location.origin;
  } catch (e) {
    return uri || null;
  }
}

export default new VueAuthenticate(Vue.prototype.$http, {
  providers: {
    flickr: {
      name: 'flickr',
      url: '/api/flickr/auth',
      authorizationEndpoint: 'https://www.flickr.com/services/oauth/authorize',
      redirectUri: getRedirectUri(),
      oauthType: '1.0',
      popupOptions: { width: 495, height: 645 },
    },
  },
});
