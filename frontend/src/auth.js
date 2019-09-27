import Vue from 'vue';
import Vuex from 'vuex';
import VueAxios from 'vue-axios';
import { VueAuthenticate } from 'vue-authenticate';
import axios from 'axios';

Vue.use(Vuex);
Vue.use(VueAxios, axios);

export default new VueAuthenticate(Vue.prototype.$http, {
  baseUrl: '',
  loginUrl: '/api/flickr/login'
});
