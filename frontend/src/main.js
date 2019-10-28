import '@babel/polyfill';
import 'mutationobserver-shim';
import Vue from 'vue';
import './plugins/bootstrap-vue';
import './plugins/fontawesome-vue';
import './plugins/mediaquery-vue';
import App from './App.vue';
import router from './router';
import store from './store';
import config from './config';

Vue.config.productionTip = false;
Vue.prototype.appConfig = config;

new Vue({
  router,
  store,
  render: h => h(App),
}).$mount('#app');
